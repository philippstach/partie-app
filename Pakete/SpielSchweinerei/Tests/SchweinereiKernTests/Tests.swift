// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchweinereiKern

final class SchweinereiTests: XCTestCase {
    func testEinsVerliertRunde() {
        var s = Schweinerei(spieler: 2); s.setzeWurf(5); s.setzeWurf(3); XCTAssertEqual(s.runde, 8)
        s.setzeWurf(1); XCTAssertEqual(s.runde, 0); XCTAssertEqual(s.dran, 1); XCTAssertEqual(s.punkte, [0, 0]); XCTAssertTrue(s.verfallen)
    }
    func testSichern() {
        var s = Schweinerei(spieler: 2); s.setzeWurf(6); s.setzeWurf(4); s.sichern()
        XCTAssertEqual(s.punkte, [10, 0]); XCTAssertEqual(s.dran, 1); XCTAssertEqual(s.runde, 0)
    }
    func testSiegUndComputer() {
        var s = Schweinerei(spieler: 2, ziel: 50); var g = SystemRandomNumberGenerator(); var n = 0
        while s.sieger == nil && n < 5000 {
            s.wuerfeln(mit: &g)
            if s.sieger == nil, s.runde > 0, SchweinereiComputer.sichert(s) { s.sichern() }
            n += 1
        }
        XCTAssertNotNil(s.sieger)
    }
    func testStufenSpielenZuEnde() {
        for stufe in 1...3 {
            for _ in 0..<100 {
                var g = SystemRandomNumberGenerator(); var s = Schweinerei(spieler: 2); var n = 0
                while s.sieger == nil && n < 20000 { n += 1; if s.runde > 0, SchweinereiComputer.sichert(s, stufe: stufe) { s.sichern() } else { s.wuerfeln(mit: &g) } }
                XCTAssertNotNil(s.sieger)
            }
        }
    }
    func testSchwerSchlaegtLeicht() {
        var siege = 0
        for _ in 0..<600 {
            var g = SystemRandomNumberGenerator(); var s = Schweinerei(spieler: 2)
            while s.sieger == nil { if s.runde > 0, SchweinereiComputer.sichert(s, stufe: s.dran == 0 ? 3 : 1) { s.sichern() } else { s.wuerfeln(mit: &g) } }
            if s.sieger == 0 { siege += 1 }
        }
        XCTAssertGreaterThan(siege, 330)
    }
}

final class SchweinereiRegelTests: XCTestCase {
    func testWuerfeBisZurEinsSammelnDieRunde() {
        var s = Schweinerei(spieler: 2)
        s.setzeWurf(4); s.setzeWurf(6)
        XCTAssertEqual(s.runde, 10); XCTAssertEqual(s.dran, 0); XCTAssertEqual(s.punkte, [0, 0])
    }
    func testEinsVerwirftDieRundeUndWechselt() {
        var s = Schweinerei(spieler: 2)
        s.setzeWurf(5); s.setzeWurf(1)
        XCTAssertEqual(s.runde, 0); XCTAssertTrue(s.verfallen); XCTAssertEqual(s.dran, 1); XCTAssertEqual(s.punkte, [0, 0])
    }
    func testSichernSchreibtGutUndWechselt() {
        var s = Schweinerei(spieler: 3)
        s.setzeWurf(6); s.setzeWurf(3); s.sichern()
        XCTAssertEqual(s.punkte, [9, 0, 0]); XCTAssertEqual(s.dran, 1); XCTAssertEqual(s.runde, 0); XCTAssertNil(s.letzterWurf)
    }
    func testSichernOhneRundenpunkteTutNichts() {
        var s = Schweinerei(spieler: 2)
        s.sichern()
        XCTAssertEqual(s.dran, 0); XCTAssertEqual(s.punkte, [0, 0])
    }
    func testWerZuerstDasZielErreichtGewinnt() {
        var s = Schweinerei(spieler: 2, ziel: 20)
        s.setzeWurf(6); s.setzeWurf(6); s.setzeWurf(6); s.setzeWurf(2); s.sichern()
        XCTAssertEqual(s.sieger, 0)
        let stand = s
        s.setzeWurf(3); s.sichern()
        XCTAssertEqual(s, stand, "Nach dem Sieg ändert sich nichts mehr")
    }
    func testUngueltigeWuerfeWerdenIgnoriert() {
        var s = Schweinerei(spieler: 2); let stand = s
        s.setzeWurf(0); s.setzeWurf(7)
        XCTAssertEqual(s, stand)
    }
    func testComputerSichertImmerBeiZielErreichung() {
        var s = Schweinerei(spieler: 2, ziel: 30)
        s.setzeWurf(6); s.setzeWurf(6); s.setzeWurf(6); s.setzeWurf(6); s.setzeWurf(6)
        for stufe in 1...3 { XCTAssertTrue(SchweinereiComputer.sichert(s, stufe: stufe)) }
    }
    func testLeichterComputerSichertFruehAbZehn() {
        var s = Schweinerei(spieler: 2)
        s.setzeWurf(5); s.setzeWurf(5)
        XCTAssertTrue(SchweinereiComputer.sichert(s, stufe: 1)); XCTAssertFalse(SchweinereiComputer.sichert(s, stufe: 2))
    }
    func testSpielstandIstCodierbar() throws {
        var s = Schweinerei(spieler: 3, ziel: 50)
        s.setzeWurf(4); s.sichern(); s.setzeWurf(2)
        let neu = try JSONDecoder().decode(Schweinerei.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}
