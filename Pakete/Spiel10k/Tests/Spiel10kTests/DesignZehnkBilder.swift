// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
@testable import Spiel10k

/// Designwechsel D.4: 10k-Spielbild (neue Fassung) in drei Designs, hell und dunkel (nur mit `DESIGN_BILDER`).
@MainActor
final class DesignZehnkBilder: XCTestCase {
    func testSpielbild() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        KlarGlasHaken.spielart = { .wuerfel }
        KlarGlasHaken.flaeche = { Gattung.wuerfel.farbe.color }
        KlarGlasHaken.accentText = { Gattung.wuerfel.farbe.textFarbe }
        let defaults = UserDefaults(suiteName: "dw-zehnk-bild")!
        let store = GameStore(repository: NurSpeicher(), defaults: defaults)
        var queue = [5, 5, 1, 3, 2, 6]
        store.roller = { queue.isEmpty ? 2 : queue.removeFirst() }
        var s = GameSettings(); s.nextPlayerOverlay = false
        store.startGame(players: [Player(name: "Anna", avatar: "😎", colorIndex: 0), Player(name: "Ben", avatar: "🤠", colorIndex: 1), Player(name: "Clara", avatar: "🧠", colorIndex: 2)], settings: s)
        store.roll()
        let prefs = AppPreferences(defaults: defaults)
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = NeuSpielView(abbrechen: {}).environment(store).environment(prefs)
                    .frame(width: 390, height: 844).background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-zehnk-spiel.png"))
            }
        }
        Design.art = .klar
    }
}

private final class NurSpeicher: GameRepository {
    var records: [UUID: GameRecord] = [:]
    func loadAll() -> [GameRecord] { Array(records.values) }
    func save(_ record: GameRecord) throws { records[record.id] = record }
    func delete(id: UUID) throws { records[id] = nil }
}
#endif
