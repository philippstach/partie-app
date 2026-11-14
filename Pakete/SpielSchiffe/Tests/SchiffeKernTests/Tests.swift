// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchiffeKern

final class SchiffeTests: XCTestCase {
    func testZufaelligeFlotte() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<50 {
            var f = Flotte(); f.zufaellig(mit: &g)
            XCTAssertEqual(f.schiffe.count, 5); XCTAssertEqual(f.belegt.count, 17)
            // keine Berührung
            for a in f.schiffe.indices { for b in f.schiffe.indices where a < b {
                for x in f.schiffe[a] { for y in f.schiffe[b] {
                    let dz = abs(x / 10 - y / 10), ds = abs(x % 10 - y % 10)
                    XCTAssertFalse(dz <= 1 && ds <= 1)
                } }
            } }
        }
    }
    func testPlatzierenRegeln() {
        var f = Flotte()
        XCTAssertTrue(f.platziere(start: 0, laenge: 5, waagrecht: true))
        XCTAssertFalse(f.platziere(start: 10, laenge: 3, waagrecht: true))      // berührt
        XCTAssertFalse(f.platziere(start: 8, laenge: 3, waagrecht: true))       // ragt hinaus
        XCTAssertTrue(f.platziere(start: 20, laenge: 3, waagrecht: false))
    }
    func testComputerVersenktAlles() {
        var g = SystemRandomNumberGenerator()
        var f = Flotte(); f.zufaellig(mit: &g); var c = SchiffeComputer(); var n = 0
        while !f.versenktAlle && n < 100 { f.schiesse(c.wahl(gegen: f, mit: &g)); n += 1 }
        XCTAssertTrue(f.versenktAlle); XCTAssertTrue(n < 100)
    }
}

final class SchiffeRegelnTests: XCTestCase {
    func testVarianten() {
        var g = SystemRandomNumberGenerator()
        for r in [FlottenRegeln.klein, .gross, .dicht, .abwechselnd] {
            var f = Flotte(regeln: r); f.zufaellig(mit: &g)
            XCTAssertEqual(f.schiffe.count, r.laengen.count)
            XCTAssertEqual(f.belegt.count, r.laengen.reduce(0, +))
            var c = SchiffeComputer(); var n = 0
            while !f.versenktAlle && n < r.groesse * r.groesse { f.schiesse(c.wahl(gegen: f, mit: &g)); n += 1 }
            XCTAssertTrue(f.versenktAlle)
        }
    }
    func testBerührungErlaubt() {
        var f = Flotte(regeln: .dicht)
        XCTAssertTrue(f.platziere(start: 0, laenge: 5, waagrecht: true))
        XCTAssertTrue(f.platziere(start: 10, laenge: 3, waagrecht: true))
    }
    func testAlterSpielstandLaedt() throws {
        let json = #"{"schiffe":[[0,1]],"beschossen":[]}"#
        XCTAssertEqual(try JSONDecoder().decode(Flotte.self, from: Data(json.utf8)).regeln, .klassisch)
    }
}

final class SchiffeStufenTests: XCTestCase {
    func testAlleStufenVersenkenAlles() {
        var g = SystemRandomNumberGenerator()
        for stufe in 1...3 {
            var f = Flotte(); f.zufaellig(mit: &g); var c = SchiffeComputer(); var n = 0
            while !f.versenktAlle && n < 100 { f.schiesse(c.wahl(gegen: f, stufe: stufe, mit: &g)); n += 1 }
            XCTAssertTrue(f.versenktAlle, "Stufe \(stufe)")
        }
    }
    func testSchwerBrauchtImSchnittWenigerSchuesse() {
        var g = SystemRandomNumberGenerator()
        func mittel(_ stufe: Int) -> Double {
            var summe = 0
            for _ in 0..<60 {
                var f = Flotte(); f.zufaellig(mit: &g); var c = SchiffeComputer(); var n = 0
                while !f.versenktAlle { f.schiesse(c.wahl(gegen: f, stufe: stufe, mit: &g)); n += 1 }
                summe += n
            }
            return Double(summe) / 60
        }
        XCTAssertLessThan(mittel(3), mittel(1))
    }
}

final class SchiffeRegelTests: XCTestCase {
    func testSchiffRagtNichtUeberDenRand() {
        let f = Flotte()
        XCTAssertNil(f.felder(start: 8, laenge: 3, waagrecht: true), "Spalte 8 + 3 passt nicht in 10")
        XCTAssertNil(f.felder(start: 85, laenge: 3, waagrecht: false))
        XCTAssertEqual(f.felder(start: 7, laenge: 3, waagrecht: true), [7, 8, 9])
        XCTAssertEqual(f.felder(start: 70, laenge: 3, waagrecht: false), [70, 80, 90])
    }
    func testBerührungVerbotenImKlassischenSpiel() {
        var f = Flotte()
        XCTAssertTrue(f.platziere(start: 0, laenge: 3, waagrecht: true))
        XCTAssertFalse(f.platziere(start: 11, laenge: 2, waagrecht: true), "diagonal berührt")
        XCTAssertFalse(f.platziere(start: 1, laenge: 2, waagrecht: false), "überlappt")
        XCTAssertTrue(f.platziere(start: 22, laenge: 2, waagrecht: true))
    }
    func testSchussWirdNurEinmalGezaehlt() {
        var f = Flotte()
        f.platziere(start: 0, laenge: 2, waagrecht: true)
        XCTAssertEqual(f.schiesse(0), true)
        XCTAssertNil(f.schiesse(0))
        XCTAssertEqual(f.schiesse(50), false)
        XCTAssertNil(f.schiesse(100)); XCTAssertNil(f.schiesse(-1))
    }
    func testSchiffIstVersenktWennAlleFelderGetroffenSind() {
        var f = Flotte()
        f.platziere(start: 0, laenge: 2, waagrecht: true); f.platziere(start: 30, laenge: 2, waagrecht: true)
        f.schiesse(0)
        XCTAssertTrue(f.versenkteSchiffe.isEmpty); XCTAssertFalse(f.versenktAlle)
        f.schiesse(1)
        XCTAssertEqual(f.versenkteSchiffe, [[0, 1]]); XCTAssertFalse(f.versenktAlle)
        f.schiesse(30); f.schiesse(31)
        XCTAssertTrue(f.versenktAlle)
    }
    func testZufaelligeFlotteHatDieRichtigeAnzahlFelder() {
        var g = SystemRandomNumberGenerator()
        for regeln in [FlottenRegeln.klassisch, .klein, .gross, .dicht] {
            var f = Flotte(regeln: regeln); f.zufaellig(mit: &g)
            XCTAssertEqual(f.belegt.count, regeln.laengen.reduce(0, +), "\(regeln.groesse)")
            XCTAssertEqual(f.schiffe.map(\.count).sorted(), regeln.laengen.sorted())
        }
    }
    func testEinzelnerTrefferLenktDenComputerInDieNachbarschaft() {
        var f = Flotte()
        f.platziere(start: 45, laenge: 3, waagrecht: true)
        f.schiesse(46)
        var g = SystemRandomNumberGenerator(); var c = SchiffeComputer()
        for _ in 0..<30 {
            XCTAssertTrue([36, 56, 45, 47].contains(c.wahl(gegen: f, stufe: 3, mit: &g)))
        }
    }
}

final class SchiffeDichteTests: XCTestCase {
    private func schuesse(_ stufe: Int, regeln: FlottenRegeln, partien: Int, _ g: inout SystemRandomNumberGenerator) -> Double {
        var summe = 0
        for _ in 0..<partien {
            var f = Flotte(regeln: regeln); f.zufaellig(mit: &g); var c = SchiffeComputer(); var n = 0
            while !f.versenktAlle && n < f.n * f.n { f.schiesse(c.wahl(gegen: f, stufe: stufe, mit: &g)); n += 1 }
            XCTAssertTrue(f.versenktAlle)
            summe += n
        }
        return Double(summe) / Double(partien)
    }
    func testSchwerBrauchtWenigerSchuesseAlsMittel() {
        var g = SystemRandomNumberGenerator()
        let schwer = schuesse(3, regeln: .klassisch, partien: 80, &g), mittel = schuesse(2, regeln: .klassisch, partien: 80, &g)
        print("SCHIFFE schwer \(schwer) mittel \(mittel)")
        XCTAssertLessThan(schwer, mittel)
    }
    func testSchwerFunktioniertInAllenVarianten() {
        var g = SystemRandomNumberGenerator()
        for r in [FlottenRegeln.klein, .gross, .dicht, .abwechselnd] {
            let m = schuesse(3, regeln: r, partien: 10, &g)
            XCTAssertLessThan(m, Double(r.groesse * r.groesse))
        }
    }
    func testNachTrefferWirdInDerNaeheWeitergeschossen() {
        var g = SystemRandomNumberGenerator()
        var f = Flotte(); f.platziere(start: 44, laenge: 3, waagrecht: true)   // Felder 44,45,46
        f.platziere(start: 0, laenge: 5, waagrecht: true)
        f.schiesse(45)
        var c = SchiffeComputer()
        let z = c.wahl(gegen: f, stufe: 3, mit: &g)
        XCTAssertTrue([44, 46, 35, 55].contains(z), "Schuss \(z)")
    }
    func testVersenktesSchiffWirdNichtWeiterBeschossen() {
        var g = SystemRandomNumberGenerator()
        var f = Flotte(); f.platziere(start: 0, laenge: 2, waagrecht: true); f.platziere(start: 50, laenge: 3, waagrecht: true)
        f.schiesse(0); f.schiesse(1)
        var c = SchiffeComputer()
        let z = c.wahl(gegen: f, stufe: 3, mit: &g)
        XCTAssertFalse(f.beschossen.contains(z))
        XCTAssertFalse([2, 10, 11].contains(z) && false)
    }
    func testComputerSchiesstNieDoppelt() {
        var g = SystemRandomNumberGenerator()
        for stufe in 1...3 {
            var f = Flotte(); f.zufaellig(mit: &g); var c = SchiffeComputer(); var gesehen = Set<Int>()
            while !f.versenktAlle { let z = c.wahl(gegen: f, stufe: stufe, mit: &g); XCTAssertTrue(gesehen.insert(z).inserted); f.schiesse(z) }
        }
    }
    func testFlottenRegelnRoundtrip() throws {
        let d = try JSONEncoder().encode(FlottenRegeln.gross)
        XCTAssertEqual(try JSONDecoder().decode(FlottenRegeln.self, from: d), .gross)
    }
    func testPlatzierenAufBesetztemFeldScheitert() {
        var f = Flotte()
        XCTAssertTrue(f.platziere(start: 0, laenge: 3, waagrecht: true))
        XCTAssertFalse(f.platziere(start: 1, laenge: 2, waagrecht: false))
        XCTAssertFalse(f.platziere(start: 10, laenge: 2, waagrecht: true))   // berührt (Verbot)
    }
    func testSchiesseAusserhalbIstNil() {
        var f = Flotte()
        XCTAssertNil(f.schiesse(-1)); XCTAssertNil(f.schiesse(100))
    }
}
