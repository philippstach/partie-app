// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import KartenduellKern
final class KartenduellTests: XCTestCase {
    func testKartenBleibenErhalten() {
        var g = SystemRandomNumberGenerator(); var s = Kartenduell(mit: &g)
        XCTAssertEqual(s.kartenGesamt, 52)
        for _ in 0..<2000 where s.sieger == nil { s.aufdecken(mit: &g); XCTAssertEqual(s.kartenGesamt, 52) }
    }
    func testPartieEndet() {
        for _ in 0..<50 {
            var g = SystemRandomNumberGenerator(); var s = Kartenduell(mit: &g)
            while s.sieger == nil { s.aufdecken(mit: &g) }
            XCTAssertNotNil(s.sieger)
        }
    }
}

final class KartenduellRegelTests: XCTestCase {
    func testHoehereKarteNimmtBeide() {
        var g = SystemRandomNumberGenerator()
        var s = Kartenduell(stapel: [[10, 3], [5, 3]])
        XCTAssertTrue(s.aufdecken(mit: &g))
        XCTAssertEqual(s.stapel[0].count, 3); XCTAssertEqual(s.stapel[1].count, 1)
        XCTAssertEqual(s.letzterGewinner, 0); XCTAssertEqual(s.offen[0], 10); XCTAssertEqual(s.offen[1], 5)
    }
    func testAssIstAmHoechsten() {
        var g = SystemRandomNumberGenerator()
        var s = Kartenduell(stapel: [[2, 9], [14, 9]])
        s.aufdecken(mit: &g)
        XCTAssertEqual(s.letzterGewinner, 1)
    }
    func testGleichstandErzeugtStreitUndDritteKartenZaehlen() {
        var g = SystemRandomNumberGenerator()
        // Streit: beide 7; dann je drei verdeckt (2,3,4 / 5,6,8) und offen 9 gegen 10 → Spieler 2 nimmt alles (10 Karten).
        var s = Kartenduell(stapel: [[7, 2, 3, 4, 9, 11], [7, 5, 6, 8, 10, 12]])
        XCTAssertFalse(s.aufdecken(mit: &g)); XCTAssertEqual(s.streit, 1); XCTAssertEqual(s.mitte.count, 2)
        XCTAssertTrue(s.aufdecken(mit: &g))
        XCTAssertEqual(s.streit, 0); XCTAssertEqual(s.letzterGewinner, 1)
        XCTAssertEqual(s.stapel[0].count, 1); XCTAssertEqual(s.stapel[1].count, 11); XCTAssertTrue(s.mitte.isEmpty)
    }
    func testWerKeineKartenMehrHatVerliert() {
        var g = SystemRandomNumberGenerator()
        var s = Kartenduell(stapel: [[14], [2]])
        s.aufdecken(mit: &g)
        XCTAssertEqual(s.sieger, 0)
        XCTAssertFalse(s.aufdecken(mit: &g), "Nach dem Ende keine Runde mehr")
    }
    func testLeererStapelBeiBeginnGibtDemGegnerDenSieg() {
        var g = SystemRandomNumberGenerator()
        var s = Kartenduell(stapel: [[], [5]])
        s.aufdecken(mit: &g)
        XCTAssertEqual(s.sieger, 1)
    }
    func testStreitMitLetzterKarteEntscheidetDasSpiel() {
        var g = SystemRandomNumberGenerator()
        var s = Kartenduell(stapel: [[8], [8, 3]])
        s.aufdecken(mit: &g)
        XCTAssertNotNil(s.sieger, "Gleichstand mit leerem Stapel beendet die Partie")
        XCTAssertEqual(s.kartenGesamt, 3)
    }
    func testRundenGrenzeEntscheidetNachKartenzahl() {
        var g = SystemRandomNumberGenerator()
        var s = Kartenduell(stapel: [[14, 14 - 1, 3, 4], [2, 2 - 0, 2]])
        var n = 0
        while s.sieger == nil && n < 1000 { s.aufdecken(mit: &g); n += 1 }
        XCTAssertNotNil(s.sieger)
        XCTAssertEqual(s.kartenGesamt, 7)
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var s = Kartenduell(mit: &g); s.aufdecken(mit: &g); s.aufdecken(mit: &g)
        let neu = try JSONDecoder().decode(Kartenduell.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
    func testNeuesSpielVerteiltJeSechsundzwanzig() {
        var g = SystemRandomNumberGenerator()
        let s = Kartenduell(mit: &g)
        XCTAssertEqual(s.stapel.map(\.count), [26, 26])
        for w in 2...14 { XCTAssertEqual((s.stapel[0] + s.stapel[1]).filter { $0 == w }.count, 4) }
    }
}

final class KartenduellRegelnTests: XCTestCase {
    func testGleicheKartenZaehlenImStreitUndGewinnerNimmtAlles() {
        var g = SystemRandomNumberGenerator()
        var k = Kartenduell(stapel: [[5, 2, 3, 4, 9], [5, 6, 7, 8, 3]])
        XCTAssertFalse(k.aufdecken(mit: &g)); XCTAssertEqual(k.streit, 1)
        XCTAssertTrue(k.aufdecken(mit: &g))
        XCTAssertEqual(k.letzterGewinner, 0); XCTAssertEqual(k.stapel[0].count, 10); XCTAssertEqual(k.stapel[1].count, 0)
    }
    func testKartenzahlBleibtImmerZweiundfuenfzig() {
        for _ in 0..<20 {
            var g = SystemRandomNumberGenerator(); var k = Kartenduell(mit: &g); var n = 0
            while k.sieger == nil && n < 2000 { k.aufdecken(mit: &g); n += 1; XCTAssertEqual(k.kartenGesamt, 52) }
        }
    }
    func testNachDemSiegIstKeinZugMehrMoeglich() {
        var g = SystemRandomNumberGenerator(); var k = Kartenduell(stapel: [[14], [2]])
        XCTAssertTrue(k.aufdecken(mit: &g)); XCTAssertEqual(k.sieger, 0)
        XCTAssertFalse(k.aufdecken(mit: &g)); XCTAssertEqual(k.runden, 1)
    }
    func testNiedrigereKarteGewinntNicht() {
        var g = SystemRandomNumberGenerator(); var k = Kartenduell(stapel: [[2, 9], [3, 4]])
        XCTAssertTrue(k.aufdecken(mit: &g)); XCTAssertEqual(k.letzterGewinner, 1); XCTAssertEqual(k.stapel[1].count, 3)
    }
    func testDoppelterStreitHaeltDenEinsatzInDerMitte() {
        var g = SystemRandomNumberGenerator()
        var k = Kartenduell(stapel: [[7, 2, 2, 2, 9, 2, 2, 2, 11], [7, 3, 3, 3, 9, 3, 3, 3, 4]])
        k.aufdecken(mit: &g); k.aufdecken(mit: &g)
        XCTAssertEqual(k.streit, 2); XCTAssertEqual(k.mitte.count, 2 + 6 + 2)
        XCTAssertTrue(k.aufdecken(mit: &g)); XCTAssertEqual(k.letzterGewinner, 0)
        XCTAssertEqual(k.kartenGesamt, 18)
    }
    func testKurzerStapelImStreitLegtWenigerVerdeckteKarten() {
        var g = SystemRandomNumberGenerator()
        var k = Kartenduell(stapel: [[6, 2, 12], [6, 3, 3, 3, 4]])
        k.aufdecken(mit: &g); k.aufdecken(mit: &g)
        XCTAssertEqual(k.kartenGesamt, 8); XCTAssertEqual(k.letzterGewinner, 0)
    }
    func testGleichstandMitLetzterKarteBeendetDasSpiel() {
        var g = SystemRandomNumberGenerator(); var k = Kartenduell(stapel: [[6], [6]])
        k.aufdecken(mit: &g); XCTAssertNotNil(k.sieger)
    }
    func testEinzelnePartieEndetImmer() {
        for _ in 0..<50 {
            var g = SystemRandomNumberGenerator(); var k = Kartenduell(mit: &g); var n = 0
            while k.sieger == nil && n < 5000 { k.aufdecken(mit: &g); n += 1 }
            XCTAssertNotNil(k.sieger); XCTAssertLessThanOrEqual(k.runden, Kartenduell.maxRunden + 1)
        }
    }
}
