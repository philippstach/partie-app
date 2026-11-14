// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import DominoKern
final class DominoTests: XCTestCase {
    func testSatz() {
        var g = SystemRandomNumberGenerator()
        for n in 2...4 { let s = Domino(spieler: n, mit: &g); XCTAssertEqual(s.steinGesamt, 28); XCTAssertEqual(Set((s.haende.joined()) + s.vorrat).count, 28) }
    }
    func testKetteBleibtPassend() {
        for _ in 0..<50 {
            var g = SystemRandomNumberGenerator(); var s = Domino(spieler: 3, mit: &g); var z = 0
            while s.sieger == nil && z < 500 {
                s.computerSchritt(); z += 1
                XCTAssertEqual(s.steinGesamt, 28)
                for (a, b) in zip(s.kette, s.kette.dropFirst()) { XCTAssertEqual(a.b, b.a) }
            }
            XCTAssertNotNil(s.sieger)
        }
    }
    func testUngueltigesLegen() {
        var g = SystemRandomNumberGenerator(); var s = Domino(spieler: 2, mit: &g)
        s.lege(0, seite: .rechts)
        let n = s.amZug
        if let i = s.haende[n].indices.first(where: { !s.passt(s.haende[n][$0], an: .links) && !s.passt(s.haende[n][$0], an: .rechts) }) { XCTAssertFalse(s.lege(i, seite: .links)) }
    }
}

final class DoppelNeunTests: XCTestCase {
    func testDoppelNeunHat55Steine() {
        var g = SystemRandomNumberGenerator()
        let d = Domino(spieler: 2, hoechstAugen: 9, handgroesse: 10, mit: &g)
        XCTAssertEqual(d.steinGesamt, 55)
        XCTAssertEqual(d.haende[0].count, 10)
        XCTAssertEqual(d.vorrat.count, 35)
    }
    func testFehlerhafterComputerSpieltLegalBisZumEnde() {
        for fehler in [0.5, 1.0] { for _ in 0..<30 {
            var g = SystemRandomNumberGenerator(); var s = Domino(spieler: 2, mit: &g); var z = 0
            while s.sieger == nil && z < 800 {
                s.computerSchritt(fehler: fehler, mit: &g); z += 1
                XCTAssertEqual(s.steinGesamt, 28)
                for (a, b) in zip(s.kette, s.kette.dropFirst()) { XCTAssertEqual(a.b, b.a) }
            }
            XCTAssertNotNil(s.sieger)
        } }
    }
}

final class DominoRegelTests: XCTestCase {
    func testSteinWirdBeimAnlegenPassendGedreht() {
        var d = Domino(haende: [[Stein(2, 5)], [Stein(1, 1)]], kette: [Stein(3, 5)])
        XCTAssertTrue(d.lege(0, seite: .rechts))
        XCTAssertEqual(d.kette, [Stein(3, 5), Stein(5, 2)]); XCTAssertEqual(d.rechts, 2)
    }
    func testAnLinkesEndeWirdPassendGedreht() {
        var d = Domino(haende: [[Stein(4, 3), Stein(0, 0)], [Stein(1, 1)]], kette: [Stein(3, 6)])
        XCTAssertTrue(d.lege(0, seite: .links))
        XCTAssertEqual(d.kette.first, Stein(4, 3)); XCTAssertEqual(d.links, 4)
    }
    func testNichtPassenderSteinWirdAbgelehnt() {
        var d = Domino(haende: [[Stein(0, 1), Stein(6, 6)], [Stein(2, 2)]], kette: [Stein(3, 4)])
        XCTAssertFalse(d.lege(0, seite: .rechts)); XCTAssertEqual(d.amZug, 0); XCTAssertEqual(d.haende[0].count, 2)
        XCTAssertFalse(d.lege(5, seite: .rechts))
    }
    func testWerDieHandLeertGewinnt() {
        var d = Domino(haende: [[Stein(3, 1)], [Stein(2, 2)]], kette: [Stein(3, 4)])
        XCTAssertTrue(d.lege(0, seite: .links))
        XCTAssertEqual(d.sieger, 0)
        XCTAssertFalse(d.lege(0, seite: .rechts), "Nach dem Sieg wird nichts mehr gelegt")
    }
    func testZiehenNurWennNichtsPasstUndVorratDa() {
        var d = Domino(haende: [[Stein(0, 0)], [Stein(5, 5)]], vorrat: [Stein(1, 2)], kette: [Stein(3, 4)])
        XCTAssertTrue(d.mussZiehen); XCTAssertFalse(d.mussPassen)
        d.ziehe()
        XCTAssertEqual(d.haende[0].count, 2); XCTAssertTrue(d.vorrat.isEmpty); XCTAssertTrue(d.mussPassen)
        var e = Domino(haende: [[Stein(3, 3)], [Stein(5, 5)]], vorrat: [Stein(1, 2)], kette: [Stein(3, 4)])
        e.ziehe()
        XCTAssertEqual(e.vorrat.count, 1, "Wer legen kann, zieht nicht")
    }
    func testBlockiertesSpielGewinntDieKleinsteSumme() {
        var d = Domino(haende: [[Stein(0, 1)], [Stein(6, 6)]], kette: [Stein(3, 4)])
        d.passe(); d.passe()
        XCTAssertTrue(d.blockiert); XCTAssertEqual(d.sieger, 0)
    }
    func testPassenOhneZwangIstWirkungslos() {
        var d = Domino(haende: [[Stein(3, 1)], [Stein(2, 2)]], kette: [Stein(3, 4)])
        d.passe()
        XCTAssertEqual(d.amZug, 0); XCTAssertNil(d.sieger)
    }
    func testErsterSteinKannAnJederSeiteLiegen() {
        var d = Domino(haende: [[Stein(2, 6), Stein(1, 1)], [Stein(0, 0)]])
        XCTAssertEqual(d.zuege(0).count, 2)
        XCTAssertTrue(d.lege(0, seite: .rechts))
        XCTAssertEqual(d.kette, [Stein(2, 6)])
    }
    func testSteinHilfen() {
        XCTAssertEqual(Stein(2, 5).augen, 7); XCTAssertTrue(Stein(4, 4).istPasch); XCTAssertEqual(Stein(1, 6).gedreht, Stein(6, 1))
    }
    func testBeginnerIstWerDenHoechstenPaschHat() {
        for _ in 0..<50 {
            var g = SystemRandomNumberGenerator()
            let d = Domino(spieler: 2, mit: &g)
            let paesche = d.haende.enumerated().flatMap { i, h in h.filter(\.istPasch).map { (i, $0.a) } }
            if let hoechster = paesche.max(by: { $0.1 < $1.1 }) { XCTAssertEqual(d.amZug, hoechster.0) }
        }
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var d = Domino(spieler: 3, mit: &g); d.computerSchritt()
        let neu = try JSONDecoder().decode(Domino.self, from: JSONEncoder().encode(d))
        XCTAssertEqual(neu, d)
    }
}

final class DominoComputerTests: XCTestCase {
    func testKluegerComputerSchlaegtEinfachen() {
        var g = SystemRandomNumberGenerator(); var siege = 0, partien = 0
        for i in 0..<200 {
            var d = Domino(spieler: 2, mit: &g); let ich = i % 2; var n = 0
            while d.sieger == nil && n < 400 {
                if d.amZug == ich { d.computerSchritt() } else { d.einfacherSchritt() }
                n += 1
            }
            if let s = d.sieger { partien += 1; if s == ich { siege += 1 } }
        }
        print("DOMINO klug \(siege) von \(partien)")
        XCTAssertGreaterThan(siege, partien * 52 / 100)
    }
    func testComputerSpieltNurGueltigeSteine() {
        var g = SystemRandomNumberGenerator()
        for sp in 2...4 {
            var d = Domino(spieler: sp, mit: &g); var n = 0
            while d.sieger == nil && n < 600 { d.computerSchritt(); n += 1; XCTAssertEqual(d.steinGesamt, 28) }
            XCTAssertNotNil(d.sieger)
        }
    }
    func testDoppelNeunHat55Steine() {
        var g = SystemRandomNumberGenerator()
        let d = Domino(spieler: 4, hoechstAugen: 9, handgroesse: 10, mit: &g)
        XCTAssertEqual(d.steinGesamt, 55)
    }
}
