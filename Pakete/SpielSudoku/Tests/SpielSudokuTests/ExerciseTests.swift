// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielSudoku

/// W2 Technik-Training: feste Übungen aus `Shared/uebungen.json`
@MainActor
struct ExerciseTests {
    @Test func bundleUndSharedSindGleich() throws {
        let shared = Regeltests.folder.deletingLastPathComponent().appending(path: "uebungen.json")
        let bundled = Regeltests.folder.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appending(path: "App/Ressourcen/Daten/uebungen.json")
        #expect(try Data(contentsOf: shared) == Data(contentsOf: bundled), "Tools/make_exercises.sh ausführen: Shared und App-Kopie weichen ab")
    }

    @Test func zwoelfTechnikenMitJeSechsUebungen() {
        #expect(Exercises.all.count == 12)
        for technique in Technique.allCases {
            #expect(Exercises.series(for: technique).map(\.nr) == [1, 2, 3, 4, 5, 6], "\(technique)")
        }
    }

    /// Von jedem Stand liefert der Löser genau den Zielschritt, und die Lösung gehört zum Feld
    @Test func jedeUebungLiefertGenauDenZielschritt() throws {
        var count = 0
        for technique in Technique.allCases {
            for exercise in Exercises.series(for: technique) {
                let label = "\(technique) \(exercise.nr)"
                let target = exercise.schritt
                let step = try #require(exercise.step, "\(label): kein Schritt")
                #expect(String(describing: step.technique) == target.technik, "\(label): Technik")
                #expect(step.pattern == target.muster, "\(label): Muster")
                #expect(Mask.digits(step.digits) == target.ziffern, "\(label): Ziffern")
                #expect(step.unit == target.einheit, "\(label): Einheit")
                #expect(step.color0 == (target.farbe0 ?? []), "\(label): Farbe 0")
                #expect(step.placement?.cell == target.setzen?.zelle && step.placement?.digit == target.setzen?.ziffer, "\(label): Setzen")
                let removed = (target.streichen ?? []).map { "\($0.zelle):\($0.ziffern.map(String.init).joined(separator: ","))" }
                let actual = step.eliminations.map { "\($0.cell):\(Mask.digits($0.mask).map(String.init).joined(separator: ","))" }
                #expect(actual == removed, "\(label): Streichen")
                #expect(Solver.solve(exercise.values).map { $0 == exercise.solution } == true, "\(label): Lösung gehört zum Feld")
                var start = Board(puzzle: exercise.puzzle(for: technique))
                for (i, mask) in exercise.masks.enumerated() where start.cells[i].isEmpty { start.cells[i].notes = mask }
                #expect(!exercise.isDone(on: start), "\(label): mit den Notizen der Übung noch nicht erledigt")
                count += 1
            }
        }
        #expect(count == 72)
    }

}
