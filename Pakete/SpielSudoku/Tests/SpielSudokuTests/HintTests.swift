// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSudoku

@MainActor
struct HintTests {
    @Test func tippZeigtZuerstAufFalscheZahl() {
        var board = Board(puzzle: Samples.raetsel)
        let i = board.cells.firstIndex { $0.isEmpty }!
        board.cells[i].value = Samples.solution[i] % 9 + 1
        let hint = HintFinder.hint(for: board, solution: Samples.solution)
        #expect(hint?.kind == .mistake)
        #expect(hint?.cell == i)
        #expect(hint?.digit == Int(Samples.solution[i]))
    }

    @Test func tippNenntTechnikUndZelleDesNaechstenSchritts() throws {
        let board = Board(puzzle: Samples.raetsel)
        let hint = try #require(HintFinder.hint(for: board, solution: Samples.solution))
        #expect(hint.kind == .step)
        #expect(board.cells[hint.cell].isEmpty)
        #expect(hint.digit == Int(Samples.solution[hint.cell]))
        #expect([Technique.nakedSingle, .hiddenSingle].contains(hint.technique))
        #expect(!hint.text.isEmpty)
    }

    @Test func tippZeigtMusterEinheitUndStreichKandidaten() throws {
        let p = Generator.generate(.hard, seed: 11)
        var board = Board(puzzle: p)
        let strikers: Set<Technique> = [.pointing, .claiming, .nakedPair, .hiddenPair, .nakedTriple, .hiddenTriple, .xWing]
        var sawStrike = false
        for _ in 0..<81 where !board.isFull {
            let hint = try #require(HintFinder.hint(for: board, solution: p.solution))
            if let t = hint.technique, strikers.contains(t) {
                sawStrike = true
                #expect(!hint.eliminations.isEmpty, "\(t): nennt die Kandidaten, die fallen")
                #expect(!hint.pattern.isEmpty, "\(t): hat ein Muster")
            }
            if hint.technique == .hiddenSingle {
                #expect(hint.unit.count == 9, "Hidden Single zeigt die ganze Einheit")
                #expect(hint.pattern.count >= 8)
            }
            #expect(!hint.pattern.contains(hint.cell), "Die Zielzelle gehört nicht zum Muster")
            board.cells[hint.cell].value = UInt8(hint.digit)
        }
        #expect(sawStrike)
    }

    @Test func tippErklaertAuchSchwereTechniken() throws {
        // Mittel-Rätsel: der erste Tipp passt zum Logik-Löser und trifft die Lösung
        let p = Generator.generate(.hard, seed: 11)
        var board = Board(puzzle: p)
        var techniques = Set<Technique>()
        for _ in 0..<81 where !board.isFull {
            let hint = try #require(HintFinder.hint(for: board, solution: p.solution))
            #expect(hint.digit == Int(p.solution[hint.cell]))
            if let t = hint.technique { techniques.insert(t) }
            board.cells[hint.cell].value = UInt8(hint.digit)
        }
        #expect(board.isFull)
        #expect(techniques.contains { $0.level >= 2 })
    }

}

struct DailyPuzzleTests {
    @Test func schluesselUndSeedAusDemDatum() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let date = cal.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 23, minute: 30))!
        let key = DailyPuzzle.key(for: date, calendar: cal)
        #expect(key == "2026-10-04")
        #expect(DailyPuzzle.seed(for: key) == 20261004)
        #expect(DailyPuzzle.date(from: key, calendar: cal) == cal.date(from: DateComponents(year: 2026, month: 10, day: 4)))
    }

    @Test func gleicherTagGleichesRaetsel() {
        #expect(DailyPuzzle.puzzle(for: "2026-10-04") == DailyPuzzle.puzzle(for: "2026-10-04"))
        #expect(DailyPuzzle.puzzle(for: "2026-10-04") != DailyPuzzle.puzzle(for: "2026-10-05"))
        #expect(DailyPuzzle.puzzle(for: "2026-10-04").difficulty == .medium)
    }
}

@MainActor
struct DailyStoreTests {
    static let noon = Date(timeIntervalSince1970: 1_790_000_000)

    /// W1d: Geister-Notizen: Tipp-Ziffern in den Musterzellen, beim XY-Flügel alle Kandidaten; bei Einzelschritten keine
    @Test func geisterNotizen() {
        var cands = [UInt16](repeating: 0, count: 81)
        cands[5] = Mask.bit(1) | Mask.bit(2); cands[6] = Mask.bit(2) | Mask.bit(3); cands[7] = Mask.bit(1) | Mask.bit(3) | Mask.bit(9)
        let xy = HintFinder.ghosts(technique: .xyWing, pattern: [5, 6, 7], digits: Mask.bit(3), candidates: cands)
        #expect(xy[5] == cands[5] && xy[6] == cands[6] && xy[7] == cands[7])
        let pair = HintFinder.ghosts(technique: .nakedPair, pattern: [6, 7], digits: Mask.bit(3), candidates: cands)
        #expect(pair == [6: Mask.bit(3), 7: Mask.bit(3)])
        #expect(HintFinder.ghosts(technique: .nakedSingle, pattern: [5], digits: Mask.bit(1), candidates: cands).isEmpty)
    }

    /// W1c: Die komplette Tipp-Folge von 16 Rätseln stimmt mit der Referenz überein (`Shared/regeltests/tipps.json`)
    @Test func tippFolgeStimmtMitDerReferenzUeberein() throws {
        var arten = Set<String>(), techniken = Set<String>(), tipps = 0
        for c in try Regeltests.cases("tipps") {
            let name = c["name"] as! String
            let grid = Regeltests.grid(c["raetsel"] as! String)
            let solution = try #require(Solver.solve(grid))
            var values = grid
            for (i, e) in (c["tipps"] as! [[String: Any]]).enumerated() {
                let label = "\(name) Tipp \(i + 1)"
                let tip = HintFinder.nextTip(values: values, solution: solution)
                let art = e["art"] as! String
                arten.insert(art)
                let expected: HintFinder.Tip.Art = art == "zahl" ? .number : art == "streichen" ? .eliminate : .fewest
                #expect(tip.art == expected, "\(label): Art")
                #expect(tip.cell == e["zelle"] as? Int, "\(label): Zelle")
                #expect(tip.digit == e["ziffer"] as? Int, "\(label): Ziffer")
                if art != "zahl" { #expect(tip.possibilities == e["moeglichkeiten"] as? Int, "\(label): Möglichkeiten") }
                if let s = e["schritt"] as? [String: Any] {
                    let step = try #require(tip.step, "\(label): Schritt fehlt")
                    techniken.insert(String(describing: step.technique))
                    #expect(String(describing: step.technique) == s["technik"] as! String, "\(label): Technik")
                    #expect(step.pattern == s["muster"] as! [Int], "\(label): Muster")
                    #expect(Mask.digits(step.digits) == s["ziffern"] as! [Int], "\(label): Ziffern")
                    #expect(step.unit == s["einheit"] as? Int, "\(label): Einheit")
                    #expect(step.color0 == (s["farbe_0"] as? [Int] ?? []), "\(label): Farbe 0")
                    let removed = (s["streichen"] as? [[String: Any]] ?? []).map {
                        "\($0["zelle"] as! Int):\(($0["ziffern"] as! [Int]).map(String.init).joined(separator: ","))"
                    }
                    #expect(step.eliminations.map { "\($0.cell):\(Mask.digits($0.mask).map(String.init).joined(separator: ","))" } == removed,
                            "\(label): Streichen")
                } else {
                    #expect(tip.step == nil, "\(label): kein Schritt erwartet")
                }
                values[tip.cell!] = UInt8(tip.digit)
                tipps += 1
            }
            #expect(!values.contains(0), "\(name): am Ende voll")
        }
        #expect(tipps > 800)
        #expect(arten == ["zahl", "streichen"] || arten.contains("streichen"), "Arten: \(arten)")
        #expect(techniken.contains("swordfish") || techniken.contains("xyWing"), "Techniken: \(techniken)")
    }

    /// Der Tipp (Darstellung) stimmt mit der Tipp-Regel überein; ohne Zahl in Sicht kommt der Probieren-Satz dazu
    @Test func tippAnzeigeFolgtDerRegel() throws {
        for c in try Regeltests.cases("tipps") {
            let grid = Regeltests.grid(c["raetsel"] as! String)
            let solution = try #require(Solver.solve(grid))
            var board = Board(puzzle: Puzzle(givens: grid, solution: solution, difficulty: .expert, seed: 0))
            for e in c["tipps"] as! [[String: Any]] {
                let hint = try #require(HintFinder.hint(for: board, solution: solution))
                #expect(hint.cell == e["zelle"] as? Int && hint.digit == e["ziffer"] as? Int)
                let art = e["art"] as! String
                #expect((hint.kind == .step) == (art == "zahl"))
                if art == "streichen" { #expect(hint.technique != nil && hint.note?.contains("Probieren") == true) }
                board.cells[hint.cell].value = UInt8(hint.digit)
            }
        }
    }
}
