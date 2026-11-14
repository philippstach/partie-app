// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
import DesignBilder
@testable import SpielSchwimmen

/// Schwimmen mit zwei Menschen (Weitergabe-Karte, F-AWS-P-017) und gegen den Computer (verdeckte Karten, K-035),
/// in allen Designs, iPhone und iPad. Nur mit `TEST_RUNNER_DESIGN_BILDER`.
@MainActor
final class DesignSzenenTests: XCTestCase {
    func testAlleDesigns() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        let zwei = { SchwimmenNeuSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], ende: { _ in }, abbrechen: {}) }
        _ = ImageRenderer(content: zwei().frame(width: 390, height: 844)).uiImage
        for (gname, g) in [("normal", CGSize(width: 390, height: 844)), ("ipad", CGSize(width: 820, height: 1180))] {
            for d in DesignArt.allCases { for dunkel in [false, true] {
                let b = Aufnahme.fensterBild(zwei(), design: d, dunkel: dunkel, groesse: g)
                XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, "schwimmen-weitergabe-\(gname)")))
            } }
        }
        Design.art = .klar
    }
}
#endif
