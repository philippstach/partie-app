// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import AblegeKarten

final class AblegeMasseTests: XCTestCase {
    func testIPhoneSE() {
        let m = AblegeMasse.berechne(breite: 375, hoehe: 667)
        XCTAssertEqual(m.aufbau, .telefon); XCTAssertEqual(m.handKarte, 84); XCTAssertEqual(m.tischKarte, 80); XCTAssertTrue(m.kleinerBildschirm)
    }
    func testIPhone390() {
        let m = AblegeMasse.berechne(breite: 390, hoehe: 844)
        XCTAssertEqual(m.handKarte, 100); XCTAssertEqual(m.tischKarte, 120); XCTAssertFalse(m.kleinerBildschirm)
    }
    func testProMax() {
        let m = AblegeMasse.berechne(breite: 430, hoehe: 932)
        XCTAssertEqual(m.handKarte, 112); XCTAssertEqual(m.tischKarte, 150)
    }
    func testIPadHochUndQuer() {
        let hoch = AblegeMasse.berechne(breite: 820, hoehe: 1180)
        XCTAssertEqual(hoch.aufbau, .padHoch); XCTAssertEqual(hoch.tischKarte, 150); XCTAssertEqual(hoch.seitenspalte, 0)
        let quer = AblegeMasse.berechne(breite: 1180, hoehe: 820)
        XCTAssertEqual(quer.aufbau, .padQuer); XCTAssertGreaterThan(quer.seitenspalte, 0)
    }
    func testKartenWachsenMitDemTelefonBildschirm() {
        let breiten: [CGFloat] = [320, 375, 390, 430]
        let hand = breiten.map { AblegeMasse.berechne(breite: $0, hoehe: $0 * 2).handKarte }
        XCTAssertEqual(hand, hand.sorted())
    }
    func testHoehenPassenZurBreite() {
        let m = AblegeMasse.berechne(breite: 390, hoehe: 844)
        XCTAssertEqual(m.handHoehe, 145, accuracy: 0.01)
        XCTAssertEqual(m.tischHoehe, 170.4, accuracy: 0.01)
    }
}
