// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielGalgenmaennchen

@MainActor
struct SurvivalTests {
    @Test func stufeSteigtMitDenSiegen() {
        var run = SurvivalRun()
        #expect(run.nextDifficulty == .easy)
        for _ in 0..<3 { run.finishWord(won: true, mistakes: 5, hints: 0) }
        #expect(run.nextDifficulty == .medium)
        for _ in 0..<4 { run.finishWord(won: true, mistakes: 5, hints: 0) }
        #expect(run.nextDifficulty == .hard)
    }

    @Test func niederlageKostetEinLebenBisZumEnde() {
        var run = SurvivalRun()
        for _ in 0..<SurvivalRun.startLives { run.finishWord(won: false, mistakes: 8, hints: 0) }
        #expect(run.lives == 0 && run.isOver && run.wins == 0 && run.played == 3)
    }

    @Test func gutesWortBringtLebenZurueckHoechstensBisZumLimit() {
        var run = SurvivalRun()
        run.finishWord(won: false, mistakes: 8, hints: 0)
        #expect(run.lives == 2)
        let bonus = run.finishWord(won: true, mistakes: 1, hints: 0)
        #expect(bonus && run.lives == 3)
        let tooMany = run.finishWord(won: true, mistakes: 2, hints: 0)   // zu viele Fehler
        let hinted = run.finishWord(won: true, mistakes: 0, hints: 1)    // Hinweis benutzt
        #expect(!tooMany && !hinted && run.lives == 3)
        for _ in 0..<5 { run.finishWord(won: true, mistakes: 0, hints: 0) }
        #expect(run.lives == SurvivalRun.maxLives)
    }

    @Test func fehlendeFelderBeimLadenGebenStandardwerte() throws {
        let run = try JSONDecoder().decode(SurvivalRun.self, from: Data("{}".utf8))
        #expect(run == SurvivalRun())
    }

    // MARK: Store

    private func makeStore(url: URL = FileManager.default.temporaryDirectory.appending(path: "galgen-surv-\(UUID()).json")) -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        prefs.wordLanguage = .de
        var n: UInt64 = 0
        return GameStore(repository: GameRepository(url: url), preferences: prefs, seedSource: { n += 1; return n })
    }

    private func win(_ store: GameStore) {
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
    }

    private func lose(_ store: GameStore) {
        while store.game?.status == .playing {
            let g = store.game!
            store.guess(String(g.language.alphabet.first { !g.solution.contains($0) && !g.guessed.contains($0) }!))
        }
    }

    @Test func serieStartetMitLeichtemWortUndZaehltNichtInDieStatistik() throws {
        let store = makeStore()
        store.startSurvival()
        #expect(store.game?.mode == .survival && store.game?.difficulty == .easy)
        win(store)
        #expect(store.survival?.wins == 1 && store.survivalBest == 1)
        #expect(store.stats.played == 0)
        #expect(store.progress(for: .de).values.contains { $0.found > 0 })   // Sieg landet in der Sammlung
    }

    @Test func dreiNiederlagenBeendenDieSerieRekordBleibt() {
        let store = makeStore()
        store.startSurvival()
        win(store)
        #expect(store.survival?.lives == SurvivalRun.startLives + 1)   // perfekter Sieg bringt ein Leben
        while store.survivalActive != nil {
            store.startSurvivalWord()
            lose(store)
        }
        #expect(store.survival?.isOver == true && store.survivalActive == nil)
        store.startSurvivalWord()   // keine Leben: kein neues Wort
        #expect(store.game?.status == .lost)
        store.goHome()
        #expect(store.survival == nil && store.survivalBest == 1)
    }

    @Test func aufgebenMitRateversuchKostetEinLeben() {
        let store = makeStore()
        store.startSurvival()
        store.guess("E")
        store.startGame(category: nil, difficulty: nil)
        #expect(store.survival?.lives == SurvivalRun.startLives - 1)
    }

    @Test func serieUndRekordUeberstehenNeustart() {
        let file = FileManager.default.temporaryDirectory.appending(path: "galgen-surv-\(UUID()).json")
        let store = makeStore(url: file)
        store.startSurvival()
        win(store)
        let reloaded = makeStore(url: file)
        #expect(reloaded.survival?.wins == 1 && reloaded.survivalBest == 1)
        reloaded.goHome()
        reloaded.continueSurvival()
        #expect(reloaded.game?.mode == .survival && reloaded.game?.status == .playing)
    }

    @Test func serieFortsetzenWertetLaufendesEinzelspielAlsAufgegeben() {
        let store = makeStore()
        store.startSurvival()
        win(store)
        store.goHome()
        store.startGame(category: nil, difficulty: .medium)
        store.guess("E")
        store.goHome()
        store.continueSurvival()
        #expect(store.game?.mode == .survival)
        #expect(store.stats.played == 1)
    }

    @Test func tageswortKeyIstUnabhaengigVomGeraetekalender() {
        let date = Date(timeIntervalSince1970: 1_793_000_000)
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = .current
        let key = DayKey.string(for: date)
        #expect(key.hasPrefix("2026"))
        #expect(DayKey.string(for: date, calendar: buddhist).hasPrefix("2569"))
    }
}
