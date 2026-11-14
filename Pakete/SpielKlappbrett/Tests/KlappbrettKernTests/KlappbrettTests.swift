// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import KlappbrettKern

final class KlappbrettTests: XCTestCase {
    func testKombinationen() {
        let k = Klappbrett.kombinationen(summe: 7, offen: Set(1...9))
        XCTAssertTrue(k.contains([7])); XCTAssertTrue(k.contains([1, 6])); XCTAssertTrue(k.contains([1, 2, 4]))
        XCTAssertEqual(Set(k.map { $0.reduce(0, +) }), [7])
        XCTAssertTrue(Klappbrett.kombinationen(summe: 12, offen: [1, 2]).isEmpty)
    }
    func testKlappenUndPunkte() {
        var b = Klappbrett(); b.setzeWurf([3, 4])
        XCTAssertFalse(b.klappen([1, 2])); XCTAssertTrue(b.klappen([3, 4]))
        XCTAssertEqual(b.punkte, 45 - 7); XCTAssertFalse(b.offen.contains(3))
        b.setzeWurf([6]); XCTAssertFalse(b.klappen([3, 3]))
    }
    func testEinWuerfelRegel() {
        var b = Klappbrett(); XCTAssertFalse(b.einWuerfel)
        for z in [7, 8, 9] { b.setzeWurf([z]); XCTAssertTrue(b.klappen([z])) }
        XCTAssertTrue(b.einWuerfel)
        var g = SystemRandomNumberGenerator(); b.wuerfeln(mit: &g); XCTAssertEqual(b.wurf.count, 1)
    }
    func testGeschafftUndRang() {
        var b = Klappbrett()
        for z in Klappbrett.zahlen { b.setzeWurf([z]); _ = b.klappen([z]) }
        XCTAssertTrue(b.geschafft); XCTAssertEqual(b.punkte, 0)
        XCTAssertEqual(klappbrettRangfolge(punkte: [5, 0, 5, 12]), [2, 1, 2, 4])
    }
    func testKeinZug() {
        var b = Klappbrett(); b.setzeWurf([6, 6])
        XCTAssertTrue(b.zugMoeglich)
    }
    func testWennNurNochEinsUndZweiOffenSindGibtEsBeiSechsKeinenZug() {
        var b = Klappbrett()
        for z in 3...9 { b.setzeWurf([z]); XCTAssertTrue(b.klappen([z])) }
        XCTAssertTrue(b.einWuerfel)
        b.setzeWurf([6])
        XCTAssertFalse(b.zugMoeglich)
        XCTAssertTrue(b.moeglicheZuege.isEmpty)
        XCTAssertFalse(b.klappen([1, 2]), "Summe 3 passt nicht zur 6")
        XCTAssertEqual(b.punkte, 3)
    }
    func testNachDemKlappenIstDerWurfVerbraucht() {
        var b = Klappbrett(); b.setzeWurf([4, 5])
        XCTAssertTrue(b.klappen([4, 5]))
        XCTAssertTrue(b.wurf.isEmpty)
        XCTAssertFalse(b.klappen([9]), "ohne neuen Wurf kann nichts geklappt werden")
    }
    func testZahlNurEinmalUndNurOffeneZahlen() {
        var b = Klappbrett(); b.setzeWurf([4, 5]); XCTAssertTrue(b.klappen([4, 5]))
        b.setzeWurf([4, 5])
        XCTAssertFalse(b.klappen([4, 5]), "4 und 5 sind schon zu")
        XCTAssertTrue(b.klappen([9]))
    }
    func testWurfSummeUndLeereAuswahl() {
        var b = Klappbrett(); b.setzeWurf([2, 3])
        XCTAssertEqual(b.summe, 5)
        XCTAssertFalse(b.klappen([]))
        XCTAssertFalse(b.klappen([5, 5]), "dieselbe Zahl doppelt gilt nicht")
        XCTAssertTrue(b.klappen([1, 4]))
    }
    func testZugAnzahlFuerSummeNeun() {
        // 9 = 9, 1+8, 2+7, 3+6, 4+5, 1+2+6, 1+3+5, 2+3+4
        XCTAssertEqual(Klappbrett.kombinationen(summe: 9, offen: Set(1...9)).count, 8)
    }
    func testErwartungSinktMitWenigerRestzahlen() {
        let voll = KlappbrettComputer.erwartung(offen: Set(1...9))
        let wenig = KlappbrettComputer.erwartung(offen: [1, 2, 3])
        XCTAssertLessThan(wenig, voll)
        XCTAssertGreaterThan(KlappbrettComputer.erwartung(offen: [9]), 0)
    }
    func testMittlerSpieltHoheZahlenZuerst() {
        var b = Klappbrett(); b.setzeWurf([4, 4])
        XCTAssertEqual(KlappbrettComputer.zug(b, stufe: 2), [8])
    }
    func testSchwerWaehltBeiElfDenGuenstigenZug() {
        var b = Klappbrett(); b.setzeWurf([5, 6])
        let z = KlappbrettComputer.zug(b, stufe: 3)!
        XCTAssertEqual(z.reduce(0, +), 11)
        XCTAssertTrue(Klappbrett.kombinationen(summe: 11, offen: b.offen).contains(z))
    }
    func testKeinZugGibtNil() {
        var b = Klappbrett()
        for z in 3...9 { b.setzeWurf([z]); b.klappen([z]) }
        b.setzeWurf([6])
        XCTAssertNil(KlappbrettComputer.zug(b, stufe: 3))
    }

    func testErwartungUndStufen() {
        XCTAssertEqual(KlappbrettComputer.erwartung(offen: []), 0)
        let alle = KlappbrettComputer.erwartung(offen: Set(Klappbrett.zahlen))
        XCTAssertLessThan(alle, 45); XCTAssertGreaterThan(alle, 5)
        var b = Klappbrett(); b.setzeWurf([3, 4])
        let z = KlappbrettComputer.zug(b, stufe: 3)!
        XCTAssertEqual(z.reduce(0, +), 7)
    }
    func testSchwerSchlaegtLeicht() {
        func spiele(_ stufe: Int) -> Double {
            var summe = 0
            for _ in 0..<400 {
                var g = SystemRandomNumberGenerator(); var b = Klappbrett()
                while !b.geschafft, b.wuerfeln(mit: &g), let z = KlappbrettComputer.zug(b, stufe: stufe) { b.klappen(z) }
                summe += b.punkte
            }
            return Double(summe) / 400
        }
        XCTAssertLessThan(spiele(3), spiele(1))
    }
}
