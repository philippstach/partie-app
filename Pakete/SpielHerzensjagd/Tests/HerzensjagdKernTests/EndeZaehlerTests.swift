// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HerzensjagdKern

/// Blatt 22 (EB2): Rundenverlauf und Durchmärsche. Nicht syntaxgeprüft.
final class EndeZaehlerTests: XCTestCase {
    private func spieleZuEnde(_ s: inout Herzensjagd, _ g: inout SystemRandomNumberGenerator) {
        var n = 0
        while !s.vorbei && n < 10000 {
            s.spiele(s.computerWahl(s.amZug))
            if s.stichVoll { s.stichAbschliessen(mit: &g) }
            if s.rundeFertig && !s.vorbei { s.naechsteRunde(mit: &g) }
            n += 1
        }
    }

    /// Je beendeter Runde ein Eintrag mit vier Werten; die Summe der Einträge ist der Gesamtstand.
    func testRundenVerlaufStimmtMitGesamt() {
        var g = SystemRandomNumberGenerator()
        var s = Herzensjagd(ziel: 50, mit: &g)
        spieleZuEnde(&s, &g)
        XCTAssertTrue(s.vorbei)
        let v = s.rundenVerlauf ?? []
        XCTAssertEqual(v.count, s.runde)
        XCTAssertTrue(v.allSatisfy { $0.count == 4 })
        XCTAssertEqual((0..<4).map { i in v.reduce(0) { $0 + $1[i] } }, s.gesamt)
        XCTAssertGreaterThanOrEqual(s.durchmaersche ?? -1, 0)
    }

    /// Ein Stand ohne die neuen Schlüssel lädt, beide Felder sind nil und bleiben es beim Weiterspielen.
    func testAlterStandLaedt() throws {
        var g = SystemRandomNumberGenerator()
        let s = Herzensjagd(mit: &g)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as? [String: Any])
        json.removeValue(forKey: "durchmaersche"); json.removeValue(forKey: "rundenVerlauf")
        var alt = try JSONDecoder().decode(Herzensjagd.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(alt.durchmaersche); XCTAssertNil(alt.rundenVerlauf)
        spieleZuEnde(&alt, &g)
        XCTAssertTrue(alt.vorbei)
        XCTAssertNil(alt.rundenVerlauf)
    }
}
