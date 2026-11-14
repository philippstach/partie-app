// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

final class GameCenterRegelnTests: XCTestCase {
    private let ich = UUID()

    private func einzel(_ spiel: String, platz: Int, dauer: TimeInterval = 0, punkte: Int? = nil, id: UUID? = nil) -> PartieErgebnis {
        PartieErgebnis(spiel: spiel, dauer: dauer, teilnehmer: [.init(spielerID: id, name: "Ich", platz: platz, punkte: punkte)])
    }

    func testBestenlistenKennungenSindEindeutig() {
        let ids = GameCenterRegeln.bestenlisten.map(\.id) + GameCenterRegeln.erfolge.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(Set(GameCenterRegeln.bestenlisten.flatMap(\.spiele)).count, GameCenterRegeln.bestenlisten.flatMap(\.spiele).count)
    }

    func testErfolgspunktesummeBleibtUnterApplesGrenze() {
        XCTAssertLessThanOrEqual(GameCenterRegeln.erfolge.map(\.punkte).reduce(0, +), 1000)
        XCTAssertTrue(GameCenterRegeln.erfolge.allSatisfy { (1...100).contains($0.punkte) })
    }

    func testGewonnenesRaetselMeldetZeit() {
        let m = GameCenterRegeln.meldung(fuer: einzel("sudoku-neu", platz: 1, dauer: 312.4), ich: nil)
        XCTAssertEqual(m, .init(bestenliste: "partie.zeit.sudoku", wert: 312))
    }

    func testVerlorenesOderZuKurzesRaetselMeldetNichts() {
        XCTAssertNil(GameCenterRegeln.meldung(fuer: einzel("minensuche", platz: 2, dauer: 90), ich: nil))
        XCTAssertNil(GameCenterRegeln.meldung(fuer: einzel("minensuche", platz: 1, dauer: 2), ich: nil))
    }

    func testPunktespielMeldetPunkteVonIch() {
        let e = PartieErgebnis(spiel: "yacht", teilnehmer: [.init(spielerID: UUID(), name: "Ben", platz: 1, punkte: 240), .init(spielerID: ich, name: "Ich", platz: 2, punkte: 198)])
        XCTAssertEqual(GameCenterRegeln.meldung(fuer: e, ich: ich), .init(bestenliste: "partie.punkte.yacht", wert: 198))
        XCTAssertNil(GameCenterRegeln.meldung(fuer: e, ich: nil))   // mehrere Personen, keiner ist „Ich“: nichts melden
    }

    func testPunktespielAlleinOhneZuordnung() {
        XCTAssertEqual(GameCenterRegeln.meldung(fuer: einzel("10k-neu", platz: 0, punkte: 10250), ich: ich)?.wert, 10250)
    }

    func testSpielOhneListeMeldetNichts() {
        XCTAssertNil(GameCenterRegeln.meldung(fuer: einzel("schach", platz: 1, dauer: 400), ich: nil))
    }

    private let angaben: (String) -> GameCenterRegeln.Spielangaben = {
        switch $0 {
        case "sudoku": .init(gattung: "raetsel", land: "Japan")
        case "mogeln": .init(gattung: "karten", land: "USA")
        case "yacht": .init(gattung: "wuerfel", land: "Kanada")
        case "viererreihe": .init(gattung: "brett", land: "USA")
        case "galgen": .init(gattung: "wort", land: "England")
        default: .init(gattung: nil, land: nil)
        }
    }

    func testFortschrittLeer() {
        let f = GameCenterRegeln.fortschritt(ereignisse: [], ich: nil, tagesSerie: 0, angaben: angaben)
        XCTAssertEqual(f.count, GameCenterRegeln.erfolge.count)
        XCTAssertTrue(f.values.allSatisfy { $0 == 0 })
    }

    func testFortschrittArtenUndLaender() {
        let e = ["sudoku", "mogeln", "yacht", "viererreihe", "galgen"].map { einzel($0, platz: 1) }
        let f = GameCenterRegeln.fortschritt(ereignisse: e, ich: nil, tagesSerie: 3, angaben: angaben)
        XCTAssertEqual(f["partie.erfolg.alleArten"], 100)
        XCTAssertEqual(f["partie.erfolg.weltreise"], 80)      // USA zählt einmal: 4 von 5 Ländern
        XCTAssertEqual(f["partie.erfolg.zehnSpiele"], 50)
        XCTAssertEqual(f["partie.erfolg.erstePartie"], 100)
        XCTAssertEqual(f["partie.erfolg.tagesSerie"]!, 3.0 / 7.0 * 100, accuracy: 0.001)
    }

    func testPartienAndererZaehlenNichtFuerIch() {
        let fremd = PartieErgebnis(spiel: "yacht", teilnehmer: [.init(spielerID: UUID(), name: "Ben", platz: 1), .init(spielerID: UUID(), name: "Cem", platz: 2)])
        let f = GameCenterRegeln.fortschritt(ereignisse: [fremd], ich: ich, tagesSerie: 0, angaben: angaben)
        XCTAssertEqual(f["partie.erfolg.erstePartie"], 0)
    }

    func testRemisUndAbbruchGebenKeinenSieg() {
        let remis = PartieErgebnis(spiel: "viererreihe", teilnehmer: [.init(spielerID: ich, name: "A", platz: 1), .init(spielerID: UUID(), name: "B", platz: 1)])
        let abbruch = PartieErgebnis(spiel: "viererreihe", teilnehmer: [.init(spielerID: ich, name: "A", platz: 2), .init(name: "Computer", platz: 1)])
        let gemeinsamAbgebrochen = PartieErgebnis(spiel: "viererreihe", teilnehmer: [.init(spielerID: ich, name: "A", platz: 2), .init(spielerID: UUID(), name: "B", platz: 2)])
        let f = GameCenterRegeln.fortschritt(ereignisse: [remis, abbruch, gemeinsamAbgebrochen], ich: ich, tagesSerie: 0, angaben: angaben)
        XCTAssertEqual(f["partie.erfolg.ersterSieg"], 0)
        XCTAssertEqual(f["partie.erfolg.erstePartie"], 100)
        XCTAssertEqual(f["partie.erfolg.fuenfzigPartien"], 4)   // Remis und Niederlage zählen, die gemeinsam abgebrochene Partie nicht
    }

    func testSpielerrundeBraucht3Teilnehmer() {
        let drei = PartieErgebnis(spiel: "yacht", teilnehmer: (1...3).map { .init(spielerID: $0 == 1 ? ich : UUID(), name: "S\($0)", platz: $0) })
        XCTAssertEqual(GameCenterRegeln.fortschritt(ereignisse: [drei], ich: ich, tagesSerie: 0, angaben: angaben)["partie.erfolg.spielerrunde"], 100)
    }
}
