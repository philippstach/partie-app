// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Das Tagesrätsel: Stufe Mittel, der Seed ergibt sich aus dem Datum (Ortszeit).
enum DailyPuzzle {
    static let difficulty = Difficulty.medium

    /// Fester gregorianischer Kalender in Ortszeit: Schlüssel und Seed hängen nicht vom Gerätekalender ab
    static var gregorian: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        c.locale = .current
        return c
    }

    /// „2026-10-04“ für den Tag von `date` in der Ortszeit
    static func key(for date: Date, calendar: Calendar = DailyPuzzle.gregorian) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Seed aus dem Schlüssel: JJJJMMTT als Zahl
    static func seed(for key: String) -> UInt64 {
        UInt64(key.filter(\.isNumber)) ?? 0
    }

    static func date(from key: String, calendar: Calendar = DailyPuzzle.gregorian) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func puzzle(for key: String) -> Puzzle {
        Generator.generate(difficulty, seed: seed(for: key))
    }
}
