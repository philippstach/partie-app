// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// F3: Jeder Start (Neues Spiel, Fortsetzen, Revanche, „Noch einmal“) setzt die Zug-Meldung zurück und beginnt die Live Activity.
@MainActor
final class PartieStartTests: XCTestCase {
    override func tearDown() { LaufendePartie.beenden(); SpielZug.zuruecksetzen("t"); super.tearDown() }

    func testStartSetztZugMeldungZurueck() {
        let w = PartieWache()
        SpielZug.gemacht("t")                                  // Zug aus der vorigen Partie
        PartieStart.ausfuehren(spielID: "t", spielName: "Test", menschen: ["Anna"], wache: w)
        XCTAssertFalse(SpielZug.hatZug("t"), "Revanche: „Beenden“ ohne Zug darf nicht als Niederlage zählen")
    }

    func testStartZaehltPartieHochUndOeffnet() {
        let w = PartieWache()
        let a = PartieStart.ausfuehren(spielID: "t", spielName: "Test", menschen: ["Anna"], wache: w)
        XCTAssertTrue(w.annehmen(partie: a))
        let b = PartieStart.ausfuehren(spielID: "t", spielName: "Test", menschen: ["Anna"], wache: w)   // Revanche
        XCTAssertEqual(b, a + 1); XCTAssertTrue(w.offen)
    }

    func testStartBeginntLiveActivityAbZweiMenschen() {
        var beginne = 0
        let alt = LaufendePartie.beginnHaken
        LaufendePartie.beginnHaken = { _ in beginne += 1 }
        defer { LaufendePartie.beginnHaken = alt }
        PartieStart.ausfuehren(spielID: "t", spielName: "Test", menschen: ["Anna", "Ben"], wache: PartieWache())
        XCTAssertEqual(LaufendePartie.aktuell?.spieler, ["Anna", "Ben"]); XCTAssertEqual(beginne, 1)
        LaufendePartie.beenden()                               // Ende der Partie
        PartieStart.ausfuehren(spielID: "t", spielName: "Test", menschen: ["Anna", "Ben"], wache: PartieWache())   // Revanche
        XCTAssertNotNil(LaufendePartie.aktuell, "auch die Revanche hat wieder eine Live Activity"); XCTAssertEqual(beginne, 2)
        PartieStart.ausfuehren(spielID: "t", spielName: "Test", menschen: ["Anna"], wache: PartieWache())
        XCTAssertNil(LaufendePartie.aktuell, "allein: keine Live Activity")
    }
}
