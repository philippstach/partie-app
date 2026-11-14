// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Eintrag im Verlauf (für die „letzte Aktion“-Zeile und die Seitenspalte auf dem iPad).
public enum NAktion: Equatable, Sendable, Codable {
    case gelegt(spieler: Int, karte: NKarte)
    case gezogen(spieler: Int, anzahl: Int)
    case ausgesetzt(spieler: Int)
    case strafkarte(spieler: Int)
    case wunsch(spieler: Int, farbe: Int)
    case richtungGewechselt(spieler: Int)
}

/// Mau-Mau: Karten gleicher Farbe oder gleichen Werts ablegen; 7 zieht, 8 setzt aus, Bube wünscht, dazu frei kombinierbare Hausregeln.
public struct NMauMau: Equatable, Sendable, Codable {
    public private(set) var haende: [[NKarte]]
    public private(set) var stapel: [NKarte] = []
    public private(set) var ablage: [NKarte] = []
    public private(set) var dran = 0
    /// +1 im Uhrzeigersinn (aufsteigende Platznummer), -1 nach einer 9 mit Richtungswechsel.
    public private(set) var richtung = 1
    public private(set) var wunsch: Int?
    public private(set) var zieh = 0
    public private(set) var aussetzen = false
    /// Nach dem Ziehen mit „sofort legen“: Index der gerade gezogenen Karte in der Hand des Spielers am Zug.
    public private(set) var gezogenIndex: Int?
    public private(set) var regeln = NRegeln.standard
    public private(set) var verlauf: [NAktion] = []

    public static let verlaufGrenze = 40

    public init<G: RandomNumberGenerator>(spieler: Int, regeln: NRegeln = .standard, beginner: Int = 0, mit g: inout G) {
        let sp = max(2, min(8, spieler))
        dran = max(0, min(beginner, sp - 1))   // T-097: Wer beginnt
        self.regeln = regeln
        var deck = (0..<NRegeln.blaetter(spieler: sp)).flatMap { _ in NKarte.blatt }.shuffled(using: &g)
        let n = max(1, min(regeln.startkarten, (deck.count - 2) / sp))
        haende = (0..<sp).map { _ in let h = Array(deck.suffix(n)); deck.removeLast(n); return h }
        var start = deck.removeLast()
        func sonder(_ k: NKarte) -> Bool { k.wert == 11 || k.wert == 7 || k.wert == 8 || k.wert == regeln.aussetzenWert || (regeln.neunRichtung && k.wert == 9) }
        var versuche = 0
        while sonder(start) && versuche < deck.count { deck.insert(start, at: 0); start = deck.removeLast(); versuche += 1 }
        ablage = [start]; stapel = deck
    }

    /// Für Tests: feste Lage.
    public init(haende: [[NKarte]], ablage: [NKarte], stapel: [NKarte] = [], regeln: NRegeln = .standard, dran: Int = 0) {
        self.haende = haende; self.ablage = ablage; self.stapel = stapel; self.regeln = regeln; self.dran = dran
    }

    public var spielerZahl: Int { haende.count }
    public var oben: NKarte { ablage[ablage.count - 1] }
    public var sieger: Int? { haende.firstIndex { $0.isEmpty } }
    public var naechster: Int { (dran + richtung + spielerZahl) % spielerZahl }
    public var vorheriger: Int { (dran - richtung + spielerZahl) % spielerZahl }

    /// Darf diese Karte jetzt (ohne Rücksicht auf eine gerade gezogene Karte) gelegt werden?
    public func passt(_ k: NKarte) -> Bool {
        if zieh > 0 { return regeln.siebenZiehen && k.wert == 7 }
        if aussetzen { return k.wert == regeln.aussetzenWert }
        if k.wert == 11 {
            if !regeln.bubeAlsSchluss && haende[dran].count == 1 { return false }
            if !regeln.bubeAufBube && oben.wert == 11 { return false }
            return true
        }
        if let w = wunsch { return k.farbe == w }
        return k.farbe == oben.farbe || k.wert == oben.wert
    }

    public func spielbar(_ i: Int) -> Bool {
        guard haende[dran].indices.contains(i) else { return false }
        if let g = gezogenIndex, g != i { return false }
        return passt(haende[dran][i])
    }

    public var spielbareIndizes: [Int] { haende[dran].indices.filter(spielbar) }

    /// Der Spieler muss gerade Karten ziehen (7), aussetzen (8) oder darf nach dem Ziehen nur die gezogene Karte legen oder weitergeben.
    public enum Pflicht: Equatable, Sendable { case keine, ziehen(Int), aussetzen, weiter }
    public var pflicht: Pflicht {
        if gezogenIndex != nil { return .weiter }
        if zieh > 0 { return .ziehen(zieh) }
        if aussetzen { return .aussetzen }
        return .keine
    }

    /// Legt die Karte `i`. `wunsch` gilt beim Buben; `mau` sagt „Mau“ (nur mit der Regel nötig).
    @discardableResult
    public mutating func spiele(_ i: Int, wunsch w: Int? = nil, mau: Bool = false) -> Bool {
        guard sieger == nil, spielbar(i) else { return false }
        let k = haende[dran].remove(at: i)
        ablage.append(k); wunsch = nil; gezogenIndex = nil
        eintrag(.gelegt(spieler: dran, karte: k))
        switch k.wert {
        case 7 where regeln.siebenZiehen: zieh += 2
        case regeln.aussetzenWert where regeln.aussetzenWert != 0: aussetzen = true
        case 11:
            let f = w ?? k.farbe
            wunsch = f; eintrag(.wunsch(spieler: dran, farbe: f))
        case 9 where regeln.neunRichtung && spielerZahl >= 3:
            richtung = -richtung; eintrag(.richtungGewechselt(spieler: dran))
        default: break
        }
        if haende[dran].isEmpty { return true }
        if regeln.maueSagen, haende[dran].count == 1, !mau {
            var g = SystemRandomNumberGenerator()
            if let s = nimm(mit: &g) { haende[dran].append(s); eintrag(.strafkarte(spieler: dran)) }
        }
        dran = naechster
        return true
    }

    /// Ziehen: bei Zieh-Pflicht alle Karten, sonst eine; bei Aussetzen nur aussetzen; nach dem Ziehen mit „sofort legen“ gibt es die Karte zum Legen oder Weitergeben.
    public mutating func ziehen<G: RandomNumberGenerator>(mit g: inout G) {
        guard sieger == nil else { return }
        if gezogenIndex != nil { gezogenIndex = nil; dran = naechster; return }
        if aussetzen {
            aussetzen = false; eintrag(.ausgesetzt(spieler: dran)); dran = naechster; return
        }
        let pflichtZug = zieh > 0
        let n = pflichtZug ? zieh : 1
        var geholt = 0
        for _ in 0..<n { if let k = nimm(mit: &g) { haende[dran].append(k); geholt += 1 } }
        zieh = 0
        eintrag(.gezogen(spieler: dran, anzahl: geholt))
        if !pflichtZug, regeln.sofortLegen, geholt == 1, passt(haende[dran][haende[dran].count - 1]) {
            gezogenIndex = haende[dran].count - 1
            return
        }
        dran = naechster
    }

    private mutating func eintrag(_ a: NAktion) {
        verlauf.append(a)
        if verlauf.count > Self.verlaufGrenze { verlauf.removeFirst(verlauf.count - Self.verlaufGrenze) }
    }

    private mutating func nimm<G: RandomNumberGenerator>(mit g: inout G) -> NKarte? {
        if stapel.isEmpty, ablage.count > 1 {
            let oben = ablage.removeLast(); stapel = ablage.shuffled(using: &g); ablage = [oben]
        }
        return stapel.popLast()
    }

    /// Restaugen jedes Spielers (für Mehrrunden).
    public func restAugen(_ s: Int) -> Int { haende[s].reduce(0) { $0 + $1.augen } }
}

/// Punktestand über mehrere Runden: Wer eine Runde gewinnt, bekommt nichts, die anderen die Augen ihrer Restkarten. Wer zuerst die Zielsumme erreicht, verliert.
public struct NRunden: Equatable, Sendable, Codable {
    public private(set) var punkte: [Int]
    public private(set) var runde = 1
    public let ziel: Int
    public init(spieler: Int, ziel: Int = 100) { punkte = Array(repeating: 0, count: spieler); self.ziel = ziel }

    /// Bucht eine beendete Runde. Gibt falsch zurück, wenn niemand gewonnen hat.
    @discardableResult
    public mutating func verbuche(_ spiel: NMauMau) -> Bool {
        guard spiel.sieger != nil, spiel.spielerZahl == punkte.count else { return false }
        for s in punkte.indices { punkte[s] += spiel.restAugen(s) }
        runde += 1
        return true
    }
    public var beendet: Bool { (punkte.max() ?? 0) >= ziel }
    /// Gesamtsieger: wenigste Punkte, sobald jemand die Zielsumme erreicht hat.
    public var gesamtSieger: Int? { beendet ? punkte.firstIndex(of: punkte.min() ?? 0) : nil }
    /// Plätze von bestem zu schlechtestem.
    public var reihenfolge: [Int] { punkte.indices.sorted { punkte[$0] < punkte[$1] } }
}

public struct NZug: Equatable, Sendable {
    public var index: Int
    public var wunsch: Int?
}

public enum NComputer {
    /// Wahl des Computers; `nil` heißt ziehen, aussetzen oder weitergeben. `fehler` (0…1): Wahrscheinlichkeit für eine zufällige spielbare Karte.
    /// Mit `fehler` 0 ist die Wahl bestimmt, deshalb nimmt auch der Tipp diese Funktion.
    public static func wahl<G: RandomNumberGenerator>(_ m: NMauMau, fehler: Double = 0, mit g: inout G) -> NZug? {
        let idx = m.spielbareIndizes
        guard !idx.isEmpty else { return nil }
        let h = m.haende[m.dran]
        if fehler > 0, Double.random(in: 0..<1, using: &g) < fehler {
            let i = idx.randomElement(using: &g)!
            return NZug(index: i, wunsch: h[i].wert == 11 ? Int.random(in: 0..<4, using: &g) : nil)
        }
        return beste(m)
    }

    /// Beste Karte ohne Zufall (Tipp und schwere Stufe).
    public static func beste(_ m: NMauMau) -> NZug? {
        let idx = m.spielbareIndizes
        guard !idx.isEmpty else { return nil }
        let h = m.haende[m.dran]
        let naechsteHand = m.haende[m.naechster].count
        let vorherigeHand = m.haende[m.vorheriger].count
        func wert(_ j: Int) -> Double {
            let k = h[j]
            if k.wert == 11 { return -5 }
            let gleicheFarbe = Double(h.filter { $0.farbe == k.farbe }.count)
            let gleicherWert = Double(h.filter { $0.wert == k.wert }.count)
            let angriff: Double = ((k.wert == 7 && m.regeln.siebenZiehen) || (k.wert == m.regeln.aussetzenWert && m.regeln.aussetzenWert != 0)) ? 3 : 0
            var w = angriff * (naechsteHand <= 2 ? 2 : 1) + gleicheFarbe * 0.6 + gleicherWert * 0.4 + (k.wert >= 12 ? 0.3 : 0)
            // 9 dreht die Richtung: lohnt, wenn der Nächste fast fertig ist und der Vorherige noch viele Karten hat
            if k.wert == 9, m.regeln.neunRichtung, m.spielerZahl >= 3, naechsteHand <= 2, vorherigeHand > 2 { w += 4 }
            return w
        }
        let i = idx.max { wert($0) < wert($1) }!
        if h[i].wert == 11 {
            let rest = h.enumerated().filter { $0.offset != i }.map(\.element)
            let best = (0..<4).max { a, b in rest.filter { $0.farbe == a }.count < rest.filter { $0.farbe == b }.count } ?? h[i].farbe
            return NZug(index: i, wunsch: best)
        }
        return NZug(index: i, wunsch: nil)
    }
}
