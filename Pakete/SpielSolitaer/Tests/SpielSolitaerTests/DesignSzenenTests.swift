// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
import DesignBilder
@testable import SpielSolitaer

/// Solitär-Tisch (Klondike, Statuszeile, F-AWS-K-026) und Spielwahl (Tagesspiel-Karte, R-001) in allen Designs.
/// Nur mit `TEST_RUNNER_DESIGN_BILDER`.
@MainActor
final class DesignSzenenTests: XCTestCase {
    func testAlleDesigns() throws {
        guard ProcessInfo.processInfo.environment["DESIGN_BILDER"] != nil else { return }
        KlarGlasHaken.spielart = { .karten }
        KlarGlasHaken.flaeche = { Gattung.karten.farbe.color }
        KlarGlasHaken.accentText = { Gattung.karten.farbe.textFarbe }
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        prefs.showTime = true; prefs.showMoves = true; prefs.showScore = true
        let app = AppModel(prefs: prefs, stats: StatsStore(url: nil), folder: nil)
        app.switchTo(.klondike(1))
        let router = Router()
        func umgeben<V: View>(_ v: V) -> some View {
            v.environment(app).environment(app.stats).environment(router)
                .environment(\.cardBackStyle, app.prefs.cardBack).environment(\.tableStyle, app.prefs.activeTable)
                .environment(\.tablePhoto, app.prefs.tablePhoto).environment(\.largeCardIndex, app.prefs.largeCards)
        }
        _ = ImageRenderer(content: umgeben(NeuTisch(name: "Anna", ende: { _ in }, zurSammlung: {})).frame(width: 390, height: 844)).uiImage
        for d in DesignArt.allCases { for dunkel in [false, true] {
            let t = Aufnahme.bild(umgeben(NeuTisch(name: "Anna", ende: { _ in }, zurSammlung: {})), design: d, dunkel: dunkel)
            XCTAssertTrue(Aufnahme.schreiben(t, name: Aufnahme.name(d, dunkel: dunkel, "solitaer-tisch")))
            for (gname, g) in [("se", CGSize(width: 320, height: 568)), ("normal", CGSize(width: 390, height: 844))] {
                let w = Aufnahme.bild(umgeben(NeuWahl(zurSammlung: {})), design: d, dunkel: dunkel, groesse: g)
                XCTAssertTrue(Aufnahme.schreiben(w, name: Aufnahme.name(d, dunkel: dunkel, "solitaer-wahl-\(gname)")))
            }
        } }
        Design.art = .klar
    }
}
#endif
