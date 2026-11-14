// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

struct DifficultyStats: Codable, Equatable, Sendable {
    var played = 0
    var won = 0

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        played = try c.decodeIfPresent(Int.self, forKey: .played) ?? 0
        won = try c.decodeIfPresent(Int.self, forKey: .won) ?? 0
    }
}

enum StatsEvent: Equatable, Sendable {
    case won(difficulty: Difficulty, mistakes: Int, hints: Int)
    case lost(difficulty: Difficulty, mistakes: Int, hints: Int)
    /// Neues Spiel gestartet, obwohl das alte lief
    case abandoned(difficulty: Difficulty, guessedCount: Int)
}

/// Statistik nur für Einzelspieler, über beide Sprachen zusammen. Fehlende Felder beim Laden → Standardwert.
struct Stats: Codable, Equatable, Sendable {
    var played = 0
    var won = 0
    var streak = 0
    var bestStreak = 0
    /// Siege ohne Fehler und ohne Hinweis
    var perfect = 0
    /// Siege nach Anzahl Fehler 0…7
    var distribution = [Int](repeating: 0, count: 8)
    private var byDifficulty: [String: DifficultyStats] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        played = try c.decodeIfPresent(Int.self, forKey: .played) ?? 0
        won = try c.decodeIfPresent(Int.self, forKey: .won) ?? 0
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        perfect = try c.decodeIfPresent(Int.self, forKey: .perfect) ?? 0
        let d = try c.decodeIfPresent([Int].self, forKey: .distribution) ?? []
        distribution = (0..<8).map { $0 < d.count ? d[$0] : 0 }
        byDifficulty = try c.decodeIfPresent([String: DifficultyStats].self, forKey: .byDifficulty) ?? [:]
    }

    subscript(_ d: Difficulty) -> DifficultyStats {
        get { byDifficulty[String(d.rawValue)] ?? DifficultyStats() }
        set { byDifficulty[String(d.rawValue)] = newValue }
    }

    var winRate: Double { played > 0 ? Double(won) / Double(played) : 0 }

    mutating func record(_ event: StatsEvent) {
        switch event {
        case let .won(difficulty, mistakes, hints):
            PartieMeldung.einzel(spiel: "galgenmaennchen", gewonnen: true)
            played += 1; won += 1; streak += 1
            bestStreak = max(bestStreak, streak)
            distribution[min(max(mistakes, 0), 7)] += 1
            if mistakes == 0 && hints == 0 { perfect += 1 }
            self[difficulty].played += 1
            self[difficulty].won += 1
        case let .lost(difficulty, _, _):
            PartieMeldung.einzel(spiel: "galgenmaennchen", gewonnen: false)
            played += 1; streak = 0
            self[difficulty].played += 1
        case let .abandoned(difficulty, guessedCount):
            // Ohne Rateversuch zählt es gar nicht, sonst als verloren: so rettet Abbrechen keine Serie.
            guard guessedCount > 0 else { return }
            record(.lost(difficulty: difficulty, mistakes: 0, hints: 0))
        }
    }
}
