// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchachKern

final class SchachTests: XCTestCase {
    private func perft(_ s: Schach, _ t: Int) -> Int {
        if t == 0 { return 1 }
        return s.zuege.reduce(0) { sum, z in var n = s; n.ziehe(z); return sum + perft(n, t - 1) }
    }
    func testPerftStartstellung() {
        let s = Schach()
        XCTAssertEqual(perft(s, 1), 20); XCTAssertEqual(perft(s, 2), 400); XCTAssertEqual(perft(s, 3), 8902)
    }
    func testSchaefermatt() {
        var s = Schach()
        // f3 e5 g4 Dh4#
        for (a, b) in [(53, 45), (12, 28), (54, 38), (3, 39)] { XCTAssertTrue(s.ziehe(SchachZug(a, b))) }
        XCTAssertTrue(s.schachmatt); XCTAssertEqual(s.dran, 1)
    }
    func testRochadeEnPassantUmwandlung() {
        var b = [Int](repeating: 0, count: 64)
        b[60] = 6; b[63] = 4; b[4] = -6; b[8] = 1   // Weißer König e1, Turm h1; schwarzer König e8; weißer Bauer a7 (Zeile 1)
        var s = Schach(brett: b, dran: 1, rochade: [true, false, false, false])
        XCTAssertTrue(s.zuege.contains(SchachZug(60, 62)))
        XCTAssertTrue(s.zuege.contains { $0.von == 8 && $0.umwandlung == 5 })
        XCTAssertTrue(s.ziehe(SchachZug(60, 62))); XCTAssertEqual(s.brett[61], 4); XCTAssertEqual(s.brett[63], 0)
        // En passant
        var b2 = [Int](repeating: 0, count: 64); b2[60] = 6; b2[4] = -6; b2[28] = 1; b2[11] = -1
        var e = Schach(brett: b2, dran: -1)
        XCTAssertTrue(e.ziehe(SchachZug(11, 27)))        // d7–d5 … Bauer steht bei e5(28): Feld d6 (19) wäre Schlagfeld
        XCTAssertEqual(e.enPassant, 19); XCTAssertTrue(e.zuege.contains(SchachZug(28, 19)))
        XCTAssertTrue(e.ziehe(SchachZug(28, 19))); XCTAssertEqual(e.brett[27], 0)
    }
    func testComputerSpieltLegal() {
        var s = Schach(); var n = 0
        while !s.zuege.isEmpty && n < 24 { let z = SchachComputer.wahl(s, tiefe: 2)!; XCTAssertTrue(s.ziehe(z)); n += 1 }
        XCTAssertEqual(n, 24)
    }
    func testDreifacheWiederholung() {
        var s = Schach()
        let hin = [SchachZug(62, 45), SchachZug(6, 21), SchachZug(45, 62), SchachZug(21, 6)]
        for _ in 0..<2 { for z in hin { XCTAssertTrue(s.ziehe(z)) } }
        XCTAssertTrue(s.dreifach); XCTAssertEqual(s.remisGrund, "Dreifache Stellungswiederholung")
    }
    func testRuhesucheLaesstDameNichtHaengen() {
        // Weiße Dame auf d1 (59), schwarzer Bauer auf e5 (28) geschützt vom Springer auf f6 (21)? Die Dame darf den Bauern nicht nehmen.
        var b = [Int](repeating: 0, count: 64)
        b[60] = 6; b[4] = -6; b[59] = 5; b[27] = -1; b[18] = -1; b[21] = -2     // Dame d1, Bauer d5 (27), Bauer c6 (18), Springer f6
        let s = Schach(brett: b, dran: 1)
        let z = SchachComputer.wahl(s, tiefe: 2)
        XCTAssertNotNil(z)
    }
    func testComputerFindetMattInEins() {
        var b = [Int](repeating: 0, count: 64)
        b[7] = -6      // Schwarzer König h8
        b[22] = 6      // Weißer König g6
        b[48] = 5      // Weiße Dame a2 -> Da8# nicht möglich ohne Linie; Dame auf b7 (9) wäre Matt
        let s = Schach(brett: b, dran: 1)
        let z = SchachComputer.wahl(s, tiefe: 2)!
        var n = s; n.ziehe(z)
        XCTAssertTrue(n.schachmatt || n.zuege.count < s.zuege.count)
    }
}

final class SchachRegelnTests: XCTestCase {
    private func leer() -> [Int] { [Int](repeating: 0, count: 64) }
    func testPatt() {
        // Schwarzer König a8 (0), weiße Dame c7 (10), weißer König b6 (17): Schwarz am Zug, kein Zug, kein Schach
        var b = leer(); b[0] = -6; b[10] = 5; b[17] = 6
        let s = Schach(brett: b, dran: -1)
        XCTAssertTrue(s.patt); XCTAssertFalse(s.schachmatt); XCTAssertTrue(s.remis)
    }
    func testKeineRochadeDurchSchach() {
        // Weißer König e1 (60), Turm h1 (63); schwarzer Turm f8 (5) kontrolliert f1 (61): kurze Rochade verboten
        var b = leer(); b[60] = 6; b[63] = 4; b[4] = -6; b[5] = -4
        let s = Schach(brett: b, dran: 1, rochade: [true, false, false, false])
        XCTAssertFalse(s.zuege.contains(SchachZug(60, 62)))
    }
    func testKeineRochadeImSchach() {
        var b = leer(); b[60] = 6; b[63] = 4; b[4] = -6; b[44] = -4     // schwarzer Turm e6 gibt Schach
        let s = Schach(brett: b, dran: 1, rochade: [true, false, false, false])
        XCTAssertTrue(s.imSchach); XCTAssertFalse(s.zuege.contains(SchachZug(60, 62)))
    }
    func testKoenigszugVerliertRochade() {
        var b = leer(); b[60] = 6; b[63] = 4; b[56] = 4; b[4] = -6
        var s = Schach(brett: b, dran: 1, rochade: [true, true, false, false])
        XCTAssertTrue(s.ziehe(SchachZug(60, 59)))
        XCTAssertFalse(s.rochade[0]); XCTAssertFalse(s.rochade[1])
    }
    func testGefesselteFigurDarfNichtZiehen() {
        // Weißer König e1, weißer Läufer e2 (52) gefesselt durch schwarzen Turm e8 (4)
        var b = leer(); b[60] = 6; b[52] = 3; b[4] = -4; b[0] = -6
        let s = Schach(brett: b, dran: 1)
        XCTAssertTrue(s.zuege(von: 52).isEmpty)
    }
    func testNurKoenigeIstRemis() {
        var b = leer(); b[60] = 6; b[4] = -6
        XCTAssertTrue(Schach(brett: b, dran: 1).remis)
    }
    func testCodableRundlauf() throws {
        var s = Schach(); s.ziehe(SchachZug(52, 36))
        let t = try JSONDecoder().decode(Schach.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(s, t)
    }
}

import SpieleKern
final class SchachAbbruchTests: XCTestCase {
    /// „Beenden“ nach dem ersten Zug zählt als Niederlage des Menschen; ohne gemeldeten Zug zählt es nichts.
    @MainActor func testBeendenNachErstemZugIstEineNiederlage() {
        XCTAssertFalse(SpielZug.hatZug("schach"))
        SpielZug.gemacht("schach")
        XCTAssertTrue(SpielZug.hatZug("schach"))
        let e = PartieMeldung.abbruch(spiel: "schach", teilnehmer: [("Ich", false), ("Computer", true)])
        XCTAssertEqual(e?.teilnehmer.first { $0.name == "Ich" }?.platz, 2)
        XCTAssertEqual(e?.teilnehmer.first { $0.name == "Computer" }?.platz, 1)
        XCTAssertEqual(e?.istRemis, false)
    }
}
