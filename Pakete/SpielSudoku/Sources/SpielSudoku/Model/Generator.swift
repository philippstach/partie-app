// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum Difficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy, medium, hard, expert

    var id: String { rawValue }

    /// S9: Techniken, die diese Stufe neu dazubringt (Experte: die drei Techniken für Tipps)
    var newTechniques: [Technique] {
        switch self {
        case .easy: [.nakedSingle, .hiddenSingle]
        case .medium: [.pointing, .claiming, .nakedPair, .hiddenPair]
        case .hard: [.nakedTriple, .hiddenTriple, .xWing]
        case .expert: [.swordfish, .xyWing, .simpleColoring]
        }
    }

    var title: String {
        switch self {
        case .easy: String(localized: "Leicht")
        case .medium: String(localized: "Mittel")
        case .hard: String(localized: "Schwer")
        case .expert: String(localized: "Experte")
        }
    }

    var detail: String {
        switch self {
        case .easy: String(localized: "Nur einfache Einzelzahlen")
        case .medium: String(localized: "Dazu Paare und Linien-Tricks")
        case .hard: String(localized: "Dazu Tripel und X-Wing")
        case .expert: String(localized: "Braucht mehr als die üblichen Tricks")
        }
    }

    /// Stufe des Logik-Lösers (1…4)
    var level: Int {
        switch self {
        case .easy: 1
        case .medium: 2
        case .hard: 3
        case .expert: 4
        }
    }
}

/// Ein Rätsel mit seiner einzigen Lösung.
struct Puzzle: Codable, Equatable, Sendable {
    var givens: [UInt8]
    var solution: [UInt8]
    var difficulty: Difficulty
    var seed: UInt64

    init(givens: [UInt8], solution: [UInt8], difficulty: Difficulty, seed: UInt64) {
        self.givens = givens; self.solution = solution; self.difficulty = difficulty; self.seed = seed
    }

    /// Rätsel, Lösung und Stufe sind Pflicht (ohne sie ist das Rätsel unbrauchbar), der Seed ist freiwillig (F2)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        givens = try c.decode([UInt8].self, forKey: .givens)
        solution = try c.decode([UInt8].self, forKey: .solution)
        difficulty = try c.decode(Difficulty.self, forKey: .difficulty)
        seed = c.lenient(UInt64.self, .seed, default: 0, report: decoder.loadReport)
    }
}

enum Generator {
    /// Erzeugt ein eindeutig lösbares Rätsel der gewünschten Stufe.
    /// Gleicher Seed und gleiche Stufe ergeben immer dasselbe Rätsel.
    static func generate(_ difficulty: Difficulty, seed: UInt64) -> Puzzle {
        generateReporting(difficulty, seed: seed).puzzle
    }

    /// Wie `generate`, meldet aber auch die Zahl der Versuche und ob die gewünschte Stufe erreicht wurde
    /// (`reached == false`: nach 4000 Versuchen Ersatz-Rätsel, dessen Stufe abweichen kann). Für die Prüfung der Stufen.
    static func generateReporting(_ difficulty: Difficulty, seed: UInt64) -> (puzzle: Puzzle, attempts: Int, reached: Bool) {
        var rng = SplitMix64(seed: seed)
        var fallback: Puzzle?
        for attempt in 0..<4000 {
            let solution = Solver.randomSolvedGrid(using: &rng)
            let givens = dig(solution, difficulty: difficulty, using: &rng)
            let puzzle = Puzzle(givens: givens, solution: solution, difficulty: difficulty, seed: seed)
            // F7: Experte nimmt nur Rätsel, die mit den Techniken bis Stufe 4 ganz ohne Raten lösbar sind (und mehr als Stufe 3 brauchen)
            if Rating.level(of: givens, cap: difficulty.level) == difficulty.level,
               difficulty != .expert || Rating.isSolvableByLogic(givens, maxLevel: 4) {
                return (puzzle, attempt + 1, true)
            }
            if attempt == 0 { fallback = puzzle }
        }
        return (fallback!, 4000, false)
    }

    /// Nimmt paarweise (punktsymmetrisch) Zahlen weg, solange die Lösung eindeutig bleibt
    /// und das Rätsel nicht schwerer wird als gewünscht.
    private static func dig(_ solution: [UInt8], difficulty: Difficulty, using rng: inout SplitMix64) -> [UInt8] {
        var grid = solution
        // Leicht soll angenehm viele Vorgaben behalten
        let minClues = difficulty == .easy ? Int.random(in: 36...40, using: &rng) : 0
        let capped = difficulty != .expert
        var order = Array(0...40)
        order.shuffle(using: &rng)
        var clues = 81
        for i in order {
            let j = 80 - i
            if clues - (i == j ? 1 : 2) < minClues { continue }
            let (a, b) = (grid[i], grid[j])
            grid[i] = 0; grid[j] = 0
            let keeps = Solver.countSolutions(grid) == 1
                && (!capped || Rating.level(of: grid, cap: difficulty.level) <= difficulty.level)
            if keeps {
                clues -= (i == j ? 1 : 2)
            } else {
                grid[i] = a; grid[j] = b
            }
        }
        return grid
    }
}
