// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Prüft jede Datei aus `Shared/regeltests/golf/` vollständig.
@MainActor
final class GolfRegeltestsTests: XCTestCase {
    private struct Names: Equatable {
        var spalten: [[String]]
        var stapel: [String]
        var ablage: [String]
        var kette: Int
        var punkte: Int
        var zuege: Int
    }

    private func names(_ s: GolfState) -> Names {
        Names(spalten: s.cols.map { $0.map(\.shortName) }, stapel: s.stock.map(\.shortName), ablage: s.waste.map(\.shortName),
              kette: s.chain, punkte: s.score, zuege: s.moves)
    }

    private func state(_ d: [String: Any]) -> GolfState {
        let cols = (d["spalten"] as? [[String]] ?? []).map { $0.map(TestJSON.card) }
        return GolfState(cols: cols, stock: TestJSON.cards(d["stapel"]), waste: TestJSON.cards(d["ablage"]),
                         chain: d["kette"] as? Int ?? 0, score: d["punkte"] as? Int ?? 0, moves: d["zuege"] as? Int ?? 0)
    }

    private func move(_ d: [String: Any]) -> Move {
        let von = d["von"] as! String
        if von == "stapel" { return .draw }
        guard von.count == 2, von.hasPrefix("G"), let k = Int(von.dropFirst()) else { return .move(from: .column(99), to: .waste, count: 1) }
        return .move(from: .column(k), to: .waste, count: 1)
    }

    func testGeben() throws {
        for f in try TestJSON.cases("golf/geben") {
            let seed = UInt64(f["seed"] as! Int)
            XCTAssertEqual(names(GolfRules.deal(seed: seed, mode: .golf)), names(state(f["zustand"] as! [String: Any])), "Seed \(seed)")
        }
    }

    func testZuege() throws {
        let faelle = try TestJSON.cases("golf/zuege")
        XCTAssertGreaterThanOrEqual(faelle.count, 20)
        for f in faelle {
            let titel = f["titel"] as! String
            let result = GolfRules.apply(state(f["start"] as! [String: Any]), move(f["zug"] as! [String: Any]))
            if f["erlaubt"] as! Bool {
                let next = try XCTUnwrap(result, titel)
                XCTAssertEqual(names(next), names(state(f["danach"] as! [String: Any])), titel)
                XCTAssertEqual(next.isWon, f["gewonnen"] as! Bool, titel)
            } else {
                XCTAssertNil(result, titel)
            }
        }
    }

    func testTipp() throws {
        let faelle = try TestJSON.cases("golf/tipp")
        XCTAssertGreaterThanOrEqual(faelle.count, 8)
        for f in faelle {
            let titel = f["titel"] as! String
            let s = state(f["start"] as! [String: Any])
            if let t = f["tipp"] as? [String: Any] { XCTAssertEqual(GolfRules.hint(s), move(t), titel) } else { XCTAssertNil(GolfRules.hint(s), titel) }
            XCTAssertEqual(GolfRules.isStuck(s), f["festgefahren"] as! Bool, titel)
        }
    }

    func testPartien() throws {
        for f in try TestJSON.cases("golf/partien") {
            let titel = f["titel"] as! String
            var s = GolfRules.deal(seed: UInt64(f["seed"] as! Int), mode: .golf)
            for z in f["zuege"] as! [[String: Any]] { s = try XCTUnwrap(GolfRules.apply(s, move(z)), "\(titel): Zug unerlaubt") }
            XCTAssertEqual(names(s), names(state(f["ende"] as! [String: Any])), titel)
            XCTAssertEqual(s.isWon, f["gewonnen"] as! Bool, titel)
            if let stuck = f["festgefahren"] as? Bool { XCTAssertEqual(GolfRules.isStuck(s), stuck, titel) }
        }
    }

    func testTagesspiel() throws {
        let k = DealCatalog.load()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        for f in try TestJSON.cases("golf/tagesspiel") {
            let teile = (f["datum"] as! String).split(separator: "-").map { Int($0)! }
            let tage = DealCatalog.daysSinceEpoch(year: teile[0], month: teile[1], day: teile[2], calendar: cal)
            XCTAssertEqual(tage, f["tage"] as! Int)
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage, kind: .golf), UInt64(f["seed"] as! Int), f["datum"] as! String)
        }
    }

    func testZugschriftUndPunkte() {
        XCTAssertEqual(GolfRules.solutionMoves(from: "s G0 G6"), [.draw, .move(from: .column(0), to: .waste, count: 1), .move(from: .column(6), to: .waste, count: 1)])
        XCTAssertNil(GolfRules.solutionMoves(from: "G7"))
        XCTAssertNil(GolfRules.solutionMoves(from: "T3"))
        // Punkte erst beim Sieg: übrige Stapelkarten
        var s = GolfState(cols: [[TestJSON.card("6H")]], stock: [TestJSON.card("2S"), TestJSON.card("3S")], waste: [TestJSON.card("5S")])
        XCTAssertNil(s.displayScore)
        s = GolfRules.apply(s, .move(from: .column(0), to: .waste, count: 1))!
        XCTAssertTrue(s.isWon)
        XCTAssertEqual(s.score, 2)
        XCTAssertEqual(s.displayScore, 2)
    }

    func testSpielstandMitFehlendenFeldern() throws {
        let s = try JSONDecoder().decode(GolfState.self, from: Data("{}".utf8))
        XCTAssertEqual(s.cols.count, 7)
        XCTAssertEqual(s.chain, 0)
    }
}
