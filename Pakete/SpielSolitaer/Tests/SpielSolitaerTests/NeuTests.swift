// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Solitär: Texte, eigene Spielstände (Ordner `solitaer-neu`), Variantenwechsel über dasselbe `AppModel`.
@MainActor
final class NeuTests: XCTestCase {
    private func prefs() -> AppPreferences { AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!) }
    private func ordner() -> URL {
        let u = FileManager.default.temporaryDirectory.appending(path: "solitaer-neu-\(UUID().uuidString)", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    func testVariantenTexte() {
        XCTAssertEqual(NeuText.variante(.klondike(1)), String(localized: "Klondike · 1 Karte"))
        XCTAssertEqual(NeuText.variante(.klondike(3)), String(localized: "Klondike · 3 Karten"))
        XCTAssertEqual(NeuText.variante(.spider(1)), String(localized: "Spider · 1 Farbe"))
        XCTAssertEqual(NeuText.variante(.spider(4)), String(localized: "Spider · 4 Farben"))
        XCTAssertEqual(NeuText.variante(.freecell), GameKind.freecell.title)
    }

    func testEigenerOrdnerGetrenntVomAlten() {
        XCTAssertEqual(NeuWurzel.ordner.lastPathComponent, "solitaer-neu")
        XCTAssertNotEqual(NeuWurzel.ordner, AppModel.standardFolder)
        XCTAssertEqual(NeuText.kennung, "solitaer-neu")
    }

    func testAlleSiebenVariantenStartenUndSpeichernImNeuenOrdner() async throws {
        let dir = ordner()
        let app = AppModel(prefs: prefs(), stats: StatsStore(url: nil), folder: dir)
        for kind in GameKind.available {
            let mode: GameMode = switch kind {
            case .klondike: .klondike(3)
            case .spider: .spider(2)
            case .freecell: .freecell
            case .pyramid: .pyramid
            case .tripeaks: .tripeaks
            case .golf: .golf
            case .yukon: .yukon
            }
            app.switchTo(mode)
            XCTAssertEqual(app.session.mode.kind, kind)
            XCTAssertFalse(app.session.isWon)
        }
        await app.session.settleSaves()
        let dateien = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertTrue(dateien.contains { $0.hasPrefix("spiel-") }, "Spielstände liegen im eigenen Ordner")
    }

    func testTagesspielStartetMitDatum() {
        let app = AppModel(prefs: prefs(), stats: StatsStore(url: nil), folder: nil)
        app.startDaily(.now, kind: .spider)
        XCTAssertEqual(app.session.deal.kind, .daily)
        XCTAssertEqual(app.session.mode.kind, .spider)
        XCTAssertEqual(app.session.deal.day, DailyDate.string(.now))
    }

    func testNeuesSpielNachSiegGibtFrischePartie() {
        let app = AppModel(prefs: prefs(), stats: StatsStore(url: nil), folder: nil)
        app.switchTo(.klondike(1))
        let alt = app.session.deal
        app.newGame()
        XCTAssertEqual(app.session.moves, 0)
        XCTAssertNotEqual(app.session.deal.seed, alt.seed)
    }
}
