// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Faire Schlussrunde (Regel `finalRound`, Standard aus).
@MainActor
struct FinalRoundTests {
    private func makeStore(players: Int = 3, tiebreak: Bool = true, finalRound: Bool = true) -> GameStore {
        let store = GameStore(repository: MemoryRepository(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var s = GameSettings(goal: 1_000, diceMode: .real, tiebreak: tiebreak, finalRound: finalRound)
        s.nextPlayerOverlay = false
        store.startGame(players: (0..<players).map { Player(name: "P\($0)", avatar: "", colorIndex: $0) }, settings: s)
        return store
    }

    private func play(_ store: GameStore, _ points: [Int]) {
        for p in points { p > 0 ? store.submitPoints(p) : store.submitNoPoints() }
    }

    @Test func othersFinishTheRoundAndCanOvertake() {
        let s = makeStore()
        play(s, [1_000])
        #expect(s.game?.finished == false && s.game?.finalRoundFrom == 0 && s.game?.current == 1)
        play(s, [1_100])                        // P1 überholt, löst aber nichts Neues aus
        #expect(s.game?.finished == false && s.game?.finalRoundFrom == 0 && s.game?.current == 2)
        play(s, [300])
        #expect(s.game?.winners == [1])
        #expect(s.game?.log.count == 3)
    }

    @Test func lastSeatReachingGoalEndsRightAway() {
        let s = makeStore()
        play(s, [300, 0, 1_000])
        #expect(s.game?.winners == [2])
    }

    @Test func tieAfterFinalRound() {
        let withTiebreak = makeStore(players: 2)
        play(withTiebreak, [1_000, 1_000])
        #expect(withTiebreak.game?.finished == false)
        #expect(withTiebreak.game?.tiebreak?.players == [0, 1])

        let shared = makeStore(players: 2, tiebreak: false)
        play(shared, [1_000, 1_000])
        #expect(shared.game?.winners == [0, 1])
    }

    @Test func offRuleWinsImmediately() {
        let s = makeStore(finalRound: false)
        play(s, [1_000])
        #expect(s.game?.winners == [0] && s.game?.finalRoundFrom == nil)
    }

    @Test func undoAndOldSaves() throws {
        let s = makeStore()
        play(s, [1_000])
        s.undo()
        #expect(s.game?.finalRoundFrom == nil && s.game?.current == 0)

        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s.game!)) as! [String: Any]
        json["finalRoundFrom"] = nil
        var settings = json["settings"] as! [String: Any]
        var rules = settings["rules"] as! [String: Any]
        rules["finalRound"] = nil
        settings["rules"] = rules
        json["settings"] = settings
        let old = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(old.finalRoundFrom == nil && !old.settings.rules.finalRound && old.isConsistent)
        #expect(RulesSummary.text(GameRules(finalRound: true)).contains("mit Schlussrunde"))
        #expect(RulePreset.matching(GameRules(finalRound: true)) == nil)
    }
}
