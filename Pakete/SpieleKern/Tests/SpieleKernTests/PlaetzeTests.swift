// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// F4: Weniger gemeldete Plätze als Namen dürfen nicht abstürzen; fehlende Plätze sind i + 1.
final class PlaetzeTests: XCTestCase {
    func testPlatzMitUndOhneAngabe() {
        XCTAssertEqual(EndeBuchung.platz(nil, 2), 3)
        XCTAssertEqual(EndeBuchung.platz([1, 1, 3], 1), 1)
        XCTAssertEqual(EndeBuchung.platz([1, 1], 2), 3, "zu kurze Liste: Platz i + 1")
        XCTAssertEqual(EndeBuchung.platz([], 0), 1)
        XCTAssertEqual(EndeBuchung.plaetze([1, 1], anzahl: 4), [1, 1, 3, 4])
    }

    func testBuchungMitWenigerPlaetzenAlsNamen() {
        let t = EndeBuchung.teilnehmer(reihenfolge: ["Anna", "Ben", "Cem"], punkte: [10, 10], plaetze: [1, 1])
        XCTAssertEqual(t.map(\.platz), [1, 1, 3]); XCTAssertEqual(t.map(\.punkte), [10, 10, nil])
        XCTAssertEqual(EndeBuchung.teilnehmer(reihenfolge: ["Anna", "Ben"], plaetze: []).map(\.platz), [1, 2])
    }

    @MainActor func testMeldenMitWenigerPlaetzenStuerztNichtAb() async {
        let alt = PartieMeldung.senke
        defer { PartieMeldung.senke = alt }
        var gebucht: PartieErgebnis?
        PartieMeldung.senke = { gebucht = $0 }
        PartieMeldung.melden(spiel: "t", reihenfolge: ["Anna", "Ben", "Cem"], plaetze: [1])
        for _ in 0..<20 where gebucht == nil { await Task.yield() }
        XCTAssertEqual(gebucht?.teilnehmer.map(\.platz), [1, 2, 3])
    }

    func testRemisNurWennAlleNamenAufPlatzEins() {
        XCTAssertFalse(Remis.gilt(plaetze: EndeBuchung.plaetze([1, 1], anzahl: 3)), "zwei vorn, einer dahinter: kein Remis")
        XCTAssertTrue(Remis.gilt(plaetze: EndeBuchung.plaetze([1, 1], anzahl: 2)))
        let text = ErgebnisText.text(spiel: "X", reihenfolge: ["Anna", "Ben", "Cem"], plaetze: [1, 1])
        XCTAssertTrue(text.contains("3. Cem")); XCTAssertFalse(text.hasPrefix(String(localized: "\("X"): Remis")))
    }
}
