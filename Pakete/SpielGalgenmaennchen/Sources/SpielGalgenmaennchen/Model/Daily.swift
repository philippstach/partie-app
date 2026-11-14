// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ein Tag als Text „JJJJ-MM-TT“ in der Ortszeit des Geräts.
enum DayKey {
    static func string(for date: Date, calendar: Calendar? = nil) -> String {
        // Immer gregorianisch, sonst bekommen Geräte mit anderem Kalender ein anderes Tageswort
        var greg = Calendar(identifier: .gregorian)
        greg.timeZone = .current
        let c = (calendar ?? greg).dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }

    /// Bestandteile (Jahr, Monat, Tag) oder nil bei kaputtem Text
    static func parts(_ day: String) -> (y: Int, m: Int, d: Int)? {
        let p = day.split(separator: "-").compactMap { Int($0) }
        return p.count == 3 ? (p[0], p[1], p[2]) : nil
    }

    /// Seed des Tageswortes: das Datum als Zahl JJJJMMTT
    static func seed(_ day: String) -> UInt64 {
        guard let p = parts(day) else { return 0 }
        return UInt64(p.y * 10000 + p.m * 100 + p.d)
    }

    /// Der Tag davor (rechnet im gregorianischen Kalender ohne Zeitzone, also ohne Sommerzeit-Fehler)
    static func previous(_ day: String) -> String {
        guard let p = parts(day) else { return day }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        guard let noon = cal.date(from: DateComponents(year: p.y, month: p.m, day: p.d, hour: 12)),
              let before = cal.date(byAdding: .day, value: -1, to: noon) else { return day }
        return string(for: before, calendar: cal)
    }

    /// Für die Anzeige („5. Okt.“), in der Sprache der App
    static func displayDate(_ day: String) -> String {
        guard let p = parts(day),
              let date = Calendar.current.date(from: DateComponents(year: p.y, month: p.m, day: p.d, hour: 12)) else { return day }
        return date.formatted(.dateTime.day().month(.abbreviated))
    }

    /// Sekunden bis Mitternacht (Ortszeit)
    static func secondsUntilTomorrow(from now: Date, calendar: Calendar = .current) -> Int {
        let start = calendar.startOfDay(for: now)
        guard let next = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }
        return max(0, Int(next.timeIntervalSince(now)))
    }
}

/// Das Wort des Tages: für alle gleich, gewählt aus den Wörtern bis Stufe 2.
enum DailyWord {
    static let maxDifficulty = 2

    /// `kandidaten[SplitMix64(JJJJMMTT).index(anzahl)]`, Kandidaten in Listenreihenfolge
    static func word(day: String, in words: [Word]) -> Word? {
        let candidates = words.filter { $0.difficulty.rawValue <= maxDifficulty }
        guard !candidates.isEmpty else { return nil }
        var rng = SplitMix64(seed: DayKey.seed(day))
        return candidates[rng.index(candidates.count)]
    }
}

/// Tageswort-Spielstand eines Tages und einer Sprache
struct DailyEntry: Codable, Equatable, Sendable {
    var day: String
    var game: Game
}

/// Eigene Statistik des Tageswortes (für beide Sprachen zusammen). Gezählt wird das erste Ergebnis eines Tages.
struct DailyStats: Codable, Equatable, Sendable {
    var played = 0
    var won = 0
    var streak = 0
    var bestStreak = 0
    var lastWin: String?
    var lastDay: String?

    init() {}

    /// Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        played = try c.decodeIfPresent(Int.self, forKey: .played) ?? 0
        won = try c.decodeIfPresent(Int.self, forKey: .won) ?? 0
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        lastWin = try c.decodeIfPresent(String.self, forKey: .lastWin)
        lastDay = try c.decodeIfPresent(String.self, forKey: .lastDay)
    }

    /// Sieg direkt nach einem Sieg gestern = Serie + 1, sonst 1. Niederlage = 0. Ein zweites Ergebnis am selben Tag zählt nicht.
    mutating func record(won isWin: Bool, day: String) {
        guard lastDay != day else { return }
        played += 1
        lastDay = day
        if isWin {
            won += 1
            streak = lastWin == DayKey.previous(day) ? streak + 1 : 1
            bestStreak = max(bestStreak, streak)
            lastWin = day
        } else {
            streak = 0
        }
    }

    /// Die angezeigte Serie ist 0, wenn der letzte Sieg vor gestern war.
    func displayedStreak(today: String) -> Int {
        guard let lastWin, lastWin == today || lastWin == DayKey.previous(today) else { return 0 }
        return streak
    }
}

/// Der Text zum Teilen (nur Text, ohne das Wort). Die Sprache folgt der App, nicht dem Wort.
enum DailyShare {
    static func text(day: String, mistakes: Int, hints: Int, won: Bool, appLanguage: WordLanguage) -> String {
        let m = min(max(mistakes, 0), 8)
        let balloons = won ? String(repeating: "🎈", count: 8 - m) + String(repeating: "💥", count: m)
                           : String(repeating: "💥", count: 8)
        let title: String, result: String
        switch appLanguage {
        case .de:
            let date = DayKey.parts(day).map { String(format: "%02d.%02d.%04d", $0.d, $0.m, $0.y) } ?? day
            title = "Galgenmännchen – Wort des Tages \(date)"
            result = won ? (m == 0 ? "Erraten ohne Fehler" : "Erraten mit \(m) \(m == 1 ? "Fehler" : "Fehlern")") : "Nicht erraten"
            return [title, balloons, result + (hints > 0 ? " · \(hints) \(hints == 1 ? "Hinweis" : "Hinweise")" : "")]
                .joined(separator: "\n")
        case .es:
            title = "Galgenmännchen – Palabra del día \(day)"
            result = won ? (m == 0 ? "Acertada sin fallos" : "Acertada con \(m) \(m == 1 ? "fallo" : "fallos")") : "No acertada"
            return [title, balloons, result + (hints > 0 ? " · \(hints) \(hints == 1 ? "pista" : "pistas")" : "")]
                .joined(separator: "\n")
        case .fr:
            title = "Galgenmännchen – Mot du jour \(day)"
            result = won ? (m == 0 ? "Trouvé sans erreur" : "Trouvé avec \(m) \(m == 1 ? "erreur" : "erreurs")") : "Pas trouvé"
            return [title, balloons, result + (hints > 0 ? " · \(hints) \(hints == 1 ? "indice" : "indices")" : "")]
                .joined(separator: "\n")
        case .en:
            title = "Galgenmännchen – Word of the Day \(day)"
            result = won ? (m == 0 ? "Solved without mistakes" : "Solved with \(m) \(m == 1 ? "mistake" : "mistakes")") : "Not solved"
            return [title, balloons, result + (hints > 0 ? " · \(hints) \(hints == 1 ? "hint" : "hints")" : "")]
                .joined(separator: "\n")
        }
    }
}
