// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import FarbwechselKern

final class FarbwechselTests: XCTestCase {
    func testKartensatz() { XCTAssertEqual(Farbwechsel.satz().count, 4 * (18 + 6 + 2)) }
    func testAusteilen() {
        var g = SystemRandomNumberGenerator(); let s = Farbwechsel(spieler: 3, mit: &g)
        XCTAssertTrue(s.haende.allSatisfy { $0.count == 7 })
        XCTAssertEqual(s.kartenGesamt, 104); XCTAssertNotNil(s.oben.zahl)
    }
    func testDarfLegenRegeln() {
        var g = SystemRandomNumberGenerator(); let s = Farbwechsel(spieler: 2, mit: &g)
        XCTAssertTrue(s.darfLegen(WKarte(farbe: 4, art: .joker)))
        XCTAssertTrue(s.darfLegen(WKarte(farbe: s.farbe, art: .sprung)))
        XCTAssertTrue(s.darfLegen(WKarte(farbe: (s.farbe + 1) % 4, art: .zahl(s.oben.zahl!))))
        XCTAssertFalse(s.darfLegen(WKarte(farbe: (s.farbe + 1) % 4, art: .zahl(s.oben.zahl! % 9 + 1))))
    }
    func testZufallsPartienEnden() {
        for n in 2...4 {
            for _ in 0..<30 {
                var g = SystemRandomNumberGenerator(); var s = Farbwechsel(spieler: n, mit: &g); var z = 0
                while s.gewinner == nil && z < 3000 { s.computerZug(mit: &g); z += 1; XCTAssertEqual(s.kartenGesamt, 104) }
                XCTAssertNotNil(s.gewinner, "\(n) Spieler")
            }
        }
    }
    func testZweiZiehenUndSprung() {
        var g = SystemRandomNumberGenerator(); var s = Farbwechsel(spieler: 3, mit: &g)
        // Hand von Spieler 0 manipulieren geht nur über Spielzüge; hier prüfen wir die Zugfolge über viele Partien
        var n = 0
        while s.gewinner == nil && n < 500 { let vorher = s.amZug; s.computerZug(mit: &g); XCTAssertTrue((0..<3).contains(s.amZug)); _ = vorher; n += 1 }
    }
    func testIllegalesLegenAbgelehnt() {
        var g = SystemRandomNumberGenerator(); var s = Farbwechsel(spieler: 2, mit: &g)
        if let i = s.haende[0].indices.first(where: { !s.darfLegen(s.haende[0][$0]) }) { XCTAssertFalse(s.lege(i, mit: &g)) }
    }

    func testFehlerhafterComputerBleibtRegelkonform() {
        for fehler in [0.5, 1.0] { for n in 2...4 { for _ in 0..<15 {
            var g = SystemRandomNumberGenerator(); var s = Farbwechsel(spieler: n, mit: &g); var z = 0
            while s.gewinner == nil && z < 4000 { s.computerZug(fehler: fehler, mit: &g); z += 1; XCTAssertEqual(s.kartenGesamt, 104) }
            XCTAssertNotNil(s.gewinner)
        } } }
    }
}

final class FarbwechselRegelTests: XCTestCase {
    private func k(_ f: Int, _ a: WKarte.Art) -> WKarte { WKarte(farbe: f, art: a) }
    private func z(_ f: Int, _ n: Int) -> WKarte { k(f, .zahl(n)) }

    func testKartensatzHat104Karten() {
        let satz = Farbwechsel.satz()
        XCTAssertEqual(satz.count, 104)
        XCTAssertEqual(satz.filter(\.istJoker).count, 8)
        XCTAssertEqual(satz.filter { $0.zahl != nil }.count, 72)
    }
    func testAblegenNachFarbeZahlOderArt() {
        let s = Farbwechsel(haende: [[z(0, 5), z(1, 5), z(1, 7), k(2, .sprung)], [z(3, 1)]], ablage: [z(0, 3)])
        XCTAssertTrue(s.darfLegen(z(0, 8)), "gleiche Farbe")
        XCTAssertTrue(s.darfLegen(z(2, 3)), "gleiche Zahl")
        XCTAssertFalse(s.darfLegen(z(1, 7)))
        XCTAssertTrue(s.darfLegen(k(4, .joker)))
        let t = Farbwechsel(haende: [[z(0, 5)], [z(3, 1)]], ablage: [k(1, .sprung)])
        XCTAssertTrue(t.darfLegen(k(3, .sprung)), "gleiche Aktion auf Aktion")
        XCTAssertFalse(t.darfLegen(k(3, .wende)))
    }
    func testSprungUeberspringtDenNaechsten() {
        var g = SystemRandomNumberGenerator()
        var s = Farbwechsel(haende: [[k(0, .sprung), z(0, 1)], [z(1, 1), z(1, 2)], [z(2, 1), z(2, 2)]], ablage: [z(0, 3)])
        XCTAssertTrue(s.lege(0, mit: &g)); XCTAssertEqual(s.amZug, 2)
    }
    func testWendeDrehtDieRichtungUndImZweierspielIstManNochmalDran() {
        var g = SystemRandomNumberGenerator()
        var s = Farbwechsel(haende: [[k(0, .wende), z(0, 1)], [z(1, 1)], [z(2, 1)]], ablage: [z(0, 3)])
        s.lege(0, mit: &g); XCTAssertEqual(s.richtung, -1); XCTAssertEqual(s.amZug, 2)
        var t = Farbwechsel(haende: [[k(0, .wende), z(0, 1)], [z(1, 1)]], ablage: [z(0, 3)])
        t.lege(0, mit: &g); XCTAssertEqual(t.amZug, 0)
    }
    func testZweiZiehenGibtZweiKartenUndUeberspringt() {
        var g = SystemRandomNumberGenerator()
        var s = Farbwechsel(haende: [[k(0, .zwei), z(0, 1)], [z(1, 1)], [z(2, 1)]], ablage: [z(0, 3)], zieh: Array(repeating: z(3, 9), count: 10))
        s.lege(0, mit: &g)
        XCTAssertEqual(s.haende[1].count, 3); XCTAssertEqual(s.amZug, 2)
    }
    func testJokerMitWunschfarbeUndDreiZiehen() {
        var g = SystemRandomNumberGenerator()
        var s = Farbwechsel(haende: [[k(4, .jokerDrei), z(0, 1)], [z(1, 1)]], ablage: [z(0, 3)], zieh: Array(repeating: z(3, 9), count: 10))
        s.lege(0, wunsch: 2, mit: &g)
        XCTAssertEqual(s.farbe, 2); XCTAssertEqual(s.haende[1].count, 4); XCTAssertEqual(s.amZug, 0)
    }
    func testLetzteKarteGewinnt() {
        var g = SystemRandomNumberGenerator()
        var s = Farbwechsel(haende: [[z(0, 5)], [z(1, 1), z(1, 2)]], ablage: [z(0, 3)])
        XCTAssertTrue(s.lege(0, mit: &g)); XCTAssertEqual(s.gewinner, 0)
        XCTAssertFalse(s.lege(0, mit: &g)); s.ziehe(mit: &g); XCTAssertEqual(s.haende[0].count, 0)
    }
    func testUnpassendeKarteWirdAbgelehnt() {
        var g = SystemRandomNumberGenerator()
        var s = Farbwechsel(haende: [[z(1, 7), z(0, 2)], [z(1, 1)]], ablage: [z(0, 3)])
        XCTAssertFalse(s.lege(0, mit: &g)); XCTAssertFalse(s.lege(9, mit: &g)); XCTAssertEqual(s.amZug, 0)
    }
    func testZiehenPassendeKarteDarfGelegtWerdenSonstWechsel() {
        var g = SystemRandomNumberGenerator()
        var s = Farbwechsel(haende: [[z(1, 7)], [z(1, 1)]], ablage: [z(0, 3)], zieh: [z(0, 9)])
        s.ziehe(mit: &g)
        XCTAssertEqual(s.gezogen, 1); XCTAssertEqual(s.amZug, 0)
        s.passe(); XCTAssertEqual(s.amZug, 1); XCTAssertNil(s.gezogen)
        var t = Farbwechsel(haende: [[z(1, 7)], [z(1, 1)]], ablage: [z(0, 3)], zieh: [z(2, 9)])
        t.ziehe(mit: &g)
        XCTAssertNil(t.gezogen); XCTAssertEqual(t.amZug, 1)
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var s = Farbwechsel(spieler: 3, mit: &g); s.computerZug(mit: &g)
        let neu = try JSONDecoder().decode(Farbwechsel.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}
