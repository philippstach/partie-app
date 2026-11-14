// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

final class ThemenTests: XCTestCase {
    private func defaults() -> UserDefaults {
        let name = "themen-test-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testStandardwerte() {
        let p = AppPreferences(defaults: defaults())
        XCTAssertEqual(p.tableStyle, .linen)
        XCTAssertEqual(p.cardBack, .gold)
    }

    func testSpeichernUndLaden() {
        let d = defaults()
        let p = AppPreferences(defaults: d)
        p.tableStyle = .slate
        p.cardBack = .bordeaux
        let q = AppPreferences(defaults: d)
        XCTAssertEqual(q.tableStyle, .slate)
        XCTAssertEqual(q.cardBack, .bordeaux)
    }

    func testUnbekannterWertFaelltAufStandard() {
        let d = defaults()
        d.set("lila", forKey: "tableStyle")
        d.set("zebra", forKey: "cardBack")
        let p = AppPreferences(defaults: d)
        XCTAssertEqual(p.tableStyle, .linen)
        XCTAssertEqual(p.cardBack, .gold)
    }

    func testAlterFilzSchalterBleibtFilz() {
        let d = defaults()
        d.set(true, forKey: "feltTable")
        XCTAssertEqual(AppPreferences(defaults: d).tableStyle, .felt)
    }

    func testKontrastRegel() {
        // genau diese Kombinationen bekommen den weißen Rand (Foto: alle, siehe FotoTischTests)
        var betroffen: [String] = []
        for b in CardBackStyle.allCases {
            for t in TableStyle.allCases where t != .photo && b.needsContrastBorder(on: t) { betroffen.append("\(b.rawValue)/\(t.rawValue)") }
        }
        XCTAssertEqual(Set(betroffen), ["retro/felt", "retro/navy", "navy/navy", "retro/spring", "gold/autumn", "bordeaux/autumn", "navy/winter"])
    }

    func testTexteWeissAusserAufLeinen() {
        for t in [TableStyle.linen, .spring, .summer] { XCTAssertFalse(t.lightText, t.rawValue) }          // helle Tische: Texte folgen hell/dunkel
        for t in [TableStyle.felt, .navy, .slate, .photo, .autumn, .winter] { XCTAssertTrue(t.lightText, t.rawValue) }
    }
}
