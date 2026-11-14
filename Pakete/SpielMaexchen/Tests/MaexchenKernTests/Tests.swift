// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MaexchenKern

final class MaexchenTests: XCTestCase {
    func testRangfolge() {
        XCTAssertEqual(MaexchenWert.alle.count, 21)
        XCTAssertTrue(MaexchenWert.rang(2, 1) > MaexchenWert.rang(6, 6))
        XCTAssertTrue(MaexchenWert.rang(1, 1) > MaexchenWert.rang(6, 5))
        XCTAssertEqual(MaexchenWert.rang(3, 5), 53); XCTAssertTrue(MaexchenWert.rang(6, 5) > MaexchenWert.rang(6, 4))
    }
    func testAblauf() {
        var m = Maexchen(spieler: 3); var g = SystemRandomNumberGenerator()
        m.wuerfeln(mit: &g); XCTAssertEqual(m.phase, .ansagen)
        XCTAssertFalse(m.ansagen(0)); XCTAssertTrue(m.ansagen(m.moeglicheAnsagen[3]))
        XCTAssertEqual(m.dran, 1); XCTAssertEqual(m.phase, .entscheiden)
        m.zweifeln(); XCTAssertNotNil(m.verlierer); XCTAssertEqual(m.leben.reduce(0, +), 8); XCTAssertEqual(m.phase, .wuerfeln)
    }
    func testZweifelEhrlich() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(6, 5); XCTAssertTrue(m.ansagen(MaexchenWert.rang(6, 5)))
        m.zweifeln(); XCTAssertEqual(m.verlierer, 1)        // Ansager war ehrlich → Zweifler verliert
        m.setzeWurf(3, 1); m.ansagen(MaexchenWert.rang(6, 6))
        m.zweifeln(); XCTAssertEqual(m.verlierer, 1)   // Spieler 1 hat gelogen
    }
    func testWahrscheinlichkeit() {
        XCTAssertEqual(MaexchenComputer.wahrscheinlichkeit(mindestens: 0), 1)
        XCTAssertEqual(MaexchenComputer.wahrscheinlichkeit(mindestens: 200), 2.0 / 36)
        XCTAssertEqual(MaexchenComputer.wahrscheinlichkeit(mindestens: 106), 3.0 / 36)   // Pasch 6 und Mäxchen
    }
    func testAlleStufenSpielenZuEnde() {
        for stufe in 1...3 {
            for _ in 0..<40 {
                var m = Maexchen(spieler: 3); var g = SystemRandomNumberGenerator(); var n = 0
                while m.sieger == nil && n < 5000 {
                    n += 1
                    switch m.phase {
                    case .wuerfeln: m.wuerfeln(mit: &g)
                    case .ansagen:
                        if m.moeglicheAnsagen.isEmpty { m.zweifeln(); continue }
                        m.ansagen(MaexchenComputer.ansage(m, stufe: stufe, mit: &g))
                    case .entscheiden: if MaexchenComputer.zweifelt(m, stufe: stufe, mit: &g) { m.zweifeln() } else { m.glauben() }
                    }
                }
                XCTAssertNotNil(m.sieger)
            }
        }
    }
    func testSpielEnde() {
        var m = Maexchen(spieler: 3); var g = SystemRandomNumberGenerator(); var n = 0
        while m.sieger == nil && n < 2000 {
            switch m.phase {
            case .wuerfeln: m.wuerfeln(mit: &g)
            case .ansagen: m.ansagen(MaexchenComputer.ansage(m, mit: &g))
            case .entscheiden: if MaexchenComputer.zweifelt(m, mit: &g) { m.zweifeln() } else { m.glauben() }
            }
            n += 1
            if m.phase == .ansagen && m.moeglicheAnsagen.isEmpty { break }
        }
        XCTAssertNotNil(m.sieger)
    }

    /// Spieler 0 spielt Stufe `a`, Spieler 1 Stufe `b`; Rückgabe: Anteil der Partien, die Spieler 0 gewinnt.
    private func quote(_ a: Int, _ b: Int, partien: Int) -> Double {
        var siege = 0
        for _ in 0..<partien {
            var m = Maexchen(spieler: 2); var g = SystemRandomNumberGenerator(); var n = 0
            while m.sieger == nil && n < 5000 {
                n += 1
                let stufe = m.dran == 0 ? a : b
                switch m.phase {
                case .wuerfeln: m.wuerfeln(mit: &g)
                case .ansagen:
                    if m.moeglicheAnsagen.isEmpty { m.zweifeln(); continue }
                    m.ansagen(MaexchenComputer.ansage(m, stufe: stufe, mit: &g))
                case .entscheiden: if MaexchenComputer.zweifelt(m, stufe: m.dran == 0 ? a : b, mit: &g) { m.zweifeln() } else { m.glauben() }
                }
            }
            if m.sieger == 0 { siege += 1 }
        }
        return Double(siege) / Double(partien)
    }
    /// Der Anfangsvorteil ist durch vertauschte Rollen herausgerechnet.
    func testSchwerSchlaegtLeicht() {
        let a = quote(3, 1, partien: 1500), b = quote(1, 3, partien: 1500)
        XCTAssertGreaterThan(a, b + 0.1, "schwer auf Platz 0: \(a), leicht auf Platz 0: \(b)")
    }
    func testMittelSchlaegtLeicht() {
        let a = quote(2, 1, partien: 1500), b = quote(1, 2, partien: 1500)
        XCTAssertGreaterThan(a, b + 0.05, "mittel auf Platz 0: \(a), leicht auf Platz 0: \(b)")
    }
    func testSchwerNichtSchlechterAlsMittel() {
        let a = quote(3, 2, partien: 1500), b = quote(2, 3, partien: 1500)
        XCTAssertGreaterThan(a, b - 0.02, "schwer auf Platz 0: \(a), mittel auf Platz 0: \(b)")
    }
}

final class MaexchenTippTests: XCTestCase {
    func testWahrscheinlichkeitSinktMitDerAnsage() {
        let alle = MaexchenWert.alle.sorted()
        var vorher = 2.0
        for r in alle { let p = MaexchenComputer.wahrscheinlichkeit(mindestens: r); XCTAssertTrue((0...1).contains(p)); XCTAssertLessThanOrEqual(p, vorher + 1e-9); vorher = p }
        XCTAssertEqual(MaexchenComputer.wahrscheinlichkeit(mindestens: 200), 2.0 / 36, accuracy: 1e-9)   // 2 und 1 in beiden Reihenfolgen
    }
}

final class MaexchenRegelTests: XCTestCase {
    func testRangfolge() {
        XCTAssertLessThan(MaexchenWert.rang(3, 1), MaexchenWert.rang(6, 5))
        XCTAssertLessThan(MaexchenWert.rang(6, 5), MaexchenWert.rang(1, 1))
        XCTAssertLessThan(MaexchenWert.rang(6, 6), MaexchenWert.rang(2, 1))
        XCTAssertEqual(MaexchenWert.rang(1, 2), MaexchenWert.rang(2, 1))
        XCTAssertEqual(MaexchenWert.alle.count, 21)
    }
    func testAnsageMussHoeherSein() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(4, 3)
        XCTAssertTrue(m.ansagen(43))
        m.glauben(); m.setzeWurf(6, 5)
        XCTAssertFalse(m.ansagen(43)); XCTAssertFalse(m.ansagen(42)); XCTAssertTrue(m.ansagen(44) == false); XCTAssertTrue(m.ansagen(51))
    }
    func testEhrlicheAnsageKostetDenZweiflerEinLeben() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(6, 5); m.ansagen(65)
        m.zweifeln()
        XCTAssertEqual(m.leben, [3, 2]); XCTAssertEqual(m.verlierer, 1); XCTAssertEqual(m.aufgedeckteLuegen, [0, 0])
    }
    func testGelogeneAnsageKostetDenLuegnerEinLeben() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(3, 1); m.ansagen(65)
        m.zweifeln()
        XCTAssertEqual(m.leben, [2, 3]); XCTAssertEqual(m.verlierer, 0); XCTAssertEqual(m.aufgedeckteLuegen, [1, 0]); XCTAssertEqual(m.aufgedeckteAnsagen, [1, 0])
    }
    func testGleicheAnsageWieWurfIstEhrlich() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(4, 4); m.ansagen(MaexchenWert.rang(4, 4))
        m.zweifeln()
        XCTAssertEqual(m.verlierer, 1)
    }
    func testMaexchenEhrlichKostetZweiLeben() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(2, 1); m.ansagen(200)
        m.zweifeln()
        XCTAssertEqual(m.leben, [3, 1])
    }
    func testAufMaexchenMussAufgedecktWerden() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(1, 2); m.ansagen(200)
        m.glauben()
        XCTAssertNotNil(m.verlierer, "Glauben auf Mäxchen deckt auf")
    }
    func testGlaubenLaesstDenNaechstenWuerfeln() {
        var m = Maexchen(spieler: 3)
        m.setzeWurf(4, 3); m.ansagen(43); m.glauben()
        XCTAssertEqual(m.phase, .wuerfeln); XCTAssertEqual(m.dran, 1); XCTAssertNil(m.wurf)
        XCTAssertEqual(m.ansage, 43, "Die letzte Ansage gilt weiter")
    }
    func testWerKeinLebenMehrHatScheidetAusUndEinerGewinnt() {
        var m = Maexchen(spieler: 2, leben: 1)
        m.setzeWurf(3, 1); m.ansagen(65); m.zweifeln()
        XCTAssertEqual(m.sieger, 1); XCTAssertEqual(m.aktive, [1])
    }
    func testAusgeschiedenerWirdUebersprungen() {
        var m = Maexchen(spieler: 3, leben: 1)
        m.setzeWurf(3, 1); m.ansagen(65); m.zweifeln()     // Spieler 0 lügt und scheidet aus
        XCTAssertEqual(m.aktive, [1, 2]); XCTAssertEqual(m.dran, 1)
    }
    func testUngueltigeEingabenAendernNichts() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(0, 7); XCTAssertEqual(m.phase, .wuerfeln)
        XCTAssertFalse(m.ansagen(65), "Erst würfeln")
        m.glauben(); m.zweifeln()
        XCTAssertEqual(m.phase, .wuerfeln); XCTAssertEqual(m.leben, [3, 3])
    }
    func testTextDerAnsagen() {
        XCTAssertEqual(MaexchenWert.text(200), "Mäxchen"); XCTAssertEqual(MaexchenWert.text(133), "Pasch 33"); XCTAssertEqual(MaexchenWert.text(64), "64")
    }
    func testSpielstandMitVerdecktemWurfIstCodierbar() throws {
        var m = Maexchen(spieler: 3)
        m.setzeWurf(5, 2); m.ansagen(52)
        let neu = try JSONDecoder().decode(Maexchen.self, from: JSONEncoder().encode(m))
        XCTAssertEqual(neu.ansage, 52); XCTAssertEqual(neu.dran, m.dran); XCTAssertEqual(neu.wurf?.0, 5); XCTAssertEqual(neu.leben, m.leben)
    }
}

final class MaexchenKonsistenzTests: XCTestCase {
    func testAlleVerliererTeilenSichPlatzZwei() {
        let e = Maexchen.schlussstand(sieger: 2, spieler: 4)
        XCTAssertEqual(e.reihenfolge, [2, 0, 1, 3])
        XCTAssertEqual(e.plaetze, [1, 2, 2, 2])
        let zwei = Maexchen.schlussstand(sieger: 0, spieler: 2)
        XCTAssertEqual(zwei.reihenfolge, [0, 1]); XCTAssertEqual(zwei.plaetze, [1, 2])
    }
    func testComputerpartieBleibtStimmig() {
        var g = SystemRandomNumberGenerator()
        for spieler in 2...5 {
            var m = Maexchen(spieler: spieler, leben: 2); var n = 0
            XCTAssertTrue(m.istKonsistent)
            while m.sieger == nil, n < 3000 {
                n += 1
                switch m.phase {
                case .wuerfeln: m.wuerfeln(mit: &g)
                case .ansagen: m.ansagen(MaexchenComputer.ansage(m, stufe: 1 + n % 3, mit: &g))
                case .entscheiden: if MaexchenComputer.zweifelt(m, stufe: 1 + n % 3, mit: &g) { m.zweifeln() } else { m.glauben() }
                }
                XCTAssertTrue(m.istKonsistent, "nach Schritt \(n) mit \(spieler) Spielern")
            }
            XCTAssertNotNil(m.sieger)
        }
    }
    func testStandInDerEntscheidungUeberlebtSpeichernUndLaden() throws {
        var m = Maexchen(spieler: 3)
        m.setzeWurf(4, 2); XCTAssertTrue(m.ansagen(53))
        let geladen = try JSONDecoder().decode(Maexchen.self, from: JSONEncoder().encode(m))
        XCTAssertTrue(geladen.istKonsistent)
        XCTAssertEqual(geladen.ansage, 53); XCTAssertEqual(geladen.ansager, 0); XCTAssertEqual(geladen.wurfRang, 42)
    }
    func testKaputteStaendeWerdenErkannt() throws {
        var m = Maexchen(spieler: 3)
        m.setzeWurf(4, 2); m.ansagen(53)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(m)) as? [String: Any])
        func lade(_ j: [String: Any]) throws -> Maexchen { try JSONDecoder().decode(Maexchen.self, from: JSONSerialization.data(withJSONObject: j)) }
        XCTAssertTrue(try lade(json).istKonsistent)
        var a = json; a.removeValue(forKey: "ansager")
        XCTAssertFalse(try lade(a).istKonsistent, "Entscheidung ohne Ansager (früher Absturz durch erzwungenes Entpacken)")
        var b = json; b.removeValue(forKey: "ansage")
        XCTAssertFalse(try lade(b).istKonsistent, "Entscheidung ohne Ansage")
        var c = json; c["wurfAugen"] = [4]
        XCTAssertFalse(try lade(c).istKonsistent, "halber Wurf")
        var d = json; d["dran"] = 7
        XCTAssertFalse(try lade(d).istKonsistent, "Zeiger außerhalb")
        var e = json; e["leben"] = [0, 0, 0]
        XCTAssertFalse(try lade(e).istKonsistent, "niemand mehr im Spiel")
        var f = json; f["aufgedeckteLuegen"] = [0]
        XCTAssertFalse(try lade(f).istKonsistent, "Zähler passen nicht zur Spielerzahl")
        var h = json; h["ansage"] = 77
        XCTAssertFalse(try lade(h).istKonsistent, "Ansage, die es nicht gibt")
    }

    // Blatt 22 (EB2, Schritt 2): Würfelzählung und Mäxchen-Zähler
    func testWuerfelZaehlung() {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(2, 1)
        XCTAssertEqual(m.augen?[0], [1, 1, 0, 0, 0, 0]); XCTAssertEqual(m.eingetippt, [2, 0]); XCTAssertEqual(m.maexchenWuerfe, 1)
        var a = Maexchen(spieler: 2); var g = SystemRandomNumberGenerator()
        a.wuerfeln(mit: &g)
        XCTAssertEqual(a.augen?[0].reduce(0, +), 2); XCTAssertEqual(a.eingetippt, [0, 0])
    }
    func testAlterStandLaedtOhneZaehlung() throws {
        var m = Maexchen(spieler: 2)
        m.setzeWurf(6, 5)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(m)) as? [String: Any])
        for k in ["augen", "eingetippt", "maexchenWuerfe"] { json.removeValue(forKey: k) }
        var alt = try JSONDecoder().decode(Maexchen.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(alt.augen); XCTAssertNil(alt.eingetippt); XCTAssertNil(alt.maexchenWuerfe)
        XCTAssertTrue(alt.istKonsistent)
        alt.ansagen(MaexchenWert.rang(6, 5)); alt.zweifeln()
        alt.setzeWurf(2, 1)   // zählt nicht, stürzt nicht ab
        XCTAssertNil(alt.augen)
    }
}
