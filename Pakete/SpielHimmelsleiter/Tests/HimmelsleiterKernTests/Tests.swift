// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HimmelsleiterKern
final class HimmelsleiterTests: XCTestCase {
    func testLeiterUndRutschenSindGueltig() {
        for (a, b) in Himmelsleiter.leitern { XCTAssertTrue(b > a && b < 100) }
        for (a, b) in Himmelsleiter.rutschen { XCTAssertTrue(b < a && b > 0) }
        XCTAssertTrue(Set(Himmelsleiter.leitern.keys).isDisjoint(with: Himmelsleiter.rutschen.keys))
        XCTAssertTrue(Set(Himmelsleiter.leitern.values).isDisjoint(with: Himmelsleiter.rutschen.keys))
        XCTAssertTrue(Set(Himmelsleiter.rutschen.values).isDisjoint(with: Himmelsleiter.leitern.keys))
    }
    func testKoordinaten() {
        XCTAssertTrue(Himmelsleiter.koordinate(1) == (0, 9)); XCTAssertTrue(Himmelsleiter.koordinate(10) == (9, 9))
        XCTAssertTrue(Himmelsleiter.koordinate(11) == (9, 8)); XCTAssertTrue(Himmelsleiter.koordinate(100) == (0, 0))
        XCTAssertEqual(Set((1...100).map { "\(Himmelsleiter.koordinate($0).spalte),\(Himmelsleiter.koordinate($0).zeile)" }).count, 100)
    }
    func testPartienEnden() {
        for n in 2...4 {
            for _ in 0..<50 {
                var s = Himmelsleiter(spieler: n); var z = 0
                while s.sieger == nil && z < 5000 { s.zug(wurf: Int.random(in: 1...6)); z += 1 }
                XCTAssertNotNil(s.sieger)
            }
        }
    }
}
