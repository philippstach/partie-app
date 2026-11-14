// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Siegesanimation: jedes Spiel liefert seine Karten aus den Zielstapeln; die Rechnung läuft in allen Fällen zu Ende.
final class WasserfallTests: XCTestCase {
    private let size = CGSize(width: 402, height: 700)

    private func laeuftZuEnde(_ cards: [(face: CardFace, origin: CGPoint)], _ layoutSize: CGSize, cardSize: CGSize) {
        let sim = WaterfallSim(cards: cards, cardSize: cardSize, bounds: layoutSize)
        XCTAssertFalse(sim.finished)
        sim.advance(to: 30)
        XCTAssertTrue(sim.finished, "alle Karten sind draußen und die Spur ist ausgeblendet")
    }

    func testKlondike() {
        var s = GameState(draw: 1, foundation: [13, 13, 13, 13])
        s.moves = 100
        let layout = KlondikeLayout(state: s, size: size, prefs: TablePrefs())
        let cards = layout.waterfallCards()
        XCTAssertEqual(cards.count, 52)
        XCTAssertEqual(Set(cards.map { $0.face.suit.rawValue * 13 + $0.face.rank }).count, 52)
        XCTAssertEqual(cards.prefix(4).map(\.face.rank), [13, 13, 13, 13])               // Könige zuerst
        XCTAssertEqual(cards.prefix(4).map { $0.origin }, (0..<4).map { layout.foundationFrame($0).origin })
        laeuftZuEnde(cards, size, cardSize: layout.cardSize)
    }

    func testFreeCell() {
        let s = FreeCellState(foundation: [13, 13, 13, 13])
        for links in [false, true] {
            let layout = FreeCellLayout(state: s, size: size, prefs: TablePrefs(leftHanded: links))
            let cards = layout.waterfallCards()
            XCTAssertEqual(cards.count, 52)
            XCTAssertEqual(Set(cards.map { $0.face.suit.rawValue * 13 + $0.face.rank }).count, 52)
            XCTAssertEqual(cards.prefix(4).map(\.face.rank), [13, 13, 13, 13])
            // die vier Könige starten genau auf ihren Zielstapeln (Pik, Herz, Karo, Kreuz)
            XCTAssertEqual(cards.prefix(4).map { $0.origin }, (0..<4).map { layout.foundationFrame($0).origin })
            XCTAssertEqual(cards.prefix(4).map(\.face.suit), Suit.allCases)
            laeuftZuEnde(cards, size, cardSize: layout.cardSize)
        }
    }

    func testSpider() {
        var s = SpiderState(suits: 4)
        s.done = (0..<8).map { DoneRun(suit: $0 % 4) }
        let layout = SpiderLayout(state: s, size: size, prefs: TablePrefs())
        let cards = layout.waterfallCards()
        XCTAssertEqual(cards.count, 56)                                                  // König bis 7 je Reihe
        XCTAssertEqual(cards.prefix(8).map(\.face.rank), Array(repeating: 13, count: 8))
        XCTAssertEqual(cards.prefix(8).map { $0.origin }, (0..<8).map { layout.doneFrame($0).origin })
        laeuftZuEnde(cards, size, cardSize: layout.cardSize)
    }

    func testSpiderOhneFertigeReihenLiefertNichts() {
        let layout = SpiderLayout(state: SpiderState(suits: 2), size: size, prefs: TablePrefs())
        XCTAssertTrue(layout.waterfallCards().isEmpty)
    }
}
