// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSudoku

/// Jedes Tagesrätsel muss eindeutig lösbar sein und am selben Tag immer gleich ausfallen.
/// Geprüft werden feste Tage über Monats-, Schaltjahr- und Jahreswechsel hinweg.
struct TagesraetselEindeutigTests {
    static let tage: [String] = {
        var t: [String] = []
        let cal = DailyPuzzle.gregorian
        for start in ["2026-11-08", "2027-12-20", "2028-02-20"] {
            var d = DailyPuzzle.date(from: start)!
            for _ in 0..<14 { t.append(DailyPuzzle.key(for: d)); d = cal.date(byAdding: .day, value: 1, to: d)! }
        }
        return t
    }()

    @Test func tageDeckenSchaltjahrUndJahreswechselAb() {
        #expect(Self.tage.contains("2028-02-29"))
        #expect(Self.tage.contains("2027-12-31") && Self.tage.contains("2028-01-01"))
    }

    @Test(arguments: TagesraetselEindeutigTests.tage)
    func tagesraetselIstEindeutigUndStabil(key: String) {
        let p = DailyPuzzle.puzzle(for: key)
        #expect(Solver.countSolutions(p.givens) == 1, "\(key) nicht eindeutig")
        #expect(Solver.solve(p.givens) == p.solution, "\(key): Lösung passt nicht")
        #expect(p == DailyPuzzle.puzzle(for: key), "\(key): am selben Tag muss dasselbe Rätsel kommen")
        #expect(p.difficulty == DailyPuzzle.difficulty)
        for i in 0..<81 where p.givens[i] != 0 { #expect(p.givens[i] == p.solution[i]) }
    }

    @Test func aufeinanderfolgendeTageSindVerschieden() {
        let ps = Self.tage.map { DailyPuzzle.puzzle(for: $0).givens }
        #expect(Set(ps.map { $0.map(String.init).joined() }).count == ps.count, "zwei Tage haben dasselbe Rätsel")
    }

    @Test func seedHaengtNurVomTagesschluesselAb() {
        #expect(DailyPuzzle.seed(for: "2026-11-08") == 20261108)
        #expect(DailyPuzzle.seed(for: "2028-02-29") == 20280229)
    }
}
