// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielYacht

final class YachtRegelnTests: XCTestCase {
    func testWertungGrundfelder() {
        XCTAssertEqual(Scoring.score([3, 3, 3, 4, 5], .threes), 9)
        XCTAssertEqual(Scoring.score([2, 2, 2, 4, 5], .threeOfAKind), 15)
        XCTAssertEqual(Scoring.score([2, 2, 4, 4, 5], .threeOfAKind), 0)
        XCTAssertEqual(Scoring.score([6, 6, 6, 6, 1], .fourOfAKind), 25)
        XCTAssertEqual(Scoring.score([2, 2, 3, 3, 3], .fullHouse), 25)
        XCTAssertEqual(Scoring.score([2, 2, 2, 2, 2], .fullHouse), 0)                 // Fünflinge sind ohne Joker kein Full House
        XCTAssertEqual(Scoring.score([1, 2, 3, 4, 6], .smallStraight), 30)
        XCTAssertEqual(Scoring.score([1, 2, 3, 5, 6], .smallStraight), 0)
        XCTAssertEqual(Scoring.score([2, 3, 4, 5, 6], .largeStraight), 40)
        XCTAssertEqual(Scoring.score([1, 2, 3, 4, 6], .largeStraight), 0)
        XCTAssertEqual(Scoring.score([5, 5, 5, 5, 5], .kniffel), 50)
        XCTAssertEqual(Scoring.score([1, 2, 3, 4, 6], .chance), 16)
    }
    func testJokerZaehltVollInFestenFeldern() {
        let yacht = [4, 4, 4, 4, 4]
        XCTAssertEqual(Scoring.score(yacht, .fullHouse, joker: true), 25)
        XCTAssertEqual(Scoring.score(yacht, .smallStraight, joker: true), 30)
        XCTAssertEqual(Scoring.score(yacht, .largeStraight, joker: true), 40)
        XCTAssertEqual(Scoring.score(yacht, .fourOfAKind, joker: true), 20)
    }
    private func partie(_ rules: Rules = Rules(joker: true, kniffelBonus: 100)) -> GameState { GameState(playerNames: ["A", "B"], rules: rules) }
    private func wuerfle(_ s: inout GameState, _ augen: [Int]) throws {
        var i = 0
        try s.apply(.roll(keep: []), roller: { defer { i += 1 }; return augen[i] })
    }
    func testJokerPflichtOberesFeldZuerst() throws {
        var s = partie(); s.players[0].scores[.kniffel] = 50
        try wuerfle(&s, [4, 4, 4, 4, 4])
        XCTAssertTrue(s.jokerActive)
        XCTAssertEqual(s.legalCategories, [.fours])                          // passendes oberes Feld ist frei: Pflicht
        s.players[0].scores[.fours] = 8
        XCTAssertTrue(s.legalCategories.allSatisfy { !$0.isUpper })           // sonst ein unteres Feld
    }
    func testJokerObenFreiWennUntenVoll() throws {
        var s = partie(); s.players[0].scores[.kniffel] = 50; s.players[0].scores[.fours] = 8
        for c in Category.lower { s.players[0].scores[c] = s.players[0].scores[c] ?? 0 }
        try wuerfle(&s, [4, 4, 4, 4, 4])
        XCTAssertEqual(Set(s.legalCategories), Set(Category.upper.filter { s.players[0].scores[$0] == nil }))
    }
    func testYachtBonusNurBeiFuenfzigImYachtFeld() throws {
        var s = partie(); s.players[0].scores[.kniffel] = 50
        try wuerfle(&s, [2, 2, 2, 2, 2])
        try s.apply(.score(.twos), roller: { 1 })
        XCTAssertEqual(s.players[0].extraKniffels, 1)
        XCTAssertEqual(s.totals(player: 0).kniffelBonus, 100)
        var t = partie(); t.players[0].scores[.kniffel] = 0                  // gestrichen: kein Bonus
        try wuerfle(&t, [2, 2, 2, 2, 2])
        try t.apply(.score(.twos), roller: { 1 })
        XCTAssertEqual(t.players[0].extraKniffels, 0)
    }
    func testObererBonusGenauAnDerSchwelle() {
        var s = partie(Rules())
        for (c, n) in zip(Category.upper, [3, 6, 9, 12, 15, 18]) { s.players[0].scores[c] = n }    // genau 63
        XCTAssertEqual(s.totals(player: 0).bonus, 35)
        s.players[0].scores[.ones] = 2
        XCTAssertEqual(s.totals(player: 0).bonus, 0)
    }
    func testGleichstandGleicheSummenBleibenErkennbar() throws {
        var s = partie(Rules())
        for c in Category.allCases { s.players[0].scores[c] = 5; s.players[1].scores[c] = 5 }
        XCTAssertEqual(s.totals(player: 0).total, s.totals(player: 1).total)
    }
    func testPartieEndetNachDreizehnRunden() throws {
        var s = partie(Rules()); var n = 0
        var wurf = 0
        while !s.finished, n < 200 {
            try s.apply(.roll(keep: []), roller: { wurf += 1; return wurf % 6 + 1 })
            let frei = s.legalCategories
            try s.apply(.score(frei.first!), roller: { 1 }); n += 1
        }
        XCTAssertTrue(s.finished); XCTAssertEqual(n, 26)                       // 2 Spieler × 13 Felder
        XCTAssertTrue(s.isConsistent)
    }
    func testZustandUeberlebtSpeichern() throws {
        var s = partie(); try wuerfle(&s, [1, 2, 3, 4, 5])
        let t = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(s, t); XCTAssertTrue(t.isConsistent)
    }
}
