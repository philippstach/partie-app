// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
@testable import SpielSolitaer

/// Designwechsel D.2: Bogen der Solitär-Karten in drei Designs, hell und dunkel (nur wenn `DESIGN_BILDER` gesetzt ist, sonst nur ein Lauf ohne Datei).
/// Aufruf: Werkzeug/designwechsel_bilder.sh solitaer
@MainActor
final class DesignKartenBilder: XCTestCase {
    struct Bogen: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    ForEach([CardFace(rank: 1, suit: .spades), CardFace(rank: 10, suit: .hearts), CardFace(rank: 7, suit: .diamonds), CardFace(rank: 4, suit: .clubs)], id: \.self) { CardFaceView(face: $0, width: 76) }
                }
                HStack(spacing: 8) {
                    ForEach([CardFace(rank: 11, suit: .hearts), CardFace(rank: 12, suit: .spades), CardFace(rank: 13, suit: .diamonds), CardFace(rank: 1, suit: .hearts)], id: \.self) { CardFaceView(face: $0, width: 76) }
                }
                HStack(spacing: 8) {
                    CardBackView(width: 76)
                    CardBackView(width: 76, style: .navy)
                    SlotView(size: CGSize(width: 76, height: 106), symbol: "suit.spade.fill")
                    CardFaceView(face: CardFace(rank: 9, suit: .clubs), width: 44, fourColor: true)
                    CardFaceView(face: CardFace(rank: 13, suit: .hearts), width: 38)
                }
            }
            .padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    /// Standard-Tisch (Leinen) mit Plätzen, Karten und Text in den drei Designs (Salon: helle Schrift auf der Spielart-Farbe).
    func testTisch() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        KlarGlasHaken.spielart = { .karten }
        KlarGlasHaken.flaeche = { Gattung.karten.farbe.color }
        KlarGlasHaken.accentText = { Gattung.karten.farbe.textFarbe }
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let stil = TableStyle.linen
                let v = VStack(spacing: 18) {
                    Text(verbatim: "Klondike · Züge 14 · 2:31").font(.headline).foregroundStyle(stil.tint)
                    HStack(spacing: 8) { ForEach(Array(0..<4), id: \.self) { _ in SlotView(size: CGSize(width: 70, height: 98), symbol: "suit.spade.fill", tint: stil.tint) } }
                    HStack(alignment: .top, spacing: 8) {
                        CardBackView(width: 70)
                        CardFaceView(face: CardFace(rank: 5, suit: .hearts), width: 70)
                        CardFaceView(face: CardFace(rank: 12, suit: .spades), width: 70)
                        SlotView(size: CGSize(width: 70, height: 98), tint: stil.tint)
                    }
                }
                .padding(20).frame(width: 390, height: 360).background(TableBackground(style: stil)).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-solitaer-tisch.png"))
            }
        }
        Design.art = .klar
    }

    func testBogen() throws {
        let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"]
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = Bogen().frame(width: 390, height: 420).background(design == .klar ? Color(.systemGroupedBackground) : Color.seitenGrund)
                    .designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let bild = try XCTUnwrap(r.uiImage)
                if let ziel, let d = bild.pngData() {
                    try d.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-solitaer-karten.png"))
                }
            }
        }
        Design.art = .klar
    }
}
#endif
