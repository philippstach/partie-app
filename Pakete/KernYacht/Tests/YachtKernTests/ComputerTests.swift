// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
@testable import SpielYacht

struct ComputerTests {
    private func partie(level: ComputerLevel, seed: UInt64, joker: Bool) -> GameState {
        var rng = SeededGenerator(seed: seed)
        var s = GameState(playerNames: ["A", "B"], rules: Rules(joker: joker, kniffelBonus: joker ? 100 : 0))
        var guardCount = 0
        while !s.finished, guardCount < 2000 {
            let action = ComputerPlayer.decide(s, level: level)
            try! s.apply(action, roller: { Int.random(in: 1...6, using: &rng) })
            guardCount += 1
        }
        return s
    }

    @Test func gutBeendetPartienOhneFehler() {
        for seed in 1...3 { #expect(partie(level: .gut, seed: UInt64(seed), joker: seed % 2 == 0).finished) }
    }

    @Test func einfachBeendetPartienOhneFehler() {
        for seed in 1...30 { #expect(partie(level: .einfach, seed: UInt64(seed), joker: seed % 2 == 1).finished) }
    }

    @Test func gutIstImSchnittBesser() {
        func avg(_ l: ComputerLevel) -> Double {
            let totals = (1...4).map { seed -> Int in
                let s = partie(level: l, seed: UInt64(seed + 100), joker: false)
                return s.totals(player: 0).total + s.totals(player: 1).total
            }
            return Double(totals.reduce(0, +)) / Double(totals.count * 2)
        }
        #expect(avg(.gut) > avg(.einfach))
    }

    @Test func ersterSchrittIstWuerfeln() {
        let s = GameState(playerNames: ["A"])
        #expect(ComputerPlayer.decide(s, level: .gut) == .roll(keep: []))
    }

    @Test func yachtWirdNichtNeuGeworfen() {
        var s = GameState(playerNames: ["A"])
        var q = [5, 5, 5, 5, 5]
        try! s.apply(.roll(keep: []), roller: { q.removeFirst() })
        guard case .score(let c) = ComputerPlayer.decide(s, level: .gut) else { Issue.record("sollte werten"); return }
        #expect(c == .kniffel)
    }

    @Test func keepMostCommon() {
        #expect(ComputerPlayer.keepMostCommon([3, 3, 1, 6, 3]) == [0, 1, 4])
        #expect(ComputerPlayer.keepMostCommon([1, 2, 3, 4, 2]) == [1, 4])
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &* 6364136223846793005 &+ 1442695040888963407 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
