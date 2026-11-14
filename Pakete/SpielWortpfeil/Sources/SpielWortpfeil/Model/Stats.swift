// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

extension KeyedDecodingContainer {
    /// Fehlende oder beschädigte Werte ergeben den Standardwert – ein kaputtes Feld kostet nicht den ganzen Spielstand.
    func lenient<T: Decodable>(_ type: T.Type, _ key: Key, default value: T) -> T {
        (try? decode(type, forKey: key)) ?? value
    }
}

struct LevelStats: Codable, Equatable, Sendable {
    var played = 0
    var won = 0
    var wonWithoutHelp = 0
    var bestTime: Double?
    var totalTime: Double = 0
    /// Zeiten der letzten 20 gelösten Rätsel (neueste zuletzt) für die Zeitkurve
    var recent: [Double] = []

    var averageTime: Double? { won > 0 ? totalTime / Double(won) : nil }

    init() {}

    init(from decoder: Decoder) throws {
        let k = try decoder.container(keyedBy: CodingKeys.self)
        played = k.lenient(Int.self, .played, default: 0)
        won = k.lenient(Int.self, .won, default: 0)
        wonWithoutHelp = k.lenient(Int.self, .wonWithoutHelp, default: 0)
        bestTime = k.lenient(Double?.self, .bestTime, default: nil)
        totalTime = k.lenient(Double.self, .totalTime, default: 0)
        recent = k.lenient([Double].self, .recent, default: [])
    }

    /// Trägt einen Sieg ein; gibt zurück, ob es eine neue Bestzeit ist (nicht beim ersten Sieg der Stufe).
    @discardableResult
    mutating func recordWin(time: Double, withoutHelp: Bool) -> Bool {
        won += 1
        if withoutHelp { wonWithoutHelp += 1 }
        totalTime += time
        recent.append(time)
        if recent.count > 20 { recent.removeFirst(recent.count - 20) }
        let isBest = bestTime.map { time < $0 } ?? false
        if bestTime == nil || time < bestTime! { bestTime = time }
        return isBest
    }
}

struct Stats: Codable, Equatable, Sendable {
    private var byLevel: [String: LevelStats] = [:]
    /// Gelöste Tagesrätsel („2026-10-04“)
    var dailySolved: Set<String> = []
    /// Davon ohne Hilfe gelöst (Stern im Kalender)
    var dailyNoHelp: Set<String> = []
    /// Nachgeholte Tage (Archiv): zählen nicht zur Serie, im Kalender ein hohler Haken
    var dailyCatchUp: Set<String> = []
    /// Lösungszeit je Tagesrätsel in Sekunden
    var dailyTimes: [String: Double] = [:]
    var bestStreak = 0
    /// Gelöste Themen-Rätsel (zählen in „Gelöst“ und für Erfolge, nicht für Stufen-Fortschritt oder Serie)
    var themeWon = 0
    /// Hilfen der zuletzt gelösten Stufen-Rätsel je Stufe (neueste zuletzt) für den Stufen-Vorschlag
    var recentHints: [String: [Int]] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        let k = try decoder.container(keyedBy: CodingKeys.self)
        byLevel = k.lenient([String: LevelStats].self, .byLevel, default: [:])
        dailySolved = k.lenient(Set<String>.self, .dailySolved, default: [])
        dailyNoHelp = k.lenient(Set<String>.self, .dailyNoHelp, default: [])
        dailyCatchUp = k.lenient(Set<String>.self, .dailyCatchUp, default: [])
        dailyTimes = k.lenient([String: Double].self, .dailyTimes, default: [:])
        bestStreak = k.lenient(Int.self, .bestStreak, default: 0)
        themeWon = k.lenient(Int.self, .themeWon, default: 0)
        recentHints = k.lenient([String: [Int]].self, .recentHints, default: [:])
    }

    subscript(_ l: Level) -> LevelStats {
        get { byLevel[l.rawValue] ?? LevelStats() }
        set { byLevel[l.rawValue] = newValue }
    }

    var totalPlayed: Int { Level.allCases.reduce(0) { $0 + self[$1].played } }
    var totalWon: Int { Level.allCases.reduce(0) { $0 + self[$1].won } + themeWon }

    /// Durchschnittszeit über alle Stufen
    var averageTime: Double? {
        // Themen-Siege tragen keine Zeit bei, zählen also nicht in den Teiler
        let won = totalWon - themeWon
        return won > 0 ? Level.allCases.reduce(0) { $0 + self[$1].totalTime } / Double(won) : nil
    }

    var dailyDays: Set<Day> { Set(dailySolved.compactMap(Day.init)) }

    /// Tage, die für die Serie zählen (ohne nachgeholte)
    var streakDays: Set<Day> { Set(dailySolved.subtracting(dailyCatchUp).compactMap(Day.init)) }

    func streak(today: Day) -> Int { Daily.streak(solved: streakDays, today: today) }
}

/// Ergebnis eines gelösten Rätsels für den Gewonnen-Bildschirm.
struct WinResult: Equatable, Sendable {
    var level: Level
    var time: Double
    var hints: Int
    var isNewBest: Bool
    var isDaily: Bool
    var streak: Int
    /// Themen-Rätsel: id des Themas
    var themeID: String?
    /// Neu erreichte Erfolge (ids)
    var newAchievements: [String] = []
    /// Angebot einer anderen Stufe (Lernkurve)
    var suggestion: Level?
    /// Mit diesem Sieg ist die ganze Stufe gelöst
    var levelCompleted = false
}
