// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// F21-005: „Abwechselnd“ muss über viele Revanchen hinweg wechseln. Nachgebaut wird der Ablauf der Viererreihe:
/// neue Partie (init: `naechster`), Erscheinen (`merke` des Beginners), Partie-Ende (`merke` des Beginners), Revanche (neue Ansicht).
final class StartSpielerRevancheTests: XCTestCase {
    private let spiel = "test-revanche-\(UUID().uuidString)"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: StartSpieler.wahlSchluessel(spiel))
        UserDefaults.standard.removeObject(forKey: StartSpieler.letzterSchluessel(spiel))
        super.tearDown()
    }

    private func partie() -> Int {
        let beginner = StartSpieler.naechster(spiel)   // init der Spielansicht
        StartSpieler.merke(beginner, spiel: spiel)       // Erscheinen (standGeladen ohne Stand)
        StartSpieler.merke(beginner, spiel: spiel)       // Partie-Ende (melden)
        return beginner
    }

    func testAbwechselndWechseltUeberFuenfRevanchen() {
        UserDefaults.standard.set(StartSpieler.abwechselnd.rawValue, forKey: StartSpieler.wahlSchluessel(spiel))
        XCTAssertEqual((0..<6).map { _ in partie() }, [1, 2, 1, 2, 1, 2])
    }

    func testNaechsterHatKeineNebenwirkung() {
        UserDefaults.standard.set(StartSpieler.abwechselnd.rawValue, forKey: StartSpieler.wahlSchluessel(spiel))
        StartSpieler.merke(2, spiel: spiel)
        // Mehrfaches Auswerten der Ansicht (SwiftUI ruft init öfter auf) darf das Ergebnis nicht verschieben.
        XCTAssertEqual(StartSpieler.naechster(spiel), 1)
        XCTAssertEqual(StartSpieler.naechster(spiel), 1)
    }

    func testFesteWahlBleibtGleich() {
        UserDefaults.standard.set(StartSpieler.zweiter.rawValue, forKey: StartSpieler.wahlSchluessel(spiel))
        XCTAssertEqual((0..<4).map { _ in partie() }, [2, 2, 2, 2])
        UserDefaults.standard.removeObject(forKey: StartSpieler.wahlSchluessel(spiel))
        XCTAssertEqual(partie(), 1, "ohne Wahl gilt „erster“")
    }
}

#if canImport(UIKit)
/// F21-013: Steht der Computer in der Spielerliste oben, geht er trotzdem als Spieler 2 ins Zwei-Spieler-Spiel.
final class MenschZuerstTests: XCTestCase {
    func testComputerObenWirdGetauscht() {
        let c = SpielTeilnehmer(name: "Computer", computer: true), m = SpielTeilnehmer(name: "Anna")
        XCTAssertEqual(SpielTeilnehmer.menschZuerst([c, m]).map(\.name), ["Anna", "Computer"])
    }
    func testAndereReihenfolgenBleiben() {
        let c = SpielTeilnehmer(name: "Computer", computer: true), m = SpielTeilnehmer(name: "Anna"), b = SpielTeilnehmer(name: "Ben")
        XCTAssertEqual(SpielTeilnehmer.menschZuerst([m, c]).map(\.name), ["Anna", "Computer"])
        XCTAssertEqual(SpielTeilnehmer.menschZuerst([b, m]).map(\.name), ["Ben", "Anna"])
        XCTAssertEqual(SpielTeilnehmer.menschZuerst([c, m, b]).map(\.name), ["Computer", "Anna", "Ben"], "nur Zweier-Runden")
    }
}
#endif
