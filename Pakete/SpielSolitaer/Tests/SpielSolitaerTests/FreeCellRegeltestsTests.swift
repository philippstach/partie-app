// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Prüft jede Datei aus `Shared/regeltests/freecell/` vollständig (ganzer Zustand im Test-JSON-Format).
final class FreeCellRegeltestsTests: XCTestCase {
    // MARK: Hilfen

    private func state(_ d: [String: Any]) -> FreeCellState {
        var cols = (d["spalten"] as? [[String]] ?? []).map { $0.map(TestJSON.card) }
        while cols.count < 8 { cols.append([]) }
        var cells: [CardID?] = (d["zellen"] as? [Any] ?? []).map { ($0 as? String).map(TestJSON.card) }
        while cells.count < 4 { cells.append(nil) }
        return FreeCellState(cols: cols, cells: cells, foundation: d["ziel"] as? [Int] ?? [0, 0, 0, 0],
                             moves: d["zuege"] as? Int ?? 0, number: d["nummer"] as? Int ?? 0)
    }

    private func pile(_ s: String) -> Pile {
        let i = Int(s.dropFirst())!
        switch s.first! {
        case "S": return .column(i)
        case "F": return .cell(i)
        default: return .foundation(i)
        }
    }

    private func move(_ d: [String: Any]) -> Move {
        .move(from: pile(d["von"] as! String), to: pile(d["nach"] as! String), count: d["anzahl"] as? Int ?? 1)
    }

    private func moves(_ any: Any?) -> [Move] { (any as? [[String: Any]] ?? []).map(move) }

    // MARK: Tests

    func testGeben() throws {
        let faelle = try TestJSON.cases("freecell/geben")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let nummer = f["nummer"] as! Int
            let s = FreeCellRules.deal(seed: UInt64(nummer), mode: GameMode(kind: .freecell, option: 0))
            XCTAssertEqual(s, state(f["zustand"] as! [String: Any]), "Partie \(nummer)")
            XCTAssertEqual(s.cols.map { $0[0].shortName }, f["erste_reihe"] as! [String], "erste Reihe, Partie \(nummer)")
            XCTAssertEqual(s.cols.map(\.count), [7, 7, 7, 7, 6, 6, 6, 6])
        }
    }

    func testZuege() throws {
        let faelle = try TestJSON.cases("freecell/zuege")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            let ergebnis = FreeCellRules.apply(state(f["start"] as! [String: Any]), move(f["zug"] as! [String: Any]))
            if f["erlaubt"] as! Bool {
                XCTAssertEqual(ergebnis, state(f["danach"] as! [String: Any]), titel)
            } else {
                XCTAssertNil(ergebnis, "\(titel): sollte unerlaubt sein")
            }
        }
    }

    func testTippen() throws {
        let faelle = try TestJSON.cases("freecell/tippen")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let ziel = FreeCellRules.tapTarget(state(f["start"] as! [String: Any]), from: pile(f["quelle"] as! String), count: f["anzahl"] as! Int)
            XCTAssertEqual(ziel, (f["zug"] as? [String: Any]).map(move), f["titel"] as! String)
        }
    }

    func testAutoAblegen() throws {
        let faelle = try TestJSON.cases("freecell/autoablegen")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            XCTAssertEqual(FreeCellRules.autoMoves(state(f["start"] as! [String: Any]), autoFoundation: true), moves(f["zuege"]), f["titel"] as! String)
        }
    }

    func testBeenden() throws {
        let faelle = try TestJSON.cases("freecell/beenden")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            XCTAssertEqual(FreeCellRules.canAutoFinish(start), f["moeglich"] as! Bool, titel)
            if f["moeglich"] as! Bool {
                XCTAssertEqual(FreeCellRules.autoFinishMoves(start), moves(f["zuege"]), titel)
            }
        }
    }

    func testTipp() throws {
        let faelle = try TestJSON.cases("freecell/tipp")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            XCTAssertEqual(FreeCellRules.hint(start), (f["tipp"] as? [String: Any]).map(move), titel)
            XCTAssertEqual(FreeCellRules.isStuck(start), f["festgefahren"] as! Bool, titel)
        }
    }

    func testPartien() throws {
        let faelle = try TestJSON.cases("freecell/partien")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            let titel = f["titel"] as! String
            var s = FreeCellRules.deal(seed: UInt64(f["nummer"] as! Int), mode: GameMode(kind: .freecell, option: 0))
            for (i, m) in moves(f["zuege"]).enumerated() {
                guard let n = FreeCellRules.apply(s, m) else { return XCTFail("\(titel): Zug \(i) \(m) unerlaubt") }
                s = n
            }
            XCTAssertEqual(s, state(f["ende"] as! [String: Any]), titel)
            XCTAssertEqual(s.isWon, f["gewonnen"] as! Bool, titel)
        }
    }

    func testTagesspiel() throws {
        let faelle = try TestJSON.cases("freecell/tagesspiel")
        XCTAssertFalse(faelle.isEmpty)
        for f in faelle {
            XCTAssertEqual(FreeCellRules.dailyNumber(days: f["tage"] as! Int), f["nummer"] as! Int, f["datum"] as! String)
        }
    }

    func testZustandCodableMitStandardwerten() throws {
        let leer = try JSONDecoder().decode(FreeCellState.self, from: Data("{}".utf8))
        XCTAssertEqual(leer.cols.count, 8)
        XCTAssertEqual(leer.cells.count, 4)
        let s = FreeCellRules.deal(seed: 617, mode: GameMode(kind: .freecell, option: 0))
        XCTAssertEqual(try JSONDecoder().decode(FreeCellState.self, from: JSONEncoder().encode(s)), s)
    }
}
