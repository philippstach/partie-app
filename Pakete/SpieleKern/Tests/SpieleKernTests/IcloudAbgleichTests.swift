// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// E7: Zwei „Geräte“ gleichen über einen Fake-Speicher ab. Nichts geht verloren, nichts wird doppelt, Wiederholen ändert nichts.
final class FakeSpeicher: AbgleichSpeicher, @unchecked Sendable {
    var konto = true
    var fehler = false
    var ablage: [String: Data] = [:]
    var uploads = 0
    func kontoVerfuegbar() async -> Bool { konto }
    func hochladen(geraet: String, daten: Data) async throws { if fehler { throw CocoaError(.fileWriteUnknown) }; ablage[geraet] = daten; uploads += 1 }
    func laden(ausser geraet: String) async throws -> [Data] { if fehler { throw CocoaError(.fileReadUnknown) }; return ablage.filter { $0.key != geraet }.map(\.value) }
}

@MainActor
final class IcloudAbgleichTests: XCTestCase {
    @MainActor struct Geraet {
        let defaults: UserDefaults
        let spieler = SpielerVerzeichnis(ablage: SpeicherAblage())
        let statistik = StatistikDienst(ablage: SpeicherAblage())
        let dienst: AbgleichDienst
        init(_ speicher: FakeSpeicher, name: String) {
            defaults = UserDefaults(suiteName: "test.icloud.\(name).\(UUID().uuidString)")!
            defaults.set(true, forKey: AbgleichDienst.schalterSchluessel)
            dienst = AbgleichDienst(speicher: speicher, defaults: defaults)
        }
        func abgleichen() async -> AbgleichStatus { await dienst.abgleichen(spieler: spieler, statistik: statistik, foto: { _ in nil }) }
    }

    private func partie(_ spiel: String, _ namen: [String]) -> PartieErgebnis {
        .init(id: UUID(), spiel: spiel, datum: Date(), dauer: 60, teilnehmer: namen.enumerated().map { .init(name: $0.element, platz: $0.offset + 1) }, kennzahlen: [:])
    }

    func testZweiGeraeteFindenZusammen() async {
        let cloud = FakeSpeicher()
        let a = Geraet(cloud, name: "a"), b = Geraet(cloud, name: "b")
        a.spieler.anlegen(name: "Anna"); a.statistik.melden(partie("yacht", ["Anna", "Ben"]))
        b.spieler.anlegen(name: "Clara"); b.statistik.melden(partie("dame", ["Clara"]))
        _ = await a.abgleichen()      // A lädt hoch
        _ = await b.abgleichen()      // B übernimmt A und lädt seine Daten hoch
        _ = await a.abgleichen()      // A übernimmt B
        XCTAssertEqual(Set(a.spieler.alle.map(\.name)), ["Anna", "Clara"])
        XCTAssertEqual(Set(b.spieler.alle.map(\.name)), ["Anna", "Clara"])
        XCTAssertEqual(a.statistik.ereignisse.count, 2)
        XCTAssertEqual(b.statistik.ereignisse.count, 2)
    }

    func testWiederholenAendertNichtsUndLaedtNichtNeuHoch() async {
        let cloud = FakeSpeicher()
        let a = Geraet(cloud, name: "a"), b = Geraet(cloud, name: "b")
        a.spieler.anlegen(name: "Anna"); a.statistik.melden(partie("yacht", ["Anna"]))
        _ = await a.abgleichen(); _ = await b.abgleichen(); _ = await a.abgleichen(); _ = await b.abgleichen()
        let uploads = cloud.uploads
        _ = await a.abgleichen(); _ = await b.abgleichen()
        XCTAssertEqual(cloud.uploads, uploads, "ohne Änderung kein neuer Upload")
        XCTAssertEqual(a.spieler.alle.count, 1); XCTAssertEqual(b.spieler.alle.count, 1)
        XCTAssertEqual(b.statistik.ereignisse.count, 1)
    }

    func testGleichnamigePersonenWerdenNichtDoppelt() async {
        let cloud = FakeSpeicher()
        let a = Geraet(cloud, name: "a"), b = Geraet(cloud, name: "b")
        a.spieler.anlegen(name: "Anna"); b.spieler.anlegen(name: "anna")
        _ = await a.abgleichen(); _ = await b.abgleichen(); _ = await a.abgleichen()
        XCTAssertEqual(a.spieler.alle.count, 1); XCTAssertEqual(b.spieler.alle.count, 1)
    }

    func testAusgeschaltetTutNichts() async {
        let cloud = FakeSpeicher()
        let a = Geraet(cloud, name: "a")
        a.dienst.aktiv = false
        a.spieler.anlegen(name: "Anna")
        let s = await a.abgleichen()
        XCTAssertEqual(s, .aus); XCTAssertEqual(cloud.uploads, 0)
    }

    func testKeinKontoUndFehlerBleibenOhneDatenverlust() async {
        let cloud = FakeSpeicher(); cloud.konto = false
        let a = Geraet(cloud, name: "a")
        a.spieler.anlegen(name: "Anna")
        var s = await a.abgleichen()
        XCTAssertEqual(s, .keinKonto)
        cloud.konto = true; cloud.fehler = true
        s = await a.abgleichen()
        XCTAssertEqual(s, .fehler)
        XCTAssertEqual(a.spieler.alle.count, 1)
        cloud.fehler = false
        s = await a.abgleichen()
        if case .fertig = s {} else { XCTFail("sollte sich erholen: \(s)") }
        XCTAssertEqual(cloud.uploads, 1)
    }

    func testKaputterDatensatzWirdUebersprungen() async {
        let cloud = FakeSpeicher()
        cloud.ablage["x"] = Data("kein json".utf8)
        let a = Geraet(cloud, name: "a")
        a.spieler.anlegen(name: "Anna")
        let s = await a.abgleichen()
        if case .fertig = s {} else { XCTFail("\(s)") }
        XCTAssertEqual(a.spieler.alle.count, 1)
    }
}
