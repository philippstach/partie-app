// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
@testable import Spiel10k

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

/// Klar-Vergleich Designwechsel: 10k-Würfel (`DieView`: unbekannt, frei, gewählt, rausgelegt, Tipp).
@MainActor
final class KlarWuerfelTests: XCTestCase {
    func testWuerfel() throws {
        try klarBilder("zehnk-wuerfel", groesse: CGSize(width: 390, height: 200)) { szene }
    }

    @ViewBuilder private var szene: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) { ForEach(1...6, id: \.self) { DieView(value: $0, state: $0 == 2 ? .selected : ($0 == 5 ? .locked : .free)) } }
                HStack(spacing: 10) { DieView(value: 1, state: .unknown); DieView(value: 4, state: .free, hinted: true, size: 40); DieView(value: 6, state: .locked, size: 22) }
            }
    }

    /// Dieselbe Szene in allen drei Designs (nur mit `DESIGN_BILDER`): `<design>-<hell|dunkel>-zehnk-wuerfel.png`.
    func testDesignBogen() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = szene.padding(16).frame(width: CGSize(width: 390, height: 200).width, height: CGSize(width: 390, height: 200).height, alignment: .topLeading)
                    .background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-zehnk-wuerfel.png"))
            }
        }
        Design.art = .klar
    }

    /// Klar-Vergleich: 10k-Spielbild (neue Fassung) mit Spielerleiste und Zugkarte, nach einem festen Wurf.
    func testSpielbild() throws {
        KlarGlasHaken.spielart = { .wuerfel }
        KlarGlasHaken.flaeche = { Gattung.wuerfel.farbe.color }
        KlarGlasHaken.accentText = { Gattung.wuerfel.farbe.textFarbe }
        let defaults = UserDefaults(suiteName: "klar-zehnk-bild")!
        let store = GameStore(repository: KlarNurSpeicher(), defaults: defaults)
        var queue = [5, 5, 1, 3, 2, 6]
        store.roller = { queue.isEmpty ? 2 : queue.removeFirst() }
        var s = GameSettings(); s.nextPlayerOverlay = false
        store.startGame(players: [Player(name: "Anna", avatar: "😎", colorIndex: 0), Player(name: "Ben", avatar: "🤠", colorIndex: 1), Player(name: "Clara", avatar: "🧠", colorIndex: 2)], settings: s)
        store.roll()
        let prefs = AppPreferences(defaults: defaults)
        try klarBilder("zehnk-spiel", groesse: CGSize(width: 390, height: 844)) { NeuSpielView(abbrechen: {}).environment(store).environment(prefs) }
    }
}

private final class KlarNurSpeicher: GameRepository {
    var records: [UUID: GameRecord] = [:]
    func loadAll() -> [GameRecord] { Array(records.values) }
    func save(_ record: GameRecord) throws { records[record.id] = record }
    func delete(id: UUID) throws { records[id] = nil }
}
#endif
