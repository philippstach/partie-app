// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
@testable import SpielSchocken

/// Zeichnet eine Ansicht in „Klar & Glas“ (hell und dunkel) als PNG nach `$KLAR_ZIEL` (Umgebungsvariable `TEST_RUNNER_KLAR_ZIEL`).
/// Ohne Ziel schreibt der Test nichts. Läuft unverändert im alten und im neuen Stand (Werkzeug/designwechsel_klar_vergleich_davor.sh).
@MainActor
private func klarBilder<V: View>(_ name: String, groesse: CGSize, _ ansicht: () -> V) throws {
    guard let ziel = ProcessInfo.processInfo.environment["KLAR_ZIEL"], !ziel.isEmpty else { return }
    try FileManager.default.createDirectory(atPath: ziel, withIntermediateDirectories: true)
    for dunkel in [false, true] {
        let v = ansicht().padding(16).frame(width: groesse.width, height: groesse.height, alignment: .topLeading)
            .background(Color(.systemGroupedBackground)).environment(\.colorScheme, dunkel ? .dark : .light)
        let r = ImageRenderer(content: v); r.scale = 2
        let daten = try XCTUnwrap(r.uiImage?.pngData(), "kein Bild: \(name)")
        try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(name)-\(dunkel ? "dunkel" : "hell").png"))
        print("BILD \(name)-\(dunkel ? "dunkel" : "hell")")
    }
}

/// Klar-Vergleich Designwechsel: Schocken-Würfel (`DieView`: frei, draußen, umgedreht, unbekannt; Stile klassisch und Gold).
@MainActor
final class KlarWuerfelTests: XCTestCase {
    func testWuerfel() throws {
        try klarBilder("schocken-wuerfel", groesse: CGSize(width: 390, height: 260)) { szene }
    }

    @ViewBuilder private var szene: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) { ForEach(1...6, id: \.self) { DieView(wert: $0, zustand: $0 == 4 ? .draussen : .frei, size: 52) } }
                HStack(spacing: 10) { DieView(wert: 1, zustand: .unbekannt); DieView(wert: 1, zustand: .draussen, umgedreht: true); DieView(wert: 6, zustand: .gewaehlt, size: 40); DieView(wert: 3, size: 22) }
                HStack(spacing: 10) { ForEach([2, 5, 6], id: \.self) { DieView(wert: $0, zustand: $0 == 5 ? .draussen : .frei, size: 44) }.environment(\.wuerfelStil, .gold) }
            }
    }

    /// Dieselbe Szene in allen drei Designs (nur mit `DESIGN_BILDER`): `<design>-<hell|dunkel>-schocken-wuerfel.png`.
    func testDesignBogen() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = szene.padding(16).frame(width: CGSize(width: 390, height: 260).width, height: CGSize(width: 390, height: 260).height, alignment: .topLeading)
                    .background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-schocken-wuerfel.png"))
            }
        }
        Design.art = .klar
    }
}
#endif
