// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Gespielt und gewonnen in einer Schwierigkeitsstufe
struct LevelCount: Codable, Equatable {
    var played = 0
    var won = 0
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        played = try c.decodeIfPresent(Int.self, forKey: .played) ?? 0
        won = try c.decodeIfPresent(Int.self, forKey: .won) ?? 0
    }
    private enum Key: String, CodingKey { case played, won }
}

/// Zahlen je Modus (`mode.key`: klondike1, klondike3, …)
struct ModeStats: Codable, Equatable {
    var played = 0
    var won = 0
    var streak = 0
    var bestStreak = 0
    var bestTime: Double?
    var fewestMoves: Int?
    var highScore: Int?
    /// je Stufe ("1" leicht, "2" mittel, "3" schwer); nur lösbare Partien aus den Listen
    var levels: [String: LevelCount] = [:]

    var winRate: Int? { played > 0 ? Int((Double(won) / Double(played) * 100).rounded()) : nil }

    init() {}

    // Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        played = try c.decodeIfPresent(Int.self, forKey: .played) ?? 0
        won = try c.decodeIfPresent(Int.self, forKey: .won) ?? 0
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? 0
        bestTime = try c.decodeIfPresent(Double.self, forKey: .bestTime)
        fewestMoves = try c.decodeIfPresent(Int.self, forKey: .fewestMoves)
        highScore = try c.decodeIfPresent(Int.self, forKey: .highScore)
        levels = try c.decodeIfPresent([String: LevelCount].self, forKey: .levels) ?? [:]
    }
    private enum Key: String, CodingKey { case played, won, streak, bestStreak, bestTime, fewestMoves, highScore, levels }
}

/// Tagesspiel-Kalender eines Spiels (Klondike, später Spider …)
struct DailyRecord: Codable, Equatable {
    /// Tage als „2026-10-04“
    var won: Set<String> = []
    var started: Set<String> = []
    /// Tage, an denen auch das Tagesziel erreicht wurde (Krone)
    var crowned: Set<String> = []
    /// Tage, an denen das leichte bzw. schwere Tagesspiel gewonnen wurde (kein Ziel, zählt nicht für Krone und Pokal)
    var wonEasy: Set<String> = []
    var wonHard: Set<String> = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        wonEasy = try c.decodeIfPresent(Set<String>.self, forKey: .wonEasy) ?? []
        wonHard = try c.decodeIfPresent(Set<String>.self, forKey: .wonHard) ?? []
        won = try c.decodeIfPresent(Set<String>.self, forKey: .won) ?? []
        started = try c.decodeIfPresent(Set<String>.self, forKey: .started) ?? []
        crowned = try c.decodeIfPresent(Set<String>.self, forKey: .crowned) ?? []
    }
    private enum Key: String, CodingKey { case won, started, crowned, wonEasy, wonHard }
}

struct StatsData: Codable, Equatable {
    /// 1 = alt (`one`/`three`, flache Tagesspiel-Listen) · 2 = je Modus (`modes`) und je Spiel ein Kalender (`daily`)
    static let currentVersion = 2
    var version = StatsData.currentVersion
    var modes: [String: ModeStats] = [:]
    /// je `GameKind.rawValue` ein Kalender
    var daily: [String: DailyRecord] = [:]
    /// Erreichte Abzeichen: `Achievement.rawValue` → Datum „2026-10-06“ (fehlt → leer)
    var achievements: [String: String] = [:]
    /// Verlauf: ein Eintrag je beendeter Partie, höchstens 2.000 (fehlt → leer, kein Nachholen)
    var history: [HistoryEntry] = []
    /// Vegas fortlaufend: Kontostand je Zieh-Art (`mode.key`), fehlt → 0
    var vegasAccount: [String: Int] = [:]
    /// Wochenziele: Fortschritt der laufenden Woche und Anzahl der Wochen mit allen 3 Zielen
    var weekly = WeekProgress()
    var weeksDone = 0

    init() {}

    subscript(mode: GameMode) -> ModeStats {
        get { modes[mode.key] ?? ModeStats() }
        set { modes[mode.key] = newValue }
    }

    /// Tagesspiel Klondike (bisher das einzige)
    var dailyWon: Set<String> {
        get { daily[GameKind.klondike.rawValue]?.won ?? [] }
        set { daily[GameKind.klondike.rawValue, default: DailyRecord()].won = newValue }
    }
    var dailyStarted: Set<String> {
        get { daily[GameKind.klondike.rawValue]?.started ?? [] }
        set { daily[GameKind.klondike.rawValue, default: DailyRecord()].started = newValue }
    }

    /// Stand vor der Umstellung auf mehrere Spiele? (wird beim Laden übernommen)
    private(set) var migratedFromV1 = false

    // Fehlende Felder beim Laden → Standardwert. Altes Format: one → klondike1, three → klondike3, Tagesspiel → Klondike.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        let v = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        if v >= 2 {
            version = v
            modes = try c.decodeIfPresent([String: ModeStats].self, forKey: .modes) ?? [:]
            daily = try c.decodeIfPresent([String: DailyRecord].self, forKey: .daily) ?? [:]
            achievements = try c.decodeIfPresent([String: String].self, forKey: .achievements) ?? [:]
            history = try c.decodeIfPresent([HistoryEntry].self, forKey: .history) ?? []
            vegasAccount = try c.decodeIfPresent([String: Int].self, forKey: .vegasAccount) ?? [:]
            weekly = try c.decodeIfPresent(WeekProgress.self, forKey: .weekly) ?? WeekProgress()
            weeksDone = try c.decodeIfPresent(Int.self, forKey: .weeksDone) ?? 0
        } else {
            version = Self.currentVersion
            migratedFromV1 = true
            if let one = try c.decodeIfPresent(ModeStats.self, forKey: .one) { modes[GameMode.klondike(1).key] = one }
            if let three = try c.decodeIfPresent(ModeStats.self, forKey: .three) { modes[GameMode.klondike(3).key] = three }
            var record = DailyRecord()
            record.won = try c.decodeIfPresent(Set<String>.self, forKey: .dailyWon) ?? []
            record.started = try c.decodeIfPresent(Set<String>.self, forKey: .dailyStarted) ?? []
            daily[GameKind.klondike.rawValue] = record
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Key.self)
        try c.encode(version, forKey: .version)
        try c.encode(modes, forKey: .modes)
        try c.encode(daily, forKey: .daily)
        try c.encode(achievements, forKey: .achievements)
        try c.encode(history, forKey: .history)
        try c.encode(vegasAccount, forKey: .vegasAccount)
        try c.encode(weekly, forKey: .weekly)
        try c.encode(weeksDone, forKey: .weeksDone)
    }

    private enum Key: String, CodingKey { case version, modes, daily, achievements, history, vegasAccount, weekly, weeksDone, one, three, dailyWon, dailyStarted }

    static func == (a: StatsData, b: StatsData) -> Bool {
        a.version == b.version && a.modes == b.modes && a.daily == b.daily && a.achievements == b.achievements && a.history == b.history && a.vegasAccount == b.vegasAccount && a.weekly == b.weekly && a.weeksDone == b.weeksDone
    }
}

/// Monatspokal je Spiel: Bronze ab 10 Kronen, Silber ab 20, Gold für alle Tage des Monats
enum Cup: Int, Comparable, CaseIterable {
    case bronze = 1, silver, gold
    static func < (a: Cup, b: Cup) -> Bool { a.rawValue < b.rawValue }

    static let bronzeCrowns = 10
    static let silverCrowns = 20
}

/// Ergebnis der Tages-Herausforderung der zuletzt gewonnenen Tagespartie
struct DailyOutcome: Equatable {
    var goal: DailyGoal
    var crowned: Bool
    /// Neuer Pokal, den diese Krone gebracht hat
    var newCup: Cup?
}

/// Welche Rekorde die letzte gewonnene Partie gebrochen hat (nur, wenn es vorher einen Wert gab)
struct NewRecords: Equatable {
    var bestTime = false
    var fewestMoves = false
    var highScore = false
    var any: Bool { bestTime || fewestMoves || highScore }
}

enum DailyDate {
    static func string(_ date: Date, calendar: Calendar = .solitaer) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }

    static func date(_ string: String, calendar: Calendar = .solitaer) -> Date? {
        let p = string.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: p[0], month: p[1], day: p[2]))
    }
}

/// Statistik, in einer eigenen Datei (geht nie mit dem Spielstand verloren).
@MainActor
@Observable
final class StatsStore {
    private(set) var data: StatsData
    private(set) var lastRecords = NewRecords()
    private(set) var lastDaily: DailyOutcome?
    /// Abzeichen, die die zuletzt gewonnene Partie gebracht hat (für die Gewonnen-Karte)
    private(set) var lastAchievements: [Achievement] = []
    /// Wochenziele, die die zuletzt gewonnene Partie fertig gemacht hat
    private(set) var lastWeeklyDone: [String] = []
    /// Uhr (für Tests austauschbar)
    @ObservationIgnored var clock: () -> Date = { .now }
    /// Abzeichen aus dem letzten Ketten-Ereignis (Hinweis über der Ablage)
    private(set) var lastChainAchievements: [Achievement] = []
    var saveError: String?
    private let url: URL?

    nonisolated static var standardURL: URL {
        let folder = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "statistik.json")
    }

    /// Gesetzt von „Solitär“: Kennung des Moduls und Name des Spielers für Niederlagen
    var meldeKennung: String?
    var meldeName = ""

    init(url: URL? = StatsStore.standardURL) {
        self.url = url
        if let url, let d = try? Data(contentsOf: url), let loaded = try? JSONDecoder().decode(StatsData.self, from: d) {
            data = loaded
            if loaded.migratedFromV1 {
                // Altes Format: Sicherung der Originaldatei, dann im neuen Format schreiben (Philipp darf nichts verlieren)
                let backup = url.deletingLastPathComponent().appending(path: "statistik-v1.json")
                if !FileManager.default.fileExists(atPath: backup.path) { try? d.write(to: backup, options: .atomic) }
                save()
            }
        } else {
            // Datei da, aber unlesbar: Kopie daneben legen, bevor der nächste Zug sie überschreibt (Statistik, Erfolge, Verlauf nicht verlieren)
            if let url { DefectBackup.preserve(url) }
            data = StatsData()
        }
        backfillAchievements()
    }

    // MARK: Wochenziele

    /// Die 3 Ziele dieser Woche mit Fortschritt
    func weeklyRows(now: Date = .now) -> [(goal: WeeklyGoal, value: Int)] {
        let p = WeeklyGoals.progress(data.weekly, now: now)
        return WeeklyGoals.selection(for: now).map { ($0, WeeklyGoals.value($0.id, p)) }
    }

    // MARK: Verlauf

    private func record(_ deal: DealInfo, won: Bool, time: Double?, moves: Int?, score: Int?, today: Date = .now) {
        // „Solitär“: Siege meldet der Rahmen selbst (mit Ende-Bildschirm); aufgegebene und neu ausgeteilte Partien meldet die Statistik hier
        if let kennung = meldeKennung {
            if !won { PartieMeldung.melden(spiel: kennung, reihenfolge: [meldeName], dauer: time ?? 0, einzel: .verloren) }
        } else {
            PartieMeldung.einzel(spiel: "solitaer", gewonnen: won, dauer: time ?? 0)
        }
        let level = deal.kind == .random ? nil : DealCatalog.shared.level(mode: deal.mode, seed: deal.seed)
        let number = deal.kind == .random ? nil : DealCatalog.shared.number(mode: deal.mode, seed: deal.seed)
        StatsHistory.append(HistoryEntry(date: DailyDate.string(today), mode: deal.mode.key, level: level, won: won, time: time,
                                         moves: moves, score: score, number: number), to: &data.history)
    }

    // MARK: Erfolge

    func earned(_ a: Achievement) -> String? { data.achievements[a.rawValue] }
    var earnedCount: Int { Achievement.allCases.filter { data.achievements[$0.rawValue] != nil }.count }

    /// Vergibt neue Abzeichen (nie doppelt) und gibt die neuen zurück
    @discardableResult
    private func award(_ event: AchievementEvent, today: Date = .now) -> [Achievement] {
        let new = Achievements.newAchievements(event, data: data, earned: Set(data.achievements.keys))
        let day = DailyDate.string(today)
        for a in new { data.achievements[a.rawValue] = day }
        return new
    }

    /// Beim Start still nachholen, was die vorhandene Statistik hergibt (ohne Hinweis)
    private func backfillAchievements() {
        var changed = false
        let day = DailyDate.string(.now)
        for a in Achievements.derivable(data) where data.achievements[a.rawValue] == nil {
            data.achievements[a.rawValue] = day
            changed = true
        }
        // Goldpokal aus den Kronen ableiten (braucht die Monatsrechnung)
        if data.achievements[Achievement.goldpokal.rawValue] == nil,
           GameKind.allCases.contains(where: { cupTotals(kind: $0)[.gold, default: 0] > 0 }) {
            data.achievements[Achievement.goldpokal.rawValue] = day
            changed = true
        }
        if changed { save() }
    }

    func stats(mode: GameMode) -> ModeStats { data[mode] }

    /// Siege insgesamt, alle Spiele (Grundlage der Bewertungsabfrage)
    var totalWins: Int { data.modes.values.reduce(0) { $0 + $1.won } }
    /// Klondike mit 1 oder 3 Karten
    func stats(draw: Int) -> ModeStats { data[.klondike(draw)] }

    private func update(mode: GameMode, _ change: (inout ModeStats) -> Void) {
        change(&data.modes[mode.key, default: ModeStats()])
    }

    /// Ereignisse aus dem Spiel verbuchen
    func handle(_ event: GameEvent) {
        switch event {
        case let .started(deal):
            lastDaily = nil
            update(mode: deal.mode) { $0.played += 1 }
            if deal.kind == .solvable, let level = DealCatalog.shared.level(mode: deal.mode, seed: deal.seed) {
                update(mode: deal.mode) { $0.levels[String(level), default: LevelCount()].played += 1 }
            }
            if deal.kind == .daily, deal.dailyLevel == nil, let day = deal.day { data.daily[deal.mode.kind.rawValue, default: DailyRecord()].started.insert(day) }
            lastRecords = NewRecords()
            lastAchievements = []
            lastWeeklyDone = []
        case let .won(deal, moves, score, seconds, undoUsed, hintUsed):
            var records = NewRecords()
            if deal.kind == .solvable, let level = DealCatalog.shared.level(mode: deal.mode, seed: deal.seed) {
                update(mode: deal.mode) { $0.levels[String(level), default: LevelCount()].won += 1 }
            }
            update(mode: deal.mode) { s in
                s.won += 1
                s.streak += 1
                s.bestStreak = max(s.bestStreak, s.streak)
                if let old = s.bestTime { if seconds < old { s.bestTime = seconds; records.bestTime = true } } else { s.bestTime = seconds }
                if let old = s.fewestMoves { if moves < old { s.fewestMoves = moves; records.fewestMoves = true } } else { s.fewestMoves = moves }
                if let score {
                    if let old = s.highScore { if score > old { s.highScore = score; records.highScore = true } } else { s.highScore = score }
                }
            }
            if deal.kind == .daily, let day = deal.day {
                switch deal.dailyLevel {
                case 1?: data.daily[deal.mode.kind.rawValue, default: DailyRecord()].wonEasy.insert(day)
                case 3?: data.daily[deal.mode.kind.rawValue, default: DailyRecord()].wonHard.insert(day)
                default: data.daily[deal.mode.kind.rawValue, default: DailyRecord()].won.insert(day)
                }
            }
            record(deal, won: true, time: seconds, moves: moves, score: score)
            lastRecords = records
            lastDaily = nil
            var newCrown = false                   // nur die erste Krone eines Tages zählt (Abzeichen, Wochenziel „Kronen“)
            // Tages-Herausforderung: Ziel erreicht → Krone (ein Tag nur einmal; Nachspielen vergangener Tage zählt mit)
            // Leicht/Schwer haben kein Tagesziel: keine Krone, kein Pokal
            if deal.kind == .daily, deal.dailyLevel == nil, let day = deal.day, let date = DailyDate.date(day),
               let goal = DailyGoalCalc.goal(kind: deal.mode.kind, date: date) {
                let reached = goal.isReached(moves: moves, seconds: seconds, undoUsed: undoUsed, hintUsed: hintUsed)
                var newCup: Cup?
                if reached {
                    let cal = Calendar.solitaer
                    let c = cal.dateComponents([.year, .month], from: date)
                    let before = cup(kind: deal.mode.kind, year: c.year!, month: c.month!)
                    newCrown = data.daily[deal.mode.kind.rawValue, default: DailyRecord()].crowned.insert(day).inserted
                    let after = cup(kind: deal.mode.kind, year: c.year!, month: c.month!)
                    if let after, before == nil || after > before! { newCup = after }
                }
                lastDaily = DailyOutcome(goal: goal, crowned: reached, newCup: newCup)
            }
            // Abzeichen: Sieg, dann Krone und Pokal dieser Partie
            var new = award(.win(deal, seconds: seconds, undoUsed: undoUsed, hintUsed: hintUsed))
            if let daily = lastDaily, daily.crowned, newCrown {
                new += award(.crown)
                if let cup = daily.newCup { new += award(.cup(cup)) }
            }
            lastAchievements = new
            // Wochenziele
            let now = clock()
            let before = WeeklyGoals.done(WeeklyGoals.progress(data.weekly, now: now), now: now).map(\.id)
            data.weekly = WeeklyGoals.recordWin(deal, seconds: seconds, undoUsed: undoUsed, hintUsed: hintUsed, crowned: newCrown,
                                                into: data.weekly, now: now)
            let after = WeeklyGoals.done(data.weekly, now: now)
            lastWeeklyDone = after.map(\.id).filter { !before.contains($0) }
            if after.count == 3, before.count < 3 { data.weeksDone += 1 }
        case let .abandoned(deal):
            update(mode: deal.mode) { $0.streak = 0 }
            record(deal, won: false, time: nil, moves: nil, score: nil)
        case let .account(deal, dollars):
            data.vegasAccount[deal.mode.key, default: 0] += dollars
        case let .chain(_, length):
            // Kette von 10 bei TriPeaks: sofort, auch ohne Sieg
            lastChainAchievements = award(.chain(length))
        }
        save()
    }

    /// Tage hintereinander, an denen das Tagesspiel gewonnen wurde – bis heute, oder bis gestern, wenn heute noch offen ist.
    // MARK: Kronen und Pokale

    func crowned(_ kind: GameKind) -> Set<String> { data.daily[kind.rawValue]?.crowned ?? [] }
    func crownCount(_ kind: GameKind) -> Int { crowned(kind).count }

    func crownsInMonth(kind: GameKind, year: Int, month: Int) -> Int {
        let prefix = String(format: "%04d-%02d", year, month)
        return crowned(kind).filter { $0.hasPrefix(prefix) }.count
    }

    /// Tage des Monats (für „Gold = alle Tage“)
    func daysInMonth(year: Int, month: Int, calendar: Calendar = .solitaer) -> Int {
        calendar.range(of: .day, in: .month, for: calendar.date(from: DateComponents(year: year, month: month))!)!.count
    }

    /// Pokal eines Monats für ein Spiel
    func cup(kind: GameKind, year: Int, month: Int, calendar: Calendar = .solitaer) -> Cup? {
        let n = crownsInMonth(kind: kind, year: year, month: month)
        if n >= daysInMonth(year: year, month: month, calendar: calendar) { return .gold }
        if n >= Cup.silverCrowns { return .silver }
        if n >= Cup.bronzeCrowns { return .bronze }
        return nil
    }

    /// Anzahl gewonnener Pokale je Stufe über alle Monate
    func cupTotals(kind: GameKind, calendar: Calendar = .solitaer) -> [Cup: Int] {
        var months = Set<String>()
        for d in crowned(kind) { months.insert(String(d.prefix(7))) }
        var totals: [Cup: Int] = [:]
        for m in months {
            let p = m.split(separator: "-").compactMap { Int($0) }
            if p.count == 2, let c = cup(kind: kind, year: p[0], month: p[1], calendar: calendar) { totals[c, default: 0] += 1 }
        }
        return totals
    }

    func dailyWon(_ kind: GameKind) -> Set<String> { data.daily[kind.rawValue]?.won ?? [] }
    func dailyLevelWon(_ kind: GameKind, level: Int) -> Set<String> {
        level == 1 ? (data.daily[kind.rawValue]?.wonEasy ?? []) : level == 3 ? (data.daily[kind.rawValue]?.wonHard ?? []) : dailyWon(kind)
    }
    func dailyStarted(_ kind: GameKind) -> Set<String> { data.daily[kind.rawValue]?.started ?? [] }

    func dailyStreak(kind: GameKind = .klondike, today: Date = .now, calendar: Calendar = .solitaer) -> Int {
        let won = dailyWon(kind)
        var day = today
        if !won.contains(DailyDate.string(day, calendar: calendar)) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var n = 0
        while won.contains(DailyDate.string(day, calendar: calendar)) {
            n += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return n
    }

    /// Längste Folge gewonnener Tage überhaupt
    func bestDailyStreak(kind: GameKind = .klondike, calendar: Calendar = .solitaer) -> Int {
        let days = dailyWon(kind).compactMap { DailyDate.date($0, calendar: calendar) }.sorted()
        var best = 0, run = 0
        var previous: Date?
        for day in days {
            if let p = previous, calendar.date(byAdding: .day, value: 1, to: p) == day { run += 1 } else { run = 1 }
            best = max(best, run)
            previous = day
        }
        return best
    }

    /// Zahlen einer Zieh-Art löschen (das Tagesspiel-Kalenderblatt bleibt, es gehört zu beiden)
    func reset(draw: Int) { reset(mode: .klondike(draw)) }

    /// Vegas-Konto einer Zieh-Art
    func vegasAccount(_ mode: GameMode) -> Int { data.vegasAccount[mode.key] ?? 0 }

    func resetVegasAccount(_ mode: GameMode) {
        data.vegasAccount[mode.key] = nil
        save()
    }

    func reset(mode: GameMode) {
        data.modes[mode.key] = ModeStats()
        data.history.removeAll { $0.mode == mode.key }
        lastRecords = NewRecords()
        save()
    }

    /// Nur für Demo: Abzeichen der letzten Partie setzen
    func demoAchievements(_ list: [Achievement]) { lastAchievements = list }

    /// Nur für Demo und Tests
    func load(_ data: StatsData, records: NewRecords = NewRecords(), daily: DailyOutcome? = nil) {
        self.data = data
        backfillAchievements()
        lastRecords = records
        lastDaily = daily
    }

    private func save() {
        TagesSerieWidget.melden(praefix: "solitaer", serie: dailyStreak(), letzterTag: dailyWon(.klondike).max())
        guard let url else { return }
        do {
            try JSONEncoder().encode(data).write(to: url, options: .atomic)
        } catch {
            saveError = error.localizedDescription
        }
    }
}
