// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct HKarte: Hashable, Sendable, Comparable, Codable {
    public let farbe: Int      // 0 Kreuz, 1 Karo, 2 Pik, 3 Herz
    public let wert: Int       // 2…14 (11 Bube, 12 Dame, 13 König, 14 Ass)
    public init(_ f: Int, _ w: Int) { farbe = f; wert = w }
    public static func < (a: HKarte, b: HKarte) -> Bool { a.farbe != b.farbe ? a.farbe < b.farbe : a.wert < b.wert }
    public static let alle: [HKarte] = (0..<4).flatMap { f in (2...14).map { HKarte(f, $0) } }
    public static let farbSymbole = ["♣", "♦", "♠", "♥"]
    public static let kreuzZwei = HKarte(0, 2)
    public static let pikDame = HKarte(2, 12)
    public var punkte: Int { farbe == 3 ? 1 : (self == HKarte.pikDame ? 13 : 0) }
    public var name: String { wert <= 10 ? "\(wert)" : ["B", "D", "K", "A"][wert - 11] }
}

/// Herzensjagd: Stichspiel für vier. Wer Herzen (1 Punkt) und die Pik-Dame (13 Punkte) in Stiche bekommt, sammelt Minuspunkte.
/// Wer nach einer Runde mit mindestens `ziel` Punkten dasteht, beendet das Spiel; es gewinnt, wer die wenigsten hat.
/// Gelingt einem Spieler, alle 26 Punkte zu holen, bekommen die anderen je 26.
/// Eine ausgespielte Karte im laufenden Stich.
public struct StichKarte: Equatable, Sendable, Codable {
    public var spieler: Int
    public var karte: HKarte
    public init(spieler: Int, karte: HKarte) { self.spieler = spieler; self.karte = karte }
}

public struct Herzensjagd: Equatable, Sendable, Codable {
    public static let spieler = 4
    public let ziel: Int
    public private(set) var haende: [[HKarte]] = []
    public private(set) var stich: [StichKarte] = []
    public private(set) var amZug = 0
    public private(set) var herzenOffen = false
    public private(set) var stichNummer = 0                 // 0…12
    public private(set) var rundenPunkte = [0, 0, 0, 0]
    public private(set) var gesamt = [0, 0, 0, 0]
    public private(set) var runde = 1
    public private(set) var vorbei = false
    public private(set) var rundeFertig = false
    public private(set) var letzterStichGewinner: Int?
    public private(set) var mondschuss: Int?
    /// 1.0 (M5): Drei Karten weitergeben vor jeder Runde (Richtung reihum links, rechts, gegenüber, keine).
    public let weitergeben: Bool
    public private(set) var weitergabeOffen = false          // gerade wird gewählt (amZug wählt)
    public private(set) var gewaehlt: [[HKarte]] = [[], [], [], []]
    public private(set) var bestaetigt = 0                    // wie viele Spieler schon bestätigt haben (0…4)
    /// Blatt 22 (EB2): wie viele Durchmärsche (Mondschuss) es gab und die Rundenpunkte je beendeter Runde (vier Werte je Runde, nach dem Umrechnen).
    /// Optional: Stände von vor dem Update haben beides nicht (nil), dann zeigt die Ergebnisseite keine Durchmärsche und keine Tabelle.
    public private(set) var durchmaersche: Int?
    public private(set) var rundenVerlauf: [[Int]]?

    /// 1.0 (M5): Richtung der Weitergabe in dieser Runde: 1 links, 3 rechts, 2 gegenüber, nil keine (jede vierte Runde).
    public static func weitergabeRichtung(runde: Int) -> Int? { [1, 3, 2, nil][((runde - 1) % 4 + 4) % 4] }
    public var weitergabeRichtung: Int? { weitergeben ? Herzensjagd.weitergabeRichtung(runde: runde) : nil }

    private enum CodingKeys: String, CodingKey {
        case ziel, haende, stich, amZug, herzenOffen, stichNummer, rundenPunkte, gesamt, runde, vorbei, rundeFertig, letzterStichGewinner, mondschuss
        case weitergeben, weitergabeOffen, gewaehlt, bestaetigt, durchmaersche, rundenVerlauf
    }

    /// 1.0 (M5): alte gespeicherte Stände ohne Weitergabe bleiben lesbar (neue Felder mit Standardwert).
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        ziel = try c.decode(Int.self, forKey: .ziel)
        haende = try c.decode([[HKarte]].self, forKey: .haende)
        stich = try c.decode([StichKarte].self, forKey: .stich)
        amZug = try c.decode(Int.self, forKey: .amZug)
        herzenOffen = try c.decode(Bool.self, forKey: .herzenOffen)
        stichNummer = try c.decode(Int.self, forKey: .stichNummer)
        rundenPunkte = try c.decode([Int].self, forKey: .rundenPunkte)
        gesamt = try c.decode([Int].self, forKey: .gesamt)
        runde = try c.decode(Int.self, forKey: .runde)
        vorbei = try c.decode(Bool.self, forKey: .vorbei)
        rundeFertig = try c.decode(Bool.self, forKey: .rundeFertig)
        letzterStichGewinner = try c.decodeIfPresent(Int.self, forKey: .letzterStichGewinner)
        mondschuss = try c.decodeIfPresent(Int.self, forKey: .mondschuss)
        weitergeben = try c.decodeIfPresent(Bool.self, forKey: .weitergeben) ?? false
        weitergabeOffen = try c.decodeIfPresent(Bool.self, forKey: .weitergabeOffen) ?? false
        gewaehlt = try c.decodeIfPresent([[HKarte]].self, forKey: .gewaehlt) ?? [[], [], [], []]
        bestaetigt = try c.decodeIfPresent(Int.self, forKey: .bestaetigt) ?? 0
        durchmaersche = try c.decodeIfPresent(Int.self, forKey: .durchmaersche)
        rundenVerlauf = try c.decodeIfPresent([[Int]].self, forKey: .rundenVerlauf)
        if let v = rundenVerlauf, !v.allSatisfy({ $0.count == 4 }) { rundenVerlauf = nil }   // unstimmig: lieber nicht verwenden
    }

    /// C-024: Prüfung eines geladenen Stands gegen die aktuelle Spielerzahl.
    public func istStimmig(spieler n: Int) -> Bool {
        n == Herzensjagd.spieler && haende.count == n && haende.allSatisfy { $0.count <= 13 } && (0..<n).contains(amZug)
            && gewaehlt.count == n && (0...n).contains(bestaetigt) && gewaehlt.allSatisfy { $0.count <= 3 }
            && gesamt.count == n && rundenPunkte.count == n && stich.allSatisfy { (0..<n).contains($0.spieler) } && (0...13).contains(stichNummer)
    }

    public static func == (a: Herzensjagd, b: Herzensjagd) -> Bool {
        a.haende == b.haende && a.amZug == b.amZug && a.gesamt == b.gesamt && a.gewaehlt == b.gewaehlt && a.bestaetigt == b.bestaetigt && a.weitergabeOffen == b.weitergabeOffen && a.stich.map { [$0.spieler, $0.karte.farbe, $0.karte.wert] } == b.stich.map { [$0.spieler, $0.karte.farbe, $0.karte.wert] }
    }

    public init<G: RandomNumberGenerator>(ziel: Int = 50, weitergeben: Bool = false, mit g: inout G) { self.ziel = ziel; self.weitergeben = weitergeben; durchmaersche = 0; rundenVerlauf = []; teile(mit: &g) }

    /// Für Tests: feste Lage mitten in einer Runde.
    public init(ziel: Int = 50, haende: [[HKarte]], amZug: Int, stichNummer: Int = 1, herzenOffen: Bool = false, stich: [StichKarte] = [], rundenPunkte: [Int] = [0, 0, 0, 0]) {
        self.weitergeben = false
        durchmaersche = 0; rundenVerlauf = []
        self.rundenPunkte = rundenPunkte; self.ziel = ziel; self.haende = haende; self.amZug = amZug; self.stichNummer = stichNummer; self.herzenOffen = herzenOffen; self.stich = stich
    }

    public mutating func teile<G: RandomNumberGenerator>(mit g: inout G) {
        var d = HKarte.alle; d.shuffle(using: &g)
        haende = (0..<4).map { i in Array(d[(i * 13)..<(i * 13 + 13)]).sorted() }
        stich = []; herzenOffen = false; stichNummer = 0; rundenPunkte = [0, 0, 0, 0]; rundeFertig = false; mondschuss = nil
        gewaehlt = [[], [], [], []]; bestaetigt = 0
        amZug = haende.firstIndex { $0.contains(HKarte.kreuzZwei) }!
        if weitergabeRichtung != nil { weitergabeOffen = true; amZug = 0 } else { weitergabeOffen = false }   // 1.0 (M5)
    }

    // MARK: 1.0 (M5) Karten weitergeben

    /// Der Spieler am Zug tippt eine Karte an oder ab (höchstens drei).
    public mutating func waehleWeitergabe(_ k: HKarte) {
        guard weitergabeOffen, haende[amZug].contains(k) else { return }
        if let i = gewaehlt[amZug].firstIndex(of: k) { gewaehlt[amZug].remove(at: i) }
        else if gewaehlt[amZug].count < 3 { gewaehlt[amZug].append(k) }
    }

    public var weitergabeBereit: Bool { weitergabeOffen && gewaehlt[amZug].count == 3 }

    /// Der Spieler am Zug bestätigt seine drei Karten. Haben alle bestätigt, wird getauscht und die Runde beginnt.
    public mutating func bestaetigeWeitergabe() {
        guard weitergabeBereit, let r = weitergabeRichtung else { return }
        bestaetigt += 1
        if bestaetigt < 4 { amZug = bestaetigt; return }
        let neu = (0..<4).map { i -> [HKarte] in
            let von = (i - r + 4) % 4      // wer gibt an i weiter? Richtung 1 = nach links = an den Nächsten
            return (haende[i].filter { !gewaehlt[i].contains($0) } + gewaehlt[von]).sorted()
        }
        haende = neu
        gewaehlt = [[], [], [], []]; bestaetigt = 0; weitergabeOffen = false
        amZug = haende.firstIndex { $0.contains(HKarte.kreuzZwei) }!
    }

    /// Computer wählt für den Spieler am Zug: Pik-Dame, Pik-König und Pik-Ass, dann hohe Herzen, dann hohe Karten.
    public func computerWeitergabe(_ s: Int) -> [HKarte] {
        func wert(_ k: HKarte) -> Int {
            if k == HKarte.pikDame { return 1000 }
            if k.farbe == 2 && k.wert >= 13 { return 900 + k.wert }
            if k.farbe == 3 { return 500 + k.wert }
            return k.wert
        }
        return Array(haende[s].sorted { wert($0) > wert($1) }.prefix(3))
    }

    public mutating func computerWaehltWeitergabe() {
        guard weitergabeOffen else { return }
        gewaehlt[amZug] = computerWeitergabe(amZug)
        bestaetigeWeitergabe()
    }

    public var angespielteFarbe: Int? { stich.first?.karte.farbe }
    public var stichVoll: Bool { stich.count == 4 }

    public func erlaubt(_ s: Int) -> [HKarte] {
        let h = haende[s]
        if stich.isEmpty {
            if stichNummer == 0 { return [HKarte.kreuzZwei] }
            if herzenOffen { return h }
            let ohneHerz = h.filter { $0.farbe != 3 }
            return ohneHerz.isEmpty ? h : ohneHerz
        }
        let f = stich[0].karte.farbe
        let bedienen = h.filter { $0.farbe == f }
        if !bedienen.isEmpty { return bedienen }
        if stichNummer == 0 {   // im ersten Stich möglichst keine Punktkarten
            let frei = h.filter { $0.punkte == 0 }
            return frei.isEmpty ? h : frei
        }
        return h
    }

    @discardableResult
    public mutating func spiele(_ k: HKarte) -> Bool {
        guard !vorbei, !rundeFertig, !weitergabeOffen, !stichVoll, erlaubt(amZug).contains(k) else { return false }
        haende[amZug].removeAll { $0 == k }
        stich.append(StichKarte(spieler: amZug, karte: k))
        if k.farbe == 3 { herzenOffen = true }
        if stichVoll { return true }
        amZug = (amZug + 1) % 4
        return true
    }

    /// Wertet einen vollen Stich aus: Der Gewinner bekommt die Punkte und spielt aus.
    public mutating func stichAbschliessen<G: RandomNumberGenerator>(mit g: inout G) {
        guard stichVoll else { return }
        let f = stich[0].karte.farbe
        let gewinn = stich.filter { $0.karte.farbe == f }.max { $0.karte.wert < $1.karte.wert }!
        rundenPunkte[gewinn.spieler] += stich.reduce(0) { $0 + $1.karte.punkte }
        letzterStichGewinner = gewinn.spieler
        if stich.contains(where: { $0.karte == HKarte.pikDame }) { herzenOffen = true }
        stich = []; stichNummer += 1; amZug = gewinn.spieler
        if stichNummer == 13 {
            if let m = rundenPunkte.firstIndex(of: 26) { mondschuss = m; rundenPunkte = (0..<4).map { $0 == m ? 0 : 26 } }
            for i in 0..<4 { gesamt[i] += rundenPunkte[i] }
            if mondschuss != nil, let d = durchmaersche { durchmaersche = d + 1 }   // Blatt 22 (EB2)
            if rundenVerlauf != nil { rundenVerlauf!.append(rundenPunkte) }
            rundeFertig = true
            if gesamt.contains(where: { $0 >= ziel }) { vorbei = true }
        }
    }

    public mutating func naechsteRunde<G: RandomNumberGenerator>(mit g: inout G) {
        guard rundeFertig, !vorbei else { return }
        runde += 1; teile(mit: &g)
    }

    /// Sieger: wenigste Punkte.
    public var rangfolge: [Int] { (0..<4).sorted { gesamt[$0] < gesamt[$1] } }

    // MARK: Computer

    /// `fehler`: Wahrscheinlichkeit, stattdessen irgendeine erlaubte Karte zu spielen (0 = Vollprofi-Heuristik).
    public func computerWahl<G: RandomNumberGenerator>(_ s: Int, fehler: Double, mit g: inout G) -> HKarte {
        let ok = erlaubt(s)
        if ok.count > 1, fehler > 0, Double.random(in: 0..<1, using: &g) < fehler { return ok.randomElement(using: &g)! }
        return computerWahl(s)
    }

    /// C-030: Tipp für Menschen = die Wahl der stärksten Computerstufe (ohne Fehlgriffe), nicht bloß die erste erlaubte Karte.
    public func tippKarte(_ s: Int) -> HKarte? { weitergabeOffen || erlaubt(s).isEmpty ? nil : computerWahl(s) }

    public func computerWahl(_ s: Int) -> HKarte {
        let ok = erlaubt(s)
        if ok.count == 1 { return ok[0] }
        if stich.isEmpty {
            // Ausspielen: niedrigste Karte einer Farbe, Pik-Dame-Gefahr beachten
            let sicher = ok.filter { $0.farbe != 2 || haende[s].contains { $0.farbe == 2 && $0.wert > 12 } == false }
            return (sicher.isEmpty ? ok : sicher).min { $0.wert < $1.wert }!
        }
        let f = stich[0].karte.farbe
        let hoechste = stich.filter { $0.karte.farbe == f }.map(\.karte.wert).max()!
        let punkteImStich = stich.reduce(0) { $0 + $1.karte.punkte }
        if ok.allSatisfy({ $0.farbe == f }) {
            let drunter = ok.filter { $0.wert < hoechste }
            if let d = drunter.max(by: { $0.wert < $1.wert }) { return d }
            // muss übernehmen: als Letzter ohne Punkte hoch, sonst niedrig
            if stich.count == 3, punkteImStich == 0 { return ok.max { $0.wert < $1.wert }! }
            return ok.min { $0.wert < $1.wert }!
        }
        // Abwerfen: Pik-Dame, hohe Herzen, höchste Pik/Karo
        if ok.contains(HKarte.pikDame) { return HKarte.pikDame }
        if let h = ok.filter({ $0.farbe == 3 }).max(by: { $0.wert < $1.wert }) { return h }
        if let a = ok.filter({ $0.farbe == 2 && $0.wert >= 13 }).max(by: { $0.wert < $1.wert }) { return a }
        return ok.max { $0.wert < $1.wert }!
    }
}

/// Kartenfächer: Wie weit liegen die Karten einer Hand auseinander, damit alle in die verfügbare Breite passen?
public enum Faecher {
    /// Abstand von Kartenanfang zu Kartenanfang (höchstens `kartenbreite + 4`, sonst so eng, dass der Fächer in `platz` passt, mindestens 12).
    public static func schritt(anzahl n: Int, kartenbreite: Double, platz: Double) -> Double {
        guard n > 1 else { return kartenbreite }
        return max(12, min(kartenbreite + 4, (platz - kartenbreite) / Double(n - 1)))
    }
    /// Gesamtbreite des Fächers.
    public static func breite(anzahl n: Int, kartenbreite: Double, platz: Double) -> Double {
        kartenbreite + schritt(anzahl: n, kartenbreite: kartenbreite, platz: platz) * Double(max(0, n - 1))
    }
}
