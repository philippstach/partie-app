// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WuerfelScan

final class AnsageTests: XCTestCase {
    private func a(_ s: String) -> [Int] { WuerfelAnsage.augen(aus: s) }

    func testEinzelneZahlwoerter() {
        XCTAssertEqual(a("drei, fünf, fünf, eins, sechs"), [3, 5, 5, 1, 6])
        XCTAssertEqual(a("Drei fünf fünf eins und sechs"), [3, 5, 5, 1, 6])
        XCTAssertEqual(a("zwo vier eine"), [2, 4, 1])
    }

    func testZiffernWieDieSpracherkennungSieSchreibt() {
        XCTAssertEqual(a("3 5 5 1 6"), [3, 5, 5, 1, 6])
        XCTAssertEqual(a("35516"), [3, 5, 5, 1, 6])
        XCTAssertEqual(a("35.516"), [3, 5, 5, 1, 6])
        XCTAssertEqual(a("3, 5, 5, 1 und 6"), [3, 5, 5, 1, 6])
    }

    func testKeineAugenzahlenWerdenUebergangen() {
        XCTAssertEqual(a("sieben acht neun null 7 8 9 0"), [])
        XCTAssertEqual(a("ähm also drei 9 vier"), [3, 4])
        XCTAssertEqual(a(""), [])
    }

    func testMehrzahlUndMal() {
        XCTAssertEqual(a("zwei Sechsen und eine Vier"), [6, 6, 4])
        XCTAssertEqual(a("dreimal die Fünf, eine Zwei, eine Eins"), [5, 5, 5, 2, 1])
        XCTAssertEqual(a("drei mal fünf"), [5, 5, 5])
        XCTAssertEqual(a("2 Sechsen 3 Einsen"), [6, 6, 1, 1, 1])
        XCTAssertEqual(a("Sechsen"), [6, 6])
    }

    func testVerhoererUndUmlaute() {
        XCTAssertEqual(a("sex funf"), [6, 5])
        XCTAssertEqual(a("FÜNF Sechs"), [5, 6])
    }

    func testEnglischSpanischFranzoesisch() {
        XCTAssertEqual(a("one two three four five six"), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(a("two sixes and a four"), [6, 6, 4])
        XCTAssertEqual(a("three times five"), [5, 5, 5])
        XCTAssertEqual(a("uno dos tres cuatro cinco seis"), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(a("dos seises"), [6, 6])
        XCTAssertEqual(a("un deux trois quatre cinq six"), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(a("trois fois cinq"), [5, 5, 5])
    }

    func testNieMehrAlsSechsGleicheAusEinerAnsage() {
        XCTAssertEqual(a("6 mal 6").count, 6)
    }
}
