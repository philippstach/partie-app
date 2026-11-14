// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import StadtLandFlussKern

final class SLFTests: XCTestCase {
    func testPlausibel() {
        XCTAssertTrue(StadtLandFlussWertung.plausibel("  berlin", buchstabe: "B")); XCTAssertTrue(StadtLandFlussWertung.plausibel("Österreich", buchstabe: "O"))
        XCTAssertFalse(StadtLandFlussWertung.plausibel("Rom", buchstabe: "B")); XCTAssertFalse(StadtLandFlussWertung.plausibel("", buchstabe: "B"))
    }
    func testPunkte() {
        let a = [["Berlin", "Belgien", "Bug"], ["Bonn", "belgien", ""], ["Bremen", "Bulgarien", ""]]
        let g = Array(repeating: [true, true, true], count: 3)
        // Stadt: alle verschieden → 10; Land: Belgien doppelt → 5/5, Bulgarien 10; Fluss: nur Spieler 0 → 20
        XCTAssertEqual(StadtLandFlussWertung.punkte(antworten: a, gueltig: g, buchstabe: "B"), [10 + 5 + 20, 10 + 5, 10 + 10])
        var g2 = g; g2[0][0] = false
        XCTAssertEqual(StadtLandFlussWertung.punkte(antworten: a, gueltig: g2, buchstabe: "B")[0], 5 + 20)
    }
    func testLeereUndLeerzeichenAntwortenGebenNichts() {
        let a = [["", "   ", "Bach"], ["Bonn", "", ""]]
        let g = Array(repeating: [true, true, true], count: 2)
        XCTAssertEqual(StadtLandFlussWertung.punkte(antworten: a, gueltig: g, buchstabe: "B"), [20, 20])
    }
    func testFalscherBuchstabeZaehltNichtUndBlockiertNicht() {
        let a = [["Rom", "x"], ["Bonn", "y"]]
        let g = Array(repeating: [true, true], count: 2)
        XCTAssertEqual(StadtLandFlussWertung.punkte(antworten: a, gueltig: g, buchstabe: "B"), [0, 20], "falsche Antwort wird nicht gewertet, der Einzige bekommt 20")
    }
    func testGleicheAntwortOhneGrossKleinUndAkzent() {
        let a = [["Öl"], ["ol"], ["OEL"]]
        let g = Array(repeating: [true], count: 3)
        let p = StadtLandFlussWertung.punkte(antworten: a, gueltig: g, buchstabe: "O")
        XCTAssertEqual(p[0], 5); XCTAssertEqual(p[1], 5)
    }
    func testGestrichenEinziger() {
        let a = [["Berlin"], ["Berlin"]]
        let p = StadtLandFlussWertung.punkte(antworten: a, gueltig: [[true], [false]], buchstabe: "B")
        XCTAssertEqual(p, [20, 0])
    }
    func testKeineSpieler() { XCTAssertEqual(StadtLandFlussWertung.punkte(antworten: [], gueltig: [], buchstabe: "A"), []) }

    func testUmlautBuchstabeUndEszett() {
        XCTAssertTrue(StadtLandFlussWertung.plausibel("Äpfel", buchstabe: "A"))
        XCTAssertTrue(StadtLandFlussWertung.plausibel("ärztin", buchstabe: "A"))
        XCTAssertFalse(StadtLandFlussWertung.plausibel("Bär", buchstabe: "A"))
    }
    func testPunkteSummeIstNieNegativUndOftAlleinig() {
        let a = [["Berlin", "Belgien"], ["Berlin", "Brasilien"], ["Bonn", "Belgien"]]
        let g = Array(repeating: [true, true], count: 3)
        let p = StadtLandFlussWertung.punkte(antworten: a, gueltig: g, buchstabe: "B")
        XCTAssertEqual(p, [5 + 5, 5 + 10, 10 + 5])
        XCTAssertTrue(p.allSatisfy { $0 >= 0 })
    }
    func testAlleKategorienUndBuchstabenSindBrauchbar() {
        XCTAssertEqual(StadtLandFlussWertung.kategorien.count, 6)
        XCTAssertEqual(Set(StadtLandFlussWertung.buchstaben).count, StadtLandFlussWertung.buchstaben.count)
        XCTAssertFalse(StadtLandFlussWertung.buchstaben.contains("Q") || StadtLandFlussWertung.buchstaben.contains("X"))
    }
    func testKategorienAuswahl() {
        XCTAssertEqual(StadtLandFlussWertung.auswahl(gespeichert: nil), StadtLandFlussWertung.kategorien)
        XCTAssertEqual(StadtLandFlussWertung.auswahl(gespeichert: ["Marke", "Stadt", "Fluss"]), ["Stadt", "Fluss", "Marke"])
        XCTAssertEqual(StadtLandFlussWertung.auswahl(gespeichert: ["Stadt"]), StadtLandFlussWertung.kategorien)
    }
}

final class StadtLandFlussNormierenTests: XCTestCase {
    func testEszettGleichSS() {
        XCTAssertEqual(StadtLandFlussWertung.normiert("Straße"), StadtLandFlussWertung.normiert("strasse"))
    }
    func testBindestrichUndPunktWieLeerzeichen() {
        XCTAssertEqual(StadtLandFlussWertung.normiert("Sankt-Gallen"), StadtLandFlussWertung.normiert("sankt gallen"))
        XCTAssertEqual(StadtLandFlussWertung.normiert("St. Gallen"), StadtLandFlussWertung.normiert("st gallen"))
    }
    func testMehrfachLeerzeichenUndRaender() {
        XCTAssertEqual(StadtLandFlussWertung.normiert("  Rio   de  Janeiro "), "rio de janeiro")
    }
    func testGleicheAntwortMitEszettTeiltPunkte() {
        let p = StadtLandFlussWertung.punkte(antworten: [["Strasse"], ["Straße"]], gueltig: [[true], [true]], buchstabe: "S")
        XCTAssertEqual(p, [5, 5])
    }
    func testAkzentBuchstabe() {
        XCTAssertTrue(StadtLandFlussWertung.plausibel("Österreich", buchstabe: "O"))
        XCTAssertTrue(StadtLandFlussWertung.plausibel("Ägypten", buchstabe: "A"))
    }
    func testDreiSpielerGemischt() {
        let p = StadtLandFlussWertung.punkte(antworten: [["Hamburg", "Hund"], ["hamburg", "Hase"], ["Halle", ""]], gueltig: Array(repeating: [true, true], count: 3), buchstabe: "H")
        XCTAssertEqual(p, [5 + 10, 5 + 10, 10 + 0])
    }
    func testUngueltigeAntwortGibtNichtsUndTeiltNicht() {
        let p = StadtLandFlussWertung.punkte(antworten: [["Hamburg"], ["Hamburg"]], gueltig: [[true], [false]], buchstabe: "H")
        XCTAssertEqual(p, [20, 0])
    }
}
