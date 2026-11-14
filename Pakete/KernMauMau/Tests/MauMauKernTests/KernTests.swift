// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MauMauKern

private func K(_ f: Int, _ w: Int) -> NKarte { NKarte(f, w) }

final class MauMauNeuRegelnTests: XCTestCase {
    func testStandardwerte() {
        let r = NRegeln.standard
        XCTAssertEqual(r.startkarten, 5); XCTAssertTrue(r.siebenZiehen); XCTAssertEqual(r.aussetzen, .acht)
        XCTAssertFalse(r.maueSagen); XCTAssertFalse(r.mehrrunden); XCTAssertFalse(r.neunRichtung); XCTAssertFalse(r.sofortLegen)
    }
    func testStartkartenWerdenBegrenzt() {
        XCTAssertEqual(NRegeln(startkarten: 2).startkarten, 5); XCTAssertEqual(NRegeln(startkarten: 12).startkarten, 7)
    }
    func testZweiBlaetterAbFuenf() {
        XCTAssertEqual(NRegeln.blaetter(spieler: 4), 1); XCTAssertEqual(NRegeln.blaetter(spieler: 5), 2)
    }
    func testVorlagenUnterscheidenSich() {
        XCTAssertEqual(NRegeln.ass.aussetzenWert, 14); XCTAssertEqual(NRegeln.schlicht.aussetzenWert, 0)
        XCTAssertEqual(NRegeln.sieben.startkarten, 7); XCTAssertTrue(NRegeln.wild.maueSagen)
    }
    func testRegelnRoundtrip() throws {
        var r = NRegeln.wild; r.mehrrunden = true; r.zielPunkte = 50
        XCTAssertEqual(try JSONDecoder().decode(NRegeln.self, from: JSONEncoder().encode(r)), r)
    }
}

final class MauMauNeuAusgabeTests: XCTestCase {
    func testAusgabeKartenUndStart() {
        var g = SystemRandomNumberGenerator()
        for sp in 2...5 {
            let s = NMauMau(spieler: sp, mit: &g)
            XCTAssertEqual(s.spielerZahl, sp)
            let gesamt = s.haende.reduce(0) { $0 + $1.count } + s.stapel.count + s.ablage.count
            XCTAssertEqual(gesamt, 32 * NRegeln.blaetter(spieler: sp))
            XCTAssertTrue([7, 8, 11].allSatisfy { s.oben.wert != $0 })
        }
    }
    func testFuenfSpielerBekommenZweiBlaetter() {
        var g = SystemRandomNumberGenerator()
        let s = NMauMau(spieler: 5, mit: &g)
        XCTAssertEqual(s.haende.reduce(0) { $0 + $1.count } + s.stapel.count + s.ablage.count, 64)
    }
    func testStartkarteIstKeineSonderkarteMitRegeln() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<60 {
            let s = NMauMau(spieler: 3, regeln: .wild, mit: &g)
            XCTAssertNotEqual(s.oben.wert, 9)
        }
    }
}

final class MauMauNeuZugTests: XCTestCase {
    func testFarbeOderWert() {
        let s = NMauMau(haende: [[K(0, 9), K(1, 10), K(2, 13)], [K(0, 12)]], ablage: [K(0, 10)])
        XCTAssertEqual(s.spielbareIndizes, [0, 1])
    }
    func testSiebenLaesstZiehenUndStapelt() {
        var s = NMauMau(haende: [[K(0, 7), K(1, 9)], [K(1, 7), K(1, 9)], [K(2, 9), K(2, 10)]], ablage: [K(0, 10)], stapel: Array(repeating: K(3, 9), count: 10))
        XCTAssertTrue(s.spiele(0)); XCTAssertEqual(s.zieh, 2); XCTAssertEqual(s.pflicht, .ziehen(2))
        XCTAssertEqual(s.spielbareIndizes, [0])           // nur eine 7 darf weitergeben
        XCTAssertTrue(s.spiele(0)); XCTAssertEqual(s.zieh, 4)
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)
        XCTAssertEqual(s.haende[2].count, 6); XCTAssertEqual(s.zieh, 0); XCTAssertEqual(s.dran, 0)
    }
    func testAchtSetztAus() {
        var s = NMauMau(haende: [[K(0, 8), K(0, 9)], [K(0, 10)], [K(0, 12)]], ablage: [K(0, 10)])
        s.spiele(0)
        XCTAssertTrue(s.aussetzen); XCTAssertEqual(s.dran, 1); XCTAssertEqual(s.pflicht, .aussetzen)
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)
        XCTAssertFalse(s.aussetzen); XCTAssertEqual(s.dran, 2)
        XCTAssertEqual(s.haende[1].count, 1)       // Aussetzen zieht keine Karte
    }
    func testAussetzenKannWeitergegebenWerden() {
        var s = NMauMau(haende: [[K(0, 8), K(0, 9)], [K(1, 8)], [K(0, 12)]], ablage: [K(0, 10)])
        s.spiele(0); XCTAssertEqual(s.spielbareIndizes, [0])
    }
    func testAssSetztAusMitRegel() {
        var s = NMauMau(haende: [[K(0, 14), K(0, 9)], [K(1, 14)], [K(2, 9)]], ablage: [K(0, 10)], regeln: .ass)
        s.spiele(0); XCTAssertTrue(s.aussetzen)
        let s2 = NMauMau(haende: [[K(0, 8), K(0, 9)], [K(1, 14)], [K(2, 9)]], ablage: [K(0, 10)], regeln: .ass)
        XCTAssertFalse(s2.aussetzen)
    }
    func testBubeWuenschtFarbe() {
        var s = NMauMau(haende: [[K(0, 11), K(0, 9)], [K(2, 9), K(1, 9)], [K(0, 12)]], ablage: [K(0, 10)])
        s.spiele(0, wunsch: 2)
        XCTAssertEqual(s.wunsch, 2); XCTAssertEqual(s.spielbareIndizes, [0])      // nur Herz
    }
    func testBubeAufBubeNurMitRegel() {
        var r = NRegeln.standard; r.bubeAufBube = false
        let s = NMauMau(haende: [[K(1, 11), K(1, 9)], [K(0, 9)]], ablage: [K(0, 11)], regeln: r)
        XCTAssertFalse(s.passt(K(1, 11)))
        let s2 = NMauMau(haende: [[K(1, 11), K(1, 9)], [K(0, 9)]], ablage: [K(0, 11)], regeln: .standard)
        XCTAssertTrue(s2.passt(K(1, 11)))
    }
    func testBubeNichtAlsSchlussBeiStreng() {
        let s = NMauMau(haende: [[K(0, 11)], [K(0, 9), K(1, 9)]], ablage: [K(0, 10)], regeln: .streng)
        XCTAssertFalse(s.passt(K(0, 11)))
    }
    func testNeunWechseltRichtungAbDreiSpielern() {
        var r = NRegeln.standard; r.neunRichtung = true
        var s = NMauMau(haende: [[K(0, 9), K(0, 10)], [K(0, 12)], [K(1, 12)], [K(2, 12)]], ablage: [K(0, 13)], regeln: r, dran: 1)
        // Spieler 1 hat keine 9; mit Spieler 0 durchspielen
        s = NMauMau(haende: [[K(0, 9), K(0, 10)], [K(0, 12)], [K(1, 12)], [K(2, 12)]], ablage: [K(0, 13)], regeln: r, dran: 0)
        s.spiele(0)
        XCTAssertEqual(s.richtung, -1); XCTAssertEqual(s.dran, 3)
        XCTAssertEqual(s.vorheriger, 0)
    }
    func testNeunBeiZweiSpielernWechseltNicht() {
        var r = NRegeln.standard; r.neunRichtung = true
        var s = NMauMau(haende: [[K(0, 9), K(0, 10)], [K(0, 12), K(1, 9)]], ablage: [K(0, 13)], regeln: r)
        s.spiele(0)
        XCTAssertEqual(s.richtung, 1); XCTAssertEqual(s.dran, 1)
    }
    func testGegenRichtungZaehltRueckwaerts() {
        var r = NRegeln.standard; r.neunRichtung = true
        var s = NMauMau(haende: [[K(0, 9), K(0, 10)], [K(0, 12)], [K(1, 12)], [K(2, 12)]], ablage: [K(0, 13)], regeln: r)
        s.spiele(0)                       // dran: 3
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)                 // 3 hat nichts spielbar? ziehen -> weiter nach 2
        XCTAssertEqual(s.dran, 2)
    }
    func testZiehenLeertStapelMischtAblage() {
        var s = NMauMau(haende: [[K(3, 9)], [K(0, 12)]], ablage: [K(0, 8), K(0, 9), K(0, 10)], stapel: [])
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)
        XCTAssertEqual(s.haende[0].count, 2); XCTAssertEqual(s.ablage.count, 1)
    }
    func testZiehenOhneKartenGibtWeiter() {
        var s = NMauMau(haende: [[K(3, 9)], [K(0, 12)]], ablage: [K(0, 10)], stapel: [])
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)
        XCTAssertEqual(s.dran, 1); XCTAssertEqual(s.haende[0].count, 1)
    }
    func testSiegerUndKeinZugDanach() {
        var s = NMauMau(haende: [[K(0, 9)], [K(0, 12)]], ablage: [K(0, 10)])
        s.spiele(0)
        XCTAssertEqual(s.sieger, 0); XCTAssertFalse(s.spiele(0))
    }
    func testUngueltigerZug() {
        var s = NMauMau(haende: [[K(1, 9), K(0, 9)], [K(0, 12)]], ablage: [K(0, 10)])
        XCTAssertFalse(s.spiele(5)); XCTAssertFalse(s.spiele(0)); XCTAssertEqual(s.dran, 0)
    }
}

final class MauMauNeuMauTests: XCTestCase {
    func testOhneMauSagenKeineStrafe() {
        var s = NMauMau(haende: [[K(0, 9), K(0, 10)], [K(0, 12)]], ablage: [K(0, 13)], stapel: [K(3, 9), K(3, 10)])
        s.spiele(0)
        XCTAssertEqual(s.haende[0].count, 1)
    }
    func testVergessenesMauKostetEineKarte() {
        var r = NRegeln.standard; r.maueSagen = true
        var s = NMauMau(haende: [[K(0, 9), K(0, 10)], [K(0, 12)]], ablage: [K(0, 13)], stapel: [K(3, 9), K(3, 10)], regeln: r)
        s.spiele(0)
        XCTAssertEqual(s.haende[0].count, 2)
        XCTAssertTrue(s.verlauf.contains(.strafkarte(spieler: 0)))
    }
    func testMauGesagtKeineStrafe() {
        var r = NRegeln.standard; r.maueSagen = true
        var s = NMauMau(haende: [[K(0, 9), K(0, 10)], [K(0, 12)]], ablage: [K(0, 13)], stapel: [K(3, 9)], regeln: r)
        s.spiele(0, mau: true)
        XCTAssertEqual(s.haende[0].count, 1)
    }
    func testLetzteKarteBrauchtKeinMau() {
        var r = NRegeln.standard; r.maueSagen = true
        var s = NMauMau(haende: [[K(0, 9)], [K(0, 12)]], ablage: [K(0, 13)], stapel: [K(3, 9)], regeln: r)
        s.spiele(0)
        XCTAssertEqual(s.sieger, 0)
    }
}

final class MauMauNeuSofortLegenTests: XCTestCase {
    private var regeln: NRegeln { var r = NRegeln.standard; r.sofortLegen = true; return r }
    func testPassendeGezogeneKarteDarfGleichGelegtWerden() {
        var s = NMauMau(haende: [[K(3, 9)], [K(0, 12)]], ablage: [K(0, 10)], stapel: [K(0, 13)], regeln: regeln)
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)
        XCTAssertEqual(s.dran, 0); XCTAssertEqual(s.pflicht, .weiter); XCTAssertEqual(s.spielbareIndizes, [1])
        XCTAssertTrue(s.spiele(1)); XCTAssertEqual(s.dran, 1)
    }
    func testWeitergebenNachGezogenerKarte() {
        var s = NMauMau(haende: [[K(3, 9)], [K(0, 12)]], ablage: [K(0, 10)], stapel: [K(0, 13)], regeln: regeln)
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g); s.ziehen(mit: &g)
        XCTAssertEqual(s.dran, 1); XCTAssertNil(s.gezogenIndex)
    }
    func testAndereKartenSindNachDemZiehenGesperrt() {
        var s = NMauMau(haende: [[K(0, 9), K(0, 10)], [K(0, 12)]], ablage: [K(2, 14)], stapel: [K(2, 13)], regeln: regeln)
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)
        XCTAssertEqual(s.spielbareIndizes, [2])
    }
    func testUnpassendeGezogeneKarteGehtWeiter() {
        var s = NMauMau(haende: [[K(3, 9)], [K(0, 12)]], ablage: [K(0, 10)], stapel: [K(1, 13)], regeln: regeln)
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)
        XCTAssertEqual(s.dran, 1)
    }
    func testOhneRegelKeinSofortLegen() {
        var s = NMauMau(haende: [[K(3, 9)], [K(0, 12)]], ablage: [K(0, 10)], stapel: [K(0, 13)])
        var g = SystemRandomNumberGenerator()
        s.ziehen(mit: &g)
        XCTAssertEqual(s.dran, 1)
    }
}

final class MauMauNeuRundenTests: XCTestCase {
    func testAugenWerte() {
        XCTAssertEqual(K(0, 11).augen, 20); XCTAssertEqual(K(0, 14).augen, 11); XCTAssertEqual(K(0, 12).augen, 10)
        XCTAssertEqual(K(0, 13).augen, 10); XCTAssertEqual(K(0, 9).augen, 9)
    }
    func testRundeBuchtRestaugen() {
        var s = NMauMau(haende: [[K(0, 9)], [K(0, 11), K(1, 7)], [K(2, 14)]], ablage: [K(0, 10)])
        s.spiele(0)
        var r = NRunden(spieler: 3, ziel: 50)
        XCTAssertTrue(r.verbuche(s))
        XCTAssertEqual(r.punkte, [0, 27, 11]); XCTAssertEqual(r.runde, 2); XCTAssertFalse(r.beendet)
    }
    func testNichtBeendeteRundeWirdNichtGebucht() {
        let s = NMauMau(haende: [[K(0, 9)], [K(0, 11)]], ablage: [K(0, 10)])
        var r = NRunden(spieler: 2)
        XCTAssertFalse(r.verbuche(s)); XCTAssertEqual(r.punkte, [0, 0])
    }
    func testZielErreichtBeendetUndWenigsterGewinnt() {
        var r = NRunden(spieler: 2, ziel: 20)
        let s = NMauMau(haende: [[], [K(0, 11), K(0, 7)]], ablage: [K(0, 10)])
        r.verbuche(s)
        XCTAssertTrue(r.beendet); XCTAssertEqual(r.gesamtSieger, 0); XCTAssertEqual(r.reihenfolge, [0, 1])
    }
    func testGesamtSiegerNilVorZiel() {
        XCTAssertNil(NRunden(spieler: 2).gesamtSieger)
    }
}

final class MauMauNeuComputerTests: XCTestCase {
    func testTippIstDieComputerwahl() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<40 {
            let s = NMauMau(spieler: 3, mit: &g)
            XCTAssertEqual(NComputer.wahl(s, fehler: 0, mit: &g), NComputer.beste(s))
        }
    }
    func testKeineKarteGibtNil() {
        var g = SystemRandomNumberGenerator()
        let s = NMauMau(haende: [[K(3, 9)], [K(0, 12)]], ablage: [K(0, 10)])
        XCTAssertNil(NComputer.wahl(s, mit: &g))
    }
    func testBubeBekommtHaeufigsteFarbe() {
        let s = NMauMau(haende: [[K(0, 11), K(2, 9), K(2, 10), K(1, 12)], [K(0, 12)]], ablage: [K(3, 8)])
        // Nur der Bube passt nicht von selbst? 8 Karo oben: 9 Herz/10 Herz passen nicht, Bube passt immer.
        let z = NComputer.beste(s)
        XCTAssertEqual(z?.index, 0); XCTAssertEqual(z?.wunsch, 2)
    }
    func testSiebenAlsAngriffVorGleicherFarbe() {
        let s = NMauMau(haende: [[K(0, 7), K(0, 9), K(0, 12)], [K(0, 12), K(1, 9)]], ablage: [K(0, 10)])
        XCTAssertEqual(NComputer.beste(s)?.index, 0)
    }
    func testGanzePartienEndenBeiAllenRegeln() {
        var g = SystemRandomNumberGenerator()
        for regeln in [NRegeln.standard, .ass, .sieben, .schlicht, .streng, .wild] {
            for sp in [2, 3, 5] {
                var s = NMauMau(spieler: sp, regeln: regeln, mit: &g); var n = 0
                while s.sieger == nil && n < 3000 {
                    if let z = NComputer.wahl(s, fehler: 0.3, mit: &g) { s.spiele(z.index, wunsch: z.wunsch, mau: true) } else { s.ziehen(mit: &g) }
                    n += 1
                }
                let gesamt = s.haende.reduce(0) { $0 + $1.count } + s.stapel.count + s.ablage.count
                XCTAssertEqual(gesamt, 32 * NRegeln.blaetter(spieler: sp))
            }
        }
    }
    func testComputerSpieltImmerGueltig() {
        var g = SystemRandomNumberGenerator()
        var s = NMauMau(spieler: 4, regeln: .wild, mit: &g); var n = 0
        while s.sieger == nil && n < 2000 {
            if let z = NComputer.wahl(s, fehler: 0, mit: &g) { XCTAssertTrue(s.spielbar(z.index)); s.spiele(z.index, wunsch: z.wunsch, mau: true) } else { s.ziehen(mit: &g) }
            n += 1
        }
    }
    func testSchwerSchlaegtLeicht() {
        var g = SystemRandomNumberGenerator(); var schwer = 0
        for i in 0..<60 {
            var s = NMauMau(spieler: 2, mit: &g); let ich = i % 2; var n = 0
            while s.sieger == nil && n < 2000 {
                let f = s.dran == ich ? 0.0 : 0.7
                if let z = NComputer.wahl(s, fehler: f, mit: &g) { s.spiele(z.index, wunsch: z.wunsch, mau: true) } else { s.ziehen(mit: &g) }
                n += 1
            }
            if s.sieger == ich { schwer += 1 }
        }
        XCTAssertGreaterThan(schwer, 33, "\(schwer)/60")
    }
}

final class MauMauNeuVerlaufTests: XCTestCase {
    func testVerlaufHaeltGrenze() {
        var g = SystemRandomNumberGenerator()
        var s = NMauMau(spieler: 3, mit: &g); var n = 0
        while s.sieger == nil && n < 500 {
            if let z = NComputer.wahl(s, fehler: 0, mit: &g) { s.spiele(z.index, wunsch: z.wunsch, mau: true) } else { s.ziehen(mit: &g) }
            n += 1
        }
        XCTAssertLessThanOrEqual(s.verlauf.count, NMauMau.verlaufGrenze)
        XCTAssertFalse(s.verlauf.isEmpty)
    }
    func testSpielstandRoundtrip() throws {
        var g = SystemRandomNumberGenerator()
        var s = NMauMau(spieler: 4, regeln: .wild, mit: &g)
        for _ in 0..<12 where s.sieger == nil { if let z = NComputer.wahl(s, mit: &g) { s.spiele(z.index, wunsch: z.wunsch, mau: true) } else { s.ziehen(mit: &g) } }
        XCTAssertEqual(try JSONDecoder().decode(NMauMau.self, from: JSONEncoder().encode(s)), s)
    }
}
