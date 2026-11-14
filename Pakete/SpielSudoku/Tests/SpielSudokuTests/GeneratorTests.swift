// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSudoku

struct GeneratorTests {
    @Test(arguments: Difficulty.allCases)
    func fuenfzigSeedsSindEindeutigUndPassenZurStufe(difficulty: Difficulty) {
        for seed in UInt64(1)...50 {
            let p = Generator.generate(difficulty, seed: seed)
            #expect(Solver.countSolutions(p.givens) == 1, "Seed \(seed) nicht eindeutig")
            #expect(Solver.solve(p.givens) == p.solution)
            #expect(Rating.level(of: p.givens, cap: 3) == difficulty.level, "Seed \(seed) passt nicht zu \(difficulty.title)")
            for i in 0..<81 where p.givens[i] != 0 { #expect(p.givens[i] == p.solution[i]) }
        }
    }

    @Test func gleicherSeedGleichesRaetsel() {
        for d in Difficulty.allCases {
            #expect(Generator.generate(d, seed: 7) == Generator.generate(d, seed: 7))
        }
        #expect(Generator.generate(.medium, seed: 7) != Generator.generate(.medium, seed: 8))
    }

    @Test func raetselSindPunktsymmetrisch() {
        let p = Generator.generate(.hard, seed: 3)
        for i in 0..<81 { #expect((p.givens[i] == 0) == (p.givens[80 - i] == 0)) }
    }

    /// Zeitmessung ist nur in optimierten Builds aussagekräftig (Debug ist um ein Vielfaches langsamer).
    private static var optimiert: Bool {
        #if DEBUG
        false
        #else
        true
        #endif
    }

    @Test(.enabled(if: optimiert, "Zeitmessung nur in Release-Builds")) func schwerDauertUnterEinerSekunde() {
        var worst = 0.0, total = 0.0
        for seed in UInt64(100)...109 {
            let t = Date()
            _ = Generator.generate(.hard, seed: seed)
            let dt = Date().timeIntervalSince(t)
            worst = max(worst, dt); total += dt
        }
        print("PERF schwer: schnitt \(total / 10) s, schlimmster \(worst) s")
        #expect(total / 10 < 1.0)
    }
}
