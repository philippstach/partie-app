// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Turm von Hanoi: Scheiben (1 = kleinste) von Stab 0 auf den letzten Stab versetzen; nie eine größere auf eine kleinere.
public struct Hanoi: Equatable, Sendable, Codable {
    public let scheiben: Int
    /// Zahl der Stäbe: 3 klassisch, 4 für „Reve’s Puzzle“ (Ziel ist immer der letzte Stab).
    public let anzahlStaebe: Int
    public private(set) var staebe: [[Int]]
    public private(set) var zuege = 0
    private var verlauf: [Schritt] = []
    private struct Schritt: Equatable, Sendable, Codable { let von: Int; let nach: Int }
    public var kannZurueck: Bool { !verlauf.isEmpty }

    public init(scheiben: Int, staebe anzahl: Int = 3) {
        self.scheiben = scheiben; anzahlStaebe = anzahl
        staebe = [Array((1...scheiben).reversed())] + Array(repeating: [], count: anzahl - 1)
    }

    private enum CodingKeys: String, CodingKey { case scheiben, anzahlStaebe, staebe, zuege, verlauf }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        scheiben = try c.decode(Int.self, forKey: .scheiben)
        staebe = try c.decode([[Int]].self, forKey: .staebe)
        anzahlStaebe = try c.decodeIfPresent(Int.self, forKey: .anzahlStaebe) ?? staebe.count
        zuege = try c.decodeIfPresent(Int.self, forKey: .zuege) ?? 0
        verlauf = try c.decodeIfPresent([Schritt].self, forKey: .verlauf) ?? []
    }

    public var geloest: Bool { staebe[anzahlStaebe - 1].count == scheiben }
    /// Kürzeste Zugzahl: 2ⁿ − 1 bei drei Stäben, bei vier nach Frame-Stewart (bewiesen optimal für Hanoi mit 4 Stäben).
    public var minimum: Int { Hanoi.minimum(scheiben: scheiben, staebe: anzahlStaebe) }
    public static func minimum(scheiben n: Int, staebe k: Int) -> Int {
        if n <= 0 { return 0 }
        if k == 3 { return (1 << n) - 1 }
        var best = Int.max
        for m in 0..<n { best = min(best, 2 * minimum(scheiben: m, staebe: k) + (1 << (n - m)) - 1) }
        return best
    }

    public func moeglich(von a: Int, nach b: Int) -> Bool {
        guard a != b, staebe.indices.contains(a), staebe.indices.contains(b), let s = staebe[a].last else { return false }
        return staebe[b].last.map { s < $0 } ?? true
    }

    @discardableResult
    public mutating func ziehe(von a: Int, nach b: Int) -> Bool {
        guard moeglich(von: a, nach: b) else { return false }
        staebe[b].append(staebe[a].removeLast()); zuege += 1; verlauf.append(Schritt(von: a, nach: b))
        return true
    }

    /// Nimmt den letzten Zug zurück (zählt wieder ab).
    @discardableResult
    public mutating func zurueck() -> Bool {
        guard let l = verlauf.popLast() else { return false }
        // Beschädigter Verlauf (alter oder kaputter Spielstand): Schritt ignorieren statt abstürzen.
        guard staebe.indices.contains(l.von), staebe.indices.contains(l.nach), !staebe[l.nach].isEmpty else { return false }
        staebe[l.von].append(staebe[l.nach].removeLast()); zuege -= 1
        return true
    }

    /// Tipp: nächster Zug auf einem kürzesten Weg zur Lösung (Breitensuche über alle Stellungen, höchstens 3^n).
    public func hinweis() -> (von: Int, nach: Int)? {
        guard !geloest else { return nil }
        func schluessel(_ st: [[Int]]) -> [Int] {
            var peg = Array(repeating: 0, count: scheiben)
            for (i, stab) in st.enumerated() { for s in stab { peg[s - 1] = i } }
            return peg
        }
        let ziel = Array(repeating: anzahlStaebe - 1, count: scheiben)
        var vorgaenger: [[Int]: ([Int], Int, Int)] = [:]
        let start = schluessel(staebe)
        var queue = [(start, staebe)]; var i = 0
        var gesehen: Set<[Int]> = [start]
        while i < queue.count {
            let (k, st) = queue[i]; i += 1
            if k == ziel {
                var cur = k
                while let (vor, a, b) = vorgaenger[cur], vor != start { cur = vor; _ = (a, b) }
                if let (_, a, b) = vorgaenger[cur] { return (a, b) }
                return nil
            }
            for a in 0..<anzahlStaebe { for b in 0..<anzahlStaebe where a != b {
                guard let s = st[a].last, st[b].last.map({ s < $0 }) ?? true else { continue }
                var n = st; n[b].append(n[a].removeLast())
                let nk = schluessel(n)
                if gesehen.insert(nk).inserted { vorgaenger[nk] = (k, a, b); queue.append((nk, n)) }
            } }
        }
        return nil
    }
}
