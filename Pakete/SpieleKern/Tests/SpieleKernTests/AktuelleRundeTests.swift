// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// Designwechsel C.1: die Runde vom Salon-Start („Wer ist dabei?“) und ihre Wirkung auf das Blatt „Neues Spiel“.
final class AktuelleRundeTests: XCTestCase {
    private func frischeDefaults() -> UserDefaults {
        let name = "AktuelleRundeTests-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    func testLeerOhneAuswahl() {
        XCTAssertEqual(AktuelleRunde.laden(defaults: frischeDefaults()), [])
    }

    func testSpeichernUndLadenBehaeltDieReihenfolge() {
        let d = frischeDefaults()
        let ids = [UUID(), UUID(), UUID()]
        AktuelleRunde.speichern(ids, defaults: d)
        XCTAssertEqual(AktuelleRunde.laden(defaults: d), ids)
        AktuelleRunde.speichern([ids[2], ids[0]], defaults: d)
        XCTAssertEqual(AktuelleRunde.laden(defaults: d), [ids[2], ids[0]])
        AktuelleRunde.speichern([], defaults: d)
        XCTAssertNil(d.object(forKey: AktuelleRunde.schluessel))
    }

    func testUnlesbareEintraegeWerdenUebergangen() {
        let d = frischeDefaults()
        let id = UUID()
        d.set(["quatsch", id.uuidString, ""], forKey: AktuelleRunde.schluessel)
        XCTAssertEqual(AktuelleRunde.laden(defaults: d), [id])
    }

    func testBereinigtEntferntGeloeschteUndDoppelte() {
        let a = UUID(), b = UUID(), c = UUID()
        XCTAssertEqual(AktuelleRunde.bereinigt([c, a, c, b], vorhanden: [a, c]), [c, a])
        XCTAssertEqual(AktuelleRunde.bereinigt([a], vorhanden: []), [])
    }

    func testOhneRundeBleibtDieBisherigeVorgabe() {
        // bisher: „Ich“, dann zuletzt Gespielte; zwei Plätze, innerhalb der Spielerzahl
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: [], bisher: ["Anna", "Ben", "Clara"], spieler: 2...4), ["Anna", "Ben"])
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: [], bisher: ["Anna"], spieler: 2...4), ["Anna", ""])
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: [], bisher: [], spieler: 3...6), ["", "", ""])
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: [], bisher: ["Anna", "Ben"], spieler: 1...1), ["Anna"])
    }

    func testRundeStehtVornInAuswahlreihenfolge() {
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: ["Clara", "Ben"], bisher: ["Anna", "Ben", "Clara"], spieler: 2...4), ["Clara", "Ben"])
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: ["Clara", "Anna", "Ben"], bisher: ["Anna", "Ben"], spieler: 2...6), ["Clara", "Anna", "Ben"])
    }

    func testRundeWirdAufDieSpielerzahlBegrenztUndAufgefuellt() {
        // Vier gewählt, das Spiel erlaubt höchstens drei
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: ["A", "B", "C", "D"], bisher: [], spieler: 2...3), ["A", "B", "C"])
        // Eine Person gewählt: zwei Plätze, der zweite kommt aus der bisherigen Vorgabe
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: ["Clara"], bisher: ["Anna", "Clara"], spieler: 2...4), ["Clara", "Anna"])
        // Namen gelten ohne Groß- und Kleinschreibung nur einmal
        XCTAssertEqual(AktuelleRunde.aufstellung(runde: ["anna"], bisher: ["Anna", "Ben"], spieler: 2...2), ["anna", "Ben"])
    }

    @MainActor func testNamenAusDemVerzeichnis() {
        let d = frischeDefaults()
        let verzeichnis = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = verzeichnis.anlegen(name: "Anna"), ben = verzeichnis.anlegen(name: "Ben")
        AktuelleRunde.speichern([ben.id, UUID(), anna.id], defaults: d)
        XCTAssertEqual(AktuelleRunde.namen(verzeichnis, defaults: d), ["Ben", "Anna"])   // unbekannte ID fällt weg
    }
}
