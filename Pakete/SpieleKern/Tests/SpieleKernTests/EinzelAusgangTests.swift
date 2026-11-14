// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// S1: Ein Einzelspiel kann eine Niederlage oder ein Punktespiel ohne Wertung melden.
@MainActor
final class EinzelAusgangTests: XCTestCase {
    private func gebucht(_ einzel: EinzelAusgang, punkte: [Int?] = [], dauer: TimeInterval = 60, spiel: String = "irrgang") -> PartieErgebnis {
        PartieErgebnis(spiel: spiel, dauer: dauer, teilnehmer: EndeBuchung.teilnehmer(reihenfolge: ["Anna"], punkte: punkte, einzel: einzel))
    }

    // MARK: Buchung

    func testStandardBleibtSiegAufPlatzEins() {
        XCTAssertEqual(EndeBuchung.teilnehmer(reihenfolge: ["Anna"]).map(\.platz), [1])
        XCTAssertEqual(EndeBuchung.teilnehmer(reihenfolge: ["Anna"], einzel: .gewonnen).map(\.platz), [1])
    }

    func testVerlorenIstPlatzZweiUndPunktespielPlatzNull() {
        XCTAssertEqual(EndeBuchung.teilnehmer(reihenfolge: ["Anna"], einzel: .verloren).map(\.platz), [2])
        XCTAssertEqual(EndeBuchung.teilnehmer(reihenfolge: ["Anna"], punkte: [42], einzel: .punkte).map(\.platz), [0])
        XCTAssertEqual(EndeBuchung.teilnehmer(reihenfolge: ["Anna"], punkte: [42], einzel: .punkte).first?.punkte, 42)
    }

    func testEinzelAusgangWirktNichtBeiMehrerenNamen() {
        XCTAssertEqual(EndeBuchung.teilnehmer(reihenfolge: ["Anna", "Ben"], einzel: .verloren).map(\.platz), [1, 2])
        XCTAssertEqual(EndeBuchung.teilnehmer(reihenfolge: ["Anna", "Ben"], plaetze: [1, 1], einzel: .punkte).map(\.platz), [1, 1])
    }

    // MARK: Statistik, Bilanz, Game Center

    func testNiederlageZaehltAlsPartieOhneSiegUndBeendetDieSerie() {
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(gebucht(.gewonnen)); st.melden(gebucht(.gewonnen))
        XCTAssertEqual(st.bilanz(spiel: "irrgang").serie, 2)
        st.melden(gebucht(.verloren))
        let b = st.bilanz(spiel: "irrgang")
        XCTAssertEqual(b.partien, 3); XCTAssertEqual(b.siege, 2); XCTAssertEqual(b.serie, 0)
        XCTAssertEqual(st.summe(spiel: "irrgang").siege, 2)
        XCTAssertEqual(gebucht(.verloren).ergebnisText(ichName: "Anna"), String(localized: "verloren"))
        XCTAssertFalse(gebucht(.verloren).istAbbruch)
    }

    func testPunktespielZaehltPartieUndBestwertAberKeinenSiegUndLaesstDieSerie() {
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(gebucht(.gewonnen, spiel: "chicago"))
        st.melden(gebucht(.punkte, punkte: [17], spiel: "chicago"))
        let b = st.bilanz(spiel: "chicago")
        XCTAssertEqual(b.partien, 2); XCTAssertEqual(b.siege, 1); XCTAssertEqual(b.serie, 1); XCTAssertEqual(b.rekord, 17)
        XCTAssertEqual(gebucht(.punkte, punkte: [17]).ergebnisText(ichName: "Anna"), String(localized: "\(17) Punkte"))
        XCTAssertEqual(gebucht(.punkte).ergebnisText(ichName: "Anna"), String(localized: "gespielt"))
    }

    func testGameCenterNiederlageOhneBestzeitPunktespielMitPunkten() {
        XCTAssertNotNil(GameCenterRegeln.meldung(fuer: gebucht(.gewonnen), ich: nil))                 // Irrgang: Zeitliste
        XCTAssertNil(GameCenterRegeln.meldung(fuer: gebucht(.verloren), ich: nil))
        XCTAssertNil(GameCenterRegeln.meldung(fuer: gebucht(.punkte), ich: nil))
        XCTAssertEqual(GameCenterRegeln.meldung(fuer: gebucht(.punkte, punkte: [17], spiel: "chicago"), ich: nil)?.wert, 17)
        let f = GameCenterRegeln.fortschritt(ereignisse: [gebucht(.verloren), gebucht(.punkte, punkte: [3])], ich: nil, tagesSerie: 0) { _ in .init(gattung: nil, land: nil) }
        XCTAssertEqual(f["partie.erfolg.erstePartie"], 100); XCTAssertEqual(f["partie.erfolg.ersterSieg"], 0)
    }

    // MARK: Ende-Bildschirm und Teilen

    func testUeberschriftJeAusgang() {
        XCTAssertEqual(EndeBuchung.titel(reihenfolge: ["Anna"], remis: false), .geschafft)
        XCTAssertEqual(EndeBuchung.titel(reihenfolge: ["Anna"], remis: false, einzel: .verloren), .verloren)
        XCTAssertEqual(EndeBuchung.titel(reihenfolge: ["Anna"], remis: false, einzel: .punkte), .beendet)
        XCTAssertEqual(EndeBuchung.titel(reihenfolge: ["Anna"], remis: false, einzel: .punkte, neuerRekord: true), .neuerRekord)
        XCTAssertEqual(EndeBuchung.titel(reihenfolge: ["Anna", "Ben"], remis: false, einzel: .verloren), .sieger("Anna"))
        XCTAssertEqual(EndeBuchung.titel(reihenfolge: ["Anna", "Ben"], remis: true, einzel: .verloren), .remis)
    }

    func testNeuerRekordNurImPunktespielMitMehrPunkten() {
        XCTAssertTrue(EndeBuchung.neuerRekord(reihenfolge: ["A"], punkte: ["18"], einzel: .punkte, bisher: 17))
        XCTAssertTrue(EndeBuchung.neuerRekord(reihenfolge: ["A"], punkte: ["18 Punkte"], einzel: .punkte, bisher: nil))
        XCTAssertFalse(EndeBuchung.neuerRekord(reihenfolge: ["A"], punkte: ["17"], einzel: .punkte, bisher: 17))
        XCTAssertFalse(EndeBuchung.neuerRekord(reihenfolge: ["A"], punkte: ["18"], einzel: .gewonnen, bisher: 17))
        XCTAssertFalse(EndeBuchung.neuerRekord(reihenfolge: ["A"], punkte: [], einzel: .punkte, bisher: nil))
        XCTAssertFalse(EndeBuchung.neuerRekord(reihenfolge: ["A", "B"], punkte: ["18"], einzel: .punkte, bisher: 1))
    }

    func testTeilenTextNenntNiederlageUndPunkte() {
        let verloren = ErgebnisText.text(spiel: "Irrgang", reihenfolge: ["Anna"], einzel: .verloren)
        XCTAssertTrue(verloren.hasPrefix(String(localized: "\("Irrgang"): Verloren")))
        let punkte = ErgebnisText.text(spiel: "Chicago", reihenfolge: ["Anna"], punkte: ["17"], einzel: .punkte)
        XCTAssertTrue(punkte.hasPrefix(String(localized: "\("Chicago"): \(17) Punkte")))
        let ohne = ErgebnisText.text(spiel: "Chicago", reihenfolge: ["Anna"], einzel: .punkte)
        XCTAssertTrue(ohne.hasPrefix(String(localized: "\("Chicago"): Partie beendet")))
        XCTAssertTrue(ErgebnisText.text(spiel: "Irrgang", reihenfolge: ["Anna"]).hasPrefix(String(localized: "\("Irrgang"): Geschafft!")))
    }
}
