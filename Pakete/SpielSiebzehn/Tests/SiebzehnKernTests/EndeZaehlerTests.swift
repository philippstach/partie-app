// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SiebzehnKern

/// Blatt 22 (EB2): Hände und größter Gewinn. Nicht syntaxgeprüft.
final class EndeZaehlerTests: XCTestCase {
    func testHaendeUndGroessterGewinnWerdenGezaehlt() {
        var g = SystemRandomNumberGenerator()
        var s = Siebzehn(spieler: 2)
        XCTAssertEqual(s.haendeGespielt, 0); XCTAssertEqual(s.groessterGewinn, 0)
        var abgerechnet = 0, vorher = s.chips
        var groesster = 0
        for _ in 0..<30 {
            s.austeilen(mit: &g)
            var n = 0
            while !s.vorbei && n < 100 {
                if Siebzehn.computerNimmtKarte(hand: s.spieler[s.dran], bankOffen: s.bank.first?.augen ?? 10) { s.karte() } else { s.halten() }
                n += 1
            }
            XCTAssertTrue(s.vorbei)
            abgerechnet += 1
            for i in s.chips.indices { groesster = max(groesster, s.chips[i] - vorher[i]) }
            vorher = s.chips
            if s.aktive.count < 2 { break }
        }
        XCTAssertEqual(s.haendeGespielt, abgerechnet)
        XCTAssertGreaterThanOrEqual(s.groessterGewinn ?? -1, groesster, "der größte Gewinn ist mindestens der größte Chip-Zuwachs einer Hand")
    }

    /// Ein Stand ohne die neuen Schlüssel lädt, beide Zähler sind nil und bleiben es.
    func testAlterStandLaedt() throws {
        var g = SystemRandomNumberGenerator()
        let s = Siebzehn(spieler: 2, mit: &g)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as? [String: Any])
        json.removeValue(forKey: "haendeGespielt"); json.removeValue(forKey: "groessterGewinn")
        var alt = try JSONDecoder().decode(Siebzehn.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(alt.haendeGespielt); XCTAssertNil(alt.groessterGewinn)
        var n = 0
        while !alt.vorbei && n < 100 { alt.halten(); n += 1 }
        XCTAssertNil(alt.haendeGespielt)
    }
}
