// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielYacht

final class ChanceTests: XCTestCase {
    private func state(_ dice: [Int], rollsUsed: Int) -> GameState {
        var s = GameState(playerNames: ["A"])
        s.dice = dice
        s.rollsUsed = rollsUsed
        return s
    }

    func testBereitsErreichtIstSicher() throws {
        let s = state([4, 4, 4, 4, 4], rollsUsed: 2)
        XCTAssertEqual(try XCTUnwrap(HoldAdvisor.chance(s, target: .kniffel)), 1, accuracy: 1e-9)
        XCTAssertEqual(try XCTUnwrap(HoldAdvisor.chance(s, target: .fourOfAKind)), 1, accuracy: 1e-9)
    }

    func testVierGleicheEinWurfNochEinYachtEinSechstel() throws {
        let s = state([3, 3, 3, 3, 5], rollsUsed: 2)
        XCTAssertEqual(try XCTUnwrap(HoldAdvisor.chance(s, target: .kniffel)), 1.0 / 6.0, accuracy: 1e-9)
    }

    func testGrosseStrasseMitViererFolgeUndEinemWurf() throws {
        // 1-2-3-4 liegt, ein Wurf: 5 macht die große Straße (1-5): 1/6; 6 allein reicht nicht, 2-6 braucht die 1 als 6 – nein
        let s = state([1, 2, 3, 4, 6], rollsUsed: 2)
        // Halten 1,2,3,4 und die 5 werfen = 1/6; Halten 2,3,4,6 und die 5 würfeln ergibt 2-6 = ebenfalls 1/6 (nicht mehr)
        let p = try XCTUnwrap(HoldAdvisor.chance(s, target: .largeStraight))
        XCTAssertEqual(p, 1.0 / 6.0, accuracy: 1e-9)
    }

    func testBelegtesFeldUndLetzterWurfLiefernNil() {
        var s = state([1, 1, 1, 1, 2], rollsUsed: 2)
        s.players[0].scores[.kniffel] = 0
        XCTAssertNil(HoldAdvisor.chance(s, target: .kniffel))
        XCTAssertNil(HoldAdvisor.chance(state([1, 1, 1, 1, 2], rollsUsed: 3), target: .fourOfAKind))
    }

    func testZweiWuerfeSindChancenreicherAlsEiner() throws {
        let zwei = try XCTUnwrap(HoldAdvisor.chance(state([2, 2, 5, 5, 6], rollsUsed: 1), target: .fullHouse))
        let eins = try XCTUnwrap(HoldAdvisor.chance(state([2, 2, 5, 5, 6], rollsUsed: 2), target: .fullHouse))
        XCTAssertGreaterThan(zwei, eins)
        XCTAssertEqual(eins, 2.0 / 6.0, accuracy: 1e-9)   // 2 oder 5 muss fallen
    }
}
