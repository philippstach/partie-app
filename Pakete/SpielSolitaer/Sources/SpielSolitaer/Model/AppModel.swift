// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Das gerade offene Spiel. Jede Variante bringt ihren eigenen, typisierten Store mit.
enum ActiveGame {
    case klondike(GameStore<KlondikeRules>)
    case spider(GameStore<SpiderRules>)
    case freecell(GameStore<FreeCellRules>)
    case pyramid(GameStore<PyramidRules>)
    case tripeaks(GameStore<TriPeaksRules>)
    case golf(GameStore<GolfRules>)
    case yukon(GameStore<YukonRules>)

    var session: any GameSession {
        switch self {
        case let .klondike(store): store
        case let .spider(store): store
        case let .freecell(store): store
        case let .pyramid(store): store
        case let .tripeaks(store): store
        case let .golf(store): store
        case let .yukon(store): store
        }
    }
}

/// Hält je Modus ein Spiel (`spiel-<key>.json`) und das aktive. Beim Start öffnet die App den zuletzt gespielten Modus.
/// Wer zwischen Modi wechselt, findet jede Partie so vor, wie er sie verlassen hat.
@MainActor
@Observable
final class AppModel {
    let prefs: AppPreferences
    let stats: StatsStore
    private(set) var active: ActiveGame
    /// Nur Speicherort: `nil` = nichts speichern (Tests, Demo)
    private let folder: URL?
    private var games: [String: ActiveGame] = [:]

    nonisolated static var standardFolder: URL {
        let folder = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    init(prefs: AppPreferences = AppPreferences(), stats: StatsStore, folder: URL? = AppModel.standardFolder, seed: UInt64? = nil) {
        self.prefs = prefs
        self.stats = stats
        self.folder = folder
        // Philipps bisherige Partie (spiel.json) wandert in den Platz ihres Modus; die App öffnet dort
        if let folder, let migrated = LegacyMigration.migrateSavedGame(in: folder) { prefs.lastModeKey = migrated.key }
        let mode = Self.mode(forKey: prefs.lastModeKey)
        let game = Self.makeGame(mode: mode, prefs: prefs, stats: stats, seed: seed, url: folder.map { Self.url(in: $0, mode: mode) })
        active = game
        games[mode.key] = game
        // Allererster Start: die erste Partie ist immer „Leicht“
        if folder != nil, seed == nil, !prefs.welcomeSeen, game.session.moves == 0 {
            var rng = SystemRandomNumberGenerator()
            if let first = DealCatalog.shared.pick(mode: mode, level: 1, recent: [], using: &rng) {
                game.session.start(DealInfo(seed: first, mode: mode, kind: .solvable))
            }
        }
    }

    nonisolated static func url(in folder: URL, mode: GameMode) -> URL { folder.appending(path: "spiel-\(mode.key).json") }

    /// Modus zu einem gespeicherten Schlüssel; Unbekanntes → Klondike mit 1 Karte
    static func mode(forKey key: String) -> GameMode {
        switch key {
        case "klondike3": .klondike(3)
        case "spider1": .spider(1)
        case "spider2": .spider(2)
        case "spider4": .spider(4)
        case "freecell": .freecell
        case "pyramid": .pyramid
        case "tripeaks": .tripeaks
        case "golf": .golf
        case "yukon": .yukon
        default: .klondike(1)
        }
    }

    /// Statistik und Erfolge an die Ereignisse eines Spiels hängen; neue Kettenabzeichen erscheinen als Kapsel über dem Tisch
    private static func wire<R: SolitaireRules>(_ store: GameStore<R>, stats: StatsStore) {
        store.onEvent = { [stats, weak store] event in
            stats.handle(event)
            if case .chain = event, let new = stats.lastChainAchievements.first { store?.showToast("🏅 " + new.title) }
        }
    }

    private static func makeGame(mode: GameMode, prefs: AppPreferences, stats: StatsStore, seed: UInt64? = nil, url: URL?) -> ActiveGame {
        switch mode.kind {
        case .spider:
            let store = GameStore<SpiderRules>(mode: mode, prefs: prefs, seed: seed, url: url)
            Self.wire(store, stats: stats)
            return .spider(store)
        case .freecell:
            let store = GameStore<FreeCellRules>(mode: mode, prefs: prefs, seed: seed, url: url)
            Self.wire(store, stats: stats)
            return .freecell(store)
        case .pyramid:
            let store = GameStore<PyramidRules>(mode: mode, prefs: prefs, seed: seed, url: url)
            Self.wire(store, stats: stats)
            return .pyramid(store)
        case .tripeaks:
            let store = GameStore<TriPeaksRules>(mode: mode, prefs: prefs, seed: seed, url: url)
            Self.wire(store, stats: stats)
            return .tripeaks(store)
        case .golf:
            let store = GameStore<GolfRules>(mode: mode, prefs: prefs, seed: seed, url: url)
            Self.wire(store, stats: stats)
            return .golf(store)
        case .yukon:
            let store = GameStore<YukonRules>(mode: mode, prefs: prefs, seed: seed, url: url)
            Self.wire(store, stats: stats)
            return .yukon(store)
        default:
            let store = GameStore<KlondikeRules>(mode: mode, prefs: prefs, seed: seed, url: url)
            Self.wire(store, stats: stats)
            return .klondike(store)
        }
    }

    /// Der Klondike-Store, wenn Klondike gerade offen ist
    var klondikeStore: GameStore<KlondikeRules>? {
        if case let .klondike(store) = active { store } else { nil }
    }

    /// Der Spider-Store, wenn Spider gerade offen ist
    var spiderStore: GameStore<SpiderRules>? {
        if case let .spider(store) = active { store } else { nil }
    }

    /// Der FreeCell-Store, wenn FreeCell gerade offen ist
    var freecellStore: GameStore<FreeCellRules>? {
        if case let .freecell(store) = active { store } else { nil }
    }

    /// Der Pyramid-Store, wenn Pyramid gerade offen ist
    var pyramidStore: GameStore<PyramidRules>? {
        if case let .pyramid(store) = active { store } else { nil }
    }

    /// Der TriPeaks-Store, wenn TriPeaks gerade offen ist
    var tripeaksStore: GameStore<TriPeaksRules>? {
        if case let .tripeaks(store) = active { store } else { nil }
    }

    /// Der Yukon-Store, wenn Yukon gerade offen ist
    var yukonStore: GameStore<YukonRules>? {
        if case let .yukon(store) = active { store } else { nil }
    }

    /// Der Golf-Store, wenn Golf gerade offen ist
    var golfStore: GameStore<GolfRules>? {
        if case let .golf(store) = active { store } else { nil }
    }

    /// Das gemeinsame Gesicht des aktiven Spiels für Kopfzeile, Leiste, Sieg und Menü
    var session: any GameSession { active.session }

    // MARK: Spiel wechseln und starten

    private func game(for mode: GameMode) -> ActiveGame {
        if let game = games[mode.key] { return game }
        let game = Self.makeGame(mode: mode, prefs: prefs, stats: stats, url: folder.map { Self.url(in: $0, mode: mode) })
        games[mode.key] = game
        return game
    }

    private func activate(_ game: ActiveGame, mode: GameMode) {
        active = game
        prefs.lastModeKey = mode.key
    }

    /// Modus, den „Neues Spiel“ im gerade offenen Spiel startet (Einstellungen: Zieh-Art bzw. Farben)
    var newGameMode: GameMode {
        switch active {
        case .klondike: prefs.klondikeMode
        case .spider: prefs.spiderMode
        case .freecell: .freecell
        case .pyramid: .pyramid
        case .tripeaks: .tripeaks
        case .golf: .golf
        case .yukon: .yukon
        }
    }

    /// „Neues Spiel“: im gewählten Modus des offenen Spiels. Die laufende Partie eines anderen Modus bleibt gespeichert.
    func newGame() {
        let mode = newGameMode
        let game = game(for: mode)
        activate(game, mode: mode)
        game.session.newGame()
    }

    /// Zu einem Modus wechseln: Eine gespeicherte Partie geht weiter, sonst wird neu ausgeteilt.
    func switchTo(_ mode: GameMode) {
        let hadFile = folder.map { FileManager.default.fileExists(atPath: Self.url(in: $0, mode: mode).path) } ?? false
        let game = game(for: mode)
        activate(game, mode: mode)
        if !hadFile && games[mode.key] != nil && folder == nil { game.session.newGame() }
        else if !hadFile { game.session.newGame() }
    }

    /// „Partie wählen…“: lösbare Partie mit dieser Nummer im Modus (Nummern siehe `DealCatalog`). false = ungültige Nummer.
    @discardableResult
    func startNumbered(_ number: Int, mode: GameMode) -> Bool {
        guard let seed = DealCatalog.shared.seed(mode: mode, number: number) else { return false }
        let game = game(for: mode)
        activate(game, mode: mode)
        game.session.start(DealInfo(seed: seed, mode: mode, kind: .solvable))
        return true
    }

    /// Läuft in diesem Modus gerade eine angefangene, nicht gewonnene Partie? (für „Weiterspielen“ in der Übersicht)
    /// Legt keine Spiele an und liest nichts von der Platte: nur für bereits geöffnete Spiele; sonst `runningKeys`.
    func isRunning(_ mode: GameMode) -> Bool {
        guard let s = games[mode.key]?.session else { return false }
        return s.moves > 0 && !s.isWon && !s.gaveUp
    }

    /// Schlüssel der Modi, in denen eine angefangene, nicht gewonnene Partie wartet. Gespeicherte Partien werden außerhalb des
    /// Haupt-Threads gelesen (nicht beim Zeichnen der Übersicht); geöffnete Spiele zählen mit ihrem aktuellen Stand.
    func runningKeys(for modes: [GameMode]) async -> Set<String> {
        var out = Set<String>()
        for mode in modes {
            if games[mode.key] != nil {
                if isRunning(mode) { out.insert(mode.key) }
            } else if let folder {
                let url = Self.url(in: folder, mode: mode)
                let kind = mode.kind
                let running = await Task.detached(priority: .userInitiated) { Self.savedRunning(kind, url: url) }.value
                if running { out.insert(mode.key) }
            }
        }
        return out
    }

    nonisolated private static func savedRunning<R: SolitaireRules>(_ rules: R.Type, url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url), let file = try? JSONDecoder().decode(SaveFile<R.State>.self, from: data) else { return false }
        return file.state.moves > 0 && !file.state.isWon && !file.gaveUp
    }

    nonisolated private static func savedRunning(_ kind: GameKind, url: URL) -> Bool {
        switch kind {
        case .klondike: savedRunning(KlondikeRules.self, url: url)
        case .spider: savedRunning(SpiderRules.self, url: url)
        case .freecell: savedRunning(FreeCellRules.self, url: url)
        case .pyramid: savedRunning(PyramidRules.self, url: url)
        case .tripeaks: savedRunning(TriPeaksRules.self, url: url)
        case .golf: savedRunning(GolfRules.self, url: url)
        case .yukon: savedRunning(YukonRules.self, url: url)
        }
    }

    /// „Gleiche Partie neu“: im Modus der laufenden Partie
    func restartSameDeal() { session.restartSameDeal() }

    /// Tagesspiel: Klondike immer 1 Karte, Spider immer 2 Farben, FreeCell nach Nummer, Pyramid aus seiner Liste
    /// `level`: nil = Gemischt (das Tagesspiel mit Ziel), 1 = Leicht, 3 = Schwer (nur Klondike und Spider)
    func startDaily(_ date: Date, kind: GameKind = .klondike, level: Int? = nil, calendar: Calendar = .solitaer) {
        let level = DealCatalog.hasDailyLevels(kind) ? level : nil
        guard let seed = DealCatalog.shared.dailySeed(for: date, kind: kind, level: level, calendar: calendar) else { return }
        let mode: GameMode = switch kind {
        case .spider: .spider(2)
        case .freecell: .freecell
        case .pyramid: .pyramid
        case .tripeaks: .tripeaks
        case .golf: .golf
        case .yukon: .yukon
        case .klondike: .klondike(1)
        }
        let game = game(for: mode)
        activate(game, mode: mode)
        game.session.start(DealInfo(seed: seed, mode: mode, kind: .daily, day: DailyDate.string(date, calendar: calendar), dailyLevel: level))
    }
}

/// Übernahme alter Dateien beim Umbau auf mehrere Spiele. Alte Datei erst löschen, wenn die neue sicher geschrieben ist.
enum LegacyMigration {
    /// `spiel.json` → `spiel-klondike<Zieh-Art>.json`. Liefert den Modus der übernommenen Partie, sonst nil.
    /// Gibt es den neuen Platz schon, bleibt alles, wie es ist.
    @discardableResult
    static func migrateSavedGame(in folder: URL) -> GameMode? {
        let old = folder.appending(path: "spiel.json")
        guard let data = try? Data(contentsOf: old),
              var file = try? JSONDecoder().decode(SaveFile<GameState>.self, from: data) else { return nil }
        let mode = GameMode.klondike(file.state.draw)
        let new = AppModel.url(in: folder, mode: mode)
        guard !FileManager.default.fileExists(atPath: new.path) else { return nil }
        file.deal.mode = mode
        guard let fresh = try? JSONEncoder().encode(file),
              (try? fresh.write(to: new, options: .atomic)) != nil,
              let check = try? Data(contentsOf: new),
              (try? JSONDecoder().decode(SaveFile<GameState>.self, from: check)) != nil else { return nil }
        try? FileManager.default.removeItem(at: old)
        return mode
    }
}
