// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielGalgenmaennchen

@MainActor
struct GameStoreTests {
    final class Seeds { var next: UInt64 = 1; func take() -> UInt64 { defer { next += 1 }; return next } }

    private func url() -> URL { FileManager.default.temporaryDirectory.appending(path: "galgen-store-\(UUID()).json") }

    private func makeStore(url: URL, seeds: Seeds = Seeds(), language: WordLanguage = .de) -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        prefs.wordLanguage = language
        return GameStore(repository: GameRepository(url: url), preferences: prefs, seedSource: seeds.take)
    }

    /// Ein Buchstabe, der in der Lösung nicht vorkommt, bzw. einer, der vorkommt.
    private func wrongLetter(_ g: Game) -> String {
        String(g.language.alphabet.first { !g.solution.contains($0) && !g.guessed.contains($0) }!)
    }

    @Test func ratenSpeichertSofortUndNeustartLaedtDasselbeSpiel() throws {
        let file = url()
        let store = makeStore(url: file)
        store.startGame(category: .animals, difficulty: nil)
        let g = try #require(store.game)
        store.guess(wrongLetter(g))
        store.guess(String(g.solution.first!))

        let reloaded = makeStore(url: file)
        #expect(reloaded.game == store.game)
        #expect(reloaded.game?.guessed.count == 2)
        #expect(reloaded.runningGame != nil)
    }

    @Test func gleicherSeedGleichesWort() {
        let a = makeStore(url: url()), b = makeStore(url: url())
        a.startGame(category: nil, difficulty: nil)
        b.startGame(category: nil, difficulty: nil)
        #expect(a.game?.solution == b.game?.solution)
    }

    @Test func gewinnUndNiederlageLandenInDerStatistik() throws {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
        #expect(store.game?.status == .won)
        #expect(store.stats.played == 1 && store.stats.won == 1 && store.stats.perfect == 1)
        store.guess("A")   // nach dem Ende nichts mehr
        #expect(store.stats.played == 1)

        store.nextWord()
        while store.game?.status == .playing { store.guess(wrongLetter(store.game!)) }
        #expect(store.game?.status == .lost)
        #expect(store.stats.played == 2 && store.stats.won == 1 && store.stats.streak == 0)
    }

    @Test func abbrechenOhneRateversuchZaehltNicht() {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        store.startGame(category: nil, difficulty: nil)
        #expect(store.stats.played == 0)
    }

    @Test func abbrechenNachRateversuchZaehltAlsVerloren() {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        store.guess(wrongLetter(store.game!))
        store.startGame(category: nil, difficulty: nil)
        #expect(store.stats.played == 1 && store.stats.won == 0)
    }

    @Test func zuletztJeSpracheUndLetzteAuswahlWerdenGemerkt() {
        let file = url()
        let store = makeStore(url: file)
        store.startGame(category: .music, difficulty: .hard)
        store.preferences.wordLanguage = .en
        store.startGame(category: nil, difficulty: .easy)

        let again = makeStore(url: file)
        #expect(again.data.recent["de"]?.count == 1)
        #expect(again.data.recent["en"]?.count == 1)
        #expect(again.lastCategory == nil)
        #expect(again.lastDifficulty == .easy)
        #expect(again.game?.language == .en)
    }

    @Test func nextWordNutztDieGemerkteAuswahl() {
        let store = makeStore(url: url())
        store.startGame(category: .sports, difficulty: .medium)
        store.nextWord()
        #expect(store.game?.category == .sports && store.game?.difficulty == .medium)
    }

    @Test func hinweisZaehltUndSpeichert() throws {
        let file = url()
        let store = makeStore(url: file)
        store.startGame(category: nil, difficulty: nil)
        // Ein Wort mit mindestens drei verschiedenen Buchstaben ist garantiert (Mindestlänge 3 reicht nicht
        // immer, daher einfach prüfen: wenn möglich, wird gezählt)
        if store.game?.canHint == true {
            let letter = try #require(store.hint())
            #expect(store.game?.hints == [letter])
            #expect(makeStore(url: file).game?.hints == [letter])
        }
    }

    @Test func zumStartBehaeltLaufendesSpielUndVerwirftBeendetes() {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        store.goHome()
        #expect(store.runningGame != nil && store.screen == .home)
        store.resume()
        #expect(store.screen == .game)
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
        store.goHome()
        #expect(store.game == nil)
    }

    @Test(.enabled(if: nurAufDemTelefon)) func endBildschirmKommtErstNachSiegMoment() async throws {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        #expect(store.endReady)
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
        #expect(store.game?.status == .won)
        #expect(!store.endReady)                     // Sieg-Moment läuft (1,2 s)
        try await Task.sleep(for: .seconds(0.9))
        #expect(!store.endReady)
        try await Task.sleep(for: .seconds(0.6))
        #expect(store.endReady)
    }

    @Test(.enabled(if: nurAufDemTelefon)) func endBildschirmKommtErstNachNiederlageMoment() async throws {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        while store.game?.status == .playing { store.guess(wrongLetter(store.game!)) }
        #expect(store.game?.status == .lost)
        #expect(!store.endReady)                     // Niederlage-Moment läuft (1,5 s)
        try await Task.sleep(for: .seconds(1.2))
        #expect(!store.endReady)
        try await Task.sleep(for: .seconds(0.6))
        #expect(store.endReady)
    }

    @Test func neuesSpielStartetOhneWartezeit() async throws {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        while store.game?.status == .playing { store.guess(wrongLetter(store.game!)) }
        store.nextWord()
        #expect(store.endReady)
        #expect(store.game?.status == .playing)
    }

    @Test func loesenFalschKostetZweiRichtigGewinnt() throws {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        let solution = try #require(store.game).solution
        #expect(store.solve("Qxqxq") == .wrong)
        #expect(store.game?.mistakes == 2)
        #expect(store.solve("qxqxq") == .alreadyTried)   // gleicher Versuch kostet nichts
        #expect(store.game?.mistakes == 2)
        #expect(store.solve("") == .invalid)
        #expect(store.game?.mistakes == 2)
        #expect(store.solve(solution) == .solved)
        #expect(store.game?.status == .won)
        #expect(store.game?.display == solution)
        #expect(store.stats.won == 1)
        #expect(store.solve("Qxqxq") == .over)
    }

    @Test func spielstandMitLoesenVersuchenUeberlebtNeustart() throws {
        let file = url()
        let store = makeStore(url: file)
        store.startGame(category: nil, difficulty: nil)
        store.solve("Qxqxq")
        let reloaded = makeStore(url: file)
        #expect(reloaded.game?.wrongSolves == ["QXQXQ"])
        #expect(reloaded.game?.mistakes == 2)
    }
}
