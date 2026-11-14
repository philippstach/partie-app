// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MogelnKern

/// Blatt 22 (EB2): richtig und falsch gezweifelt. Nicht syntaxgeprüft.
final class EndeZaehlerTests: XCTestCase {
    private func partie() -> Mogeln {
        Mogeln(haende: [[MoKarte(0, 7), MoKarte(1, 9), MoKarte(2, 10)], [MoKarte(0, 8), MoKarte(1, 8)], [MoKarte(3, 11), MoKarte(2, 12)]], dran: 0, rang: 7)
    }

    /// Spieler 0 legt eine falsche Karte (9 statt 7), Spieler 1 zweifelt: richtig gezweifelt.
    func testRichtigGezweifelt() {
        var m = partie()
        XCTAssertTrue(m.lege([1]))           // 9♠ als „7“
        m.anzweifeln()                        // Spieler 1 zweifelt, es war gelogen
        XCTAssertEqual(m.richtigGezweifelt, [0, 1, 0])
        XCTAssertEqual(m.falschGezweifelt, [0, 0, 0])
    }

    /// Spieler 0 legt eine echte 7, Spieler 1 zweifelt trotzdem: falsch gezweifelt.
    func testFalschGezweifelt() {
        var m = partie()
        XCTAssertTrue(m.lege([0]))           // 7♣ als „7“
        m.anzweifeln()
        XCTAssertEqual(m.falschGezweifelt, [0, 1, 0])
        XCTAssertEqual(m.richtigGezweifelt, [0, 0, 0])
    }

    /// Ein Stand ohne die neuen Schlüssel lädt, die Zähler sind nil und Zweifeln bricht nicht ab.
    func testAlterStandLaedt() throws {
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(partie())) as? [String: Any])
        json.removeValue(forKey: "richtigGezweifelt"); json.removeValue(forKey: "falschGezweifelt")
        var alt = try JSONDecoder().decode(Mogeln.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(alt.richtigGezweifelt); XCTAssertNil(alt.falschGezweifelt)
        XCTAssertTrue(alt.lege([1])); alt.anzweifeln()
        XCTAssertNil(alt.richtigGezweifelt)
    }
}
