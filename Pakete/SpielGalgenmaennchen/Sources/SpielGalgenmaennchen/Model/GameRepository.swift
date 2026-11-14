// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Alles, was auf dem Gerät gespeichert wird. Fehlende Felder beim Laden → Standardwert.
struct SaveData: Codable, Equatable, Sendable {
    var version = 1
    /// Das laufende (oder gerade beendete) Spiel; es gibt immer nur eins
    var game: Game?
    var stats = Stats()
    /// Letzte 200 Lösungen je Sprache (Schlüssel `de` / `en`)
    var recent: [String: [String]] = [:]
    var lastCategory: Category?
    var lastDifficulty: Difficulty?
    var lastKids = false
    /// Fehler im letzten Einzelspieler-Sieg (hebt in der Statistik den Balken hervor)
    var lastWinMistakes: Int?
    /// Wort des Tages je Sprache (Schlüssel `de` / `en`); ein Eintrag von einem anderen Tag gilt als „noch nicht gespielt“
    var daily: [String: DailyEntry] = [:]
    var dailyStats = DailyStats()
    /// Erratene Lösungen je Sprache (Wortsammlung)
    var collection: [String: [String]] = [:]
    /// Kategorien, für die die Feier schon gezeigt wurde (je Sprache), damit sie sich nicht wiederholt
    var celebrated: [String: [String]] = [:]
    /// Die laufende Partie (Mehrspieler) und die zuletzt benutzten Namen
    var party: PartyMatch?
    var partyNames: [String] = []
    /// Die laufende Überleben-Serie und der Rekord (meiste gelöste Wörter einer Serie)
    var survival: SurvivalRun?
    var survivalBest = 0
    /// Freigeschaltete Erfolge (Kennungen)
    var achievements: [String] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        // Ein kaputtes Spiel wird verworfen, die Statistik bleibt.
        game = (try? c.decodeIfPresent(Game.self, forKey: .game)) ?? nil
        stats = (try? c.decodeIfPresent(Stats.self, forKey: .stats)) ?? Stats()
        recent = (try? c.decodeIfPresent([String: [String]].self, forKey: .recent)) ?? [:]
        lastCategory = (try? c.decodeIfPresent(Category.self, forKey: .lastCategory)) ?? nil
        lastDifficulty = (try? c.decodeIfPresent(Difficulty.self, forKey: .lastDifficulty)) ?? nil
        lastKids = (try? c.decodeIfPresent(Bool.self, forKey: .lastKids)) ?? false
        lastWinMistakes = (try? c.decodeIfPresent(Int.self, forKey: .lastWinMistakes)) ?? nil
        daily = (try? c.decodeIfPresent([String: DailyEntry].self, forKey: .daily)) ?? [:]
        dailyStats = (try? c.decodeIfPresent(DailyStats.self, forKey: .dailyStats)) ?? DailyStats()
        collection = (try? c.decodeIfPresent([String: [String]].self, forKey: .collection)) ?? [:]
        celebrated = (try? c.decodeIfPresent([String: [String]].self, forKey: .celebrated)) ?? [:]
        party = (try? c.decodeIfPresent(PartyMatch.self, forKey: .party)) ?? nil
        partyNames = (try? c.decodeIfPresent([String].self, forKey: .partyNames)) ?? []
        survival = (try? c.decodeIfPresent(SurvivalRun.self, forKey: .survival)) ?? nil
        survivalBest = (try? c.decodeIfPresent(Int.self, forKey: .survivalBest)) ?? 0
        achievements = (try? c.decodeIfPresent([String].self, forKey: .achievements)) ?? []
    }
}

/// Speichert als JSON in Application Support, atomar (erst neue Datei, dann tauschen).
struct GameRepository: Sendable {
    let url: URL

    init(url: URL = GameRepository.defaultURL) { self.url = url }

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "galgen.json")
    }

    func load() -> SaveData {
        guard let data = try? Data(contentsOf: url) else { return SaveData() }
        guard let decoded = try? JSONDecoder().decode(SaveData.self, from: data) else {
            // Beschädigte Datei sichern statt beim nächsten Speichern zu überschreiben
            let stamp = Int(Date().timeIntervalSince1970)
            let backup = url.deletingLastPathComponent().appending(path: "galgen.corrupt-\(stamp).json")
            try? FileManager.default.moveItem(at: url, to: backup)
            return SaveData()
        }
        return decoded
    }

    func save(_ data: SaveData) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: url, options: .atomic)
    }
}
