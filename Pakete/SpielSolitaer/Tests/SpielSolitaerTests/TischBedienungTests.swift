// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

@MainActor
final class TischBedienungTests: XCTestCase {
    private func store(_ state: GameState) -> GameStore<KlondikeRules> {
        let s = GameStore<KlondikeRules>(mode: .klondike(1), prefs: AppPreferences(defaults: UserDefaults(suiteName: "tb-\(UUID().uuidString)")!), seed: 1, url: nil)
        s.load(state: state)
        return s
    }

    private func card(_ s: String) -> CardID { TestJSON.card(s) }

    func testDoppeltipp_zweiterTippBewegtNichtNochmal() {
        var g = GameState()
        g.cols[0] = Column(down: [], up: [card("5H")])
        g.cols[1] = Column(down: [], up: [card("6S")])
        g.cols[2] = Column(down: [], up: [card("6C")])
        let st = store(g)
        st.tap(card: card("5H"), source: CardSource(pile: .column(0), count: 1))
        XCTAssertEqual(st.moves, 1)                                    // erster Tipp: auf eine passende Spalte
        let ziel = st.state.cols.firstIndex { $0.up.contains(card("5H")) }!
        st.tap(card: card("5H"), source: CardSource(pile: .column(ziel), count: 1))
        XCTAssertEqual(st.moves, 1)                                    // schneller zweiter Tipp: keine weitere Bewegung
    }

    func testFoundationMove() {
        var g = GameState()
        g.cols[0] = Column(down: [], up: [card("AH")])
        g.cols[1] = Column(down: [], up: [card("5S")])
        XCTAssertEqual(KlondikeRules.foundationMove(g, from: .column(0), count: 1), .move(from: .column(0), to: .foundation(1), count: 1))
        XCTAssertNil(KlondikeRules.foundationMove(g, from: .column(1), count: 1))              // 5♠ darf nicht aufs Ziel
        g.foundation[1] = 1
        XCTAssertNil(KlondikeRules.foundationMove(g, from: .foundation(1), count: 1))          // nicht vom Ziel
        var f = FreeCellState()
        f.cols[0] = [card("AS")]
        XCTAssertEqual(FreeCellRules.foundationMove(f, from: .column(0), count: 1), .move(from: .column(0), to: .foundation(0), count: 1))
        XCTAssertNil(PyramidRules.foundationMove(PyramidState(), from: .waste, count: 1))     // andere Spiele: keiner
    }

    func testZurueckMehrfach() {
        // Mehrere Züge hintereinander zurücknehmen (das macht das lange Drücken schnell hintereinander)
        let st = GameStore<KlondikeRules>(mode: .klondike(1), prefs: AppPreferences(defaults: UserDefaults(suiteName: "tb-\(UUID().uuidString)")!), seed: 2, url: nil)
        st.drawStock(); st.drawStock(); st.drawStock()
        XCTAssertEqual(st.moves, 3)
        while st.canUndo { st.undo() }
        XCTAssertEqual(st.moves, 0)
    }

    func testAusteilenUeberspringen() {
        let st = GameStore<KlondikeRules>(mode: .klondike(1), prefs: AppPreferences(defaults: UserDefaults(suiteName: "tb-\(UUID().uuidString)")!), seed: 3, url: nil)
        st.newGame()
        XCTAssertTrue(st.dealing)
        st.skipDeal()
        XCTAssertFalse(st.dealing)
        XCTAssertFalse(st.showsPreDeal)
        XCTAssertEqual(st.dealSkips, 1)
        st.skipDeal()                                   // nichts mehr zu überspringen
        XCTAssertEqual(st.dealSkips, 1)
    }

    func testSchimmerNurFuerAss() {
        var g = GameState()
        g.cols[0] = Column(down: [], up: [card("AH")])
        g.cols[1] = Column(down: [], up: [card("2H")])
        let st = store(g)
        st.perform(.move(from: .column(0), to: .foundation(1), count: 1))
        XCTAssertEqual(st.shimmers[1], 1)                              // Ass aufs Ziel: Schimmer
        st.perform(.move(from: .column(1), to: .foundation(1), count: 1))
        XCTAssertEqual(st.shimmers[1], 1)                              // Zwei: kein neuer Schimmer
    }

    func testAufgedeckteSpalten() {
        var g = GameState()
        g.cols[0] = Column(down: [card("5S")], up: [card("AH")])
        XCTAssertEqual(g.revealedColumns, 0)
        g.cols[0] = Column(down: [], up: [card("5S")])
        XCTAssertEqual(g.revealedColumns, 1)
    }
}
