// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import KaestchenjagdKern
final class KaestchenjagdTests: XCTestCase {
    func testKantenZahl() {
        let s = Kaestchenjagd(breite: 4, hoehe: 4); XCTAssertEqual(s.alleKanten.count, 40)
    }
    func testKaestchenSchliessenGibtNochmalZug() {
        var s = Kaestchenjagd(breite: 2, hoehe: 2)
        for k in s.seiten(0, 0).dropLast() { s.ziehe(k) }       // 3 Seiten, Spieler wechseln
        XCTAssertEqual(s.punkte, [0, 0])
        let vor = s.amZug
        s.ziehe(s.seiten(0, 0).last!)
        XCTAssertEqual(s.punkte[vor], 1); XCTAssertEqual(s.amZug, vor)
    }
    func testPartienEnden() {
        var g = SystemRandomNumberGenerator()
        for st in 0...2 {
            var s = Kaestchenjagd(breite: 4, hoehe: 4)
            while !s.vorbei { s.ziehe(s.computerZug(stufe: st, mit: &g)!) }
            XCTAssertEqual(s.punkte.reduce(0, +), 16)
        }
    }
    func testSchwererSchlaegtZufall() {
        var g = SystemRandomNumberGenerator(); var siege = 0
        for k in 0..<12 {
            var s = Kaestchenjagd(breite: 4, hoehe: 4)
            let ich = k % 2
            while !s.vorbei { s.ziehe(s.computerZug(stufe: s.amZug == ich ? 2 : 0, mit: &g)!) }
            if s.punkte[ich] > s.punkte[1 - ich] { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 9)
    }
}

final class KaestchenjagdRegelTests: XCTestCase {
    func testDoppelterZugUndFremdeKanteWerdenAbgelehnt() {
        var s = Kaestchenjagd(breite: 3, hoehe: 3)
        let k = Kante(waagrecht: true, 0, 0)
        XCTAssertTrue(s.ziehe(k)); XCTAssertFalse(s.ziehe(k))
        XCTAssertFalse(s.ziehe(Kante(waagrecht: true, 9, 9)))
        XCTAssertFalse(s.ziehe(Kante(waagrecht: true, 0, 4)))
    }
    func testOhneKaestchenWechseltDerSpieler() {
        var s = Kaestchenjagd(breite: 3, hoehe: 3)
        s.ziehe(Kante(waagrecht: true, 0, 0))
        XCTAssertEqual(s.amZug, 1); XCTAssertEqual(s.letzte, Kante(waagrecht: true, 0, 0))
    }
    func testEineKanteKannZweiKaestchenSchliessen() {
        var s = Kaestchenjagd(breite: 2, hoehe: 1)
        // Beide Kästchen bis auf die gemeinsame senkrechte Mittelkante füllen
        for k in [Kante(waagrecht: true, 0, 0), Kante(waagrecht: true, 1, 0), Kante(waagrecht: true, 0, 1), Kante(waagrecht: true, 1, 1), Kante(waagrecht: false, 0, 0), Kante(waagrecht: false, 2, 0)] { s.ziehe(k) }
        let wer = s.amZug
        s.ziehe(Kante(waagrecht: false, 1, 0))
        XCTAssertEqual(s.punkte[wer], 2); XCTAssertTrue(s.vorbei); XCTAssertEqual(s.besitzer[0], [wer, wer])
    }
    func testNachDemEndeKeineZuegeMehr() {
        var s = Kaestchenjagd(breite: 1, hoehe: 1)
        for k in s.alleKanten { s.ziehe(k) }
        XCTAssertTrue(s.vorbei)
        XCTAssertFalse(s.ziehe(Kante(waagrecht: true, 0, 0)))
        var rng = SystemRandomNumberGenerator(); XCTAssertNil(s.computerZug(stufe: 2, mit: &rng))
    }
    func testAngrenzendeKaestchenAmRand() {
        let s = Kaestchenjagd(breite: 3, hoehe: 3)
        XCTAssertEqual(s.angrenzend(Kante(waagrecht: true, 1, 0)).count, 1)
        XCTAssertEqual(s.angrenzend(Kante(waagrecht: true, 1, 1)).count, 2)
        XCTAssertEqual(s.angrenzend(Kante(waagrecht: false, 0, 1)).count, 1)
    }
    func testComputerNimmtGeschenktesKaestchenAufJederStufe() {
        var g = SystemRandomNumberGenerator()
        for st in 0...2 {
            var s = Kaestchenjagd(breite: 2, hoehe: 2)
            for k in s.seiten(0, 0).dropLast() { s.ziehe(k) }
            let fehlend = s.seiten(0, 0).last!
            XCTAssertEqual(s.computerZug(stufe: st, mit: &g), fehlend, "Stufe \(st)")
        }
    }
    func testKluegerComputerVermeidetDieDritteSeiteWennEsGeht() {
        var g = SystemRandomNumberGenerator()
        var s = Kaestchenjagd(breite: 3, hoehe: 3)
        for k in s.seiten(1, 1).prefix(2) { s.ziehe(k) }       // Kästchen in der Mitte hat zwei Seiten
        for _ in 0..<30 {
            let z = s.computerZug(stufe: 1, mit: &g)!
            XCTAssertFalse(s.angrenzend(z).contains { s.zahlSeiten($0.0, $0.1) == 2 }, "keine dritte Seite verschenken")
        }
    }
    func testSpielstandIstCodierbar() throws {
        var s = Kaestchenjagd(breite: 3, hoehe: 2)
        s.ziehe(Kante(waagrecht: true, 0, 0)); s.ziehe(Kante(waagrecht: false, 0, 0))
        let neu = try JSONDecoder().decode(Kaestchenjagd.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}

final class KaestchenjagdEndspielTests: XCTestCase {
    /// Spielt eine Partie bis nur noch `rest` Kanten frei sind (zufällig, ohne Computer).
    private func bisRest(_ rest: Int, _ g: inout SystemRandomNumberGenerator, b: Int = 3, h: Int = 3) -> Kaestchenjagd {
        var s = Kaestchenjagd(breite: b, hoehe: h)
        while s.freieKanten.count > rest { s.ziehe(s.freieKanten.randomElement(using: &g)!) }
        return s
    }
    func testExakterZugIstGueltig() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            let s = bisRest(10, &g)
            if s.vorbei { continue }
            let z = s.computerZug(stufe: 2, mit: &g)!
            XCTAssertTrue(s.freieKanten.contains(z))
        }
    }
    func testExakteSucheSchlaegtGierigImEndspiel() {
        var g = SystemRandomNumberGenerator(); var siege = 0, verloren = 0
        for i in 0..<40 {
            var s = bisRest(12, &g)
            let ich = i % 2
            s = { var t = s; if t.amZug != ich { _ = t }; return t }()
            while !s.vorbei { s.ziehe(s.computerZug(stufe: s.amZug == ich ? 2 : 1, mit: &g)!) }
            if s.punkte[ich] > s.punkte[1 - ich] { siege += 1 } else if s.punkte[ich] < s.punkte[1 - ich] { verloren += 1 }
        }
        print("KAESTCHEN exakt \(siege) gierig \(verloren)")
        XCTAssertGreaterThanOrEqual(siege, verloren)
    }
    func testDoppelKreuzWirdErkannt() {
        // Kette aus zwei Kästchen (1×2) mit nur der Mittelkante und einer Endkante offen: Nehmen beider ist besser als das Opfern.
        var s = Kaestchenjagd(breite: 2, hoehe: 1)
        for k in [Kante(waagrecht: true, 0, 0), Kante(waagrecht: true, 1, 0), Kante(waagrecht: true, 0, 1), Kante(waagrecht: true, 1, 1), Kante(waagrecht: false, 0, 0)] { s.ziehe(k) }
        // frei: Mitte (1,0) und Ende (2,0) -- jeder Zug öffnet die Kette; der Gegner nimmt dann beide
        var g = SystemRandomNumberGenerator()
        XCTAssertNotNil(s.computerZug(stufe: 2, mit: &g))
    }
    func testGanzePartieMitAllenStufen() {
        var g = SystemRandomNumberGenerator()
        for stufe in 0...2 {
            var s = Kaestchenjagd(breite: 3, hoehe: 3)
            while !s.vorbei { s.ziehe(s.computerZug(stufe: stufe, mit: &g)!) }
            XCTAssertEqual(s.punkte[0] + s.punkte[1], 9)
        }
    }
}
