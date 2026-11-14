// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

final class ErgebnisTextTests: XCTestCase {
    func testMehrspielerNenntSiegerUndRangliste() {
        let t = ErgebnisText.text(spiel: "Yacht", reihenfolge: ["Anna", "Ben"], punkte: ["212", "190"])
        let z = t.components(separatedBy: "\n")
        XCTAssertEqual(z.first, "Yacht: Anna gewinnt")
        XCTAssertTrue(z.contains("1. Anna – 212"))
        XCTAssertTrue(z.contains("2. Ben – 190"))
        XCTAssertEqual(z.last, "Gespielt mit Partie")
    }

    func testGleichePlaetzeWerdenUebernommen() {
        let t = ErgebnisText.text(spiel: "Schocken", reihenfolge: ["A", "B", "C"], plaetze: [1, 1, 3])
        XCTAssertTrue(t.contains("1. A"))
        XCTAssertTrue(t.contains("1. B"))
        XCTAssertTrue(t.contains("3. C"))
        XCTAssertFalse(t.contains("–"))   // ohne Punkte kein Strich
    }

    func testEinfachNenntTitelUndUntertitel() {
        let t = ErgebnisText.einfach(spiel: "Viererreihe", titel: "Gewonnen!", untertitel: "4 Steine")
        XCTAssertEqual(t, "Viererreihe: Gewonnen! – 4 Steine\nGespielt mit Partie")
        XCTAssertEqual(ErgebnisText.einfach(spiel: "X", titel: "Remis"), "X: Remis\nGespielt mit Partie")
    }

    func testEinzelspielerGeschafft() {
        XCTAssertTrue(ErgebnisText.text(spiel: "Sudoku", reihenfolge: ["Anna"]).hasPrefix("Sudoku: Geschafft!"))
    }

    func testArcadePunkteUndRekord() {
        XCTAssertTrue(ErgebnisText.text(spiel: "Steinfall", reihenfolge: [], arcadePunkte: 42).hasPrefix("Steinfall: 42 Punkte"))
        XCTAssertTrue(ErgebnisText.text(spiel: "Steinfall", reihenfolge: [], arcadePunkte: 99, neuerRekord: true).hasPrefix("Steinfall: Neuer Rekord mit 99 Punkten!"))
    }

    func testArcadeDuell() {
        XCTAssertTrue(ErgebnisText.text(spiel: "Ballwechsel", reihenfolge: [], arcadePunkte: 5, arcadeSieg: true).hasPrefix("Ballwechsel: Gewonnen!"))
        XCTAssertTrue(ErgebnisText.text(spiel: "Ballwechsel", reihenfolge: [], arcadePunkte: 5, arcadeSieg: false).hasPrefix("Ballwechsel: Verloren"))
    }

    func testRemisNenntKeinenSieger() {
        let t = ErgebnisText.text(spiel: "Dame", reihenfolge: ["Anna", "Ben"], plaetze: [1, 1])
        let z = t.components(separatedBy: "\n")
        XCTAssertEqual(z.first, "Dame: Remis")
        XCTAssertFalse(t.contains("gewinnt"))
        XCTAssertTrue(z.contains("1. Anna")); XCTAssertTrue(z.contains("1. Ben"))
    }

    func testNurEinigeGleichaufVornBleibtSieg() {
        XCTAssertEqual(ErgebnisText.text(spiel: "Yacht", reihenfolge: ["Anna", "Ben", "Cem"], plaetze: [1, 1, 3]).components(separatedBy: "\n").first, "Yacht: Anna gewinnt")
        // Ohne Plätze gilt 1, 2, 3 …, nie Remis
        XCTAssertEqual(ErgebnisText.text(spiel: "Dame", reihenfolge: ["Anna", "Ben"]).components(separatedBy: "\n").first, "Dame: Anna gewinnt")
    }

    func testDieEineRemisRegel() {
        XCTAssertTrue(Remis.gilt(plaetze: [1, 1]))
        XCTAssertTrue(Remis.gilt(plaetze: [1, 1, 1]))
        XCTAssertFalse(Remis.gilt(plaetze: [1, 1, 3]))
        XCTAssertFalse(Remis.gilt(plaetze: [1]))          // Einzelspiel
        XCTAssertFalse(Remis.gilt(plaetze: [0]))          // Punktespiel
        XCTAssertFalse(Remis.gilt(plaetze: [2, 2]))       // gemeinsamer Abbruch
        XCTAssertFalse(Remis.gilt(plaetze: nil))
        XCTAssertFalse(Remis.gilt(plaetze: []))
        let e = PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "A", platz: 1), .init(name: "B", platz: 1)])
        XCTAssertEqual(e.istRemis, Remis.gilt(plaetze: [1, 1]))
    }
}
