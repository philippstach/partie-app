// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSchwimmen

/// Blatt 22 (EB2): „Bestes Blatt“ der Partie. Nicht syntaxgeprüft.
final class EndeZaehlerTests: XCTestCase {
    typealias K = SwKarte
    let std = SchwimmenRegeln.standard

    /// Feuer in der ersten Runde: das Blatt des Spielers mit 31 ist das beste der Partie.
    func testBestesBlattWirdGemerkt() {
        var s = SchwimmenNeu(regeln: std, leben: [3, 3, 3], hand: [[K(2, 14), K(2, 13), K(0, 7)], [K(0, 8), K(1, 9), K(2, 10)], [K(0, 9), K(1, 10), K(2, 8)]],
                             tisch: [K(2, 10), K(1, 7), K(3, 8)], dran: 0)
        XCTAssertNil(s.bestesBlatt)
        s.tauscheEine(hand: 2, tisch: 0)   // Spieler 0 hat jetzt 31 (Feuer)
        XCTAssertEqual(s.bestesBlatt, 31)
        XCTAssertEqual(s.bestesBlattVon, 0)
    }

    /// Ein Stand von vor dem Update (ohne die neuen Schlüssel) lädt, die Felder sind nil.
    func testAlterStandLaedt() throws {
        let s = SchwimmenNeu(regeln: std, leben: [3, 3], hand: [[K(2, 14), K(2, 13), K(0, 7)], [K(0, 8), K(1, 9), K(2, 10)]], tisch: [K(2, 10), K(1, 7), K(3, 8)], dran: 0)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as? [String: Any])
        json.removeValue(forKey: "bestesBlatt"); json.removeValue(forKey: "bestesBlattVon")
        let alt = try JSONSerialization.data(withJSONObject: json)
        let geladen = try JSONDecoder().decode(SchwimmenNeu.self, from: alt)
        XCTAssertNil(geladen.bestesBlatt); XCTAssertNil(geladen.bestesBlattVon)
        XCTAssertEqual(geladen.hand, s.hand)
    }
}
