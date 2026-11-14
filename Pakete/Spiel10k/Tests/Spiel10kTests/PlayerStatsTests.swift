// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Spieler-Details: Rang, Abstände, Schnitt, letzte Züge, Übernahme-Herkunft.
@MainActor
struct PlayerStatsTests {
    private func makeStore(players: Int = 3, settings: GameSettings = GameSettings(goal: 5_000, penalty: 500, diceMode: .real, realEntry: .pips)) -> GameStore {
        let store = GameStore(repository: MemoryRepository(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var s = settings
        s.nextPlayerOverlay = false
        store.startGame(players: (0..<players).map { Player(name: "P\($0)", avatar: "", colorIndex: $0) }, settings: s)
        return store
    }

    @Test func beforeFirstTurn() {
        let store = makeStore()
        let s = PlayerStats(game: store.game!, player: 1)
        #expect(s.rank == 1 && s.behindLeader == 0 && s.toGoal == 5_000)
        #expect(s.average == nil && s.recent.isEmpty && s.turns == 0)
    }

    @Test func rankGapsAverageAndRecent() {
        let store = makeStore()
        // Runde 1: P0 300, P1 Niete, P2 450 · Runde 2: P0 Niete, P1 200, P2 Niete · Runde 3: P0 600
        for p in [300, 0, 450, 0, 200, 0, 600] { p > 0 ? store.submitPoints(p) : store.submitNoPoints() }
        let g = store.game!
        let s0 = PlayerStats(game: g, player: 0)
        #expect(s0.score == 900 && s0.rank == 1 && s0.behindLeader == 0 && s0.toGoal == 4_100)
        #expect(s0.turns == 3 && s0.bestTurn == 600 && s0.nieten == 1 && s0.streak == 0)
        #expect(s0.average == 300)                                   // (300 + 0 + 600) / 3
        #expect(s0.recent.map(\.number) == [7, 4, 1])                 // neueste zuerst, Zug-Nummer im Spiel
        #expect(s0.recent.map(\.points) == [600, 0, 300])

        let s1 = PlayerStats(game: g, player: 1)
        #expect(s1.rank == 3 && s1.behindLeader == 700 && s1.average == 100)
        let s2 = PlayerStats(game: g, player: 2)
        #expect(s2.rank == 2 && s2.behindLeader == 450 && s2.streak == 1 && !s2.penaltyThreatened)
    }

    /// Gleichstand teilt den Rang; Strafe erscheint im Zug, zählt aber nicht in den Schnitt.
    @Test func sharedRankAndPenalty() {
        let store = makeStore(players: 2)
        for p in [0, 300, 0, 300] { p > 0 ? store.submitPoints(p) : store.submitNoPoints() }
        #expect(PlayerStats(game: store.game!, player: 0).penaltyThreatened)
        store.submitNoPoints()                                        // P0: dritte Niete → −500
        store.submitPoints(0 + 50)                                    // P1 +50
        let g = store.game!
        let s0 = PlayerStats(game: g, player: 0)
        #expect(s0.score == -500 && s0.recent.first?.penalty == 500 && s0.average == 0)
        #expect(s0.rank == 2 && s0.behindLeader == 1_150)

        let tie = makeStore(players: 2)
        tie.submitPoints(200); tie.submitPoints(200)
        #expect(PlayerStats(game: tie.game!, player: 0).rank == 1)
        #expect(PlayerStats(game: tie.game!, player: 1).rank == 1)
    }

    /// „übernommen von X“ steht im Zug, auch bei einer Niete nach der Übernahme.
    @Test func inheritedFromIsRecorded() {
        let store = makeStore(players: 2)
        store.layOut([1, 5], bank: true)          // P0 150, 3 offen
        store.acceptOffer()
        store.layOut([1], bank: true)             // P1 übernimmt: 250
        #expect(store.game?.log.last?.inheritedFrom == 0)
        let s1 = PlayerStats(game: store.game!, player: 1)
        #expect(s1.recent.first?.inheritedFrom == 0 && s1.recent.first?.points == 250)
        store.acceptOffer()                       // P0 übernimmt von P1 …
        store.submitNoPoints()                    // … und hat eine Niete
        #expect(store.game?.log.last?.inheritedFrom == 1 && store.game?.log.last?.points == 0)
        #expect(store.game?.log.first?.inheritedFrom == nil)
    }

    /// Ältere Spielstände ohne das Feld laden weiter.
    @Test func oldTurnRecordDecodes() throws {
        let json = #"{"id":"\#(UUID().uuidString)","player":1,"points":300,"penalty":0}"#
        let r = try JSONDecoder().decode(TurnRecord.self, from: Data(json.utf8))
        #expect(r.inheritedFrom == nil && r.points == 300)
    }
}
