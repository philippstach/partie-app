// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import ArcadeKern

final class ArcadeKernTests: XCTestCase {
    func testTaktLiefertFesteSchritte() {
        var t = FesterTakt()
        var n = 0
        for _ in 0..<60 { n += t.schritte(fuer: 1.0 / 60) }      // eine Sekunde in 60 Bildern
        XCTAssertTrue((119...120).contains(n), "\(n)")
    }
    func testTaktBegrenztLangeBildzeit() {
        var t = FesterTakt()
        XCTAssertLessThanOrEqual(t.schritte(fuer: 5), 12)
        XCTAssertEqual(t.schritte(fuer: -1), 0)
    }
    func testZufallReproduzierbar() {
        var a = ArcadeZufall(startwert: 7), b = ArcadeZufall(startwert: 7)
        for _ in 0..<20 { XCTAssertEqual(a.next(), b.next()) }
    }
    func testBeutelJedeSorteEinmalProRunde() {
        var z = ArcadeZufall(startwert: 1); var be = Beutel(sorten: 6)
        for _ in 0..<5 { XCTAssertEqual(Set((0..<6).map { _ in be.ziehe(&z) }).count, 6) }
    }
    func testKreisKasten() {
        let k = Kasten(x: 0, y: 0, b: 1, h: 1)
        XCTAssertNil(Treffer.kreis(x: 2, y: 2, r: 0.1, kasten: k))
        XCTAssertEqual(Treffer.kreis(x: 0.5, y: 1.05, r: 0.1, kasten: k)?.seite, .unten)
        XCTAssertEqual(Treffer.kreis(x: -0.05, y: 0.5, r: 0.1, kasten: k)?.seite, .links)
        XCTAssertNotNil(Treffer.kreis(x: 0.5, y: 0.5, r: 0.1, kasten: k))
    }
    func testSchwierigkeitSteigtUndBleibtBegrenzt() {
        XCTAssertEqual(Schwierigkeit.anteil(0, halbwert: 30), 0)
        XCTAssertEqual(Schwierigkeit.anteil(30, halbwert: 30), 0.5, accuracy: 1e-9)
        XCTAssertLessThan(Schwierigkeit.anteil(10_000, halbwert: 30), 1.0 + 1e-12)
        var v = -1.0
        for t in stride(from: 0.0, to: 600, by: 5) { let a = Schwierigkeit.anteil(t, halbwert: 40); XCTAssertGreaterThanOrEqual(a, v); v = a }
    }
    func testRekord() {
        XCTAssertTrue(Rekord.istNeu(punkte: 10, bisher: nil))
        XCTAssertFalse(Rekord.istNeu(punkte: 10, bisher: 10))
        XCTAssertFalse(Rekord.istNeu(punkte: 0, bisher: nil))
    }
}

final class ArcadePauseTests: XCTestCase {
    func testHintergrundPausiertNurLaufendesSpiel() {
        var p = ArcadePause()
        p.szene(aktiv: false, phase: .bereit); XCTAssertFalse(p.pausiert, "vor dem Start gibt es nichts zu pausieren")
        p.szene(aktiv: false, phase: .vorbei(grund: "x")); XCTAssertFalse(p.pausiert)
        p.szene(aktiv: false, phase: .laeuft); XCTAssertTrue(p.pausiert)
        XCTAssertFalse(p.uhrLaeuft(phase: .laeuft)); XCTAssertFalse(p.nimmtEingabe)
    }
    func testRueckkehrBleibtPausiertBisTippen() {
        var p = ArcadePause()
        p.szene(aktiv: false, phase: .laeuft)
        p.szene(aktiv: true, phase: .laeuft)
        XCTAssertTrue(p.pausiert, "nach der Rückkehr wartet das Spiel auf den Tipp")
        p.weiter(); XCTAssertTrue(p.uhrLaeuft(phase: .laeuft)); XCTAssertTrue(p.nimmtEingabe)
    }
    func testMenueUndVerlassenUndNeu() {
        var p = ArcadePause()
        p.umschalten(phase: .bereit); XCTAssertFalse(p.pausiert)
        p.umschalten(phase: .laeuft); XCTAssertTrue(p.pausiert)
        p.umschalten(phase: .laeuft); XCTAssertFalse(p.pausiert)
        p.verlassen(phase: .laeuft); XCTAssertTrue(p.pausiert)
        p.zuruecksetzen(); XCTAssertFalse(p.pausiert)
        p.verlassen(phase: .vorbei(grund: "x")); XCTAssertFalse(p.pausiert)
    }
    /// Während der Pause darf sich ein Spiel nicht bewegen: die Hülle ruft `schritt` dann nicht auf (Uhr aus).
    func testPauseHaeltTaktAn() {
        var p = ArcadePause(); var t = FesterTakt(); var schritte = 0
        p.szene(aktiv: false, phase: .laeuft)
        for _ in 0..<60 { if p.uhrLaeuft(phase: .laeuft) { schritte += t.schritte(fuer: 1.0 / 60) } }
        XCTAssertEqual(schritte, 0)
        p.weiter()
        for _ in 0..<60 { if p.uhrLaeuft(phase: .laeuft) { schritte += t.schritte(fuer: 1.0 / 60) } }
        XCTAssertGreaterThanOrEqual(schritte, 119)
    }
}

final class ArcadeRueckmeldungTests: XCTestCase {
    func testZuordnungUndSchalter() {
        var r = ArcadeRueckmeldung()
        XCTAssertEqual(r.melden(.treffer, zeit: 0, haptikAn: true, tonAn: true), ArcadeAusgabe(haptik: .leicht, ton: .tick))
        XCTAssertEqual(r.melden(.verlust, zeit: 0, haptikAn: true, tonAn: false), ArcadeAusgabe(haptik: .fehler, ton: nil))
        XCTAssertEqual(r.melden(.rekord, zeit: 0, haptikAn: false, tonAn: true), ArcadeAusgabe(haptik: nil, ton: .fanfare))
        var s = ArcadeRueckmeldung()
        XCTAssertNil(s.melden(.verlust, zeit: 0, haptikAn: false, tonAn: false), "beide Schalter aus: nichts")
    }
    func testTrefferWerdenGedrosseltAndereEreignisseUnabhaengig() {
        var r = ArcadeRueckmeldung()
        XCTAssertNotNil(r.melden(.treffer, zeit: 10.00, haptikAn: true, tonAn: true))
        XCTAssertNil(r.melden(.treffer, zeit: 10.05, haptikAn: true, tonAn: true))
        XCTAssertNotNil(r.melden(.verlust, zeit: 10.06, haptikAn: true, tonAn: true), "anderes Ereignis wird nicht gedrosselt")
        XCTAssertNotNil(r.melden(.treffer, zeit: 10.20, haptikAn: true, tonAn: true))
        XCTAssertNil(r.melden(.verlust, zeit: 10.5, haptikAn: true, tonAn: true), "Verlust höchstens einmal je Sekunde")
    }
    func testPauseIstStumm() {
        var r = ArcadeRueckmeldung()
        XCTAssertNil(r.melden(.treffer, zeit: 0, haptikAn: true, tonAn: true, pausiert: true))
        XCTAssertNotNil(r.melden(.treffer, zeit: 0, haptikAn: true, tonAn: true), "Pause verbraucht die Drossel nicht")
    }
    func testEndeEreignisRekordOderVerlust() {
        XCTAssertEqual(ArcadeRueckmeldung.endeEreignis(punkte: 500, bisherigerRekord: 400), .rekord)
        XCTAssertEqual(ArcadeRueckmeldung.endeEreignis(punkte: 500, bisherigerRekord: nil), .rekord)
        XCTAssertEqual(ArcadeRueckmeldung.endeEreignis(punkte: 400, bisherigerRekord: 400), .verlust)
        XCTAssertEqual(ArcadeRueckmeldung.endeEreignis(punkte: 0, bisherigerRekord: nil), .verlust)
    }

    func testWiederErscheinenPausiertNurEinmalUndSchaltetNichtUm() {
        var p = ArcadePause()
        p.verlassen(phase: .laeuft); p.verlassen(phase: .laeuft)
        XCTAssertTrue(p.pausiert)
        var q = ArcadePause(); q.verlassen(phase: .bereit)
        XCTAssertFalse(q.pausiert)
    }

    func testLebenVerlorenHatEigeneRueckmeldungUndSchalter() {
        var r = ArcadeRueckmeldung()
        let a = r.melden(.lebenVerloren, zeit: 10, haptikAn: true, tonAn: false)
        XCTAssertEqual(a?.haptik, .mittel); XCTAssertNil(a?.ton)
        XCTAssertNil(r.melden(.lebenVerloren, zeit: 10.2, haptikAn: true, tonAn: true), "zu kurz danach")
        XCTAssertNotNil(r.melden(.lebenVerloren, zeit: 10.6, haptikAn: true, tonAn: true))
        XCTAssertNil(r.melden(.lebenVerloren, zeit: 20, haptikAn: false, tonAn: false), "beide Schalter aus")
        XCTAssertNil(r.melden(.lebenVerloren, zeit: 30, haptikAn: true, tonAn: true, pausiert: true))
    }
}
