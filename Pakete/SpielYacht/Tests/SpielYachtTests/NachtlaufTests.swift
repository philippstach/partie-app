// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielYacht
import KlarGlas

final class NachtlaufTests: XCTestCase {
    func testNegativerFarbindexWirdBeimLadenAufNullGesetzt() throws {
        let json = Data(#"{"id":"11111111-1111-1111-1111-111111111111","name":"A","avatar":"😎","colorIndex":-3}"#.utf8)
        let p = try JSONDecoder().decode(Player.self, from: json)
        XCTAssertEqual(p.colorIndex, 0)
    }

    func testBeendetOhneAlleFelderIstUnstimmig() {
        var s = GameState(playerNames: ["A"])
        XCTAssertTrue(s.isConsistent)
        s.finished = true                      // beendet, aber kein Feld belegt
        XCTAssertFalse(s.isConsistent)
    }

    func testAchtSpielerSindStimmigNeunNicht() {
        XCTAssertTrue(GameState(playerNames: (1...8).map { "S\($0)" }).isConsistent)
        XCTAssertFalse(GameState(playerNames: (1...9).map { "S\($0)" }).isConsistent)
    }

    func testHoechstzahlSpielerJeNachGeraet() {
        XCTAssertEqual(Theme.maxPlayers(regular: false), 6)
        XCTAssertEqual(Theme.maxPlayers(regular: true), 8)
    }
}
