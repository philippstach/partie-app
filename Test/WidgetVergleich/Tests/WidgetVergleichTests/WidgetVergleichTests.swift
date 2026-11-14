// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import WidgetKit
import KlarGlas
@testable import WidgetKopie

/// Zeichnet die echten Widget-Ansichten (aus den kopierten Quellen) in „Klar & Glas“, hell und dunkel, als PNG nach `$KLAR_ZIEL`.
/// Gleicher Test im alten und im neuen Baum; der Vergleich läuft in designwechsel_widget_vergleich.sh.
@MainActor
final class WidgetVergleichTests: XCTestCase {
    static let klein = CGSize(width: 158, height: 158), mittel = CGSize(width: 329, height: 158), gross = CGSize(width: 329, height: 345)
    static var ziel: String { ProcessInfo.processInfo.environment["KLAR_ZIEL"] ?? NSTemporaryDirectory() + "widget-vergleich" }
    static let datum = Date(timeIntervalSince1970: 1_794_000_000)

    private func bild<V: View>(_ name: String, _ groesse: CGSize, familie: WidgetFamily, hintergrund: Color, _ ansicht: () -> V) throws {
        try FileManager.default.createDirectory(atPath: Self.ziel, withIntermediateDirectories: true)
        for dunkel in [false, true] {
            let v = ansicht().padding(16).environment(\.testFamilie, familie)
                .frame(width: groesse.width, height: groesse.height).background(hintergrund)
                .environment(\.colorScheme, dunkel ? .dark : .light)
            let r = ImageRenderer(content: v); r.scale = 2
            let daten = try XCTUnwrap(r.uiImage?.pngData(), "kein Bild: \(name)")
            try daten.write(to: URL(fileURLWithPath: Self.ziel).appendingPathComponent("\(name)-\(dunkel ? "dunkel" : "hell").png"))
            print("BILD \(name)-\(dunkel ? "dunkel" : "hell")")
        }
    }

    private var zeilen: [UebersichtZeile] {
        TagesSpielInfo.alle.enumerated().map { UebersichtZeile(info: $1, serie: [4, 12, 0, 2, 1, 0, 3][$0], geloest: [true, true, false, false, true, false, true][$0]) }
    }

    func testTagesraetsel() throws {
        _ = ImageRenderer(content: Text("x")).uiImage
        let info = TagesSpielInfo.alle[1]   // Sudoku
        let konfig = TagesWidgetKonfiguration(gruppe: PartieGeteilt.gruppe, praefix: info.praefix, titel: info.name, galerieName: info.name, farbeHex: info.farbeHex)
        for (n, geloest, serie) in [("offen", false, 0), ("geloest", true, 12)] {
            let e = TagesWidgetEintrag(date: Self.datum, serie: serie, heuteGeloest: geloest)
            try bild("widget-tages-\(n)-klein", Self.klein, familie: .systemSmall, hintergrund: Color.familie(info.farbeHex)) { TagesSpielAnsicht(info: info, konfig: konfig, eintrag: e) }
            try bild("widget-tages-\(n)-mittel", Self.mittel, familie: .systemMedium, hintergrund: Color.familie(info.farbeHex)) { TagesSpielAnsicht(info: info, konfig: konfig, eintrag: e) }
        }
    }

    func testUebersicht() throws {
        let e = UebersichtEintrag(date: Self.datum, zeilen: zeilen)
        try bild("widget-uebersicht-mittel", Self.mittel, familie: .systemMedium, hintergrund: Color.familie(Familienfarbe.nachtblau.flaeche)) { UebersichtAnsicht(eintrag: e) }
        try bild("widget-uebersicht-gross", Self.gross, familie: .systemLarge, hintergrund: Color.familie(Familienfarbe.nachtblau.flaeche)) { UebersichtAnsicht(eintrag: e) }
    }

    func testWeiterspielen() throws {
        let z = PartieGeteilt.Zuletzt(id: "yacht", name: "Yacht", farbeHex: Familienfarbe.orange.flaeche, datum: Date().addingTimeInterval(-3 * 3600 - 60))
        for (n, zuletzt) in [("spiel", Optional(z)), ("leer", nil)] {
            let hg = Color.familie(zuletzt?.farbeHex ?? Familienfarbe.nachtblau.flaeche)
            try bild("widget-weiter-\(n)-klein", Self.klein, familie: .systemSmall, hintergrund: hg) { WeiterAnsicht(eintrag: WeiterEintrag(date: Self.datum, zuletzt: zuletzt)) }
            try bild("widget-weiter-\(n)-mittel", Self.mittel, familie: .systemMedium, hintergrund: hg) { WeiterAnsicht(eintrag: WeiterEintrag(date: Self.datum, zuletzt: zuletzt)) }
        }
    }

    func testBestleistung() throws {
        let rek = [PartieGeteilt.Rekord(id: "yacht", name: "Yacht", farbeHex: Familienfarbe.orange.flaeche, punkte: 312, datum: Self.datum),
                   PartieGeteilt.Rekord(id: "10k", name: "10k", farbeHex: Familienfarbe.indigo.flaeche, punkte: 10450, datum: Self.datum.addingTimeInterval(-1000)),
                   PartieGeteilt.Rekord(id: "muehle", name: "Mühle", farbeHex: Familienfarbe.tuerkis.flaeche, punkte: 9, datum: Self.datum.addingTimeInterval(-2000))]
        let voll = RekordEintrag(date: Self.datum, rekorde: rek, summen: .init(partien: 42, siege: 17))
        let leer = RekordEintrag(date: Self.datum, rekorde: [], summen: .init())
        try bild("widget-rekord-klein", Self.klein, familie: .systemSmall, hintergrund: Color.familie(Familienfarbe.orange.flaeche)) { RekordAnsicht(eintrag: voll) }
        try bild("widget-rekord-mittel", Self.mittel, familie: .systemMedium, hintergrund: Color.familie(Familienfarbe.nachtblau.flaeche)) { RekordAnsicht(eintrag: voll) }
        try bild("widget-rekord-leer-klein", Self.klein, familie: .systemSmall, hintergrund: Color.familie(Familienfarbe.nachtblau.flaeche)) { RekordAnsicht(eintrag: leer) }
        try bild("widget-rekord-leer-mittel", Self.mittel, familie: .systemMedium, hintergrund: Color.familie(Familienfarbe.nachtblau.flaeche)) { RekordAnsicht(eintrag: leer) }
    }

    func testSperrbildschirm() throws {
        let a = PartieAktivitaet(spielID: "yacht", spielName: "Yacht", farbeHex: Familienfarbe.orange.flaeche, spieler: ["Anna", "Ben"], beginn: Date().addingTimeInterval(86_400))   // Beginn in der Zukunft: die Uhr steht still auf 0:00
        for (n, z) in [("zug", PartieAktivitaet.ContentState(amZug: "Anna", stand: "Anna 12 · Ben 8")), ("namen", PartieAktivitaet.ContentState(amZug: nil, stand: nil))] {
            try bild("widget-sperre-\(n)", CGSize(width: 372, height: 100), familie: .systemMedium, hintergrund: Color.familie(a.farbeHex)) { SperrbildschirmAnsicht(attribute: a, zustand: z) }
        }
    }
}
#endif
