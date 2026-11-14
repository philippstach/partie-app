// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import FlinkhandKern
final class FlinkhandTests: XCTestCase {
    func testKartenBleibenErhalten() {
        var g = SystemRandomNumberGenerator(); var s = Flinkhand(spieler: 3, mit: &g)
        for _ in 0..<3000 where s.sieger == nil {
            s.lege(); if s.passt { s.schnapp(Int.random(in: 0..<3, using: &g)) }
            XCTAssertEqual(s.kartenGesamt, 48)
        }
    }
    func testFalschesSchnappKostetKarte() {
        var g = SystemRandomNumberGenerator(); var s = Flinkhand(spieler: 2, mit: &g)
        let vor = s.haende[0].count
        XCTAssertFalse(s.schnapp(0)); XCTAssertEqual(s.haende[0].count, vor - 1)
    }
    func testPartieEndet() {
        for n in 2...4 {
            var g = SystemRandomNumberGenerator(); var s = Flinkhand(spieler: n, mit: &g); var z = 0
            while s.sieger == nil && z < 200000 {
                s.lege(); if s.passt { s.schnapp(Int.random(in: 0..<n, using: &g)) }; z += 1
            }
            XCTAssertNotNil(s.sieger, "\(n)")
        }
    }

    func testLetzteKarteOhnePaarGewinntDerLetzteLeger() {
        // Spieler 1 hat keine Karten mehr; Spieler 0 legt seine letzte Karte ohne Paar: er hielt alles und gewinnt (nicht automatisch Spieler 0 per Zufall)
        var s = Flinkhand(haende: [[], [3]], mitte: [1, 2], amZug: 1)
        s.lege()
        XCTAssertEqual(s.sieger, 1)
    }
    func testSchnappGibtDenStapelUndSetztAmZug() {
        var s = Flinkhand(haende: [[5, 9], [7, 7, 2]], mitte: [4], amZug: 0)
        s.lege()                 // 5 auf die 4, kein Paar
        XCTAssertFalse(s.passt)
        s.lege()                 // Spieler 1: 7
        s.lege()                 // Spieler 0: 9
        s.lege()                 // Spieler 1: 7 – kein Paar, 9 liegt dazwischen
        XCTAssertFalse(s.passt)
        var t = Flinkhand(haende: [[1], [3, 3, 8]], mitte: [], amZug: 1)
        t.lege(); t.lege()       // Spieler 1 legt 3, Spieler 0 legt 1 – kein Paar
        var u = Flinkhand(haende: [[6, 6], [2, 9]], mitte: [], amZug: 0)
        u.lege(); u.lege(); u.lege()   // 6, 2, 6
        XCTAssertFalse(u.passt)
        var w = Flinkhand(haende: [[6, 1], [6, 9]], mitte: [], amZug: 0)
        w.lege(); w.lege()       // 6, 6 – Paar
        XCTAssertTrue(w.passt)
        XCTAssertTrue(w.schnapp(0))
        XCTAssertEqual(w.haende[0].count, 3); XCTAssertTrue(w.mitte.isEmpty); XCTAssertEqual(w.amZug, 0)
        XCTAssertEqual(w.kartenGesamt, 4)
    }
    func testNachSiegGehtNichtsMehr() {
        var s = Flinkhand(haende: [[], [3]], mitte: [1, 2], amZug: 1)
        s.lege()
        let danach = s
        s.lege(); XCTAssertFalse(s.schnapp(0)); XCTAssertEqual(s, danach)
    }
    func testSchnappMitLeererHandKostetNichts() {
        var s = Flinkhand(haende: [[], [3, 4]], mitte: [1], amZug: 1)
        XCTAssertFalse(s.schnapp(0)); XCTAssertEqual(s.kartenGesamt, 3)
    }
}

final class FlinkhandRegelTests: XCTestCase {
    func testPaarNurBeiZweiGleichenObenaufliegendenMotiven() {
        XCTAssertTrue(Flinkhand(haende: [[1], [2]], mitte: [4, 4]).passt)
        XCTAssertFalse(Flinkhand(haende: [[1], [2]], mitte: [4, 5]).passt)
        XCTAssertFalse(Flinkhand(haende: [[1], [2]], mitte: [4]).passt)
        XCTAssertFalse(Flinkhand(haende: [[1], [2]], mitte: [4, 4, 5]).passt)
    }
    func testRichtigesSchnappGibtDenStapelUndKeineStrafe() {
        var s = Flinkhand(haende: [[1, 2], [3, 4]], mitte: [7, 7])
        XCTAssertTrue(s.schnapp(1))
        XCTAssertEqual(s.haende[1], [3, 4, 7, 7]); XCTAssertTrue(s.mitte.isEmpty); XCTAssertEqual(s.amZug, 1)
        XCTAssertEqual(s.kartenGesamt, 6)
    }
    func testFalschesSchnappLegtStrafkarteUnterDenStapel() {
        var s = Flinkhand(haende: [[1, 2], [3, 4]], mitte: [7, 8])
        XCTAssertFalse(s.schnapp(0))
        XCTAssertEqual(s.mitte, [1, 7, 8], "Strafkarte liegt ganz unten")
        XCTAssertEqual(s.haende[0], [2])
    }
    func testAmZugSpringtUeberLeereHaende() {
        var s = Flinkhand(haende: [[1, 2], [], [5]], mitte: [], amZug: 0)
        s.lege()
        XCTAssertEqual(s.amZug, 2, "Spieler 1 hat keine Karten und wird übersprungen")
    }
    func testLegenMitLeererHandAendertNichts() {
        var s = Flinkhand(haende: [[], [2, 3]], mitte: [], amZug: 0)
        let vorher = s
        s.lege()
        XCTAssertEqual(s, vorher)
    }
    func testSpielerzahlWirdBegrenztUndAlleMotiveVierfach() {
        var g = SystemRandomNumberGenerator()
        XCTAssertEqual(Flinkhand(spieler: 1, mit: &g).spieler, 2)
        let s = Flinkhand(spieler: 9, mit: &g)
        XCTAssertEqual(s.spieler, 4)
        let alle = s.haende.flatMap { $0 }
        XCTAssertEqual(alle.count, 48)
        for m in 0..<Flinkhand.motive { XCTAssertEqual(alle.filter { $0 == m }.count, 4) }
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var s = Flinkhand(spieler: 3, mit: &g); s.lege(); s.lege()
        let neu = try JSONDecoder().decode(Flinkhand.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}
