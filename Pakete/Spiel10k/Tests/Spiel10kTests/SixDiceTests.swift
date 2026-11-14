// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Spiel mit 6 Würfeln: Wertung, Straße (5er oder große 1–6), Spielablauf.
struct SixDiceScoringTests {
    let five = ScoringRules(diceCount: 6, straight6: .five)
    let full = ScoringRules(diceCount: 6, straight6: .full)

    @Test func fiveStraightInFullThrow() {
        #expect(Scoring.score([1, 2, 3, 4, 5], fullThrow: true, rules: five) == 1_000)
        #expect(Scoring.score([2, 3, 4, 5, 6], fullThrow: true, rules: five) == 1_000)
        #expect(Scoring.score([1, 2, 3, 4, 5, 5], fullThrow: true, rules: five) == 1_050)
        #expect(Scoring.score([1, 2, 3, 4, 5, 1], fullThrow: true, rules: five) == 1_100)
        #expect(Scoring.score([1, 2, 3, 4, 5, 6], fullThrow: true, rules: five) == 1_100)   // 2–6 + einzelne 1
        #expect(Scoring.score([1, 2, 3, 4, 5, 3], fullThrow: true, rules: five) == nil)     // 3 zählt nicht
        #expect(Scoring.score([1, 2, 3, 4, 5], fullThrow: false, rules: five) == nil)       // nicht im vollen Wurf
    }

    @Test func bigStraightOnly() {
        #expect(Scoring.score([1, 2, 3, 4, 5, 6], fullThrow: true, rules: full) == Scoring.bigStraightPoints)
        #expect(Scoring.score([1, 2, 3, 4, 5], fullThrow: true, rules: full) == nil)
        #expect(Scoring.score([1, 2, 3, 4, 5, 5], fullThrow: true, rules: full) == nil)
        #expect(Scoring.score([1, 2, 3, 4, 5, 6], fullThrow: false, rules: full) == nil)
    }

    @Test func triplesAndSinglesWithSix() {
        #expect(Scoring.score([2, 2, 2, 4, 4, 4], fullThrow: true, rules: five) == 600)     // zwei Drillinge
        #expect(Scoring.score([1, 1, 1, 5, 5, 5], fullThrow: true, rules: five) == 1_500)
        #expect(Scoring.score([1, 1, 1, 1, 1, 1], fullThrow: true, rules: five) == 1_300)   // Drilling + 3 Einzelne
        #expect(Scoring.score([2, 2, 2, 2, 2, 2], fullThrow: true, rules: five) == nil)     // keine zwei Drillinge derselben Zahl
        #expect(Scoring.score([2, 2, 3, 3, 4, 4], fullThrow: true, rules: five) == nil)     // keine drei Paare
        let b = ScoringRules(triples: .onesAndFives, diceCount: 6)
        #expect(Scoring.score([1, 1, 1, 5, 5, 5], fullThrow: true, rules: b) == 1_000)
        #expect(Scoring.score([2, 2, 2, 4, 4, 4], fullThrow: true, rules: b) == nil)
    }

    @Test func bestSelectionWithSix() {
        let s = Scoring.bestSelection([1, 2, 3, 4, 5, 5], fullThrow: true, rules: five)
        #expect(s.points == 1_050 && s.indices.count == 6)
        let t = Scoring.bestSelection([2, 2, 2, 4, 4, 4], fullThrow: true, rules: five)
        #expect(t.points == 600)
        let n = Scoring.bestSelection([2, 3, 4, 6, 6, 2], fullThrow: true, rules: five)
        #expect(n.points == 0)
        #expect(!Scoring.canScore([2, 3, 4, 6, 6, 2]))
    }
}

@MainActor
struct SixDiceGameTests {
    private func makeStore(rolls: [Int] = [], settings: GameSettings) -> GameStore {
        let store = GameStore(repository: MemoryRepository(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var queue = rolls
        store.roller = { queue.isEmpty ? 2 : queue.removeFirst() }
        var s = settings
        s.nextPlayerOverlay = false
        store.startGame(players: [Player(name: "A", avatar: "", colorIndex: 0), Player(name: "B", avatar: "", colorIndex: 1)], settings: s)
        return store
    }

    @Test func digitalRollsSixAndHotDice() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4, 6,   1, 1, 1, 5,   2, 3, 4, 5, 6, 1],
                              settings: GameSettings(diceCount: 6))
        #expect(store.turn.count == 6)
        store.roll()
        #expect(store.turn.dice == [1, 5, 2, 3, 4, 6])
        #expect(store.bestSelection.count == 6)            // 5er-Straße 2–6 + 1 = 1.100
        store.selectBest()
        #expect(store.turnTotal == 1_100)
        store.roll()                                       // alle 6 punkten → mit allen 6 weiter
        #expect(store.turn.banked == 1_100)
        #expect(store.turn.openCount == 6 && store.turn.fullThrow)
        store.selectBest()
        #expect(store.turnTotal == 1_100 + 1_050)          // 1-1-1 + 5 aus 1,1,1,5,2,3
        store.endTurn()
        #expect(store.game?.offer?.dice.count == 6)
    }

    @Test func layOutWithSixAndOffer() {
        let store = makeStore(settings: GameSettings(diceMode: .real, realEntry: .pips, diceCount: 6, straight6: .full))
        #expect(store.keptScore([1, 2, 3, 4, 5, 6]) == Scoring.bigStraightPoints)
        #expect(store.keptScore([1, 1, 1, 5, 5, 5, 5]) == nil)       // mehr als 6
        store.layOut([1, 5], bank: false)
        #expect(store.turn.openCount == 4)
        store.layOut([1], bank: true)
        #expect(store.game?.players[0].score == 250)
        let offer = store.game?.offer
        #expect(offer?.dice.count == 6 && offer?.openCount == 3)
        store.acceptOffer()
        #expect(store.turn.openCount == 3 && store.turn.count == 6)
        store.layOut([5, 5, 5], bank: false)                          // alle raus → mit allen 6 weiter
        #expect(store.turn.openCount == 6)
        #expect(store.keptScore([1, 2, 3, 4, 5, 6]) == Scoring.bigStraightPoints) // nach eigenem „alle raus“ wieder Straße
        #expect(store.game?.isConsistent == true)
    }

    @Test func noStraightRightAfterInheritingSix() {
        let store = makeStore(settings: GameSettings(diceMode: .real, realEntry: .pips, diceCount: 6))
        store.layOut([1, 1, 1, 5, 5, 5], bank: true)                  // alle 6 raus → Angebot mit allen 6
        #expect(store.game?.offer?.allOut == true)
        store.acceptOffer()
        #expect(store.turn.openCount == 6)
        #expect(store.keptScore([1, 2, 3, 4, 5]) == nil)
        #expect(store.keptScore([1]) == 100)
    }

    @Test func rulesDecodeAndSummary() throws {
        let old = try JSONDecoder().decode(GameRules.self, from: Data(#"{"goal":10000}"#.utf8))
        #expect(old.diceCount == 5 && old.straight6 == .five)
        let bad = try JSONDecoder().decode(GameRules.self, from: Data(#"{"diceCount":9}"#.utf8))
        #expect(bad.diceCount == 5)
        let six = GameRules(diceCount: 6, straight6: .full)
        let back = try JSONDecoder().decode(GameRules.self, from: JSONEncoder().encode(six))
        #expect(back == six)
        #expect(RulesSummary.text(GameRules(diceCount: 6)).contains("6 Würfel · 5er-Straße"))
        #expect(RulePreset.matching(GameRules(diceCount: 6)) == .sixDice)
        #expect(RulePreset.matching(GameRules()) == .standard)
    }

    @Test func oldSavedGameStaysWithFive() throws {
        let state = GameState(players: [Player(name: "A", avatar: "", colorIndex: 0), Player(name: "B", avatar: "", colorIndex: 1)],
                              settings: GameSettings())
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as! [String: Any]
        var settings = json["settings"] as! [String: Any]
        var rules = settings["rules"] as! [String: Any]
        rules["diceCount"] = nil
        rules["straight6"] = nil
        settings["rules"] = rules
        json["settings"] = settings
        let loaded = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(loaded.settings.rules.diceCount == 5 && loaded.turn.count == 5 && loaded.isConsistent)
    }

    /// Regression (Fund Chat 5): Nach einer Übernahme hatte `selected` 5 statt 6 Einträge –
    /// der gespeicherte Stand galt als unstimmig und wurde beim Laden übersprungen.
    @Test(arguments: [DiceMode.digital, .real])
    func offerWithSixSurvivesSaveAndLoad(mode: DiceMode) throws {
        let dir = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let repo = FileGameRepository(directory: dir)
        let store = GameStore(repository: repo, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var queue = [1, 5, 2, 3, 4, 6,   2, 2, 3, 4]
        store.roller = { queue.isEmpty ? 2 : queue.removeFirst() }
        var s = GameSettings(diceMode: mode, realEntry: .pips, diceCount: 6)
        s.nextPlayerOverlay = false
        store.startGame(players: [Player(name: "A", avatar: "", colorIndex: 0), Player(name: "B", avatar: "", colorIndex: 1)], settings: s)
        if mode == .digital {
            store.roll()
            store.perform(.bank(keep: [0, 1]))
        } else {
            store.layOut([1, 5], bank: true)
        }
        #expect(store.game?.offer != nil)
        store.declineOffer()
        store.undo()                                   // Angebot wieder offen
        store.acceptOffer()
        let g = try #require(store.game)
        #expect(g.turn.dice.count == 6 && g.turn.locked.count == 6 && g.turn.selected.count == 6)
        #expect(g.isConsistent)

        let reloaded = GameStore(repository: FileGameRepository(directory: dir), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(reloaded.pausedGames.count == 1)
        #expect(reloaded.pausedGames.first?.state.turn.selected.count == 6)
    }
}
