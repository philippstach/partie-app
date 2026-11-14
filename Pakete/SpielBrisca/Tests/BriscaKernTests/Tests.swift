// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import BriscaKern

final class BriscaTests: XCTestCase {
    private func k(_ f: Int, _ r: Int) -> BriscaKarte { BriscaKarte(farbe: f, rang: r) }

    func testGesamtaugen() {
        var g = SystemRandomNumberGenerator(); let b = Brisca(mit: &g)
        let alle = b.haende.joined() + b.stapel
        XCTAssertEqual(alle.count, 40)
        XCTAssertEqual(alle.reduce(0) { $0 + $1.augen }, 120)
        XCTAssertEqual(b.stapel.last, b.atoutKarte)
    }
    func testStechen() {
        // Atout = Münzen
        let b = Brisca(karten: [k(1, 1), k(1, 2), k(1, 4), k(2, 3), k(2, 4), k(2, 5), k(0, 2)])
        XCTAssertTrue(b.sticht(k(1, 3), k(1, 1)) == false)       // Drei sticht Ass nicht
        XCTAssertTrue(b.sticht(k(1, 1), k(1, 3)))                // Ass sticht Drei
        XCTAssertTrue(b.sticht(k(0, 4), k(1, 1)))                // Atout sticht
        XCTAssertFalse(b.sticht(k(2, 1), k(1, 4)))               // fremde Farbe sticht nicht
    }
    func testStichUndNachziehen() {
        var b = Brisca(karten: [k(1, 1), k(1, 2), k(1, 4), k(1, 3), k(2, 4), k(2, 5), k(2, 12), k(3, 2), k(0, 2)])
        XCTAssertTrue(b.spiele(0, karte: 0))                     // Ass Becher
        XCTAssertFalse(b.spiele(0, karte: 0))                    // nicht dran
        XCTAssertTrue(b.spiele(1, karte: 0))                     // Drei Becher
        XCTAssertEqual(b.augen, [21, 0]); XCTAssertEqual(b.amZug, 0)
        XCTAssertEqual(b.haende[0].count, 3); XCTAssertEqual(b.haende[1].count, 3)
        XCTAssertEqual(b.haende[0].last, k(2, 12))               // Gewinner zieht zuerst
        XCTAssertEqual(b.haende[1].last, k(3, 2))
    }
    func testAlleStufenEnden() {
        for stufe in 1...3 {
            for _ in 0..<(stufe == 3 ? 6 : 30) {
                var g = SystemRandomNumberGenerator(); var b = Brisca(mit: &g); var n = 0
                while !b.vorbei && n < 100 { XCTAssertTrue(b.spiele(b.amZug, karte: BriscaComputer.wahl(b, spieler: b.amZug, stufe: stufe))); n += 1 }
                XCTAssertTrue(b.vorbei); XCTAssertEqual(b.augen[0] + b.augen[1], 120)
            }
        }
    }
    func testSchwerSchlaegtLeicht() {
        var s = 0
        for _ in 0..<30 {
            var g = SystemRandomNumberGenerator(); var b = Brisca(mit: &g)
            while !b.vorbei { b.spiele(b.amZug, karte: BriscaComputer.wahl(b, spieler: b.amZug, stufe: b.amZug == 0 ? 3 : 1)) }
            if b.augen[0] > b.augen[1] { s += 1 }
        }
        XCTAssertGreaterThan(s, 18)
    }
    func testComputerPartienEnden() {
        for _ in 0..<100 {
            var g = SystemRandomNumberGenerator(); var b = Brisca(mit: &g); var n = 0
            while !b.vorbei && n < 100 { XCTAssertTrue(b.spiele(b.amZug, karte: BriscaComputer.wahl(b, spieler: b.amZug))); n += 1 }
            XCTAssertTrue(b.vorbei); XCTAssertEqual(b.augen[0] + b.augen[1], 120); XCTAssertEqual(n, 40)
        }
    }
}

final class BriscaRegelTests: XCTestCase {
    private func k(_ f: Int, _ r: Int) -> BriscaKarte { BriscaKarte(farbe: f, rang: r) }
    /// Spieler 0: Münzen-Ass, Münzen-4, Becher-2; Spieler 1: Becher-Drei, Schwerter-7, Stäbe-5; Stapel danach; Atout unten = Schwerter-2.
    private func start(amZug: Int = 0) -> Brisca {
        Brisca(karten: [k(0, 1), k(0, 4), k(1, 2), k(1, 3), k(2, 7), k(3, 5), k(3, 6), k(3, 10), k(2, 2)], amZug: amZug)
    }

    func testAugenUndStaerkeFolge() {
        XCTAssertEqual([1, 3, 12, 11, 10, 7, 4].map { k(0, $0).augen }, [11, 10, 4, 3, 2, 0, 0])
        let folge = [1, 3, 12, 11, 10, 7, 6, 5, 4, 2].map { k(0, $0).staerke }
        XCTAssertEqual(folge, folge.sorted(by: >), "As > Drei > König > Reiter > Bube > 7 … > 2")
    }
    func testZweiteKarteMitFremderFarbeStichtNicht() {
        var b = start()
        b.spiele(0, karte: 0)               // Münzen-Ass
        b.spiele(1, karte: 2)               // Stäbe-5 (kein Atout, andere Farbe)
        XCTAssertEqual(b.letzterStich?.gewinner, 0); XCTAssertEqual(b.augen[0], 11); XCTAssertEqual(b.amZug, 0)
    }
    func testAtoutStichtJedeAndereFarbe() {
        var b = start()
        b.spiele(0, karte: 0)               // Münzen-Ass
        b.spiele(1, karte: 1)               // Schwerter-7 = Atout
        XCTAssertEqual(b.letzterStich?.gewinner, 1); XCTAssertEqual(b.augen[1], 11); XCTAssertEqual(b.amZug, 1)
    }
    func testNurDerAmZugDarfSpielenUndNurEineKarte() {
        var b = start()
        XCTAssertFalse(b.spiele(1, karte: 0), "Spieler 1 ist nicht dran")
        XCTAssertFalse(b.spiele(0, karte: 7)); XCTAssertFalse(b.spiele(0, karte: -1))
        XCTAssertTrue(b.spiele(0, karte: 0)); XCTAssertFalse(b.spiele(0, karte: 0), "Nicht zweimal hintereinander")
    }
    func testGewinnerZiehtZuerstNach() {
        var b = start()
        b.spiele(0, karte: 0); b.spiele(1, karte: 1)         // Spieler 1 gewinnt den Stich
        XCTAssertEqual(b.haende[1].last, k(3, 6), "Gewinner bekommt die oberste Stapelkarte")
        XCTAssertEqual(b.haende[0].last, k(3, 10))
        XCTAssertEqual(b.stapel.count, 1)
    }
    func testAusgespielteStichkartenWerdenGemerkt() {
        var b = start()
        b.spiele(0, karte: 0); b.spiele(1, karte: 0)
        XCTAssertEqual(Set(b.gespielt), [k(0, 1), k(1, 3)]); XCTAssertEqual(b.letzterStich?.karten.count, 2)
    }
    func testPartieEndetWennBeideHaendeLeerSindUndSiegerHatMehrAugen() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<30 {
            var b = Brisca(mit: &g); var n = 0
            while !b.vorbei && n < 200 { b.spiele(b.amZug, karte: 0); n += 1 }
            XCTAssertTrue(b.vorbei); XCTAssertEqual(b.augen[0] + b.augen[1], 120)
            if let s = b.sieger { XCTAssertGreaterThan(b.augen[s], b.augen[1 - s]) } else { XCTAssertEqual(b.augen, [60, 60]) }
            XCTAssertFalse(b.spiele(b.amZug, karte: 0))
        }
    }
    func testComputerWaehltImmerEineGueltigeKarteAufAllenStufen() {
        var g = SystemRandomNumberGenerator()
        for stufe in 1...3 {
            var b = Brisca(mit: &g); var n = 0
            while !b.vorbei && n < 200 {
                let w = BriscaComputer.wahl(b, spieler: b.amZug, stufe: stufe)
                XCTAssertTrue(b.haende[b.amZug].indices.contains(w), "Stufe \(stufe)")
                b.spiele(b.amZug, karte: w); n += 1
            }
            XCTAssertTrue(b.vorbei)
        }
    }
    func testUnbekannteKartenSindNurWasMeinHandUndAblageNichtZeigen() {
        let b = start()
        let u = BriscaComputer.unbekannt(b, spieler: 0)
        XCTAssertFalse(u.contains(k(0, 1))); XCTAssertFalse(u.contains(b.atoutKarte))
        XCTAssertEqual(u.count, 40 - 3 - 1)
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var b = Brisca(mit: &g); b.spiele(b.amZug, karte: 0)
        let neu = try JSONDecoder().decode(Brisca.self, from: JSONEncoder().encode(b))
        XCTAssertEqual(neu, b)
    }
}
