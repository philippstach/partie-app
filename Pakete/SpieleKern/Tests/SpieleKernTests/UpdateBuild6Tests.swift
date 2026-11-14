// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// Update von Build 6 auf Build 7: Spieler, Fotos und Partien müssen vollständig übernommen werden.
/// Die alten Datenstände entstehen aus den Typen, wie sie in Build 6 waren (ohne Foto-Zähler), mit dem damaligen Standard-Encoder.
@MainActor
final class UpdateBuild6Tests: XCTestCase {
    /// `Spieler` in Build 6.
    private struct AltSpieler: Codable {
        var id: UUID; var name: String; var avatar: String; var farbeIndex: Int; var art: String; var ich: Bool; var angelegt: Date; var zuletzt: Date
    }

    private let anna = UUID(), ben = UUID(), computer = UUID()

    private func altSpieler() throws -> Data {
        let t0 = Date(timeIntervalSinceReferenceDate: 700_000_000)
        return try JSONEncoder().encode([
            AltSpieler(id: anna, name: "Anna", avatar: "A", farbeIndex: 0, art: "mensch", ich: true, angelegt: t0, zuletzt: t0 + 900),
            AltSpieler(id: ben, name: "Ben", avatar: "🦊", farbeIndex: 1, art: "mensch", ich: false, angelegt: t0 + 100, zuletzt: t0 + 500),
            AltSpieler(id: computer, name: "Computer", avatar: "C", farbeIndex: 2, art: "computer", ich: false, angelegt: t0 + 200, zuletzt: t0 + 200)])
    }

    private func altePartien() throws -> Data {
        try JSONEncoder().encode([
            PartieErgebnis(spiel: "dame", datum: Date(timeIntervalSinceReferenceDate: 700_000_200), dauer: 300, teilnehmer: [.init(spielerID: anna, name: "Anna", platz: 1), .init(spielerID: ben, name: "Ben", platz: 2)]),
            PartieErgebnis(spiel: "sudoku", datum: Date(timeIntervalSinceReferenceDate: 700_000_100), dauer: 600, teilnehmer: [.init(name: "", platz: 1)]),
            PartieErgebnis(spiel: "yacht", datum: Date(timeIntervalSinceReferenceDate: 700_000_300), dauer: 900, teilnehmer: [.init(spielerID: anna, name: "Anna", platz: 1, punkte: 210), .init(name: "Computer", platz: 2, punkte: 180)], kennzahlen: ["stufe": 2])])
    }

    private func suite(_ name: String) -> UserDefaults { let d = UserDefaults(suiteName: name)!; d.removePersistentDomain(forName: name); return d }

    func testAlterSpeicherstandImEchtenUserDefaultsWegLaedtVollstaendig() throws {
        let d = suite("update6-a")
        d.set(try altSpieler(), forKey: "partie.spieler"); d.set(try altePartien(), forKey: "partie.statistik")
        let v = SpielerVerzeichnis(ablage: DefaultsAblageDaten(schluessel: "partie.spieler", defaults: d))
        let st = StatistikDienst(ablage: DefaultsAblageDaten(schluessel: "partie.statistik", defaults: d))
        XCTAssertEqual(v.alle.map(\.name), ["Anna", "Ben", "Computer"])
        XCTAssertEqual(v.ich?.id, anna); XCTAssertEqual(v.alle[1].avatar, "🦊"); XCTAssertEqual(v.alle[2].art, .computer)
        XCTAssertTrue(v.alle.allSatisfy { $0.bildNr == nil })
        XCTAssertEqual(st.ereignisse.count, 3)
        XCTAssertEqual(st.summe(spieler: anna), StatistikSumme(partien: 2, siege: 2, dauer: 1200))
        XCTAssertEqual(st.rekord(spiel: "yacht"), 210)
        XCTAssertEqual(st.rekord(spiel: "yacht", stufe: 2), 210)
        XCTAssertEqual(st.summe(spiel: "sudoku").siege, 1, "Partie ohne Personenzuordnung bleibt erhalten und zählt")
    }

    func testNachDemUpdateWirdWeiterGeschriebenOhneAltesZuVerlieren() throws {
        let d = suite("update6-b")
        d.set(try altSpieler(), forKey: "partie.spieler"); d.set(try altePartien(), forKey: "partie.statistik")
        do {   // erster Start von Build 7: neue Person mit Foto, neue Partie
            let v = SpielerVerzeichnis(ablage: DefaultsAblageDaten(schluessel: "partie.spieler", defaults: d))
            let st = StatistikDienst(ablage: DefaultsAblageDaten(schluessel: "partie.statistik", defaults: d))
            let cem = v.speichern(name: "Cem", avatar: "", farbeIndex: 4)!
            var neu = v.alle.first { $0.id == cem.id }!; neu.bildNr = 1; XCTAssertEqual(neu.name, "Cem")
            st.melden(v.zuordnen(PartieErgebnis(spiel: "schach", teilnehmer: [.init(name: "Cem", platz: 1), .init(name: "Anna", platz: 2)])))
        }
        // zweiter Start: alles da, alt und neu
        let v2 = SpielerVerzeichnis(ablage: DefaultsAblageDaten(schluessel: "partie.spieler", defaults: d))
        let st2 = StatistikDienst(ablage: DefaultsAblageDaten(schluessel: "partie.statistik", defaults: d))
        XCTAssertEqual(v2.alle.map(\.name), ["Anna", "Ben", "Computer", "Cem"]); XCTAssertEqual(v2.ich?.id, anna)
        XCTAssertEqual(st2.ereignisse.count, 4)
        XCTAssertEqual(st2.summe(spieler: anna).partien, 3)
    }

    func testFotosUeberlebenDasUpdateWeilSieInDateienLiegenNichtImSpeicher() throws {
        let id = UUID()
        let jpg = Data([0xFF, 0xD8, 1, 2, 3, 0xFF, 0xD9])
        try jpg.write(to: SpielerBilder.datei(id))
        // Build 7 startet neu (neues Verzeichnis-Objekt): die Datei ist unabhängig vom Speicher noch da
        XCTAssertEqual(SpielerBilder.daten(id), jpg)
        SpielerBilder.loeschen(id)
    }

    func testEinKaputterEintragVerliertNichtAlleSpielerUndPartien() throws {
        let kaputt = """
        [{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Anna","avatar":"A","farbeIndex":0,"art":"mensch","ich":true,"angelegt":700000000,"zuletzt":700000000},
         {"id":"nicht-eine-uuid","name":"Defekt"},
         {"id":"7F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Ben","avatar":"B","farbeIndex":1,"art":"mensch","ich":false,"angelegt":700000100,"zuletzt":700000100}]
        """
        let v = SpielerVerzeichnis(ablage: SpeicherAblage(daten: Data(kaputt.utf8)))
        XCTAssertEqual(v.alle.map(\.name), ["Anna", "Ben"])
        let partien = """
        [{"id":"11111111-1111-1111-1111-111111111111","spiel":"dame","datum":1,"dauer":1,"kennzahlen":{},"teilnehmer":[{"name":"A","platz":1}]},
         {"spiel":"ohne-id"},
         {"id":"22222222-2222-2222-2222-222222222222","spiel":"schach","datum":2,"dauer":2,"kennzahlen":{},"teilnehmer":[{"name":"B","platz":1}]}]
        """
        let st = StatistikDienst(ablage: SpeicherAblage(daten: Data(partien.utf8)))
        XCTAssertEqual(st.ereignisse.map(\.spiel), ["dame", "schach"])
    }

    func testUnbekannteArtEinerPersonMachtSieNichtUnsichtbar() throws {
        // z. B. aus einer späteren Fassung: neue Art, die dieser Stand nicht kennt
        let j = """
        [{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Roboter-Ron","avatar":"R","farbeIndex":3,"art":"roboter","ich":false,"angelegt":1,"zuletzt":1}]
        """
        let v = SpielerVerzeichnis(ablage: SpeicherAblage(daten: Data(j.utf8)))
        XCTAssertEqual(v.alle.map(\.name), ["Roboter-Ron"])
    }

    func testKomplettKaputterSpeicherstandWirdNichtZurLeerschreibungDerGuten() {
        // Kein Array: nichts lesbar. Das Verzeichnis startet leer, überschreibt die Ablage aber erst bei einer echten Änderung.
        let ablage = SpeicherAblage(daten: Data("{\"kaputt\":true}".utf8))
        _ = SpielerVerzeichnis(ablage: ablage)
        XCTAssertEqual(ablage.daten, Data("{\"kaputt\":true}".utf8), "Nur Lesen darf die Ablage nicht anfassen")
    }
}
