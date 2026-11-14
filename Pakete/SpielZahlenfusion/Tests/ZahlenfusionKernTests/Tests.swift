// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import ZahlenfusionKern

final class ZahlenfusionTests: XCTestCase {
    func testVerschmelzen() {
        var z = Zahlenfusion(); var g = SystemRandomNumberGenerator()
        z.setze([2, 2, 2, 2, 0, 0, 0, 0, 4, 0, 4, 8, 0, 0, 0, 0])
        XCTAssertTrue(z.bewege(.links, mit: &g))
        XCTAssertEqual(Array(z.feld[0..<2]), [4, 4]); XCTAssertEqual(Array(z.feld[8..<10]), [8, 8]) // neue Kachel kann in jedes freie Feld fallen
        XCTAssertEqual(z.punkte, 4 + 4 + 8)
        XCTAssertEqual(z.feld.filter { $0 != 0 }.count, 5)
    }
    func testRichtungenUndEnde() {
        var z = Zahlenfusion(); var g = SystemRandomNumberGenerator()
        z.setze([2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2])
        XCTAssertTrue(z.vorbei); XCTAssertFalse(z.bewege(.links, mit: &g))
        z.setze([0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertFalse(z.bewege(.oben, mit: &g)); XCTAssertTrue(z.bewege(.unten, mit: &g)); XCTAssertEqual(z.feld[15], 2)
        XCTAssertFalse(z.erreicht2048)
    }
    func testEinMalVerschmelzenProZug() {
        var z = Zahlenfusion(); var g = SystemRandomNumberGenerator()
        z.setze([2, 2, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        z.bewege(.links, mit: &g)
        XCTAssertEqual(Array(z.feld[0..<2]), [4, 4], "2,2,4 wird 4,4 und nicht 8")
        XCTAssertEqual(z.punkte, 4)
    }
    func testRechtsUndPunkteUndSieg() {
        var z = Zahlenfusion(); var g = SystemRandomNumberGenerator()
        z.setze([1024, 1024, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertFalse(z.erreicht2048)
        z.bewege(.rechts, mit: &g)
        XCTAssertEqual(z.feld[3], 2048); XCTAssertTrue(z.erreicht2048); XCTAssertEqual(z.punkte, 2048)
    }
    func testVolleAberBeweglich() {
        var z = Zahlenfusion()
        z.setze([2, 2, 4, 8, 16, 32, 64, 128, 2, 4, 8, 16, 32, 64, 128, 256])
        XCTAssertFalse(z.vorbei); XCTAssertTrue(z.kannBewegen(.links)); XCTAssertFalse(z.kannBewegen(.oben))
    }

    /// Zufälliges Spiel: Summe wächst pro Zug genau um die neue Kachel (2 oder 4), Spiel endet, vorbei stimmt mit kannBewegen überein.
    func testZufallsspielHaeltInvarianten() {
        for seed in 1...20 as ClosedRange<UInt64> {
            var g = SplitMix(seed); var z = Zahlenfusion(); z.neueKachel(mit: &g); z.neueKachel(mit: &g)
            var zuege = 0
            while !z.vorbei && zuege < 5000 {
                let summe = z.feld.reduce(0, +)
                let r = [FusionRichtung.links, .rechts, .oben, .unten].randomElement(using: &g)!
                if z.bewege(r, mit: &g) {
                    let d = z.feld.reduce(0, +) - summe
                    XCTAssertTrue(d == 2 || d == 4, "Summe +\(d)")
                }
                zuege += 1
            }
            XCTAssertTrue(z.vorbei, "Seed \(seed) endet nicht")
            XCTAssertFalse([FusionRichtung.links, .rechts, .oben, .unten].contains { z.kannBewegen($0) })
            XCTAssertTrue(z.feld.allSatisfy { $0 == 0 || ($0 & ($0 - 1)) == 0 }, "nur Zweierpotenzen")
        }
    }
    func testNeueKachelNurInFreieFelderUndNieBeiVollemFeld() {
        var g = SystemRandomNumberGenerator(); var z = Zahlenfusion()
        z.setze([2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2])
        let vorher = z.feld; z.neueKachel(mit: &g); XCTAssertEqual(z.feld, vorher)
    }

    func testTippWaehltVerschmelzungUndNieEinenLeerenZug() {
        var z = Zahlenfusion()
        z.setze([2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertTrue([.links, .rechts].contains(z.tippRichtung!), "verschmelzen bringt Punkte")
        z.setze([2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2])
        XCTAssertNil(z.tippRichtung, "kein Zug möglich")
        z.setze([2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let r = z.tippRichtung!
        XCTAssertNotNil(z.vorschau(r))
    }
    func testTippFuehrtImmerZuGueltigemZugBisZumEnde() {
        var g = SplitMix(1); var z = Zahlenfusion(); z.neueKachel(mit: &g); z.neueKachel(mit: &g)
        var zuege = 0
        while let r = z.tippRichtung, zuege < 3000 {
            XCTAssertTrue(z.bewege(r, mit: &g)); zuege += 1
        }
        XCTAssertTrue(z.vorbei, "Tipp findet einen Zug, solange einer existiert")
        XCTAssertGreaterThan(z.punkte, 100)
    }
    func testVorschauAendertDasFeldNicht() {
        var z = Zahlenfusion(); z.setze([2, 2, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let v = z.vorschau(.links)!
        XCTAssertEqual(Array(v.feld[0..<2]), [4, 4]); XCTAssertEqual(v.punkte, 4)
        XCTAssertEqual(Array(z.feld[0..<3]), [2, 2, 4]); XCTAssertEqual(z.punkte, 0)
    }
}

struct SplitMix: RandomNumberGenerator {
    var z: UInt64
    init(_ s: UInt64) { z = s &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        z &+= 0x9E37_79B9_7F4A_7C15
        var x = z; x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9; x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        return x ^ (x >> 31)
    }
    func testGroessen() {
        var g = SystemRandomNumberGenerator()
        for n in 3...6 {
            var z = Zahlenfusion(n: n); XCTAssertEqual(z.feld.count, n * n)
            z.neueKachel(mit: &g); z.neueKachel(mit: &g)
            var k = 0; while !z.vorbei, k < 5000 { if let r = z.tippRichtung { z.bewege(r, mit: &g) }; k += 1 }
            XCTAssertTrue(z.vorbei)
        }
    }
    func testAlterStandLaedt() throws {
        let alt = "{\"feld\":[2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],\"punkte\":4}".data(using: .utf8)!
        let z = try JSONDecoder().decode(Zahlenfusion.self, from: alt)
        XCTAssertEqual(z.n, 4)
    }
}

final class ZahlenfusionZusatzTests: XCTestCase {
    func testCodableRundlaufMitGroesse() throws {
        var g = SystemRandomNumberGenerator()
        var z = Zahlenfusion(n: 5); z.neueKachel(mit: &g); z.neueKachel(mit: &g)
        let d = try JSONEncoder().encode(z)
        let r = try JSONDecoder().decode(Zahlenfusion.self, from: d)
        XCTAssertEqual(r, z); XCTAssertEqual(r.n, 5); XCTAssertEqual(r.feld.count, 25)
    }
    func testBewegenAufAllenGroessenHaeltFeldlaenge() {
        var g = SystemRandomNumberGenerator()
        for n in 3...6 {
            var z = Zahlenfusion(n: n); z.neueKachel(mit: &g); z.neueKachel(mit: &g)
            for r in [FusionRichtung.links, .oben, .rechts, .unten, .links, .oben] { z.bewege(r, mit: &g); XCTAssertEqual(z.feld.count, n * n) }
        }
    }
    func testSummeWaechstNurDurchNeueKacheln() {
        var g = SystemRandomNumberGenerator()
        var z = Zahlenfusion(n: 4); z.neueKachel(mit: &g); z.neueKachel(mit: &g)
        var summe = z.feld.reduce(0, +)
        for _ in 0..<200 where !z.vorbei {
            guard let r = z.tippRichtung else { break }
            z.bewege(r, mit: &g)
            let neu = z.feld.reduce(0, +)
            XCTAssertTrue(neu - summe == 2 || neu - summe == 4); summe = neu
        }
    }
    func testKleinstesFeldIstSpielbar() {
        var g = SystemRandomNumberGenerator()
        var z = Zahlenfusion(n: 3); z.neueKachel(mit: &g)
        XCTAssertFalse(z.vorbei); XCTAssertNotNil(z.tippRichtung)
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class ZahlenfusionKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = Zahlenfusion(n: 4)
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = Zahlenfusion(n: 4)
        let k = try kaputt(w, "feld", [2, 4, 8])
        XCTAssertFalse(k.istKonsistent)
    }
}

final class ZahlenfusionRegelTests: XCTestCase {
    private func feld(_ z: [[Int]], n: Int = 4) -> Zahlenfusion { var s = Zahlenfusion(n: n); s.setze(z.flatMap { $0 }); return s }

    func testVierGleicheVerschmelzenZuZweiPaaren() {
        var g = SystemRandomNumberGenerator()
        var s = feld([[2, 2, 2, 2], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        XCTAssertTrue(s.bewege(.links, mit: &g))
        XCTAssertEqual(Array(s.feld.prefix(2)), [4, 4], "Die neue Kachel kann nur auf Feld 3 oder 4 der Reihe landen"); XCTAssertEqual(s.punkte, 8)
    }
    func testDreiGleicheVerschmelzenVonDerZielseite() {
        var g = SystemRandomNumberGenerator()
        var s = feld([[2, 2, 2, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        s.bewege(.rechts, mit: &g)
        XCTAssertEqual(Array(s.feld[2...3]), [2, 4], "Das Paar liegt am Rand, in Zugrichtung; links davon kann die neue Kachel liegen")
    }
    func testBewegungOhneWirkungGibtFalseUndKeineNeueKachel() {
        var g = SystemRandomNumberGenerator()
        var s = feld([[2, 4, 8, 16], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        let vorher = s
        XCTAssertFalse(s.bewege(.links, mit: &g)); XCTAssertEqual(s, vorher)
    }
    func testObenUndUntenBewegenSpaltenweise() {
        var g = SystemRandomNumberGenerator()
        var s = feld([[2, 0, 0, 0], [2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        s.bewege(.oben, mit: &g)
        XCTAssertEqual(s.feld[0], 4); XCTAssertEqual(s.punkte, 4)
        var t = feld([[2, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [2, 0, 0, 0]])
        t.bewege(.unten, mit: &g)
        XCTAssertEqual(t.feld[12], 4)
    }
    func testNeueKachelIstZweiOderVier() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            var s = Zahlenfusion(n: 4); s.neueKachel(mit: &g)
            XCTAssertEqual(s.feld.filter { $0 != 0 }.count, 1); XCTAssertTrue([2, 4].contains(s.hoechste))
        }
    }
    func testErreicht2048() {
        XCTAssertFalse(feld([[1024, 1024, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]).erreicht2048)
        var g = SystemRandomNumberGenerator()
        var s = feld([[1024, 1024, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]])
        s.bewege(.links, mit: &g)
        XCTAssertTrue(s.erreicht2048)
    }
    func testSpielIstVorbeiNurBeiVollemFeldOhneVerschmelzung() {
        XCTAssertTrue(feld([[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 2]]).vorbei)
        XCTAssertFalse(feld([[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 4]]).vorbei)
        XCTAssertFalse(Zahlenfusion(n: 4).vorbei)
    }
    func testTippIstNilWennNichtsGeht() {
        XCTAssertNil(feld([[2, 4, 2, 4], [4, 2, 4, 2], [2, 4, 2, 4], [4, 2, 4, 2]]).tippRichtung)
    }
    func testVorschauEntsprichtDemEchtenZugOhneNeueKachel() {
        var g = SystemRandomNumberGenerator()
        var s = feld([[2, 2, 4, 0], [0, 4, 4, 8], [0, 0, 0, 0], [2, 0, 0, 2]])
        let v = s.vorschau(.links)!
        s.bewege(.links, mit: &g)
        let unterschied = zip(v.feld, s.feld).filter { $0 != $1 }.count
        XCTAssertEqual(unterschied, 1, "Nur die neue Kachel kommt dazu"); XCTAssertEqual(s.punkte, v.punkte)
    }
}
