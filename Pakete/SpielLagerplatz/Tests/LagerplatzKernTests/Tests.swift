// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import LagerplatzKern
final class LagerplatzTests: XCTestCase {
    func testStufenSindLoesbar() {
        var g = SystemRandomNumberGenerator()
        for st in 1...3 { for _ in 0..<6 {
            let l = Lagerplatz(stufe: st, mit: &g)
            XCTAssertFalse(l.geloest); XCTAssertFalse(l.waende.contains(l.spieler)); XCTAssertFalse(l.kisten.contains(l.spieler))
            XCTAssertEqual(l.kisten.count, Lagerplatz.kistenZahl(stufe: st)); XCTAssertEqual(l.ziele.count, l.kisten.count)
            XCTAssertTrue(l.loesbar(), "Stufe \(st) nicht lösbar")
        } }
    }
    func testSchiebenUndZurueck() {
        var g = SystemRandomNumberGenerator(); var l = Lagerplatz(stufe: 1, mit: &g)
        let start = l
        var n = 0
        for _ in 0..<200 { if l.bewege(Richtung.allCases.randomElement(using: &g)!) { n += 1 } }
        XCTAssertTrue(n > 0)
        while l.kannZurueck { l.zurueck() }
        XCTAssertEqual(l, start); XCTAssertEqual(l.schritte, 0)
    }
    func testKisteNichtDurchWandOderKiste() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            var l = Lagerplatz(stufe: 4, mit: &g)
            for _ in 0..<500 { l.bewege(Richtung.allCases.randomElement(using: &g)!)
                XCTAssertTrue(l.kisten.allSatisfy { l.frei($0) }); XCTAssertEqual(l.kisten.count, Lagerplatz.kistenZahl(stufe: 4)); XCTAssertFalse(l.kisten.contains(l.spieler)) }
        }
    }
    func testGrosseStufenWerdenErzeugt() {
        var g = SystemRandomNumberGenerator()
        for st in [6, 10, 20] { let l = Lagerplatz(stufe: st, mit: &g); XCTAssertEqual(l.kisten.count, Lagerplatz.kistenZahl(stufe: st)) }
    }
    func testKeineFestenKistenZuBeginn() {
        var g = SystemRandomNumberGenerator()
        for st in 1...8 { for _ in 0..<10 { XCTAssertTrue(Lagerplatz(stufe: st, mit: &g).festeKisten.isEmpty) } }
    }
    func testHinweiseLoesenKleineStufen() {
        var g = SystemRandomNumberGenerator()
        for st in 1...2 {
            for _ in 0..<4 {
                var l = Lagerplatz(stufe: st, mit: &g); var n = 0
                while !l.geloest, let h = l.hinweis(), n < 400 { XCTAssertTrue(l.bewege(h) || true); n += 1 }
                XCTAssertTrue(l.geloest, "Stufe \(st) mit Hinweisen nicht gelöst")
            }
        }
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class LagerplatzKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = { var g = SystemRandomNumberGenerator(); return Lagerplatz(stufe: 1, mit: &g) }()
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = { var g = SystemRandomNumberGenerator(); return Lagerplatz(stufe: 1, mit: &g) }()
        let k = try kaputt(w, "breite", 1)
        XCTAssertFalse(k.istKonsistent)
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<10 { let t0 = Date(); _ = Lagerplatz(stufe: 1, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Lagerplatz Stufe 1: Ø \(String(format: "%.3f", sum / 10)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<10 { let t0 = Date(); _ = Lagerplatz(stufe: 5, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Lagerplatz Stufe 5: Ø \(String(format: "%.3f", sum / 10)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<10 { let t0 = Date(); _ = Lagerplatz(stufe: 10, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Lagerplatz Stufe 10: Ø \(String(format: "%.3f", sum / 10)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<10 { let t0 = Date(); _ = Lagerplatz(stufe: 15, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Lagerplatz Stufe 15: Ø \(String(format: "%.3f", sum / 10)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<10 { let t0 = Date(); _ = Lagerplatz(stufe: 20, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Lagerplatz Stufe 20: Ø \(String(format: "%.3f", sum / 10)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<5 { let t0 = Date(); _ = { let l = Lagerplatz(stufe: 10, mit: &g); return l.hinweis() }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Lagerplatz Tipp (hinweis) Stufe 10: Ø \(String(format: "%.3f", sum / 5)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}

final class LagerplatzBeschaedigterVerlauf: XCTestCase {
    func testZurueckMitKistenAusserhalbDesLagersWirdVerworfen() throws {
        var g = SystemRandomNumberGenerator()
        var l = Lagerplatz(stufe: 1, mit: &g)
        var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(l)) as! [String: Any]
        d["verlauf"] = [["spieler": ["x": 99, "y": 99], "kisten": [[String: Int]](), "schob": false]]
        l = try JSONDecoder().decode(Lagerplatz.self, from: JSONSerialization.data(withJSONObject: d))
        let vorher = l.kisten
        l.zurueck()
        XCTAssertEqual(l.kisten, vorher); XCTAssertTrue(l.istKonsistent)
    }
}

final class LagerplatzRegelTests: XCTestCase {
    private func p(_ x: Int, _ y: Int) -> LPos { LPos(x, y) }
    /// 5×1-Gang: Spieler links, Kiste in der Mitte, Ziel rechts.
    private func gang() -> Lagerplatz { Lagerplatz(breite: 5, hoehe: 1, ziele: [p(4, 0)], kisten: [p(2, 0)], spieler: p(0, 0)) }

    func testSchiebenBewegtDieKisteUndZaehltSchiebungen() {
        var l = gang()
        XCTAssertTrue(l.bewege(.rechts)); XCTAssertEqual(l.schritte, 1); XCTAssertEqual(l.schiebungen, 0)
        XCTAssertTrue(l.bewege(.rechts)); XCTAssertEqual(l.kisten, [p(3, 0)]); XCTAssertEqual(l.spieler, p(2, 0)); XCTAssertEqual(l.schiebungen, 1)
        XCTAssertFalse(l.geloest)
        XCTAssertTrue(l.bewege(.rechts)); XCTAssertTrue(l.geloest); XCTAssertEqual(l.kistenAufZiel, 1)
    }
    func testWandUndSpielfeldrandBlockieren() {
        var l = Lagerplatz(breite: 3, hoehe: 1, waende: [p(1, 0)], ziele: [p(2, 0)], kisten: [], spieler: p(0, 0))
        XCTAssertFalse(l.bewege(.rechts)); XCTAssertFalse(l.bewege(.links)); XCTAssertFalse(l.bewege(.hoch))
        XCTAssertEqual(l.schritte, 0)
    }
    func testKisteLaesstSichNichtGegenWandOderKisteSchieben() {
        var l = Lagerplatz(breite: 4, hoehe: 1, ziele: [p(3, 0)], kisten: [p(1, 0), p(2, 0)], spieler: p(0, 0))
        XCTAssertFalse(l.bewege(.rechts), "Zwei Kisten hintereinander")
        var m = Lagerplatz(breite: 3, hoehe: 1, ziele: [p(2, 0)], kisten: [p(2, 0)], spieler: p(1, 0))
        XCTAssertFalse(m.bewege(.rechts), "Kiste am Rand")
        XCTAssertTrue(m.geloest)
    }
    func testZurueckStelltSpielerKistenUndZaehlerWiederHer() {
        var l = gang()
        l.bewege(.rechts); l.bewege(.rechts)
        XCTAssertTrue(l.kannZurueck)
        l.zurueck(); XCTAssertEqual(l.kisten, [p(2, 0)]); XCTAssertEqual(l.spieler, p(1, 0)); XCTAssertEqual(l.schiebungen, 0); XCTAssertEqual(l.schritte, 1)
        l.zurueck(); XCTAssertFalse(l.kannZurueck); XCTAssertEqual(l.schritte, 0)
        l.zurueck(); XCTAssertEqual(l.spieler, p(0, 0))
    }
    func testEckenKistenSindFestUndZielKistenNicht() {
        let l = Lagerplatz(breite: 3, hoehe: 3, waende: [p(-1, 0), p(0, -1), p(3, 2), p(2, 3)], ziele: [p(2, 2)], kisten: [p(0, 0), p(2, 2)], spieler: p(1, 1))
        XCTAssertEqual(l.festeKisten, [p(0, 0)], "Im Eck nur fest, wenn nicht am Ziel")
    }
    func testKistenZahlWaechstMitDerStufeBisSechs() {
        XCTAssertEqual((1...14).map { Lagerplatz.kistenZahl(stufe: $0) }, [2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 6, 6, 6, 6])
    }
    func testLoesbarkeitUndHinweisFuehrenZumZiel() {
        var l = gang()
        XCTAssertTrue(l.loesbar())
        var z = 0
        while !l.geloest, let r = l.hinweis(), z < 20 { l.bewege(r); z += 1 }
        XCTAssertTrue(l.geloest); XCTAssertEqual(z, 3, "drei Schritte: rechts, rechts, rechts")
    }
    func testUnloesbareStufeWirdErkannt() {
        let l = Lagerplatz(breite: 3, hoehe: 3, waende: [p(-1, 0), p(0, -1)], ziele: [p(2, 2)], kisten: [p(0, 0)], spieler: p(1, 1))
        XCTAssertFalse(l.loesbar())
    }
    func testGeloestObwohlNochKeinZugErkannt() {
        XCTAssertTrue(Lagerplatz(breite: 2, hoehe: 1, ziele: [p(1, 0)], kisten: [p(1, 0)], spieler: p(0, 0)).geloest)
    }
    func testSpielstandMitVerlaufIstCodierbar() throws {
        var l = gang(); l.bewege(.rechts); l.bewege(.rechts)
        var neu = try JSONDecoder().decode(Lagerplatz.self, from: JSONEncoder().encode(l))
        XCTAssertEqual(neu, l); XCTAssertEqual(neu.schritte, 2)
        neu.zurueck(); XCTAssertEqual(neu.kisten, [p(2, 0)])
    }
}
