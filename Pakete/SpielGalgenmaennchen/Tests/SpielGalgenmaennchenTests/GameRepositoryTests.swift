// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielGalgenmaennchen

struct GameRepositoryTests {
    private func tempRepository() -> GameRepository {
        GameRepository(url: FileManager.default.temporaryDirectory.appending(path: "galgen-test-\(UUID()).json"))
    }

    @Test func speichernUndLadenErgibtDasGleiche() throws {
        let repo = tempRepository()
        var data = SaveData()
        data.stats.record(.won(difficulty: .easy, mistakes: 2, hints: 0))
        data.game = Game(solution: "KÄSE", language: .de, category: .food, difficulty: .easy, displayText: "Käse")
        data.game?.guess("k")
        data.recent["de"] = ["KÄSE"]
        data.lastCategory = .food
        data.lastDifficulty = .easy
        try repo.save(data)
        #expect(repo.load() == data)
    }

    @Test func fehlendeDateiErgibtStandardwerte() {
        #expect(tempRepository().load() == SaveData())
    }

    @Test func fehlendeFelderErgebenStandardwerte() throws {
        let repo = tempRepository()
        try Data(#"{"stats":{"played":2},"game":{"solution":"HUND"}}"#.utf8).write(to: repo.url)
        let loaded = repo.load()
        #expect(loaded.version == 1)
        #expect(loaded.stats.played == 2)
        #expect(loaded.stats.won == 0)
        #expect(loaded.stats.distribution == [Int](repeating: 0, count: 8))
        #expect(loaded.game?.solution == "HUND")
        #expect(loaded.game?.mode == .single)
        #expect(loaded.game?.guessed == [])
        #expect(loaded.game?.maxMistakes == 8)
        #expect(loaded.recent.isEmpty)
    }

    @Test func kaputteDateiErgibtStandardwerte() throws {
        let repo = tempRepository()
        try Data("kein json".utf8).write(to: repo.url)
        #expect(repo.load() == SaveData())
    }

    @Test func kaputtesSpielWirdVerworfenStatistikBleibt() throws {
        let repo = tempRepository()
        try Data(#"{"stats":{"played":4},"game":{"unsinn":true}}"#.utf8).write(to: repo.url)
        let loaded = repo.load()
        #expect(loaded.game == nil)
        #expect(loaded.stats.played == 4)
    }
}
