// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
@testable import DesignBilder
import HuelleBilder

/// Startseiten Tinte und Salon, Spieler-Kopf und Einführung: die echten Dateien aus App/Start mit Beispieldaten.
/// Diese Seiten gibt es nur in Tinte und Salon; „Klar & Glas“ behält seinen bisherigen Aufbau in `StartSeite`.
@MainActor
class HuelleBilderTests: XCTestCase {
    override func setUp() async throws {
        await MainActor.run {
            KlarGlasHaken.spielart = { nil }   // Hülle: kein Spiel offen
            KlarGlasHaken.flaeche = { Design.werte.huelleFlaeche.color }
            KlarGlasHaken.accentText = { Design.werte.huelleAkzent.color }
            HuelleSzenen.rundeWaehlen()
        }
    }
    override func tearDown() async throws { await MainActor.run { Design.art = .klar; AktuelleRunde.speichern([]) } }

    private func neue(_ szene: String, groesse: CGSize = Aufnahme.telefon, _ ansicht: (DesignArt) -> AnyView) -> [String] {
        var leer: [String] = []
        for design in [DesignArt.tinte, .salon] {
            for dunkel in Aufnahme.toene {
                Design.art = design
                let n = Aufnahme.name(design, dunkel: dunkel, szene)
                let e = Aufnahme.seite(ansicht(design), design: design, dunkel: dunkel, groesse: groesse)
                if !Aufnahme.schreiben(e.bild, name: n) || Aufnahme.inhaltAnteil(e.bild) < 0.01 { leer.append(n) }
                print("BILD \(n) [\(e.verfahren)] Inhalt \(String(format: "%.3f", Aufnahme.inhaltAnteil(e.bild)))")
            }
        }
        return leer
    }

    func testStart() {
        XCTAssertEqual(neue("start") { $0 == .salon ? AnyView(HuelleSzenen.startSalon) : AnyView(HuelleSzenen.startTinte) }, [])
    }

    /// Mehrere offene Partien: Tinte zeigt den Stapel zum Wischen (Punkte in der Kachel, „Zuletzt“ bleibt), Salon bleibt wie bisher.
    func testStartStapel() {
        XCTAssertEqual(neue("start-stapel") { $0 == .salon ? AnyView(HuelleSzenen.startSalonStapel) : AnyView(HuelleSzenen.startTinteStapel) }, [])
    }

    func testEinstellungsZeilen() {
        XCTAssertEqual(neue("einstellungen-zeilen", groesse: CGSize(width: 390, height: 420)) { _ in AnyView(HuelleSzenen.einstellungsZeilen) }, [])
    }

    func testStatistikSeite() { XCTAssertEqual(neue("statistik") { _ in AnyView(HuelleSzenen.statistikSeite) }, []) }
    func testSpielerSeite() { XCTAssertEqual(neue("spielerseite") { _ in AnyView(HuelleSzenen.spielerSeite) }, []) }
    /// Klar-Gegenprobe der Seiten (nur Aufnahme, ohne Vergleich im Test)
    func testKlarSeiten() {
        for (n, v) in [("statistik", AnyView(HuelleSzenen.statistikSeite)), ("spielerseite", AnyView(HuelleSzenen.spielerSeite)), ("glossar", AnyView(HuelleSzenen.glossar))] {
            for dunkel in Aufnahme.toene {
                Design.art = .klar
                let e = Aufnahme.seite(v, design: .klar, dunkel: dunkel, groesse: Aufnahme.telefon)
                XCTAssertTrue(Aufnahme.schreiben(e.bild, name: Aufnahme.name(.klar, dunkel: dunkel, n)))
            }
        }
    }
    func testSuche() { XCTAssertEqual(neue("suche") { _ in AnyView(HuelleSzenen.suche) }, []) }
    func testGlossar() { XCTAssertEqual(neue("glossar") { _ in AnyView(HuelleSzenen.glossar) }, []) }

    func testSpielerKopf() {
        XCTAssertEqual(neue("spieler-kopf", groesse: CGSize(width: 390, height: 360)) { _ in AnyView(HuelleSzenen.spielerKopf) }, [])
    }

    func testEinfuehrung() {
        XCTAssertEqual(neue("einfuehrung-1") { _ in AnyView(HuelleSzenen.einfuehrung(0)) }, [])
        XCTAssertEqual(neue("einfuehrung-2") { _ in AnyView(HuelleSzenen.einfuehrung(1)) }, [])
    }
}
#endif
