// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Spanisches 40er-Blatt ohne 8 und 9: Ränge 1–7 und 10–12. Farben: 0 Münzen, 1 Becher, 2 Schwerter, 3 Stäbe.
public struct TrucoKarte: Equatable, Hashable, Sendable, Codable {
    public let farbe: Int
    public let rang: Int
    public init(farbe: Int, rang: Int) { self.farbe = farbe; self.rang = rang }

    /// Stärke im Stechen (höher gewinnt).
    public var staerke: Int {
        switch (rang, farbe) {
        case (1, 2): return 14
        case (1, 3): return 13
        case (7, 2): return 12
        case (7, 0): return 11
        case (3, _): return 10
        case (2, _): return 9
        case (1, _): return 8
        case (12, _): return 7
        case (11, _): return 6
        case (10, _): return 5
        case (7, _): return 4
        case (6, _): return 3
        case (5, _): return 2
        default: return 1
        }
    }
    /// Zählwert für das Envido (Bilder zählen 0).
    public var envidoWert: Int { rang >= 10 ? 0 : rang }
}

public enum TrucoAnruf: Equatable, Sendable, Codable {
    case envido
    case truco(stufe: Int)   // 2 = Truco, 3 = Retruco, 4 = Vale cuatro
}

/// Truco für zwei Spieler: eine Hand (drei Stiche). Wer zwei Stiche gewinnt, bekommt die Punkte des Einsatzes.
public struct TrucoHand: Sendable, Codable {
    public private(set) var haende: [[TrucoKarte]]
    public let ursprung: [[TrucoKarte]]
    public let mano: Int                       // beginnt den ersten Stich
    public private(set) var amZug: Int
    public private(set) var ausgespielt: [TrucoKarte?] = [nil, nil]     // aktueller Stich
    public private(set) var stiche: [Int?] = []                          // Gewinner je Stich, nil = Parda (Gleichstand)
    public private(set) var einsatz = 1
    public private(set) var einsatzSteigerer: Int?                       // wer zuletzt gesteigert hat
    private var offenAnruf: TrucoAnruf?
    private var offenVon: Int?
    public private(set) var offen: (anruf: TrucoAnruf, von: Int)? {
        get { if let a = offenAnruf, let v = offenVon { return (a, v) } else { return nil } }
        set { offenAnruf = newValue?.anruf; offenVon = newValue?.von }
    }
    public private(set) var envidoVorbei = false
    public private(set) var envidoPunkte = [0, 0]                        // an die Spieler vergeben
    public private(set) var envidoLog: String?
    public private(set) var gewinner: Int?
    public private(set) var handPunkte = [0, 0]

    public init<G: RandomNumberGenerator>(mano: Int, mit g: inout G) {
        var k = (0..<4).flatMap { f in ([1, 2, 3, 4, 5, 6, 7, 10, 11, 12]).map { TrucoKarte(farbe: f, rang: $0) } }
        k.shuffle(using: &g)
        self.init(mano: mano, haende: [Array(k[0..<3]), Array(k[3..<6])])
    }
    public init(mano: Int, haende: [[TrucoKarte]]) {
        self.haende = haende; ursprung = haende; self.mano = mano; amZug = mano
    }

    // MARK: Envido
    public static func envido(_ h: [TrucoKarte]) -> Int {
        var best = h.map(\.envidoWert).max() ?? 0
        for i in h.indices { for j in h.indices where j > i && h[i].farbe == h[j].farbe { best = max(best, 20 + h[i].envidoWert + h[j].envidoWert) } }
        return best
    }
    public func envidoWert(_ s: Int) -> Int { Self.envido(ursprung[s]) }

    // MARK: Züge
    public var vorbei: Bool { gewinner != nil }
    public var meinStich: Int { stiche.count }

    public func darfSpielen(_ s: Int) -> Bool { !vorbei && offen == nil && amZug == s && !haende[s].isEmpty }

    @discardableResult
    public mutating func spiele(_ s: Int, karte i: Int) -> Bool {
        guard darfSpielen(s), haende[s].indices.contains(i) else { return false }
        ausgespielt[s] = haende[s].remove(at: i)
        if ausgespielt[1 - s] == nil { amZug = 1 - s } else { stichAuswerten() }
        return true
    }

    private mutating func stichAuswerten() {
        let a = ausgespielt[0]!.staerke, b = ausgespielt[1]!.staerke
        let w: Int? = a == b ? nil : (a > b ? 0 : 1)
        stiche.append(w); ausgespielt = [nil, nil]
        envidoVorbei = true
        if let e = entscheidung() { beende(e) } else { amZug = w ?? mano }
    }

    private func entscheidung() -> Int? {
        let w0 = stiche.filter { $0 == 0 }.count, w1 = stiche.filter { $0 == 1 }.count
        if w0 >= 2 { return 0 }
        if w1 >= 2 { return 1 }
        if stiche.count == 2 {
            if stiche[0] == nil, let w = stiche[1] { return w }
            if stiche[1] == nil, let w = stiche[0] { return w }
        }
        if stiche.count == 3 { return stiche[2] ?? mano }
        return nil
    }

    private mutating func beende(_ s: Int) { gewinner = s; handPunkte[s] += einsatz }

    // MARK: Rufe
    public func kannRufen(_ s: Int, _ a: TrucoAnruf) -> Bool {
        guard !vorbei, offen == nil else { return false }
        switch a {
        case .envido: return !envidoVorbei && stiche.isEmpty && ausgespielt[s] == nil
        case .truco(let stufe): return stufe == einsatz + 1 && stufe <= 4 && einsatzSteigerer != s && (stufe == 2 || einsatzSteigerer != nil)
        }
    }

    @discardableResult
    public mutating func rufe(_ s: Int, _ a: TrucoAnruf) -> Bool {
        guard kannRufen(s, a) else { return false }
        offen = (a, s); return true
    }

    /// Antwort des Gegners: annehmen oder ablehnen.
    @discardableResult
    public mutating func antworte(_ s: Int, annehmen: Bool) -> Bool {
        guard let o = offen, o.von != s, !vorbei else { return false }
        offen = nil
        switch o.anruf {
        case .envido:
            envidoVorbei = true
            if !annehmen { envidoPunkte[o.von] = 1; envidoLog = "abgelehnt" }
            else {
                let a = envidoWert(o.von), b = envidoWert(s)
                let w = a == b ? mano : (a > b ? o.von : s)
                envidoPunkte[w] = 2; envidoLog = "\(a) : \(b)"
            }
        case .truco(let stufe):
            if annehmen { einsatz = stufe; einsatzSteigerer = o.von }
            else { beende(o.von) }       // bekommt den bisherigen Einsatz
        }
        return true
    }

    /// Aufgeben: der Gegner bekommt den aktuellen Einsatz.
    public mutating func passe(_ s: Int) {
        guard !vorbei else { return }
        offen = nil
        beende(1 - s)
    }
}

public enum TrucoComputer {
    /// Stärke einer Hand 0...1 grob.
    static func gutheit(_ k: [TrucoKarte]) -> Double {
        guard !k.isEmpty else { return 0 }
        return k.map { Double($0.staerke) }.reduce(0, +) / Double(k.count) / 14
    }

    /// `stufe`: 1 leicht, 2 mittel, 3 schwer (blufft und rechnet mit der eigenen Hand genauer).
    public static func antwort(_ h: TrucoHand, spieler s: Int, stufe: Int = 2) -> Bool {
        guard let o = h.offen else { return false }
        if stufe <= 1 { return Bool.random() }
        if stufe >= 3 {
            switch o.anruf {
            case .envido: return h.envidoWert(s) >= 24 || (h.envidoWert(s) >= 20 && Double.random(in: 0...1) < 0.3)
            case .truco(let st):
                let g = gutheit(h.haende[s]), schonGewonnen = h.stiche.filter { $0 == s }.count
                let schwelle = 0.5 + Double(st - 2) * 0.08 - (schonGewonnen > 0 ? 0.15 : 0)
                return g > schwelle || (g > schwelle - 0.15 && Double.random(in: 0...1) < 0.4)
            }
        }
        switch o.anruf {
        case .envido: return h.envidoWert(s) >= 25 || (h.envidoWert(s) >= 22 && Bool.random())
        case .truco: return gutheit(h.haende[s]) > 0.55 || (gutheit(h.haende[s]) > 0.4 && Bool.random())
        }
    }

    /// Eine Aktion: Ruf, Karte oder Aufgeben.
    public enum Aktion: Equatable { case spiele(Int), ruf(TrucoAnruf), passen }
    public static func aktion(_ h: TrucoHand, spieler s: Int, stufe: Int = 2) -> Aktion {
        if stufe <= 1 {
            if let i = h.haende[s].indices.randomElement() { return .spiele(i) }
        }
        if stufe >= 3, !h.haende[s].isEmpty {
            // Schwer: gelegentlich Bluff-Truco, Envido schon ab 26
            let g = gutheit(h.haende[s])
            if h.kannRufen(s, .envido), h.envidoWert(s) >= 26 { return .ruf(.envido) }
            for st in 2...4 where h.kannRufen(s, .truco(stufe: st)) {
                let bluff = Double.random(in: 0...1) < 0.12 && st == 2
                if (g > 0.62 && Double.random(in: 0...1) < 0.6) || bluff { return .ruf(.truco(stufe: st)) }
            }
        }
        if stufe == 2, h.kannRufen(s, .envido), h.envidoWert(s) >= 27 { return .ruf(.envido) }
        let g = gutheit(h.haende[s])
        if stufe == 2 { for st in 2...4 where h.kannRufen(s, .truco(stufe: st)) && g > 0.7 && Double.random(in: 0...1) < 0.5 { return .ruf(.truco(stufe: st)) } }
        let idx = h.haende[s].indices
        let gegner = h.ausgespielt[1 - s]
        if let c = gegner {
            // Billigste Karte, die sticht; sonst die schwächste
            let sticht = idx.filter { h.haende[s][$0].staerke > c.staerke }.min { h.haende[s][$0].staerke < h.haende[s][$1].staerke }
            if let i = sticht { return .spiele(i) }
            return .spiele(idx.min { h.haende[s][$0].staerke < h.haende[s][$1].staerke }!)
        }
        // Anspielen: starke Karte zuerst, wenn die Hand gut ist, sonst mittlere.
        // Schwer: Nach dem ersten Stich (verloren, Parda oder gewonnen) zählt jeder weitere Stich, also die stärkste Karte vorlegen.
        if stufe >= 3, !h.stiche.isEmpty { return .spiele(idx.max { h.haende[s][$0].staerke < h.haende[s][$1].staerke }!) }
        let sortiert = idx.sorted { h.haende[s][$0].staerke < h.haende[s][$1].staerke }
        return .spiele(g > 0.5 ? sortiert.last! : sortiert[sortiert.count / 2])
    }
}

/// Partie bis 15 Punkte (Hand für Hand, Mano wechselt).
public struct TrucoPartie: Sendable, Codable {
    public static let ziel = 15
    public private(set) var punkte = [0, 0]
    public var hand: TrucoHand
    public private(set) var naechsteMano = 1
    public private(set) var gewinner: Int?

    public init<G: RandomNumberGenerator>(mit g: inout G) { hand = TrucoHand(mano: 0, mit: &g) }

    /// Nach Ende einer Hand verbuchen und die nächste geben.
    public mutating func handAbschliessen<G: RandomNumberGenerator>(mit g: inout G) {
        guard hand.vorbei, gewinner == nil else { return }
        for s in 0..<2 { punkte[s] += hand.handPunkte[s] + hand.envidoPunkte[s] }
        if let s = (0..<2).first(where: { punkte[$0] >= Self.ziel }) { gewinner = s; return }
        hand = TrucoHand(mano: naechsteMano, mit: &g); naechsteMano = 1 - naechsteMano
    }
}
