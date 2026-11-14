// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import WidgetKit
import KlarGlas
@testable import WidgetKopie

/// Nur im neuen Baum (Dateien „…Neu.swift“ kommen nicht in den alten): die echten Widget-Ansichten in Tinte und Salon, hell und dunkel,
/// einschließlich Sperrbildschirm der Live-Anzeige. Zielordner `$KLAR_ZIEL` (Bilder `<design>-<hell|dunkel>-widget-<szene>.png`).
@MainActor
final class WidgetDesignNeu: XCTestCase {
    private var zeilen: [UebersichtZeile] {
        TagesSpielInfo.alle.enumerated().map { UebersichtZeile(info: $1, serie: [4, 12, 0, 2, 1, 0, 3][$0], geloest: [true, true, false, false, true, false, true][$0]) }
    }

    private func bild<V: View>(_ art: DesignArt, _ name: String, _ groesse: CGSize, familie: WidgetFamily, id: String?, _ ansicht: () -> V) throws {
        let stil = WidgetStil(art)
        for dunkel in [false, true] {
            let v = ansicht().padding(16).environment(\.testFamilie, familie)
                .frame(width: groesse.width, height: groesse.height).background(stil.grund(id: id))
                .environment(\.colorScheme, dunkel ? .dark : .light)
            let r = ImageRenderer(content: v); r.scale = 2
            let daten = try XCTUnwrap(r.uiImage?.pngData(), "kein Bild: \(name)")
            try FileManager.default.createDirectory(atPath: WidgetVergleichTests.ziel, withIntermediateDirectories: true)
            try daten.write(to: URL(fileURLWithPath: WidgetVergleichTests.ziel).appendingPathComponent("\(art.rawValue)-\(dunkel ? "dunkel" : "hell")-widget-\(name).png"))
        }
    }

    func testTinteUndSalon() throws {
        _ = ImageRenderer(content: Text("x")).uiImage
        let k = WidgetVergleichTests.klein, m = WidgetVergleichTests.mittel, g = WidgetVergleichTests.gross
        let info = TagesSpielInfo.alle[1]
        let konfig = TagesWidgetKonfiguration(gruppe: PartieGeteilt.gruppe, praefix: info.praefix, titel: info.name, galerieName: info.name, farbeHex: info.farbeHex)
        let rek = [PartieGeteilt.Rekord(id: "yacht", name: "Yacht", farbeHex: 0, punkte: 312, datum: Date()), PartieGeteilt.Rekord(id: "10k", name: "10k", farbeHex: 0, punkte: 10450, datum: Date()),
                   PartieGeteilt.Rekord(id: "muehle", name: "Mühle", farbeHex: 0, punkte: 9, datum: Date())]
        let a = PartieAktivitaet(spielID: "yacht", spielName: "Yacht", farbeHex: 0xF26B1D, spieler: ["Anna", "Ben"], beginn: Date().addingTimeInterval(86_400))
        let zuletzt = PartieGeteilt.Zuletzt(id: "yacht", name: "Yacht", farbeHex: 0xF26B1D, datum: Date().addingTimeInterval(-3 * 3600 - 60))
        for art in [DesignArt.tinte, .salon] {
            PartieGeteilt.designSchreiben(art.rawValue)
            XCTAssertEqual(PartieGeteilt.design(), art.rawValue, "App Group nicht beschreibbar")
            let e = TagesWidgetEintrag(date: Date(timeIntervalSince1970: 1_794_000_000), serie: 12, heuteGeloest: true)
            try bild(art, "tages-klein", k, familie: .systemSmall, id: "sudoku") { TagesSpielAnsicht(info: info, konfig: konfig, eintrag: e) }
            try bild(art, "tages-mittel", m, familie: .systemMedium, id: "sudoku") { TagesSpielAnsicht(info: info, konfig: konfig, eintrag: e) }
            let ue = UebersichtEintrag(date: Date(), zeilen: zeilen)
            try bild(art, "uebersicht-mittel", m, familie: .systemMedium, id: "solitaer") { UebersichtAnsicht(eintrag: ue) }
            try bild(art, "uebersicht-gross", g, familie: .systemLarge, id: "solitaer") { UebersichtAnsicht(eintrag: ue) }
            try bild(art, "weiter-klein", k, familie: .systemSmall, id: "yacht") { WeiterAnsicht(eintrag: WeiterEintrag(date: Date(), zuletzt: zuletzt)) }
            try bild(art, "weiter-leer-mittel", m, familie: .systemMedium, id: nil) { WeiterAnsicht(eintrag: WeiterEintrag(date: Date(), zuletzt: nil)) }
            let re = RekordEintrag(date: Date(), rekorde: rek, summen: .init(partien: 42, siege: 17))
            try bild(art, "rekord-klein", k, familie: .systemSmall, id: "yacht") { RekordAnsicht(eintrag: re) }
            try bild(art, "rekord-mittel", m, familie: .systemMedium, id: "yacht") { RekordAnsicht(eintrag: re) }
            for (n, z) in [("zug", PartieAktivitaet.ContentState(amZug: "Anna", stand: "Anna 12 · Ben 8")), ("namen", PartieAktivitaet.ContentState(amZug: nil, stand: nil))] {
                try bild(art, "sperre-\(n)", CGSize(width: 372, height: 100), familie: .systemMedium, id: "yacht") { SperrbildschirmAnsicht(attribute: a, zustand: z) }
            }
        }
        PartieGeteilt.designSchreiben("klar")
    }
}
#endif
