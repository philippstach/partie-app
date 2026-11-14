// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielViererreihe

final class NeuSpielTests: XCTestCase {
    func testWurfUndVerlauf() {
        var s = NeuSpiel(zweiSpieler: true, stufe: .mittel, zufall: SplitMix64(seed: 1))
        XCTAssertTrue(s.wirf(3)); XCTAssertTrue(s.wirf(2)); XCTAssertTrue(s.wirf(3))
        XCTAssertEqual(s.dran, 1)
        let v = NeuVerlauf.letzte(s.partie, anzahl: 2)
        XCTAssertEqual(v.map(\.spalte), [2, 3]); XCTAssertEqual(v.map(\.spieler), [2, 1]); XCTAssertEqual(v.map(\.nummer), [2, 3])
        XCTAssertEqual(NeuVerlauf.letzte(s.partie, anzahl: 10).count, 3)
    }

    func testSpalteVollWirdAbgelehnt() {
        var s = NeuSpiel(zweiSpieler: true, stufe: .leicht, zufall: SplitMix64(seed: 2))
        for _ in 0..<6 { XCTAssertTrue(s.wirf(0)) }
        XCTAssertFalse(s.wirf(0))
    }

    func testSiegBeendetUndIstNichtFortsetzbar() {
        var s = NeuSpiel(zweiSpieler: true, stufe: .leicht, zufall: SplitMix64(seed: 3))
        for z in [0, 1, 0, 1, 0, 1, 0] { s.wirf(z) }
        XCTAssertEqual(s.partie.gewinner, 1)
        XCTAssertFalse(s.laeuft); XCTAssertFalse(s.istFortsetzbar)
        XCTAssertFalse(s.wirf(2))
    }

    func testZurueckGegenComputerNimmtAntwortMit() {
        var s = NeuSpiel(zweiSpieler: false, stufe: .leicht, zufall: SplitMix64(seed: 4))
        s.wirf(3)
        var z = s.zufall
        let antwort = Computer.waehle(.leicht, s.partie, zufall: &z); s.zufall = z
        s.wirf(antwort)
        XCTAssertTrue(s.kannZurueck)
        XCTAssertTrue(s.zurueck())
        XCTAssertEqual(s.partie.zuege.count, 0)
        XCTAssertFalse(s.computerDran)
    }

    func testCodableRundlauf() throws {
        var s = NeuSpiel(zweiSpieler: false, stufe: .geuebt, zufall: SplitMix64(seed: 5))
        s.wirf(1); s.wirf(4)
        let d = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(NeuSpiel.self, from: d), s)
    }

    func testMasseIPhone() {
        let se = NeuMasse.hochformat(breite: 375, hoehe: 647)
        XCTAssertEqual(se.brettBreite, 343, accuracy: 0.5); XCTAssertEqual(se.brettHoehe, 294, accuracy: 0.5)
        XCTAssertEqual(se.karten(schrift: 0), [])
        let m390 = NeuMasse.hochformat(breite: 390, hoehe: 763)
        XCTAssertEqual(m390.brettBreite, 358, accuracy: 0.5)
        XCTAssertEqual(m390.karten(schrift: 0), [.verlauf, .stand])
        let max = NeuMasse.hochformat(breite: 430, hoehe: 840)
        XCTAssertEqual(max.karten(schrift: 0), [.verlauf, .stand, .quote])
    }

    /// Blatt 16 (iPad hoch, Tinte): Brett bis 113 pt je Zelle, aber nur so groß, dass „Verlauf“ und „Stand“ Platz behalten. iPhone-Maße unverändert (siehe oben).
    func testMasseIPadHoch() {
        let m = NeuMasse.hochformat(breite: 834, hoehe: 1100, rand: 20, hoechsteKante: 113, hoeheBegrenzt: true)
        XCTAssertGreaterThan(m.kante, 97)
        XCTAssertLessThanOrEqual(m.kante, 113)
        XCTAssertGreaterThanOrEqual(m.rest, 180 - 0.5)
        XCTAssertEqual(m.karten(schrift: 0).prefix(2), [.verlauf, .stand])
    }

    func testGrosseSchriftLaesstZuerstStandWeg() {
        let m = NeuMasse.hochformat(breite: 430, hoehe: 840)
        XCTAssertEqual(m.karten(schrift: 1), [.verlauf])
        XCTAssertEqual(m.karten(schrift: 2), [])
    }

    func testQuote() {
        XCTAssertNil(neuQuote(siege: 0, partien: 0))
        XCTAssertEqual(neuQuote(siege: 3, partien: 4), 0.75)
    }
}
