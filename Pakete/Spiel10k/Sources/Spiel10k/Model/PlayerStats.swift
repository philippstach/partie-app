// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Kennzahlen eines Spielers für die Detail-Karte im Spiel – nur lesend, aus dem Spielstand berechnet.
nonisolated struct PlayerStats: Equatable, Sendable {
    /// Ein Zug in der Liste „Letzte Züge“
    struct Turn: Equatable, Sendable {
        var number: Int           // laufende Nummer im Spiel (1 = erster Zug überhaupt)
        var points: Int           // 0 = Niete
        var penalty: Int
        var inheritedFrom: Int?
    }

    var player: Int
    var score: Int
    /// 1 = vorne; gleiche Punkte teilen sich den Rang
    var rank: Int
    /// Punkte bis zum Ersten (0, wenn man selbst vorne liegt oder gleichauf ist)
    var behindLeader: Int
    /// Punkte bis zum Ziel (0, wenn erreicht)
    var toGoal: Int
    var turns: Int
    var bestTurn: Int
    var nieten: Int
    var streak: Int
    var penaltyThreatened: Bool
    /// Schnitt pro Zug (Nieten zählen als 0, Strafen nicht); `nil` vor dem ersten Zug
    var average: Int?
    /// Neueste zuerst
    var recent: [Turn]

    init(game: GameState, player i: Int, recentLimit: Int = 8) {
        let p = game.players[i]
        let top = game.players.map(\.score).max() ?? 0
        player = i
        score = p.score
        rank = game.players.filter { $0.score > p.score }.count + 1
        behindLeader = max(top - p.score, 0)
        toGoal = max(game.settings.goal - p.score, 0)
        turns = p.turns
        bestTurn = p.bestTurn
        nieten = p.nieten
        streak = p.streak
        penaltyThreatened = game.penaltyThreatened(i)

        let own = game.log.enumerated().filter { $0.element.player == i }
        let sum = own.reduce(0) { $0 + $1.element.points }
        average = own.isEmpty ? nil : Int((Double(sum) / Double(own.count)).rounded())
        recent = own.suffix(recentLimit).reversed().map { n, r in
            Turn(number: n + 1, points: r.points, penalty: r.penalty, inheritedFrom: r.inheritedFrom)
        }
    }
}
