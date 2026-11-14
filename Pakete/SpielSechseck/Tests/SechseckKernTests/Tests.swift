// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SechseckKern
final class SechseckTests: XCTestCase {
    func testNachbarn() {
        let s = Sechseck(groesse: 5)
        XCTAssertEqual(s.nachbarIndizes(s.index(2, 2)).count, 6); XCTAssertEqual(s.nachbarIndizes(0).count, 2); XCTAssertEqual(s.nachbarIndizes(s.index(4, 0)).count, 3)
    }
    func testBlauSiegtMitSpalte() {
        var s = Sechseck(groesse: 5)
        for y in 0..<5 { s.setze(s.index(2, y)); if y < 4 { s.setze(s.index(0, y)) } }
        XCTAssertEqual(s.sieger, 1)
    }
    func testRotSiegtMitReihe() {
        var s = Sechseck(groesse: 5)
        s.setze(s.index(0, 0))   // Blau
        for x in 0..<5 { s.setze(s.index(x, 2)); if x < 4 { s.setze(s.index(x, 4)) } }
        XCTAssertEqual(s.sieger, 2)
    }
    func testGenauEinGewinnerBeiVollemBrett() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<50 {
            var s = Sechseck(groesse: 6)
            for i in s.freie.shuffled(using: &g) { if s.sieger == nil { s.setze(i) } }
            XCTAssertNotNil(s.sieger)
        }
    }
    func testComputerSchlaegtZufall() {
        var g = SystemRandomNumberGenerator(); var siege = 0
        for k in 0..<10 {
            var s = Sechseck(groesse: 7)
            let computerIst = k % 2 == 0 ? 1 : 2
            while s.sieger == nil {
                if s.amZug == computerIst { s.setze(s.computerZug(spiele: 25, mit: &g)!) } else { s.setze(s.computerZug(spiele: 0, mit: &g)!) }
            }
            if s.sieger == computerIst { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 8)
    }
}

final class SechseckRegelTests: XCTestCase {
    func testBlauBeginntUndDieSpielerWechseln() {
        var s = Sechseck(groesse: 5)
        XCTAssertEqual(s.amZug, 1)
        s.setze(0); XCTAssertEqual(s.amZug, 2); s.setze(1); XCTAssertEqual(s.amZug, 1)
        XCTAssertEqual(s.zuege, 2); XCTAssertEqual(s.letzter, 1)
    }
    func testBesetzteUndFremdeFelderWerdenAbgelehnt() {
        var s = Sechseck(groesse: 5)
        XCTAssertTrue(s.setze(3)); XCTAssertFalse(s.setze(3)); XCTAssertFalse(s.setze(-1)); XCTAssertFalse(s.setze(25))
        XCTAssertEqual(s.zuege, 1); XCTAssertEqual(s.amZug, 2)
    }
    func testNachDemSiegIstSchluss() {
        var s = Sechseck(groesse: 3)
        for y in 0..<3 { s.setze(s.index(1, y)); if y < 2 { s.setze(s.index(0, y)) } }
        XCTAssertEqual(s.sieger, 1)
        XCTAssertFalse(s.setze(s.index(2, 2)))
    }
    func testDiagonaleVerbindungGiltAlsBenachbart() {
        // Nachbarn: (1,-1) und (-1,1) sind verbunden, (1,1) nicht
        var s = Sechseck(groesse: 3)
        s.setze(s.index(2, 0)); s.setze(s.index(0, 0)); s.setze(s.index(1, 1)); s.setze(s.index(0, 1)); s.setze(s.index(0, 2))
        XCTAssertEqual(s.sieger, 1, "(2,0)-(1,1)-(0,2) ist eine Kette über die (1,-1)-Nachbarschaft")
    }
    func testGleichfarbigeGegenueberReichenNichtOhneVerbindung() {
        var s = Sechseck(groesse: 4)
        s.setze(s.index(0, 0)); s.setze(s.index(3, 0)); s.setze(s.index(0, 3))
        XCTAssertNil(s.sieger); XCTAssertFalse(s.verbunden(1)); XCTAssertFalse(s.verbunden(2))
    }
    func testComputerSetztZuerstInDieMitte() {
        var g = SystemRandomNumberGenerator()
        let s = Sechseck(groesse: 7)
        XCTAssertEqual(s.computerZug(spiele: 5, mit: &g), s.index(3, 3))
    }
    func testComputerGewinntSofortWennMoeglich() {
        var g = SystemRandomNumberGenerator()
        var s = Sechseck(groesse: 4)
        // Blau hat x=1 von y=0..2, Rot setzt irgendwo anders; Blau am Zug soll (1,3) setzen
        for y in 0..<3 { s.setze(s.index(1, y)); s.setze(s.index(3, y)) }
        XCTAssertEqual(s.amZug, 1)
        XCTAssertTrue([s.index(1, 3), s.index(0, 3)].contains(s.computerZug(spiele: 10, mit: &g)!), "beide Felder schließen die Kette")
    }
    func testComputerBlocktDenSofortigenGewinnDesGegners() {
        var g = SystemRandomNumberGenerator()
        var s = Sechseck(groesse: 4)
        s.setze(s.index(0, 3)); s.setze(s.index(0, 0)); s.setze(s.index(1, 3)); s.setze(s.index(1, 0)); s.setze(s.index(2, 3)); s.setze(s.index(2, 0))
        // Rot (2) hat y=0, x=0..2: braucht (3,0); Blau ist am Zug und muss blocken (Blau selbst hat nur die untere Reihe)
        XCTAssertEqual(s.amZug, 1)
        XCTAssertEqual(s.computerZug(spiele: 10, mit: &g), s.index(3, 0))
    }
    func testSpielstandIstCodierbar() throws {
        var s = Sechseck(groesse: 5); s.setze(7); s.setze(8)
        let neu = try JSONDecoder().decode(Sechseck.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}

final class SechseckStufenTests: XCTestCase {
    func testMehrZuspieleSchlagenWenigeZuspiele() {
        var g = SystemRandomNumberGenerator(); var stark = 0
        for k in 0..<10 {
            var s = Sechseck(groesse: 7); let starkIst = 1 + k % 2
            while s.sieger == nil { s.setze(s.computerZug(spiele: s.amZug == starkIst ? 60 : 3, mit: &g)!) }
            if s.sieger == starkIst { stark += 1 }
        }
        print("SECHSECK stark \(stark) von 10")
        XCTAssertGreaterThanOrEqual(stark, 6)
    }
    func testVollesBrettHatKeinenZug() {
        var g = SystemRandomNumberGenerator(); var s = Sechseck(groesse: 3)
        while s.sieger == nil { s.setze(s.freie.randomElement(using: &g)!) }
        XCTAssertNil(s.sieger == nil ? 0 : nil as Int?)
        XCTAssertFalse(s.setze(0))
    }
    func testGroessenVonDreiBisElfSpielbar() {
        var g = SystemRandomNumberGenerator()
        for n in [3, 5, 9, 11] {
            var s = Sechseck(groesse: n); var k = 0
            while s.sieger == nil && k < n * n { s.setze(s.computerZug(spiele: 0, mit: &g)!); k += 1 }
            XCTAssertNotNil(s.sieger, "Größe \(n)")
        }
    }
}
