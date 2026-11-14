// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Schneller Lösungs-Suchlauf (Backtracking) mit Bitmasken.
/// Ein Gitter ist ein Array mit 81 Zahlen, 0 = leer.
enum Solver {
    /// Die erste gefundene Lösung oder `nil` (unlösbar oder widersprüchlich).
    static func solve(_ grid: [UInt8]) -> [UInt8]? {
        var search = Search(grid: grid, limit: 1)
        search?.run()
        return search?.solution
    }

    /// Zählt Lösungen und bricht bei `limit` ab (Standard 2: „eindeutig?“).
    static func countSolutions(_ grid: [UInt8], limit: Int = 2) -> Int {
        var search = Search(grid: grid, limit: limit)
        search?.run()
        return search?.count ?? 0
    }

    /// Ein zufälliges, vollständig gefülltes, gültiges Gitter.
    static func randomSolvedGrid(using rng: inout SplitMix64) -> [UInt8] {
        var search = Search(grid: [UInt8](repeating: 0, count: 81), limit: 1)!
        search.rng = rng
        search.run()
        rng = search.rng!
        return search.solution!
    }

    private struct Search {
        var values: [UInt8]
        var rowUsed = [UInt16](repeating: 0, count: 9)
        var colUsed = [UInt16](repeating: 0, count: 9)
        var boxUsed = [UInt16](repeating: 0, count: 9)
        let limit: Int
        var count = 0
        var solution: [UInt8]?
        /// Gesetzt = Ziffern in zufälliger Reihenfolge probieren
        var rng: SplitMix64?

        init?(grid: [UInt8], limit: Int) {
            guard grid.count == 81 else { return nil }
            values = grid
            self.limit = limit
            for i in 0..<81 where grid[i] != 0 {
                let bit = Mask.bit(Int(grid[i]))
                let r = Units.row(i), c = Units.col(i), b = Units.box(i)
                if (rowUsed[r] | colUsed[c] | boxUsed[b]) & bit != 0 { return nil }
                rowUsed[r] |= bit; colUsed[c] |= bit; boxUsed[b] |= bit
            }
        }

        mutating func run() {
            var best = -1
            var bestMask: UInt16 = 0
            var bestCount = 10
            for i in 0..<81 where values[i] == 0 {
                let mask = ~(rowUsed[Units.row(i)] | colUsed[Units.col(i)] | boxUsed[Units.box(i)]) & Mask.all
                let n = mask.nonzeroBitCount
                if n < bestCount {
                    best = i; bestMask = mask; bestCount = n
                    if n <= 1 { break }
                }
            }
            if best < 0 {
                count += 1
                if solution == nil { solution = values }
                return
            }
            if bestCount == 0 { return }

            var digits = Mask.digits(bestMask)
            if rng != nil { digits.shuffle(using: &rng!) }
            let r = Units.row(best), c = Units.col(best), b = Units.box(best)
            for d in digits {
                let bit = Mask.bit(d)
                values[best] = UInt8(d)
                rowUsed[r] |= bit; colUsed[c] |= bit; boxUsed[b] |= bit
                run()
                rowUsed[r] &= ~bit; colUsed[c] &= ~bit; boxUsed[b] &= ~bit
                values[best] = 0
                if count >= limit { return }
            }
        }
    }
}
