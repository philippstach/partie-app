// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

final class GrosseKartenTests: XCTestCase {
    private let sizes = [CGSize(width: 393, height: 600), CGSize(width: 375, height: 520), CGSize(width: 320, height: 430)]

    private func longKlondike() -> GameState {
        var g = GameState()
        let all = CardID.all
        g.cols[0] = Column(down: Array(all[0..<6]), up: Array(all[6..<19]))      // 6 verdeckt + 13 offen: die längste mögliche Spalte
        g.cols[1] = Column(down: Array(all[19..<24]), up: Array(all[24..<28]))
        return g
    }

    func testKlondikeFaecherHaeltGrenzenEin() {
        for size in sizes {
            for large in [false, true] {
                let layout = KlondikeLayout(state: longKlondike(), size: size, prefs: TablePrefs(largeCards: large))
                let h = layout.cardHeight
                for col in longKlondike().cols {
                    let (down, open) = layout.steps(for: col)
                    XCTAssertGreaterThanOrEqual(open, h * (large ? 0.16 : 0.17) - 0.001, "offen \(size) groß=\(large)")
                    XCTAssertLessThanOrEqual(open, h * (large ? 0.46 : 0.42) + 0.001)
                    XCTAssertGreaterThanOrEqual(down, h * 0.05 - 0.001)
                }
                // nie über den unteren Rand hinaus (kein Scrollen)
                XCTAssertLessThanOrEqual(layout.columnBottoms.max() ?? 0, size.height, "Spalte passt \(size) groß=\(large)")
            }
        }
    }

    func testGrossAendertDieKartenbreiteNicht() {
        let a = KlondikeLayout(state: GameState(), size: sizes[0], prefs: TablePrefs(largeCards: false))
        let b = KlondikeLayout(state: GameState(), size: sizes[0], prefs: TablePrefs(largeCards: true))
        XCTAssertEqual(a.cardSize, b.cardSize)
    }

    func testGrosserFaecherBeiLeeremTischWaechstBisZweiundvierzig() {
        var g = GameState()
        g.cols[0] = Column(down: [], up: Array(CardID.all[0..<5]))
        let layout = KlondikeLayout(state: g, size: sizes[0], prefs: TablePrefs(largeCards: true))
        XCTAssertEqual(layout.openBase, layout.cardHeight * 0.46, accuracy: 0.001)             // viel Platz → bis 0,46 (Normal: 0,42)
        let tight = KlondikeLayout(state: longKlondike(), size: sizes[2], prefs: TablePrefs(largeCards: true))
        XCTAssertGreaterThanOrEqual(tight.openBase, tight.cardHeight * 0.26 - 0.001)          // sonst mindestens der Grundwert
    }

    func testFreeCellFaecherHaeltGrenzenEin() {
        var f = FreeCellState()
        f.cols[0] = Array(CardID.all[0..<19])
        for size in sizes {
            for large in [false, true] {
                let layout = FreeCellLayout(state: f, size: size, prefs: TablePrefs(largeCards: large))
                XCTAssertGreaterThanOrEqual(layout.openStepFor(f.cols[0]), layout.cardHeight * 0.20 - 0.001)
                XCTAssertLessThanOrEqual(layout.columnBottoms.max() ?? 0, size.height, "FreeCell passt \(size) groß=\(large)")
            }
        }
    }

    func testEinstellungWirdGespeichert() {
        let d = UserDefaults(suiteName: "gk-\(UUID().uuidString)")!
        XCTAssertFalse(AppPreferences(defaults: d).largeCards)
        let p = AppPreferences(defaults: d)
        p.largeCards = true
        XCTAssertTrue(AppPreferences(defaults: d).largeCards)
    }
}
