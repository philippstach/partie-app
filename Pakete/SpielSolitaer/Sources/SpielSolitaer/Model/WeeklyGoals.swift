// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Wochenziele (BACKLOG N4): Jede Woche (Montag bis Sonntag, Ortszeit) 3 Ziele aus 12. Gezählt wird ab Montag 0:00.
struct WeeklyGoal: Equatable, Identifiable {
    let id: String
    let count: Int

    var title: String {
        switch id {
        case "siege": String(localized: "10 Partien gewinnen")
        case "siegeSpider": String(localized: "3 Spider-Partien gewinnen")
        case "siegeFreeCell": String(localized: "3 FreeCell-Partien gewinnen")
        case "siegePyramid": String(localized: "2 Pyramid-Partien gewinnen")
        case "siegeTriPeaks": String(localized: "3 TriPeaks-Partien gewinnen")
        case "ohneTipp": String(localized: "3 Siege ohne Tipp")
        case "ohneZurueck": String(localized: "2 Siege ohne Rückgängig")
        case "schwer": String(localized: "1 schwere Partie gewinnen")
        case "tagesspiele": String(localized: "An 4 Tagen das Tagesspiel gewinnen")
        case "kronen": String(localized: "2 Kronen holen")
        case "unter5Min": String(localized: "2 Siege in unter 5 Minuten")
        default: String(localized: "2 Siege mit „3 Karten ziehen“")
        }
    }
}

/// Fortschritt der laufenden Woche (wird beim Wochenwechsel neu begonnen)
struct WeekProgress: Codable, Equatable {
    /// Montag der Woche, „2026-10-05“
    var monday = ""
    var wins = 0
    var spider = 0, freecell = 0, pyramid = 0, tripeaks = 0
    var noHint = 0, noUndo = 0, hard = 0, under5 = 0, threeCards = 0, crowns = 0
    /// Verschiedene Tage, an denen das Tagesspiel (Gemischt) gewonnen wurde
    var dailyDays: Set<String> = []
    /// Ziele, die diese Woche schon als „erreicht“ gemeldet wurden
    var reached: Set<String> = []

    init() {}

    // Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        func int(_ k: Key) -> Int { (try? c.decodeIfPresent(Int.self, forKey: k)) ?? 0 }
        monday = try c.decodeIfPresent(String.self, forKey: .monday) ?? ""
        wins = int(.wins); spider = int(.spider); freecell = int(.freecell); pyramid = int(.pyramid); tripeaks = int(.tripeaks)
        noHint = int(.noHint); noUndo = int(.noUndo); hard = int(.hard); under5 = int(.under5); threeCards = int(.threeCards); crowns = int(.crowns)
        dailyDays = try c.decodeIfPresent(Set<String>.self, forKey: .dailyDays) ?? []
        reached = try c.decodeIfPresent(Set<String>.self, forKey: .reached) ?? []
    }
    private enum Key: String, CodingKey {
        case monday, wins, spider, freecell, pyramid, tripeaks, noHint, noUndo, hard, under5, threeCards, crowns, dailyDays, reached
    }
}

enum WeeklyGoals {
    /// Feste Liste von 12 (Reihenfolge = Reihenfolge der Regeltests)
    static let all: [WeeklyGoal] = [
        ("siege", 10), ("siegeSpider", 3), ("siegeFreeCell", 3), ("siegePyramid", 2), ("siegeTriPeaks", 3), ("ohneTipp", 3),
        ("ohneZurueck", 2), ("schwer", 1), ("tagesspiele", 4), ("kronen", 2), ("unter5Min", 2), ("dreiKarten", 2),
    ].map { WeeklyGoal(id: $0.0, count: $0.1) }

    static func goal(_ id: String) -> WeeklyGoal? { all.first { $0.id == id } }

    // MARK: Woche und Auswahl

    /// Montag der Woche (Ortszeit, 0:00)
    static func monday(of date: Date, calendar: Calendar = .solitaer) -> Date {
        var cal = calendar
        cal.firstWeekday = 2
        return cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
    }

    static func mondayString(of date: Date, calendar: Calendar = .solitaer) -> String {
        DailyDate.string(monday(of: date, calendar: calendar), calendar: calendar)
    }

    /// Die 3 Ziele der Woche: seed = JJJJMMTT(Montag) × 10 + 9, SplitMix64.below(12) ziehen, bis 3 verschiedene da sind (in Ziehreihenfolge)
    static func selection(forMonday monday: Date, calendar: Calendar = .solitaer) -> [WeeklyGoal] {
        let c = calendar.dateComponents([.year, .month, .day], from: monday)
        var rng = SplitMix64(seed: UInt64((c.year! * 10_000 + c.month! * 100 + c.day!) * 10 + 9))
        var chosen: [WeeklyGoal] = []
        while chosen.count < 3 {
            let g = all[rng.below(all.count)]
            if !chosen.contains(g) { chosen.append(g) }
        }
        return chosen
    }

    static func selection(for date: Date, calendar: Calendar = .solitaer) -> [WeeklyGoal] {
        selection(forMonday: monday(of: date, calendar: calendar), calendar: calendar)
    }

    // MARK: Zählen

    static func value(_ id: String, _ p: WeekProgress) -> Int {
        switch id {
        case "siege": p.wins
        case "siegeSpider": p.spider
        case "siegeFreeCell": p.freecell
        case "siegePyramid": p.pyramid
        case "siegeTriPeaks": p.tripeaks
        case "ohneTipp": p.noHint
        case "ohneZurueck": p.noUndo
        case "schwer": p.hard
        case "tagesspiele": p.dailyDays.count
        case "kronen": p.crowns
        case "unter5Min": p.under5
        default: p.threeCards
        }
    }

    /// Fortschritt der Woche von `now` (eine andere Woche zählt als leer)
    static func progress(_ p: WeekProgress, now: Date, calendar: Calendar = .solitaer) -> WeekProgress {
        p.monday == mondayString(of: now, calendar: calendar) ? p : WeekProgress()
    }

    /// Ein Sieg (und eine mögliche Krone) kommt dazu. Aufgeben und „Lösung ansehen“ erzeugen nie ein Ereignis.
    static func recordWin(_ deal: DealInfo, seconds: TimeInterval, undoUsed: Bool, hintUsed: Bool, crowned: Bool,
                          into old: WeekProgress, now: Date, calendar: Calendar = .solitaer) -> WeekProgress {
        var p = progress(old, now: now, calendar: calendar)
        p.monday = mondayString(of: now, calendar: calendar)
        p.wins += 1
        switch deal.mode.kind {
        case .spider: p.spider += 1
        case .freecell: p.freecell += 1
        case .pyramid: p.pyramid += 1
        case .tripeaks: p.tripeaks += 1
        case .klondike, .golf, .yukon: break
        }
        if !hintUsed { p.noHint += 1 }
        if !undoUsed { p.noUndo += 1 }
        if deal.kind != .random, DealCatalog.shared.level(mode: deal.mode, seed: deal.seed) == 3 { p.hard += 1 }
        if seconds < 300 { p.under5 += 1 }
        if deal.mode == .klondike(3) { p.threeCards += 1 }
        if deal.kind == .daily, deal.dailyLevel == nil { p.dailyDays.insert(DailyDate.string(now, calendar: calendar)) }
        if crowned { p.crowns += 1 }
        return p
    }

    /// Erreichte Ziele der Auswahl
    static func done(_ p: WeekProgress, now: Date, calendar: Calendar = .solitaer) -> [WeeklyGoal] {
        selection(for: now, calendar: calendar).filter { value($0.id, p) >= $0.count }
    }
}
