// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// F1: Ein gescheitertes Kodieren (NaN, unendlich) darf die gespeicherten Daten nie löschen.
@MainActor
final class DatenverlustTests: XCTestCase {
    func testKodierenSchlaegtFehlDatenBleibenErhalten() {
        let ablage = SpeicherAblage(daten: Data("alt".utf8))
        XCTAssertFalse(Verlustfrei.schreiben([Double.nan], in: ablage), "NaN lässt sich nicht kodieren")
        XCTAssertEqual(ablage.daten, Data("alt".utf8), "die bisherigen Daten bleiben unberührt")
        XCTAssertTrue(Verlustfrei.schreiben([1.5], in: ablage))
        XCTAssertNotEqual(ablage.daten, Data("alt".utf8))
    }

    func testPartieMitNichtEndlichenZahlenWirdBereinigtVerbucht() {
        let ablage = SpeicherAblage()
        let st = StatistikDienst(ablage: ablage)
        st.melden(PartieErgebnis(spiel: "a", dauer: 30, teilnehmer: [.init(name: "A", platz: 1)]))
        let vorher = ablage.daten
        XCTAssertNotNil(vorher)
        st.melden(PartieErgebnis(spiel: "b", dauer: .nan, teilnehmer: [.init(name: "A", platz: 1)], kennzahlen: ["stufe": .infinity, "rallye": 12, "x": .nan]))
        XCTAssertEqual(st.ereignisse.count, 2)
        XCTAssertEqual(st.ereignisse[1].dauer, 0); XCTAssertEqual(st.ereignisse[1].kennzahlen, ["rallye": 12])
        // Neu aus der Ablage gelesen: beide Partien sind da, nichts wurde gelöscht
        XCTAssertEqual(StatistikDienst(ablage: ablage).ereignisse.count, 2)
    }

    func testNachtraeglichVerdorbenePartieLoeschtNichtsBeimMeldenUndUebernehmen() {
        let ablage = SpeicherAblage()
        let st = StatistikDienst(ablage: ablage)
        st.melden(PartieErgebnis(spiel: "a", teilnehmer: [.init(name: "A", platz: 1)]))
        var kaputt = PartieErgebnis(spiel: "b", teilnehmer: [.init(name: "A", platz: 2)])
        kaputt.dauer = -.infinity; kaputt.kennzahlen["stufe"] = .nan      // am Bereinigen im init vorbei
        st.melden(kaputt)
        var kaputt2 = PartieErgebnis(spiel: "c", teilnehmer: [.init(name: "A", platz: 2)]); kaputt2.dauer = .nan
        XCTAssertEqual(st.uebernehmen([kaputt2]), 1)
        let neu = StatistikDienst(ablage: ablage)
        XCTAssertEqual(neu.ereignisse.map(\.spiel).sorted(), ["a", "b", "c"])
        XCTAssertTrue(neu.ereignisse.allSatisfy { $0.dauer == 0 && $0.kennzahlen.isEmpty })
    }

    func testSpielerVerzeichnisSichertWeiterhin() {
        let ablage = SpeicherAblage()
        let v = SpielerVerzeichnis(ablage: ablage)
        v.anlegen(name: "Anna")
        XCTAssertNotNil(ablage.daten)
        XCTAssertEqual(SpielerVerzeichnis(ablage: ablage).menschen.map(\.name), ["Anna"])
    }

    func testKennzahlenOhneAbsturz() {
        XCTAssertEqual(Kennzahl.ganz(.nan, ersatz: 2), 2); XCTAssertEqual(Kennzahl.ganz(nil, ersatz: 2), 2)
        XCTAssertEqual(Kennzahl.ganz(.infinity), 0); XCTAssertEqual(Kennzahl.ganz(1e300), Int(Int32.max)); XCTAssertEqual(Kennzahl.ganz(3.9), 3)
        XCTAssertEqual(Kennzahl.dauer(-5), 0); XCTAssertEqual(Kennzahl.dauer(.nan), 0); XCTAssertEqual(Kennzahl.dauer(12), 12)
        let e = PartieErgebnis(spiel: "sudoku", dauer: 1e300, teilnehmer: [.init(name: "A", platz: 1)])
        XCTAssertNotNil(GameCenterRegeln.meldung(fuer: e, ich: nil), "riesige Dauer stürzt nicht ab")
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "A", platz: 0, punkte: 5)], kennzahlen: ["stufe": 1e300]))
        XCTAssertNil(st.rekord(spiel: "x", stufe: 2)); _ = st.csv()
    }

    func testLetzteRundeBleibtLesbar() {
        let d = UserDefaults(suiteName: "datenverlust.tests")!; d.removePersistentDomain(forName: "datenverlust.tests")
        LetzteRunde(plaetze: [.init(name: "Anna", computer: false)]).speichern("t", defaults: d)
        XCTAssertEqual(LetzteRunde.laden("t", defaults: d)?.kurz, "Anna")
    }
}
