// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct Kante: Hashable, Sendable, Codable {
    public var waagrecht: Bool
    public var x: Int, y: Int
    public init(waagrecht: Bool, _ x: Int, _ y: Int) { self.waagrecht = waagrecht; self.x = x; self.y = y }
}

/// Kästchenjagd (Käsekästchen): Auf einem Punktegitter ziehen zwei Spieler abwechselnd eine Linie zwischen zwei benachbarten Punkten.
/// Wer ein Kästchen mit der vierten Seite schließt, bekommt es und zieht nochmal. Wer am Ende mehr Kästchen hat, gewinnt.
public struct Kaestchenjagd: Equatable, Sendable, Codable {
    public let breite: Int, hoehe: Int          // Anzahl Kästchen
    public private(set) var gezogen: [Kante: Int] = [:]          // Kante → Spieler (0 oder 1)
    public private(set) var besitzer: [[Int?]]
    public private(set) var punkte = [0, 0]
    public private(set) var amZug = 0
    public private(set) var letzte: Kante?

    public init(breite: Int, hoehe: Int) {
        self.breite = breite; self.hoehe = hoehe
        besitzer = Array(repeating: Array(repeating: nil, count: breite), count: hoehe)
    }

    public var alleKanten: [Kante] {
        (0...hoehe).flatMap { y in (0..<breite).map { Kante(waagrecht: true, $0, y) } } + (0..<hoehe).flatMap { y in (0...breite).map { Kante(waagrecht: false, $0, y) } }
    }
    public var freieKanten: [Kante] { alleKanten.filter { gezogen[$0] == nil } }
    public var vorbei: Bool { punkte[0] + punkte[1] == breite * hoehe }

    /// Seiten eines Kästchens (oben, unten, links, rechts).
    public func seiten(_ x: Int, _ y: Int) -> [Kante] {
        [Kante(waagrecht: true, x, y), Kante(waagrecht: true, x, y + 1), Kante(waagrecht: false, x, y), Kante(waagrecht: false, x + 1, y)]
    }
    public func zahlSeiten(_ x: Int, _ y: Int) -> Int { seiten(x, y).filter { gezogen[$0] != nil }.count }

    /// Kästchen, die an der Kante liegen.
    public func angrenzend(_ k: Kante) -> [(Int, Int)] {
        let c: [(Int, Int)] = k.waagrecht ? [(k.x, k.y - 1), (k.x, k.y)] : [(k.x - 1, k.y), (k.x, k.y)]
        return c.filter { (0..<breite).contains($0.0) && (0..<hoehe).contains($0.1) }
    }

    @discardableResult
    public mutating func ziehe(_ k: Kante) -> Bool {
        guard !vorbei, gezogen[k] == nil, alleKanten.contains(k) else { return false }
        gezogen[k] = amZug; letzte = k
        var gewonnen = 0
        for (x, y) in angrenzend(k) where zahlSeiten(x, y) == 4 { besitzer[y][x] = amZug; gewonnen += 1 }
        punkte[amZug] += gewonnen
        if gewonnen == 0 { amZug = 1 - amZug }
        return true
    }

    // MARK: Computer

    /// `stufe` 0 = zufällig (nimmt aber geschenkte Kästchen), 1 = vermeidet die dritte Seite, 2 = opfert zusätzlich die kleinste Kette.
    public func computerZug<G: RandomNumberGenerator>(stufe: Int, mit g: inout G) -> Kante? {
        let frei = freieKanten
        guard !frei.isEmpty else { return nil }
        // Schwere Stufe: Im Endspiel exakt durchrechnen (erkennt auch, wann man die letzten zwei Kästchen einer Kette stehen lässt).
        if stufe >= 2, frei.count <= Kaestchenjagd.exaktGrenze, let k = exakterZug(frei, mit: &g) { return k }
        let nimm = frei.filter { k in angrenzend(k).contains { zahlSeiten($0.0, $0.1) == 3 } }
        if !nimm.isEmpty {
            // Bei schwerer Stufe: nicht alles gierig nehmen am Ende einer langen Kette (vereinfacht: immer nehmen)
            return nimm.randomElement(using: &g)
        }
        if stufe == 0 { return frei.randomElement(using: &g) }
        let sicher = frei.filter { k in angrenzend(k).allSatisfy { zahlSeiten($0.0, $0.1) < 2 } }
        if !sicher.isEmpty { return sicher.randomElement(using: &g) }
        if stufe == 1 { return frei.randomElement(using: &g) }
        // Kleinste Kette verschenken: Zug, der dem Gegner die wenigsten Kästchen ermöglicht
        var bester = frei[0]; var wenigste = Int.max
        for k in frei {
            var t = self; t.amZug = 0; t.ziehe(k)
            var n = 0
            while let nk = t.freieKanten.first(where: { kk in t.angrenzend(kk).contains { t.zahlSeiten($0.0, $0.1) == 3 } }) { let v = t.punkte[0]; t.ziehe(nk); n += t.punkte[0] - v }
            if n < wenigste { wenigste = n; bester = k }
        }
        return bester
    }

    /// Bis zu dieser Zahl freier Kanten rechnet die schwere Stufe das Spiel bis zum Ende exakt durch.
    public static let exaktGrenze = 14

    /// Bester Zug nach vollständiger Suche (Ergebnis: Kästchendifferenz für den Spieler am Zug, mit Zwischenspeicher je Kantenmenge).
    func exakterZug<G: RandomNumberGenerator>(_ frei: [Kante], mit g: inout G) -> Kante? {
        let alle = alleKanten
        var index: [Kante: Int] = [:]
        for (i, k) in alle.enumerated() { index[k] = i }
        let anliegend: [[Int]] = alle.map { k in angrenzend(k).map { $0.1 * breite + $0.0 } }
        var seitenMaske: [Int] = []          // je Kästchen: die vier Kantenbits
        for y in 0..<hoehe { for x in 0..<breite { seitenMaske.append(seiten(x, y).reduce(0) { $0 | (1 << index[$1]!) }) } }
        var start = 0
        for (k, _) in gezogen { start |= 1 << index[k]! }
        var memo: [Int: Int] = [:]
        func wert(_ m: Int) -> Int {
            if let v = memo[m] { return v }
            var best = Int.min
            for e in 0..<alle.count where m & (1 << e) == 0 {
                let n = m | (1 << e)
                let gew = anliegend[e].filter { n & seitenMaske[$0] == seitenMaske[$0] }.count
                let v = gew > 0 ? gew + wert(n) : -wert(n)
                best = max(best, v)
            }
            let r = best == Int.min ? 0 : best
            memo[m] = r
            return r
        }
        var beste: [Kante] = []; var bw = Int.min
        for k in frei {
            let e = index[k]!, n = start | (1 << e)
            let gew = anliegend[e].filter { n & seitenMaske[$0] == seitenMaske[$0] }.count
            let v = gew > 0 ? gew + wert(n) : -wert(n)
            if v > bw { bw = v; beste = [k] } else if v == bw { beste.append(k) }
        }
        return beste.randomElement(using: &g)
    }
}
