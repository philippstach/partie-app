// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Spiele, für die es ein Tagesziel gibt (auch Pyramid und TriPeaks, damit ihre Ziele schon jetzt getestet werden)
enum DailyGame: String, CaseIterable {
    case klondike, spider, freecell, pyramid, tripeaks, golf, yukon

    /// Spielnummer für den Zufall des Tagesziels
    var number: Int {
        switch self {
        case .klondike: 0
        case .spider: 1
        case .freecell: 2
        case .pyramid: 3
        case .tripeaks: 4
        case .golf: 5
        case .yukon: 6
        }
    }

    init?(kind: GameKind) {
        switch kind {
        case .klondike: self = .klondike
        case .spider: self = .spider
        case .freecell: self = .freecell
        case .pyramid: self = .pyramid
        case .tripeaks: self = .tripeaks
        case .golf: self = .golf
        case .yukon: self = .yukon
        }
    }
}

/// Das Tagesziel zu einer Tagespartie
enum DailyGoal: Equatable {
    case win
    /// in höchstens so vielen Zügen
    case moves(limit: Int)
    case noUndo
    case underMinutes(Int)
    case noHint

    /// Schlüssel der Regeltests (`art`)
    var artKey: String {
        switch self {
        case .win: "gewinnen"
        case .moves: "zuege"
        case .noUndo: "ohneRueckgaengig"
        case let .underMinutes(m): "unter\(m)Min"
        case .noHint: "ohneTipp"
        }
    }

    /// Ziel erreicht? Zeit wie angezeigt (ganze Sekunden)
    func isReached(moves: Int, seconds: TimeInterval, undoUsed: Bool, hintUsed: Bool) -> Bool {
        switch self {
        case .win: true
        case let .moves(limit): moves <= limit
        case .noUndo: !undoUsed
        case let .underMinutes(m): Int(seconds) < m * 60
        case .noHint: !hintUsed
        }
    }

    /// Als Satzende: „Heute: ohne Rückgängig“
    var sentence: String {
        switch self {
        case .win: String(localized: "gewinnen")
        case let .moves(limit): String(localized: "in höchstens \(limit) Zügen")
        case .noUndo: String(localized: "ohne Rückgängig")
        case let .underMinutes(m): String(localized: "in unter \(m) Minuten")
        case .noHint: String(localized: "ohne Tipp")
        }
    }
}

enum DailyGoalCalc {
    /// JJJJMMTT als Zahl
    static func dateNumber(year: Int, month: Int, day: Int) -> Int { year * 10_000 + month * 100 + day }

    static func dateNumber(of date: Date, calendar: Calendar = .solitaer) -> Int {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return dateNumber(year: c.year!, month: c.month!, day: c.day!)
    }

    /// Nummer des Ziels: `SplitMix64(seed = JJJJMMTT × 10 + Spielnummer).below(k)`, erster Wert eines frischen Generators
    static func index(game: DailyGame, dateNumber: Int) -> Int {
        var rng = SplitMix64(seed: UInt64(dateNumber * 10 + game.number))
        return rng.below(game == .klondike || game == .spider ? 5 : 4)
    }

    /// ⌈x × 1,4⌉ ohne Rundungsfehler
    static func ceilTimes14(_ x: Int) -> Int { (x * 14 + 9) / 10 }

    /// Tagesziel eines Tages. `solutionMoves` = Lösungslänge der Tagespartie (Klondike und Spider); fehlt sie, wird „in höchstens … Zügen“ zu „gewinnen“.
    static func goal(game: DailyGame, dateNumber: Int, solutionMoves: Int?) -> DailyGoal {
        let i = index(game: game, dateNumber: dateNumber)
        switch game {
        case .klondike, .spider:
            switch i {
            case 0: return .win
            case 1:
                guard let solutionMoves else { return .win }
                // Spider: die 8 Abräum-Züge zählen nicht
                return .moves(limit: ceilTimes14(game == .spider ? solutionMoves - 8 : solutionMoves))
            case 2: return .noUndo
            case 3: return .underMinutes(game == .klondike ? 6 : 12)
            default: return .noHint
            }
        case .freecell:
            return [DailyGoal.win, .noUndo, .underMinutes(5), .noHint][i]
        case .pyramid, .tripeaks, .golf:
            return [DailyGoal.win, .noUndo, .underMinutes(4), .noHint][i]
        case .yukon:
            return [DailyGoal.win, .noUndo, .underMinutes(6), .noHint][i]
        }
    }

    /// Tagesziel der Tagespartie eines Datums (Lösungslänge aus dem Katalog)
    static func goal(kind: GameKind, date: Date, catalog: DealCatalog = .shared, calendar: Calendar = .solitaer) -> DailyGoal? {
        guard let game = DailyGame(kind: kind) else { return nil }
        let seed = catalog.dailySeed(for: date, kind: kind, calendar: calendar)
        let length = seed.flatMap { catalog.solutionLength(kind: kind, seed: $0) }
        return goal(game: game, dateNumber: dateNumber(of: date, calendar: calendar), solutionMoves: length)
    }
}
