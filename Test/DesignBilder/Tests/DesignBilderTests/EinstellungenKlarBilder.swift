// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
@testable import DesignBilder
import HuelleBilder

/// Klar-Gegenprobe der Einstellungszeilen (Symbolkacheln), hell und dunkel; läuft unverändert im alten und im neuen Stand.
@MainActor
final class EinstellungenKlarBilder: XCTestCase {
    func testKlarZeilen() {
        KlarGlasHaken.spielart = { nil }
        for dunkel in Aufnahme.toene {
            Design.art = .klar
            let n = Aufnahme.name(.klar, dunkel: dunkel, "einstellungen-zeilen")
            let e = Aufnahme.seite(HuelleSzenen.einstellungsZeilen, design: .klar, dunkel: dunkel, groesse: CGSize(width: 390, height: 420))
            XCTAssertTrue(Aufnahme.schreiben(e.bild, name: n))
        }
        Design.art = .klar
    }
}
#endif
