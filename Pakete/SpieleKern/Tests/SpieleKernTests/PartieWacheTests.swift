// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// F2: Verzögerte oder doppelte Ende-Meldungen dürfen keine zweite Partie verbuchen.
final class PartieWacheTests: XCTestCase {
    func testEntscheidung() {
        XCTAssertTrue(PartieWache.nimmtAn(laeuft: true, offen: true, aktuelle: 3, gemeldete: 3))
        XCTAssertFalse(PartieWache.nimmtAn(laeuft: false, offen: true, aktuelle: 3, gemeldete: 3), "Phase ist nicht „läuft“")
        XCTAssertFalse(PartieWache.nimmtAn(laeuft: true, offen: false, aktuelle: 3, gemeldete: 3), "schon gemeldet oder beendet")
        XCTAssertFalse(PartieWache.nimmtAn(laeuft: true, offen: true, aktuelle: 3, gemeldete: 2), "Meldung einer früheren Partie")
    }

    func testOhneStartWirdNichtsAngenommen() {
        XCTAssertFalse(PartieWache().annehmen(partie: 0))
    }

    func testEineMeldungJePartie() {
        let w = PartieWache()
        let p = w.starten()
        XCTAssertTrue(w.annehmen(partie: p))
        XCTAssertFalse(w.annehmen(partie: p), "doppelte Meldung derselben Partie")
    }

    func testVerzoegerteMeldungNachBeendenOderPausieren() {
        let w = PartieWache()
        let p = w.starten()
        w.schliessen()                                   // „Beenden“ oder „Pausieren“
        XCTAssertFalse(w.annehmen(partie: p))
    }

    func testAlteMeldungTrifftNeuePartieNicht() {
        let w = PartieWache()
        let alt = w.starten()
        w.schliessen()                                   // Beenden …
        let neu = w.starten()                            // … und sofort neues Spiel, Fortsetzen oder Revanche
        XCTAssertNotEqual(alt, neu)
        XCTAssertFalse(w.annehmen(partie: alt), "das verzögerte Ende der alten Partie darf die neue nicht beenden")
        XCTAssertTrue(w.offen)
        XCTAssertTrue(w.annehmen(partie: neu))
    }

    func testRevancheNachEndeZaehltWeiter() {
        let w = PartieWache()
        let a = w.starten(); XCTAssertTrue(w.annehmen(partie: a))
        let b = w.starten()
        XCTAssertFalse(w.annehmen(partie: a)); XCTAssertTrue(w.annehmen(partie: b))
    }

    func testPhaseNichtLaeuftWeistAb() {
        let w = PartieWache()
        let p = w.starten()
        XCTAssertFalse(w.annehmen(partie: p, laeuft: false))
        XCTAssertTrue(w.offen, "eine abgewiesene Meldung schließt die Partie nicht")
    }
}
