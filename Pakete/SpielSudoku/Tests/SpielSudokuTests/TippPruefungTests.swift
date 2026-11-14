// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import Testing
@testable import SpielSudoku

/// P2: Der Tipp findet in jeder Stellung einen richtigen Schritt (Schwer und Experte), auch mit falschen Ziffern und Notizen,
/// und die Tipp-Folge endet immer (keine Endlosschleife).
struct TippPruefungTests {
    @Test func tippFindetImmerEinenSchritt() throws {
        var positions = 0, mistakes = 0, steps = 0, guesses = 0, tipsApplied = 0
        for difficulty in [Difficulty.hard, .expert] {
            for seed in 1...25 {
                let puzzle = Generator.generate(difficulty, seed: UInt64(seed))
                let solution = puzzle.solution
                var rng = SplitMix64(seed: UInt64(difficulty.level * 1000 + seed))
                let empties = (0..<81).filter { puzzle.givens[$0] == 0 }
                for round in 0..<20 {
                    let label = "\(difficulty.rawValue) Seed \(seed) Stellung \(round)"
                    var board = Board(puzzle: puzzle)
                    let order = empties.shuffled(using: &rng)
                    let fill = Int.random(in: 0..<order.count, using: &rng)
                    for c in order.prefix(fill) { board.cells[c].value = solution[c] }
                    // 0–3 falsche Ziffern in offenen Zellen
                    let open = Array(order.dropFirst(fill))
                    let wrongCount = min(open.count, Int.random(in: 0...3, using: &rng))
                    var wrong = Set<Int>()
                    for c in open.prefix(wrongCount) {
                        board.cells[c].value = UInt8((1...9).filter { UInt8($0) != solution[c] }.randomElement(using: &rng)!)
                        wrong.insert(c)
                    }
                    // zufällige Notizen in anderen offenen Zellen, auch falsche (ohne die Lösungsziffer)
                    var noted = board
                    for c in open.dropFirst(wrongCount).prefix(15) { noted.cells[c].notes = UInt16.random(in: 0..<512, using: &rng) }
                    guard !board.isFull else { continue }
                    positions += 1

                    let hint = try #require(HintFinder.hint(for: board, solution: solution), "\(label): kein Tipp")
                    #expect(HintFinder.hint(for: noted, solution: solution) == hint, "\(label): Notizen ändern den Tipp")
                    switch hint.kind {
                    case .mistake:
                        mistakes += 1
                        #expect(wrong.contains(hint.cell), "\(label): .mistake zeigt auf eine richtige Zelle")
                        #expect(hint.digit == Int(solution[hint.cell]), "\(label): falsche Lösungsziffer")
                    case .step, .guess:
                        if hint.kind == .step { steps += 1 } else { guesses += 1 }
                        #expect(wrong.isEmpty, "\(label): Tipp ignoriert falsche Zahlen")
                        #expect(board.cells[hint.cell].value == 0, "\(label): Zelle nicht leer")
                        #expect(hint.digit == Int(solution[hint.cell]), "\(label): falsche Lösungsziffer")
                        for e in hint.eliminations {
                            #expect(e.mask & Mask.bit(Int(solution[e.cell])) == 0, "\(label): Streichung entfernt die Lösungsziffer in Zelle \(e.cell)")
                        }
                    }

                    // Von hier aus immer „zweite Stufe“ (Zahl eintragen), bis das Feld fertig ist
                    var guardCount = 0
                    while !board.isFull {
                        guardCount += 1
                        guard guardCount <= 81 + wrongCount else { Issue.record("\(label): Endlosschleife"); break }
                        guard let h = HintFinder.hint(for: board, solution: solution) else { Issue.record("\(label): Tipp fehlt mitten drin"); break }
                        board.cells[h.cell].value = UInt8(h.digit)
                        tipsApplied += 1
                    }
                    #expect(board.values == solution, "\(label): Folge endet nicht in der Lösung")
                }
            }
        }
        #expect(positions > 900 && mistakes > 100 && steps > 100, "positions \(positions) mistakes \(mistakes) steps \(steps) guesses \(guesses)")
    }
}
