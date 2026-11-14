// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import FarbflutKern
final class FarbflutTests: XCTestCase {
    func testStufenSindLoesbarMitGierigerLoesung() {
        var g = SystemRandomNumberGenerator()
        for (n, f) in [(8, 4), (12, 6), (14, 6)] {
            for _ in 0..<20 {
                var s = Farbflut(groesse: n, farben: f, luft: 0, mit: &g)
                XCTAssertFalse(s.geloest)
                while !s.vorbei { s.zug(s.besteFarbeGierig()) }
                XCTAssertTrue(s.geloest, "\(n)x\(n) mit \(f) Farben nicht gelöst in \(s.limit)")
            }
        }
    }
    /// Blatt 22 (Schritt 2): Das Feld vom Anfang bleibt bis zum Ende erhalten; ohne Zug gibt es keins. Nichts Neues gespeichert, alte Stände laden wie vorher.
    func testAnfangFeld() throws {
        var g = SystemRandomNumberGenerator()
        var s = Farbflut(groesse: 8, farben: 4, luft: 6, mit: &g)
        XCTAssertNil(s.anfang)
        let start = s.feld
        while !s.vorbei { s.zug(s.besteFarbeGierig()) }
        XCTAssertEqual(s.anfang, start)
        let alt = try JSONDecoder().decode(Farbflut.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(alt.anfang, start)
    }
    /// RT-004: Ohne gespeicherte Stufe gilt Normal (wie im Blatt angezeigt), nicht Leicht.
    func testStandardStufeIstNormal() {
        let d = UserDefaults(suiteName: "farbflut.test.stufe")!
        d.removePersistentDomain(forName: "farbflut.test.stufe")
        XCTAssertEqual(FarbflutStufenWahl.gespeichert("k", d), 1)
        d.set(0, forKey: "k"); XCTAssertEqual(FarbflutStufenWahl.gespeichert("k", d), 0)
        d.set(2, forKey: "k"); XCTAssertEqual(FarbflutStufenWahl.gespeichert("k", d), 2)
    }
    func testZugUndZurueck() {
        var g = SystemRandomNumberGenerator(); var s = Farbflut(groesse: 8, farben: 5, luft: 10, mit: &g)
        let start = s
        s.zug((s.aktuelleFarbe + 1) % 5); XCTAssertEqual(s.zuege, 1); s.zurueck(); XCTAssertEqual(s, start)
        XCTAssertFalse(s.zug(s.aktuelleFarbe))
    }
    func testFlutWaechst() {
        var g = SystemRandomNumberGenerator(); var s = Farbflut(groesse: 10, farben: 5, luft: 20, mit: &g)
        var letzte = s.flut.count
        for _ in 0..<6 { s.zug(s.besteFarbeGierig()); XCTAssertGreaterThanOrEqual(s.flut.count, letzte); letzte = s.flut.count }
    }
    func testGleicherStartwertGleichesFeld() {
        var a = TestGenerator(s: 42), b = TestGenerator(s: 42)
        XCTAssertEqual(Farbflut(groesse: 10, farben: 6, luft: 3, mit: &a), Farbflut(groesse: 10, farben: 6, luft: 3, mit: &b))
        XCTAssertEqual(Farbflut(groesse: 10, farben: 6, luft: 3, mit: &a).limit, Farbflut(groesse: 10, farben: 6, luft: 3, mit: &b).limit)
    }
}

struct TestGenerator: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s &+= 0x9E3779B97F4A7C15; var z = s; z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9; z = (z ^ (z >> 27)) &* 0x94D049BB133111EB; return z ^ (z >> 31) }
}

final class FarbflutZusatzTests: XCTestCase {
    func testStufeIstImmerMitGierigerLoesungLoesbar() {
        var g = SystemRandomNumberGenerator()
        for (n, farben) in [(6, 4), (8, 5), (10, 6)] {
            for _ in 0..<10 {
                var f = Farbflut(groesse: n, farben: farben, luft: 0, mit: &g)
                var k = 0
                while !f.geloest, !f.vorbei, k < 500 { XCTAssertTrue(f.zug(f.besteFarbeGierig())); k += 1 }
                XCTAssertTrue(f.geloest, "\(n)x\(n)/\(farben)")
            }
        }
    }
    func testZugMitAktuellerFarbeOderUngueltigerFarbeZaehltNicht() {
        var g = SystemRandomNumberGenerator()
        var f = Farbflut(groesse: 6, farben: 4, luft: 5, mit: &g)
        XCTAssertFalse(f.zug(f.aktuelleFarbe)); XCTAssertFalse(f.zug(-1)); XCTAssertFalse(f.zug(9))
        XCTAssertEqual(f.zuege, 0)
    }
    func testZurueckStelltFeldWiederHer() {
        var g = SystemRandomNumberGenerator()
        var f = Farbflut(groesse: 6, farben: 4, luft: 5, mit: &g)
        let vorher = f.feld
        let farbe = (f.aktuelleFarbe + 1) % 4
        XCTAssertTrue(f.zug(farbe)); XCTAssertTrue(f.kannZurueck)
        f.zurueck()
        XCTAssertEqual(f.feld, vorher); XCTAssertEqual(f.zuege, 0); XCTAssertFalse(f.kannZurueck)
    }
    func testFlutWaechstMitJedemZugMonoton() {
        var g = SystemRandomNumberGenerator()
        var f = Farbflut(groesse: 8, farben: 5, luft: 20, mit: &g)
        var letzte = f.flut.count
        for _ in 0..<10 where !f.geloest { f.zug(f.besteFarbeGierig()); XCTAssertGreaterThanOrEqual(f.flut.count, letzte); letzte = f.flut.count }
    }
    func testNachLimitIstVorbei() {
        var g = SystemRandomNumberGenerator()
        var f = Farbflut(groesse: 8, farben: 6, luft: 0, mit: &g)
        var k = 0
        // bewusst schlechte Züge: immer die nächste Farbe nach der aktuellen
        while !f.vorbei, k < 200 { f.zug((f.aktuelleFarbe + 1) % 6); k += 1 }
        XCTAssertTrue(f.vorbei); XCTAssertEqual(f.verbleibend <= 0 || f.geloest, true)
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class FarbflutKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = { var g = SystemRandomNumberGenerator(); return Farbflut(groesse: 6, farben: 4, luft: 5, mit: &g) }()
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = { var g = SystemRandomNumberGenerator(); return Farbflut(groesse: 6, farben: 4, luft: 5, mit: &g) }()
        let k = try kaputt(w, "feld", [0])
        XCTAssertFalse(k.istKonsistent)
    }
}

final class SchwierigkeitMessung: XCTestCase {
    func testStufen() {
        var g = SystemRandomNumberGenerator()
        for (name, gr, fa, luft) in [("leicht", 8, 4, 6), ("normal", 12, 6, 5), ("schwer", 14, 6, 2)] {
            var limit = 0.0, gierig = 0.0
            for _ in 0..<40 { let f = Farbflut(groesse: gr, farben: fa, luft: luft, mit: &g); limit += Double(f.limit); gierig += Double(f.limit - luft) }
            print("MESS Farbflut \(name): \(gr)x\(gr), \(fa) Farben, Zuglimit Ø \(String(format: "%.1f", limit / 40)), gierige Lösung Ø \(String(format: "%.1f", gierig / 40)), Luft \(luft)")
        }
    }
}

final class FarbflutLimitTests: XCTestCase {
    func testLimitIstGierigePlusLuftUndRealistisch() {
        var g = SystemRandomNumberGenerator()
        for (n, farben, luft) in [(8, 4, 6), (12, 6, 5), (14, 6, 2)] {
            for _ in 0..<10 {
                let f = Farbflut(groesse: n, farben: farben, luft: luft, mit: &g)
                XCTAssertLessThan(f.limit, 60, "Zuglimit muss aus der gierigen Lösung stammen, nicht aus der Obergrenze der Suche")
                var k = f; var z = 0
                while !k.geloest, !k.vorbei, z < 100 { k.zug(k.besteFarbeGierig()); z += 1 }
                XCTAssertTrue(k.geloest); XCTAssertEqual(f.limit, z + luft)
            }
        }
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Farbflut(groesse: 8, farben: 4, luft: 2, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Farbflut 8x8: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Farbflut(groesse: 12, farben: 6, luft: 2, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Farbflut 12x12: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Farbflut(groesse: 14, farben: 6, luft: 2, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Farbflut 14x14: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}

final class FarbflutBeschaedigterVerlauf: XCTestCase {
    func testZurueckMitFalschGrossemVerlaufBeschaedigtDasFeldNicht() throws {
        var g = SystemRandomNumberGenerator()
        var f = Farbflut(groesse: 6, farben: 4, luft: 5, mit: &g)
        var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(f)) as! [String: Any]
        d["verlauf"] = [[0, 1]]
        f = try JSONDecoder().decode(Farbflut.self, from: JSONSerialization.data(withJSONObject: d))
        let vorher = f.feld
        f.zurueck()
        XCTAssertEqual(f.feld, vorher); XCTAssertTrue(f.istKonsistent)
    }
}

final class FarbflutSperreNachEnde: XCTestCase {
    /// Früher ließ sich nach „keine Züge mehr“ beliebig oft zurücknehmen.
    func testNachVerlorenerPartieLaesstSichNichtsZuruecknehmen() {
        var g = SystemRandomNumberGenerator()
        var verloren: Farbflut?
        for _ in 0..<50 where verloren == nil {
            var f = Farbflut(groesse: 10, farben: 6, luft: 0, mit: &g); var k = 0
            while !f.vorbei, k < 300 { f.zug((f.aktuelleFarbe + 1) % 6); k += 1 }   // bewusst schlechte Züge
            if !f.geloest { verloren = f }
        }
        guard var f = verloren else { return XCTFail("keine verlorene Partie erzeugt") }
        XCTAssertTrue(f.vorbei); XCTAssertEqual(f.verbleibend, 0)
        XCTAssertFalse(f.kannZurueck)
        let feld = f.feld, zuege = f.zuege
        f.zurueck(); f.zurueck()
        XCTAssertEqual(f.feld, feld); XCTAssertEqual(f.zuege, zuege); XCTAssertTrue(f.vorbei)
        XCTAssertFalse(f.zug((f.aktuelleFarbe + 1) % 6), "nach dem Ende auch kein weiterer Zug")
    }
    func testNachGeloesterPartieLaesstSichNichtsZuruecknehmen() {
        var g = SystemRandomNumberGenerator()
        var f = Farbflut(groesse: 6, farben: 4, luft: 5, mit: &g); var k = 0
        while !f.geloest, k < 200 { f.zug(f.besteFarbeGierig()); k += 1 }
        XCTAssertTrue(f.geloest); XCTAssertFalse(f.kannZurueck)
        let feld = f.feld; f.zurueck(); XCTAssertEqual(f.feld, feld)
    }
    func testWaehrendDerPartieBleibtZuruecknehmenMoeglich() {
        var g = SystemRandomNumberGenerator()
        var f = Farbflut(groesse: 12, farben: 6, luft: 5, mit: &g)
        let vorher = f.feld
        XCTAssertTrue(f.zug((f.aktuelleFarbe + 1) % 6)); XCTAssertTrue(f.kannZurueck)
        f.zurueck(); XCTAssertEqual(f.feld, vorher)
    }
}
