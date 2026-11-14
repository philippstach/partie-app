// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HerzensjagdKern

final class HerzensjagdTests: XCTestCase {
    func testAustellen() {
        var g = SystemRandomNumberGenerator(); let s = Herzensjagd(mit: &g)
        XCTAssertTrue(s.haende.allSatisfy { $0.count == 13 })
        XCTAssertTrue(s.haende[s.amZug].contains(HKarte.kreuzZwei))
        XCTAssertEqual(s.erlaubt(s.amZug), [HKarte.kreuzZwei])
    }
    func testRundenSummenPunkte26() {
        for _ in 0..<50 {
            var g = SystemRandomNumberGenerator(); var s = Herzensjagd(mit: &g)
            while !s.rundeFertig {
                s.spiele(s.computerWahl(s.amZug))
                if s.stichVoll { s.stichAbschliessen(mit: &g) }
            }
            XCTAssertTrue(s.gesamt.reduce(0, +) == 26 || s.gesamt.reduce(0, +) == 78)    // normal oder Mondschuss
        }
    }
    func testPartienEnden() {
        for _ in 0..<20 {
            var g = SystemRandomNumberGenerator(); var s = Herzensjagd(ziel: 50, mit: &g); var n = 0
            while !s.vorbei && n < 10000 {
                s.spiele(s.computerWahl(s.amZug))
                if s.stichVoll { s.stichAbschliessen(mit: &g) }
                if s.rundeFertig && !s.vorbei { s.naechsteRunde(mit: &g) }
                n += 1
            }
            XCTAssertTrue(s.vorbei)
        }
    }
    func testBedienenPflicht() {
        var g = SystemRandomNumberGenerator(); var s = Herzensjagd(mit: &g)
        s.spiele(HKarte.kreuzZwei)
        let n = s.amZug
        let kreuze = s.haende[n].filter { $0.farbe == 0 }
        if !kreuze.isEmpty { XCTAssertTrue(s.erlaubt(n).allSatisfy { $0.farbe == 0 }) }
    }
    func testKartenPunkte() {
        XCTAssertEqual(HKarte.alle.reduce(0) { $0 + $1.punkte }, 26)
    }
    func testFehlerhafterComputerSpieltTrotzdemLegal() {
        for fehler in [0.0, 0.5, 1.0] {
            var g = SystemRandomNumberGenerator(); var s = Herzensjagd(mit: &g); var n = 0
            while !s.rundeFertig && n < 500 {
                let k = s.computerWahl(s.amZug, fehler: fehler, mit: &g)
                XCTAssertTrue(s.erlaubt(s.amZug).contains(k))
                s.spiele(k)
                if s.stichVoll { s.stichAbschliessen(mit: &g) }
                n += 1
            }
            XCTAssertTrue(s.rundeFertig)
        }
    }

    /// Platz 0 spielt „schwer“ (fehler 0), die drei anderen „leicht“ (fehler 0.45): Platz 0 sammelt deutlich weniger Strafpunkte.
    func testSchwerSammeltWenigerPunkteAlsLeicht() {
        var eigene = 0.0, fremde = 0.0; let partien = 60
        for _ in 0..<partien {
            var g = SystemRandomNumberGenerator(); var s = Herzensjagd(ziel: 50, mit: &g); var n = 0
            while !s.vorbei && n < 10000 {
                let k = s.computerWahl(s.amZug, fehler: s.amZug == 0 ? 0 : 0.45, mit: &g)
                s.spiele(k)
                if s.stichVoll { s.stichAbschliessen(mit: &g) }
                if s.rundeFertig && !s.vorbei { s.naechsteRunde(mit: &g) }
                n += 1
            }
            eigene += Double(s.gesamt[0]); fremde += Double(s.gesamt[1] + s.gesamt[2] + s.gesamt[3]) / 3
        }
        XCTAssertLessThan(eigene, fremde * 0.9, "schwer \(eigene / Double(partien)), leicht \(fremde / Double(partien))")
    }
}

final class FaecherTests: XCTestCase {
    func testDreizehnKartenPassenAufJedesIPhone() {
        for breite in stride(from: 320.0, through: 440.0, by: 10) {
            let platz = breite - 32
            XCTAssertLessThanOrEqual(Faecher.breite(anzahl: 13, kartenbreite: 44, platz: platz), platz, "Breite \(breite)")
        }
    }
    func testWenigeKartenLiegenLockerNebeneinander() {
        XCTAssertEqual(Faecher.schritt(anzahl: 3, kartenbreite: 44, platz: 340), 48)
        XCTAssertEqual(Faecher.schritt(anzahl: 1, kartenbreite: 44, platz: 340), 44)
        XCTAssertEqual(Faecher.breite(anzahl: 0, kartenbreite: 44, platz: 340), 44)
    }
    func testSchrittNimmtMitMehrKartenAb() {
        let a = (2...13).map { Faecher.schritt(anzahl: $0, kartenbreite: 44, platz: 340) }
        XCTAssertEqual(a, a.sorted(by: >))
    }
}

final class HerzensjagdRegelnTests: XCTestCase {
    private func h(_ f: Int, _ w: Int) -> HKarte { HKarte(f, w) }
    private func vier(_ a: [HKarte], _ b: [HKarte] = [HKarte(0, 3)], _ c: [HKarte] = [HKarte(0, 4)], _ d: [HKarte] = [HKarte(0, 5)]) -> [[HKarte]] { [a, b, c, d] }

    func testPunktwerte() {
        XCTAssertEqual(HKarte(3, 2).punkte, 1); XCTAssertEqual(HKarte.pikDame.punkte, 13); XCTAssertEqual(HKarte(2, 13).punkte, 0)
        XCTAssertEqual(HKarte.alle.reduce(0) { $0 + $1.punkte }, 26)
    }
    func testErsterStichBeginntMitKreuzZwei() {
        var g = SystemRandomNumberGenerator(); let s = Herzensjagd(mit: &g)
        XCTAssertEqual(s.erlaubt(s.amZug), [HKarte.kreuzZwei])
        XCTAssertTrue(s.haende[s.amZug].contains(HKarte.kreuzZwei))
        XCTAssertEqual(s.haende.map(\.count), [13, 13, 13, 13])
    }
    func testBedienpflicht() {
        let t = Herzensjagd(haende: vier([h(1, 2), h(0, 9), h(3, 5)], [h(1, 8)]), amZug: 0, stichNummer: 2, herzenOffen: true, stich: [StichKarte(spieler: 3, karte: h(0, 7))])
        XCTAssertEqual(t.erlaubt(0), [h(0, 9)])
    }
    func testAusspielenMitHerzErstNachDemErstenHerz() {
        let zu = Herzensjagd(haende: vier([h(3, 5), h(0, 9)]), amZug: 0, stichNummer: 3)
        XCTAssertEqual(zu.erlaubt(0), [h(0, 9)])
        let offen = Herzensjagd(haende: vier([h(3, 5), h(0, 9)]), amZug: 0, stichNummer: 3, herzenOffen: true)
        XCTAssertEqual(Set(offen.erlaubt(0)), [h(3, 5), h(0, 9)])
        let nurHerz = Herzensjagd(haende: vier([h(3, 5), h(3, 9)]), amZug: 0, stichNummer: 3)
        XCTAssertEqual(Set(nurHerz.erlaubt(0)), [h(3, 5), h(3, 9)])
    }
    func testImErstenStichKeinePunktkartenWennVermeidbar() {
        let s = Herzensjagd(haende: vier([h(3, 5), h(2, 12), h(2, 3)]), amZug: 1, stichNummer: 0, stich: [StichKarte(spieler: 0, karte: h(0, 2))])
        XCTAssertEqual(s.erlaubt(0), [h(2, 3)])
    }
    func testStichGewinnerIstDerHoechsteDerAngespieltenFarbeUndBekommtDiePunkte() {
        var g = SystemRandomNumberGenerator()
        var s = Herzensjagd(haende: vier([h(1, 9)], [h(1, 13)], [h(3, 2)], [h(2, 12)]), amZug: 0, stichNummer: 5)
        for _ in 0..<4 { s.spiele(s.erlaubt(s.amZug)[0]) }
        XCTAssertTrue(s.stichVoll)
        s.stichAbschliessen(mit: &g)
        XCTAssertEqual(s.rundenPunkte, [0, 14, 0, 0]); XCTAssertEqual(s.amZug, 1); XCTAssertTrue(s.herzenOffen)
    }
    func testKarteAusFremderHandWirdAbgelehnt() {
        var s = Herzensjagd(haende: vier([h(0, 9)], [h(1, 2)]), amZug: 0, stichNummer: 2, herzenOffen: true)
        XCTAssertFalse(s.spiele(h(1, 2))); XCTAssertTrue(s.spiele(h(0, 9)))
    }
    func testMondschussGibtDenAnderenJeSechsundzwanzig() {
        var g = SystemRandomNumberGenerator()
        var s = Herzensjagd(haende: vier([h(0, 14)], [h(0, 3)], [h(0, 4)], [h(0, 5)]), amZug: 0, stichNummer: 12, rundenPunkte: [26, 0, 0, 0])
        for _ in 0..<4 { s.spiele(s.erlaubt(s.amZug)[0]) }
        s.stichAbschliessen(mit: &g)
        XCTAssertEqual(s.mondschuss, 0); XCTAssertEqual(s.gesamt, [0, 26, 26, 26]); XCTAssertTrue(s.rundeFertig)
    }
    func testSpielEndetBeiZielUndSiegerHatDieWenigstenPunkte() {
        var g = SystemRandomNumberGenerator()
        var s = Herzensjagd(ziel: 20, haende: vier([h(0, 14)], [h(0, 3)], [h(0, 4)], [h(0, 5)]), amZug: 0, stichNummer: 12, rundenPunkte: [0, 0, 0, 22])
        for _ in 0..<4 { s.spiele(s.erlaubt(s.amZug)[0]) }
        s.stichAbschliessen(mit: &g)
        XCTAssertTrue(s.vorbei); XCTAssertEqual(s.gesamt, [0, 0, 0, 22]); XCTAssertEqual(s.rangfolge.last, 3)
    }
    func testComputerWirftPikDameBeiNichtBedienenAb() {
        let s = Herzensjagd(haende: vier([h(2, 12), h(3, 9), h(1, 5)]), amZug: 1, stichNummer: 4, herzenOffen: true, stich: [StichKarte(spieler: 0, karte: h(0, 9))])
        XCTAssertEqual(s.computerWahl(0), HKarte.pikDame)
    }
    func testComputerGibtNiedrigerBeiBedienenWennMoeglich() {
        let s = Herzensjagd(haende: vier([h(0, 3), h(0, 13), h(0, 8)]), amZug: 1, stichNummer: 4, herzenOffen: true, stich: [StichKarte(spieler: 3, karte: h(0, 10))])
        XCTAssertEqual(s.computerWahl(0), h(0, 8))
    }

    // MARK: 1.0 (M5) Weitergeben und Zielpunkte
    func testWeitergabeRichtungReihum() {
        XCTAssertEqual((1...5).map { Herzensjagd.weitergabeRichtung(runde: $0) }, [1, 3, 2, nil, 1])
    }
    func testOhneWeitergabeBeginntDirekt() {
        var g = SystemRandomNumberGenerator(); let s = Herzensjagd(mit: &g)
        XCTAssertFalse(s.weitergabeOffen)
    }
    func testWeitergabeTauschtDreiKartenNachLinks() {
        var g = SystemRandomNumberGenerator(); var s = Herzensjagd(weitergeben: true, mit: &g)
        XCTAssertTrue(s.weitergabeOffen); XCTAssertEqual(s.weitergabeRichtung, 1)
        XCTAssertNil(s.tippKarte(0)); XCTAssertFalse(s.spiele(s.haende[0][0]))
        let vorher = s.haende
        var gegeben: [[HKarte]] = []
        for i in 0..<4 { gegeben.append(s.computerWeitergabe(i)); s.computerWaehltWeitergabe() }
        XCTAssertFalse(s.weitergabeOffen)
        for i in 0..<4 {
            let von = (i + 3) % 4   // Richtung links: Spieler i bekommt von i-1
            XCTAssertEqual(s.haende[i].count, 13)
            XCTAssertTrue(gegeben[von].allSatisfy { s.haende[i].contains($0) })
            XCTAssertTrue(vorher[i].filter { !gegeben[i].contains($0) }.allSatisfy { s.haende[i].contains($0) })
        }
        XCTAssertEqual(Set(s.haende.flatMap { $0 }).count, 52)
        XCTAssertTrue(s.haende[s.amZug].contains(HKarte.kreuzZwei))
    }
    func testWeitergabeBrauchtGenauDreiKarten() {
        var g = SystemRandomNumberGenerator(); var s = Herzensjagd(weitergeben: true, mit: &g)
        let h = s.haende[0]
        s.waehleWeitergabe(h[0]); s.waehleWeitergabe(h[1])
        XCTAssertFalse(s.weitergabeBereit)
        s.waehleWeitergabe(h[2]); s.waehleWeitergabe(h[3])
        XCTAssertEqual(s.gewaehlt[0].count, 3); XCTAssertTrue(s.weitergabeBereit)
        s.waehleWeitergabe(h[2]); XCTAssertEqual(s.gewaehlt[0].count, 2)
    }
    func testComputerGibtPikDameUndHoheHerzenWeiter() {
        let hand: [HKarte] = [h(2, 12), h(3, 14), h(3, 13), h(0, 3), h(1, 4), h(0, 5), h(1, 6), h(0, 7), h(1, 8), h(0, 9), h(1, 10), h(0, 11), h(1, 2)]
        let s = Herzensjagd(haende: vier(hand), amZug: 0)
        XCTAssertEqual(Set(s.computerWeitergabe(0)), [h(2, 12), h(3, 14), h(3, 13)])
    }
    func testPartieMitWeitergabeUndZiel100EndetErst100() {
        for _ in 0..<5 {
            var g = SystemRandomNumberGenerator(); var s = Herzensjagd(ziel: 100, weitergeben: true, mit: &g); var n = 0
            while !s.vorbei && n < 20000 {
                if s.weitergabeOffen { s.computerWaehltWeitergabe() }
                else { s.spiele(s.computerWahl(s.amZug)); if s.stichVoll { s.stichAbschliessen(mit: &g) } }
                if s.rundeFertig && !s.vorbei { s.naechsteRunde(mit: &g) }
                n += 1
            }
            XCTAssertTrue(s.vorbei); XCTAssertTrue(s.gesamt.max()! >= 100)
        }
    }
    func testAlterStandOhneWeitergabeLaesstSichLesen() throws {
        var g = SystemRandomNumberGenerator(); let s = Herzensjagd(mit: &g)
        var j = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as! [String: Any]
        for k in ["weitergeben", "weitergabeOffen", "gewaehlt", "bestaetigt"] { j[k] = nil }
        let neu = try JSONDecoder().decode(Herzensjagd.self, from: JSONSerialization.data(withJSONObject: j))
        XCTAssertEqual(neu, s); XCTAssertFalse(neu.weitergeben)
    }
}
