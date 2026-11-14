// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import Testing
@testable import SpielGalgenmaennchen

@MainActor
struct AchievementTests {
    @Test func leereDatenHabenKeineErfolge() {
        #expect(Achievement.newlyEarned(in: SaveData()).isEmpty)
    }

    @Test func schwellenWerdenAusDemSpielstandBerechnet() {
        var data = SaveData()
        data.stats.record(.won(difficulty: .hard, mistakes: 7, hints: 0))
        let first = Set(Achievement.newlyEarned(in: data))
        #expect(first == [.firstWin, .lastBalloon])
        data.survivalBest = 10
        data.dailyStats.bestStreak = 7
        data.celebrated["de"] = ["animals"]
        let more = Set(Achievement.newlyEarned(in: data))
        #expect(more.isSuperset(of: [.survival5, .survival10, .daily7, .categoryFull]))
    }

    @Test func bereitsFreigeschalteteKommenNichtNochmal() {
        var data = SaveData()
        data.stats.record(.won(difficulty: .easy, mistakes: 0, hints: 0))
        data.achievements = Achievement.newlyEarned(in: data).map(\.rawValue)
        #expect(Achievement.newlyEarned(in: data).isEmpty)
        #expect(data.achievements.contains("perfect1"))
    }

    private func makeStore() -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        prefs.wordLanguage = .de
        var n: UInt64 = 0
        return GameStore(repository: GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "galgen-ach-\(UUID()).json")),
                         preferences: prefs, seedSource: { n += 1; return n })
    }

    @Test func siegSchaltetErfolgeFreiUndZuruecksetzenNimmtSieNichtWeg() {
        let store = makeStore()
        store.startGame(category: nil, difficulty: .easy)
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
        #expect(store.newAchievements.contains(.firstWin) && store.newAchievements.contains(.perfect1))
        #expect(store.achievements.contains(.firstWin))
        store.resetStats()
        #expect(store.achievements.contains(.firstWin))
        store.nextWord()
        #expect(store.newAchievements.isEmpty)
    }
}

@MainActor
struct KinderleichtTests {
    private func makeStore() -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        prefs.wordLanguage = .de
        var n: UInt64 = 0
        return GameStore(repository: GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "galgen-kids-\(UUID()).json")),
                         preferences: prefs, seedSource: { n += 1; return n })
    }

    @Test func kinderleichtGibtLeichteWoerterUndVierHinweise() {
        let store = makeStore()
        store.startGame(category: nil, difficulty: .hard, kids: true)
        #expect(store.game?.difficulty == .easy && store.game?.kids == true)
        #expect(store.game?.hintLimit == 4)
        var rng = SplitMix64(seed: 1)
        var kidsGame = Game(solution: "ABCDEFGHIJ", language: .de, kids: true)
        var normalGame = Game(solution: "ABCDEFGHIJ", language: .de)
        for _ in 0..<2 { _ = kidsGame.hint(using: &rng); _ = normalGame.hint(using: &rng) }
        #expect(kidsGame.canHint && !normalGame.canHint)
        for _ in 0..<2 { _ = kidsGame.hint(using: &rng) }
        #expect(kidsGame.hints.count == 4 && !kidsGame.canHint)
    }

    @Test func normalesSpielHatWeiterZweiHinweiseUndNextWordMerktKinderleicht() {
        let store = makeStore()
        store.startGame(category: nil, difficulty: .medium)
        #expect(store.game?.hintLimit == 2 && store.game?.kids == false)
        store.startGame(category: nil, difficulty: .medium, kids: true)
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
        store.nextWord()
        #expect(store.game?.kids == true && store.game?.difficulty == .easy)
    }

    @Test func aeltererSpielstandOhneKinderleichtLaedt() throws {
        let json = #"{"solution":"HUND","language":"de"}"#
        let g = try JSONDecoder().decode(Game.self, from: Data(json.utf8))
        #expect(g.kids == false)
    }
}

struct HinweisArtTests {
    @Test func ersterBuchstabeUndVokalDeckenGezieltAuf() {
        var rng = SplitMix64(seed: 3)
        var g = Game(solution: "BANANE", language: .de)
        #expect(g.canHint(.first) && g.canHint(.vowel))
        #expect(g.hint(.first, using: &rng) == "B")
        #expect(!g.canHint(.first))                      // schon offen
        let vowel = g.hint(.vowel, using: &rng)
        #expect(vowel == "A" || vowel == "E")
        #expect(g.hints.count == 2 && !g.canHint)         // Limit 2
    }

    @Test func ohneVokalGehtDerVokalHinweisNicht() {
        let g = Game(solution: "BRT", language: .en)
        #expect(!g.canHint(.vowel) && g.canHint(.random))
    }
}
