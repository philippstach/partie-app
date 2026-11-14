// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Eine Frage, die der Spieler zum Melden vorgemerkt hat (nur lokal, kein Server).
struct FlaggedClue: Codable, Equatable, Identifiable, Sendable {
    var id: String { "\(puzzleID)|\(clue)" }
    var puzzleID: String
    var clue: String
    var answer: String
    var date: String
}

/// Alles, was auf dem Gerät gespeichert wird.
struct SaveData: Codable, Equatable, Sendable {
    var version = 1
    var game: Game?
    var stats = Stats()
    /// Gelöste Rätsel-IDs je Paket („leicht“, „mittel“, „schwer“)
    var solved: [String: Set<String>] = [:]
    var flagged: [FlaggedClue] = []
    /// Beste Lösungszeit je Rätsel-ID
    var times: [String: Double] = [:]
    /// Erreichte Erfolge (einmal erreicht = bleibt)
    var achieved: [String] = []
    /// Tag, an dem zuletzt ein Stufen-Vorschlag je Stufe gezeigt wurde (höchstens einmal je Stufe und Tag)
    var suggestionDays: [String: String] = [:]

    init() {}

    /// Fehlende oder beschädigte Felder bekommen Standardwerte – ein kaputtes Feld darf nie den ganzen Spielstand kosten.
    init(from decoder: Decoder) throws {
        let k = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? k.decodeIfPresent(Int.self, forKey: .version)) ?? 1
        game = (try? k.decodeIfPresent(Game.self, forKey: .game)) ?? nil
        stats = (try? k.decodeIfPresent(Stats.self, forKey: .stats)) ?? Stats()
        solved = (try? k.decodeIfPresent([String: Set<String>].self, forKey: .solved)) ?? [:]
        flagged = (try? k.decodeIfPresent([FlaggedClue].self, forKey: .flagged)) ?? []
        times = (try? k.decodeIfPresent([String: Double].self, forKey: .times)) ?? [:]
        achieved = (try? k.decodeIfPresent([String].self, forKey: .achieved)) ?? []
        suggestionDays = (try? k.decodeIfPresent([String: String].self, forKey: .suggestionDays)) ?? [:]
    }
}

/// Speichert als JSON in Application Support (atomar).
struct GameRepository: Sendable {
    let url: URL

    init(url: URL = GameRepository.defaultURL) { self.url = url }

    static var defaultURL: URL {
        URL.applicationSupportDirectory.appending(path: "kreuzwort.json")
    }

    /// Lädt den Spielstand. Fehlt die Datei, beginnt ein leerer Stand. Ist sie unlesbar, bleibt eine Kopie
    /// (`kreuzwort.json.beschaedigt`) liegen, damit der nächste Speichervorgang sie nicht überschreibt.
    func load() -> SaveData {
        guard let data = try? Data(contentsOf: url) else { return SaveData() }
        if let decoded = try? JSONDecoder().decode(SaveData.self, from: data) { return decoded }
        let backup = url.appendingPathExtension("beschaedigt")
        try? FileManager.default.removeItem(at: backup)
        try? FileManager.default.copyItem(at: url, to: backup)
        return SaveData()
    }

    func save(_ data: SaveData) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: url, options: .atomic)
    }
}
