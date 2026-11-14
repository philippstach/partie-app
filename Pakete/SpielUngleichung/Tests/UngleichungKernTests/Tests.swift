// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import UngleichungKern
final class UngleichungTests: XCTestCase {
    func testEindeutigUndLoesungGueltig() {
        var g = SystemRandomNumberGenerator()
        for (n, schwer) in [(4, false), (4, true), (5, false), (5, true)] {
            for _ in 0..<1 {
                let p = Ungleichung(n: n, schwer: schwer, mit: &g)
                XCTAssertEqual(Ungleichung.zaehle(n, p.zeichen, p.vorgaben, p.loesung, max: 3), 1, "\(n) \(schwer)")
                for y in 0..<n { XCTAssertEqual(Set((0..<n).map { p.loesung[y * n + $0] }).count, n); XCTAssertEqual(Set((0..<n).map { p.loesung[$0 * n + y] }).count, n) }
                XCTAssertTrue(p.zeichen.allSatisfy { p.loesung[$0.a] < p.loesung[$0.b] })
                XCTAssertFalse(p.geloest); XCTAssertTrue(p.fehler.isEmpty)
            }
        }
    }
    func testLoesenUndFehler() {
        var g = SystemRandomNumberGenerator(); var p = Ungleichung(n: 4, schwer: false, mit: &g)
        for i in 0..<16 { p.setze(i, p.loesung[i]) }
        XCTAssertTrue(p.geloest); XCTAssertTrue(p.fehler.isEmpty)
        let frei = (0..<16).first { !p.vorgaben.contains($0) }!
        p.setze(frei, p.loesung[frei] % 4 + 1)
        XCTAssertFalse(p.geloest)
    }
    func testTipp() {
        var g = SystemRandomNumberGenerator(); var p = Ungleichung(n: 4, schwer: true, mit: &g)
        var n = 0
        while p.tipp(mit: &g) != nil { n += 1 }
        XCTAssertTrue(p.geloest); XCTAssertTrue(n > 0)
    }
    func testGleicherStartwertGleichesRaetsel() {
        var a = TestGenerator(s: 7), b = TestGenerator(s: 7)
        let p = Ungleichung(n: 4, schwer: false, mit: &a), q = Ungleichung(n: 4, schwer: false, mit: &b)
        XCTAssertEqual(p.loesung, q.loesung); XCTAssertEqual(p.vorgaben, q.vorgaben); XCTAssertEqual(p.zeichen, q.zeichen)
    }
}

final class UngleichungQualitaetTests: XCTestCase {
    func testViele_RaetselSindEindeutig() {
        for seed in 1...2 as ClosedRange<UInt64> {
            for (n, schwer) in [(4, false), (4, true), (5, false), (5, true)] {
                var g = TestGenerator(s: seed)
                let p = Ungleichung(n: n, schwer: schwer, mit: &g)
                XCTAssertEqual(Ungleichung.zaehle(n, p.zeichen, p.vorgaben, p.loesung, max: 2), 1, "Seed \(seed) n=\(n) schwer=\(schwer)")
            }
        }
    }
    func testSchwerHatWenigerHilfenAlsLeicht() {
        var leicht = 0, schwer = 0
        for seed in 1...4 as ClosedRange<UInt64> {
            var a = TestGenerator(s: seed), b = TestGenerator(s: seed)
            let l = Ungleichung(n: 5, schwer: false, mit: &a), h = Ungleichung(n: 5, schwer: true, mit: &b)
            leicht += l.vorgaben.count; schwer += h.vorgaben.count
        }
        XCTAssertGreaterThan(leicht, schwer)
    }
    func testFalscheZeichenFehlerUndGeloestErstBeiRichtigerLoesung() {
        var g = TestGenerator(s: 3); var p = Ungleichung(n: 4, schwer: true, mit: &g)
        guard let z = p.zeichen.first else { return }
        // gegen das Zeichen verstoßen
        if !p.vorgaben.contains(z.a) && !p.vorgaben.contains(z.b) {
            p.setze(z.a, 4); p.setze(z.b, 1)
            XCTAssertTrue(p.fehler.contains(z.a) && p.fehler.contains(z.b))
        }
        XCTAssertFalse(p.geloest)
    }
}

struct TestGenerator: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s &+= 0x9E3779B97F4A7C15; var z = s; z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9; z = (z ^ (z >> 27)) &* 0x94D049BB133111EB; return z ^ (z >> 31) }
}

final class UngleichungZurueckTests: XCTestCase {
    func testZugZurueckNimmtEintragUndTippZurueck() {
        var g = TestGenerator(s: 5); var p = Ungleichung(n: 4, schwer: true, mit: &g)
        XCTAssertFalse(p.kannZurueck); XCTAssertFalse(p.zurueck())
        let start = p.werte
        let frei = (0..<16).first { !p.vorgaben.contains($0) }!
        p.setze(frei, 2); p.setze(frei, 3)
        XCTAssertEqual(p.werte[frei], 3)
        XCTAssertTrue(p.zurueck()); XCTAssertEqual(p.werte[frei], 2)
        XCTAssertTrue(p.zurueck()); XCTAssertEqual(p.werte, start)
        var h = SystemRandomNumberGenerator()
        XCTAssertNotNil(p.tipp(mit: &h)); XCTAssertNotEqual(p.werte, start)
        XCTAssertTrue(p.zurueck()); XCTAssertEqual(p.werte, start)
    }
    func testGleicherWertUndVorgabenErzeugenKeinenVerlauf() {
        var g = TestGenerator(s: 6); var p = Ungleichung(n: 4, schwer: false, mit: &g)
        if let v = p.vorgaben.first { p.setze(v, 1); XCTAssertFalse(p.kannZurueck) }
        let frei = (0..<16).first { !p.vorgaben.contains($0) }!
        p.setze(frei, 0); XCTAssertFalse(p.kannZurueck, "leer auf leer ist kein Zug")
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class UngleichungKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = { var g = SystemRandomNumberGenerator(); return Ungleichung(n: 4, schwer: false, mit: &g) }()
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = { var g = SystemRandomNumberGenerator(); return Ungleichung(n: 4, schwer: false, mit: &g) }()
        let k = try kaputt(w, "werte", [1])
        XCTAssertFalse(k.istKonsistent)
    }
}

final class SchwierigkeitMessung: XCTestCase {
    func testStufen() {
        var g = SystemRandomNumberGenerator()
        for n in [4, 5, 6] { for schwer in [false, true] {
            var v = 0.0, z = 0.0, zeit = 0.0
            let m = 5
            for _ in 0..<m { let t0 = Date(); let u = Ungleichung(n: n, schwer: schwer, mit: &g); zeit += Date().timeIntervalSince(t0); v += Double(u.vorgaben.count); z += Double(u.zeichen.count) }
            print("MESS Ungleichung \(n)x\(n) \(schwer ? "schwer" : "Starthilfe"): Vorgaben Ø \(String(format: "%.1f", v / Double(m))) von \(n * n), Zeichen Ø \(String(format: "%.1f", z / Double(m))), Erzeugung Ø \(String(format: "%.2f", zeit / Double(m))) s")
        } }
    }
}

final class EindeutigkeitTests: XCTestCase {
    func testRaetselBleibenEindeutigTrotzSuchgrenze() {
        var g = SystemRandomNumberGenerator()
        for (n, schwer) in [(4, false), (4, true), (5, false), (5, true), (6, true)] {
            for _ in 0..<(n == 6 ? 2 : 6) {
                let u = Ungleichung(n: n, schwer: schwer, mit: &g)
                let anzahl = Ungleichung.zaehle(n, u.zeichen, u.vorgaben, u.loesung, max: 2, knotenGrenze: 50_000_000)
                XCTAssertEqual(anzahl, 1, "\(n)x\(n) schwer=\(schwer) muss genau eine Lösung haben")
            }
        }
    }
    func testSechsMalSechsWirdInEndlicherZeitErzeugt() {
        var g = SystemRandomNumberGenerator()
        let t = Date()
        _ = Ungleichung(n: 6, schwer: false, mit: &g)
        XCTAssertLessThan(Date().timeIntervalSince(t), 60)    // Debug-Build; im Release dauert es Bruchteile einer Sekunde
    }
}

final class UngleichungRandfaelle: XCTestCase {
    func testStandOhneVorgabenWertenIstNichtKonsistent() throws {
        var g = SystemRandomNumberGenerator()
        let u = Ungleichung(n: 4, schwer: false, mit: &g)
        XCTAssertFalse(u.vorgaben.isEmpty)
        let k = try kaputt(u, "werte", [Int](repeating: 0, count: 16))
        XCTAssertFalse(k.istKonsistent, "leere Vorgabefelder sind nicht änderbar, das Rätsel wäre unlösbar")
    }
    func testZurueckNachDemLoesenHebtGeloestAufUndLoestNeuAus() {
        var g = SystemRandomNumberGenerator()
        var u = Ungleichung(n: 4, schwer: false, mit: &g)
        var k = 0
        while !u.geloest, let _ = u.tipp(mit: &g), k < 30 { k += 1 }
        XCTAssertTrue(u.geloest)
        XCTAssertTrue(u.zurueck()); XCTAssertFalse(u.geloest)
    }
}

final class UngleichungIndexSchutz: XCTestCase {
    func testUngueltigesFeldIstWirkungslos() {
        var g = SystemRandomNumberGenerator()
        var u = Ungleichung(n: 4, schwer: false, mit: &g)
        let vorher = u.werte
        u.setze(999, 1); u.setze(-1, 1)
        XCTAssertEqual(u.werte, vorher)
    }
}

final class UngleichungBeschaedigterVerlauf: XCTestCase {
    func testZurueckMitFalschGrossemVerlauf() throws {
        var g = SystemRandomNumberGenerator()
        var u = Ungleichung(n: 4, schwer: false, mit: &g)
        var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(u)) as! [String: Any]
        d["verlauf"] = [[1, 2]]
        u = try JSONDecoder().decode(Ungleichung.self, from: JSONSerialization.data(withJSONObject: d))
        XCTAssertFalse(u.zurueck()); XCTAssertTrue(u.istKonsistent)
    }
}

final class ErzeugungsZeitMax: XCTestCase {
    func testSchwerstesMax() {
        var g = SystemRandomNumberGenerator()
        for (n, s) in [(5, true), (6, true), (6, false), (7, true)] {
            var mx = 0.0, sum = 0.0
            let m = 30
            for _ in 0..<m { let t = Date(); _ = Ungleichung(n: n, schwer: s, mit: &g); let d = Date().timeIntervalSince(t); mx = max(mx, d); sum += d }
            print("ZEIT Ungleichung \(n)x\(n) \(s ? "schwer" : "Start"): Ø \(String(format: "%.3f", sum / Double(m))) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}
