// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ein Eintrag je beendeter Partie (Sieg, Niederlage, Aufgeben) – für Verlauf und „Deine besten 10“.
struct HistoryEntry: Codable, Equatable {
    /// „2026-10-06“
    var date: String
    /// `GameMode.key`
    var mode: String
    var level: Int?
    var won: Bool
    var time: Double?
    var moves: Int?
    var score: Int?
    /// Nummer der Partie (nur nummerierte Partien, sonst nil)
    var number: Int?

    init(date: String, mode: String, level: Int? = nil, won: Bool, time: Double? = nil, moves: Int? = nil, score: Int? = nil, number: Int? = nil) {
        self.date = date; self.mode = mode; self.level = level; self.won = won; self.time = time; self.moves = moves; self.score = score; self.number = number
    }

    // Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        date = try c.decodeIfPresent(String.self, forKey: .date) ?? ""
        mode = try c.decodeIfPresent(String.self, forKey: .mode) ?? ""
        level = try c.decodeIfPresent(Int.self, forKey: .level)
        won = try c.decodeIfPresent(Bool.self, forKey: .won) ?? false
        time = try c.decodeIfPresent(Double.self, forKey: .time)
        moves = try c.decodeIfPresent(Int.self, forKey: .moves)
        score = try c.decodeIfPresent(Int.self, forKey: .score)
        number = try c.decodeIfPresent(Int.self, forKey: .number)
    }
    private enum Key: String, CodingKey { case date, mode, level, won, time, moves, score, number }
}

/// Eine Woche (Montag-Beginn je nach Kalender) mit Siegen und Niederlagen
struct WeekBucket: Equatable, Identifiable {
    var start: Date
    var wins: Int
    var losses: Int
    var id: Date { start }
}

/// Reine Auswertungen des Verlaufs
enum StatsHistory {
    static let limit = 2000
    static let weeks = 8
    static let recentWins = 20
    static let minGames = 3

    /// Neuen Eintrag anhängen; die ältesten fallen heraus (höchstens 2.000)
    static func append(_ entry: HistoryEntry, to list: inout [HistoryEntry]) {
        list.append(entry)
        if list.count > limit { list.removeFirst(list.count - limit) }
    }

    static func entries(_ list: [HistoryEntry], mode: GameMode) -> [HistoryEntry] { list.filter { $0.mode == mode.key } }

    /// Siege und Niederlagen der letzten 8 Wochen (die letzte Woche enthält `today`), älteste zuerst
    static func weekly(_ list: [HistoryEntry], mode: GameMode, today: Date = .now, calendar: Calendar = .solitaer) -> [WeekBucket] {
        let thisWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let starts = (0..<weeks).reversed().map { calendar.date(byAdding: .weekOfYear, value: -$0, to: thisWeek)! }
        var buckets = starts.map { WeekBucket(start: $0, wins: 0, losses: 0) }
        for e in entries(list, mode: mode) {
            guard let d = DailyDate.date(e.date, calendar: calendar), let week = calendar.dateInterval(of: .weekOfYear, for: d)?.start,
                  let i = buckets.firstIndex(where: { $0.start == week }) else { continue }
            if e.won { buckets[i].wins += 1 } else { buckets[i].losses += 1 }
        }
        return buckets
    }

    /// Zeiten der letzten 20 Siege (älteste zuerst)
    static func recentWinTimes(_ list: [HistoryEntry], mode: GameMode) -> [Double] {
        Array(entries(list, mode: mode).filter { $0.won }.compactMap(\.time).suffix(recentWins))
    }

    /// „Deine besten 10“: schnellste Siege, bei gleicher Zeit der frühere zuerst
    static func top10(_ list: [HistoryEntry], mode: GameMode) -> [HistoryEntry] {
        let wins = entries(list, mode: mode).enumerated().filter { $0.element.won && $0.element.time != nil }
        return Array(wins.sorted { ($0.element.time!, $0.offset) < ($1.element.time!, $1.offset) }.prefix(10).map(\.element))
    }

    /// Genug Partien für ein Diagramm?
    static func hasEnough(_ list: [HistoryEntry], mode: GameMode) -> Bool { entries(list, mode: mode).count >= minGames }
}
