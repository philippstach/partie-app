// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ein Wurf mit dem gewählten Zug (nil = verfallen).
struct Wurf: Codable, Equatable, Hashable, Sendable {
    var augen: Int
    var zug: Zug?
}

/// Ein abgeschlossener Spielzug im Verlauf: Format wie `erwartet.zuege` in `partien/*.json`.
struct Verlaufseintrag: Codable, Equatable, Sendable {
    var spieler: Int
    var wuerfe: [Wurf]
    var figuren: [[Int]]
    /// Wie viele dieser Würfe mit einem echten Würfel gewürfelt und eingetippt wurden
    var eingetippt = 0

    init(spieler: Int, wuerfe: [Wurf], figuren: [[Int]], eingetippt: Int = 0) {
        self.spieler = spieler
        self.wuerfe = wuerfe
        self.figuren = figuren
        self.eingetippt = eingetippt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spieler = try c.decode(Int.self, forKey: .spieler)
        wuerfe = try c.decode([Wurf].self, forKey: .wuerfe)
        figuren = try c.decode([[Int]].self, forKey: .figuren)
        eingetippt = try c.decodeIfPresent(Int.self, forKey: .eingetippt) ?? 0
    }

    /// Gleicher Inhalt wie in den gemeinsamen Regeltests (ohne das iOS-Zählfeld `eingetippt`).
    func gleichWieRegeltest(_ o: Verlaufseintrag) -> Bool {
        spieler == o.spieler && wuerfe == o.wuerfe && figuren == o.figuren
    }
}

/// Alle Würfe eines Spielers, bis der Nächste dran ist (SPEZIFIKATION 4.2). Zustandsmaschine mit Halt-Punkten
/// für die Oberfläche: `vorWurf` → (würfeln) → `wahl` oder `verfallen` → …
struct Spielzug: Codable, Equatable, Sendable {
    enum Stand: String, Codable, Sendable {
        /// Der Spieler darf würfeln.
        case vorWurf
        /// Gewürfelt, es gibt erlaubte Züge: ein Zug muss gewählt werden.
        case wahl
        /// Gewürfelt, aber kein Zug möglich: der Wurf verfällt, `weiter()` geht weiter.
        case verfallen
        /// Spielzug zu Ende (nur kurz, `Partie` schließt ihn sofort ab).
        case ende
    }

    var spieler: Int
    var stand = Stand.vorWurf
    /// Letzte gewürfelte Augenzahl (bleibt nach dem Zug stehen, bis neu gewürfelt wird).
    var augen: Int?
    /// Fehlversuche in diesem Spielzug (nur bei „blockiert“ und drei Versuchen).
    var fehlversuche = 0
    /// Galt vor dem aktuellen Wurf „blockiert“ (und sind drei Versuche an)?
    var blockiertVorWurf = false
    /// Erlaubte Züge des aktuellen Wurfs.
    var erlaubt: [Zug] = []
    /// Bisherige Würfe dieses Spielzugs.
    var wuerfe: [Wurf] = []
    /// Wie viele Würfe dieses Spielzugs eingetippt wurden (echter Würfel)
    var eingetippt = 0

    init(spieler: Int) { self.spieler = spieler }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        spieler = try c.decode(Int.self, forKey: .spieler)
        stand = (try? c.decodeIfPresent(Stand.self, forKey: .stand)) ?? .vorWurf
        augen = try c.decodeIfPresent(Int.self, forKey: .augen)
        fehlversuche = try c.decodeIfPresent(Int.self, forKey: .fehlversuche) ?? 0
        blockiertVorWurf = try c.decodeIfPresent(Bool.self, forKey: .blockiertVorWurf) ?? false
        erlaubt = try c.decodeIfPresent([Zug].self, forKey: .erlaubt) ?? []
        wuerfe = try c.decodeIfPresent([Wurf].self, forKey: .wuerfe) ?? []
        eingetippt = try c.decodeIfPresent(Int.self, forKey: .eingetippt) ?? 0
    }

    /// Würfeln. Vorher wird festgestellt, ob der Spieler blockiert ist.
    mutating func wuerfeln(_ lage: Lage, _ opt: Optionen, _ quelle: inout some Wuerfelquelle) {
        precondition(stand == .vorWurf)
        anwenden(lage, opt, augen: quelle.naechster(), eingetippt: false)
    }

    /// Echter Würfel: Die Zahl kommt von Hand, die Würfelquelle der App wird nicht angefasst.
    mutating func eintippen(_ lage: Lage, _ opt: Optionen, augen w: Int) {
        precondition(stand == .vorWurf && (1 ... 6).contains(w))
        anwenden(lage, opt, augen: w, eingetippt: true)
    }

    private mutating func anwenden(_ lage: Lage, _ opt: Optionen, augen w: Int, eingetippt wurdeEingetippt: Bool) {
        blockiertVorWurf = opt.dreiVersuche && lage.blockiert(spieler, opt)
        if wurdeEingetippt { eingetippt += 1 }
        augen = w
        erlaubt = lage.moeglicheZuege(spieler, w, opt)
        if erlaubt.isEmpty {
            wuerfe.append(Wurf(augen: w, zug: nil))      // auch eine 6 ohne Zug gibt keinen Extrawurf
            if blockiertVorWurf { fehlversuche += 1 }
            stand = .verfallen
        } else {
            stand = .wahl
        }
    }

    /// Einen erlaubten Zug ausführen.
    @discardableResult
    mutating func waehle(_ zug: Zug, _ lage: inout Lage, _ opt: Optionen) -> Bewegung {
        precondition(stand == .wahl && erlaubt.contains(zug))
        let w = augen ?? 0
        let bewegung = lage.fuehreAus(spieler, zug)
        wuerfe.append(Wurf(augen: w, zug: zug))
        erlaubt = []
        if lage.fertig(spieler) {
            stand = .ende
        } else if w == 6 && opt.sechsNochmal {
            stand = .vorWurf
        } else {
            stand = .ende
        }
        return bewegung
    }

    /// Nach einem verfallenen Wurf: noch ein Versuch oder Ende des Spielzugs.
    mutating func weiter() {
        precondition(stand == .verfallen)
        erlaubt = []
        stand = (blockiertVorWurf && fehlversuche < 3) ? .vorWurf : .ende
    }
}

/// Eine Partie: Lage, Regeln, wer dran ist (SPEZIFIKATION 4.1).
struct Partie: Codable, Equatable, Sendable {
    var lage: Lage
    var optionen: Optionen
    var amZug: Int
    /// Spieler in der Reihenfolge, in der sie fertig wurden.
    var platzierung: [Int] = []
    var spielzug: Spielzug
    /// Alle abgeschlossenen Spielzüge (für die Statistik).
    var verlauf: [Verlaufseintrag] = []

    static func neu(sitze: [Int], beginner: Int, optionen: Optionen = .standard) -> Partie {
        precondition(sitze == sitze.sorted() && Set(sitze).count == sitze.count && (2 ... Brettmass.sitze).contains(sitze.count))
        return Partie(lage: .neu(sitze: sitze, optionen), optionen: optionen, amZug: beginner, spielzug: Spielzug(spieler: beginner))
    }

    init(lage: Lage, optionen: Optionen, amZug: Int, spielzug: Spielzug) {
        self.lage = lage
        self.optionen = optionen
        self.amZug = amZug
        self.spielzug = spielzug
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lage = try c.decode(Lage.self, forKey: .lage)
        optionen = try c.decodeIfPresent(Optionen.self, forKey: .optionen) ?? .standard
        amZug = try c.decode(Int.self, forKey: .amZug)
        platzierung = try c.decodeIfPresent([Int].self, forKey: .platzierung) ?? []
        spielzug = try c.decodeIfPresent(Spielzug.self, forKey: .spielzug) ?? Spielzug(spieler: amZug)
        verlauf = try c.decodeIfPresent([Verlaufseintrag].self, forKey: .verlauf) ?? []
    }

    var spielerzahl: Int { lage.sitze.count }

    var vorbei: Bool {
        if teamsAktiv { return teamFertig(0) || teamFertig(1) }
        return optionen.spielende == .erster ? platzierung.count >= 1 : platzierung.count >= spielerzahl - 1
    }

    /// Teams 2 gegen 2 gelten nur mit genau vier Spielern
    var teamsAktiv: Bool { optionen.teams && spielerzahl == 4 }

    /// Team eines Spielers: 0 = Spieler 1 + 3, 1 = Spieler 2 + 4
    static func team(von spieler: Int) -> Int { spieler % 2 }

    /// Haben beide Spieler dieses Teams alle Figuren im Ziel?
    func teamFertig(_ team: Int) -> Bool { platzierung.contains(team) && platzierung.contains(team + 2) }

    func naechster(_ p: Int) -> Int {
        let n = spielerzahl
        for i in 1 ... n {
            let q = (p + i) % n
            if !platzierung.contains(q) { return q }
        }
        return p
    }

    /// Der aktuelle Spieler würfelt.
    mutating func wuerfeln(_ quelle: inout some Wuerfelquelle) {
        guard !vorbei, spielzug.stand == .vorWurf else { return }
        spielzug.wuerfeln(lage, optionen, &quelle)
    }

    /// Der aktuelle Spieler tippt die Zahl seines echten Würfels ein.
    mutating func eintippen(_ augen: Int) {
        guard !vorbei, spielzug.stand == .vorWurf, (1 ... 6).contains(augen) else { return }
        spielzug.eintippen(lage, optionen, augen: augen)
    }

    /// Der aktuelle Spieler zieht.
    @discardableResult
    mutating func waehle(_ zug: Zug) -> Bewegung? {
        guard !vorbei, spielzug.stand == .wahl, spielzug.erlaubt.contains(zug) else { return nil }
        let b = spielzug.waehle(zug, &lage, optionen)
        abschliessenFallsEnde()
        return b
    }

    /// Ein verfallener Wurf ist quittiert.
    mutating func weiter() {
        guard !vorbei, spielzug.stand == .verfallen else { return }
        spielzug.weiter()
        abschliessenFallsEnde()
    }

    private mutating func abschliessenFallsEnde() {
        guard spielzug.stand == .ende else { return }
        let p = amZug
        verlauf.append(Verlaufseintrag(spieler: p, wuerfe: spielzug.wuerfe, figuren: lage.figuren, eingetippt: spielzug.eingetippt))
        if lage.fertig(p) {
            platzierung.append(p)
            let n = spielerzahl
            if teamsAktiv {
                // Gewinnerteam an die Spitze der Platzierung (der zuerst Fertige davon steht ganz oben)
                if vorbei {
                    let gewinner = Self.team(von: p)
                    platzierung = platzierung.filter { Self.team(von: $0) == gewinner } + platzierung.filter { Self.team(von: $0) != gewinner }
                }
            } else if optionen.spielende == .alle && platzierung.count == n - 1,
               let rest = (0 ..< n).first(where: { !platzierung.contains($0) }) {
                platzierung.append(rest)
            }
        }
        if !vorbei { amZug = naechster(p) }
        spielzug = Spielzug(spieler: amZug)
    }
}
