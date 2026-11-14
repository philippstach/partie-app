// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import KlarGlas
import SpieleKern
@testable import DesignBilder

/// Stufe D.3: Würfel-Bogen (Würfel des Designs in allen Augenzahlen, gehalten, unbekannt, drei Größen, auf Farbband, `WuerfelBild`, Schloss-Plakette).
@MainActor
class WuerfelBilder: XCTestCase {
    override func setUp() async throws {
        await MainActor.run {
            KlarGlasHaken.spielart = { .wuerfel }
            KlarGlasHaken.flaeche = { Gattung.wuerfel.farbe.color }
            KlarGlasHaken.accentText = { Gattung.wuerfel.farbe.textFarbe }
        }
    }
    override func tearDown() async throws { await MainActor.run { Design.art = .klar } }

    struct Bogen: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) { ForEach(1...6, id: \.self) { WuerfelFlaeche(augen: $0, groesse: 48) } }
                HStack(spacing: 10) { ForEach(1...6, id: \.self) { WuerfelFlaeche(augen: $0, gehalten: true, groesse: 48) } }
                HStack(spacing: 10) {
                    WuerfelFlaeche(augen: nil, groesse: 48); WuerfelFlaeche(augen: 5, groesse: 72); WuerfelFlaeche(augen: 3, groesse: 30)
                    WuerfelFlaeche(augen: 6, gehalten: true, groesse: 48).overlay(alignment: .topTrailing) { WuerfelSchloss(groesse: 48).offset(x: 5, y: -5) }
                }
                // Würfelzone: Farbband in der Spielart-Farbe (Salon), sonst auf dem Grund
                HStack(spacing: 10) { ForEach([2, 6, 4, 1, 5], id: \.self) { WuerfelFlaeche(augen: $0, gehalten: $0 == 6, groesse: 52, aufBand: true) } }
                    .padding(14).frame(maxWidth: .infinity)
                    .background(Design.ist(.salon) ? (Design.spielFarben?.flaeche ?? Color.clear) : Color.clear)
                HStack(spacing: 10) { ForEach(1...6, id: \.self) { WuerfelBild($0).font(.system(size: 34)) } }
                HStack(spacing: 14) { WuerfelBild(5).font(.largeTitle); WuerfelBild(2, gehalten: true).font(.title); WuerfelBild(6).font(.system(size: 54)) }
            }
            .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    func testWuerfelBogen() {
        XCTAssertEqual(Aufnahme.alle("wuerfel", groesse: CGSize(width: 390, height: 560)) { Bogen() }, [])
    }
}
#endif
