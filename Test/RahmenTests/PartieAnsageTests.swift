// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SpieleKern
@testable import Partie

/// KI-N (Blatt 18 „Neue Partie sagen“): Spielerzahl aus dem Satz und Vormerkung für die Spielseite, ohne Modell.
@MainActor
final class PartieAnsageTests: XCTestCase {
    func testSpielerzahlAusDemSatz() {
        XCTAssertEqual(PartieAnsage.spielerzahl(in: "Mau-Mau zu dritt mit sieben Karten")?.zahl, 3)
        XCTAssertEqual(PartieAnsage.spielerzahl(in: "Rommé zu viert")?.zahl, 4)
        XCTAssertEqual(PartieAnsage.spielerzahl(in: "Schwimmen mit 5 Spielern")?.zahl, 5)
        XCTAssertEqual(PartieAnsage.spielerzahl(in: "Mau-Mau für drei Personen")?.zahl, 3)
        XCTAssertEqual(PartieAnsage.spielerzahl(in: "Mau-Mau zu zehnt")?.zahl, 10)
    }

    func testKeineSpielerzahlBeiKartenOderNurSpiel() {
        XCTAssertNil(PartieAnsage.spielerzahl(in: "Mau-Mau mit sieben Karten"))
        XCTAssertNil(PartieAnsage.spielerzahl(in: "Mau-Mau"))
        XCTAssertNil(PartieAnsage.spielerzahl(in: "Ass setzt aus, Bube nicht zuletzt"))
    }

    func testVormerkungGiltZehnMinutenUndEndetMitLoeschen() {
        let d = UserDefaults(suiteName: "partie.test.vormerkung")!
        d.removePersistentDomain(forName: "partie.test.vormerkung")
        let jetzt = Date()
        SpielerVormerkung.merken(3, fuer: "maumau-neu", jetzt: jetzt, defaults: d)
        XCTAssertEqual(SpielerVormerkung.lesen(fuer: "maumau-neu", jetzt: jetzt.addingTimeInterval(599), defaults: d), 3)
        XCTAssertNil(SpielerVormerkung.lesen(fuer: "maumau-neu", jetzt: jetzt.addingTimeInterval(601), defaults: d))
        XCTAssertNil(SpielerVormerkung.lesen(fuer: "schwimmen", jetzt: jetzt, defaults: d))
        SpielerVormerkung.loeschen(fuer: "maumau-neu", defaults: d)
        XCTAssertNil(SpielerVormerkung.lesen(fuer: "maumau-neu", jetzt: jetzt, defaults: d))
    }
}
