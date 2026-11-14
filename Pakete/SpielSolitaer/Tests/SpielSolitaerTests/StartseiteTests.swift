// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SwiftUI
@testable import SpielSolitaer

/// Startseite (Doku/SPEZIFIKATION-START.md): wann sie kommt, 
final class StartseiteTests: XCTestCase {
    private let jetzt = Date(timeIntervalSince1970: 1_800_000_000)

    func testKaltstartZeigtImmerDieStartseite() {
        XCTAssertTrue(zeigeStartseite(kaltstart: true, letzteAktivitaet: jetzt, jetzt: jetzt))
        XCTAssertTrue(zeigeStartseite(kaltstart: true, letzteAktivitaet: nil, jetzt: jetzt))
    }

    func testRueckkehrNachWenigerAls30MinutenBleibtImSpiel() {
        XCTAssertFalse(zeigeStartseite(kaltstart: false, letzteAktivitaet: jetzt, jetzt: jetzt))
        XCTAssertFalse(zeigeStartseite(kaltstart: false, letzteAktivitaet: jetzt.addingTimeInterval(-(29 * 60 + 59)), jetzt: jetzt), "29:59 nein")
    }

    func testAb30MinutenKommtDieStartseite() {
        XCTAssertTrue(zeigeStartseite(kaltstart: false, letzteAktivitaet: jetzt.addingTimeInterval(-30 * 60), jetzt: jetzt), "30:00 ja")
        XCTAssertTrue(zeigeStartseite(kaltstart: false, letzteAktivitaet: jetzt.addingTimeInterval(-5 * 3600), jetzt: jetzt))
        XCTAssertTrue(zeigeStartseite(kaltstart: false, letzteAktivitaet: nil, jetzt: jetzt), "unbekannt: Startseite")
    }

    func testModusText() {
        XCTAssertEqual(StartText.modus(.klondike(1), difficulty: nil, solvable: true), "Klondike · 1 Karte")
        XCTAssertEqual(StartText.modus(.klondike(3), difficulty: nil, solvable: true), "Klondike · 3 Karten")
        XCTAssertEqual(StartText.modus(.spider(2), difficulty: nil, solvable: true), "Spider · 2 Farben")
        XCTAssertEqual(StartText.modus(.pyramid, difficulty: nil, solvable: true), "Pyramid")
    }
}
