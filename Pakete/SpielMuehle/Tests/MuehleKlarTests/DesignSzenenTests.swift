// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
import DesignBilder
import MuehleKern
@testable import SpielMuehle

/// Designwechsel: dieselben Szenen wie in KlarSpielTests in allen drei Designs, hell und dunkel, als PNG nach `Aufnahme.ordner`
/// (`TEST_RUNNER_DESIGN_BILDER`). Ohne diese Variable schreibt der Test nichts.
@MainActor
final class DesignSzenenTests: XCTestCase {
    func testAlleDesigns() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        _ = ImageRenderer(content: MuehleSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], ende: { _ in }, abbrechen: {}, vorgabe: KlarSpielTests.szene()).frame(width: 390, height: 844)).uiImage   // der erste ImageRenderer-Lauf richtet unter Mac Catalyst die App-Umgebung ein; erst danach geht das Fenster
        let m = KlarSpielTests.szene()
        for d in DesignArt.allCases { for dunkel in [false, true] {
            let b = Aufnahme.bild(MuehleSpiel(teilnehmer: [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")], ende: { _ in }, abbrechen: {}, vorgabe: m), design: d, dunkel: dunkel)
            XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, "muehle-spiel")))
        } }
        Design.art = .klar
    }

    /// Spielmitte (Zugphase, alle Steine gesetzt) mit gewähltem Stein: Zielpunkte und gewählter Punkt sind markiert (Runde 3, Punkt 7).
    func testSpielmitte() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        var brett = [Int](repeating: 0, count: 24)
        for p in [1, 4, 9, 13, 17, 22] { brett[p] = 1 }
        for p in [3, 6, 10, 15, 19, 21] { brett[p] = 2 }
        let json = "{\"brett\":\(brett),\"vorrat\":[0,0,0],\"dran\":1,\"mussEntfernen\":false,\"ruhigeZuege\":3}"
        let m = try JSONDecoder().decode(Muehle.self, from: Data(json.utf8))
        guard case .ziehe(let von, _)? = m.zuege().first else { return XCTFail("kein Zug") }
        let leute = [SpielTeilnehmer(name: "Anna"), SpielTeilnehmer(name: "Ben")]
        let gattung = Gattung.brett   // Spielart-Farbe wie in der App (sonst fehlt die Zug-Markierung in Tinte/Salon die Farbe)
        KlarGlasHaken.spielart = { gattung.designSpielart }
        KlarGlasHaken.flaeche = { gattung.farbe.color }
        KlarGlasHaken.accentText = { gattung.farbe.textFarbe }
        _ = ImageRenderer(content: MuehleSpiel(teilnehmer: leute, ende: { _ in }, abbrechen: {}, vorgabe: m, waehle: von).frame(width: 390, height: 844)).uiImage
        for d in DesignArt.allCases { for dunkel in [false, true] {
            let b = Aufnahme.bild(MuehleSpiel(teilnehmer: leute, ende: { _ in }, abbrechen: {}, vorgabe: m, waehle: von), design: d, dunkel: dunkel)
            XCTAssertTrue(Aufnahme.schreiben(b, name: Aufnahme.name(d, dunkel: dunkel, "spiel-muehle-mitte")))
        } }
        Design.art = .klar
    }
}
#endif
