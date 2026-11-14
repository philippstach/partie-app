// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielYacht

private typealias Category = SpielYacht.Category

final class HoldAdvisorTests: XCTestCase {
    private func state(dice: [Int], rollsUsed: Int, taken: [Category: Int] = [:], rules: Rules = Rules()) -> GameState {
        var s = GameState(playerNames: ["A"], rules: rules)
        s.players[0].scores = taken
        s.dice = dice
        s.rollsUsed = rollsUsed
        return s
    }

    private func allExcept(_ free: [Category]) -> [Category: Int] {
        Dictionary(uniqueKeysWithValues: Category.allCases.filter { !free.contains($0) }.map { ($0, 0) })
    }

    func testVierSechserWerdenGehalten() throws {
        let a = try XCTUnwrap(HoldAdvisor.advise(state(dice: [6, 6, 6, 6, 1], rollsUsed: 1)))
        XCTAssertEqual(a.keep, [0, 1, 2, 3])
    }

    func testFuenflingBleibt() throws {
        let s = state(dice: [5, 5, 5, 5, 5], rollsUsed: 1, taken: allExcept([.kniffel, .chance]))
        let a = try XCTUnwrap(HoldAdvisor.advise(s))
        XCTAssertTrue(a.keepsAll)
    }

    func testGrosseStrasseNurNochFrei() throws {
        let s = state(dice: [1, 2, 3, 4, 6], rollsUsed: 1, taken: allExcept([.largeStraight]))
        let a = try XCTUnwrap(HoldAdvisor.advise(s))
        XCTAssertEqual(a.keep.count, 4)
        XCTAssertTrue(a.keep.map { s.dice[$0] }.contains(where: { [2, 3, 4].contains($0) }))
    }

    func testKeinRatVorDemWurfOderNachDemDritten() {
        XCTAssertNil(HoldAdvisor.advise(state(dice: [], rollsUsed: 0)))
        XCTAssertNil(HoldAdvisor.advise(state(dice: [1, 2, 3, 4, 5], rollsUsed: 3)))
    }

    /// Unabhängige Kontrolle ohne Mustertricks: alle 6^k Ausgänge, alle 32 Halte-Masken.
    func testLetzterWurfStimmtMitBruteForceUeberein() throws {
        let taken = allExcept([.ones, .fullHouse, .largeStraight, .chance])
        let dice = [2, 2, 5, 5, 5]
        let s = state(dice: dice, rollsUsed: 2, taken: taken)

        func utilityOf(_ d: [Int]) -> Double {
            Category.allCases.filter { taken[$0] == nil }
                .map { Double(Scoring.score(d, $0)) - (HoldAdvisor.par[$0] ?? 0) }.max()!
        }
        func expected(mask: Int) -> Double {
            let rolled = (0..<5).filter { mask & (1 << $0) == 0 }
            var total = 0.0
            let count = Int(pow(6.0, Double(rolled.count)))
            for n in 0..<count {
                var d = dice, m = n
                for i in rolled { d[i] = m % 6 + 1; m /= 6 }
                total += utilityOf(d)
            }
            return total / Double(count)
        }
        let best = (0..<32).map(expected(mask:)).max()!
        let advice = try XCTUnwrap(HoldAdvisor.advise(s))
        XCTAssertEqual(advice.expected, best, accuracy: 1e-9)
        let mask = advice.keep.reduce(0) { $0 | (1 << $1) }
        XCTAssertEqual(expected(mask: mask), best, accuracy: 1e-9)
    }

    func testZweiWuerfeProMehrAlsEiner() throws {
        let taken = allExcept([.kniffel, .chance, .sixes])
        let one = try XCTUnwrap(HoldAdvisor.advise(state(dice: [6, 6, 3, 4, 1], rollsUsed: 2, taken: taken)))
        let two = try XCTUnwrap(HoldAdvisor.advise(state(dice: [6, 6, 3, 4, 1], rollsUsed: 1, taken: taken)))
        XCTAssertGreaterThanOrEqual(two.expected, one.expected - 1e-12)
        XCTAssertGreaterThanOrEqual(one.expected, one.stopValue)
    }

    func testJokerBeschraenktWahl() throws {
        // Yacht-Feld belegt, Joker an: mit Fünfling Sechser darf nur das obere Feld „Sechser“ gewählt werden
        let s = state(dice: [6, 6, 6, 6, 6], rollsUsed: 1,
                      taken: allExcept([.sixes, .chance]).merging([.kniffel: 50]) { $1 },
                      rules: Rules(joker: true))
        let a = try XCTUnwrap(HoldAdvisor.advise(s))
        XCTAssertTrue(a.keepsAll)
        XCTAssertEqual(a.stopValue, 30 - (HoldAdvisor.par[.sixes] ?? 0), accuracy: 1e-9)
    }

    /// Wert mit einer unabhängigen Python-Rechnung (alle Würfe, zwei Stufen) bestätigt.
    func testZweiWuerfeStimmenMitPythonReferenzUeberein() throws {
        let s = state(dice: [4, 5, 3, 1, 6], rollsUsed: 1, taken: [.sixes: 12, .threes: 0])
        let a = try XCTUnwrap(HoldAdvisor.advise(s))
        XCTAssertEqual(a.keep, [0, 1, 2, 4])
        XCTAssertEqual(a.expected, 2.9608333333, accuracy: 1e-6)
        XCTAssertEqual(a.stopValue, 0.54, accuracy: 1e-9)
    }

    func testRechenzeit() {
        let s = state(dice: [1, 3, 3, 5, 6], rollsUsed: 1)
        measure { _ = HoldAdvisor.advise(s) }
    }
}
