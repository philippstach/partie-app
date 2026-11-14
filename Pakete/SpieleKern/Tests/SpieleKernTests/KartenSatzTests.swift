// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SwiftUI
import KlarGlas
@testable import SpieleKern

/// KS Schritt 2: Kartensatz und Würfelsatz. Ohne Wahl gilt das Design; eine Wahl bestimmt den ganzen Stil.
final class KartenSatzTests: XCTestCase {
    func testWieDesignFolgtDemDesign() {
        for art in [DesignArt.klar, .tinte, .salon] {
            XCTAssertEqual(KartenSatz.wieDesign.bild(design: art), art)
            XCTAssertEqual(WuerfelSatz.wieDesign.bild(design: art), art)
        }
    }

    func testGewaehlterSatzGiltInJedemDesign() {
        for art in [DesignArt.klar, .tinte, .salon] {
            XCTAssertEqual(KartenSatz.salon.bild(design: art), .salon)
            XCTAssertEqual(WuerfelSatz.tinte.bild(design: art), .tinte)
        }
    }

    func testStilEinesSatzesHatSeineArt() {
        XCTAssertEqual(KartenStil.fuer(.klar).art, .klar)
        XCTAssertEqual(KartenStil.fuer(.tinte).art, .tinte)
        XCTAssertEqual(KartenStil.fuer(.salon).art, .salon)
        XCTAssertEqual(KartenStil.fuer(.salon).bild, .salon)
    }

    func testWahlListenOhneWieDesign() {
        XCTAssertEqual(KartenSatz.wahl, [.klar, .tinte, .salon, .figuren])
        XCTAssertEqual(WuerfelSatz.wahl, [.tinte, .salon])
        XCTAssertNil(KartenSatz.wieDesign.name)
    }

    func testUnbekannterWertFaelltAufDesignZurueck() {
        XCTAssertNil(KartenSatz(rawValue: "quatsch"))
        XCTAssertEqual(KartenSatz(rawValue: "salon"), .salon)
    }
}

/// Satz „Figuren“ (Blatt 19): Aufbau und Pfadleser.
final class KartenFigurTests: XCTestCase {
    func testFigurenBautAufTinteAuf() {
        XCTAssertEqual(KartenSatz.figuren.bild(design: .klar), .tinte)
        XCTAssertTrue(KartenSatz.wahl.contains(.figuren))
        XCTAssertTrue(KartenStil.fuer(satz: .figuren).figuren)
        XCTAssertFalse(KartenStil.fuer(satz: .tinte).figuren)
        XCTAssertEqual(KartenStil.fuer(satz: .figuren).art, .tinte)
    }

    func testNurBildkartenHabenFiguren() {
        for r in ["B", "D", "K"] { XCTAssertTrue(KartenFigur.hat(r)); XCTAssertFalse(KartenFigur.teile(r).isEmpty) }
        for r in ["A", "10", "7", "9"] { XCTAssertFalse(KartenFigur.hat(r)) }
    }

    func testPfadleser() {
        let box = SVGPfad.pfad("M0 0 L10 0 V10 H0 Z").boundingRect
        XCTAssertEqual(box.width, 10, accuracy: 0.001)
        XCTAssertEqual(box.height, 10, accuracy: 0.001)
        let kurve = SVGPfad.pfad("M10 10 C20 0 30 0 40 10 Q50 20 60 10").boundingRect
        XCTAssertGreaterThan(kurve.maxX, 59.9)
    }

    func testAllePfadeInDerHaelfte() {
        // Alle Figuren liegen im Feld 100 × 71 (obere Hälfte), Pfade dürfen den Rand nicht überschreiten
        for r in ["B", "D", "K"] {
            for t in KartenFigur.teile(r) {
                if case .pfad(let d) = t.form {
                    let b = SVGPfad.pfad(d).boundingRect
                    XCTAssertGreaterThanOrEqual(b.minX, 0); XCTAssertLessThanOrEqual(b.maxX, 100)
                    XCTAssertGreaterThanOrEqual(b.minY, 0); XCTAssertLessThanOrEqual(b.maxY, 72.1)
                }
            }
        }
    }
}
