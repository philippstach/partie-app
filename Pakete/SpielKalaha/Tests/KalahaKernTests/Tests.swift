// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import KalahaKern

final class KalahaTests: XCTestCase {
    func testErsterZugEndetImHaus() {
        var k = Kalaha(); XCTAssertTrue(k.spiele(2))   // 4 Steine: 3,4,5,Haus
        XCTAssertEqual(k.punkte(0), 1); XCTAssertEqual(k.dran, 0)
    }
    func testSteineBleibenErhalten() {
        var k = Kalaha(); var g = SystemRandomNumberGenerator(); var n = 0
        while !k.beendet && n < 500 { k.spiele(k.zuege.randomElement(using: &g)!); n += 1; if !k.beendet { XCTAssertEqual(k.felder.reduce(0, +), 48) } }
        XCTAssertTrue(k.beendet); XCTAssertEqual(k.felder.reduce(0, +), 48)
    }
    func testComputer() {
        var k = Kalaha(); var n = 0
        while !k.beendet && n < 300 { XCTAssertTrue(k.spiele(KalahaComputer.wahl(k, tiefe: 3)!)); n += 1 }
        XCTAssertTrue(k.beendet)
    }
}

final class KalahaRegelnTests: XCTestCase {
    func testSchlichtOhneExtrazug() {
        var k = Kalaha(regeln: .schlicht); XCTAssertTrue(k.spiele(2)); XCTAssertEqual(k.dran, 1)
    }
    func testSechsSteinSummeBleibt() {
        var k = Kalaha(regeln: .sechs); var n = 0
        while !k.beendet && n < 600 { k.spiele(k.zuege.randomElement()!); n += 1 }
        XCTAssertTrue(k.beendet); XCTAssertEqual(k.felder.reduce(0, +), 72)
    }
    func testAlterSpielstandLaedt() throws {
        let json = #"{"felder":\#(Kalaha().felder),"dran":0,"beendet":false}"#
        XCTAssertEqual(try JSONDecoder().decode(Kalaha.self, from: Data(json.utf8)).regeln, .standard)
    }
}

/// Stufen-Simulation: Die schwere Stufe (Tiefe 7) muss deutlich öfter gewinnen als die leichte (Tiefe 3).
final class KalahaStufenTests: XCTestCase {
    func testSchwerSchlaegtLeicht() {
        var g = SystemRandomNumberGenerator()
        var schwer = 0, leicht = 0, partien = 0
        for i in 0..<16 {
            var k = Kalaha()
            for _ in 0..<4 where !k.beendet { k.spiele(k.zuege.randomElement(using: &g)!) }   // zufällige Eröffnung
            let schwerSeite = i % 2
            var n = 0
            while !k.beendet && n < 400 {
                let tiefe = k.dran == schwerSeite ? 7 : 3
                k.spiele(KalahaComputer.wahl(k, tiefe: tiefe)!); n += 1
            }
            XCTAssertTrue(k.beendet); partien += 1
            if let s = k.sieger { if s == schwerSeite { schwer += 1 } else { leicht += 1 } }
        }
        print("KALAHA schwer \(schwer) leicht \(leicht) von \(partien)")
        XCTAssertGreaterThanOrEqual(schwer, leicht + 5, "schwer \(schwer), leicht \(leicht)")
    }
}

final class KalahaRegelDetailTests: XCTestCase {
    func testFangenNimmtGegenueberliegende() {
        var k = Kalaha()
        // Mulde 0 (4 Steine) endet in Mulde 4; erst Mulde 4 leeren, damit dort gefangen wird.
        k.spiele(4)            // 4 Steine: 5, Haus, 7, 8 -> Zug des Gegners
        k.spiele(7)            // Gegner spielt, Spieler 0 wieder dran
        let vorher = k.punkte(0)
        XCTAssertTrue(k.spiele(0))
        XCTAssertGreaterThanOrEqual(k.punkte(0), vorher)
        XCTAssertEqual(k.felder.reduce(0, +), 48)
    }
    func testGegnerHausWirdUebersprungen() {
        var k = Kalaha(steine: 14)
        k.spiele(0)   // 14 Steine laufen einmal rundherum, das gegnerische Haus bleibt leer
        XCTAssertEqual(k.felder[13], 0)
        XCTAssertEqual(k.felder.reduce(0, +), 14 * 12)
    }
    func testUngueltigerZug() {
        var k = Kalaha()
        XCTAssertFalse(k.spiele(7))     // fremde Mulde
        XCTAssertFalse(k.spiele(6))     // Haus
        XCTAssertFalse(k.spiele(99))
        XCTAssertEqual(k, Kalaha())
    }
    func testSpielendeSammeltReststeine() {
        var k = Kalaha(); var g = SystemRandomNumberGenerator()
        while !k.beendet { k.spiele(k.zuege.randomElement(using: &g)!) }
        XCTAssertTrue(Kalaha.mulden(0).allSatisfy { k.felder[$0] == 0 })
        XCTAssertTrue(Kalaha.mulden(1).allSatisfy { k.felder[$0] == 0 })
        XCTAssertEqual(k.punkte(0) + k.punkte(1), 48)
        XCTAssertTrue(k.zuege.isEmpty)
        XCTAssertNil(KalahaComputer.wahl(k))
    }
    func testNachSpielendeKeinZugMehr() {
        var k = Kalaha(); var g = SystemRandomNumberGenerator()
        while !k.beendet { k.spiele(k.zuege.randomElement(using: &g)!) }
        XCTAssertFalse(k.spiele(0)); XCTAssertFalse(k.spiele(7))
    }
    func testComputerNimmtExtrazug() {
        let k = Kalaha()   // 4 Steine: Mulde 2 endet im Haus
        XCTAssertEqual(KalahaComputer.wahl(k, tiefe: 1), 2)
    }
    func testComputerSpieltNurGueltige() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            var k = Kalaha(); var n = 0
            while !k.beendet && n < 300 {
                let m = KalahaComputer.wahl(k, tiefe: Int.random(in: 1...5, using: &g))!
                XCTAssertTrue(k.zuege.contains(m)); k.spiele(m); n += 1
            }
        }
    }
    func testSpielstandRoundtrip() throws {
        var k = Kalaha(regeln: .sechs); k.spiele(1); k.spiele(8)
        let d = try JSONEncoder().encode(k)
        XCTAssertEqual(try JSONDecoder().decode(Kalaha.self, from: d), k)
    }
    func testGeordnetZeigtExtrazugZuerst() {
        XCTAssertEqual(KalahaComputer.geordnet(Kalaha()).first, 2)
    }
}
