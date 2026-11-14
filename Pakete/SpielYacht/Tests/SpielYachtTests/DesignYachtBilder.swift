// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
@testable import SpielYacht

/// Designwechsel D.4: Yacht-Wertungsblock (`NeuBlock`) in allen drei Designs, hell und dunkel (nur mit `DESIGN_BILDER`, sonst kein Bild).
@MainActor
final class DesignYachtBilder: XCTestCase {
    private func record() -> GameRecord {
        var r = GameRecord(players: [Player(name: "Anna", avatar: "😎", colorIndex: 0), Player(name: "Ben", avatar: "🤠", colorIndex: 1), Player(name: "Clara", avatar: "🧠", colorIndex: 2)],
                           settings: GameSettings())
        r.state.players[0].scores = [.ones: 3, .twos: 6, .threes: 9, .chance: 22]
        r.state.players[1].scores = [.ones: 2, .fours: 12, .chance: 18]
        r.state.players[2].scores = [.sixes: 18]
        r.state.dice = [3, 3, 3, 5, 6]
        r.state.rollsUsed = 2
        return r
    }

    override func setUp() async throws {
        await MainActor.run {
            // Wie in der App mit offenem Würfelspiel: Spielart-Farben und Spielart-Text
            KlarGlasHaken.spielart = { .wuerfel }
            KlarGlasHaken.flaeche = { Gattung.wuerfel.farbe.color }
            KlarGlasHaken.accentText = { Gattung.wuerfel.farbe.textFarbe }
        }
    }

    /// Ganzer Spielbildschirm von unten: Wertungsblock und die echte Würfelzone (Farbband in Salon).
    func testSpielbild() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        let verz = FileManager.default.temporaryDirectory.appending(path: "yacht-bild-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: verz) }
        let store = GameStore(repository: FileGameRepository(directory: verz))
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "dw-yacht-bild")!)
        var r = record()
        r.held = [1, 3]
        let rec = r
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = VStack(spacing: 0) {
                    NeuBlock(record: rec, gewaehlt: .constant(.threes), bedienbar: true).padding(.horizontal, 12)
                    NeuWuerfelZone(record: rec, kante: 52, gewaehlt: .constant(.threes), computerAmZug: false, wirbelnd: [], gezeigt: [1, 2, 3, 4, 5], rat: nil,
                                   tippAn: .constant(false), wuerfeln: {}, eintragen: { _ in })
                }
                .environment(store).environment(prefs)
                .frame(width: 390, height: 780).background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let img = ImageRenderer(content: v); img.scale = 2
                let daten = try XCTUnwrap(img.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-yacht-spiel.png"))
            }
        }
        Design.art = .klar
    }

    func testBlock() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = NeuBlock(record: record(), gewaehlt: .constant(.threes), bedienbar: true).padding(12)
                    .frame(width: 390, height: 600).background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-yacht-block.png"))
            }
        }
        Design.art = .klar
    }
}
#endif
