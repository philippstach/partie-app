// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import MauMauKern
import SpieleKern
@testable import SpielMauMau

/// KI-6 (Vorbereitung): Adapter Mau-Mau, ohne Modell. Die Attrappe liefert „Mau-Mau mit 7 ziehen und Neuner dreht“.
final class MauMauVariantenTests: XCTestCase {
    func testSchemaIstStimmigUndNenntDieSechsVorlagen() {
        XCTAssertEqual(MauMauVarianten.schema.fehler(), [])
        XCTAssertEqual(MauMauVarianten.schema.vorlagen.map(\.id), ["standard", "ass", "sieben", "schlicht", "streng", "wild"])
        XCTAssertEqual(MauMauVarianten.schema.optionen.count, 10)
    }

    func testLesenUndEinsetzenSindUmkehrbar() {
        for r in [NRegeln.standard, .ass, .sieben, .schlicht, .streng, .wild] {
            XCTAssertEqual(MauMauVarianten.einsetzen(MauMauVarianten.lesen(r), in: NRegeln.standard), r)
        }
    }

    func testVorlageWildGleichtSchnellwahlImRegelblatt() {
        // Das Regelblatt übernimmt Runden und Zielsumme der aktuellen Regeln, der Rest kommt aus der Vorlage.
        var start = NRegeln.standard; start.mehrrunden = true; start.zielPunkte = 150
        let a = MauMauVarianten(regeln: start) { _ in }
        let roh = VariantenRohAntwort(vorlage: "wild")
        let v = VariantenPruefer.pruefen(roh, schema: a.schema, aktuell: a.lesen())
        v.uebernehmen(in: a)
        var erwartet = NRegeln.wild; erwartet.mehrrunden = true; erwartet.zielPunkte = 150
        XCTAssertEqual(a.regeln, erwartet)
    }

    func testAttrappeSiebenZiehenUndNeunerDreht() async throws {
        var gesichert: NRegeln?
        let a = MauMauVarianten(regeln: .schlicht) { gesichert = $0 }     // 7 zieht = aus, 9 dreht = aus
        let modell = VariantenModellAttrappe(antworten: ["Mau-Mau mit 7 ziehen und Neuner dreht": VariantenRohAntwort(aenderungen: [
            .init(option: "sieben_ziehen", wert: "an"), .init(option: "neun_richtung", wert: "an")])])
        let v = try await VariantenAnsage(modell: modell).ansagen("Mau-Mau mit 7 ziehen und Neuner dreht", fuer: a)
        XCTAssertEqual(v.aenderungen.map(\.optionID), ["sieben_ziehen", "neun_richtung"])
        XCTAssertNil(gesichert)                                           // vor der Bestätigung nichts gesetzt
        v.uebernehmen(in: a)
        XCTAssertTrue(a.regeln.siebenZiehen); XCTAssertTrue(a.regeln.neunRichtung)
        XCTAssertEqual(a.regeln.aussetzen, .keine)                        // Rest bleibt
        XCTAssertEqual(gesichert, a.regeln)
    }

    func testNachDemErstenZugNichtMehrAenderbar() async {
        let a = MauMauVarianten(regeln: .standard, aenderbar: { false }) { _ in XCTFail() }
        a.anwenden(["start_karten": .zahl(7)])
        XCTAssertEqual(a.regeln, .standard)
        do { _ = try await VariantenAnsage(modell: VariantenModellAttrappe()).ansagen("sieben Karten", fuer: a); XCTFail() }
        catch { XCTAssertEqual(error as? VariantenFehler, .nichtAenderbar) }
    }

    func testUngueltigeWerteVerwirftDieApp() {
        let a = MauMauVarianten(regeln: .standard) { _ in }
        let v = VariantenPruefer.pruefen(VariantenRohAntwort(aenderungen: [.init(option: "start_karten", wert: "12"), .init(option: "ziel_punkte", wert: "120"), .init(option: "aussetzen", wert: "dame")]),
                                         schema: a.schema, aktuell: a.lesen())
        XCTAssertTrue(v.istLeer)
        XCTAssertEqual(v.verworfen.count, 3)
    }
}
