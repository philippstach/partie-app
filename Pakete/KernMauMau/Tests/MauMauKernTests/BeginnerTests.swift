// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MauMauKern

/// T-097: Wer beginnt. Nicht syntaxgeprüft.
final class BeginnerTests: XCTestCase {
    func testBeginnerWirdUebernommenUndBegrenzt() {
        var g = SystemRandomNumberGenerator()
        XCTAssertEqual(NMauMau(spieler: 4, mit: &g).dran, 0)
        XCTAssertEqual(NMauMau(spieler: 4, beginner: 2, mit: &g).dran, 2)
        XCTAssertEqual(NMauMau(spieler: 3, beginner: 9, mit: &g).dran, 2)
        XCTAssertEqual(NMauMau(spieler: 3, beginner: -1, mit: &g).dran, 0)
    }
}
