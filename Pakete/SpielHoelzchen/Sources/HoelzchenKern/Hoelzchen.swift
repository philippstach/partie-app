// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Hölzchen (Nim): Mehrere Reihen von Hölzchen. Wer dran ist, nimmt aus genau einer Reihe beliebig viele Hölzchen.
/// Normal gewinnt, wer das letzte nimmt; im Modus „Pechvogel“ verliert, wer das letzte nehmen muss.
public struct Hoelzchen: Equatable, Sendable, Codable {
    public enum Modus: String, Sendable, CaseIterable, Codable { case normal, misere }
    public private(set) var reihen: [Int]
    public let modus: Modus
    public private(set) var amZug = 0
    public private(set) var sieger: Int?
    private var verlauf: [Stand] = []
    private struct Stand: Codable, Equatable, Sendable { var reihen: [Int]; var amZug: Int }

    enum CodingKeys: String, CodingKey { case reihen, modus, amZug, sieger, verlauf }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        reihen = try c.decode([Int].self, forKey: .reihen); modus = try c.decode(Modus.self, forKey: .modus)
        amZug = try c.decode(Int.self, forKey: .amZug); sieger = try c.decodeIfPresent(Int.self, forKey: .sieger)
        verlauf = try c.decodeIfPresent([Stand].self, forKey: .verlauf) ?? []      // ältere Spielstände haben keinen Verlauf
    }

    public static let aufbauten: [[Int]] = [[1, 3, 5, 7], [3, 4, 5], [2, 3, 4, 5], [1, 2, 3, 4, 5]]

    public init(reihen: [Int], modus: Modus) { self.reihen = reihen; self.modus = modus }

    public var summe: Int { reihen.reduce(0, +) }

    @discardableResult
    public mutating func nimm(reihe r: Int, anzahl n: Int) -> Bool {
        guard sieger == nil, reihen.indices.contains(r), n >= 1, n <= reihen[r] else { return false }
        verlauf.append(Stand(reihen: reihen, amZug: amZug))
        reihen[r] -= n
        if summe == 0 { sieger = modus == .normal ? amZug : 1 - amZug } else { amZug = 1 - amZug }
        return true
    }

    /// Gibt es einen früheren Zug von `spieler`, den man zurücknehmen kann?
    public func kannZurueck(zumSpieler spieler: Int) -> Bool { verlauf.contains { $0.amZug == spieler } }

    /// Nimmt den letzten Zug von `spieler` zurück – samt allem, was danach kam (also auch den Zug des Computers).
    /// Danach ist `spieler` wieder am Zug.
    @discardableResult
    public mutating func zurueck(zumSpieler spieler: Int) -> Bool {
        guard let i = verlauf.lastIndex(where: { $0.amZug == spieler }) else { return false }
        let st = verlauf[i]
        guard st.reihen.count == reihen.count else { verlauf.removeSubrange(i...); return false }   // beschädigter Verlauf
        reihen = st.reihen; amZug = st.amZug; sieger = nil
        verlauf.removeSubrange(i...)
        return true
    }

    /// Bester Zug (Nim-Summe); `fehler` ist die Wahrscheinlichkeit, stattdessen einen zufälligen Zug zu machen.
    public func computerZug<G: RandomNumberGenerator>(fehler: Double, mit g: inout G) -> (reihe: Int, anzahl: Int)? {
        let moeglich = reihen.indices.filter { reihen[$0] > 0 }
        guard !moeglich.isEmpty else { return nil }
        func zufall() -> (Int, Int) { let r = moeglich.randomElement(using: &g)!; return (r, Int.random(in: 1...reihen[r], using: &g)) }
        if Double.random(in: 0..<1, using: &g) < fehler { return zufall() }
        let x = reihen.reduce(0, ^)
        let grosse = reihen.filter { $0 > 1 }.count
        if modus == .misere && grosse <= 1 {
            // Endspiel: so lassen, dass eine ungerade Zahl einzelner Hölzchen bleibt
            let einzel = reihen.filter { $0 == 1 }.count
            if let r = reihen.indices.first(where: { reihen[$0] > 1 }) {
                return (r, reihen[r] - (einzel % 2 == 0 ? 1 : 0))
            }
            return (moeglich[0], 1)
        }
        if x == 0 { return zufall() }
        for r in moeglich where reihen[r] ^ x < reihen[r] { return (r, reihen[r] - (reihen[r] ^ x)) }
        return zufall()
    }
}
