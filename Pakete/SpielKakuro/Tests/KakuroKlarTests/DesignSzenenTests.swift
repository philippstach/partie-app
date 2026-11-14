// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import DesignBilder
import KakuroKern
@testable import SpielKakuro

/// Designwechsel: dieselben Szenen wie in KlarSpielTests in allen drei Designs, hell und dunkel, als PNG nach `Aufnahme.ordner`
/// (`TEST_RUNNER_DESIGN_BILDER`). Ohne diese Variable schreibt der Test nichts.
@MainActor
final class DesignSzenenTests: XCTestCase {
    func testAlleDesigns() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        _ = ImageRenderer(content: KakuroSpiel(name: "Anna", ende: { _ in }, abbrechen: {}, vorgabe: KlarSpielTests.szene()).frame(width: 390, height: 844)).uiImage   // der erste ImageRenderer-Lauf richtet unter Mac Catalyst die App-Umgebung ein; erst danach geht das Fenster
        let k = KlarSpielTests.szene()
        for d in DesignArt.allCases { for dunkel in [false, true] {
            let b = Aufnahme.fensterBild(KakuroSpiel(name: "Anna", ende: { _ in }, abbrechen: {}, vorgabe: k), design: d, dunkel: dunkel)
            XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, "kakuro-spiel")))
        } }
        Design.art = .klar
    }
}
#endif
