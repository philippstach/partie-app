// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Philipps Daten dürfen beim Umbau nicht verloren gehen: Tests mit echten Dateien im alten Format.
@MainActor
final class MigrationTests: XCTestCase {
    /// Alte `spiel.json` (vor dem Umbau): `deal` kennt nur `draw`, keinen Modus.
    private let altesSpiel = """
    {"version":1,
     "state":{"draw":3,"stock":[5,9],"waste":[20],"fan":1,"foundation":[2,0,0,0],
       "cols":[{"down":[],"up":[30]},{"down":[],"up":[]},{"down":[],"up":[]},{"down":[],"up":[]},{"down":[],"up":[]},{"down":[],"up":[]},{"down":[],"up":[]}],
       "score":35,"moves":12,"passes":1},
     "deal":{"seed":462,"draw":3,"kind":"solvable"},
     "history":[],"elapsed":123.5,"recentSeeds":[462]}
    """

    /// Alte `statistik.json`: `one`/`three`, flache Tagesspiel-Listen
    private let alteStatistik = """
    {"version":1,
     "one":{"played":42,"won":27,"streak":3,"bestStreak":7,"bestTime":212,"fewestMoves":104,"highScore":812},
     "three":{"played":15,"won":4,"streak":0,"bestStreak":2},
     "dailyWon":["2026-10-03","2026-10-04"],"dailyStarted":["2026-10-05"]}
    """

    private func tempFolder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "migration-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func prefs() -> AppPreferences { AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!) }

    func testAlterSpielstandWandertInDenModus() throws {
        let folder = try tempFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        try altesSpiel.write(to: folder.appending(path: "spiel.json"), atomically: true, encoding: .utf8)
        let p = prefs()

        let app = AppModel(prefs: p, stats: StatsStore(url: nil), folder: folder)

        let store = try XCTUnwrap(app.klondikeStore)
        XCTAssertEqual(store.mode, .klondike(3))
        XCTAssertEqual(store.deal.seed, 462)
        XCTAssertEqual(store.deal.kind, .solvable)
        XCTAssertEqual(store.state.moves, 12)
        XCTAssertEqual(store.state.score, 35)
        XCTAssertEqual(store.state.foundation, [2, 0, 0, 0])
        XCTAssertEqual(store.elapsed, 123.5)
        XCTAssertEqual(p.lastModeKey, "klondike3")                         // die App öffnet dort, wo Philipp war
        XCTAssertFalse(FileManager.default.fileExists(atPath: folder.appending(path: "spiel.json").path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appending(path: "spiel-klondike3.json").path))
    }

    func testNeuerSpielstandBleibtUnangetastet() throws {
        let folder = try tempFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let neu = folder.appending(path: "spiel-klondike3.json")
        try "{\"marker\":true}".write(to: neu, atomically: true, encoding: .utf8)
        try altesSpiel.write(to: folder.appending(path: "spiel.json"), atomically: true, encoding: .utf8)
        XCTAssertNil(LegacyMigration.migrateSavedGame(in: folder))
        XCTAssertEqual(try String(contentsOf: neu, encoding: .utf8), "{\"marker\":true}")
        XCTAssertTrue(FileManager.default.fileExists(atPath: folder.appending(path: "spiel.json").path))   // alte Datei bleibt
    }

    func testSpeichernNachUebernahmeUndNeuStart() async throws {
        let folder = try tempFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        try altesSpiel.write(to: folder.appending(path: "spiel.json"), atomically: true, encoding: .utf8)
        let p = prefs()
        let app = AppModel(prefs: p, stats: StatsStore(url: nil), folder: folder)
        let store = try XCTUnwrap(app.klondikeStore)
        store.drawStock()
        await store.settleSaves()
        // zweiter Start: lädt die Partie aus dem neuen Platz
        let app2 = AppModel(prefs: p, stats: StatsStore(url: nil), folder: folder)
        XCTAssertEqual(app2.klondikeStore?.state, store.state)
        XCTAssertEqual(app2.klondikeStore?.deal.seed, 462)
    }

    func testAlteStatistikWirdUebernommenUndGesichert() throws {
        let folder = try tempFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appending(path: "statistik.json")
        try alteStatistik.write(to: url, atomically: true, encoding: .utf8)

        let stats = StatsStore(url: url)

        XCTAssertEqual(stats.stats(mode: .klondike(1)).played, 42)
        XCTAssertEqual(stats.stats(mode: .klondike(1)).won, 27)
        XCTAssertEqual(stats.stats(mode: .klondike(1)).bestTime, 212)
        XCTAssertEqual(stats.stats(mode: .klondike(1)).highScore, 812)
        XCTAssertEqual(stats.stats(mode: .klondike(3)).played, 15)
        XCTAssertNil(stats.stats(mode: .klondike(3)).bestTime)
        XCTAssertEqual(stats.data.dailyWon, ["2026-10-03", "2026-10-04"])
        XCTAssertEqual(stats.data.dailyStarted, ["2026-10-05"])
        XCTAssertEqual(stats.data.daily["klondike"]?.won.count, 2)
        // Sicherung der Originaldatei und neues Format auf der Platte
        XCTAssertEqual(try String(contentsOf: folder.appending(path: "statistik-v1.json"), encoding: .utf8), alteStatistik)
        XCTAssertEqual(StatsStore(url: url).data, stats.data)
        let json = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(json.contains("\"modes\""))
        XCTAssertFalse(json.contains("\"one\""))
    }

    func testStatistikJeModusGetrennt() {
        let s = StatsStore(url: nil)
        let k1 = DealInfo(seed: 1, mode: .klondike(1), kind: .solvable)
        let k3 = DealInfo(seed: 2, mode: .klondike(3), kind: .solvable)
        s.handle(.started(k1)); s.handle(.won(k1, moves: 90, score: 500, seconds: 100))
        s.handle(.started(k3))
        XCTAssertEqual(s.stats(mode: .klondike(1)).won, 1)
        XCTAssertEqual(s.stats(mode: .klondike(3)).played, 1)
        XCTAssertEqual(s.stats(mode: .klondike(3)).won, 0)
        XCTAssertEqual(s.data.modes.keys.sorted(), ["klondike1", "klondike3"])
    }

    func testPartieOhnePunkteVeraendertHoechstePunkteNicht() {
        let s = StatsStore(url: nil)
        let deal = DealInfo(seed: 1, mode: .klondike(1), kind: .solvable)
        s.handle(.won(deal, moves: 50, score: nil, seconds: 60))
        XCTAssertNil(s.stats(mode: .klondike(1)).highScore)
        XCTAssertEqual(s.stats(mode: .klondike(1)).fewestMoves, 50)
    }

    func testAlterDealMitDrawWirdZumModus() throws {
        let deal = try JSONDecoder().decode(DealInfo.self, from: Data("{\"seed\":7,\"draw\":3,\"kind\":\"random\"}".utf8))
        XCTAssertEqual(deal.mode, .klondike(3))
        let neu = try JSONDecoder().decode(DealInfo.self, from: JSONEncoder().encode(DealInfo(seed: 9, mode: .klondike(1), kind: .daily, day: "2026-10-05")))
        XCTAssertEqual(neu, DealInfo(seed: 9, mode: .klondike(1), kind: .daily, day: "2026-10-05"))
    }
}
