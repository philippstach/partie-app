// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import Testing
@testable import SpielGalgenmaennchen

/// Zufällige Komplett-Partien: Es darf nie eine Sackgasse geben (jede Runde endet), die Statistik zählt jede genau
/// einmal, und nach jedem Zug ergibt Speichern + Laden denselben Stand.
@MainActor
struct DurchspielTests {
    final class Seeds { var next: UInt64 = 1000; func take() -> UInt64 { defer { next += 1 }; return next } }

    private func makeStore(file: URL, language: WordLanguage) -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "durchspiel-\(UUID())")!)
        prefs.wordLanguage = language
        return GameStore(repository: GameRepository(url: file), preferences: prefs, seedSource: Seeds().take)
    }

    private func spiele(language: WordLanguage, runden: Int, seed: UInt64) {
        let file = FileManager.default.temporaryDirectory.appending(path: "galgen-durchspiel-\(UUID()).json")
        var rng = SplitMix64(seed: seed)
        let store = makeStore(file: file, language: language)
        let cats: [SpielGalgenmaennchen.Category?] = [nil] + SpielGalgenmaennchen.Category.allCases.map { Optional($0) }
        let levels: [Difficulty?] = [nil] + Difficulty.allCases.map { Optional($0) }

        for i in 0..<runden {
            store.startGame(category: cats[Int(rng.next() % UInt64(cats.count))],
                            difficulty: levels[Int(rng.next() % UInt64(levels.count))],
                            kids: i % 7 == 0)
            var schritte = 0
            while let g = store.game, g.status == .playing {
                schritte += 1
                #expect(schritte < 80, "Runde endet nicht")
                if schritte >= 80 { return }
                switch rng.next() % 10 {
                case 0: _ = store.hint([HintKind.random, .first, .vowel][Int(rng.next() % 3)])
                case 1: _ = store.solve(String(g.solution.shuffled(using: &rng)))      // falscher Lösungsversuch
                case 2 where g.mistakes >= 0 && rng.next() % 5 == 0: _ = store.solve(g.solution)   // gelegentlich richtig lösen
                default:
                    let letter = g.language.alphabet.filter { !g.guessed.contains($0) }.randomElement(using: &rng)
                    if let letter { store.guess(String(letter)) }
                }
                // Speichern und Laden ergibt denselben Stand
                if schritte % 5 == 0 { #expect(makeStore(file: file, language: language).game == store.game) }
            }
            #expect(store.game?.status != .playing)
        }
        #expect(store.stats.played == runden)
        #expect(store.stats.won <= store.stats.played)
    }

    @Test func deutschSpielen() { spiele(language: .de, runden: 60, seed: 11) }
    @Test func englischSpielen() { spiele(language: .en, runden: 60, seed: 22) }
}

private extension Array where Element == Character {
    func shuffled(using rng: inout SplitMix64) -> [Character] {
        var a = self
        for i in stride(from: a.count - 1, to: 0, by: -1) { a.swapAt(i, Int(rng.next() % UInt64(i + 1))) }
        return a
    }
}
private extension String {
    func shuffled(using rng: inout SplitMix64) -> [Character] { Array(self).shuffled(using: &rng) }
}
