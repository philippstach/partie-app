// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Vorlagen, Regel-Zusammenfassung, Reihenfolge und die Einstellungen für alle Spiele.
struct RulePresetTests {
    @Test func standardMatchesDefaults() {
        #expect(RulePreset.matching(GameRules()) == .standard)
        #expect(RulePreset.standard.rules == GameRules())
    }

    @Test func presetsSetTheirRules() {
        #expect(RulePreset.short.rules.goal == 5_000)
        #expect(RulePreset.short.rules.triples == .all)
        #expect(RulePreset.onesAndFives.rules.triples == .onesAndFives)
        #expect(RulePreset.onesAndFives.rules.goal == 10_000)
    }

    /// Eine Vorlage ändert den Würfel-Schalter nicht.
    @Test func presetKeepsDiceMode() {
        let current = GameRules(goal: 20_000, penalty: 0, diceMode: .real)
        let applied = RulePreset.short.apply(to: current)
        #expect(applied.diceMode == .real)
        #expect(applied.goal == 5_000)
        #expect(applied.penalty == 500)
        #expect(RulePreset.matching(applied) == .short)
    }

    @Test func customRulesMatchNoPreset() {
        #expect(RulePreset.matching(GameRules(goal: 7_000)) == nil)
        #expect(RulePreset.matching(GameRules(inheritAllFive: false)) == nil)
    }

    @Test func summary() {
        #expect(RulesSummary.text(GameRules()) == "10.000 Punkte · Strafe 500 · alle Drillinge · ohne Rundenlimit")
        #expect(RulesSummary.text(GameRules(goal: 5_000, roundLimit: 10, penalty: 0, triples: .onesAndFives, tiebreak: false))
                == "5.000 Punkte · ohne Strafe · nur Einsen und Fünfen · 10 Runden · ohne Stechen")
        #expect(RulesSummary.text(GameRules(roundLimit: 1, inheritAllFive: false))
                == "10.000 Punkte · Strafe 500 · alle Drillinge · 1 Runde · ohne Übernahme mit allen 5")
    }
}

struct PlayerOrderTests {
    private func players(_ scores: [Int]) -> [Player] {
        scores.enumerated().map { i, s in
            var p = Player(name: "P\(i)", avatar: "🎲", colorIndex: i)
            p.score = s
            return p
        }
    }

    /// „Wer fängt an?“ dreht die Reihenfolge, der Kreis bleibt gleich.
    @Test func startingRotates() {
        #expect(PlayerOrder.starting(["A", "B", "C", "D"], at: 2) == ["C", "D", "A", "B"])
        #expect(PlayerOrder.starting(["A", "B", "C"], at: 0) == ["A", "B", "C"])
        #expect(PlayerOrder.starting(["A", "B"], at: 5) == ["A", "B"])
        #expect(PlayerOrder.starting([String](), at: 0) == [])
    }

    @Test func shuffleKeepsEveryone() {
        var generator = SeededGenerator(seed: 42)
        let items = Array(1...8)
        let shuffled = PlayerOrder.shuffled(items, using: &generator)
        #expect(shuffled.sorted() == items)
    }

    /// Mischen liefert nie die bisherige Reihenfolge – bei 2 Spielern also immer getauscht.
    @Test func shuffleNeverKeepsOrder() {
        var generator = SeededGenerator(seed: 7)
        for _ in 0..<500 {
            #expect(PlayerOrder.shuffled(["A", "B"], using: &generator) == ["B", "A"])
            let three = PlayerOrder.shuffled(["A", "B", "C"], using: &generator)
            #expect(three != ["A", "B", "C"] && three.sorted() == ["A", "B", "C"])
        }
        #expect(PlayerOrder.shuffled(["A"], using: &generator) == ["A"])
        // Bei 3 Spielern kommen alle anderen 5 Reihenfolgen vor
        var seen = Set<[String]>()
        for _ in 0..<500 { seen.insert(PlayerOrder.shuffled(["A", "B", "C"], using: &generator)) }
        #expect(seen.count == 5)
    }

    @Test func loserStarts() {
        let ps = players([4_000, 10_050, 2_500, 6_000])
        #expect(PlayerOrder.loserIndex(ps) == 2)
        let order = PlayerOrder.starting(PlayerOrder.fresh(ps), at: 2)
        #expect(order.map(\.name) == ["P2", "P3", "P0", "P1"])
        #expect(order.allSatisfy { $0.score == 0 && $0.turns == 0 })
    }

    /// Gleichstand beim Letzten: der erste in Sitzreihenfolge
    @Test func loserTieTakesFirstSeat() {
        #expect(PlayerOrder.loserIndex(players([500, 200, 200])) == 1)
        #expect(PlayerOrder.loserIndex([]) == nil)
    }

    @Test func samePeopleIgnoresOrderAndScores() {
        let a = players([100, 200, 300])
        let b = PlayerOrder.fresh(Array(a.reversed()))
        #expect(PlayerOrder.samePeople(a, b))
        #expect(!PlayerOrder.samePeople(a, Array(b.dropLast())))
    }
}

@MainActor
struct AppPreferencesTests {
    private func emptyDefaults() -> UserDefaults { UserDefaults(suiteName: UUID().uuidString)! }

    @Test func defaultsWithoutAnything() {
        let prefs = AppPreferences(defaults: emptyDefaults())
        #expect(prefs.values == AppPreferences.Values())
        #expect(prefs.nextPlayerOverlay && !prefs.bestHint)
    }

    /// Einmalige Übernahme aus der letzten Einrichtung (früher lagen die Werte pro Spiel).
    @Test func migratesFromLastSetup() throws {
        let defaults = emptyDefaults()
        let old = GameSettings(nextPlayerOverlay: false, bestHint: true)
        let setup = GameStore.SavedSetup(players: [Player(name: "A", avatar: "😎", colorIndex: 0)], settings: old)
        defaults.set(try JSONEncoder().encode(setup), forKey: AppPreferences.legacySetupKey)

        let prefs = AppPreferences(defaults: defaults)
        #expect(!prefs.nextPlayerOverlay)
        #expect(prefs.bestHint)
    }

    @Test func changesAreSavedAndWinOverLastSetup() throws {
        let defaults = emptyDefaults()
        let setup = GameStore.SavedSetup(players: [], settings: GameSettings(bestHint: false))
        defaults.set(try JSONEncoder().encode(setup), forKey: AppPreferences.legacySetupKey)

        AppPreferences(defaults: defaults).bestHint = true
        #expect(AppPreferences(defaults: defaults).bestHint)
    }

    /// Vorauswahl der Punkte-Würfel: Standard an, auch für ältere gespeicherte Einstellungen ohne den Schlüssel.
    @Test func preselectDefaultsOnAndReachesGame() throws {
        let defaults = emptyDefaults()
        defaults.set(Data(#"{"sounds":false,"haptics":true,"nextPlayerOverlay":true,"bestHint":false}"#.utf8), forKey: AppPreferences.key)
        let prefs = AppPreferences(defaults: defaults)
        #expect(prefs.nextPlayerOverlay && !prefs.bestHint)   // alte Werte bleiben erhalten; frühere Schlüssel (Töne, Vibration) stören nicht
        #expect(prefs.preselect)        // neuer Schlüssel → Standard
        #expect(prefs.applied(to: GameSettings()).preselectsBest)
        prefs.preselect = false
        #expect(!prefs.applied(to: GameSettings()).preselectsBest)
        #expect(!prefs.applied(to: GameSettings(diceMode: .real)).preselectsBest)  // echte Würfel: keine Vorauswahl
    }

    /// Töne, Vibration und Hell/Dunkel gehören der Sammlung: Alte gespeicherte Werte mit diesen Schlüsseln laden weiter.
    @Test func alteSchluesselWerdenUeberlesen() throws {
        let defaults = emptyDefaults()
        defaults.set(Data(#"{"sounds":false,"haptics":false,"appearance":"sepia","bestHint":true}"#.utf8), forKey: AppPreferences.key)
        let prefs = AppPreferences(defaults: defaults)
        #expect(prefs.bestHint && prefs.nextPlayerOverlay)
        let alt = try JSONDecoder().decode(GameSettings.self, from: Data(#"{"haptics":false,"sounds":false,"bestHint":true}"#.utf8))
        #expect(alt.bestHint && alt.rules == GameRules())
    }

    @Test func applyOverwritesOnlyPersonalValues() {
        let prefs = AppPreferences(defaults: emptyDefaults())
        prefs.bestHint = true
        prefs.nextPlayerOverlay = false
        let game = GameSettings(goal: 5_000, diceMode: .real, triples: .onesAndFives, nextPlayerOverlay: true, bestHint: false, realEntry: .pips)
        let applied = prefs.applied(to: game)
        #expect(applied.bestHint)
        #expect(!applied.nextPlayerOverlay)
        #expect(applied.rules == game.rules)
        #expect(applied.realEntry == .pips)
        #expect(prefs.matches(applied))
        #expect(!prefs.matches(game))
    }

    /// Laufende Spiele übernehmen geänderte persönliche Werte.
    @Test func runningGameTakesPreferences() {
        let defaults = emptyDefaults()
        let store = GameStore(repository: MemoryRepository(), defaults: defaults)
        store.startGame(players: [Player(name: "A", avatar: "😎", colorIndex: 0), Player(name: "B", avatar: "🤠", colorIndex: 1)],
                        settings: GameSettings(nextPlayerOverlay: true, bestHint: false))
        let prefs = AppPreferences(defaults: defaults)
        prefs.values = .init(nextPlayerOverlay: false, bestHint: true)
        prefs.apply(to: store)
        #expect(store.game?.settings.nextPlayerOverlay == false)
        #expect(store.game?.settings.bestHint == true)
    }
}

/// Reproduzierbarer Zufall für Tests (SplitMix64)
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
