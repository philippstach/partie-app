// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// S10 Sanfte Serie: gelöste Tagesrätsel-Tage rückwärts ab heute.
/// Ein einzelner verpasster Tag ist ein Ruhetag (zählt nicht, bricht nicht), zwei verpasste Tage hintereinander beenden die Serie.
/// Heute noch offen bricht nichts. Berechnet aus `Stats.dailySolved`, ohne eigene Speicherung.
struct DailyStreak: Equatable, Sendable {
    var length: Int
    /// Heute noch offen und gestern verpasst, die Serie lebt aber noch
    var resting: Bool
    /// Ruhetage innerhalb der Serie („JJJJ-MM-TT“)
    var restDays: Set<String>

    static let none = DailyStreak(length: 0, resting: false, restDays: [])

    static func compute(solved: Set<String>, today: String, calendar: Calendar = DailyPuzzle.gregorian) -> DailyStreak {
        guard let todayDate = DailyPuzzle.date(from: today, calendar: calendar) else { return .none }
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: todayDate) ?? todayDate }
        func key(_ d: Date) -> String { DailyPuzzle.key(for: d, calendar: calendar) }

        let todaySolved = solved.contains(today)
        let resting = !todaySolved && !solved.contains(key(day(-1)))
        var offset = todaySolved ? 0 : -1
        var length = 0, gap = 0
        var pendingRest: String?
        var restDays = Set<String>()
        while true {
            let current = day(offset)
            let k = key(current)
            if solved.contains(k) {
                length += 1
                gap = 0
                if let rest = pendingRest { restDays.insert(rest); pendingRest = nil }
            } else {
                gap += 1
                if gap == 1 { pendingRest = k }
                if gap >= 2 { break }
            }
            offset -= 1
            if length == 0, gap >= 1, offset < -3 { break }
        }
        return DailyStreak(length: length, resting: resting && length > 0, restDays: length > 0 ? restDays : [])
    }

    /// Beste Serie aller Zeiten: die längste Serie, die an irgendeinem gelösten Tag endete.
    /// F6: ein Durchlauf über die sortierten Tage (statt für jeden Tag die Serie neu zu berechnen). Zwei gelöste Tage gehören zur selben
    /// Serie, wenn höchstens ein Tag dazwischen fehlt (der Ruhetag); das ist dieselbe Regel wie in `compute`.
    static func best(solved: Set<String>, calendar: Calendar = DailyPuzzle.gregorian) -> Int {
        let days = solved.compactMap { DailyPuzzle.date(from: $0, calendar: calendar) }.sorted()
        var best = 0, current = 0
        var previous: Date?
        for day in days {
            if let previous, let gap = calendar.dateComponents([.day], from: previous, to: day).day, gap <= 2 {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }
}
