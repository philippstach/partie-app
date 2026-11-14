// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import SpieleKern
@testable import SpielSudoku

private func grid(_ s: String) -> [UInt8] {
    s.filter { $0.isNumber || $0 == "." }.map { $0 == "." ? 0 : UInt8(String($0))! }
}

enum Samples {
    /// Das Beispielrätsel als `Puzzle` (Stufe leicht)
    static let raetsel = Puzzle(givens: puzzle, solution: solution, difficulty: .easy, seed: 1)
    static let puzzle = grid("""
    53..7.... 6..195... .98....6. 8...6...3 4..8.3..1 7...2...6 .6....28. ...419..5 ....8..79
    """)
    static let solution = grid("""
    534678912 672195348 198342567 859761423 426853791 713924856 961537284 287419635 345286179
    """)
    /// Fast leer, also mehrere Lösungen
    static let ambiguous = grid("""
    2.9.5.... .......1. 1........ ......... ......... ......... ......... ......... .........
    """)
}

struct SolverTests {
    @Test func loestBekanntesRaetsel() {
        #expect(Solver.solve(Samples.puzzle) == Samples.solution)
        #expect(Solver.countSolutions(Samples.puzzle) == 1)
    }

    @Test func erkenntMehrereLoesungen() {
        #expect(Solver.countSolutions(Samples.ambiguous) == 2)
        #expect(Solver.countSolutions([UInt8](repeating: 0, count: 81)) == 2)
    }

    @Test func erkenntUnloesbare() {
        var g = Samples.puzzle
        g[2] = 5 // 5 steht schon in der Zeile
        #expect(Solver.solve(g) == nil)
        // Zelle ohne Kandidaten, aber ohne direkten Widerspruch unter den Vorgaben
        var h = [UInt8](repeating: 0, count: 81)
        for c in 1...8 { h[c] = UInt8(c) }
        h[9] = 9 // Zelle 0 sieht 1–8 in der Zeile und die 9 in der Box
        #expect(Solver.solve(h) == nil)
        #expect(Solver.countSolutions(h) == 0)
    }

    @Test func zufallsgitterIstGueltigUndSeedbar() {
        var r1 = SplitMix64(seed: 42), r2 = SplitMix64(seed: 42)
        let a = Solver.randomSolvedGrid(using: &r1)
        let b = Solver.randomSolvedGrid(using: &r2)
        #expect(a == b)
        #expect(!a.contains(0))
        #expect(Solver.countSolutions(a) == 1)
        for unit in Units.all { #expect(Set(unit.map { a[$0] }).count == 9) }
    }
}
