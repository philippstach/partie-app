// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
@testable import SpielSolitaer

/// Zeichnet eine Ansicht in „Klar & Glas“ (hell und dunkel) als PNG nach `$KLAR_ZIEL` (Umgebungsvariable `TEST_RUNNER_KLAR_ZIEL`).
/// Ohne Ziel schreibt der Test nichts. Läuft unverändert im alten und im neuen Stand (Werkzeug/designwechsel_klar_vergleich_davor.sh).
@MainActor
private func klarBilder<V: View>(_ name: String, groesse: CGSize, _ ansicht: () -> V) throws {
    guard let ziel = ProcessInfo.processInfo.environment["KLAR_ZIEL"], !ziel.isEmpty else { return }
    try FileManager.default.createDirectory(atPath: ziel, withIntermediateDirectories: true)
    for dunkel in [false, true] {
        let v = ansicht().padding(16).frame(width: groesse.width, height: groesse.height, alignment: .topLeading)
            .background(Color(.systemGroupedBackground)).environment(\.colorScheme, dunkel ? .dark : .light)
        let r = ImageRenderer(content: v); r.scale = 2
        let daten = try XCTUnwrap(r.uiImage?.pngData(), "kein Bild: \(name)")
        try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(name)-\(dunkel ? "dunkel" : "hell").png"))
        print("BILD \(name)-\(dunkel ? "dunkel" : "hell")")
    }
}

/// Klar-Vergleich Designwechsel: Solitär-Karten (Vorderseiten, Bildkarten mit Gold-Rahmen und Krone, Pik-Ass mit Goldring,
/// Standard-Rücken und gewählter Rücken, leerer Platz, Vierfarb-Karte, kleine und verdeckte Karte, Karte im großen Index).
@MainActor
final class KlarKartenTests: XCTestCase {
    func testSolitaerKarten() throws {
        try klarBilder("solitaer", groesse: CGSize(width: 390, height: 520)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) { ForEach([CardFace(rank: 1, suit: .spades), CardFace(rank: 10, suit: .hearts), CardFace(rank: 7, suit: .diamonds), CardFace(rank: 4, suit: .clubs)], id: \.self) { CardFaceView(face: $0, width: 76) } }
                HStack(spacing: 8) { ForEach([CardFace(rank: 11, suit: .hearts), CardFace(rank: 12, suit: .spades), CardFace(rank: 13, suit: .diamonds), CardFace(rank: 1, suit: .hearts)], id: \.self) { CardFaceView(face: $0, width: 76) } }
                HStack(spacing: 8) {
                    CardBackView(width: 76); CardBackView(width: 76, style: .navy); CardBackView(width: 76, style: .bordeaux); CardBackView(width: 76, style: .retro)
                }
                HStack(alignment: .top, spacing: 8) {
                    SlotView(size: CGSize(width: 76, height: 106), symbol: "suit.spade.fill")
                    CardFaceView(face: CardFace(rank: 9, suit: .clubs), width: 44, fourColor: true)
                    CardFaceView(face: CardFace(rank: 13, suit: .hearts), width: 38)
                    CardFaceView(face: CardFace(rank: 12, suit: .diamonds), width: 76, covered: true)
                    CardFaceView(face: CardFace(rank: 8, suit: .diamonds), width: 76, fourColor: true).environment(\.largeCardIndex, true)
                }
            }
        }
    }

    /// Tisch (`TableBackground`) in den Standard-Tischen und einer Jahreszeit, mit Plätzen darauf.
    func testTische() throws {
        try klarBilder("solitaer-tische", groesse: CGSize(width: 390, height: 300)) {
            VStack(spacing: 8) {
                ForEach([TableStyle.linen, .felt, .navy, .slate, .spring], id: \.self) { stil in
                    HStack(spacing: 8) { SlotView(size: CGSize(width: 40, height: 56), symbol: "suit.heart.fill", tint: stil.tint); CardFaceView(face: CardFace(rank: 5, suit: .hearts), width: 40) }
                        .frame(maxWidth: .infinity, minHeight: 50).background(TableBackground(style: stil))
                }
            }
        }
    }
}
#endif
