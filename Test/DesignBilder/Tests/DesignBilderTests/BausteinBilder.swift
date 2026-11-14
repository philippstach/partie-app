// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
@testable import DesignBilder

/// Probe und Bausteine-Bogen: zeichnet die Bausteine des Baukastens in allen drei Designs, hell und dunkel.
@MainActor
class BausteinBilder: XCTestCase {
    override func setUp() async throws {
        await MainActor.run {
            // Wie in der App mit einem offenen Würfelspiel: Fläche und Textfarbe der Spielart
            KlarGlasHaken.spielart = { .wuerfel }
            KlarGlasHaken.flaeche = { Gattung.wuerfel.farbe.color }
            KlarGlasHaken.accentText = { Gattung.wuerfel.farbe.textFarbe }
        }
    }

    override func tearDown() async throws { await MainActor.run { Design.art = .klar } }

    /// Bogen mit Knöpfen, Kopf, Leisten, Zeilen (ohne ScrollView, damit `ImageRenderer` alles zeichnet).
    struct Bogen: View {
        var body: some View {
            VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                SpielKopf(mitte: "Runde 7 · Anna würfelt", mitteKurz: "Runde 7", linksAktion: {}) {
                    RundKnopfMenue(beschriftung: "Menü") { Button("Regeln") {} }
                }
                .padding(.horizontal, -Theme.seitenRand)
                StartTitel("Partie")
                SectionLabel("Abschnitt")
                HStack(spacing: Design.Abstand.s) {
                    StatusChip(symbol: "lightbulb", text: "3")
                    StatusChip(text: Text(verbatim: "liegt hinten"), ton: .warnung)
                    StatusChip(text: Text(verbatim: "neutral"), ton: .neutral)
                }
                WeiterspielenKarte(zeit: "4:12", beschreibung: "Sudoku", fortschritt: 0.4) {}
                SpielZeile(name: "Yacht", untertitel: Text(verbatim: "Würfel · 1–4 Spieler"), farbe: Gattung.wuerfel.farbe.color, miniatur: .wuerfel, hell: true) {}
                SpielZeile(name: "Solitär", untertitel: Text(verbatim: "Karten · 1 Spieler"), farbe: Gattung.karten.farbe.color, miniatur: .kartenstapel, favorit: true, hell: true) {}
                StatistikZeile(titel: "Statistik", werte: [.init(zahl: "48", name: "Partien"), .init(zahl: "21", name: "Siege"), .init(zahl: "3", name: "Serie")]) {}
                SpielerLeiste(eintraege: [.init(id: "a", name: "Anna", farbe: Spieler.farbe(0), wert: "124"), .init(id: "b", name: "Ben", farbe: Spieler.farbe(3), wert: "98"),
                                          .init(id: "c", name: "Clara", farbe: Spieler.farbe(2), wert: "131")], aktiv: "a")
                HinweisKarte(symbol: "lightbulb", titel: Text(verbatim: "Tipp"), text: Text(verbatim: "In dieser Reihe fehlen noch 1, 2 und 4."))
                Spacer(minLength: 0)
                AktionsLeiste(eintraege: [.init(symbol: "arrow.uturn.backward", titel: "Rückgängig") {}, .init(symbol: "delete.left", titel: "Löschen") {},
                                          .init(symbol: "pencil", titel: "Notizen", aktiv: true) {}, .init(symbol: "lightbulb", titel: "Tipp") {}])
                    .padding(.horizontal, -Theme.seitenRand)
                HStack(spacing: Design.Abstand.s) {
                    Button("Eintragen") {}.zweitKnopf()
                    Button("Würfeln") {}.hauptKnopf()
                }
            }
            .padding(.horizontal, Theme.seitenRand).padding(.vertical, 12)
        }
    }

    func testBausteinBogen() throws {
        var leer: [String] = []
        for design in DesignArt.allCases {
            for dunkel in Aufnahme.toene {
                let name = Aufnahme.name(design, dunkel: dunkel, "bausteine")
                let bild = Aufnahme.bild(Bogen(), design: design, dunkel: dunkel, groesse: CGSize(width: 390, height: 1040))
                XCTAssertTrue(Aufnahme.schreiben(bild, name: name), "nicht geschrieben: \(name)")
                if Aufnahme.inhaltAnteil(bild) < 0.01 { leer.append(name) }
            }
        }
        XCTAssertEqual(leer, [], "leere Bilder")
    }
}
#endif
