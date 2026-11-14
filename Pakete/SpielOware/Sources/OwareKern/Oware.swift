// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Regelvarianten des Oware. Standard = 4 Samen je Mulde, Grand Slam bringt nichts.
public struct OwareRegeln: Equatable, Sendable, Codable {
    public var samen = 4
    /// Ein Zug, der alle gegnerischen Samen erobern würde, zählt (sonst passiert nichts).
    public var grandSlam = false
    public init(samen: Int = 4, grandSlam: Bool = false) { self.samen = samen; self.grandSlam = grandSlam }
    public static let standard = OwareRegeln()
    public static let kurz = OwareRegeln(samen: 3)
    public static let lang = OwareRegeln(samen: 5)
    public static let grand = OwareRegeln(grandSlam: true)
    /// Wer mehr als die Hälfte aller Samen erobert, gewinnt (3 → 19, 4 → 25, 5 → 31).
    public var ziel: Int { samen * 12 / 2 + 1 }
}

/// Oware (Awalé), Westafrika: 12 Mulden, je 4 Samen. Spieler 0 besitzt die Mulden 0–5, Spieler 1 die Mulden 6–11.
/// Gesät wird gegen den Uhrzeigersinn (aufsteigende Nummer). Wer 25 Samen erobert, gewinnt.
public struct Oware: Equatable, Sendable, Codable {
    public private(set) var mulden = [Int](repeating: 4, count: 12)
    public private(set) var vorrat = [0, 0]
    public private(set) var amZug = 0
    public private(set) var vorbei = false
    /// Halbzüge seit der letzten Beute; bei 150 endet das Spiel (Endlosschleife).
    public private(set) var ohneBeute = 0

    public private(set) var regeln = OwareRegeln.standard

    public init(regeln: OwareRegeln = .standard) { self.regeln = regeln; mulden = [Int](repeating: regeln.samen, count: 12) }

    private enum CodingKeys: String, CodingKey { case mulden, vorrat, amZug, vorbei, ohneBeute, regeln }
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mulden = try c.decode([Int].self, forKey: .mulden)
        vorrat = try c.decode([Int].self, forKey: .vorrat)
        amZug = try c.decode(Int.self, forKey: .amZug)
        vorbei = try c.decode(Bool.self, forKey: .vorbei)
        ohneBeute = try c.decodeIfPresent(Int.self, forKey: .ohneBeute) ?? 0
        regeln = try c.decodeIfPresent(OwareRegeln.self, forKey: .regeln) ?? .standard   // alte Spielstände
    }
    public init(mulden: [Int], vorrat: [Int] = [0, 0], amZug: Int = 0) { self.mulden = mulden; self.vorrat = vorrat; self.amZug = amZug; pruefeEnde() }

    public static func besitzer(_ m: Int) -> Int { m / 6 }

    /// Erlaubte Mulden des Spielers am Zug (Gegner ohne Samen muss bedient werden).
    public var zuege: [Int] {
        guard !vorbei else { return [] }
        let eigene = (amZug * 6..<amZug * 6 + 6).filter { mulden[$0] > 0 }
        let gegnerLeer = !(((1 - amZug) * 6..<(1 - amZug) * 6 + 6).contains { mulden[$0] > 0 })
        guard gegnerLeer else { return eigene }
        return eigene.filter { gibtSamen($0) }
    }

    private func gibtSamen(_ m: Int) -> Bool {
        // Erreicht der Zug eine Mulde des Gegners?
        var letzte = m, n = mulden[m], s = 0
        while n > 0 { letzte = (letzte + 1) % 12; if letzte == m { continue }; n -= 1; s += 1; if Self.besitzer(letzte) != amZug { return true } }
        return false
    }

    /// Zug ausführen; liefert die erbeuteten Samen (oder nil bei ungültigem Zug).
    @discardableResult
    public mutating func spiele(_ m: Int) -> Int? {
        guard zuege.contains(m) else { return nil }
        var n = mulden[m], pos = m; mulden[m] = 0
        while n > 0 { pos = (pos + 1) % 12; if pos == m { continue }; mulden[pos] += 1; n -= 1 }
        var beute = 0
        let gegner = 1 - amZug
        if Self.besitzer(pos) == gegner, (2...3).contains(mulden[pos]) {
            // Würde alles genommen (Grand Slam), gibt es nichts
            var kopie = mulden, p = pos, summe = 0
            while Self.besitzer(p) == gegner, (2...3).contains(kopie[p]) { summe += kopie[p]; kopie[p] = 0; p -= 1; if p < 0 { break } }
            let rest = (gegner * 6..<gegner * 6 + 6).reduce(0) { $0 + kopie[$1] }
            if rest > 0 || regeln.grandSlam { mulden = kopie; beute = summe }
        }
        vorrat[amZug] += beute
        ohneBeute = beute > 0 ? 0 : ohneBeute + 1
        amZug = gegner
        pruefeEnde()
        return beute
    }

    private mutating func pruefeEnde() {
        if vorrat[0] >= regeln.ziel || vorrat[1] >= regeln.ziel { vorbei = true; return }
        if zuege.isEmpty || ohneBeute >= 150 {
            // Wer nicht ziehen kann: Restsamen gehen an den Besitzer der Seite
            for s in 0..<2 { vorrat[s] += (s * 6..<s * 6 + 6).reduce(0) { $0 + mulden[$1] } }
            mulden = [Int](repeating: 0, count: 12)
            vorbei = true
        }
    }

    /// 0/1 oder nil bei 24:24.
    public var sieger: Int? { vorbei ? (vorrat[0] == vorrat[1] ? nil : (vorrat[0] > vorrat[1] ? 0 : 1)) : nil }
}

public enum OwareComputer {
    /// Alpha-Beta mit gegebener Tiefe (leicht 1, mittel 3, schwer 6).
    public static func wahl(_ o: Oware, tiefe: Int) -> Int? {
        let z = o.zuege
        guard !z.isEmpty else { return nil }
        let ich = o.amZug
        var best = z[0], bestW = -Int.max
        for m in z.shuffled() {
            var k = o; k.spiele(m)
            let w = -negamax(k, tiefe - 1, -Int.max, Int.max, ich)
            if w > bestW { bestW = w; best = m }
        }
        return best
    }

    private static func negamax(_ o: Oware, _ t: Int, _ alpha: Int, _ beta: Int, _ ich: Int) -> Int {
        let sicht = o.amZug == ich ? 1 : -1
        if o.vorbei || t <= 0 { return bewerte(o, ich) * (sicht == 1 ? 1 : -1) * 1 }
        var a = alpha
        var best = -Int.max
        for m in o.zuege {
            var k = o; k.spiele(m)
            // Perspektive: negamax aus Sicht des Spielers am Zug
            let w = -negamax(k, t - 1, -beta, -a, ich)
            best = max(best, w); a = max(a, w); if a >= beta { break }
        }
        return best
    }

    /// Bewertung aus Sicht von `ich`; der Aufrufer dreht das Vorzeichen für den Gegner.
    static func bewerte(_ o: Oware, _ ich: Int) -> Int {
        let diff = (o.vorrat[ich] - o.vorrat[1 - ich]) * 10
        let eigene = (ich * 6..<ich * 6 + 6).reduce(0) { $0 + o.mulden[$1] }
        let fremde = ((1 - ich) * 6..<(1 - ich) * 6 + 6).reduce(0) { $0 + o.mulden[$1] }
        return diff + (eigene - fremde)
    }
}
