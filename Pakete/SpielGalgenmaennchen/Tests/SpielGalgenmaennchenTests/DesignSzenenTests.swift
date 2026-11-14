// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import DesignBilder
@testable import SpielGalgenmaennchen

/// Designwechsel: dieselben Szenen wie in KlarSpielTests in allen drei Designs, hell und dunkel, als PNG nach `Aufnahme.ordner`
/// (`TEST_RUNNER_DESIGN_BILDER`). Ohne diese Variable schreibt der Test nichts.
@MainActor
final class DesignSzenenTests: XCTestCase {
    func testAlleDesigns() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        _ = ImageRenderer(content: NeuTastatur(sprache: .de, geraten: Array("AEISTRZ"), loesung: "ERDBEERE", spalten: 7, taste: { _ in }).frame(width: 390, height: 844)).uiImage   // der erste ImageRenderer-Lauf richtet unter Mac Catalyst die App-Umgebung ein; erst danach geht das Fenster
        for d in DesignArt.allCases { for dunkel in [false, true] {
            let v = NeuTastatur(sprache: .de, geraten: Array("AEISTRZ"), loesung: "ERDBEERE", spalten: 7, taste: { _ in }).padding(16)
            let b = Aufnahme.bild(v, design: d, dunkel: dunkel, groesse: CGSize(width: 390, height: 360))
            XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, "galgen-tastatur")))
        } }
        Design.art = .klar
    }
}
#endif
