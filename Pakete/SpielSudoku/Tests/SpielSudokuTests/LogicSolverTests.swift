// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
@testable import SpielSudoku

private func grid(_ s: String) -> [UInt8] { s.map { UInt8(String($0))! } }

/// Alle Techniken, die der Logik-Löser auf dem Weg zur Lösung braucht (einfachste zuerst).
private func techniquesUsed(_ g: [UInt8]) -> (techniques: Set<Technique>, solved: Bool, values: [UInt8]) {
    var board = LogicBoard(grid: g)
    var used = Set<Technique>()
    while !board.isSolved, let step = board.nextStep() {
        used.insert(step.technique)
        board.apply(step)
    }
    return (used, board.isSolved, board.values)
}

struct LogicSolverTests {
    @Test func einzelneZahlen() {
        let r = techniquesUsed(Samples.puzzle)
        #expect(r.solved)
        #expect(r.values == Samples.solution)
        #expect(r.techniques.isSubset(of: [.nakedSingle, .hiddenSingle]))
        #expect(Rating.level(of: Samples.puzzle) == 1)
    }

    @Test func versteckteEinzelzahl() {
        // Unter den leichten Rätseln gibt es solche, die versteckte Einzelzahlen brauchen
        var seen = Set<Technique>()
        for seed in UInt64(1)...30 {
            let p = Generator.generate(.easy, seed: seed)
            let r = techniquesUsed(p.givens)
            #expect(r.solved)
            #expect(r.techniques.isSubset(of: [.nakedSingle, .hiddenSingle]))
            seen.formUnion(r.techniques)
        }
        #expect(seen.contains(.hiddenSingle))
        // Gezielt: In Zeile 1 passt die 9 nur in Spalte 9, weil sie in allen anderen Spalten schon steht
        var g = [UInt8](repeating: 0, count: 81)
        for c in 0..<8 { g[(c + 1) * 9 + c] = 9 }
        let step = LogicBoard(grid: g).nextStep()
        #expect(step?.placement?.digit == 9)
        #expect(step?.placement?.cell == 8)
    }

    @Test func zeigendesPaarUndNacktesPaar() {
        let g = grid("008300004400007030630005000300069701070000060205710003000900086010400007900003400")
        let r = techniquesUsed(g)
        #expect(r.solved)
        #expect(r.techniques.contains(.pointing))
        #expect(r.techniques.contains(.nakedPair))
        #expect(Solver.solve(g) == r.values)
    }

    @Test func beanspruchteLinieUndNacktesTripel() {
        let g = grid("040005008002008930800900200060040100000000000007030090006007001081200700700500020")
        let r = techniquesUsed(g)
        #expect(r.solved)
        #expect(r.techniques.contains(.claiming))
        #expect(r.techniques.contains(.nakedTriple))
        #expect(Rating.level(of: g) == 3)
    }

    @Test func xWingUndVerstecktesPaar() {
        let g = grid("160000000000026510078900000050200840009070200042005060000008320026490000000000094")
        let r = techniquesUsed(g)
        #expect(r.solved)
        #expect(r.techniques.contains(.xWing))
        #expect(r.techniques.contains(.hiddenPair))
        #expect(Solver.solve(g) == r.values)
    }

    @Test func verstecktesTripel() {
        let g = grid("600000910200001000000070028000032500010704080004180000870090000000500002023000006")
        let r = techniquesUsed(g)
        #expect(r.solved)
        #expect(r.techniques.contains(.hiddenTriple))
    }

    @Test func expertBrauchtMehrAlsDieBekanntenTechniken() {
        let p = Generator.generate(.expert, seed: 5)
        #expect(Rating.level(of: p.givens) == 4)
        #expect(Solver.countSolutions(p.givens) == 1)
    }

    @Test func schritteStreichenNurFalscheKandidaten() {
        // Jeder Schritt des Logik-Lösers stimmt mit der echten Lösung überein
        let p = Generator.generate(.hard, seed: 11)
        var board = LogicBoard(grid: p.givens)
        while !board.isSolved, let step = board.nextStep() {
            if let place = step.placement { #expect(UInt8(place.digit) == p.solution[place.cell]) }
            for e in step.eliminations {
                #expect(e.mask & Mask.bit(Int(p.solution[e.cell])) == 0, "\(step.technique) streicht eine richtige Zahl")
            }
            board.apply(step)
        }
    }
}
