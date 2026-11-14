// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ein Kalendertag ohne Uhrzeit und Zeitzone („2026-10-04“).
struct Day: Hashable, Codable, Comparable, Sendable, CustomStringConvertible {
    var year: Int
    var month: Int
    var day: Int

    init(_ year: Int, _ month: Int, _ day: Int) { self.year = year; self.month = month; self.day = day }

    /// „yyyy-MM-dd“
    init?(_ string: String) {
        let p = string.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        self.init(p[0], p[1], p[2])
    }

    /// Lokaler Kalendertag des Zeitpunkts
    init(_ date: Date, calendar: Calendar = .current) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(c.year!, c.month!, c.day!)
    }

    var description: String { String(format: "%04d-%02d-%02d", year, month, day) }

    /// Tage seit 1970-01-01 (proleptisch gregorianisch, ohne Zeitzonen)
    var number: Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let doy = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146097 + doe - 719468
    }

    init(number z: Int) {
        let z = z + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let doe = z - era * 146097
        let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        self.init(yoe + era * 400 + (m <= 2 ? 1 : 0), m, d)
    }

    /// Mittag dieses Tages im Kalender (für Anzeige)
    func date(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? Date()
    }

    func adding(days: Int) -> Day { Day(number: number + days) }

    static func < (a: Day, b: Day) -> Bool { a.number < b.number }
}

/// Rätsel des Tages und Serie.
enum Daily {
    /// Tag 0 des Tagespakets: 01.01.2026
    static let start = Day(2026, 1, 1)

    /// Index im Tagespaket: Tage seit 01.01.2026, immer positiv modulo `count`.
    static func index(day: Day, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (((day.number - start.number) % count) + count) % count
    }

    static func index(date: Date, count: Int, calendar: Calendar = .current) -> Int {
        index(day: Day(date, calendar: calendar), count: count)
    }

    /// Gelöste Tagesrätsel am Stück bis heute. Ist heute noch offen, zählt die Serie ab gestern.
    static func streak(solved: Set<Day>, today: Day) -> Int {
        var day = solved.contains(today) ? today : today.adding(days: -1)
        var n = 0
        while solved.contains(day) { n += 1; day = day.adding(days: -1) }
        return n
    }

    /// Beste Serie aller Zeiten in einer Menge gelöster Tage
    static func bestStreak(solved: Set<Day>) -> Int {
        var best = 0, run = 0
        var previous: Int?
        for d in solved.map(\.number).sorted() {
            run = (previous == d - 1) ? run + 1 : 1
            previous = d
            best = max(best, run)
        }
        return best
    }
}
