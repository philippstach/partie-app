// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import AblegeKarten

final class FaecherMasseTests: XCTestCase {
    func testLeer() { XCTAssertEqual(FaecherMasse.berechne(anzahl: 0, breite: 300, kartenBreite: 60).zeilen, []) }

    func testWenigeKartenEinzeilig() {
        let m = FaecherMasse.berechne(anzahl: 5, breite: 358, kartenBreite: 70)
        XCTAssertEqual(m.zeilen, [0..<5])
        XCTAssertLessThanOrEqual(m.inhaltsBreite, 358)
        XCTAssertGreaterThanOrEqual(m.schritt, 26)
    }

    func testVieleKartenZweizeilig() {
        let m = FaecherMasse.berechne(anzahl: 16, breite: 358, kartenBreite: 70)
        XCTAssertEqual(m.zeilen.count, 2)
        XCTAssertEqual(m.zeilen.flatMap { Array($0) }, Array(0..<16))
        XCTAssertLessThanOrEqual(m.inhaltsBreite, 358.5)
    }

    func testSehrVieleKartenBleibenImMinimumUndScrollen() {
        let m = FaecherMasse.berechne(anzahl: 40, breite: 300, kartenBreite: 70)
        XCTAssertEqual(m.zeilen.count, 2)
        XCTAssertEqual(m.schritt, 26)
        XCTAssertGreaterThan(m.inhaltsBreite, 300)
    }

    func testEineKarteSteht() {
        let m = FaecherMasse.berechne(anzahl: 1, breite: 300, kartenBreite: 70)
        XCTAssertEqual(m.zeilen, [0..<1]); XCTAssertEqual(m.inhaltsBreite, 70)
    }
}
