// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Eingabe für die Erfolge: Zahlen aus der Statistik (Zeiten in Sekunden, 0 = keine).
struct AchievementInput: Sendable, Equatable {
    var solved: [Level: Int] = [:]
    var withoutHelp: [Level: Int] = [:]
    var bestTime: [Level: Double] = [:]
    var bestStreak = 0
    var dailySolved = 0
    var themesSolved = 0
    var packSize: [Level: Int] = [:]

    func sum(_ d: [Level: Int]) -> Int { Level.allCases.reduce(0) { $0 + (d[$1] ?? 0) } }
}

/// Die 14 Erfolge (nur lokal). Reihenfolge und Bedingungen wie `Shared/regeltests/erfolge.json`.
struct Achievement: Identifiable, Sendable {
    let id: String
    let symbol: String
    let isReached: @Sendable (AchievementInput) -> Bool

    var name: String {
        switch id {
        case "erstes_raetsel": String(localized: "Erstes Rätsel")
        case "zehn_raetsel": String(localized: "Zehn gelöst")
        case "hundert_raetsel": String(localized: "Hundert gelöst")
        case "ohne_hilfe": String(localized: "Ganz allein")
        case "ohne_hilfe_25": String(localized: "Rätselprofi")
        case "erstes_schwer": String(localized: "Mutig")
        case "serie_7": String(localized: "Eine Woche")
        case "serie_30": String(localized: "Ein Monat")
        case "tages_30": String(localized: "Treuer Gast")
        case "blitz_leicht": String(localized: "Flink")
        case "blitz_mittel": String(localized: "Schnell")
        case "blitz_schwer": String(localized: "Blitz")
        case "alle_leicht": String(localized: "Leicht gemeistert")
        default: String(localized: "Themenfreund")
        }
    }

    /// Bedingung in einem Satz
    var condition: String {
        switch id {
        case "erstes_raetsel": String(localized: "Löse dein erstes Rätsel.")
        case "zehn_raetsel": String(localized: "Löse 10 Rätsel.")
        case "hundert_raetsel": String(localized: "Löse 100 Rätsel.")
        case "ohne_hilfe": String(localized: "Löse ein Rätsel ohne Hilfe.")
        case "ohne_hilfe_25": String(localized: "Löse 25 Rätsel ohne Hilfe.")
        case "erstes_schwer": String(localized: "Löse ein schweres Rätsel.")
        case "serie_7": String(localized: "Löse das Tagesrätsel an 7 Tagen hintereinander.")
        case "serie_30": String(localized: "Löse das Tagesrätsel an 30 Tagen hintereinander.")
        case "tages_30": String(localized: "Löse 30 Tagesrätsel.")
        case "blitz_leicht": String(localized: "Löse ein leichtes Rätsel in höchstens 3 Minuten.")
        case "blitz_mittel": String(localized: "Löse ein mittleres Rätsel in höchstens 7 Minuten.")
        case "blitz_schwer": String(localized: "Löse ein schweres Rätsel in höchstens 15 Minuten.")
        case "alle_leicht": String(localized: "Löse alle leichten Rätsel.")
        default: String(localized: "Löse ein Themen-Rätsel.")
        }
    }
}

enum Achievements {
    static let all: [Achievement] = [
        Achievement(id: "erstes_raetsel", symbol: "flag") { $0.sum($0.solved) >= 1 },
        Achievement(id: "zehn_raetsel", symbol: "10.circle") { $0.sum($0.solved) >= 10 },
        Achievement(id: "hundert_raetsel", symbol: "trophy") { $0.sum($0.solved) >= 100 },
        Achievement(id: "ohne_hilfe", symbol: "hand.thumbsup") { $0.sum($0.withoutHelp) >= 1 },
        Achievement(id: "ohne_hilfe_25", symbol: "rosette") { $0.sum($0.withoutHelp) >= 25 },
        Achievement(id: "erstes_schwer", symbol: "mountain.2") { ($0.solved[.schwer] ?? 0) >= 1 },
        Achievement(id: "serie_7", symbol: "calendar") { $0.bestStreak >= 7 },
        Achievement(id: "serie_30", symbol: "calendar.badge.checkmark") { $0.bestStreak >= 30 },
        Achievement(id: "tages_30", symbol: "heart") { $0.dailySolved >= 30 },
        Achievement(id: "blitz_leicht", symbol: "hare") { 0 < ($0.bestTime[.leicht] ?? 0) && ($0.bestTime[.leicht] ?? 0) <= 180 },
        Achievement(id: "blitz_mittel", symbol: "bolt") { 0 < ($0.bestTime[.mittel] ?? 0) && ($0.bestTime[.mittel] ?? 0) <= 420 },
        Achievement(id: "blitz_schwer", symbol: "bolt.fill") { 0 < ($0.bestTime[.schwer] ?? 0) && ($0.bestTime[.schwer] ?? 0) <= 900 },
        Achievement(id: "alle_leicht", symbol: "crown") { ($0.packSize[.leicht] ?? 0) > 0 && ($0.solved[.leicht] ?? 0) >= ($0.packSize[.leicht] ?? Int.max) },
        Achievement(id: "thema_1", symbol: "paintpalette") { $0.themesSolved >= 1 },
    ]

    /// Alle erreichten Erfolge (ids in fester Reihenfolge)
    static func reached(_ input: AchievementInput) -> [String] {
        all.filter { $0.isReached(input) }.map(\.id)
    }

    static func find(_ id: String) -> Achievement? { all.first { $0.id == id } }
}

/// Lernkurve: Stufen-Empfehlung nach den letzten gelösten Rätseln DIESER Stufe (Hilfen, neueste zuletzt).
/// Drei in Folge ohne Hilfe → nächstschwerere Stufe; drei in Folge mit je ≥ 3 Hilfen → nächstleichtere.
enum Recommendation {
    static func suggest(level: Level, hints: [Int]) -> Level? {
        guard hints.count >= 3 else { return nil }
        let last = hints.suffix(3)
        let all = Level.allCases
        guard let i = all.firstIndex(of: level) else { return nil }
        if last.allSatisfy({ $0 == 0 }), i < all.count - 1 { return all[i + 1] }
        if last.allSatisfy({ $0 >= 3 }), i > 0 { return all[i - 1] }
        return nil
    }
}
