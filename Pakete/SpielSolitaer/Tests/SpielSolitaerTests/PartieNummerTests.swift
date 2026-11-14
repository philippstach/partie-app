// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

@MainActor
final class PartieNummerTests: XCTestCase {
    private let k = DealCatalog.load()

    func testNummerIstPlatzInDerListePlusEins() {
        for mode in [GameMode.klondike(1), .klondike(3), .spider(1), .spider(2), .pyramid, .tripeaks, .golf, .yukon] {
            let liste = k.seeds(for: mode)
            XCTAssertFalse(liste.isEmpty, mode.key)
            XCTAssertEqual(k.maxNumber(mode: mode), liste.count, mode.key)
            XCTAssertEqual(k.number(mode: mode, seed: liste[0]), 1, mode.key)
            XCTAssertEqual(k.number(mode: mode, seed: liste[liste.count - 1]), liste.count, mode.key)
            XCTAssertEqual(k.seed(mode: mode, number: 1), liste[0], mode.key)
            XCTAssertEqual(k.seed(mode: mode, number: liste.count), liste[liste.count - 1], mode.key)
            // Hin und zurück
            for n in [1, 2, liste.count / 2, liste.count] { XCTAssertEqual(k.number(mode: mode, seed: k.seed(mode: mode, number: n)!), n, mode.key) }
        }
    }

    func testUngueltigeNummern() {
        let m = GameMode.klondike(1)
        let n = k.maxNumber(mode: m)!
        XCTAssertNil(k.seed(mode: m, number: 0))
        XCTAssertNil(k.seed(mode: m, number: -3))
        XCTAssertNil(k.seed(mode: m, number: n + 1))
        XCTAssertNil(k.maxNumber(mode: .spider(4)))             // nur Zufall: keine Nummern
        XCTAssertNil(k.seed(mode: .spider(4), number: 1))
        XCTAssertNil(k.number(mode: m, seed: 999_999_999))     // nicht in der Liste
    }

    func testFreeCellNummerIstDieMicrosoftNummer() {
        XCTAssertEqual(k.maxNumber(mode: .freecell), 32000)
        XCTAssertEqual(k.seed(mode: .freecell, number: 617), 617)
        XCTAssertEqual(k.number(mode: .freecell, seed: 617), 617)
        XCTAssertNil(k.seed(mode: .freecell, number: 11982))    // unlösbar
        XCTAssertNil(k.seed(mode: .freecell, number: 32001))
        XCTAssertNil(k.seed(mode: .freecell, number: 0))
    }

    func testAnzeigeNummer() {
        let m = GameMode.klondike(1)
        let seed = k.seed(mode: m, number: 7)!
        XCTAssertEqual(DealInfo(seed: seed, mode: m, kind: .solvable).number, "7")
        XCTAssertTrue(DealInfo(seed: seed, mode: m, kind: .solvable).isNumbered)
        XCTAssertTrue(DealInfo(seed: seed, mode: m, kind: .daily, day: "2026-10-06").isNumbered)
        let zufall = DealInfo(seed: 123_456_789_012, mode: m, kind: .random)
        XCTAssertEqual(zufall.number, "789012")                  // letzte 6 Ziffern
        XCTAssertFalse(zufall.isNumbered)
    }

    func testStartNumbered() {
        let app = AppModel(prefs: AppPreferences(defaults: UserDefaults(suiteName: "nummer-\(UUID().uuidString)")!),
                           stats: StatsStore(url: nil), folder: nil, seed: 1)
        XCTAssertFalse(app.startNumbered(0, mode: .pyramid))
        XCTAssertTrue(app.startNumbered(3, mode: .pyramid))
        XCTAssertEqual(app.session.mode, .pyramid)
        XCTAssertEqual(app.session.deal.seed, k.seed(mode: .pyramid, number: 3))
        XCTAssertEqual(app.session.deal.kind, .solvable)
        XCTAssertEqual(app.session.deal.number, "3")
        XCTAssertTrue(app.startNumbered(617, mode: .freecell))
        XCTAssertEqual(app.session.deal.seed, 617)
    }
}
