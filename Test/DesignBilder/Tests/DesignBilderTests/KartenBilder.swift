// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
@testable import DesignBilder

/// Stufe D: Kartenset-Bogen in drei Designs, hell und dunkel.
@MainActor
class KartenBilder: XCTestCase {
    override func setUp() async throws {
        await MainActor.run {
            KlarGlasHaken.spielart = { .karten }
            KlarGlasHaken.flaeche = { Gattung.karten.farbe.color }
            KlarGlasHaken.accentText = { Gattung.karten.farbe.textFarbe }
        }
    }
    override func tearDown() async throws { await MainActor.run { Design.art = .klar } }

    /// Eigene Kartenzeichner (Rommé, Mogeln) über `kartenPapier`: normal, gewählt, klein.
    func testEigeneKarten() {
        struct Reihe: View {
            func karte(_ n: String, _ s: String, rot: Bool, gewaehlt: Bool = false, klein: Bool = false) -> some View {
                VStack(spacing: 0) {
                    Text(verbatim: n).font(.system(klein ? .footnote : .title3, design: Design.zahlDesign).weight(.bold))
                    Text(verbatim: s).font(.system(klein ? Font.TextStyle.subheadline : .title3))
                }
                .foregroundStyle(KartenStil.aktuell.farbe(rot: rot))
                .frame(width: klein ? 30 : 46, height: klein ? 44 : 66)
                .kartenPapier(ecke: 7, breite: klein ? 30 : 46, gewaehlt: gewaehlt)
                .offset(y: gewaehlt ? -8 : 0)
            }
            var body: some View {
                HStack(spacing: 8) {
                    karte("K", "♥", rot: true); karte("7", "♠", rot: false); karte("10", "♦", rot: true, gewaehlt: true); karte("A", "♣", rot: false)
                    karte("3", "♥", rot: true, klein: true); karte("Q", "♠", rot: false, klein: true)
                }.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        XCTAssertEqual(Aufnahme.alle("karten-eigen", groesse: CGSize(width: 390, height: 120)) { Reihe() }, [])
    }

    func testKartenBogen() {
        _ = Aufnahme.bild(KartenBogen(), design: .klar, dunkel: false, groesse: CGSize(width: 390, height: 640))   // der erste ImageRenderer richtet unter Mac Catalyst die App-Umgebung ein
        XCTAssertEqual(Aufnahme.alle("karten", groesse: CGSize(width: 390, height: 640)) { KartenBogen() }, [])
    }
}
#endif
