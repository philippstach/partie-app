// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

final class GegenueberTests: XCTestCase {
    func testGiltNurFuerZweiMenschen() {
        XCTAssertTrue(GegenueberEinstellung.gilt(teilnehmer: 2, computer: 0, eingeschaltet: true))
        XCTAssertFalse(GegenueberEinstellung.gilt(teilnehmer: 2, computer: 1, eingeschaltet: true))
        XCTAssertFalse(GegenueberEinstellung.gilt(teilnehmer: 1, computer: 0, eingeschaltet: true))
        XCTAssertFalse(GegenueberEinstellung.gilt(teilnehmer: 3, computer: 1, eingeschaltet: true))
    }

    func testAusgeschaltetGiltNie() {
        XCTAssertFalse(GegenueberEinstellung.gilt(teilnehmer: 2, computer: 0, eingeschaltet: false))
    }

    func testStandardIstAn() {
        let d = UserDefaults(suiteName: "gegenueber-test-\(UUID().uuidString)")!
        XCTAssertTrue(GegenueberEinstellung.aktiv(defaults: d))
        d.set(false, forKey: GegenueberEinstellung.schluessel)
        XCTAssertFalse(GegenueberEinstellung.aktiv(defaults: d))
    }
}
