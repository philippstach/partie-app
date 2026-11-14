// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WuerfelFunk

/// Zweiwege-Protokoll (Fassung 2), Quittungen, Puls, Wiederverbinden und bekannte Geräte: alles reine Logik, läuft mit `swift test`.
final class ProtokollTests: XCTestCase {
    private func hinUndZurueck(_ n: FunkNachricht, file: StaticString = #filePath, line: UInt = #line) throws {
        let d = try XCTUnwrap(n.kodiert(), file: file, line: line)
        XCTAssertEqual(FunkNachricht.lies(d), n, file: file, line: line)
    }

    func testAlleArtenHinUndZurueck() throws {
        try hinUndZurueck(.hallo(FunkHallo(kennung: "A-1", name: "iPad", rolle: .spielgeraet)))
        try hinUndZurueck(.lage(FunkLage(spiel: "Yacht", amZug: "Anna", erwartet: 5, gehalten: 2, bereit: true)))
        try hinUndZurueck(.lage(FunkLage()))
        try hinUndZurueck(.quittung(FunkQuittung(folge: 4, lauf: "L", grund: .angenommen)))
        try hinUndZurueck(.quittung(FunkQuittung(folge: 4, lauf: nil, grund: .keinEmpfaenger)))
        try hinUndZurueck(.wurf(FunkWurf(folge: 3, augen: [1, 6, 4], lauf: "L")))
        try hinUndZurueck(.wurf(FunkWurf(folge: 3, augen: [1, 6, 4])))
        try hinUndZurueck(.stand(FunkStand(erkannt: 3, erwartet: 5, sicher: false)))
        try hinUndZurueck(.puls)
        try hinUndZurueck(.tschuess)
    }

    func testUmschlagTraegtVersionUndArt() throws {
        let d = try XCTUnwrap(FunkNachricht.puls.kodiert())
        let o = try XCTUnwrap(try JSONSerialization.jsonObject(with: d) as? [String: Any])
        XCTAssertEqual(o["v"] as? Int, FunkProtokoll.version)
        XCTAssertEqual(o["art"] as? String, "puls")
    }

    func testUnbekannteArtWirdUeberlesen() {
        let d = Data(#"{"v":3,"art":"zaubertrick","inhalt":{"x":1}}"#.utf8)
        XCTAssertEqual(FunkNachricht.lies(d), .unbekannt(art: "zaubertrick"))
        XCTAssertNil(FunkNachricht.unbekannt(art: "x").kodiert(), "Unbekanntes wird nie verschickt")
    }

    func testNeuereFassungMitZusatzfeldernWirdGelesen() {
        let d = Data(#"{"v":7,"art":"wurf","inhalt":{"folge":2,"augen":[5,5],"lauf":"L","farbe":"rot"},"neu":true}"#.utf8)
        XCTAssertEqual(FunkNachricht.lies(d), .wurf(FunkWurf(folge: 2, augen: [5, 5], lauf: "L")))
    }

    func testUnbekannterQuittungsgrund() {
        let d = Data(#"{"v":3,"art":"quittung","inhalt":{"folge":1,"grund":"spaeter"}}"#.utf8)
        guard case .quittung(let q)? = FunkNachricht.lies(d) else { return XCTFail("keine Quittung") }
        XCTAssertEqual(q.grund, .anderer)
        XCTAssertFalse(q.angekommen)
    }

    func testKaputtesUndFehlendeFelder() {
        XCTAssertNil(FunkNachricht.lies(Data("kaputt".utf8)))
        XCTAssertNil(FunkNachricht.lies(Data(#"{"v":2,"art":"wurf"}"#.utf8)), "Wurf ohne Inhalt")
        XCTAssertNil(FunkNachricht.lies(Data(#"{"v":2,"art":"wurf","inhalt":{"augen":[1]}}"#.utf8)), "Wurf ohne Nummer")
    }

    /// Fassung 1 (bis Build 21) schickt das synthetische Enum-Format. Das muss weiter ankommen.
    func testAltesFormatAusFassungEins() {
        let d = Data(#"{"wurf":{"_0":{"folge":3,"augen":[1,6,4]}}}"#.utf8)
        XCTAssertEqual(FunkNachricht.lies(d), .wurf(FunkWurf(folge: 3, augen: [1, 6, 4])))
    }

    // MARK: Empfang mit Lauf-Kennung

    func testEmpfangZaehltUeberWiederverbindenWeiter() {
        var e = WurfEmpfang()
        XCTAssertEqual(e.pruefe(FunkWurf(folge: 1, augen: [2], lauf: "A")), .neu([2]))
        XCTAssertEqual(e.pruefe(FunkWurf(folge: 2, augen: [3], lauf: "A")), .neu([3]))
        e.neueVerbindung()
        XCTAssertEqual(e.pruefe(FunkWurf(folge: 2, augen: [3], lauf: "A")), .doppelt, "nach dem Wiederverbinden nochmal geschickt")
        XCTAssertEqual(e.pruefe(FunkWurf(folge: 3, augen: [4], lauf: "A")), .neu([4]))
    }

    func testEmpfangNeuerLaufBeginntBeiEins() {
        var e = WurfEmpfang()
        _ = e.pruefe(FunkWurf(folge: 5, augen: [2], lauf: "A"))
        XCTAssertEqual(e.pruefe(FunkWurf(folge: 1, augen: [6], lauf: "B")), .neu([6]))
        XCTAssertEqual(e.pruefe(FunkWurf(folge: 0, augen: [6], lauf: "B")), .doppelt)
        XCTAssertEqual(e.pruefe(FunkWurf(folge: 2, augen: [0], lauf: "B")), .ungueltig)
    }

    func testMelderLaufNeuNachZuruecksetzen() {
        var m = WurfMelder()
        let a = m.lauf
        var w: FunkWurf?
        for _ in 0..<6 { w = m.beobachte(augen: [4], sicher: true) ?? w }
        XCTAssertEqual(w?.lauf, a)
        m.zuruecksetzen()
        XCTAssertNotEqual(m.lauf, a)
    }

    // MARK: Ausgang

    func testAusgangHaeltBisZurQuittung() {
        var a = WurfAusgang()
        a.gesendet(FunkWurf(folge: 1, augen: [1], lauf: "L"))
        a.gesendet(FunkWurf(folge: 2, augen: [2], lauf: "L"))
        XCTAssertEqual(a.offen.count, 2)
        a.quittiert(FunkQuittung(folge: 2, lauf: "L", grund: .angenommen))
        XCTAssertTrue(a.offen.isEmpty, "Quittung für 2 gilt auch für 1")
    }

    func testAusgangKeinEmpfaengerBleibtOffenUngueltigFaellt() {
        var a = WurfAusgang()
        a.gesendet(FunkWurf(folge: 1, augen: [1], lauf: "L"))
        a.quittiert(FunkQuittung(folge: 1, lauf: "L", grund: .keinEmpfaenger))
        XCTAssertEqual(a.offen.count, 1)
        a.quittiert(FunkQuittung(folge: 1, lauf: "L", grund: .ungueltig))
        XCTAssertTrue(a.offen.isEmpty)
    }

    func testAusgangFremderLaufUndObergrenze() {
        var a = WurfAusgang()
        for i in 1...8 { a.gesendet(FunkWurf(folge: i, augen: [1], lauf: "L")) }
        XCTAssertEqual(a.offen.map(\.folge), [4, 5, 6, 7, 8])
        a.quittiert(FunkQuittung(folge: 8, lauf: "anderer", grund: .angenommen))
        XCTAssertEqual(a.offen.count, 5, "Quittung eines anderen Laufs zählt nicht")
        a.gesendet(FunkWurf(folge: 8, augen: [1], lauf: "L"))
        XCTAssertEqual(a.offen.count, 5, "derselbe Wurf nicht doppelt")
    }

    // MARK: Puls

    func testPulsDreiVerpassteHeissenStumm() {
        var p = PulsWaechter(abstand: 2, grenze: 3)
        let t0 = Date(timeIntervalSince1970: 1000)
        XCTAssertFalse(p.istStumm(t0), "ohne Lebenszeichen noch nicht stumm")
        p.lebenszeichen(t0)
        XCTAssertFalse(p.istStumm(t0.addingTimeInterval(5.9)))
        XCTAssertTrue(p.istStumm(t0.addingTimeInterval(6.1)))
        p.lebenszeichen(t0.addingTimeInterval(6.1))
        XCTAssertFalse(p.istStumm(t0.addingTimeInterval(7)))
    }

    // MARK: Wiederverbinden

    func testWiederverbindenWachsenderAbstandHoechstensZweiMinuten() {
        var w = WiederverbindePlan()
        var abstaende: [TimeInterval] = []
        while let a = w.naechsteWartezeit() { abstaende.append(a) }
        XCTAssertEqual(Array(abstaende.prefix(5)), [1, 2, 4, 8, 8])
        XCTAssertLessThanOrEqual(abstaende.reduce(0, +), 120)
        XCTAssertGreaterThan(abstaende.reduce(0, +), 110)
        XCTAssertNil(w.naechsteWartezeit(), "aufgegeben bleibt aufgegeben")
        w.zuruecksetzen()
        XCTAssertFalse(w.laeuft)
        XCTAssertEqual(w.naechsteWartezeit(), 1)
        XCTAssertTrue(w.laeuft)
    }

    // MARK: Bekannte Geräte

    func testBekannteMerkenVergessenReihenfolge() {
        var b = BekannteGeraete()
        let t = Date(timeIntervalSince1970: 0)
        b.merke(kennung: "A", name: "iPad", jetzt: t)
        b.merke(kennung: "B", name: "iPad", jetzt: t)
        XCTAssertEqual(b.liste.map(\.kennung), ["B", "A"], "gleicher Name, trotzdem zwei Geräte")
        b.merke(kennung: "A", name: "iPad Küche", jetzt: t)
        XCTAssertEqual(b.liste.map(\.kennung), ["A", "B"])
        XCTAssertEqual(b.liste.first?.name, "iPad Küche")
        XCTAssertTrue(b.kennt("B")); XCTAssertFalse(b.kennt("C")); XCTAssertFalse(b.kennt(nil)); XCTAssertFalse(b.kennt(""))
        b.vergiss("B")
        XCTAssertFalse(b.kennt("B"))
        b.merke(kennung: "", name: "leer")
        XCTAssertEqual(b.liste.count, 1)
    }

    func testBekannteObergrenze() {
        var b = BekannteGeraete()
        b.hoechstens = 3
        for i in 0..<5 { b.merke(kennung: "\(i)", name: "x") }
        XCTAssertEqual(b.liste.map(\.kennung), ["4", "3", "2"])
    }

    func testBekannteUndEigeneKennungGespeichert() throws {
        let name = "WuerfelFunkTests-\(UUID().uuidString)"
        let d = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { d.removePersistentDomain(forName: name) }
        var b = BekannteGeraete()
        b.merke(kennung: "A", name: "iPad")
        b.sichern(d)
        XCTAssertEqual(BekannteGeraete.laden(d).liste.map(\.kennung), ["A"])
        let k = EigeneKennung.lesen(d)
        XCTAssertFalse(k.isEmpty)
        XCTAssertEqual(EigeneKennung.lesen(d), k, "Kennung bleibt gleich")
    }

    // MARK: Zustände

    func testZustandGegenueber() {
        XCTAssertEqual(FunkZustand.verbunden(name: "iPad").gegenueber, "iPad")
        XCTAssertTrue(FunkZustand.verbunden(name: "iPad").istVerbunden)
        XCTAssertTrue(FunkZustand.unterbrochen(name: "iPad", versuch: 2).istUnterbrochen)
        XCTAssertNil(FunkZustand.sucht.gegenueber)
        XCTAssertEqual(FunkZustand.getrennt(name: nil, grund: .abgelehnt).gegenueber, nil)
    }
}
