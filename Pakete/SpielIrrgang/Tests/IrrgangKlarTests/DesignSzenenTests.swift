// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import DesignBilder
import IrrgangKern
@testable import SpielIrrgang

/// Designwechsel: dieselben Szenen wie in KlarSpielTests in allen drei Designs, hell und dunkel, als PNG nach `Aufnahme.ordner`
/// (`TEST_RUNNER_DESIGN_BILDER`). Ohne diese Variable schreibt der Test nichts.
@MainActor
final class DesignSzenenTests: XCTestCase {
    func testAlleDesigns() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        _ = ImageRenderer(content: IrrgangSpiel(name: "Anna", ende: { _ in }, abbrechen: {}, vorgabe: KlarSpielTests.szene()).frame(width: 390, height: 844)).uiImage   // der erste ImageRenderer-Lauf richtet unter Mac Catalyst die App-Umgebung ein; erst danach geht das Fenster
        for (szene, m) in [("irrgang-spiel", KlarSpielTests.szene()), ("irrgang-laterne", KlarSpielTests.laterne())] {
            for d in DesignArt.allCases { for dunkel in [false, true] {
                let b = Aufnahme.fensterBild(IrrgangSpiel(name: "Anna", ende: { _ in }, abbrechen: {}, vorgabe: m), design: d, dunkel: dunkel)
                XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, szene)))
            } }
        }
        Design.art = .klar
    }
}
#endif
