// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
@testable import SpieleKern

/// Designwechsel D.4: Würfel-Eingabeblatt (`WuerfelEingabeBlatt`) in drei Designs, hell und dunkel (nur mit `DESIGN_BILDER`).
@MainActor
final class DesignEingabeBilder: XCTestCase {
    func testBlatt() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        KlarGlasHaken.spielart = { .wuerfel }
        KlarGlasHaken.flaeche = { Gattung.wuerfel.farbe.color }
        KlarGlasHaken.accentText = { Gattung.wuerfel.farbe.textFarbe }
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = WuerfelEingabeBlatt(anzahl: 5, fertig: { _ in }, abbrechen: {})
                    .frame(width: 390, height: 600).background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-eingabeblatt.png"))
            }
        }
        Design.art = .klar
    }
}
#endif
