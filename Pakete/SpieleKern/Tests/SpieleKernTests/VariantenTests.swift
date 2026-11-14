// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// KI-5: Varianten-Gerüst ohne Modell (Attrappe mit festen Antworten).
final class VariantenTests: XCTestCase {
    private let schema = VariantenSchema(
        spielID: "test", spielName: "Testspiel",
        optionen: [
            VariantenOption(id: "karten", titel: "Karten", art: .zahl(von: 5, bis: 7), standard: .zahl(5), stichworte: ["Hand"]),
            VariantenOption(id: "sieben", titel: "Sieben zieht", art: .schalter, standard: .an(true)),
            VariantenOption(id: "ziel", titel: "Ziel", art: .zahl(von: 50, bis: 150, schritt: 50), standard: .zahl(100)),
            VariantenOption(id: "aussetzen", titel: "Aussetzen", art: .auswahl([VariantenAuswahlEintrag(id: "acht", titel: "Mit der 8"), VariantenAuswahlEintrag(id: "ass", titel: "Mit dem Ass")]),
                            standard: .auswahl("acht")),
        ],
        vorlagen: [VariantenVorlage(id: "wild", titel: "Wild", werte: ["karten": .zahl(7), "sieben": .an(false)])])

    private final class Spiel: SpielVarianten {
        let schema: VariantenSchema
        var werte: [String: VariantenWert]
        var erlaubt = true
        var aenderbar: Bool { erlaubt }
        init(_ s: VariantenSchema) { schema = s; werte = [:] }
        func lesen() -> [String: VariantenWert] { werte }
        func anwenden(_ w: [String: VariantenWert]) { werte.merge(w) { _, neu in neu } }
    }

    func testSchemaIstStimmig() { XCTAssertEqual(schema.fehler(), []) }

    func testFehlerImSchemaWerdenGefunden() {
        let kaputt = VariantenSchema(spielID: "k", spielName: "K",
            optionen: [VariantenOption(id: "a", titel: "A", art: .zahl(von: 1, bis: 3), standard: .zahl(9)), VariantenOption(id: "a", titel: "B", art: .schalter, standard: .an(true))],
            vorlagen: [VariantenVorlage(id: "v", titel: "V", werte: ["x": .an(true), "a": .zahl(99)])])
        XCTAssertEqual(kaputt.fehler().count, 4)
    }

    func testWerteWerdenGeprueft() {
        let k = schema.option("karten")!, z = schema.option("ziel")!, a = schema.option("aussetzen")!, s = schema.option("sieben")!
        XCTAssertEqual(schema.wert(aus: "7", fuer: k), .zahl(7))
        XCTAssertNil(schema.wert(aus: "8", fuer: k))      // außerhalb der Grenzen
        XCTAssertNil(schema.wert(aus: "zehn", fuer: k))   // keine Zahl
        XCTAssertEqual(schema.wert(aus: "150", fuer: z), .zahl(150))
        XCTAssertNil(schema.wert(aus: "120", fuer: z))    // nicht auf dem Raster
        XCTAssertEqual(schema.wert(aus: " Ass ", fuer: a), .auswahl("ass"))
        XCTAssertEqual(schema.wert(aus: "Mit der 8", fuer: a), .auswahl("acht"))
        XCTAssertNil(schema.wert(aus: "dame", fuer: a))
        XCTAssertEqual(schema.wert(aus: "Aus", fuer: s), .an(false))
        XCTAssertNil(schema.wert(aus: "vielleicht", fuer: s))
        XCTAssertFalse(schema.istGueltig(.zahl(1), fuer: s))   // falsche Art
    }

    func testUngueltigesUndUnbekanntesFaelltWeg() {
        let roh = VariantenRohAntwort(vorlage: "gibtesnicht", aenderungen: [
            .init(option: "karten", wert: "9"), .init(option: "erfunden", wert: "an"), .init(option: "sieben", wert: "aus")])
        let v = VariantenPruefer.pruefen(roh, schema: schema, aktuell: [:])
        XCTAssertEqual(v.aenderungen.map(\.optionID), ["sieben"])
        XCTAssertEqual(v.verworfen.map(\.grund), [.unbekannteVorlage, .ungueltigerWert, .unbekannteOption])
        XCTAssertNil(v.vorlageID)
    }

    func testVorlageUndEinzelschalterUeberschreiben() {
        let roh = VariantenRohAntwort(vorlage: "wild", aenderungen: [.init(option: "sieben", wert: "an")])
        let v = VariantenPruefer.pruefen(roh, schema: schema, aktuell: [:])
        XCTAssertEqual(v.vorlageID, "wild")
        XCTAssertEqual(v.aenderungen.map(\.optionID), ["karten"])    // „sieben“ ist wieder an = schon so
        XCTAssertEqual(v.schonSo, 1)
        XCTAssertEqual(v.aenderungen.first?.alt, .zahl(5))
        XCTAssertEqual(v.aenderungen.first?.neu, .zahl(7))
    }

    func testWertGleichAktuellKommtNichtInDieListe() {
        let roh = VariantenRohAntwort(aenderungen: [.init(option: "karten", wert: "6")])
        XCTAssertTrue(VariantenPruefer.pruefen(roh, schema: schema, aktuell: ["karten": .zahl(6)]).istLeer)
    }

    func testReihenfolgeFolgtDemSchema() {
        let roh = VariantenRohAntwort(aenderungen: [.init(option: "aussetzen", wert: "ass"), .init(option: "karten", wert: "6")])
        XCTAssertEqual(VariantenPruefer.pruefen(roh, schema: schema, aktuell: [:]).aenderungen.map(\.optionID), ["karten", "aussetzen"])
    }

    func testAnsageSetztNichtsBisZurBestaetigung() async throws {
        let spiel = Spiel(schema)
        let modell = VariantenModellAttrappe(antworten: ["Wild mit sechs Karten": VariantenRohAntwort(vorlage: "wild", aenderungen: [.init(option: "karten", wert: "6")])])
        let v = try await VariantenAnsage(modell: modell).ansagen("Wild mit sechs Karten", fuer: spiel)
        XCTAssertEqual(spiel.werte, [:])                                   // noch nichts gesetzt
        XCTAssertEqual(Set(v.aenderungen.map(\.optionID)), ["karten", "sieben"])
        XCTAssertEqual(v.uebernehmen(in: spiel, ausgenommen: ["sieben"]), 1)   // Zeile abgewählt
        XCTAssertEqual(spiel.werte, ["karten": .zahl(6)])
    }

    func testNichtAenderbarUndLeereEingabe() async {
        let spiel = Spiel(schema); spiel.erlaubt = false
        let ansage = VariantenAnsage(modell: VariantenModellAttrappe())
        do { _ = try await ansage.ansagen("Wild", fuer: spiel); XCTFail() } catch { XCTAssertEqual(error as? VariantenFehler, .nichtAenderbar) }
        spiel.erlaubt = true
        do { _ = try await ansage.ansagen("   ", fuer: spiel); XCTFail() } catch { XCTAssertEqual(error as? VariantenFehler, .leereEingabe) }
        let v = VariantenVorschlag(spielID: "test", vorlageID: nil, aenderungen: [VariantenAenderung(optionID: "karten", titel: "K", alt: .zahl(5), neu: .zahl(7))], verworfen: [], schonSo: 0)
        spiel.erlaubt = false
        XCTAssertEqual(v.uebernehmen(in: spiel), 0)                         // gesperrt: nichts gesetzt
        XCTAssertEqual(spiel.werte, [:])
    }

    func testModellFehlerWirdZuModellFehler() async {
        struct Kaputt: VariantenModell, Sendable { struct E: Error {}; func waehle(anweisung: String, eingabe: String) async throws -> VariantenRohAntwort { throw E() } }
        do { _ = try await VariantenAnsage(modell: Kaputt()).ansagen("Wild", fuer: Spiel(schema)); XCTFail() } catch { XCTAssertEqual(error as? VariantenFehler, .modellFehler) }
        let attrappe = VariantenModellAttrappe(fehler: .nichtVerfuegbar)
        do { _ = try await VariantenAnsage(modell: attrappe).ansagen("Wild", fuer: Spiel(schema)); XCTFail() } catch { XCTAssertEqual(error as? VariantenFehler, .nichtVerfuegbar) }
    }

    func testVorlageAusAnderemSpielWirdNichtUebernommen() {
        let v = VariantenVorschlag(spielID: "anderes", vorlageID: nil, aenderungen: [VariantenAenderung(optionID: "karten", titel: "K", alt: .zahl(5), neu: .zahl(7))], verworfen: [], schonSo: 0)
        let spiel = Spiel(schema)
        XCTAssertEqual(v.uebernehmen(in: spiel), 0)
    }

    func testPromptEnthaeltNurSchemaUndBleibtBegrenzt() {
        let viele = (1...40).map { VariantenOption(id: "o\($0)", titel: "Option \($0)", art: .schalter, standard: .an(false), stichworte: $0 == 33 ? ["Strafkarte"] : []) }
        let s = VariantenSchema(spielID: "viel", spielName: "Viel", optionen: viele)
        let p = VariantenAnsage.anweisung(schema: s, aktuell: [:], eingabe: "mit Strafkarte")
        XCTAssertEqual(p.components(separatedBy: "\n").filter { $0.hasPrefix("o") && $0.contains("|") }.count, VariantenAnsage.hoechstensOptionen)
        XCTAssertTrue(p.contains("o33|"))                                  // Stichwort findet die Option
        XCTAssertTrue(p.contains("Viel"))
        XCTAssertLessThan(p.count, 3000)                                    // grob unter dem Kontext von 4096 Tokens
        let klein = VariantenAnsage.anweisung(schema: schema, aktuell: ["karten": .zahl(6)], eingabe: "egal")
        XCTAssertTrue(klein.contains("karten|Karten|Zahl 5 bis 7|jetzt: 6"))
        XCTAssertTrue(klein.contains("wild|Wild"))
    }

    func testStatusOhneModellIstVerborgenOderEinZustand() {
        // Im Simulator ohne Apple Intelligence darf nichts abstürzen; auf iOS 17 bis 25 ist es immer verborgen.
        _ = VariantenStatus.aktuell()
    }
}
