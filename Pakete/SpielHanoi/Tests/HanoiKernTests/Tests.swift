// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HanoiKern

final class HanoiTests: XCTestCase {
    func testRegeln() {
        var h = Hanoi(scheiben: 3)
        XCTAssertFalse(h.moeglich(von: 1, nach: 0)); XCTAssertTrue(h.ziehe(von: 0, nach: 2))
        XCTAssertFalse(h.ziehe(von: 0, nach: 2)); XCTAssertTrue(h.ziehe(von: 0, nach: 1))
        XCTAssertEqual(h.zuege, 2); XCTAssertEqual(h.minimum, 7)
    }
    func testLoesung() {
        var h = Hanoi(scheiben: 4)
        func los(_ n: Int, _ a: Int, _ b: Int, _ c: Int) { guard n > 0 else { return }; los(n - 1, a, c, b); h.ziehe(von: a, nach: c); los(n - 1, b, a, c) }
        los(4, 0, 1, 2)
        XCTAssertTrue(h.geloest); XCTAssertEqual(h.zuege, 15)
    }
    func testRandfaelle() {
        var h = Hanoi(scheiben: 3)
        XCTAssertFalse(h.moeglich(von: 0, nach: 3)); XCTAssertFalse(h.moeglich(von: -1, nach: 0))
        XCTAssertFalse(h.ziehe(von: 0, nach: 0)); XCTAssertEqual(h.zuege, 0)
        h.ziehe(von: 0, nach: 1)
        XCTAssertFalse(h.ziehe(von: 0, nach: 1), "grosse Scheibe nie auf kleine")
        XCTAssertFalse(h.geloest)
    }
    func testEineScheibe() {
        var h = Hanoi(scheiben: 1)
        XCTAssertEqual(h.minimum, 1); XCTAssertTrue(h.ziehe(von: 0, nach: 2)); XCTAssertTrue(h.geloest)
    }
    func testZurueck() {
        var h = Hanoi(scheiben: 3)
        XCTAssertFalse(h.zurueck()); XCTAssertFalse(h.kannZurueck)
        h.ziehe(von: 0, nach: 2); h.ziehe(von: 0, nach: 1)
        XCTAssertTrue(h.zurueck()); XCTAssertEqual(h.zuege, 1); XCTAssertEqual(h.staebe[0], [3, 2])
        XCTAssertTrue(h.zurueck()); XCTAssertEqual(h, Hanoi(scheiben: 3))
    }
    func testHinweisFuehrtInMinimalenZuegenZumZiel() {
        for n in 1...6 {
            var h = Hanoi(scheiben: n)
            while !h.geloest, let z = h.hinweis() { XCTAssertTrue(h.ziehe(von: z.von, nach: z.nach)); XCTAssertTrue(h.zuege <= h.minimum) }
            XCTAssertTrue(h.geloest); XCTAssertEqual(h.zuege, h.minimum)
        }
    }
    func testHinweisAusZufallsStellungNurLegaleZuege() {
        var g = SystemRandomNumberGenerator(); var h = Hanoi(scheiben: 5)
        for _ in 0..<40 { let a = Int.random(in: 0..<3, using: &g), b = Int.random(in: 0..<3, using: &g); h.ziehe(von: a, nach: b) }
        var n = 0
        while !h.geloest, let z = h.hinweis(), n < 200 { XCTAssertTrue(h.ziehe(von: z.von, nach: z.nach)); n += 1 }
        XCTAssertTrue(h.geloest)
    }
    func testVierStaebeMinimum() {
        XCTAssertEqual(Hanoi.minimum(scheiben: 4, staebe: 4), 9)
        XCTAssertEqual(Hanoi.minimum(scheiben: 6, staebe: 4), 17)
        XCTAssertEqual(Hanoi(scheiben: 5).minimum, 31)
    }
    func testVierStaebeTippLoest() {
        var h = Hanoi(scheiben: 5, staebe: 4); var k = 0
        while !h.geloest, let t = h.hinweis(), k < 40 { XCTAssertTrue(h.ziehe(von: t.von, nach: t.nach)); k += 1 }
        XCTAssertTrue(h.geloest); XCTAssertEqual(h.zuege, h.minimum)
    }
    func testAlterStandLaedtMitDreiStaeben() throws {
        let alt = #"{"scheiben":3,"staebe":[[3,2],[1],[]],"zuege":1,"verlauf":[]}"#.data(using: .utf8)!
        let h = try JSONDecoder().decode(Hanoi.self, from: alt)
        XCTAssertEqual(h.anzahlStaebe, 3)
    }
}

final class HanoiZusatzTests: XCTestCase {
    func testVierStaebeZielIstLetzterStab() {
        var h = Hanoi(scheiben: 2, staebe: 4)
        XCTAssertTrue(h.ziehe(von: 0, nach: 1)); XCTAssertTrue(h.ziehe(von: 0, nach: 3)); XCTAssertTrue(h.ziehe(von: 1, nach: 3))
        XCTAssertTrue(h.geloest)
    }
    func testFrameStewartWerte() {
        XCTAssertEqual(Hanoi.minimum(scheiben: 1, staebe: 4), 1)
        XCTAssertEqual(Hanoi.minimum(scheiben: 3, staebe: 4), 5)
        XCTAssertEqual(Hanoi.minimum(scheiben: 5, staebe: 4), 13)
        XCTAssertEqual(Hanoi.minimum(scheiben: 7, staebe: 3), 127)
    }
    func testGrosseAufKleineUndStabAußerhalbWirdAbgelehnt() {
        var h = Hanoi(scheiben: 3, staebe: 4)
        XCTAssertTrue(h.ziehe(von: 0, nach: 1)); XCTAssertFalse(h.ziehe(von: 0, nach: 1))
        XCTAssertFalse(h.ziehe(von: 0, nach: 4)); XCTAssertFalse(h.ziehe(von: 2, nach: 2))
        XCTAssertEqual(h.zuege, 1)
    }
    func testZurueckBeiVierStaeben() {
        var h = Hanoi(scheiben: 4, staebe: 4)
        h.ziehe(von: 0, nach: 3); h.ziehe(von: 0, nach: 2)
        XCTAssertTrue(h.zurueck()); XCTAssertTrue(h.zurueck()); XCTAssertFalse(h.zurueck())
        XCTAssertEqual(h, Hanoi(scheiben: 4, staebe: 4))
    }
    func testCodableRundlauf() throws {
        var h = Hanoi(scheiben: 5, staebe: 4); h.ziehe(von: 0, nach: 2)
        let d = try JSONEncoder().encode(h)
        let r = try JSONDecoder().decode(Hanoi.self, from: d)
        XCTAssertEqual(r.staebe, h.staebe); XCTAssertEqual(r.anzahlStaebe, 4); XCTAssertEqual(r.zuege, 1)
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class HanoiKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = Hanoi(scheiben: 3)
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = Hanoi(scheiben: 3)
        let k = try kaputt(w, "staebe", [[1], [Int](), [Int]()])
        XCTAssertFalse(k.istKonsistent)
    }
}

final class HanoiBeschaedigterVerlauf: XCTestCase {
    func testZurueckMitKaputtemVerlaufStuerztNichtAb() throws {
        var h = Hanoi(scheiben: 3)
        var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(h)) as! [String: Any]
        d["verlauf"] = [["von": 0, "nach": 2], ["von": 9, "nach": 1]]       // Stab 2 ist leer, Stab 9 gibt es nicht
        h = try JSONDecoder().decode(Hanoi.self, from: JSONSerialization.data(withJSONObject: d))
        XCTAssertFalse(h.zurueck()); XCTAssertFalse(h.zurueck())
        XCTAssertTrue(h.istKonsistent)
    }
}

final class HanoiRegelTests: XCTestCase {
    func testStartstellung() {
        let h = Hanoi(scheiben: 4)
        XCTAssertEqual(h.staebe, [[4, 3, 2, 1], [], []]); XCTAssertEqual(h.zuege, 0); XCTAssertFalse(h.geloest); XCTAssertFalse(h.kannZurueck)
    }
    func testGroessereScheibeNieAufKleinere() {
        var h = Hanoi(scheiben: 3)
        XCTAssertTrue(h.ziehe(von: 0, nach: 1))          // 1 → Stab 2
        XCTAssertFalse(h.ziehe(von: 0, nach: 1), "2 auf 1 verboten")
        XCTAssertTrue(h.ziehe(von: 0, nach: 2))          // 2 → Stab 3
        XCTAssertFalse(h.moeglich(von: 2, nach: 1)); XCTAssertTrue(h.moeglich(von: 1, nach: 2))
    }
    func testUngueltigeStaebeUndLeereStaebe() {
        var h = Hanoi(scheiben: 3)
        XCTAssertFalse(h.ziehe(von: 1, nach: 2), "Stab 2 ist leer")
        XCTAssertFalse(h.ziehe(von: 0, nach: 0)); XCTAssertFalse(h.ziehe(von: 0, nach: 9)); XCTAssertFalse(h.ziehe(von: -1, nach: 1))
        XCTAssertEqual(h.zuege, 0)
    }
    func testKuerzesteLoesungHatZweiHochNMinusEinsZuege() {
        for n in 1...6 { XCTAssertEqual(Hanoi(scheiben: n).minimum, (1 << n) - 1) }
        XCTAssertEqual(Hanoi.minimum(scheiben: 0, staebe: 3), 0)
    }
    func testVierStaebeBrauchenWenigerZuege() {
        XCTAssertEqual(Hanoi.minimum(scheiben: 4, staebe: 4), 9)
        XCTAssertEqual(Hanoi.minimum(scheiben: 5, staebe: 4), 13)
        XCTAssertLessThan(Hanoi.minimum(scheiben: 6, staebe: 4), Hanoi.minimum(scheiben: 6, staebe: 3))
    }
    func testZurueckNimmtDenLetztenZugUndZaehltAb() {
        var h = Hanoi(scheiben: 3)
        h.ziehe(von: 0, nach: 2); h.ziehe(von: 0, nach: 1)
        XCTAssertTrue(h.zurueck()); XCTAssertEqual(h.zuege, 1); XCTAssertEqual(h.staebe[0], [3, 2])
        XCTAssertTrue(h.zurueck()); XCTAssertFalse(h.zurueck()); XCTAssertEqual(h, Hanoi(scheiben: 3))
    }
    func testHinweisFuehrtInOptimalerZugzahlZurLoesung() {
        for n in 2...5 {
            var h = Hanoi(scheiben: n); var z = 0
            while !h.geloest, let (a, b) = h.hinweis(), z < 100 { XCTAssertTrue(h.ziehe(von: a, nach: b)); z += 1 }
            XCTAssertTrue(h.geloest); XCTAssertEqual(z, h.minimum, "\(n) Scheiben")
        }
    }
    func testGeloestGibtKeinenHinweisMehr() {
        var h = Hanoi(scheiben: 1)
        h.ziehe(von: 0, nach: 2)
        XCTAssertTrue(h.geloest); XCTAssertNil(h.hinweis())
    }
    func testVierStaebeHinweisIstOptimal() {
        var h = Hanoi(scheiben: 4, staebe: 4); var z = 0
        while !h.geloest, let (a, b) = h.hinweis(), z < 50 { h.ziehe(von: a, nach: b); z += 1 }
        XCTAssertTrue(h.geloest); XCTAssertEqual(z, 9)
    }
    func testSpielstandMitVerlaufIstCodierbar() throws {
        var h = Hanoi(scheiben: 3)
        h.ziehe(von: 0, nach: 2); h.ziehe(von: 0, nach: 1)
        var neu = try JSONDecoder().decode(Hanoi.self, from: JSONEncoder().encode(h))
        XCTAssertEqual(neu, h)
        XCTAssertTrue(neu.zurueck(), "Der Verlauf überlebt das Speichern")
    }
}
