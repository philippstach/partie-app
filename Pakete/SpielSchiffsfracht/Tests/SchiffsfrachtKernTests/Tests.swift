// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchiffsfrachtKern
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
final class SchiffsfrachtTests: XCTestCase {
    func testFestlegenInReihenfolge() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<500 {
            var s = Schiffsfracht(spieler: 2)
            while s.wuerfe < 3 { s.wuerfeln(mit: &g) }
            XCTAssertTrue(s.fest == [] || s.fest == [6] || s.fest == [6, 5] || s.fest == [6, 5, 4])
            XCTAssertTrue(s.fracht >= 0 && s.fracht <= 12)
        }
    }
    func testPartieMitComputer() {
        var g = SystemRandomNumberGenerator(); var s = Schiffsfracht(spieler: 3)
        while !s.vorbei {
            s.wuerfeln(mit: &g)
            while s.computerWillWeiter { s.wuerfeln(mit: &g) }
            s.fertig()
            if s.rundeGewertet { s.naechsteRunde() }
        }
        XCTAssertTrue(s.punkte.reduce(0, +) <= Schiffsfracht.runden * 3)
    }
    func testNullOhneMannschaft() {
        var g = SystemRandomNumberGenerator(); var s = Schiffsfracht(spieler: 2)
        s.wuerfeln(mit: &g); s.fertig()
        if !(s.ergebnisse[0] ?? 0 > 0) { XCTAssertEqual(s.ergebnisse[0], 0) }
    }
}

import SpieleKern

final class SchiffsfrachtRegelTests: XCTestCase {
    private func wurf(_ s: inout Schiffsfracht, _ augen: [Int]) {
        var z = EchteWuerfelZufall(); z.lade(augen: augen); s.wuerfeln(mit: &z)
    }

    func testSchiffKapitaenMannschaftWerdenInReihenfolgeFestgelegt() {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [4, 5, 6, 2, 3])
        XCTAssertEqual(s.fest, [6, 5, 4], "Alle drei in einem Wurf, auch bei umgekehrter Reihenfolge")
        XCTAssertTrue(s.mannschaftKomplett); XCTAssertEqual(s.fracht, 5); XCTAssertEqual(s.freieWuerfel.sorted(), [2, 3])
    }
    func testKapitaenOhneSchiffZaehltNicht() {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [5, 4, 1, 2, 3])
        XCTAssertTrue(s.fest.isEmpty); XCTAssertEqual(s.gesucht, 6)
    }
    func testFestgelegteWuerfelBleibenBeimNaechstenWurf() {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [6, 1, 1, 1, 1])
        XCTAssertEqual(s.fest, [6]); XCTAssertEqual(s.wuerfelAnzahl, 4)
        wurf(&s, [5, 4, 3, 2])
        XCTAssertEqual(s.fest, [6, 5, 4]); XCTAssertEqual(s.fracht, 5)
        XCTAssertEqual(s.wuerfe, 2)
    }
    func testMaximalDreiWuerfe() {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [1, 1, 1, 1, 1]); wurf(&s, [1, 1, 1, 1, 1]); wurf(&s, [1, 1, 1, 1, 1]); wurf(&s, [6, 6, 6, 6, 6])
        XCTAssertEqual(s.wuerfe, 3); XCTAssertTrue(s.fest.isEmpty)
    }
    func testFertigVorDemErstenWurfGehtNicht() {
        var s = Schiffsfracht(spieler: 2)
        s.fertig()
        XCTAssertEqual(s.amZug, 0); XCTAssertNil(s.ergebnisse[0])
    }
    func testRundeWertetHoehereFrachtUndGleichstandGibtBeidenPunkte() {
        var s = Schiffsfracht(spieler: 3)
        wurf(&s, [6, 5, 4, 6, 5]); s.fertig()                      // Fracht 11
        wurf(&s, [6, 5, 4, 1, 1]); s.fertig()                      // Fracht 2
        wurf(&s, [6, 5, 4, 6, 5]); s.fertig()                      // Fracht 11
        XCTAssertTrue(s.rundeGewertet); XCTAssertEqual(s.rundenSieger, [0, 2]); XCTAssertEqual(s.punkte, [1, 0, 1])
    }
    func testNiemandMitMannschaftGibtKeinenPunkt() {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [1, 1, 1, 1, 1]); s.fertig()
        wurf(&s, [2, 2, 2, 2, 2]); s.fertig()
        XCTAssertTrue(s.rundenSieger.isEmpty); XCTAssertEqual(s.punkte, [0, 0]); XCTAssertEqual(s.ergebnisse, [0, 0])
    }
    func testNaechsteRundeSetztDenZugZurueckUndSpielEndetNachFuenfRunden() {
        var s = Schiffsfracht(spieler: 2)
        for r in 0..<Schiffsfracht.runden {
            XCTAssertFalse(s.vorbei)
            wurf(&s, [6, 5, 4, 6, 6]); s.fertig(); wurf(&s, [6, 5, 4, 1, 1]); s.fertig()
            XCTAssertEqual(s.rundenSieger, [0])
            s.naechsteRunde()
            XCTAssertEqual(s.runde, r + 1); XCTAssertEqual(s.amZug, 0)
        }
        XCTAssertTrue(s.vorbei); XCTAssertEqual(s.punkte, [5, 0])
    }
    func testComputerWillWeiterNurSolangeEsSichLohnt() {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [6, 5, 4, 6, 6])           // Fracht 12
        XCTAssertFalse(s.computerWillWeiter)
        var t = Schiffsfracht(spieler: 2)
        wurf(&t, [6, 5, 4, 1, 1])           // Fracht 2
        XCTAssertTrue(t.computerWillWeiter)
    }
    func testLetzterHoertAufSobaldErDenBestenUeberbietet() {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [6, 5, 4, 3, 3]); s.fertig()           // Fracht 6
        wurf(&s, [6, 5, 4, 4, 3])                        // Fracht 7 > 6
        XCTAssertFalse(s.computerWillWeiter(stufe: 3))
    }
    func testLetzterWuerfeltWeiterSolangeErHinterherLiegt() {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [6, 5, 4, 6, 5]); s.fertig()           // Fracht 11
        wurf(&s, [6, 5, 4, 6, 3])                        // Fracht 9: leicht hört auf, schwer greift an
        XCTAssertFalse(s.computerWillWeiter(stufe: 1))
        XCTAssertTrue(s.computerWillWeiter(stufe: 3))
    }
    func testSchwerSchlaegtLeichtInSimulation() {
        var schwer = 0, leicht = 0
        var g = SeededGenerator(seed: 11)
        for partie in 0..<400 {
            var s = Schiffsfracht(spieler: 2)
            let schwerPlatz = partie % 2            // Sitzplatz wechselt, damit die Zugreihenfolge nichts verfälscht
            while !s.vorbei {
                for spieler in 0..<2 {
                    let stufe = spieler == schwerPlatz ? 3 : 1
                    s.wuerfeln(mit: &g)
                    while s.computerWillWeiter(stufe: stufe) { s.wuerfeln(mit: &g) }
                    s.fertig()
                }
                s.naechsteRunde()
            }
            schwer += s.punkte[schwerPlatz]; leicht += s.punkte[1 - schwerPlatz]
        }
        XCTAssertGreaterThan(schwer, leicht)
    }
    func testSpielstandIstCodierbar() throws {
        var s = Schiffsfracht(spieler: 2)
        wurf(&s, [6, 1, 2, 3, 4])
        let neu = try JSONDecoder().decode(Schiffsfracht.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu.fest, s.fest); XCTAssertEqual(neu.wuerfe, s.wuerfe); XCTAssertEqual(neu.punkte, s.punkte)
    }
}
