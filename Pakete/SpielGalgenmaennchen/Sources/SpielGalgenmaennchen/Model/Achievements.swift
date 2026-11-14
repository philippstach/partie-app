// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Erfolge. Werden aus dem Spielstand berechnet und einmal freigeschaltet; Zurücksetzen der Statistik nimmt sie nicht weg.
enum Achievement: String, CaseIterable, Codable, Sendable {
    case firstWin, wins10, wins50
    case perfect1, perfect10
    case streak5, streak10
    case lastBalloon, hardWins5
    case daily7, categoryFull
    case survival5, survival10

    func isEarned(in data: SaveData) -> Bool {
        let s = data.stats
        switch self {
        case .firstWin: return s.won >= 1
        case .wins10: return s.won >= 10
        case .wins50: return s.won >= 50
        case .perfect1: return s.perfect >= 1
        case .perfect10: return s.perfect >= 10
        case .streak5: return s.bestStreak >= 5
        case .streak10: return s.bestStreak >= 10
        case .lastBalloon: return s.distribution[7] >= 1
        case .hardWins5: return s[.hard].won >= 5
        case .daily7: return data.dailyStats.bestStreak >= 7
        case .categoryFull: return data.celebrated.values.contains { !$0.isEmpty }
        case .survival5: return data.survivalBest >= 5
        case .survival10: return data.survivalBest >= 10
        }
    }

    /// Neu erreichte Erfolge, die noch nicht gespeichert sind
    static func newlyEarned(in data: SaveData) -> [Achievement] {
        allCases.filter { !data.achievements.contains($0.rawValue) && $0.isEarned(in: data) }
    }
}
