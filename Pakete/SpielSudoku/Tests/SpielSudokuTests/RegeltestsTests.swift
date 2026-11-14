// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import Testing
@testable import SpielSudoku

/// Liest die gemeinsamen Testfälle aus `Shared/regeltests/` (dieselben wie bei Android und in der Python-Referenz).
enum Regeltests {
    static var folder: URL {
        // …/iOS/SudokuTests/Datei.swift → …/Shared/regeltests
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Shared/regeltests")
    }

    static func cases(_ file: String) throws -> [[String: Any]] {
        let data = try Data(contentsOf: folder.appending(path: "\(file).json"))
        let root = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try #require(root["faelle"] as? [[String: Any]])
    }

    static func grid(_ s: String) -> [UInt8] { s.map { UInt8(String($0))! } }
}

struct RegeltestsTests {
    @Test func loesen() throws {
        let cases = try Regeltests.cases("loesen")
        #expect(!cases.isEmpty)
        for c in cases {
            let name = c["name"] as! String
            let grid = Regeltests.grid(c["raetsel"] as! String)
            #expect(Solver.countSolutions(grid) == c["anzahl_loesungen"] as! Int, "\(name): Anzahl der Lösungen")
            if let solution = c["loesung"] as? String {
                let solved = Solver.solve(grid)
                #expect(solved.map { $0.map(String.init).joined() } == solution, "\(name): Lösung")
            }
            if let solvable = c["loesbar"] as? Bool {
                #expect((Solver.solve(grid) != nil) == solvable, "\(name): lösbar")
            }
        }
    }

    @Test func bewertung() throws {
        let cases = try Regeltests.cases("bewertung")
        #expect(!cases.isEmpty)
        for c in cases {
            let name = c["name"] as! String
            let grid = Regeltests.grid(c["raetsel"] as! String)
            #expect(Rating.level(of: grid, cap: 3) == c["stufe"] as! Int, "\(name): Stufe")
            #expect(Rating.level(of: grid, cap: 1) == c["stufe_mit_obergrenze_1"] as! Int, "\(name): Stufe mit Obergrenze 1")
        }
    }

    /// Jeder Schritt des Logik-Lösers gleich der Referenz (`file`), mit Techniken bis `maxLevel`
    private func verifySteps(_ file: String, maxLevel: Int) throws {
        let cases = try Regeltests.cases(file)
        #expect(!cases.isEmpty)
        var steps = 0
        for c in cases {
            let name = c["name"] as! String
            var board = LogicBoard(grid: Regeltests.grid(c["raetsel"] as! String))
            let expected = c["schritte"] as! [[String: Any]]
            var index = 0
            while !board.isSolved, let step = board.nextStep(maxLevel: maxLevel) {
                guard index < expected.count else {
                    Issue.record("\(name): mehr Schritte als erwartet")
                    break
                }
                let e = expected[index]
                let label = "\(name) Schritt \(index + 1)"
                #expect(String(describing: step.technique) == e["technik"] as! String, "\(label): Technik")
                #expect(step.pattern == e["muster"] as! [Int], "\(label): Muster")
                #expect(Mask.digits(step.digits) == e["ziffern"] as! [Int], "\(label): Ziffern")
                #expect(step.unit == e["einheit"] as? Int, "\(label): Einheit")
                #expect(step.color0 == (e["farbe_0"] as? [Int] ?? []), "\(label): Farbe 0")
                if let place = e["setzen"] as? [String: Int] {
                    #expect(step.placement?.cell == place["zelle"] && step.placement?.digit == place["ziffer"], "\(label): Setzen")
                } else {
                    #expect(step.placement == nil, "\(label): sollte nichts setzen")
                }
                let removed = (e["streichen"] as? [[String: Any]] ?? []).map {
                    "\($0["zelle"] as! Int):\(($0["ziffern"] as! [Int]).map(String.init).joined(separator: ","))"
                }
                let actual = step.eliminations.map { "\($0.cell):\(Mask.digits($0.mask).map(String.init).joined(separator: ","))" }
                #expect(actual == removed, "\(label): Streichen")
                board.apply(step)
                index += 1
                steps += 1
            }
            #expect(index == expected.count, "\(name): Anzahl der Schritte")
            #expect(board.isSolved == c["geloest"] as! Bool, "\(name): gelöst")
        }
        #expect(steps > 100)
    }

    @Test func logikSchritte() throws { try verifySteps("schritte", maxLevel: 3) }

    /// W1: Swordfish, XY-Wing und einfache Färbung, Schritt für Schritt wie die Referenz (nur für Tipps auf Experte)
    @Test func logikSchritteExperte() throws {
        try verifySteps("schritte_experte", maxLevel: 4)
        // Die Einstufung nutzt weiter nur Stufe 1–3: diese Rätsel bleiben Experte
        for c in try Regeltests.cases("schritte_experte") {
            #expect(Rating.level(of: Regeltests.grid(c["raetsel"] as! String)) == c["stufe"] as! Int, "\(c["name"] as! String): Stufe")
        }
    }

    @Test func zufall() throws {
        let cases = try Regeltests.cases("zufall")
        #expect(!cases.isEmpty)
        for c in cases {
            var rng = SplitMix64(seed: UInt64(c["seed"] as! String)!)
            let expected = c["werte"] as! [String]
            #expect((0..<expected.count).map { _ in String(rng.next()) } == expected, "Seed \(c["seed"]!)")
        }
    }

    /// S8: Der Logik-Löser findet auf den Feldern aus `techniken.json` genau den erwarteten Schritt (Technik, Muster, Ziffern, Setzen, Streichen).
    /// Feld und Kandidaten kommen direkt aus der Regeltest-Datei (früher über die Technik-Sammlung der Einzel-App).
    @Test func techniken() throws {
        let cases = try Regeltests.cases("techniken")
        #expect(cases.count == 9)
        try pruefeTechnikSchritte(cases)
    }

    /// W1: die drei Stufe-4-Techniken (techniken_experte.json)
    @Test func technikenExperte() throws {
        let cases = try Regeltests.cases("techniken_experte")
        #expect(cases.count == 3)
        try pruefeTechnikSchritte(cases)
    }

    private func pruefeTechnikSchritte(_ cases: [[String: Any]]) throws {
        for c in cases {
            let name = c["technik"] as! String
            let werte = (c["feld"] as! String).map { UInt8(String($0)) ?? 0 }
            let kandidaten = (c["kandidaten"] as! [String]).map { $0.reduce(UInt16(0)) { $0 | Mask.bit(Int(String($1))!) } }
            let expected = c["schritt"] as! [String: Any]
            let step = try #require(LogicBoard(grid: werte, candidates: kandidaten).nextStep(maxLevel: 4), "\(name): kein Schritt")
            #expect(String(describing: step.technique) == expected["technik"] as! String, "\(name): Technik")
            #expect(step.pattern == expected["muster"] as! [Int], "\(name): Muster")
            #expect(Mask.digits(step.digits) == expected["ziffern"] as! [Int], "\(name): Ziffern")
            #expect(step.unit == expected["einheit"] as? Int, "\(name): Einheit")
            #expect(step.color0 == (expected["farbe_0"] as? [Int] ?? []), "\(name): Farbe 0")
            if let place = expected["setzen"] as? [String: Int] {
                #expect(step.placement?.cell == place["zelle"] && step.placement?.digit == place["ziffer"], "\(name): Setzen")
            } else {
                #expect(step.placement == nil, "\(name): setzt nichts")
            }
            let removed = (expected["streichen"] as? [[String: Any]] ?? []).map {
                "\($0["zelle"] as! Int):\(($0["ziffern"] as! [Int]).map(String.init).joined(separator: ","))"
            }
            let actual = step.eliminations.map { "\($0.cell):\(Mask.digits($0.mask).map(String.init).joined(separator: ","))" }
            #expect(actual == removed, "\(name): Streichen")
        }
    }

    @Test func tagesserie() throws {
        let cases = try Regeltests.cases("tagesserie")
        #expect(!cases.isEmpty)
        for c in cases {
            let name = c["name"] as! String
            let streak = DailyStreak.compute(solved: Set(c["geloest"] as! [String]), today: c["heute"] as! String)
            #expect(streak.length == c["laenge"] as! Int, "\(name): Länge")
            #expect(streak.resting == c["ruht"] as! Bool, "\(name): ruht")
        }
    }

}
