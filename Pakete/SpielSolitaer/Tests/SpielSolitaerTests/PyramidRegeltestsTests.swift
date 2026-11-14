// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Prüft jede Datei aus `Shared/regeltests/pyramid/` vollständig.
@MainActor
final class PyramidRegeltestsTests: XCTestCase {
    // MARK: Hilfen

    private struct Names: Equatable {
        var pyramide: [String?]
        var stapel: [String]
        var ablage: [String]
        var durchgang: Int
        var zuege: Int
    }

    private func names(_ s: PyramidState) -> Names {
        Names(pyramide: s.pyramid.map { $0?.shortName }, stapel: s.stock.map(\.shortName), ablage: s.waste.map(\.shortName),
              durchgang: s.passes, zuege: s.moves)
    }

    private func state(_ d: [String: Any]) -> PyramidState {
        let pyr = (d["pyramide"] as? [Any] ?? []).map { ($0 as? String).map(TestJSON.card) }
        return PyramidState(pyramid: pyr, stock: TestJSON.cards(d["stapel"]), waste: TestJSON.cards(d["ablage"]),
                            passes: d["durchgang"] as? Int ?? 1, moves: d["zuege"] as? Int ?? 0)
    }

    private func names(json d: [String: Any]) -> Names { names(state(d)) }

    /// Ort der Tests: „P21“ / „A“; nil = unbekannt
    private func pile(_ s: String) -> Pile? {
        if s == "A" { return .waste }
        guard s.hasPrefix("P"), let k = Int(s.dropFirst()), String(k) == s.dropFirst() else { return nil }
        return .column(k)       // P28 und mehr: Regel muss das ablehnen
    }

    /// Zug der Tests → unser Zug; nil, wenn schon die Schreibweise unmöglich ist (drei Orte, zweimal derselbe Ort …)
    private func move(_ d: [String: Any]) -> Move? {
        if d["von"] as? String == "stapel" { return .draw }
        guard let paar = d["paar"] as? [String] else { return nil }
        let places = paar.compactMap(pile)
        guard places.count == paar.count else { return Move.move(from: .column(99), to: .column(99), count: 1) }
        switch places.count {
        case 1: return .move(from: places[0], to: places[0], count: 1)
        case 2 where places[0] != places[1]: return .move(from: places[0], to: places[1], count: 1)
        default: return Move.move(from: .column(99), to: .column(99), count: 1)    // unerlaubt
        }
    }

    private func play(_ s: PyramidState, _ z: [String: Any]) -> PyramidState? {
        guard let m = move(z) else { return nil }
        return PyramidRules.apply(s, m)
    }

    // MARK: Tests

    func testGeben() throws {
        for f in try TestJSON.cases("pyramid/geben") {
            let seed = UInt64(f["seed"] as! Int)
            XCTAssertEqual(names(PyramidRules.deal(seed: seed, mode: .pyramid)), names(json: f["zustand"] as! [String: Any]), "Seed \(seed)")
        }
    }

    func testZuege() throws {
        let faelle = try TestJSON.cases("pyramid/zuege")
        XCTAssertGreaterThanOrEqual(faelle.count, 20)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            let result = play(start, f["zug"] as! [String: Any])
            if f["erlaubt"] as! Bool {
                let next = try XCTUnwrap(result, titel)
                XCTAssertEqual(names(next), names(json: f["danach"] as! [String: Any]), titel)
                XCTAssertEqual(next.isWon, f["gewonnen"] as! Bool, titel)
            } else {
                XCTAssertNil(result, titel)
            }
        }
    }

    func testTippen() throws {
        let faelle = try TestJSON.cases("pyramid/tippen")
        XCTAssertGreaterThanOrEqual(faelle.count, 8)
        for f in faelle {
            let titel = f["titel"] as! String
            let s = state(f["start"] as! [String: Any])
            let ort = try XCTUnwrap(pile(f["ort"] as! String))
            XCTAssertEqual(PyramidRules.partners(s, of: ort), (f["partner"] as! [String]).compactMap(pile), titel)
        }
    }

    func testTipp() throws {
        let faelle = try TestJSON.cases("pyramid/tipp")
        XCTAssertGreaterThanOrEqual(faelle.count, 8)
        for f in faelle {
            let titel = f["titel"] as! String
            let s = state(f["start"] as! [String: Any])
            if let t = f["tipp"] as? [String: Any] {
                XCTAssertEqual(PyramidRules.hint(s), move(t), titel)
            } else {
                XCTAssertNil(PyramidRules.hint(s), titel)
            }
            XCTAssertEqual(PyramidRules.isStuck(s), f["festgefahren"] as! Bool, titel)
        }
    }

    func testPartien() throws {
        for f in try TestJSON.cases("pyramid/partien") {
            let titel = f["titel"] as! String
            var s = PyramidRules.deal(seed: UInt64(f["seed"] as! Int), mode: .pyramid)
            for z in f["zuege"] as! [[String: Any]] {
                s = try XCTUnwrap(play(s, z), "\(titel): Zug unerlaubt")
            }
            XCTAssertEqual(names(s), names(json: f["ende"] as! [String: Any]), titel)
            XCTAssertEqual(s.isWon, f["gewonnen"] as! Bool, titel)
            if let stuck = f["festgefahren"] as? Bool { XCTAssertEqual(PyramidRules.isStuck(s), stuck, titel) }
        }
    }

    func testTagesspiel() throws {
        let k = DealCatalog.load()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        for f in try TestJSON.cases("pyramid/tagesspiel") {
            let teile = (f["datum"] as! String).split(separator: "-").map { Int($0)! }
            let tage = DealCatalog.daysSinceEpoch(year: teile[0], month: teile[1], day: teile[2], calendar: cal)
            XCTAssertEqual(tage, f["tage"] as! Int)
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage, kind: .pyramid), UInt64(f["seed"] as! Int), f["datum"] as! String)
        }
    }

    func testZugschrift() {
        XCTAssertEqual(PyramidRules.solutionMoves(from: "P21 P15+P27 s A P25+A"),
                       [.move(from: .column(21), to: .column(21), count: 1), .move(from: .column(15), to: .column(27), count: 1), .draw,
                        .move(from: .waste, to: .waste, count: 1), .move(from: .column(25), to: .waste, count: 1)])
        XCTAssertNil(PyramidRules.solutionMoves(from: "P28"))
        XCTAssertNil(PyramidRules.solutionMoves(from: "P21+"))
        XCTAssertNil(PyramidRules.solutionMoves(from: "x"))
    }

    func testSpielstandMitFehlendenFeldern() throws {
        let s = try JSONDecoder().decode(PyramidState.self, from: Data("{}".utf8))
        XCTAssertEqual(s.pyramid.count, 28)
        XCTAssertEqual(s.passes, 1)
        XCTAssertEqual(s.moves, 0)
    }

    func testAuswahlImStore() async {
        // 8H (P21) hat zwei Partner (5S auf P26 und 5D in der Ablage) → erster Tipp wählt, zweiter entfernt das Paar
        var s = PyramidState()
        s.pyramid[21] = TestJSON.card("8H"); s.pyramid[26] = TestJSON.card("5S"); s.pyramid[27] = TestJSON.card("KH")
        s.waste = [TestJSON.card("5D")]
        let store = GameStore<PyramidRules>(mode: .pyramid, prefs: AppPreferences(), seed: 1, url: nil)
        store.load(state: s)
        store.tap(card: TestJSON.card("8H"), source: CardSource(pile: .column(21), count: 1))
        XCTAssertEqual(store.selected, .column(21))
        XCTAssertEqual(store.moves, 0)
        store.tap(card: TestJSON.card("8H"), source: CardSource(pile: .column(21), count: 1))
        XCTAssertNil(store.selected)                                  // erneutes Antippen hebt die Wahl auf
        store.tap(card: TestJSON.card("8H"), source: CardSource(pile: .column(21), count: 1))
        store.tap(card: TestJSON.card("5D"), source: CardSource(pile: .waste, count: 1))
        XCTAssertNil(store.selected)
        XCTAssertEqual(store.moves, 1)
        XCTAssertNil(store.state.pyramid[21])
        XCTAssertTrue(store.state.waste.isEmpty)
        store.tap(card: TestJSON.card("KH"), source: CardSource(pile: .column(27), count: 1))   // König geht sofort
        XCTAssertEqual(store.moves, 2)
    }
}
