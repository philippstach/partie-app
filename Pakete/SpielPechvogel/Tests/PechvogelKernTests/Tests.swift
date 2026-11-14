// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import PechvogelKern

final class PechvogelTests: XCTestCase {
    func testAnfangOhnePaare() {
        var g = SystemRandomNumberGenerator()
        for n in 2...4 {
            let s = Pechvogel(spieler: n, mit: &g)
            for h in s.haende { let m = h.filter { $0 != Pechvogel.pechvogel }; XCTAssertEqual(Set(m).count, m.count) }
            XCTAssertTrue(s.haende.joined().contains(Pechvogel.pechvogel))
        }
    }
    func testPartienEndenMitVerlierer() {
        for n in 2...4 {
            for _ in 0..<50 {
                var g = SystemRandomNumberGenerator(); var s = Pechvogel(spieler: n, mit: &g); var z = 0
                while s.verlierer == nil && z < 1000 { s.ziehe(s.computerWahl(mit: &g)!, mit: &g); z += 1 }
                XCTAssertNotNil(s.verlierer)
                XCTAssertEqual(s.haende[s.verlierer!], [Pechvogel.pechvogel])
                XCTAssertEqual(s.kartenGesamt, 1)
            }
        }
    }
    func testZiehenVomNachbarn() {
        var g = SystemRandomNumberGenerator(); var s = Pechvogel(spieler: 3, mit: &g)
        let n = s.nachbar!; let vor = s.haende[n].count
        s.ziehe(0, mit: &g)
        XCTAssertEqual(s.haende[n].count, vor - 1)
    }
}

final class PechvogelRegelTests: XCTestCase {
    func testGezogenesPaarWirdSofortAbgelegt() {
        var g = SystemRandomNumberGenerator()
        var s = Pechvogel(haende: [[1, 2], [1, 3]])
        s.ziehe(0, mit: &g)                     // Spieler 0 zieht die 1 von Spieler 1
        XCTAssertEqual(s.haende[0], [2]); XCTAssertEqual(s.haende[1], [3])
        XCTAssertEqual(s.letzteAblage, [1]); XCTAssertEqual(s.gezogen, 1); XCTAssertEqual(s.amZug, 1)
    }
    func testKeinPaarDieKarteBleibtInDerHand() {
        var g = SystemRandomNumberGenerator()
        var s = Pechvogel(haende: [[1, 2], [3, 4]])
        s.ziehe(1, mit: &g)
        XCTAssertEqual(s.haende[0].count, 3); XCTAssertEqual(s.haende[1], [3]); XCTAssertTrue(s.letzteAblage.isEmpty)
    }
    func testWerDenPechvogelAlleinBehaeltVerliert() {
        var g = SystemRandomNumberGenerator()
        var s = Pechvogel(haende: [[5], [5, Pechvogel.pechvogel]])
        s.ziehe(0, mit: &g)                     // zieht die 5, legt das Paar ab; Spieler 1 hat nur noch den Pechvogel
        XCTAssertEqual(s.verlierer, 1)
        XCTAssertFalse(s.ziehe(0, mit: &g), "Nach dem Ende wird nicht mehr gezogen")
    }
    func testUngueltigerIndexWirdAbgelehnt() {
        var g = SystemRandomNumberGenerator()
        var s = Pechvogel(haende: [[1], [1, 2]])
        XCTAssertFalse(s.ziehe(7, mit: &g)); XCTAssertFalse(s.ziehe(-1, mit: &g))
        XCTAssertEqual(s.amZug, 0)
    }
    func testNachbarUeberspringtSpielerOhneKarten() {
        let s = Pechvogel(haende: [[1, 2], [], [3, 4]], amZug: 0)
        XCTAssertEqual(s.nachbar, 2)
    }
    func testAmZugSpringtUeberLeereHaende() {
        var g = SystemRandomNumberGenerator()
        var s = Pechvogel(haende: [[1], [2, 2, 3], [1, 4]], amZug: 2)
        s.ziehe(0, mit: &g)                     // Spieler 2 zieht von Spieler 0 die 1 und legt das Paar ab
        XCTAssertTrue(s.haende[0].isEmpty); XCTAssertEqual(s.amZug, 1, "Spieler 0 ist fertig, weiter mit 1")
    }
    func testDreizehnPaarePlusPechvogelBeimStart() {
        var g = SystemRandomNumberGenerator()
        let s = Pechvogel(spieler: 4, mit: &g)
        let alle = s.haende.flatMap { $0 }
        XCTAssertEqual(alle.filter { $0 == Pechvogel.pechvogel }.count, 1)
        XCTAssertLessThanOrEqual(alle.count, 27)
        XCTAssertEqual(alle.count % 2, 1, "Nach dem Ablegen bleibt eine ungerade Kartenzahl")
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var s = Pechvogel(spieler: 3, mit: &g); s.ziehe(0, mit: &g)
        let neu = try JSONDecoder().decode(Pechvogel.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}

final class PechvogelRegelnTests: XCTestCase {
    func testAnzahlSpielerWirdAuf2Bis4Begrenzt() {
        var g = SystemRandomNumberGenerator()
        XCTAssertEqual(Pechvogel(spieler: 1, mit: &g).spieler, 2); XCTAssertEqual(Pechvogel(spieler: 9, mit: &g).spieler, 4)
    }
    func testNachDemAblegenGibtEsKeinPaarInEinerHand() {
        for n in 2...4 { for _ in 0..<50 {
            var g = SystemRandomNumberGenerator(); let p = Pechvogel(spieler: n, mit: &g)
            for h in p.haende { XCTAssertEqual(h.count, Set(h).count) }
            XCTAssertTrue(p.haende.joined().contains(Pechvogel.pechvogel) || p.verlierer != nil)
        } }
    }
    func testPechvogelBleibtImmerImSpiel() {
        for _ in 0..<100 {
            var g = SystemRandomNumberGenerator(); var p = Pechvogel(spieler: 3, mit: &g); var n = 0
            while p.verlierer == nil && n < 400 { n += 1; _ = p.ziehe(p.computerWahl(mit: &g)!, mit: &g); XCTAssertTrue(p.haende.joined().contains(Pechvogel.pechvogel)) }
            XCTAssertNotNil(p.verlierer)
            XCTAssertEqual(p.haende[p.verlierer!], [Pechvogel.pechvogel])
        }
    }
    func testNachbarIstDerNaechsteMitKarten() {
        let p = Pechvogel(haende: [[1], [], [2, -1]], amZug: 0)
        XCTAssertEqual(p.nachbar, 2); XCTAssertEqual(p.aktive, [0, 2])
    }
    func testNichtsMehrZuZiehenNachSpielende() {
        var g = SystemRandomNumberGenerator(); var p = Pechvogel(haende: [[5], [5, Pechvogel.pechvogel]], amZug: 0)
        XCTAssertTrue(p.ziehe(0, mit: &g)); XCTAssertEqual(p.verlierer, 1) 
        XCTAssertFalse(p.ziehe(0, mit: &g))
    }
    func testZiehenVomPechvogelBringtIhnInDieHand() {
        var g = SystemRandomNumberGenerator(); var p = Pechvogel(haende: [[3], [Pechvogel.pechvogel, 3]], amZug: 0)
        XCTAssertTrue(p.ziehe(0, mit: &g))      // Spieler 0 zieht den Pechvogel, das Spiel geht weiter
        XCTAssertTrue(p.haende[0].contains(Pechvogel.pechvogel)); XCTAssertNil(p.verlierer); XCTAssertEqual(p.amZug, 1)
    }
    func testComputerWahlLiegtImBereichDerNachbarhand() {
        var g = SystemRandomNumberGenerator(); let p = Pechvogel(haende: [[1, 2], [3, 4, -1]], amZug: 0)
        for _ in 0..<50 { XCTAssertTrue((0..<3).contains(p.computerWahl(mit: &g)!)) }
    }
}
