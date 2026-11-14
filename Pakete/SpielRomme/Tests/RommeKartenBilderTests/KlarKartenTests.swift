// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import RommeKern
@testable import SpielRomme

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

/// Klar-Vergleich Designwechsel: Rommé-Karten (`RBild`) normal, gewählt, klein, Joker.
@MainActor
final class KlarKartenTests: XCTestCase {
    func testRBild() throws {
        try klarBilder("romme", groesse: CGSize(width: 390, height: 200)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) { RBild(karte: RKarte(2, 13)); RBild(karte: RKarte(1, 1)); RBild(karte: RKarte(3, 10), markiert: true); RBild(karte: RKarte(0, 7)); RBild(karte: RKarte(0, 0)) }
                HStack(spacing: 6) { RBild(karte: RKarte(2, 5), klein: true); RBild(karte: RKarte(1, 12), klein: true); RBild(karte: RKarte(0, 0), klein: true); RBild(karte: RKarte(3, 9), markiert: true, klein: true) }
            }
        }
    }
}
#endif
