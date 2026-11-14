// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import BrueckenKern

final class BrueckenTests: XCTestCase {
    func testGenerierteLoesungIstGueltig() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<40 {
            var b = Bruecken.zufaellig(mit: &g)
            XCTAssertTrue(b.inseln.count >= 7); XCTAssertFalse(b.geloest)
            b.loesen(); XCTAssertTrue(b.geloest)
        }
    }
    func testUmschaltenUndKreuzung() {
        let inseln = [Insel(x: 0, y: 1, n: 0), Insel(x: 4, y: 1, n: 0), Insel(x: 2, y: 0, n: 0), Insel(x: 2, y: 3, n: 0)]
        var b = Bruecken(inseln: inseln, groesse: 5, loesung: [:])
        XCTAssertTrue(b.umschalten(0, 1)); XCTAssertEqual(b.bruecken[.init(0, 1)], 1)
        XCTAssertFalse(b.umschalten(2, 3))          // kreuzt die waagrechte Brücke
        XCTAssertFalse(b.umschalten(0, 2))          // nicht in einer Linie
        XCTAssertTrue(b.umschalten(0, 1)); XCTAssertEqual(b.bruecken[.init(0, 1)], 2)
        XCTAssertTrue(b.umschalten(0, 1)); XCTAssertNil(b.bruecken[.init(0, 1)])
        XCTAssertTrue(b.umschalten(2, 3))
    }
    func testNachbarUeberspringtKeineInsel() {
        let inseln = [Insel(x: 0, y: 0, n: 0), Insel(x: 2, y: 0, n: 0), Insel(x: 4, y: 0, n: 0)]
        var b = Bruecken(inseln: inseln, groesse: 5, loesung: [:])
        XCTAssertEqual(b.nachbar(von: 0, dx: 1, dy: 0), 1); XCTAssertNil(b.nachbar(von: 0, dx: -1, dy: 0))
        XCTAssertFalse(b.umschalten(0, 2), "Insel dazwischen")
        XCTAssertFalse(b.umschalten(1, 1))
    }
    func testZusammenhangPflicht() {
        let inseln = [Insel(x: 0, y: 0, n: 1), Insel(x: 2, y: 0, n: 1), Insel(x: 0, y: 3, n: 1), Insel(x: 2, y: 3, n: 1)]
        var b = Bruecken(inseln: inseln, groesse: 4, loesung: [:])
        b.umschalten(0, 1); b.umschalten(2, 3)
        XCTAssertTrue(b.zahlenErfuellt); XCTAssertFalse(b.verbunden); XCTAssertFalse(b.geloest, "zwei getrennte Gruppen")
    }
    func testDoppelbrueckeZaehltZweifach() {
        let inseln = [Insel(x: 0, y: 0, n: 2), Insel(x: 3, y: 0, n: 2)]
        var b = Bruecken(inseln: inseln, groesse: 4, loesung: [:])
        b.umschalten(0, 1); XCTAssertEqual(b.grad(0), 1); b.umschalten(0, 1)
        XCTAssertEqual(b.grad(0), 2); XCTAssertTrue(b.geloest)
    }
    func testTippFuehrtZurLoesung() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<10 {
            var b = Bruecken.zufaellig(mit: &g)
            if let p = b.loesung.keys.first { _ = p }
            var n = 0
            while b.tipp() != nil && n < 100 { n += 1 }
            XCTAssertTrue(b.geloest); XCTAssertEqual(b.bruecken, b.loesung)
        }
    }
}

final class StufenTests: XCTestCase {
    func testStufenErzeugen() {
        var g = SystemRandomNumberGenerator()
        for (gr, n) in [(7, 8), (9, 13), (11, 20)] {
            let t = Date()
            for _ in 0..<5 { let b = Bruecken.zufaellig(groesse: gr, inseln: n, mit: &g); XCTAssertEqual(b.groesse, gr); XCTAssertGreaterThanOrEqual(b.inseln.count, n - 3) }
            print("ZEIT \(gr)/\(n): \(Date().timeIntervalSince(t))  inseln=\(Bruecken.zufaellig(groesse: gr, inseln: n, mit: &g).inseln.count)")
        }
    }
}

final class BrueckenZusatzTests: XCTestCase {
    func testStufenErzeugenLoesbareRaetsel() {
        var g = SystemRandomNumberGenerator()
        for (gr, n) in [(7, 8), (7, 10), (9, 14), (11, 20)] {
            for _ in 0..<5 {
                var b = Bruecken.zufaellig(groesse: gr, inseln: n, mit: &g)
                XCTAssertEqual(b.groesse, gr); XCTAssertFalse(b.geloest)
                b.loesen(); XCTAssertTrue(b.geloest, "\(gr)/\(n)")
            }
        }
    }
    func testInselnLiegenImFeldUndSindEindeutigePlaetze() {
        var g = SystemRandomNumberGenerator()
        let b = Bruecken.zufaellig(groesse: 9, inseln: 14, mit: &g)
        XCTAssertTrue(b.inseln.allSatisfy { (0..<9).contains($0.x) && (0..<9).contains($0.y) && $0.n >= 1 && $0.n <= 8 })
        XCTAssertEqual(Set(b.inseln.map { $0.y * 9 + $0.x }).count, b.inseln.count)
    }
    func testCodableRundlauf() throws {
        var g = SystemRandomNumberGenerator()
        var b = Bruecken.zufaellig(mit: &g); _ = b.tipp()
        let d = try JSONEncoder().encode(b)
        XCTAssertEqual(try JSONDecoder().decode(Bruecken.self, from: d), b)
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class BrueckenKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = { var g = SystemRandomNumberGenerator(); return Bruecken.zufaellig(mit: &g) }()
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = { var g = SystemRandomNumberGenerator(); return Bruecken.zufaellig(mit: &g) }()
        let k = try kaputt(w, "groesse", 1)
        XCTAssertFalse(k.istKonsistent)
    }
}

final class SchwierigkeitMessung: XCTestCase {
    func testStufen() {
        var g = SystemRandomNumberGenerator()
        for (i, (gr, n)) in [(7, 8), (7, 10), (9, 14), (11, 20)].enumerated() {
            var inseln = 0.0, bruecken = 0.0, mehrfach = 0.0
            for _ in 0..<30 { let b = Bruecken.zufaellig(groesse: gr, inseln: n, mit: &g); inseln += Double(b.inseln.count); bruecken += Double(b.loesung.values.reduce(0, +)); mehrfach += Double(b.loesung.values.filter { $0 == 2 }.count) }
            print("MESS Bruecken Stufe \(i) (\(gr)x\(gr)): Inseln Ø \(String(format: "%.1f", inseln / 30)), Brücken Ø \(String(format: "%.1f", bruecken / 30)), Doppelbrücken Ø \(String(format: "%.1f", mehrfach / 30))")
        }
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Bruecken.zufaellig(groesse: 7, inseln: 8, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Bruecken 7x7/8: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Bruecken.zufaellig(groesse: 7, inseln: 10, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Bruecken 7x7/10: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Bruecken.zufaellig(groesse: 9, inseln: 14, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Bruecken 9x9/14: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Bruecken.zufaellig(groesse: 11, inseln: 20, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Bruecken 11x11/20: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}

final class BrueckenIndexSchutz: XCTestCase {
    func testUngueltigeInselnWerdenAbgelehnt() {
        var g = SystemRandomNumberGenerator()
        var b = Bruecken.zufaellig(mit: &g)
        XCTAssertFalse(b.umschalten(0, 999)); XCTAssertFalse(b.umschalten(-1, 0))
    }
}

final class ErzeugungsZeitSchwanz: XCTestCase {
    func testSchwanz() {
        var g = SystemRandomNumberGenerator()
        var zeiten: [Double] = []
        for _ in 0..<300 { let t = Date(); _ = Bruecken.zufaellig(groesse: 11, inseln: 20, mit: &g); zeiten.append(Date().timeIntervalSince(t)) }
        zeiten.sort()
        print("ZEIT Bruecken 11x11/20: Median \(String(format: "%.3f", zeiten[zeiten.count / 2])) s, 95% \(String(format: "%.3f", zeiten[zeiten.count * 95 / 100])) s, max \(String(format: "%.3f", zeiten.last!)) s")
    }
}

final class BrueckenEindeutigkeit: XCTestCase {
    func testErzeugteRaetselHabenMeistensGenauEineLoesung() {
        var g = SystemRandomNumberGenerator()
        for (gr, n) in [(7, 8), (7, 10), (9, 14)] {
            var eindeutig = 0, keine = 0
            for _ in 0..<40 {
                let b = Bruecken.zufaellig(groesse: gr, inseln: n, mit: &g)
                let c = b.anzahlLoesungen(grenze: 2)
                if c == 1 { eindeutig += 1 }; if c == 0 { keine += 1 }
            }
            XCTAssertEqual(keine, 0, "jedes Rätsel muss lösbar sein")
            XCTAssertGreaterThanOrEqual(eindeutig, 36, "\(gr)x\(gr)/\(n): nur \(eindeutig)/40 eindeutig")
        }
    }
    func testSolverFindetBekannteMehrdeutigkeitUndEindeutigkeit() {
        // Zwei Inseln mit je 1: genau eine Brücke, eindeutig.
        let b = Bruecken(inseln: [.init(x: 0, y: 0, n: 1), .init(x: 2, y: 0, n: 1)], groesse: 3, loesung: [.init(0, 1): 1])
        XCTAssertEqual(b.anzahlLoesungen(grenze: 2), 1)
        // Zwei Inseln mit je 2: genau eine Doppelbrücke.
        let c = Bruecken(inseln: [.init(x: 0, y: 0, n: 2), .init(x: 2, y: 0, n: 2)], groesse: 3, loesung: [.init(0, 1): 2])
        XCTAssertEqual(c.anzahlLoesungen(grenze: 2), 1)
    }
}
