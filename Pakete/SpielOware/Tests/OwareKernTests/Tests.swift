// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import OwareKern

final class OwareTests: XCTestCase {
    func testAnfang() {
        let o = Oware()
        XCTAssertEqual(o.mulden.reduce(0, +), 48)
        XCTAssertEqual(o.zuege, [0, 1, 2, 3, 4, 5])
    }
    func testSaeen() {
        var o = Oware()
        XCTAssertEqual(o.spiele(2), 0)
        XCTAssertEqual(Array(o.mulden[0...7]), [4, 4, 0, 5, 5, 5, 5, 4])
        XCTAssertEqual(o.amZug, 1)
    }
    func testErbeuten() {
        var o = Oware(mulden: [0, 0, 0, 0, 0, 1, 1, 5, 5, 5, 5, 5])
        XCTAssertEqual(o.spiele(5), 2)          // Mulde 6: 1 → 2, erbeutet
    }
    func testErbeutenMitKette() {
        var o = Oware(mulden: [0, 0, 0, 0, 0, 2, 1, 1, 5, 5, 5, 5])
        XCTAssertEqual(o.spiele(5), 4)          // 7 → 2 und rückwärts 6 → 2
    }
    func testKetteRueckwaerts() {
        var o = Oware(mulden: [0, 0, 0, 0, 0, 3, 1, 1, 1, 5, 5, 5])
        XCTAssertEqual(o.spiele(5), 6)          // 6→2, 7→2, 8→2: 2+2+2 = 6
        XCTAssertEqual(o.vorrat[0], 6)
    }
    func testGrandSlamGibtNichts() {
        var o = Oware(mulden: [0, 0, 0, 0, 0, 3, 1, 1, 1, 0, 0, 0])
        XCTAssertEqual(o.spiele(5), 0)
        XCTAssertEqual(o.vorrat[0], 0)
    }
    func testGegnerLeerMussBedienen() {
        let o = Oware(mulden: [1, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(o.zuege, [5])
    }
    func testEndlosspielWirdBeendet() {
        var o = Oware(mulden: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertTrue(o.vorbei)
        o = Oware(mulden: [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])
        XCTAssertFalse(o.vorbei)
    }
    func testComputerPartienEnden() {
        for stufe in [1, 3] {
            for _ in 0..<20 {
                var o = Oware(); var n = 0
                while !o.vorbei && n < 500 { XCTAssertNotNil(o.spiele(OwareComputer.wahl(o, tiefe: stufe)!)); n += 1 }
                XCTAssertTrue(o.vorbei)
                XCTAssertEqual(o.vorrat[0] + o.vorrat[1] + o.mulden.reduce(0, +), 48)
            }
        }
    }
}

final class OwareRegelnTests: XCTestCase {
    func testZiel() { XCTAssertEqual(OwareRegeln.kurz.ziel, 19); XCTAssertEqual(OwareRegeln.standard.ziel, 25); XCTAssertEqual(OwareRegeln.lang.ziel, 31) }
    func testVariantenSpielenBisEnde() {
        for r in [OwareRegeln.kurz, .lang, .grand] {
            var o = Oware(regeln: r); var n = 0
            XCTAssertEqual(o.mulden.reduce(0, +), r.samen * 12)
            while !o.vorbei, n < 1000, let z = o.zuege.randomElement() { o.spiele(z); n += 1 }
            XCTAssertTrue(o.vorbei)
            XCTAssertEqual(o.vorrat.reduce(0, +) + o.mulden.reduce(0, +), r.samen * 12)
        }
    }
    func testAlterSpielstandLaedt() throws {
        let json = #"{"mulden":[4,4,4,4,4,4,4,4,4,4,4,4],"vorrat":[0,0],"amZug":0,"vorbei":false}"#
        XCTAssertEqual(try JSONDecoder().decode(Oware.self, from: Data(json.utf8)).regeln, .standard)
    }
}

/// Stufen-Simulation: schwer (Tiefe 6) muss deutlich öfter gewinnen als leicht (Tiefe 1).
final class OwareStufenTests: XCTestCase {
    func testSchwerSchlaegtLeicht() {
        var schwer = 0, leicht = 0
        for i in 0..<10 {
            var o = Oware()
            for _ in 0..<2 where !o.vorbei { o.spiele(o.zuege.randomElement()!) }
            let seite = i % 2
            var n = 0
            while !o.vorbei && n < 400 {
                o.spiele(OwareComputer.wahl(o, tiefe: o.amZug == seite ? 6 : 1)!); n += 1
            }
            if let s = o.sieger { if s == seite { schwer += 1 } else { leicht += 1 } }
        }
        print("OWARE schwer \(schwer) leicht \(leicht) von 10")
        XCTAssertGreaterThanOrEqual(schwer, leicht + 4, "schwer \(schwer), leicht \(leicht)")
    }
}

final class OwareDetailTests: XCTestCase {
    func testSaeenUeberspringtStartmulde() {
        var o = Oware(mulden: [12, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1])
        o.spiele(0)
        XCTAssertEqual(o.mulden[0], 0)       // Startmulde bleibt leer, auch nach einer vollen Runde
        XCTAssertEqual(o.mulden.reduce(0, +) + o.vorrat.reduce(0, +), 18)
    }
    func testErbeutenNurBeiZweiOderDrei() {
        var o = Oware(mulden: [0, 0, 0, 0, 0, 1, 1, 4, 0, 0, 0, 0])
        XCTAssertEqual(o.spiele(5), 2)       // Mulde 6 wird 2 -> Beute 2
        XCTAssertEqual(o.vorrat[0], 2)
    }
    func testKeineBeuteImEigenenFeld() {
        var o = Oware(mulden: [1, 1, 0, 0, 0, 0, 4, 4, 4, 4, 4, 4])
        XCTAssertEqual(o.spiele(0), 0)
        XCTAssertEqual(o.vorrat, [0, 0])
    }
    func testGrandSlamMitRegelNimmtAlles() {
        var o = Oware(mulden: [0, 0, 0, 0, 0, 2, 1, 1, 0, 0, 0, 0])
        o = try! JSONDecoder().decode(Oware.self, from: JSONEncoder().encode(o))
        XCTAssertNotNil(o.spiele(5))
    }
    func testNachSpielendeKeinZug() {
        var o = Oware(); var n = 0
        while !o.vorbei && n < 500 { o.spiele(o.zuege.randomElement()!); n += 1 }
        XCTAssertTrue(o.vorbei); XCTAssertTrue(o.zuege.isEmpty); XCTAssertNil(o.spiele(0)); XCTAssertNil(OwareComputer.wahl(o, tiefe: 3))
    }
    func testSamenSummeBleibtErhalten() {
        var o = Oware(); var n = 0
        while !o.vorbei && n < 500 { o.spiele(o.zuege.randomElement()!); n += 1; XCTAssertEqual(o.mulden.reduce(0, +) + o.vorrat.reduce(0, +), 48) }
    }
    func testSiegerBeiZiel() {
        var o = Oware(mulden: [0, 0, 0, 0, 0, 2, 1, 1, 0, 0, 0, 0], vorrat: [24, 0])
        o.spiele(5)
        XCTAssertTrue(o.vorbei); XCTAssertEqual(o.sieger, 0)
    }
    func testComputerNimmtSofortigeBeute() {
        let o = Oware(mulden: [0, 0, 0, 0, 0, 1, 1, 4, 0, 4, 0, 4])
        XCTAssertEqual(OwareComputer.wahl(o, tiefe: 2), 5)
    }
    func testComputerSpieltImmerGueltig() {
        for tiefe in 1...5 {
            var o = Oware(); var n = 0
            while !o.vorbei && n < 400 { let m = OwareComputer.wahl(o, tiefe: tiefe)!; XCTAssertTrue(o.zuege.contains(m)); o.spiele(m); n += 1 }
        }
    }
    func testBedienenPflicht() {
        let o = Oware(mulden: [3, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(o.zuege, [5])       // nur der Zug, der dem leeren Gegner Samen gibt
        let ende = Oware(mulden: [3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0])
        XCTAssertTrue(ende.vorbei)         // niemand kann bedienen: Restsamen gehen an die Besitzer
        XCTAssertEqual(ende.vorrat, [4, 0])
    }
}
