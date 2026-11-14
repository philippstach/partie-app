// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import HerzensjagdKern
@testable import SpielHerzensjagd

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

/// Klar-Vergleich Designwechsel: Herzensjagd-Karten (`HKartenBild`), alle Farben, gedimmt.
@MainActor
final class KlarKartenTests: XCTestCase {
    func testHKartenBild() throws {
        try klarBilder("herzensjagd", groesse: CGSize(width: 390, height: 200)) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) { HKartenBild(karte: HKarte(3, 14)); HKartenBild(karte: HKarte(1, 10)); HKartenBild(karte: HKarte(2, 12)); HKartenBild(karte: HKarte(0, 2)); HKartenBild(karte: HKarte(3, 7), gedimmt: true) }
            }
        }
    }
}
#endif
