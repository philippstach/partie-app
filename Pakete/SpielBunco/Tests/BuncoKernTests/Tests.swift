// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import BuncoKern

final class BuncoTests: XCTestCase {
    func testBewertung() {
        XCTAssertEqual(Bunco.bewerte([2, 2, 2], ziel: 2), .bunco)
        XCTAssertEqual(Bunco.bewerte([4, 4, 4], ziel: 2), .miniBunco)
        XCTAssertEqual(Bunco.bewerte([2, 5, 2], ziel: 2), .punkte(2))
        XCTAssertEqual(Bunco.bewerte([1, 5, 3], ziel: 2), .nichts)
        XCTAssertEqual(Bunco.bewerte([1, 1], ziel: 1), .nichts)
    }
    func testWechselBeiNull() {
        var b = Bunco()
        XCTAssertTrue(b.wuerfle(augen: [3, 4, 5]))
        XCTAssertEqual(b.amZug, 1); XCTAssertEqual(b.punkte, [0, 0])
    }
    func testWeiterBeiPunkten() {
        var b = Bunco()
        b.wuerfle(augen: [1, 4, 5])
        XCTAssertEqual(b.amZug, 0); XCTAssertEqual(b.punkte, [1, 0])
        b.wuerfle(augen: [2, 2, 2])                     // Mini-Bunco
        XCTAssertEqual(b.punkte, [6, 0])
    }
    func testBuncoBeendetRunde() {
        var b = Bunco()
        b.wuerfle(augen: [1, 1, 1])
        XCTAssertEqual(b.rundeBeendetVon, 0); XCTAssertEqual(b.rundenSiege, [1, 0])
        XCTAssertFalse(b.wuerfle(augen: [1, 2, 3]))      // erst nächste Runde
        b.naechsteRunde()
        XCTAssertEqual(b.runde, 2); XCTAssertEqual(b.punkte, [0, 0]); XCTAssertEqual(b.amZug, 1)
        XCTAssertEqual(b.ziel, 2)
    }
    func testVerlauf() {
        var b = Bunco()
        b.wuerfle(augen: [1, 1, 1]); b.naechsteRunde()
        b.wuerfle(augen: [5, 5, 5]); XCTAssertEqual(b.rundenVerlauf, [0])   // Mini-Bunco gibt nur 5 Punkte
        XCTAssertNil(b.rundeBeendetVon)
    }
    func testRundeBisZwanzigEins() {
        var b = Bunco()
        for _ in 0..<21 { b.wuerfle(augen: [1, 5, 6]) }
        XCTAssertEqual(b.rundeBeendetVon, 0)
    }
    func testPartienEnden() {
        for _ in 0..<50 {
            var g = SystemRandomNumberGenerator(); var b = Bunco(); var n = 0
            while !b.vorbei && n < 100_000 {
                n += 1
                if b.rundeBeendetVon != nil { b.naechsteRunde() } else { b.wuerfle(mit: &g) }
            }
            XCTAssertTrue(b.vorbei); XCTAssertEqual(b.runde, 6)
            XCTAssertEqual(b.rundenSiege[0] + b.rundenSiege[1], 6)
        }
    }
}

final class BuncoRegelTests: XCTestCase {
    func testMiniBuncoZaehltNurAlsFuenfAuchBeiRundenzahl() {
        var b = Bunco()
        b.wuerfle(augen: [4, 4, 4])
        XCTAssertEqual(b.punkte[0], 5); XCTAssertEqual(b.amZug, 0, "Wer punktet, würfelt weiter")
    }
    func testUngueltigeWuerfeWerdenAbgelehnt() {
        var b = Bunco(); let stand = b
        XCTAssertFalse(b.wuerfle(augen: [1, 2]))
        XCTAssertFalse(b.wuerfle(augen: [0, 2, 3]))
        XCTAssertFalse(b.wuerfle(augen: [1, 2, 7]))
        XCTAssertEqual(b, stand)
    }
    func testRundeEndetBeiUeber21MitUeberschuss() {
        var b = Bunco()
        for _ in 0..<20 { b.wuerfle(augen: [1, 5, 6]) }
        b.wuerfle(augen: [1, 1, 5])                     // 20 + 2 = 22
        XCTAssertEqual(b.punkte[0], 22); XCTAssertEqual(b.rundeBeendetVon, 0)
    }
    func testSiegerNachSechsRunden() {
        var b = Bunco()
        for r in 1...6 {
            b.wuerfle(augen: [r, r, r])
            if r < 6 { b.naechsteRunde() }
        }
        XCTAssertTrue(b.vorbei); XCTAssertEqual(b.rundenSiege, [3, 3]); XCTAssertNil(b.sieger, "Gleichstand ist unentschieden")
    }
    func testRundenbeginnWechseltJedeRunde() {
        var b = Bunco()
        b.wuerfle(augen: [1, 1, 1]); b.naechsteRunde(); XCTAssertEqual(b.amZug, 1)
        b.wuerfle(augen: [2, 3, 4]); b.wuerfle(augen: [2, 2, 2]); b.naechsteRunde()
        XCTAssertEqual(b.runde, 3); XCTAssertEqual(b.amZug, 0)
    }
    func testNaechsteRundeNurNachRundenende() {
        var b = Bunco(); b.naechsteRunde()
        XCTAssertEqual(b.runde, 1)
    }
    func testSpielstandIstCodierbar() throws {
        var b = Bunco(); b.wuerfle(augen: [1, 1, 5]); b.wuerfle(augen: [3, 4, 5])
        let neu = try JSONDecoder().decode(Bunco.self, from: JSONEncoder().encode(b))
        XCTAssertEqual(neu, b)
    }
}
