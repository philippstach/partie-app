// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HoelzchenKern
final class HoelzchenTests: XCTestCase {
    func testRegeln() {
        var s = Hoelzchen(reihen: [1, 3], modus: .normal)
        XCTAssertFalse(s.nimm(reihe: 0, anzahl: 2)); XCTAssertTrue(s.nimm(reihe: 1, anzahl: 3)); XCTAssertEqual(s.amZug, 1)
        XCTAssertTrue(s.nimm(reihe: 0, anzahl: 1)); XCTAssertEqual(s.sieger, 1)
        var m = Hoelzchen(reihen: [1], modus: .misere); m.nimm(reihe: 0, anzahl: 1); XCTAssertEqual(m.sieger, 1)
    }
    /// Der perfekte Computer gewinnt als Anziehender oder Nachziehender immer gegen Zufall, wenn die Stellung gewonnen ist.
    func testPerfekterComputerSchlaegtZufall() {
        for modus in Hoelzchen.Modus.allCases {
            var siege = 0, spiele = 0
            for aufbau in Hoelzchen.aufbauten {
                for _ in 0..<40 {
                    var g = SystemRandomNumberGenerator(); var s = Hoelzchen(reihen: aufbau, modus: modus)
                    while s.sieger == nil {
                        if s.amZug == 0 { let z = s.computerZug(fehler: 0, mit: &g)!; s.nimm(reihe: z.reihe, anzahl: z.anzahl) }
                        else { let z = s.computerZug(fehler: 1, mit: &g)!; s.nimm(reihe: z.reihe, anzahl: z.anzahl) }
                    }
                    spiele += 1; if s.sieger == 0 { siege += 1 }
                }
            }
            XCTAssertTrue(Double(siege) / Double(spiele) > 0.8, "\(modus): \(siege)/\(spiele)")
        }
    }
    /// Das schwere Computer-Niveau spielt in jeder Stellung perfekt (gegen vollständige Suche geprüft).
    func testComputerSpieltPerfekt() {
        func gewinnt(_ r: [Int], _ modus: Hoelzchen.Modus, _ memo: inout [[Int]: Bool]) -> Bool {   // Spieler am Zug gewinnt?
            let k = r.sorted()
            if let m = memo[k] { return m }
            if k.reduce(0, +) == 0 { return modus == .misere }      // der Vorgänger nahm das letzte: bei Misere gewinnt der Spieler am Zug
            var ergebnis = false
            outer: for i in k.indices where k[i] > 0 { for n in 1...k[i] { var h = k; h[i] -= n; if !gewinnt(h, modus, &memo) { ergebnis = true; break outer } } }
            memo[k] = ergebnis; return ergebnis
        }
        var g = SystemRandomNumberGenerator()
        for modus in Hoelzchen.Modus.allCases {
            var memo: [[Int]: Bool] = [:]
            for a in 0...4 { for b in 0...4 { for c in 0...4 where a + b + c > 0 {
                let r = [a, b, c]
                guard gewinnt(r, modus, &memo) else { continue }
                let s = Hoelzchen(reihen: r, modus: modus)
                let z = s.computerZug(fehler: 0, mit: &g)!
                var t = s; XCTAssertTrue(t.nimm(reihe: z.reihe, anzahl: z.anzahl))
                if t.sieger == nil { XCTAssertFalse(gewinnt(t.reihen, modus, &memo), "\(modus) \(r) -> \(t.reihen)") }
                else { XCTAssertEqual(t.sieger, 0) }
            } } }
        }
    }

    func testZugZurueckNimmtEigenenZugUndComputerAntwortZurueck() {
        var g = SystemRandomNumberGenerator()
        var s = Hoelzchen(reihen: [1, 3, 5, 7], modus: .normal)
        XCTAssertFalse(s.kannZurueck(zumSpieler: 0))
        let start = s.reihen
        s.nimm(reihe: 3, anzahl: 2)
        let z = s.computerZug(fehler: 0, mit: &g)!; s.nimm(reihe: z.reihe, anzahl: z.anzahl)
        XCTAssertEqual(s.amZug, 0); XCTAssertTrue(s.kannZurueck(zumSpieler: 0))
        XCTAssertTrue(s.zurueck(zumSpieler: 0))
        XCTAssertEqual(s.reihen, start); XCTAssertEqual(s.amZug, 0); XCTAssertNil(s.sieger)
        XCTAssertFalse(s.kannZurueck(zumSpieler: 0), "danach ist der Verlauf leer")
    }
    func testZugZurueckNachSpielendeHebtSiegAuf() {
        var s = Hoelzchen(reihen: [1], modus: .normal)
        s.nimm(reihe: 0, anzahl: 1)
        XCTAssertEqual(s.sieger, 0)
        XCTAssertTrue(s.zurueck(zumSpieler: 0)); XCTAssertNil(s.sieger); XCTAssertEqual(s.reihen, [1])
    }
    func testZuZweitNimmtDerVorgaengerSeinenZugZurueck() {
        var s = Hoelzchen(reihen: [2, 3], modus: .normal)
        s.nimm(reihe: 0, anzahl: 1)      // Spieler 0
        XCTAssertTrue(s.kannZurueck(zumSpieler: 1 - s.amZug))
        s.zurueck(zumSpieler: 1 - s.amZug)
        XCTAssertEqual(s.reihen, [2, 3]); XCTAssertEqual(s.amZug, 0)
    }
    func testSpeichernUndLadenBehaeltVerlaufUndAlteStaendeFunktionieren() throws {
        var s = Hoelzchen(reihen: [3, 4], modus: .misere)
        s.nimm(reihe: 1, anzahl: 2)
        let d = try JSONEncoder().encode(s)
        var g = try JSONDecoder().decode(Hoelzchen.self, from: d)
        XCTAssertTrue(g.kannZurueck(zumSpieler: 0)); g.zurueck(zumSpieler: 0); XCTAssertEqual(g.reihen, [3, 4])
        let alt = #"{"reihen":[1,2],"modus":"normal","amZug":1}"#.data(using: .utf8)!
        let a = try JSONDecoder().decode(Hoelzchen.self, from: alt)
        XCTAssertEqual(a.reihen, [1, 2]); XCTAssertEqual(a.amZug, 1); XCTAssertFalse(a.kannZurueck(zumSpieler: 1))
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class HoelzchenKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = Hoelzchen(reihen: [1, 3, 5], modus: .normal)
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = Hoelzchen(reihen: [1, 3, 5], modus: .normal)
        let k = try kaputt(w, "amZug", 5)
        XCTAssertFalse(k.istKonsistent)
    }
}

final class HoelzchenBeschaedigterVerlauf: XCTestCase {
    func testZurueckMitFalscherReihenzahl() throws {
        var h = Hoelzchen(reihen: [1, 3, 5], modus: .normal)
        h.nimm(reihe: 1, anzahl: 1)
        var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(h)) as! [String: Any]
        d["verlauf"] = [["reihen": [1], "amZug": 0]]
        h = try JSONDecoder().decode(Hoelzchen.self, from: JSONSerialization.data(withJSONObject: d))
        XCTAssertFalse(h.zurueck(zumSpieler: 0))
        XCTAssertEqual(h.reihen.count, 3)
    }
}

final class HoelzchenRegelnZusatzTests: XCTestCase {
    func testNimmLehntNullUndZuVieleUndUngueltigeReiheAb() {
        var s = Hoelzchen(reihen: [2, 3], modus: .normal)
        XCTAssertFalse(s.nimm(reihe: 0, anzahl: 0)); XCTAssertFalse(s.nimm(reihe: 0, anzahl: 3)); XCTAssertFalse(s.nimm(reihe: 2, anzahl: 1)); XCTAssertFalse(s.nimm(reihe: -1, anzahl: 1))
        XCTAssertEqual(s.summe, 5); XCTAssertEqual(s.amZug, 0)
    }
    func testNachSiegSindKeineZuegeMehrErlaubt() {
        var s = Hoelzchen(reihen: [1], modus: .normal)
        s.nimm(reihe: 0, anzahl: 1)
        XCTAssertEqual(s.sieger, 0); XCTAssertFalse(s.nimm(reihe: 0, anzahl: 1))
    }
    func testComputerGewinntAusGewonnenerStellungMitNimSumme() {
        // [1,2,3] hat Nim-Summe 0 (verloren für den Anziehenden); [1,2,4] hat 7 → der Computer muss einen Gewinnzug finden.
        var g = SystemRandomNumberGenerator()
        var s = Hoelzchen(reihen: [1, 2, 4], modus: .normal)
        let z = s.computerZug(fehler: 0, mit: &g)!
        s.nimm(reihe: z.reihe, anzahl: z.anzahl)
        XCTAssertEqual(s.reihen.reduce(0, ^), 0)
    }
    func testMisereEndspielLaesstUngeradeZahlEinzelneStehen() {
        var g = SystemRandomNumberGenerator()
        var s = Hoelzchen(reihen: [1, 1, 3], modus: .misere)
        let z = s.computerZug(fehler: 0, mit: &g)!
        s.nimm(reihe: z.reihe, anzahl: z.anzahl)
        XCTAssertEqual(s.reihen.filter { $0 == 1 }.count % 2, 1)
    }
    func testZurueckNimmtZugUndAntwortZurueck() {
        var s = Hoelzchen(reihen: [3, 3], modus: .normal)
        s.nimm(reihe: 0, anzahl: 1); s.nimm(reihe: 1, anzahl: 2)
        XCTAssertTrue(s.zurueck(zumSpieler: 0))
        XCTAssertEqual(s.reihen, [3, 3]); XCTAssertEqual(s.amZug, 0); XCTAssertFalse(s.kannZurueck(zumSpieler: 0))
    }
    func testAufbautenHabenKeineLeerenReihen() {
        for a in Hoelzchen.aufbauten { XCTAssertTrue(a.allSatisfy { $0 > 0 }); XCTAssertGreaterThan(a.reduce(0, +), 5) }
    }
}
