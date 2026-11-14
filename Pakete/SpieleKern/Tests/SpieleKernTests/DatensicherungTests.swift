// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// Datensicherung und Übernahme: nichts geht verloren, auch nicht Partien ohne Personenzuordnung oder Daten aus Build 6.
@MainActor
final class DatensicherungTests: XCTestCase {
    /// So sah der Speicher in Build 6 aus: Personen ohne Foto-Feld, Partien teils ohne Zuordnung.
    private let spielerBuild6 = """
    [{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Anna","avatar":"A","farbeIndex":0,"art":"mensch","ich":true,"angelegt":700000000,"zuletzt":700000900},
     {"id":"7F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Ben","avatar":"🦊","farbeIndex":1,"art":"mensch","ich":false,"angelegt":700000100,"zuletzt":700000500}]
    """
    private let partienBuild6 = """
    [{"id":"11111111-1111-1111-1111-111111111111","spiel":"dame","datum":700000200,"dauer":300,"kennzahlen":{},
      "teilnehmer":[{"spielerID":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Anna","platz":1},{"spielerID":"7F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Ben","platz":2}]},
     {"id":"22222222-2222-2222-2222-222222222222","spiel":"sudoku","datum":700000100,"dauer":600,"kennzahlen":{},"teilnehmer":[{"name":"","platz":1}]},
     {"id":"33333333-3333-3333-3333-333333333333","spiel":"wortpfeil","datum":700000300,"dauer":120,"kennzahlen":{},"teilnehmer":[{"name":"Anna","platz":1}]}]
    """

    private func build6() -> (SpielerVerzeichnis, StatistikDienst) {
        (SpielerVerzeichnis(ablage: SpeicherAblage(daten: Data(spielerBuild6.utf8))), StatistikDienst(ablage: SpeicherAblage(daten: Data(partienBuild6.utf8))))
    }

    func testBuild6DatenLadenVollstaendigUndLassenSichSichern() throws {
        let (v, st) = build6()
        XCTAssertEqual(v.alle.map(\.name), ["Anna", "Ben"]); XCTAssertEqual(v.ich?.name, "Anna")
        XCTAssertNil(v.alle[0].bildNr)
        XCTAssertEqual(v.alle[1].avatar, "🦊")
        XCTAssertEqual(st.ereignisse.count, 3, "auch die Partien ohne Personenzuordnung bleiben")
        let daten = try Datensicherung.erstellen(spieler: v.alle, partien: st.ereignisse, foto: { _ in nil })
        let s = try Datensicherung.lesen(daten)
        XCTAssertEqual(s.spieler, v.alle); XCTAssertEqual(s.partien, st.ereignisse); XCTAssertTrue(s.fotos.isEmpty)
        XCTAssertEqual(s.version, Sicherung.aktuelleVersion)
    }

    func testSicherungAufNeuemGeraetWiederherstellenMitFotoUndPartienOhneZuordnung() throws {
        let (v, st) = build6()
        let anna = v.alle[0]
        // Anna bekommt ein Foto (Bytes wie eine kleine JPEG-Datei)
        let jpg = Data([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3, 0xFF, 0xD9])
        XCTAssertTrue(SpielerBilder.ablegen(jpg, fuer: anna.id))
        var a = anna; a.bildNr = 1
        let daten = try Datensicherung.erstellen(spieler: [a, v.alle[1]], partien: st.ereignisse, foto: { SpielerBilder.daten($0) })
        SpielerBilder.loeschen(anna.id)                                   // „neues Gerät“: Foto ist weg
        let neuV = SpielerVerzeichnis(ablage: SpeicherAblage()); let neuSt = StatistikDienst(ablage: SpeicherAblage())
        let u = neuV.uebernehmen(try Datensicherung.lesen(daten), statistik: neuSt)
        XCTAssertEqual(u, Uebernahme(spieler: 2, fotos: 1, partien: 3))
        XCTAssertEqual(neuV.alle.map(\.name), ["Anna", "Ben"])
        XCTAssertEqual(neuV.alle[0].bildNr, 1); XCTAssertEqual(SpielerBilder.daten(anna.id), jpg)
        XCTAssertEqual(neuV.ich?.name, "Anna")
        XCTAssertEqual(neuSt.ereignisse.count, 3)
        XCTAssertEqual(neuSt.summe(spieler: anna.id), StatistikSumme(partien: 1, siege: 1, dauer: 300))
        XCTAssertTrue(neuSt.ereignisse.contains { $0.teilnehmer.allSatisfy { $0.spielerID == nil } }, "Partie ohne Zuordnung ist noch da")
        SpielerBilder.loeschen(anna.id)
    }

    func testMehrfachesUebernehmenAendertNichts() throws {
        let (v, st) = build6()
        let s = try Datensicherung.lesen(Datensicherung.erstellen(spieler: v.alle, partien: st.ereignisse, foto: { _ in nil }))
        XCTAssertTrue(v.uebernehmen(s, statistik: st).nichtsNeu)
        XCTAssertEqual(v.alle.count, 2); XCTAssertEqual(st.ereignisse.count, 3)
    }

    func testGleichnamigePersonUnterAndererIDWirdZusammengefuehrt() throws {
        let (v, st) = build6()
        let s = try Datensicherung.lesen(Datensicherung.erstellen(spieler: v.alle, partien: st.ereignisse, foto: { _ in nil }))
        // Gerät, auf dem es „Anna“ schon unter einer anderen ID gibt, mit eigener Partie
        let gv = SpielerVerzeichnis(ablage: SpeicherAblage()); let gs = StatistikDienst(ablage: SpeicherAblage())
        let annaNeu = gv.speichern(name: "anna", avatar: "", farbeIndex: 3)!
        gs.melden(PartieErgebnis(spiel: "schach", datum: Date(timeIntervalSinceReferenceDate: 700000400), teilnehmer: [.init(spielerID: annaNeu.id, name: "anna", platz: 1)]))
        let u = gv.uebernehmen(s, statistik: gs)
        XCTAssertEqual(u.spieler, 1, "nur Ben ist neu")
        XCTAssertEqual(gv.alle.filter { $0.name.lowercased() == "anna" }.count, 1)
        XCTAssertEqual(gv.ich?.id, annaNeu.id, "die vorhandene Person bleibt Ich")
        XCTAssertEqual(gv.alle.first { $0.name == "Ben" }?.ich, false)
        XCTAssertEqual(gs.summe(spieler: annaNeu.id).partien, 2, "dame (mit ID, umgelegt) und schach; sudoku und wortpfeil haben im alten Stand keine ID und bleiben unverändert erhalten")
        XCTAssertEqual(gs.ereignisse.map(\.spiel), ["sudoku", "dame", "wortpfeil", "schach"], "nach Datum sortiert")
    }

    func testKaputteUndFremdeDateienUndNeueVersionWerdenAbgelehnt() throws {
        XCTAssertThrowsError(try Datensicherung.lesen(Data("kein json".utf8))) { XCTAssertEqual($0 as? SicherungFehler, .keineSicherung) }
        XCTAssertThrowsError(try Datensicherung.lesen(Data("[1,2,3]".utf8))) { XCTAssertEqual($0 as? SicherungFehler, .keineSicherung) }
        XCTAssertThrowsError(try Datensicherung.lesen(Data(#"{"foo":1}"#.utf8))) { XCTAssertEqual($0 as? SicherungFehler, .keineSicherung) }
        let neu = #"{"version":99,"erstellt":0,"spieler":[],"fotos":{},"partien":[]}"#
        XCTAssertThrowsError(try Datensicherung.lesen(Data(neu.utf8))) { XCTAssertEqual($0 as? SicherungFehler, .zuNeu) }
        let leer = #"{"version":1,"erstellt":0,"spieler":[],"fotos":{},"partien":[]}"#
        XCTAssertEqual(try Datensicherung.lesen(Data(leer.utf8)).partien.count, 0)
    }

    func testDateiname() {
        let d = Date(timeIntervalSince1970: 1_762_560_000)   // 8. November 2025, UTC-Mittag spielt keine Rolle
        XCTAssertTrue(Datensicherung.dateiname(am: d).hasPrefix("Partie-Sicherung-20"))
        XCTAssertTrue(Datensicherung.dateiname(am: d).hasSuffix(".json"))
    }
}
