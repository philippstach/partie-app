// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Statistik über alle Spiele („Hall of Fame“).
@MainActor
struct HallOfFameTests {
    private func store(_ defaults: UserDefaults, repo: GameRepository = MemoryRepository()) -> GameStore {
        GameStore(repository: repo, defaults: defaults)
    }

    /// Ein Spiel bis zum Ende: Punkte je Zug der Reihe nach, Ziel 1.000.
    private func play(_ store: GameStore, _ names: [String], _ points: [Int]) {
        var s = GameSettings(goal: 1_000, diceMode: .real)
        s.nextPlayerOverlay = false
        store.startGame(players: names.enumerated().map { Player(name: $1, avatar: "🎲", colorIndex: $0) }, settings: s)
        for p in points { p > 0 ? store.submitPoints(p) : store.submitNoPoints() }
    }

    @Test func countsWinsStreaksAndRecords() {
        let s = store(UserDefaults(suiteName: UUID().uuidString)!)
        play(s, ["Lena", "Max"], [1_000])                    // Lena
        play(s, ["Lena", "Max"], [0, 600, 1_000])            // Lena (Max 600)
        play(s, ["Max", "lena "], [1_050])                   // Max – „lena “ ist dieselbe Lena
        let hof = s.hallOfFame
        #expect(hof.gameCount == 3)
        let lena = hof.rows.first { $0.id == "lena" }!
        let max = hof.rows.first { $0.id == "max" }!
        #expect(lena.games == 3 && lena.wins == 2 && lena.longestStreak == 2 && lena.currentStreak == 0)
        #expect(max.games == 3 && max.wins == 1 && max.nieten == 0)
        #expect(lena.nieten == 1 && lena.name == "lena ")    // zuletzt benutzte Schreibweise
        #expect(hof.rows.first?.id == "lena")                // mehr Siege zuerst
        #expect(hof.bestTurn?.value == 1_050 && hof.bestTurn?.name == "Max")
        #expect(hof.highestFinal?.value == 1_050)
        #expect(hof.longestStreak?.value == 2 && hof.longestStreak?.name.hasPrefix("lena") == true)
        #expect(hof.mostNietenInGame?.value == 1)
    }

    /// Rückgängig nach dem Sieg nimmt das Spiel wieder aus der Statistik – nichts zählt doppelt.
    @Test func undoAfterWinRemovesSummary() {
        let s = store(UserDefaults(suiteName: UUID().uuidString)!)
        play(s, ["A", "B"], [1_000])
        #expect(s.summaries.count == 1)
        s.undo()
        #expect(s.summaries.isEmpty)
        s.submitPoints(1_000)
        #expect(s.summaries.count == 1 && s.hallOfFame.rows.first { $0.id == "a" }?.wins == 1)
    }

    /// Statistik bleibt, auch wenn beendete Spiele nicht behalten werden, und übersteht einen Neustart.
    @Test func survivesDiscardAndRelaunch() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let repo = MemoryRepository()
        let s = store(defaults, repo: repo)
        s.keepFinishedGames = false
        play(s, ["A", "B"], [1_000])
        #expect(s.finishedGames.isEmpty)
        let again = store(defaults, repo: repo)
        #expect(again.summaries.count == 1)
        #expect(again.hallOfFame.rows.count == 2)
    }

    /// Beim ersten Start werden schon beendete Spiele aus dem Verlauf übernommen.
    @Test func backfillsFinishedGames() {
        let repo = MemoryRepository()
        let first = store(UserDefaults(suiteName: UUID().uuidString)!, repo: repo)
        play(first, ["A", "B"], [1_000])
        let fresh = store(UserDefaults(suiteName: UUID().uuidString)!, repo: repo)  // leere Statistik, gleicher Verlauf
        #expect(fresh.summaries.count == 1)
        #expect(fresh.summaries.first?.id == first.currentID)
    }

    @Test func personalBestExcludesCurrentGame() {
        let a = GameSummary(id: UUID(), date: .now, game: {
            var g = GameState(players: [Player(name: "Anna", avatar: "", colorIndex: 0)], settings: GameSettings())
            g.players[0].bestTurn = 800
            return g
        }())
        #expect(HallOfFame.personalBestTurn("anna", in: [a], excluding: nil) == 800)
        #expect(HallOfFame.personalBestTurn("Anna", in: [a], excluding: a.id) == nil)
        #expect(HallOfFame.personalBestTurn("Ben", in: [a], excluding: nil) == nil)
    }

    /// Rekord-Einblendung: nur mit Vorgeschichte, nur über dem bisherigen Bestwert (auch aus diesem Spiel).
    @Test func personalRecordNotice() {
        let s = store(UserDefaults(suiteName: UUID().uuidString)!)
        play(s, ["Lena", "Max"], [400, 300, 600])            // Lena gewinnt, bester Zug 600; Max 300
        #expect(s.recordNotice == nil)                       // erstes Spiel: keine Vorgeschichte

        var settings = GameSettings(goal: 5_000, diceMode: .real)
        settings.nextPlayerOverlay = false
        s.startGame(players: [Player(name: "Lena", avatar: "", colorIndex: 0), Player(name: "Max", avatar: "", colorIndex: 1), Player(name: "Neu", avatar: "", colorIndex: 2)], settings: settings)
        s.submitPoints(600)                                  // Lena: nur gleich → kein Rekord
        #expect(s.recordNotice == nil)
        s.submitPoints(350)                                  // Max: 350 > 300
        #expect(s.recordNotice == RecordNotice(player: 1, points: 350, previous: 300))
        s.submitPoints(2_000)                                // Neu: keine Vorgeschichte
        #expect(s.recordNotice?.player == 1)
        s.submitPoints(650)                                  // Lena: 650 > 600
        #expect(s.recordNotice == RecordNotice(player: 0, points: 650, previous: 600))
        s.submitPoints(350)                                  // Max: gleich wie eben in diesem Spiel → kein neuer
        #expect(s.recordNotice?.player == 0)
        s.undo()
        #expect(s.recordNotice == nil)
    }
}
