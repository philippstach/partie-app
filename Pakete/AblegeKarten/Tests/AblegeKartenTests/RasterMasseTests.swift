// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import AblegeKarten

final class RasterMasseTests: XCTestCase {
    let gross = CGSize(width: 58, height: 84), klein = CGSize(width: 44, height: 64)

    func testZehnKartenGrossInZweiGleichenZeilen() {
        let m = RasterMasse.berechne(anzahl: 10, breite: 358, groessen: [gross, klein], hoechstHoehe: 190)
        XCTAssertEqual(m.karte, gross); XCTAssertEqual(m.zeilen, 2); XCTAssertEqual(m.spalten, 5); XCTAssertTrue(m.passt)
    }

    func testKeineKarteRagtUeberDieBreite() {
        for n in 1...30 {
            let m = RasterMasse.berechne(anzahl: n, breite: 343, groessen: [gross, klein], hoechstHoehe: 150)
            XCTAssertLessThanOrEqual(CGFloat(m.spalten) * m.karte.width + CGFloat(m.spalten - 1) * m.abstand, 343.5, "\(n) Karten")
            XCTAssertGreaterThanOrEqual(m.spalten * m.zeilen, n)
        }
    }

    func testVieleKartenWerdenKleinUndScrollen() {
        let m = RasterMasse.berechne(anzahl: 30, breite: 343, groessen: [gross, klein], hoechstHoehe: 150)
        XCTAssertEqual(m.karte, klein); XCTAssertFalse(m.passt)
    }

    func testLeer() {
        let m = RasterMasse.berechne(anzahl: 0, breite: 343, groessen: [gross, klein], hoechstHoehe: 150)
        XCTAssertEqual(m.zeilen, 0); XCTAssertEqual(m.hoehe, 0); XCTAssertTrue(m.passt)
    }
}
