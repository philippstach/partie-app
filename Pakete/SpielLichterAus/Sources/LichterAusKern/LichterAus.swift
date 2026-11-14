// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Lichter aus: Ein Tipp schaltet das Feld und seine vier Nachbarn um. Ziel: alle Lichter aus.
public struct LichterAus: Equatable, Sendable, Codable {
    /// Wirkungsmuster eines Tipps.
    public enum Muster: String, Sendable, Codable, CaseIterable {
        case kreuz      // Feld + 4 Nachbarn (klassisch)
        case diagonal   // Feld + 4 Diagonalen (Läufer-Muster)
        case rund       // Feld + alle 8 Nachbarn
        public var abstaende: [(Int, Int)] {
            switch self {
            case .kreuz: [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)]
            case .diagonal: [(0, 0), (1, 1), (-1, -1), (1, -1), (-1, 1)]
            case .rund: [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)]
            }
        }
    }
    public let n: Int
    public let muster: Muster
    public private(set) var an: [Bool]
    public private(set) var zuege = 0

    public init(n: Int = 5, muster: Muster = .kreuz) { self.n = n; self.muster = muster; an = Array(repeating: false, count: n * n) }

    private enum CodingKeys: String, CodingKey { case n, muster, an, zuege }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        n = try c.decode(Int.self, forKey: .n)
        muster = try c.decodeIfPresent(Muster.self, forKey: .muster) ?? .kreuz
        an = try c.decode([Bool].self, forKey: .an)
        zuege = try c.decodeIfPresent(Int.self, forKey: .zuege) ?? 0
    }

    public var geschafft: Bool { !an.contains(true) }
    public var anzahlAn: Int { an.filter { $0 }.count }

    private mutating func umschalten(_ i: Int) {
        let z = i / n, s = i % n
        for (dz, ds) in muster.abstaende {
            let zz = z + dz, ss = s + ds
            if (0..<n).contains(zz), (0..<n).contains(ss) { an[zz * n + ss].toggle() }
        }
    }

    public mutating func tippe(_ i: Int) { guard an.indices.contains(i) else { return }; umschalten(i); zuege += 1 }

    /// Mischt mit zufälligen Tipps aus dem gelösten Zustand (immer lösbar).
    public mutating func mischen<G: RandomNumberGenerator>(tipps: Int = 12, mit g: inout G) {
        an = Array(repeating: false, count: n * n)
        for i in (0..<(n * n)).shuffled(using: &g).prefix(tipps) { umschalten(i) }
        if geschafft { umschalten(0) }
        zuege = 0
    }

    /// Tipp: ein Feld, das zu einer kürzesten Lösung gehört (Lösung über Gauß-Verfahren mod 2, unter allen Lösungen die mit den wenigsten Tipps).
    public func hinweis() -> Int? {
        let m = n * n
        guard m <= 63, !geschafft else { return nil }
        // Zeile i: welche Tipps schalten Lampe i um (Bits 0…m-1), Bit m = Zielzustand (Lampe an → muss umgeschaltet werden)
        var zeilen: [UInt64] = (0..<m).map { i in
            var r: UInt64 = 0
            let z = i / n, s = i % n
            for (dz, ds) in muster.abstaende {
                let zz = z + dz, ss = s + ds
                if (0..<n).contains(zz), (0..<n).contains(ss) { r |= 1 << UInt64(zz * n + ss) }
            }
            if an[i] { r |= 1 << UInt64(m) }
            return r
        }
        var pivotSpalte: [Int] = []; var reihe = 0
        for spalte in 0..<m {
            guard let p = (reihe..<m).first(where: { zeilen[$0] & (1 << UInt64(spalte)) != 0 }) else { continue }
            zeilen.swapAt(reihe, p)
            for k in 0..<m where k != reihe && zeilen[k] & (1 << UInt64(spalte)) != 0 { zeilen[k] ^= zeilen[reihe] }
            pivotSpalte.append(spalte); reihe += 1
        }
        if (reihe..<m).contains(where: { zeilen[$0] == 1 << UInt64(m) }) { return nil }       // nicht lösbar
        let freie = (0..<m).filter { !pivotSpalte.contains($0) }
        var beste: [Int]?
        for maske in 0..<(1 << min(freie.count, 12)) {
            var x = Array(repeating: false, count: m)
            for (k, f) in freie.enumerated() where k < 12 && maske & (1 << k) != 0 { x[f] = true }
            for (r, sp) in pivotSpalte.enumerated() {
                var wert = zeilen[r] & (1 << UInt64(m)) != 0
                for f in freie where x[f] && zeilen[r] & (1 << UInt64(f)) != 0 { wert.toggle() }
                x[sp] = wert
            }
            let tipps = (0..<m).filter { x[$0] }
            if beste == nil || tipps.count < beste!.count { beste = tipps }
        }
        return beste?.first
    }
}
