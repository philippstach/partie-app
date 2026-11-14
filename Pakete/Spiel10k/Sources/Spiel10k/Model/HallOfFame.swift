// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Kurzfassung eines beendeten Spiels für die Statistik über alle Spiele („Hall of Fame“).
/// Wird getrennt von den Spielständen gespeichert – sie bleibt, auch wenn beendete Spiele nicht
/// behalten oder gelöscht werden.
nonisolated struct GameSummary: Codable, Equatable, Sendable, Identifiable {
    struct Entry: Codable, Equatable, Sendable {
        var name: String
        var avatar: String
        var score: Int
        var bestTurn: Int
        var nieten: Int
        var won: Bool
    }

    /// = ID des Spiels
    var id: UUID
    var date: Date
    var players: [Entry]

    init(id: UUID, date: Date, game: GameState) {
        self.id = id
        self.date = date
        // Computergegner stehen nicht in der Hall of Fame
        players = game.players.enumerated().filter { !$0.element.isComputer }.map { i, p in
            Entry(name: p.name, avatar: p.avatar, score: p.score, bestTurn: p.bestTurn,
                  nieten: p.nieten, won: game.winners.contains(i))
        }
    }

    /// Personen werden über den Namen wiedererkannt (siehe `PlayerName.key`).
    static func key(_ name: String) -> String { PlayerName.key(name) }
}

/// Statistik über alle Spiele, je Spielername, plus Rekorde.
nonisolated struct HallOfFame: Equatable, Sendable {
    struct Row: Identifiable, Equatable, Sendable {
        var id: String          // Schlüssel des Namens
        var name: String        // zuletzt benutzte Schreibweise
        var avatar: String      // zuletzt benutzter Avatar
        var games = 0
        var wins = 0
        var bestTurn = 0
        var highestFinal = Int.min
        var nieten = 0
        var longestStreak = 0
        var currentStreak = 0

        /// Siegquote 0…1
        var winRate: Double { games == 0 ? 0 : Double(wins) / Double(games) }
    }

    struct Record: Equatable, Sendable {
        var name: String
        var avatar: String
        var value: Int
    }

    /// Sortiert nach Siegen, dann Siegquote, dann Spielen
    var rows: [Row]
    var bestTurn: Record?
    var highestFinal: Record?
    var longestStreak: Record?
    var mostNietenInGame: Record?
    var gameCount: Int

    init(summaries: [GameSummary]) {
        var byKey: [String: Row] = [:]
        var bestTurn: Record?, highestFinal: Record?, mostNieten: Record?
        let ordered = summaries.sorted { $0.date < $1.date }
        for s in ordered {
            // Platzhalter („Person 2“) und leere Namen zählen nicht
            for e in s.players where PlayerName.isKnowable(e.name) {
                let k = GameSummary.key(e.name)
                var r = byKey[k] ?? Row(id: k, name: e.name, avatar: e.avatar)
                r.name = e.name
                r.avatar = e.avatar
                r.games += 1
                r.bestTurn = max(r.bestTurn, e.bestTurn)
                r.highestFinal = max(r.highestFinal, e.score)
                r.nieten += e.nieten
                if e.won {
                    r.wins += 1
                    r.currentStreak += 1
                    r.longestStreak = max(r.longestStreak, r.currentStreak)
                } else {
                    r.currentStreak = 0
                }
                byKey[k] = r
                if e.bestTurn > (bestTurn?.value ?? 0) { bestTurn = Record(name: e.name, avatar: e.avatar, value: e.bestTurn) }
                if e.score > (highestFinal?.value ?? Int.min) { highestFinal = Record(name: e.name, avatar: e.avatar, value: e.score) }
                if e.nieten > (mostNieten?.value ?? 0) { mostNieten = Record(name: e.name, avatar: e.avatar, value: e.nieten) }
            }
        }
        rows = byKey.values.sorted {
            ($0.wins, $0.winRate, $0.games, $1.name) > ($1.wins, $1.winRate, $1.games, $0.name)
        }
        self.bestTurn = bestTurn
        self.highestFinal = highestFinal
        self.mostNietenInGame = mostNieten
        if let streak = rows.max(by: { $0.longestStreak < $1.longestStreak }), streak.longestStreak > 0 {
            longestStreak = Record(name: streak.name, avatar: streak.avatar, value: streak.longestStreak)
        }
        gameCount = summaries.count
    }

    /// Bester Zug eines Spielers in früheren Spielen; `nil`, wenn er noch kein beendetes Spiel hat.
    static func personalBestTurn(_ name: String, in summaries: [GameSummary], excluding id: UUID?) -> Int? {
        guard PlayerName.isKnowable(name) else { return nil }
        let k = GameSummary.key(name)
        let turns = summaries.filter { $0.id != id }.flatMap(\.players).filter { GameSummary.key($0.name) == k }.map(\.bestTurn)
        return turns.isEmpty ? nil : turns.max()
    }
}
