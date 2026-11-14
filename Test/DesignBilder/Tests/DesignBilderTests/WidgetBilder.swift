// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import DesignBilder

/// Designwechsel E: Widget-Ansichten für Tinte und Salon (die Datei `WidgetAnsichten.swift` ist ein Verweis auf Widget/Geteilt).
/// Ein Bogen je Design und Darstellung mit klein/mittel/groß: Tagesrätsel (Rätsel, Karten, Wort), Übersicht, Weiterspielen, Bestleistung.
@MainActor
final class WidgetBilder: XCTestCase {
    private let klein = CGSize(width: 158, height: 158), mittel = CGSize(width: 329, height: 158), gross = CGSize(width: 329, height: 345)

    private func bogen(_ stil: WidgetStil) -> some View {
        let zeilen = [("minensuche", "Minensuche", true, 4), ("sudoku", "Sudoku", true, 12), ("solitaer", "Solitär", false, 0), ("viererreihe", "Viererreihe", false, 2),
                      ("galgenmaennchen", "Galgenmännchen", true, 1), ("wortpfeil", "Kreuzworträtsel", false, 0), ("farbraetsel", "Farbrätsel", true, 3)]
            .map { UebersichtKachelZeile(id: $0.0, name: $0.1, geloest: $0.2, serie: $0.3) }
        let rekorde = [RekordKachelZeile(id: "yacht", name: "Yacht", punkte: 312), RekordKachelZeile(id: "10k", name: "10k", punkte: 10450), RekordKachelZeile(id: "muehle", name: "Mühle", punkte: 9)]
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                TagesKachel(stil: stil, id: "sudoku", name: "Sudoku", datum: Date(timeIntervalSince1970: 1_794_000_000), geloest: true, serie: 12, serieText: TagesSerie.text(12)).widgetKachel(stil, id: "sudoku", container: false)
                TagesKachel(stil: stil, id: "solitaer", name: "Solitär", datum: Date(timeIntervalSince1970: 1_794_000_000), geloest: false, serie: 0, serieText: TagesSerie.text(0)).widgetKachel(stil, id: "solitaer", container: false)
                TagesKachel(stil: stil, id: "galgenmaennchen", name: "Galgenmännchen", datum: Date(timeIntervalSince1970: 1_794_000_000), geloest: false, serie: 3, serieText: TagesSerie.text(3)).widgetKachel(stil, id: "galgenmaennchen", container: false)
            }
            HStack(spacing: 12) {
                WeiterKachel(stil: stil, id: "yacht", name: "Yacht", wann: "vor 3 Stunden").widgetKachel(stil, id: "yacht", container: false)
                RekordKachel(stil: stil, rekorde: rekorde, partien: 42, siege: 17).widgetKachel(stil, id: "yacht", container: false)
                WeiterKachel(stil: stil, id: nil, name: nil, wann: "").widgetKachel(stil, id: nil, container: false)
            }
            HStack(alignment: .top, spacing: 12) {
                UebersichtKachel(stil: stil, zeilen: zeilen, link: { _ in nil }).widgetKachel(stil, id: "solitaer", container: false, groesse: mittel)
                RekordKachel(stil: stil, rekorde: rekorde, partien: 42, siege: 17, mittel: true).widgetKachel(stil, id: "yacht", container: false, groesse: mittel)
            }
            UebersichtKachel(stil: stil, zeilen: zeilen, gross: true, link: { _ in nil }).widgetKachel(stil, id: "solitaer", container: false, groesse: gross)
        }
        .padding(16)
    }

    func testBogen() throws {
        _ = ImageRenderer(content: Text("x")).uiImage
        for art in [DesignArt.tinte, .salon] {
            for dunkel in [false, true] {
                Design.art = art
                let v = bogen(WidgetStil(art)).background(Color.seitenGrund).environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                XCTAssertTrue(Aufnahme.schreiben(r.uiImage, name: Aufnahme.name(art, dunkel: dunkel, "widgets")))
            }
        }
        Design.art = .klar
    }
}
#endif
