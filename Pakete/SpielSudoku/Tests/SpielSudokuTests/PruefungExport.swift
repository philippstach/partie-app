// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import Testing
@testable import SpielSudoku

/// Prüfung der Stufen. Läuft nur auf Wunsch (sonst sofort fertig).
/// 1. `testExportFuerPruefung` (`TEST_RUNNER_SUDOKU_EXPORT=1`): je 500 Rätsel (Seeds 1…500) pro Stufe und 60 Tagesrätsel, zweimal erzeugt,
///    nach `/tmp/sudoku-pruefung/` (`raetsel_<stufe>.json`, `tagesraetsel.json`). Prüft `Referenz/pruefe_export.py` unabhängig.
///    `TEST_RUNNER_SUDOKU_EXPORT_STUFE=hard` begrenzt auf eine Stufe.
/// 2. `exportiereRaetsel` (`TEST_RUNNER_PRUEFUNG=hard|all`, `PRUEFUNG_ANZAHL`, `PRUEFUNG_TIPP`): Analyse mit Techniken des Logik-Lösers
///    und Tipp-Prüfung nach `/tmp/sudoku-pruefung/analyse_<stufe>.json`.
struct PruefungExport {
    private static var outputFolder: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Shared/pruefung")
    }
    private static var tmpFolder: URL { URL(fileURLWithPath: "/tmp/sudoku-pruefung") }

    private static func string(_ grid: [UInt8]) -> String { grid.map { String($0) }.joined() }

    /// Seeds: Stufe·100000 + Nummer, damit jede Stufe eigene Rätsel hat und alles nachvollziehbar bleibt
    static func seed(_ difficulty: Difficulty, _ index: Int) -> UInt64 { UInt64(difficulty.level * 100_000 + index) }

    /// Alle Schritte des Logik-Lösers (bis Stufe 4) für ein Rätsel
    private static func solveSteps(_ grid: [UInt8]) -> (counts: [String: Int], hardest: Technique?, solved: Bool, steps: Int) {
        var board = LogicBoard(grid: grid)
        var counts = [String: Int]()
        var hardest: Technique?
        var steps = 0
        while !board.isSolved, let step = board.nextStep(maxLevel: 4) {
            counts[String(describing: step.technique), default: 0] += 1
            if hardest == nil || step.technique.level > hardest!.level { hardest = step.technique }
            board.apply(step)
            steps += 1
        }
        return (counts, hardest, board.isSolved, steps)
    }

    private static func percentile(_ sorted: [Double], _ p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        return sorted[min(sorted.count - 1, Int(Double(sorted.count) * p))]
    }

    @Test func testExportFuerPruefung() throws {
        let env = ProcessInfo.processInfo.environment
        guard env["SUDOKU_EXPORT"] == "1" else { return }
        try FileManager.default.createDirectory(at: Self.tmpFolder, withIntermediateDirectories: true)
        let only = env["SUDOKU_EXPORT_STUFE"]
        // SUDOKU_EXPORT_STUFE=tage: nur die Tagesrätsel
        for difficulty in Difficulty.allCases where only == nil || only == difficulty.rawValue {
            var list = [[String: Any]]()
            for seed in 1...500 {
                let start = Date()
                let r = Generator.generateReporting(difficulty, seed: UInt64(seed))
                let ms = Int((Date().timeIntervalSince(start) * 1000).rounded())
                list.append(["seed": seed, "givens": Self.string(r.puzzle.givens), "solution": Self.string(r.puzzle.solution),
                             "difficulty": difficulty.rawValue, "attempts": r.attempts, "fallback": !r.reached, "ms": ms])
            }
            let data = try JSONSerialization.data(withJSONObject: list, options: [.sortedKeys])
            try data.write(to: Self.tmpFolder.appending(path: "raetsel_\(difficulty.rawValue).json"))
        }
        guard only == nil || only == "tage" else { return }
        // 60 Tagesrätsel ab 2026-10-01, jedes zweimal erzeugt
        var days = [[String: Any]]()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let first = calendar.date(from: DateComponents(year: 2026, month: 10, day: 1))!
        for offset in 0..<60 {
            let day = calendar.date(byAdding: .day, value: offset, to: first)!
            let key = DailyPuzzle.key(for: day, calendar: calendar)
            let start = Date()
            let a = DailyPuzzle.puzzle(for: key), b = DailyPuzzle.puzzle(for: key)
            days.append(["key": key, "seed": DailyPuzzle.seed(for: key), "givens": Self.string(a.givens), "solution": Self.string(a.solution),
                         "gleich": a == b, "ms": Int((Date().timeIntervalSince(start) * 500).rounded())])
        }
        try JSONSerialization.data(withJSONObject: ["tage": days], options: [.sortedKeys]).write(to: Self.tmpFolder.appending(path: "tagesraetsel.json"))
    }

    /// Gleicher Seed und gleiche Stufe ergeben immer dasselbe Rätsel (auch über `generateReporting`)
    @Test func generatorIstDeterministisch() {
        for difficulty in Difficulty.allCases {
            let a = Generator.generate(difficulty, seed: 17), b = Generator.generateReporting(difficulty, seed: 17).puzzle
            #expect(a == b && a == Generator.generate(difficulty, seed: 17))
        }
    }

    @Test func exportiereRaetsel() throws {
        let env = ProcessInfo.processInfo.environment
        guard let which = env["PRUEFUNG"] else { return }
        let count = Int(env["PRUEFUNG_ANZAHL"] ?? "") ?? 500
        let tippCount = Int(env["PRUEFUNG_TIPP"] ?? "") ?? 60
        let levels = which == "all" ? Difficulty.allCases : Difficulty.allCases.filter { $0.rawValue == which }
        try FileManager.default.createDirectory(at: Self.tmpFolder, withIntermediateDirectories: true)

        for difficulty in levels {
            var entries = [[String: Any]]()
            var times = [Double](), attemptsList = [Int]()
            var notReached = 0, notUnique = 0, ratingMismatch = 0
            var tipp = TippStats()
            for index in 1...count {
                let seed = Self.seed(difficulty, index)
                let start = Date()
                let result = Generator.generateReporting(difficulty, seed: seed)
                let ms = Date().timeIntervalSince(start) * 1000
                let puzzle = result.puzzle
                let unique = Solver.countSolutions(puzzle.givens) == 1 && Solver.solve(puzzle.givens) == puzzle.solution
                let rated = Rating.level(of: puzzle.givens)
                let solve = Self.solveSteps(puzzle.givens)
                if !result.reached { notReached += 1 }
                if !unique { notUnique += 1 }
                if rated != difficulty.level { ratingMismatch += 1 }
                times.append(ms); attemptsList.append(result.attempts)
                entries.append([
                    "seed": seed,
                    "stufe": difficulty.rawValue,
                    "startziffern": Self.string(puzzle.givens),
                    "loesung": Self.string(puzzle.solution),
                    "vorgaben": puzzle.givens.filter { $0 != 0 }.count,
                    "eindeutig": unique,
                    "bewertung": rated,
                    "stufe_erreicht": result.reached,
                    "versuche": result.attempts,
                    "erzeugung_ms": Int(ms.rounded()),
                    "loesbar_mit_techniken": solve.solved,
                    "schwerste_technik": solve.hardest.map { String(describing: $0) } ?? "",
                    "schritte": solve.steps,
                    "techniken": solve.counts,
                ])
                if index <= tippCount { tipp.add(Self.checkTips(puzzle, seed: seed)) }
            }
            let sortedTimes = times.sorted()
            let summary: [String: Any] = [
                "erzeugung_ms": ["min": Int(sortedTimes.first ?? 0), "median": Int(Self.percentile(sortedTimes, 0.5)),
                                 "p95": Int(Self.percentile(sortedTimes, 0.95)), "max": Int(sortedTimes.last ?? 0),
                                 "summe_s": Int(times.reduce(0, +) / 1000)],
                "versuche": ["median": attemptsList.sorted()[attemptsList.count / 2], "max": attemptsList.max() ?? 0],
                "stufe_nicht_erreicht": notReached,
                "nicht_eindeutig": notUnique,
                "bewertung_weicht_ab": ratingMismatch,
                "tipp_pruefung": tipp.json,
            ]
            let root: [String: Any] = [
                "beschreibung": "Prüfung der Stufen (iOS-Generator, feste Seeds \(difficulty.level)00001…). Je Rätsel: Startziffern und Lösung als 81 Ziffern (0 = leer), bewertung = Stufe des Logik-Lösers (Rating, 4 = braucht mehr als Stufe 3), techniken = Zahl der Schritte je Technik (Löser bis Stufe 4), versuche = Durchgänge im Generator, stufe_erreicht = false, wenn nach 4000 Versuchen das Ersatz-Rätsel genommen wurde.",
                "stufe": difficulty.rawValue,
                "anzahl": count,
                "zusammenfassung": summary,
                "raetsel": entries,
            ]
            let data = try JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys])
            try data.write(to: Self.tmpFolder.appending(path: "analyse_\(difficulty.rawValue).json"))
        }
    }

    // MARK: Tipp-Prüfung

    struct TippStats {
        var positions = 0, number = 0, eliminate = 0, fewest = 0
        var wrongPositions = 0, mistakeOK = 0
        var violations = [String]()
        var pathTips = 0, pathNumber = 0, pathEliminate = 0, pathFewest = 0

        mutating func add(_ o: TippStats) {
            positions += o.positions; number += o.number; eliminate += o.eliminate; fewest += o.fewest
            wrongPositions += o.wrongPositions; mistakeOK += o.mistakeOK
            pathTips += o.pathTips; pathNumber += o.pathNumber; pathEliminate += o.pathEliminate; pathFewest += o.pathFewest
            violations += o.violations
        }

        var json: [String: Any] {
            ["weg_tipps": pathTips, "weg_zahl": pathNumber, "weg_streichen": pathEliminate, "weg_wenigste": pathFewest,
             "stellungen": positions, "stellung_zahl": number, "stellung_streichen": eliminate, "stellung_wenigste": fewest,
             "falsche_zahlen_stellungen": wrongPositions, "falsche_zahlen_tipp_zeigt_fehler": mistakeOK,
             "verstoesse": violations.count, "verstoesse_beispiele": Array(violations.prefix(10))]
        }
    }

    /// Tipps (1) entlang der Tipp-Folge von Anfang bis Ende, (2) in 20 zufälligen Stellungen mit richtigen Zahlen,
    /// (3) in Stellungen mit 1–3 falschen Zahlen: dann muss der Tipp auf eine falsche Zahl zeigen.
    static func checkTips(_ puzzle: Puzzle, seed: UInt64) -> TippStats {
        var stats = TippStats()
        let solution = puzzle.solution
        var rng = SplitMix64(seed: seed &+ 7)
        func violation(_ text: String) { stats.violations.append("seed \(seed): \(text)") }

        // (1) Weg
        var board = Board(puzzle: puzzle)
        while !board.isFull {
            let tip = HintFinder.nextTip(values: board.values, solution: solution)
            guard let cell = tip.cell else { violation("Weg: keine Zelle"); break }
            stats.pathTips += 1
            switch tip.art { case .number: stats.pathNumber += 1; case .eliminate: stats.pathEliminate += 1; case .fewest: stats.pathFewest += 1 }
            if board.cells[cell].value != 0 || tip.digit != Int(solution[cell]) { violation("Weg: falsche Zelle/Ziffer \(cell)"); break }
            board.cells[cell].value = UInt8(tip.digit)
        }

        // (2) und (3): zufällige Stellungen
        let empties = (0..<81).filter { puzzle.givens[$0] == 0 }
        for round in 0..<20 {
            var b = Board(puzzle: puzzle)
            let fill = Int.random(in: 0..<empties.count, using: &rng)
            let shuffled = empties.shuffled(using: &rng)
            for c in shuffled.prefix(fill) { b.cells[c].value = solution[c] }
            let open = shuffled.dropFirst(fill)
            guard !open.isEmpty else { continue }
            guard let hint = HintFinder.hint(for: b, solution: solution) else { violation("Stellung \(round): kein Tipp"); continue }
            stats.positions += 1
            if hint.kind == .mistake || b.cells[hint.cell].value != 0 || hint.digit != Int(solution[hint.cell]) {
                violation("Stellung \(round): ungültiger Tipp Zelle \(hint.cell)")
            }
            let tip = HintFinder.nextTip(values: b.values, solution: solution)
            switch tip.art { case .number: stats.number += 1; case .eliminate: stats.eliminate += 1; case .fewest: stats.fewest += 1 }

            // falsche Zahlen in 1–3 offenen Zellen
            let wrongCount = min(open.count, Int.random(in: 1...3, using: &rng))
            var wrongCells = Set<Int>()
            for c in open.prefix(wrongCount) {
                let wrong = (1...9).filter { UInt8($0) != solution[c] }.randomElement(using: &rng)!
                b.cells[c].value = UInt8(wrong)
                wrongCells.insert(c)
            }
            stats.wrongPositions += 1
            if let h = HintFinder.hint(for: b, solution: solution), h.kind == .mistake, wrongCells.contains(h.cell), h.digit == Int(solution[h.cell]) {
                stats.mistakeOK += 1
            } else {
                violation("Stellung \(round): Tipp zeigt falsche Zahl nicht")
            }
        }
        return stats
    }
}
