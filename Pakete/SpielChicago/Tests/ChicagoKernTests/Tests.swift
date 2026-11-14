// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import ChicagoKern

final class ChicagoTests: XCTestCase {
    func testTrefferUndPasch() {
        var c = Chicago(spieler: 2)
        c.setzeWurf(1, 1); XCTAssertEqual(c.ziel, 2); XCTAssertEqual(c.punkte[0], 4); XCTAssertEqual(c.treffer, true)
        c.weiter(); XCTAssertEqual(c.dran, 1)
        c.setzeWurf(3, 4); c.setzeWurf(5, 5); c.setzeWurf(6, 6); XCTAssertEqual(c.treffer, false); XCTAssertEqual(c.punkte[1], 0)
    }
    func testSpielEnde() {
        var c = Chicago(spieler: 3); var g = SystemRandomNumberGenerator(); var n = 0
        while !c.beendet && n < 2000 { if c.darfWerfen { c.wuerfeln(mit: &g) } else { c.weiter() }; n += 1 }
        XCTAssertTrue(c.beendet); XCTAssertEqual(c.runde, 11)
    }
    func testUngueltigeEingabenUndWeiterOhneAbschluss() {
        var c = Chicago(spieler: 2)
        c.setzeWurf(0, 3); c.setzeWurf(7, 1); XCTAssertEqual(c.versuche, 0)
        c.weiter(); XCTAssertEqual(c.dran, 0, "ohne Ergebnis kein Weiterschalten")
        c.setzeWurf(2, 3); XCTAssertEqual(c.versuche, 1); XCTAssertNil(c.treffer); XCTAssertTrue(c.darfWerfen)
    }
    func testNachTrefferKeinWeiteresWerfen() {
        var c = Chicago(spieler: 1)
        c.setzeWurf(1, 1); c.setzeWurf(1, 1)
        XCTAssertEqual(c.punkte[0], 4); XCTAssertEqual(c.versuche, 1); XCTAssertFalse(c.darfWerfen)
    }
    func testLetzteRundePaschZaehltDoppelt() {
        var c = Chicago(spieler: 1)
        for _ in 0..<10 { c.setzeWurf(6, 6); c.setzeWurf(6, 6); c.setzeWurf(6, 6); c.weiter() }
        XCTAssertEqual(c.ziel, 12); XCTAssertFalse(c.beendet)
        let vorher = c.punkte[0]
        c.setzeWurf(6, 6); XCTAssertEqual(c.punkte[0], vorher + 24)
        c.weiter(); XCTAssertTrue(c.beendet)
        c.setzeWurf(1, 1); c.weiter(); XCTAssertEqual(c.punkte[0], vorher + 24)
    }
}

final class ChicagoRegelTests: XCTestCase {
    func testNormalerTrefferGibtZielzahlPunkte() {
        var c = Chicago(spieler: 1)
        c.setzeWurf(1, 1); c.weiter()          // Runde 1 (Ziel 2), Pasch doppelt
        XCTAssertEqual(c.ziel, 3)
        c.setzeWurf(1, 2); XCTAssertEqual(c.punkte[0], 4 + 3, "Kein Pasch: einfache Zielzahl")
    }
    func testDreiFehlversucheBeendenDenZug() {
        var c = Chicago(spieler: 2)
        c.setzeWurf(6, 6); c.setzeWurf(5, 6); c.setzeWurf(4, 6)
        XCTAssertEqual(c.treffer, false); XCTAssertFalse(c.darfWerfen); XCTAssertEqual(c.punkte, [0, 0])
        c.weiter(); XCTAssertEqual(c.dran, 1); XCTAssertEqual(c.runde, 0)
    }
    func testNachAllenSpielernKommtDieNaechsteRunde() {
        var c = Chicago(spieler: 3)
        for _ in 0..<3 { c.setzeWurf(1, 1); c.weiter() }
        XCTAssertEqual(c.dran, 0); XCTAssertEqual(c.runde, 1); XCTAssertEqual(c.ziel, 3)
    }
    func testSpielstandIstCodierbarOhneAnzeigewurf() throws {
        var c = Chicago(spieler: 2)
        c.setzeWurf(1, 1)
        let neu = try JSONDecoder().decode(Chicago.self, from: JSONEncoder().encode(c))
        XCTAssertEqual(neu.punkte, c.punkte); XCTAssertEqual(neu.treffer, true); XCTAssertEqual(neu.runde, c.runde)
        XCTAssertNil(neu.wurf)
    }
    func testElfRundenMitZielzahlenZweiBisZwoelf() {
        var c = Chicago(spieler: 1); var ziele: [Int] = []
        while !c.beendet { ziele.append(c.ziel); c.setzeWurf(c.ziel > 7 ? 6 : 1, c.ziel > 7 ? c.ziel - 6 : c.ziel - 1); c.weiter() }
        XCTAssertEqual(ziele, Array(2...12))
    }

    func testZielZweiGehtNurMitZweiEinsern() {
        var c = Chicago(spieler: 2)
        c.setzeWurf(1, 1)
        XCTAssertEqual(c.punkte[0], 4, "2 mal 2 für den Pasch")
    }
    func testZielZwoelfIstDerSechserPasch() {
        var c = Chicago(spieler: 1)
        for _ in 0..<10 { c.setzeWurf(6, 6); c.setzeWurf(6, 6); c.setzeWurf(6, 6); c.weiter() }
        XCTAssertEqual(c.ziel, 12)
        c.setzeWurf(6, 6)
        XCTAssertEqual(c.punkte[0], 24)
    }
    func testVersucheZaehlenUndDritterFehlschlagBeendetDenZug() {
        var c = Chicago(spieler: 2)
        c.setzeWurf(5, 6); XCTAssertEqual(c.versuche, 1); XCTAssertNil(c.treffer); XCTAssertTrue(c.darfWerfen)
        c.setzeWurf(5, 6); XCTAssertEqual(c.versuche, 2); XCTAssertTrue(c.darfWerfen)
        c.setzeWurf(5, 6); XCTAssertEqual(c.versuche, 3); XCTAssertEqual(c.treffer, false); XCTAssertFalse(c.darfWerfen)
    }
    func testTrefferImZweitenVersuchGibtVolleZielPunkte() {
        var c = Chicago(spieler: 1)
        c.setzeWurf(5, 6); c.weiter()      // kein Treffer, Zug nicht beendet: weiter() tut nichts
        XCTAssertEqual(c.dran, 0); XCTAssertEqual(c.versuche, 1)
        c.setzeWurf(1, 1)
        XCTAssertEqual(c.punkte[0], 4)
    }
    func testNachDemSpielEndeIstKeinWurfMehrMoeglich() {
        var c = Chicago(spieler: 1)
        while !c.beendet { c.setzeWurf(1, 1); c.setzeWurf(1, 1); c.setzeWurf(1, 1); c.weiter() }
        let vorher = c.punkte
        c.setzeWurf(6, 6)
        XCTAssertEqual(c.punkte, vorher)
        XCTAssertFalse(c.darfWerfen)
    }
    func testTrefferChancenImMittelPassenZurTheorie() {
        // Chance auf die Zielzahl in drei Würfen: Summe 7 (p = 1/6) ist die häufigste, 2 und 12 (p = 1/36) die seltensten.
        var g = SeededGenerator(seed: 21)
        func quote(_ ziel: Int) -> Double {
            var treffer = 0
            for _ in 0..<6000 {
                var c = Chicago(spieler: 1)
                for _ in 0..<(ziel - 2) { c.setzeWurf(6, 6); c.setzeWurf(6, 6); c.setzeWurf(6, 6); c.weiter() }
                while c.darfWerfen { c.wuerfeln(mit: &g) }
                if c.treffer == true { treffer += 1 }
            }
            return Double(treffer) / 6000
        }
        let sieben = quote(7), zwei = quote(2)
        XCTAssertEqual(sieben, 1 - pow(5.0 / 6, 3), accuracy: 0.03)
        XCTAssertEqual(zwei, 1 - pow(35.0 / 36, 3), accuracy: 0.02)
        XCTAssertGreaterThan(sieben, zwei * 4)
    }
}

struct SeededGenerator: RandomNumberGenerator {
    var z: UInt64
    init(seed: UInt64) { z = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        z &+= 0x9E37_79B9_7F4A_7C15
        var x = z
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        return x ^ (x >> 31)
    }
}

/// 1.0 (P4): Chance auf die Zielzahl.
final class ChicagoChanceTests: XCTestCase {
    func testChanceProSumme() {
        XCTAssertEqual(Chicago.chance(summe: 7), 6.0 / 36, accuracy: 1e-9)
        XCTAssertEqual(Chicago.chance(summe: 2), 1.0 / 36, accuracy: 1e-9)
        XCTAssertEqual(Chicago.chance(summe: 12), 1.0 / 36, accuracy: 1e-9)
        XCTAssertEqual(Chicago.chance(summe: 1), 0)
        XCTAssertEqual(Chicago.chance(summe: 13), 0)
        let alle = (2...12).reduce(0.0) { $0 + Chicago.chance(summe: $1) }
        XCTAssertEqual(alle, 1, accuracy: 1e-9)
    }

    func testChanceNaechsterUndRestlicherWurf() {
        var c = Chicago(spieler: 1)                         // Ziel 2
        XCTAssertEqual(c.chanceNaechsterWurf, 1.0 / 36, accuracy: 1e-9)
        XCTAssertEqual(c.chanceRestlicheWuerfe, 1 - pow(35.0 / 36, 3), accuracy: 1e-9)
        c.setzeWurf(3, 4)                                   // verfehlt, noch zwei Versuche
        XCTAssertEqual(c.chanceRestlicheWuerfe, 1 - pow(35.0 / 36, 2), accuracy: 1e-9)
        c.setzeWurf(3, 4); c.setzeWurf(3, 4)                // Zug vorbei
        XCTAssertEqual(c.chanceNaechsterWurf, 0)
        XCTAssertEqual(c.chanceRestlicheWuerfe, 0)
    }

    func testComputerSpielerWuerfeltBisZumTreffer() {
        var c = Chicago(spieler: 2); var g = SeededGenerator(seed: 4)
        var schritte = 0
        while !c.beendet && schritte < 1000 {
            if c.darfWerfen { c.wuerfeln(mit: &g) } else { c.weiter() }
            schritte += 1
        }
        XCTAssertTrue(c.beendet)
    }

    // Blatt 22 (EB2, Schritt 2): Punkte je Zug, Treffer je Person, alter Stand
    func testRundenPunkteZaehlen() {
        var c = Chicago(spieler: 2)
        c.setzeWurf(1, 1); c.weiter()            // Spieler 0, Zielzahl 2: Pasch, 4 Punkte
        c.setzeWurf(6, 6); c.setzeWurf(6, 5); c.setzeWurf(4, 4); c.weiter()   // Spieler 1: dreimal verfehlt
        XCTAssertEqual(c.rundenPunkte?[0], [4]); XCTAssertEqual(c.rundenPunkte?[1], [0])
        XCTAssertEqual(c.trefferJePerson, [1, 0])
    }
    func testAlterStandLaedtOhneZaehlung() throws {
        var c = Chicago(spieler: 2)
        c.setzeWurf(1, 2)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(c)) as? [String: Any])
        json.removeValue(forKey: "rundenPunkte")
        var alt = try JSONDecoder().decode(Chicago.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(alt.rundenPunkte); XCTAssertNil(alt.trefferJePerson); XCTAssertTrue(alt.istStimmig)
        alt.setzeWurf(5, 5); alt.setzeWurf(1, 1)   // zählt nicht, stürzt nicht ab
        XCTAssertNil(alt.rundenPunkte)
    }
}
