// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WuerfelScan

final class ZuordnungTests: XCTestCase {
    func testErsterWurfNimmtAlle() {
        XCTAssertEqual(WuerfelZuordnung.zuordnen(erkannt: [3, 1, 6, 6, 2], gehalten: [], plaetze: 5), [3, 1, 6, 6, 2])
    }
    func testGehalteneLiegenMitAufDemTisch() {
        XCTAssertEqual(WuerfelZuordnung.zuordnen(erkannt: [6, 6, 2, 4, 1], gehalten: [6, 6], plaetze: 3), [2, 4, 1])
    }
    func testNurDieNeuenFotografiert() {
        XCTAssertEqual(WuerfelZuordnung.zuordnen(erkannt: [2, 4, 1], gehalten: [6, 6], plaetze: 3), [2, 4, 1])
    }
    func testZuVieleWerdenGekappt() {
        XCTAssertEqual(WuerfelZuordnung.zuordnen(erkannt: [1, 2, 3, 4], gehalten: [], plaetze: 3), [1, 2, 3])
    }
    func testZuWenigeBleibenKurz() {
        XCTAssertEqual(WuerfelZuordnung.zuordnen(erkannt: [5], gehalten: [], plaetze: 5), [5])
    }
    func testGehalteneNichtGefundenBleibtUnveraendert() {
        XCTAssertEqual(WuerfelZuordnung.zuordnen(erkannt: [1, 2, 3, 4, 5], gehalten: [6, 6], plaetze: 3), [1, 2, 3])
    }
}
