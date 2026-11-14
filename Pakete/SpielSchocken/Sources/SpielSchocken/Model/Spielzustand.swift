// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Wo im Ablauf der Bildschirm gerade steht.
enum Phase: String, Codable {
    /// Ein Mensch ist dran und hat noch nicht geworfen.
    case vorWurf
    /// Ein Mensch hat geworfen und entscheidet.
    case nachWurf
    /// Ein Computer ist dran (Wurf oder Entscheidung stehen aus).
    case computer
    /// Die Runde ist gewertet, die Deckel sind verteilt; wartet auf „Weiter“.
    case rundenwertung
    /// Eine Hälfte ist zu Ende, es folgt Hälfte 2 oder das Finale.
    case haelfteVorbei
    case partieVorbei
    /// Der Zug ist beendet (automatisch nach dem letzten Wurf, oder „Stehen lassen“ eines Computers),
    /// Wurf und Wertung bleiben sichtbar; der Mensch tippt „Weiter“, beim Computer läuft eine Pause (SPEZIFIKATION 15.1).
    case zugEnde
}

/// Wie ein Mensch würfelt: mit den Würfeln der App oder mit echten Würfeln am Tisch (SPEZIFIKATION 15.2).
enum WuerfelModus: String, Codable, CaseIterable {
    case app, echt
}

/// Ein beendeter Zug in der Runde (für Wertungsanzeige und Tests).
struct ZugProtokoll: Codable, Equatable {
    var spieler: Int
    /// alle drei Würfel, absteigend
    var wuerfel: [Int]
    var ergebnis: Ergebnis
    var aktionen: [Aktion] = []

    init(spieler: Int, wuerfel: [Int], ergebnis: Ergebnis, aktionen: [Aktion] = []) {
        self.spieler = spieler
        self.wuerfel = wuerfel
        self.ergebnis = ergebnis
        self.aktionen = aktionen
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spieler = try c.decode(Int.self, forKey: .spieler)
        wuerfel = try c.decode([Int].self, forKey: .wuerfel)
        ergebnis = try c.decode(Ergebnis.self, forKey: .ergebnis)
        aktionen = try c.decodeIfPresent([Aktion].self, forKey: .aktionen) ?? []
    }
}

/// Eine beendete Runde im Rundenverlauf (Format wie `partien/*.json` → `runden[]`, SPEZIFIKATION 13.2).
struct RundenEintrag: Codable, Equatable {
    var beginner: Int
    var zuege: [ZugProtokoll]
    var verlierer: Int
    var gewinner: Int
    var deckel: Int
    var ausStock: Bool
    var stock: Int
    var stand: [Int]
    var raus: [Int]
}

/// Alle beendeten Runden einer Hälfte (oder des Finales).
struct HaelftenVerlauf: Codable, Equatable {
    var art: Haelfte.Art
    var spieler: [Int]
    var runden: [RundenEintrag] = []

    /// Deckel eines Spielers nach jeder Runde, beginnend mit 0 vor der ersten Runde (für die Kurve).
    func kurve(_ spielerIndex: Int) -> [Int] {
        guard let i = spieler.firstIndex(of: spielerIndex) else { return [] }
        return [0] + runden.map { $0.stand[i] }
    }

    /// Ab welcher Runde (1-basiert) lag der Spieler ununterbrochen bis zum Ende vorn bei den Deckeln („hinten“)?
    func liegtHintenAb(_ spielerIndex: Int) -> Int? {
        guard let i = spieler.firstIndex(of: spielerIndex), !runden.isEmpty else { return nil }
        var ab: Int?
        for (r, e) in runden.enumerated().reversed() {
            guard e.stand[i] == e.stand.max() else { break }
            ab = r + 1
        }
        return ab
    }

    /// Wie oft Schock aus geworfen wurde
    var schockAus: Int {
        runden.flatMap(\.zuege).filter { $0.ergebnis.wertung.art == .schockAus }.count
    }

    /// Der beste Wurf der Hälfte mit dem Spieler, der ihn geworfen hat
    var besterWurf: (spieler: Int, wertung: Wertung)? {
        runden.flatMap(\.zuege).map { ($0.spieler, $0.ergebnis.wertung) }
            .max { $0.1.schluessel < $1.1.schluessel }
    }
}

struct Runde: Codable, Equatable {
    var beginner: Int
    /// aktive Spieler ab dem Vorleger
    var reihenfolge: [Int]
    /// Index in `reihenfolge`; gleich `reihenfolge.count`, wenn alle dran waren
    var position = 0
    /// Würfe, die der Vorleger benutzt hat, sind für alle das Maximum
    var maxWuerfe = 3
    var zuege: [ZugProtokoll] = []
    /// laufender oder zuletzt beendeter Zug
    var zug: Zug?
    var ausgang: Rundenausgang?

    var ergebnisse: [(spieler: Int, ergebnis: Ergebnis)] { zuege.map { ($0.spieler, $0.ergebnis) } }
}

/// Zähler für die Statistik, je Spieler (Index wie in `namen`).
struct Zaehler: Codable, Equatable {
    var schockAus: [Int]
    var besterWurf: [Wertung?]
    var haelftenVerloren: [Int]

    init(spieler n: Int) {
        schockAus = Array(repeating: 0, count: n)
        besterWurf = Array(repeating: nil, count: n)
        haelftenVerloren = Array(repeating: 0, count: n)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let n = try c.decodeIfPresent([Int].self, forKey: .schockAus)?.count ?? 0
        schockAus = try c.decodeIfPresent([Int].self, forKey: .schockAus) ?? Array(repeating: 0, count: n)
        besterWurf = try c.decodeIfPresent([Wertung?].self, forKey: .besterWurf) ?? Array(repeating: nil, count: schockAus.count)
        haelftenVerloren = try c.decodeIfPresent([Int].self, forKey: .haelftenVerloren) ?? Array(repeating: 0, count: schockAus.count)
    }
}

/// Der ganze Spielstand einer Partie. Reine Logik: Zufall kommt als `inout`-Quelle hinein.
struct Spielzustand: Codable, Equatable {
    var namen: [String]
    var strategien: [Strategie]
    var avatare: [String]
    var optionen: Optionen
    /// Statistik dieser Partie ist schon verbucht
    var statistikErfasst = false
    var haelftenVerlierer: [Int] = []
    var haelfte: Haelfte
    var runde: Runde
    var phase: Phase = .vorWurf
    var partieVerlierer: Int?
    var zaehler: Zaehler
    /// Rundenverlauf, eine Liste je Hälfte (die letzte ist die aktuelle)
    var verlaeufe: [HaelftenVerlauf] = []
    /// Geführte erste Partie: Hinweise werden gezeigt
    var gefuehrt = false
    /// Je Spieler (Index wie `namen`): App-Würfel oder echte Würfel (gilt nur für Menschen)
    var wuerfelModus: [WuerfelModus] = []
    /// Bei echten Würfeln: nur das Endergebnis eintragen (Standard) oder Wurf für Wurf (SPEZIFIKATION 15.3)
    var schnelleingabe = true
    /// Blatt 22 (EB2, Schritt 2): Würfelzählung für „So fielen die Würfel“. Je Person sechs Zähler (Index 0 = Einsen) und wie viele davon eingetippt wurden.
    /// Optional: ein Stand von vor dem Update lädt mit `nil`, dann gibt es kein Bild.
    var wuerfelAugen: [[Int]]?
    var wuerfelGetippt: [Int]?

    init(namen: [String], strategien: [Strategie], avatare: [String]? = nil, optionen: Optionen, beginner: Int,
         wuerfelModus: [WuerfelModus]? = nil, schnelleingabe: Bool = true) {
        precondition(namen.count == strategien.count && (2...6).contains(namen.count))
        self.namen = namen
        self.strategien = strategien
        self.avatare = avatare ?? namen.indices.map(Avatare.standard)
        self.wuerfelModus = wuerfelModus ?? Array(repeating: .app, count: namen.count)
        self.schnelleingabe = schnelleingabe
        wuerfelAugen = Array(repeating: Array(repeating: 0, count: 6), count: namen.count)
        wuerfelGetippt = Array(repeating: 0, count: namen.count)
        self.optionen = optionen
        haelfte = Haelfte(art: .haelfte1, spieler: Array(namen.indices), beginner: beginner, optionen: optionen)
        runde = Runde(beginner: beginner, reihenfolge: haelfte.reihenfolge(ab: beginner))
        zaehler = Zaehler(spieler: namen.count)
        verlaeufe = [HaelftenVerlauf(art: haelfte.art, spieler: haelfte.spieler)]
        phase = phaseFuerAktuellen()
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        namen = try c.decode([String].self, forKey: .namen)
        strategien = try c.decodeIfPresent([Strategie].self, forKey: .strategien)
            ?? Array(repeating: .mensch, count: namen.count)
        avatare = try c.decodeIfPresent([String].self, forKey: .avatare) ?? namen.indices.map(Avatare.standard)
        statistikErfasst = try c.decodeIfPresent(Bool.self, forKey: .statistikErfasst) ?? false
        optionen = try c.decodeIfPresent(Optionen.self, forKey: .optionen) ?? .standard
        haelftenVerlierer = try c.decodeIfPresent([Int].self, forKey: .haelftenVerlierer) ?? []
        haelfte = try c.decode(Haelfte.self, forKey: .haelfte)
        runde = try c.decode(Runde.self, forKey: .runde)
        phase = try c.decodeIfPresent(Phase.self, forKey: .phase) ?? .vorWurf
        partieVerlierer = try c.decodeIfPresent(Int.self, forKey: .partieVerlierer)
        zaehler = try c.decodeIfPresent(Zaehler.self, forKey: .zaehler) ?? Zaehler(spieler: namen.count)
        verlaeufe = try c.decodeIfPresent([HaelftenVerlauf].self, forKey: .verlaeufe)
            ?? [HaelftenVerlauf(art: haelfte.art, spieler: haelfte.spieler)]
        gefuehrt = try c.decodeIfPresent(Bool.self, forKey: .gefuehrt) ?? false
        wuerfelModus = try c.decodeIfPresent([WuerfelModus].self, forKey: .wuerfelModus)
            ?? Array(repeating: .app, count: namen.count)
        schnelleingabe = try c.decodeIfPresent(Bool.self, forKey: .schnelleingabe) ?? true
        wuerfelAugen = try c.decodeIfPresent([[Int]].self, forKey: .wuerfelAugen)   // alter Stand: nil
        wuerfelGetippt = try c.decodeIfPresent([Int].self, forKey: .wuerfelGetippt)
    }

    /// Zählt Würfel für einen Spieler (nur wenn die Zählung zu dieser Partie gehört; ein alter Stand zählt nicht).
    private mutating func zaehleWuerfel(_ werte: [Int], spieler: Int?, echt: Bool) {
        guard let sp = spieler, var a = wuerfelAugen, var g = wuerfelGetippt,
              a.indices.contains(sp), g.indices.contains(sp), a[sp].count == 6 else { return }
        for w in werte where (1...6).contains(w) { a[sp][w - 1] += 1 }
        if echt { g[sp] += werte.count }
        wuerfelAugen = a; wuerfelGetippt = g
    }

    /// Alle Runden der Partie (über alle Hälften).
    var rundenGesamt: Int { verlaeufe.reduce(0) { $0 + $1.runden.count } }

    /// Die Zählung als `WuerfelBilanz`, wenn sie zu dieser Partie passt und etwas enthält (sonst `nil`: kein Bild).
    var wuerfelBilanz: WuerfelBilanz? {
        guard let a = wuerfelAugen, a.count == namen.count, a.allSatisfy({ $0.count == 6 }) else { return nil }
        var b = WuerfelBilanz(namen: namen)
        b.augen = a
        if let g = wuerfelGetippt, g.count == namen.count { b.eingetippt = g }
        return b.leer ? nil : b
    }

    // MARK: Abfragen

    /// Nummer der Runde, die gerade läuft (bzw. gerade gewertet wurde)
    var rundenNummer: Int { phase == .rundenwertung ? haelfte.runden : haelfte.runden + 1 }

    /// Wer jetzt würfelt (nur in den Phasen vorWurf, nachWurf, computer).
    var aktuellerSpieler: Int? {
        guard [.vorWurf, .nachWurf, .computer, .zugEnde].contains(phase), runde.position < runde.reihenfolge.count else { return nil }
        return runde.reihenfolge[runde.position]
    }

    /// Läuft gerade ein Zug (geworfen, noch nicht beendet)?
    var zugLaeuft: Bool { runde.zug.map { !$0.fertig } ?? false }

    /// Das schlechteste Ergebnis der Spieler, die in dieser Runde schon dran waren.
    var zuSchlagen: Ergebnis? {
        var ref: Ergebnis?
        for e in runde.zuege.map(\.ergebnis) where ref == nil || istBesser(ref!, e) { ref = e }
        return ref
    }

    /// Lage für den Computer; nur sinnvoll, wenn `zugLaeuft`.
    var lage: Lage? {
        guard zugLaeuft, let zug = runde.zug else { return nil }
        return Lage(draussen: zug.draussen, wurf: zug.wurf, wuerfe: zug.wuerfe, maxWuerfe: zug.maxWuerfe,
                    ziel: Ziel(ref: zuSchlagen, position: runde.position), optionen: optionen)
    }

    // MARK: Aktionen

    /// Der aktuelle Spieler macht seinen ersten Wurf (immer mit allen drei Würfeln).
    mutating func wuerfeln<Q: Wuerfelquelle>(_ quelle: inout Q) {
        guard aktuellerSpieler != nil, phase != .zugEnde, !zugLaeuft else { return }
        var zug = Zug(maxWuerfe: runde.maxWuerfe, optionen: optionen)
        zug.werfen(&quelle)
        zaehleWuerfel(zug.wurf, spieler: aktuellerSpieler, echt: quelle is ListenQuelle)
        runde.zug = zug
        if !zug.darfWeiter { zugBeenden(automatisch: true) } else if phase == .vorWurf { phase = .nachWurf }
    }

    /// Herauslegen und/oder umdrehen und neu werfen. `false`, wenn unerlaubt.
    @discardableResult
    mutating func weiter<Q: Wuerfelquelle>(herauslegen: [Int], umdrehen: Int, _ quelle: inout Q) -> Bool {
        guard zugLaeuft, var zug = runde.zug,
              zug.weiter(herauslegen: herauslegen, umdrehen: umdrehen, quelle: &quelle) else { return false }
        runde.zug = zug
        zaehleWuerfel(zug.wurf, spieler: aktuellerSpieler, echt: quelle is ListenQuelle)
        if !zug.darfWeiter { zugBeenden(automatisch: true) }
        return true
    }

    mutating func stehen() {
        guard zugLaeuft, var zug = runde.zug else { return }
        zug.stehen()
        runde.zug = zug
        // Ein Computer, der stehen lässt, zeigt seinen Wurf erst noch (Pause); ein Mensch braucht sie nicht.
        zugBeenden(automatisch: aktuellerSpieler.map { strategien[$0] != .mensch } ?? false)
    }

    /// „Weiter“ nach `zugEnde`: der beendete Zug wird gewertet, der nächste Spieler ist dran.
    mutating func zugWeiter() {
        guard phase == .zugEnde else { return }
        beendeZug()
    }

    // MARK: Echte Würfel (SPEZIFIKATION 15.2 und 15.3)

    /// Erster Wurf mit eingetippten Würfeln (3 Werte), die Würfelquelle wird nicht verbraucht.
    mutating func wuerfeln(eingabe werte: [Int]) {
        guard werte.count == 3, werte.allSatisfy({ (1...6).contains($0) }) else { return }
        var q = ListenQuelle(werte)
        wuerfeln(&q)
    }

    /// Weiterwürfeln mit eingetippten Würfeln (so viele, wie neu geworfen werden).
    @discardableResult
    mutating func weiter(herauslegen: [Int], umdrehen: Int, eingabe werte: [Int]) -> Bool {
        guard let zug = runde.zug, zugLaeuft,
              werte.count == 3 - zug.draussen.count - herauslegen.count - umdrehen,
              werte.allSatisfy({ (1...6).contains($0) }) else { return false }
        var q = ListenQuelle(werte)
        return weiter(herauslegen: herauslegen, umdrehen: umdrehen, &q)
    }

    /// Schnelleingabe: nur das Endergebnis. `wuerfel` sind die 3 Endwürfel (eine umgedrehte Sechs zählt als Eins),
    /// `wuerfe` die benutzten Würfe (höchstens die Vorgabe). `ausEinemWurf`: alle drei fielen im letzten Wurf
    /// zusammen (nur für Straße und General wichtig; sonst zählt der Wurf als Zahl).
    @discardableResult
    mutating func endergebnis(wuerfel: [Int], wuerfe: Int, ausEinemWurf: Bool = true) -> Bool {
        guard phase != .zugEnde, !zugLaeuft, aktuellerSpieler != nil,
              wuerfel.count == 3, wuerfel.allSatisfy({ (1...6).contains($0) }),
              (1...runde.maxWuerfe).contains(wuerfe) else { return false }
        var zug = Zug(maxWuerfe: runde.maxWuerfe, optionen: optionen)
        let sortiert = wuerfel.sorted(by: >)
        if ausEinemWurf {
            zug.wurf = sortiert
        } else {
            zug.draussen = [sortiert[0]]   // „nicht aus einem Wurf“: Straße und General zählen dann nicht
            zug.wurf = Array(sortiert.dropFirst())
        }
        zug.wuerfe = wuerfe
        zug.fertig = true
        zaehleWuerfel(wuerfel, spieler: aktuellerSpieler, echt: true)
        runde.zug = zug
        beendeZug()
        return true
    }

    /// Würde die Eingabe nach Straße oder General fragen müssen?
    static func fragtNachEinemWurf(_ wuerfel: [Int], optionen: Optionen) -> Bool {
        let art = werte(wuerfel, ausEinemWurf: true, optionen: optionen).art
        return art == .strasse || art == .general
    }

    /// Führt eine (Computer-)Aktion aus.
    @discardableResult
    mutating func fuehreAus<Q: Wuerfelquelle>(_ aktion: Aktion, _ quelle: inout Q) -> Bool {
        switch aktion {
        case .stehen: guard zugLaeuft else { return false }; stehen(); return true
        case let .weiter(h, u): return weiter(herauslegen: h, umdrehen: u, &quelle)
        }
    }

    /// Nach der Rundenwertung: nächste Runde oder Ende der Hälfte bzw. Partie.
    mutating func rundeWeiter() {
        guard phase == .rundenwertung, let ausgang = runde.ausgang else { return }
        if let v = haelfte.verlierer {
            haelftenVerlierer.append(v)
            zaehler.haelftenVerloren[v] += 1
            let ablauf = partieAblauf(haelftenVerlierer: haelftenVerlierer, optionen: optionen)
            if ablauf.naechste == nil {
                partieVerlierer = ablauf.verlierer
                phase = .partieVorbei
            } else {
                phase = .haelfteVorbei
            }
        } else {
            beginneRunde(beginner: ausgang.verlierer)
        }
    }

    /// Nach „Hälfte vorbei“: Hälfte 2 oder Finale beginnt. Es beginnt der Verlierer der letzten Hälfte.
    mutating func haelfteWeiter() {
        guard phase == .haelfteVorbei else { return }
        let ablauf = partieAblauf(haelftenVerlierer: haelftenVerlierer, optionen: optionen)
        guard let naechste = ablauf.naechste, let beginner = haelftenVerlierer.last else { return }
        let alle = Array(namen.indices)
        haelfte = Haelfte(art: naechste == .haelfte2 ? .haelfte2 : .finale,
                          spieler: naechste == .haelfte2 ? alle : ablauf.finaleSpieler,
                          beginner: beginner, optionen: optionen)
        verlaeufe.append(HaelftenVerlauf(art: haelfte.art, spieler: haelfte.spieler))
        beginneRunde(beginner: beginner)
    }

    // MARK: Intern

    private func phaseFuerAktuellen() -> Phase {
        strategien[runde.reihenfolge[runde.position]] == .mensch ? .vorWurf : .computer
    }

    private mutating func beginneRunde(beginner: Int) {
        runde = Runde(beginner: beginner, reihenfolge: haelfte.reihenfolge(ab: beginner))
        phase = phaseFuerAktuellen()
    }

    /// Zug ist zu Ende. Automatisch (letzter Wurf, Computer-„Stehen“): erst `zugEnde` zeigen, dann „Weiter“.
    private mutating func zugBeenden(automatisch: Bool) {
        runde.zug?.fertig = true
        if automatisch { phase = .zugEnde } else { beendeZug() }
    }

    private mutating func beendeZug() {
        guard let spieler = aktuellerSpieler, runde.zug != nil else { return }
        runde.zug?.fertig = true   // auch nach dem letzten erlaubten Wurf: Zug endet automatisch
        guard let zug = runde.zug else { return }
        let ergebnis = Ergebnis(wertung: zug.wertung(), wuerfe: zug.wuerfe, position: runde.position)
        runde.zuege.append(ZugProtokoll(spieler: spieler, wuerfel: zug.alleWuerfel, ergebnis: ergebnis, aktionen: zug.aktionen))
        if ergebnis.wertung.art == .schockAus { zaehler.schockAus[spieler] += 1 }
        if zaehler.besterWurf[spieler].map({ $0.schluessel < ergebnis.wertung.schluessel }) ?? true {
            zaehler.besterWurf[spieler] = ergebnis.wertung
        }
        if runde.position == 0 { runde.maxWuerfe = zug.wuerfe }
        runde.position += 1
        if runde.position < runde.reihenfolge.count {
            phase = phaseFuerAktuellen()
            return
        }
        let ausgang = werteRunde(runde.ergebnisse, haelfte: haelfte)
        haelfte.wendeAn(ausgang)
        runde.ausgang = ausgang
        if verlaeufe.isEmpty { verlaeufe = [HaelftenVerlauf(art: haelfte.art, spieler: haelfte.spieler)] }
        verlaeufe[verlaeufe.count - 1].runden.append(
            RundenEintrag(beginner: runde.beginner, zuege: runde.zuege, verlierer: ausgang.verlierer, gewinner: ausgang.gewinner,
                          deckel: ausgang.deckel, ausStock: ausgang.ausStock, stock: haelfte.stock,
                          stand: haelfte.stand, raus: haelfte.raus))
        phase = .rundenwertung
    }
}

extension Spielzustand {
    /// Passt ein geladener Spielstand zusammen? Verhindert Abstürze durch Indexfehler bei beschädigten Dateien.
    var istStimmig: Bool {
        let n = namen.count
        guard (2...6).contains(n), strategien.count == n, avatare.count == n, wuerfelModus.count == n,
              zaehler.schockAus.count == n, zaehler.besterWurf.count == n, zaehler.haelftenVerloren.count == n,
              (1...30).contains(optionen.deckel) else { return false }
        let h = haelfte
        guard !h.spieler.isEmpty, h.spieler.allSatisfy({ (0..<n).contains($0) }), Set(h.spieler).count == h.spieler.count,
              h.deckel.count == h.spieler.count, h.deckel.allSatisfy({ $0 >= 0 }), h.stock >= 0,
              h.stock + h.deckel.reduce(0, +) == h.gesamt,
              h.raus.allSatisfy({ h.spieler.contains($0) }), h.spieler.contains(h.beginner),
              h.verlierer.map({ h.spieler.contains($0) }) ?? true else { return false }
        guard haelftenVerlierer.allSatisfy({ (0..<n).contains($0) }), partieVerlierer.map({ (0..<n).contains($0) }) ?? true,
              !verlaeufe.isEmpty else { return false }
        let r = runde
        guard !r.reihenfolge.isEmpty, r.reihenfolge.allSatisfy({ h.spieler.contains($0) }),
              (0...r.reihenfolge.count).contains(r.position), (1...3).contains(r.maxWuerfe) else { return false }
        switch phase {
        case .vorWurf:
            return r.position < r.reihenfolge.count && !zugLaeuft
        case .computer:
            return r.position < r.reihenfolge.count
        case .nachWurf:
            return r.position < r.reihenfolge.count && zugLaeuft
        case .zugEnde:
            return r.position < r.reihenfolge.count && r.zug?.fertig == true
        case .rundenwertung:
            return r.ausgang != nil
        case .haelfteVorbei:
            return h.verlierer != nil && !haelftenVerlierer.isEmpty
        case .partieVorbei:
            return partieVerlierer != nil
        }
    }
}
