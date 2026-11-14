// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import XCTest
import MauMauKern
import SpieleKern
@testable import SpielMauMau

/// KI-6 (Blatt 13): Ablauf der Ansage mit der Simulator-Attrappe, ohne Modell. Nichts wird gesetzt, bevor bestätigt ist.
final class AnsageFeldTests: XCTestCase {
    func testSiebenZiehenUndNeunerDrehtGibtNurDieNeunAlsAenderung() async throws {
        var gesetzt: NRegeln?
        let adapter = MauMauVarianten(regeln: .standard) { gesetzt = $0 }
        let ansage = VariantenAnsage(modell: AnsageAttrappe())
        let v = try await ansage.ansagen("Mau-Mau mit sieben zieht und Neuner dreht, neun dreht", fuer: adapter)
        XCTAssertNil(gesetzt, "vor der Bestätigung wird nichts gesetzt")
        XCTAssertEqual(v.aenderungen.map(\.optionID), ["neun_richtung"])
        XCTAssertEqual(v.schonSo, 1)
        v.uebernehmen(in: adapter)
        XCTAssertEqual(gesetzt?.neunRichtung, true)
    }

    func testUnbekanntesWirdVerworfenUndRestBleibt() async throws {
        let adapter = MauMauVarianten(regeln: .standard) { _ in }
        let v = try await VariantenAnsage(modell: AnsageAttrappe()).ansagen("mit Sieben Karten, das Ass setzt aus und mit Joker", fuer: adapter)
        XCTAssertEqual(Set(v.aenderungen.map(\.optionID)), ["start_karten", "aussetzen"])
        XCTAssertEqual(v.verworfen.map(\.name), ["mit Joker"])
    }

    func testNachDemErstenZugIstNichtsAenderbar() async {
        let adapter = MauMauVarianten(regeln: .standard, aenderbar: { false }) { _ in XCTFail("darf nichts setzen") }
        do { _ = try await VariantenAnsage(modell: AnsageAttrappe()).ansagen("wild", fuer: adapter); XCTFail("erwartet Fehler") }
        catch { XCTAssertEqual(error as? VariantenFehler, .nichtAenderbar) }
    }

    func testVerwerfenSetztNichts() async throws {
        var gesetzt = false
        let adapter = MauMauVarianten(regeln: .standard) { _ in gesetzt = true }
        _ = try await VariantenAnsage(modell: AnsageAttrappe()).ansagen("wild", fuer: adapter)
        XCTAssertFalse(gesetzt)
    }
}
#endif
