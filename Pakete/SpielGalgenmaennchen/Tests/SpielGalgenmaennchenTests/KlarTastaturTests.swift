// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
@testable import SpielGalgenmaennchen

/// Klar-Vergleich Designwechsel: Tastatur von „Galgenmännchen“ mit Treffern, Fehlern und freien Tasten
/// (`$KLAR_ZIEL`, Umgebungsvariable `TEST_RUNNER_KLAR_ZIEL`; ohne Ziel schreibt der Test nichts).
@MainActor
final class KlarTastaturTests: XCTestCase {
    func testTastatur() throws {
        guard let ziel = ProcessInfo.processInfo.environment["KLAR_ZIEL"], !ziel.isEmpty else { return }
        try FileManager.default.createDirectory(atPath: ziel, withIntermediateDirectories: true)
        for dunkel in [false, true] {
            let v = NeuTastatur(sprache: .de, geraten: Array("AEISTRZ"), loesung: "ERDBEERE", spalten: 7, taste: { _ in })
                .padding(16).frame(width: 390, height: 360, alignment: .topLeading)
                .background(Color(.systemGroupedBackground)).environment(\.colorScheme, dunkel ? .dark : .light)
            let r = ImageRenderer(content: v); r.scale = 2
            let daten = try XCTUnwrap(r.uiImage?.pngData(), "kein Bild")
            try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("galgen-tastatur-\(dunkel ? "dunkel" : "hell").png"))
        }
    }
}
#endif
