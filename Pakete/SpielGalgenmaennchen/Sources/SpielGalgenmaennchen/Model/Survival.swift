// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Eine Überleben-Serie: mehrere Wörter hintereinander mit begrenzten Leben.
/// Jedes Wort ist ein normales Spiel mit 8 Ballons; verloren = ein Leben weg, sehr gut gelöst = ein Leben dazu.
/// Reine Logik: Stufe, Leben, Zähler.
struct SurvivalRun: Codable, Equatable, Sendable {
    static let startLives = 3
    static let maxLives = 5
    /// Ein Sieg mit höchstens so vielen Fehlern (ohne Hinweis) bringt ein Leben zurück
    static let bonusMistakes = 1

    var lives = SurvivalRun.startLives
    /// Gelöste Wörter dieser Serie
    var wins = 0
    /// Gespielte Wörter dieser Serie (gelöst und verloren)
    var played = 0

    init() {}

    /// Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lives = min(Self.maxLives, max(0, try c.decodeIfPresent(Int.self, forKey: .lives) ?? Self.startLives))
        wins = max(0, try c.decodeIfPresent(Int.self, forKey: .wins) ?? 0)
        played = max(wins, try c.decodeIfPresent(Int.self, forKey: .played) ?? 0)
    }

    var isOver: Bool { lives <= 0 }

    /// Stufe des nächsten Wortes: 3 leichte, dann 4 mittlere, danach nur noch schwere
    var nextDifficulty: Difficulty {
        switch wins {
        case ..<3: .easy
        case ..<7: .medium
        default: .hard
        }
    }

    /// Wort beendet. Gibt zurück, ob dabei ein Leben dazukam.
    @discardableResult
    mutating func finishWord(won: Bool, mistakes: Int, hints: Int) -> Bool {
        played += 1
        guard won else {
            lives = max(0, lives - 1)
            return false
        }
        wins += 1
        guard mistakes <= Self.bonusMistakes, hints == 0, lives < Self.maxLives else { return false }
        lives += 1
        return true
    }
}
