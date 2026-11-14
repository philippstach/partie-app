// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import SwiftUI
import UIKit
import KlarGlas
import SpieleKern
@testable import SpielYacht

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

/// Klar-Vergleich Designwechsel: Yacht-Würfel (`DieView`: unbekannt, frei, gehalten, Tipp) und `WuerfelBild` aus SpieleKern.
@MainActor
final class KlarWuerfelTests: XCTestCase {
    func testWuerfel() throws {
        try klarBilder("yacht-wuerfel", groesse: CGSize(width: 390, height: 300)) { szene }
    }

    /// Wertungsblock (`NeuBlock`) in klar: Spalte am Zug, gewähltes Feld, Vorschau.
    func testBlock() throws {
        var r = GameRecord(players: [Player(name: "Anna", avatar: "😎", colorIndex: 0), Player(name: "Ben", avatar: "🤠", colorIndex: 1), Player(name: "Clara", avatar: "🧠", colorIndex: 2)], settings: GameSettings())
        r.state.players[0].scores = [.ones: 3, .twos: 6, .threes: 9, .chance: 22]
        r.state.players[1].scores = [.ones: 2, .fours: 12, .chance: 18]
        r.state.players[2].scores = [.sixes: 18]
        r.state.dice = [3, 3, 3, 5, 6]
        r.state.rollsUsed = 2
        let record = r
        try klarBilder("yacht-block", groesse: CGSize(width: 390, height: 600)) { NeuBlock(record: record, gewaehlt: .constant(.threes), bedienbar: true) }
    }

    /// Würfelzone (`NeuWuerfelZone`) unter dem Block, mit zwei gehaltenen Würfeln.
    func testZone() throws {
        let verz = FileManager.default.temporaryDirectory.appending(path: "yacht-klar-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: verz) }
        let store = GameStore(repository: FileGameRepository(directory: verz))
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "dw-yacht-klar")!)
        var r = GameRecord(players: [Player(name: "Anna", avatar: "😎", colorIndex: 0), Player(name: "Ben", avatar: "🤠", colorIndex: 1)], settings: GameSettings())
        r.state.dice = [3, 3, 3, 5, 6]
        r.state.rollsUsed = 2
        r.held = [1, 3]
        let rec = r
        try klarBilder("yacht-zone", groesse: CGSize(width: 390, height: 300)) {
            NeuWuerfelZone(record: rec, kante: 52, gewaehlt: .constant(.threes), computerAmZug: false, wirbelnd: [], gezeigt: [1, 2, 3, 4, 5], rat: nil,
                           tippAn: .constant(false), wuerfeln: {}, eintragen: { _ in })
                .environment(store).environment(prefs)
        }
    }

    @ViewBuilder private var szene: some View {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) { ForEach(1...6, id: \.self) { DieView(value: $0, state: $0 == 3 ? .held : .free, size: 52) } }
                HStack(spacing: 10) { DieView(value: 1, state: .unknown); DieView(value: 4, state: .free, hinted: true); DieView(value: 6, state: .held, size: 40); DieView(value: 2, state: .free, size: 28) }
                HStack(spacing: 10) { ForEach(1...6, id: \.self) { WuerfelBild($0).font(.system(size: 40)).foregroundStyle(Color.appFlaeche) } }
                HStack(spacing: 10) { WuerfelBild(5).font(.largeTitle); WuerfelBild(2, gehalten: true).font(.title); WuerfelBild(6).font(.system(size: 54)).foregroundStyle(Color.secondary) }
            }
    }

    /// Dieselbe Szene in allen drei Designs (nur mit `DESIGN_BILDER`): `<design>-<hell|dunkel>-yacht-wuerfel.png`.
    func testDesignBogen() throws {
        guard let ziel = ProcessInfo.processInfo.environment["DESIGN_BILDER"], !ziel.isEmpty else { return }
        for design in DesignArt.allCases {
            for dunkel in [false, true] {
                Design.art = design
                let v = szene.padding(16).frame(width: CGSize(width: 390, height: 300).width, height: CGSize(width: 390, height: 300).height, alignment: .topLeading)
                    .background(Color.seitenGrund).designWurzel().environment(\.colorScheme, dunkel ? .dark : .light)
                let r = ImageRenderer(content: v); r.scale = 2
                let daten = try XCTUnwrap(r.uiImage?.pngData())
                try daten.write(to: URL(fileURLWithPath: ziel).appendingPathComponent("\(design.rawValue)-\(dunkel ? "dunkel" : "hell")-yacht-wuerfel.png"))
            }
        }
        Design.art = .klar
    }
}
#endif
