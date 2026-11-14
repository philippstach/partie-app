// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
@testable import Spiel10k

struct ScoringTests {
    @Test func singles() {
        #expect(Scoring.score([1], fullThrow: true) == 100)
        #expect(Scoring.score([5], fullThrow: true) == 50)
        #expect(Scoring.score([1, 5], fullThrow: true) == 150)
        #expect(Scoring.score([1, 1], fullThrow: false) == 200)
    }

    @Test func triples() {
        #expect(Scoring.score([1, 1, 1], fullThrow: true) == 1000)
        #expect(Scoring.score([2, 2, 2], fullThrow: true) == 200)
        #expect(Scoring.score([5, 5, 5], fullThrow: true) == 500)
        #expect(Scoring.score([6, 6, 6], fullThrow: true) == 600)
        #expect(Scoring.score([4, 4, 4, 1], fullThrow: true) == 500)
        #expect(Scoring.score([1, 1, 1, 1], fullThrow: true) == 1100)
        #expect(Scoring.score([5, 5, 5, 5, 1], fullThrow: true) == 650)
    }

    @Test func straights() {
        #expect(Scoring.score([3, 1, 5, 2, 4], fullThrow: true) == 1000)
        #expect(Scoring.score([6, 2, 5, 3, 4], fullThrow: true) == 1000)
        // Straße nur, wenn alle 5 in einem Wurf fielen
        #expect(Scoring.score([1, 2, 3, 4, 5], fullThrow: false) == nil)
    }

    @Test func invalidSelections() {
        #expect(Scoring.score([], fullThrow: true) == nil)
        #expect(Scoring.score([2], fullThrow: true) == nil)
        #expect(Scoring.score([1, 3], fullThrow: true) == nil)
        #expect(Scoring.score([2, 2], fullThrow: true) == nil)
        #expect(Scoring.score([2, 2, 2, 2], fullThrow: true) == nil)
    }

    @Test func niete() {
        #expect(!Scoring.canScore([2, 3, 4, 6, 6]))
        #expect(!Scoring.canScore([2, 3]))
        #expect(Scoring.canScore([2, 3, 4, 6, 5]))
        #expect(Scoring.canScore([2, 2, 2, 3, 4]))
        #expect(Scoring.canScore([1]))
    }

    @Test func best() {
        #expect(Scoring.best([1, 1, 1, 5, 2], fullThrow: true) == 1050)
        #expect(Scoring.best([1, 2, 3, 4, 5], fullThrow: true) == 1000)
        #expect(Scoring.best([2, 3, 4, 6, 6], fullThrow: true) == 0)
    }
}

struct BestSelectionTests {
    @Test func picksHighestScore() {
        let best = Scoring.bestSelection([1, 1, 1, 5, 2], fullThrow: true)
        #expect(best.points == 1050)
        #expect(Set(best.indices) == [0, 1, 2, 3])
    }

    @Test func prefersStraightInFullThrow() {
        #expect(Scoring.bestSelection([6, 2, 5, 3, 4], fullThrow: true).points == 1000)
        #expect(Scoring.bestSelection([6, 2, 5, 3, 4], fullThrow: false).points == 50)
    }

    @Test func noneOnNiete() {
        #expect(Scoring.bestSelection([2, 3, 4, 6, 6], fullThrow: true).indices.isEmpty)
    }

    /// Nur freie Würfel des aktuellen Wurfs werden markiert, gesperrte nie.
    @Test func turnHintSkipsLockedDice() {
        var t = DiceTurn()
        t.dice = [1, 5, 1, 3, 4]
        t.locked = [true, true, false, false, false]
        t.hasRolled = true
        t.fullThrow = false
        #expect(t.bestSelection(.standard) == [2])
    }
}

/// (4) Drilling-Regel „Nur Einsen und Fünfen“ (B) gegenüber „Alle Drillinge“ (A)
struct TripleRuleTests {
    @Test func otherTriplesDoNotCountInB() {
        #expect(Scoring.score([2, 2, 2], fullThrow: true, triples: .all) == 200)
        #expect(Scoring.score([2, 2, 2], fullThrow: true, triples: .onesAndFives) == nil)
        #expect(Scoring.score([6, 6, 6, 1], fullThrow: true, triples: .onesAndFives) == nil)
    }

    @Test func nieteDetection() {
        #expect(Scoring.canScore([2, 2, 2, 3, 4], triples: .all))
        #expect(!Scoring.canScore([2, 2, 2, 3, 4], triples: .onesAndFives))
        #expect(Scoring.best([2, 2, 2, 3, 4], fullThrow: true, triples: .all) == 200)
        #expect(Scoring.best([2, 2, 2, 3, 4], fullThrow: true, triples: .onesAndFives) == 0)
    }

    @Test func onesAndFivesSameInBoth() {
        for rule in TripleRule.allCases {
            #expect(Scoring.score([5, 5, 5], fullThrow: true, triples: rule) == 500)
            #expect(Scoring.score([2, 3, 4, 5, 6], fullThrow: true, triples: rule) == 1000)
            #expect(Scoring.score([1, 5], fullThrow: false, triples: rule) == 150)
        }
    }

    /// Entscheidung Philipp: bei „Nur Einsen und Fünfen“ sind drei Einsen 500 statt 1.000.
    @Test func threeOnesDependOnRule() {
        #expect(Scoring.score([1, 1, 1], fullThrow: true, triples: .all) == 1000)
        #expect(Scoring.score([1, 1, 1, 1], fullThrow: true, triples: .all) == 1100)
        #expect(Scoring.score([1, 1, 1, 1, 1], fullThrow: true, triples: .all) == 1200)
        #expect(Scoring.score([1, 1, 1], fullThrow: true, triples: .onesAndFives) == 500)
        #expect(Scoring.score([1, 1, 1, 1], fullThrow: true, triples: .onesAndFives) == 600)
        #expect(Scoring.score([1, 1, 1, 1, 1], fullThrow: true, triples: .onesAndFives) == 700)
        #expect(Scoring.score([1, 1, 1, 5, 5], fullThrow: true, triples: .onesAndFives) == 600)
        #expect(Scoring.score([5, 5, 5, 5], fullThrow: true, triples: .onesAndFives) == 550)
        // Drilling bleibt besser als drei einzelne Einsen
        let best = Scoring.bestSelection([1, 1, 1, 3, 4], fullThrow: true, triples: .onesAndFives)
        #expect(best.points == 500 && best.indices == [0, 1, 2])
    }

    @Test func bestSelectionIgnoresOtherTriplesInB() {
        let b = Scoring.bestSelection([4, 4, 4, 1, 3], fullThrow: true, triples: .onesAndFives)
        #expect(b.points == 100 && b.indices == [3])
        let a = Scoring.bestSelection([4, 4, 4, 1, 3], fullThrow: true, triples: .all)
        #expect(a.points == 500)
    }
}

