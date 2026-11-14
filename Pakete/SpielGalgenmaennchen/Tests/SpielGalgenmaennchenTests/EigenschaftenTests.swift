// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import Testing
@testable import SpielGalgenmaennchen

/// Eigenschaften, die für jedes Wort beider Listen gelten müssen (Hinweise, Spielende).
struct EigenschaftenTests {
    struct W { let solution: String; let text: String; let language: WordLanguage; let category: SpielGalgenmaennchen.Category; let difficulty: Difficulty }
    private func alleWoerter() throws -> [W] {
        try WordLanguage.alle.flatMap { l in
            try WordList.load(l).words.map { W(solution: $0.solution, text: $0.text, language: l, category: $0.category, difficulty: $0.difficulty) }
        }
    }

    @Test func hinweiseDeckenNieDenLetztenBuchstabenAufUndGewinnenNie() throws {
        var rng = SplitMix64(seed: 7)
        for w in try alleWoerter() {
            for kind in HintKind.allCases {
                var g = Game(solution: w.solution, language: w.language, category: w.category, difficulty: w.difficulty)
                while g.hint(kind, using: &rng) != nil {}
                #expect(g.status == GameStatus.playing, Comment(rawValue: "\(w.solution) \(kind)"))
                #expect(g.hints.count <= g.hintLimit)
                #expect(g.mistakes == 0)
            }
        }
    }

    @Test func spielEndetImmerNachAchtFehlernUndDasWortWirdGezeigt() throws {
        for w in try alleWoerter() {
            var g = Game(solution: w.solution, language: w.language, category: w.category, difficulty: w.difficulty)
            for c in g.language.alphabet where g.status == .playing && !w.solution.contains(c) { g.guess(String(c)) }
            #expect(g.status == GameStatus.lost)
            #expect(g.mistakes == 8)
            #expect(g.display == w.solution)
        }
    }

    @Test func richtigesWortGewinntUndKostetNichts() throws {
        for w in try alleWoerter() {
            var g = Game(solution: w.solution, language: w.language, category: w.category, difficulty: w.difficulty)
            #expect(g.solve(w.text) == .solved)
            #expect(g.status == GameStatus.won)
            #expect(g.mistakes == 0)
        }
    }

    @Test func nachDemEndeGeschiehtNichtsMehr() throws {
        let w = try #require(try alleWoerter().first)
        var g = Game(solution: w.solution, language: w.language, category: w.category, difficulty: w.difficulty)
        _ = g.solve(w.text)
        let vorher = g
        #expect(g.guess("A") == .over)
        #expect(g.solve("xyz") == .over)
        var rng = SplitMix64(seed: 1)
        #expect(g.hint(.random, using: &rng) == nil)
        #expect(g == vorher)
    }
}
