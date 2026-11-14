// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

@MainActor
final class TurnierRivalitaetTests: XCTestCase {
    func testRivalitaetSerieUndBilanzJeSpiel() {
        let a = UUID(), b = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        func melde(_ spiel: String, _ pa: Int, _ pb: Int) { st.melden(PartieErgebnis(spiel: spiel, teilnehmer: [.init(spielerID: a, name: "A", platz: pa), .init(spielerID: b, name: "B", platz: pb)])) }
        melde("dame", 2, 1); melde("dame", 1, 2); melde("yacht", 1, 2); melde("yacht", 1, 2)
        var r = st.rivalitaet(a, gegen: b)
        XCTAssertEqual(r.gesamt, StatistikDienst.Duell(partien: 4, siege: 3, niederlagen: 1, unentschieden: 0))
        XCTAssertEqual(r.serieWer, a); XCTAssertEqual(r.serieLaenge, 3)
        XCTAssertEqual(r.spiele.count, 2)
        melde("dame", 1, 1)                       // Remis bricht die Serie
        r = st.rivalitaet(a, gegen: b)
        XCTAssertNil(r.serieWer); XCTAssertEqual(r.serieLaenge, 0)
        XCTAssertEqual(st.rivalitaet(b, gegen: a).gesamt.siege, 1)
        XCTAssertEqual(st.rivalen(von: a, unter: [a, b, UUID()]).count, 1)
    }

    func testTurnierPunkteRanglisteUndAbbruch() {
        var t = Turnier(spieler: ["Anna", "Ben", "Cem"], spiele: ["yacht", "dame"])
        XCTAssertFalse(t.buchen(spiel: "dame", teilnehmer: [("Anna", 1), ("Ben", 2), ("Cem", 3)]))   // falsches Spiel
        XCTAssertFalse(t.buchen(spiel: "yacht", teilnehmer: [("Anna", 2), ("Ben", 2), ("Cem", 2)]))  // Abbruch
        XCTAssertTrue(t.buchen(spiel: "yacht", teilnehmer: [("anna", 1), ("Ben", 2), ("Cem", 3), ("Computer", 4)]))
        XCTAssertEqual(t.naechsteRunde?.spiel, "dame"); XCTAssertFalse(t.fertig)
        XCTAssertTrue(t.buchen(spiel: "dame", teilnehmer: [("Ben", 1), ("Cem", 1), ("Anna", 3)]))
        XCTAssertTrue(t.fertig)
        let r = t.rangliste
        // Anna 3+1=4, Ben 2+3=5, Cem 1+3=4 (je 1 Sieg, geteilter Sieg zählt)
        XCTAssertEqual(r[0].name, "Ben"); XCTAssertEqual(r[0].punkte, 5)
        XCTAssertEqual(r[1].name, "Anna"); XCTAssertEqual(r[1].punkte, 4); XCTAssertEqual(r[1].platz, 2)
        XCTAssertEqual(r[2].name, "Cem"); XCTAssertEqual(r[2].platz, 2)   // gleiche Punkte, je ein (geteilter) Sieg
    }

    func testTurnierDienstSpeichertUndUeberspringt() {
        let d = UserDefaults(suiteName: "turnier-test-\(UUID())")!
        let dienst = TurnierDienst(defaults: d)
        dienst.starten(Turnier(spieler: ["A", "B"], spiele: ["x", "y"]))
        XCTAssertTrue(dienst.partieBeendet(PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "A", platz: 1), .init(name: "B", platz: 2)])))
        XCTAssertEqual(TurnierDienst(defaults: d).aktuell?.gespielteRunden, 1)
        dienst.ueberspringen()
        XCTAssertTrue(dienst.aktuell?.fertig == true)
        dienst.beenden()
        XCTAssertNil(TurnierDienst(defaults: d).aktuell)
    }

    func testDuellGewichtVerlaufUndVorzeitigesEnde() {
        var t = Turnier(spieler: ["A", "B"], spiele: ["a", "b", "c", "d", "e"], art: .duell)
        XCTAssertEqual(t.gesamtPunkte, 15); XCTAssertEqual(t.restPunkte, 15)
        t.buchen(spiel: "a", teilnehmer: [("A", 1), ("B", 2)])        // A: 1
        t.buchen(spiel: "b", teilnehmer: [("A", 1), ("B", 1)])        // Remis: nichts
        t.buchen(spiel: "c", teilnehmer: [("B", 1), ("A", 2)])        // B: 3
        XCTAssertEqual(t.rangliste.first { $0.name == "A" }?.punkte, 1)
        XCTAssertEqual(t.rangliste.first { $0.name == "B" }?.punkte, 3)
        XCTAssertEqual(t.restPunkte, 9); XCTAssertFalse(t.fertig)
        let v = t.verlauf
        XCTAssertEqual(v.filter { $0.name == "B" }.map(\.punkte), [0, 0, 0, 3])
        t.buchen(spiel: "d", teilnehmer: [("B", 1), ("A", 2)])        // B: 7, Rest 5, Vorsprung 6 -> entschieden
        XCTAssertTrue(t.vorzeitigEntschieden); XCTAssertTrue(t.fertig)
        XCTAssertEqual(t.rangliste.first?.name, "B")
    }

    func testZufallsSpieleUndAltesTurnierDecodiert() throws {
        XCTAssertEqual(Set(Turnier.zufallsSpiele(aus: ["a", "b", "c"], anzahl: 3)), ["a", "b", "c"])
        XCTAssertEqual(Turnier.zufallsSpiele(aus: ["a", "b"], anzahl: 5).count, 5)
        let alt = #"{"spieler":["A","B"],"runden":[]}"#.data(using: .utf8)!
        XCTAssertEqual(try JSONDecoder().decode(Turnier.self, from: alt).art, .abend)
    }
}
