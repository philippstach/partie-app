// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import RommeKern

/// Blatt 22 (EB2): Wer hat welche Auslage gelegt. Nicht syntaxgeprüft.
final class EndeZaehlerTests: XCTestCase {
    private func stellung() -> Romme {
        Romme(haende: [[RKarte(0, 7), RKarte(1, 7), RKarte(2, 7), RKarte(0, 12)], [RKarte(0, 3), RKarte(1, 9)]], hatAusgelegt: [true, true], dran: 0, gezogen: true)
    }

    func testAuslageMerktBesitzer() {
        var r = stellung()
        XCTAssertTrue(r.auslegen([0, 1, 2]))
        XCTAssertEqual(r.tisch.count, 1)
        XCTAssertEqual(r.tischVon, [0])
    }

    func testNeuePartieStartetMitLeerem() {
        var g = FesterZufall(seed: 3)
        let r = Romme(spieler: 2, runden: 3, mit: &g)
        XCTAssertEqual(r.tischVon, [])
    }

    /// Ein Stand ohne den neuen Schlüssel lädt, tischVon ist nil.
    func testAlterStandLaedt() throws {
        var r = stellung()
        XCTAssertTrue(r.auslegen([0, 1, 2]))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(r)) as? [String: Any])
        json.removeValue(forKey: "tischVon")
        let geladen = try JSONDecoder().decode(Romme.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(geladen.tischVon)
        XCTAssertEqual(geladen.tisch, r.tisch)
    }

    /// Unstimmige Länge wird verworfen statt verwendet.
    func testUnstimmigeLaengeWirdNil() throws {
        var r = stellung()
        XCTAssertTrue(r.auslegen([0, 1, 2]))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(r)) as? [String: Any])
        json["tischVon"] = [0, 1, 1]
        let geladen = try JSONDecoder().decode(Romme.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(geladen.tischVon)
    }
}
