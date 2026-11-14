// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import NonogrammKern

final class NonogrammTests: XCTestCase {
    func testHinweiseUndLoesen() {
        let l = [true, true, false, true, false,
                 false, false, false, false, false,
                 true, false, true, true, true,
                 false, false, false, false, false,
                 true, true, true, true, true]
        var n = Nonogramm(loesung: l, n: 5)
        XCTAssertEqual(n.zeilenHinweise[0], [2, 1]); XCTAssertEqual(n.zeilenHinweise[1], [0]); XCTAssertEqual(n.zeilenHinweise[2], [1, 3])
        XCTAssertEqual(n.spaltenHinweise[0], [1, 1, 1]); XCTAssertEqual(n.spaltenHinweise[4], [1, 1])
        XCTAssertFalse(n.geloest)
        for i in l.indices where l[i] { n.tippe(i) }
        XCTAssertTrue(n.geloest); XCTAssertEqual(n.fehler, 0)
        n.tippe(1); XCTAssertFalse(n.geloest)
    }
    func testMarkieren() { var n = Nonogramm.zufaellig(n: 5, mit: &SystemRandomNumberGenerator.shared); n.markiere(3); XCTAssertEqual(n.stand[3], .markiert); n.tippe(3); XCTAssertEqual(n.stand[3], .gefuellt) }
    func testMarkierteZaehlenNichtAlsGefuellt() {
        var n = Nonogramm(loesung: [true, false, false, true], n: 2)
        n.markiere(0); n.markiere(3)
        XCTAssertFalse(n.geloest); XCTAssertEqual(n.fehler, 0)
        n.tippe(0); n.tippe(3); XCTAssertTrue(n.geloest)
    }
    func testFehlerUndLeereZeile() {
        var n = Nonogramm(loesung: [false, false, false, true], n: 2)
        XCTAssertEqual(n.zeilenHinweise[0], [0])
        n.tippe(0); XCTAssertEqual(n.fehler, 1); XCTAssertFalse(n.geloest)
        n.tippe(0); XCTAssertEqual(n.fehler, 0)
    }
    func testZufaelligEnthaeltImmerFelder() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<50 { XCTAssertTrue(Nonogramm.zufaellig(n: 5, dichte: 0, mit: &g).loesung.contains(true)) }
    }
    func testTippFuehrtZurLoesung() {
        var g = SystemRandomNumberGenerator()
        var p = Nonogramm.zufaellig(n: 6, mit: &g)
        for i in 0..<36 where i % 3 == 0 { p.tippe(i) }
        var n = 0
        while p.tipp(mit: &g) != nil { n += 1 }
        XCTAssertTrue(p.geloest); XCTAssertTrue(n <= 36)
    }
}
extension SystemRandomNumberGenerator { nonisolated(unsafe) static var shared = SystemRandomNumberGenerator() }

final class NonogrammLogikTests: XCTestCase {
    func testBekannteRaetselLogischLoesbar() {
        // Kreuz: Hinweise bestimmen es eindeutig
        let kreuz = [false, false, true, false, false,
                     false, false, true, false, false,
                     true, true, true, true, true,
                     false, false, true, false, false,
                     false, false, true, false, false]
        XCTAssertTrue(Nonogramm(loesung: kreuz, n: 5).logischLoesbar)
        // Zwei Lösungen (Schachbrett-Ecke): nicht eindeutig
        let mehrdeutig = [true, false, false, true]
        XCTAssertFalse(Nonogramm(loesung: mehrdeutig, n: 2).logischLoesbar)
    }
    func testZufaelligeRaetselSindMeistLogischLoesbar() {
        var g = SystemRandomNumberGenerator()
        for n in [5, 6, 8, 10] {
            var gut = 0
            for _ in 0..<10 where Nonogramm.zufaellig(n: n, mit: &g).logischLoesbar { gut += 1 }
            XCTAssertEqual(gut, 10, "n=\(n): nur \(gut)/10 ohne Raten lösbar")
        }
    }
}

final class GrosseRaetselTests: XCTestCase {
    func testGroessen12Und15() {
        var g = SystemRandomNumberGenerator()
        for n in [12, 15] {
            let t = Date()
            let p = Nonogramm.zufaellig(n: n, mit: &g)
            XCTAssertEqual(p.n, n)
            print("ZEIT n=\(n): \(Date().timeIntervalSince(t))")
        }
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class NonogrammKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = { var g = SystemRandomNumberGenerator(); return Nonogramm.zufaellig(n: 5, mit: &g) }()
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = { var g = SystemRandomNumberGenerator(); return Nonogramm.zufaellig(n: 5, mit: &g) }()
        let k = try kaputt(w, "stand", [Int]())
        XCTAssertFalse(k.istKonsistent)
    }
}

final class SchwierigkeitMessung: XCTestCase {
    func testStufen() {
        var g = SystemRandomNumberGenerator()
        for n in [5, 8, 10, 12, 15] {
            var dichte = 0.0, logisch = 0, hinweise = 0.0
            for _ in 0..<20 {
                let p = Nonogramm.zufaellig(n: n, mit: &g)
                dichte += Double(p.loesung.filter { $0 }.count) / Double(n * n)
                if p.logischLoesbar { logisch += 1 }
                hinweise += Double(p.zeilenHinweise.map(\.count).reduce(0, +) + p.spaltenHinweise.map(\.count).reduce(0, +)) / Double(2 * n)
            }
            print("MESS Nonogramm \(n)x\(n): gefüllt Ø \(String(format: "%.0f", dichte / 20 * 100)) %, logisch lösbar \(logisch)/20, Hinweiszahlen je Linie Ø \(String(format: "%.1f", hinweise / 20))")
        }
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Nonogramm.zufaellig(n: 5, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Nonogramm 5x5: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Nonogramm.zufaellig(n: 8, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Nonogramm 8x8: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Nonogramm.zufaellig(n: 10, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Nonogramm 10x10: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Nonogramm.zufaellig(n: 12, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Nonogramm 12x12: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Nonogramm.zufaellig(n: 15, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Nonogramm 15x15: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}

final class NonogrammRandfaelle: XCTestCase {
    func testHinweiseDieNichtZurLoesungPassenSindNichtKonsistent() throws {
        var g = SystemRandomNumberGenerator()
        let p = Nonogramm.zufaellig(n: 5, mit: &g)
        let k = try kaputt(p, "zeilenHinweise", [[Int]](repeating: [99], count: 5))
        XCTAssertFalse(k.istKonsistent, "unlösbar: Hinweise passen nicht zur Lösung")
    }
    func testAlleFeldFuellenIstNichtGeloestBeiTeilloesung() {
        var g = SystemRandomNumberGenerator()
        var p = Nonogramm.zufaellig(n: 5, mit: &g)
        XCTAssertFalse(p.geloest)
        for i in 0..<25 where p.loesung[i] { p.tippe(i) }
        XCTAssertTrue(p.geloest)
        p.tippe(p.loesung.firstIndex(of: true)!); XCTAssertFalse(p.geloest)
    }
}

final class NonogrammIndexSchutz: XCTestCase {
    func testUngueltigerIndexIstWirkungslos() {
        var g = SystemRandomNumberGenerator()
        var p = Nonogramm.zufaellig(n: 5, mit: &g)
        let vorher = p.stand
        p.tippe(999); p.tippe(-1); p.markiere(25); p.markiere(-3)
        XCTAssertEqual(p.stand, vorher)
    }
}

final class ErzeugungsZeitSchwanz: XCTestCase {
    func testSchwanz() {
        var g = SystemRandomNumberGenerator()
        var zeiten: [Double] = []
        for _ in 0..<150 { let t = Date(); _ = Nonogramm.zufaellig(n: 15, mit: &g); zeiten.append(Date().timeIntervalSince(t)) }
        zeiten.sort()
        print("ZEIT Nonogramm 15x15: Median \(String(format: "%.3f", zeiten[zeiten.count / 2])) s, 95% \(String(format: "%.3f", zeiten[zeiten.count * 95 / 100])) s, max \(String(format: "%.3f", zeiten.last!)) s")
    }
}

final class NonogrammLayoutTests: XCTestCase {
    func testHinweiseSindAufDemKleinstenIPhonePlatzfest() {
        for n in [5, 8, 10, 12, 15] {
            let s = NonogrammLayout.skalaGrenze(n: n)
            XCTAssertLessThanOrEqual(s, 1.3)
            XCTAssertGreaterThanOrEqual(s, 1.0)
            // Hinweisspalte höchstens ein Viertel des Rasters
            XCTAssertLessThanOrEqual(NonogrammLayout.hinweisBreite(n: n) * s, NonogrammLayout.rasterBreite(geraet: 320) / 3.5, "n=\(n)")
            // Bei Skalierung über 1 muss eine zweistellige Spaltenzahl noch in ein Feld passen (bei 1,0 ist es der bisherige Stand)
            if s > 1.0 {
                XCTAssertLessThanOrEqual(NonogrammLayout.zweistelligBreite(skala: s), NonogrammLayout.feldBreite(n: n, geraet: 320, skala: s), "n=\(n) bei \(s)")
            }
            XCTAssertGreaterThan(NonogrammLayout.feldBreite(n: n, geraet: 320, skala: s), 10, "Felder dürfen nicht kleiner als 10 pt werden, n=\(n)")
        }
    }
    func testGroessteRaeumeWachsenNichtMehrAlsBisher() {
        XCTAssertEqual(NonogrammLayout.skalaGrenze(n: 15), 1.0)
        XCTAssertLessThanOrEqual(NonogrammLayout.skalaGrenze(n: 12), 1.1)
    }
}

final class NonogrammHinweisZeileTests: XCTestCase {
    func testLaengsteHinweiszeileBraucht_hoechstensNZeichen() {
        var g = SystemRandomNumberGenerator()
        for n in [5, 8, 10, 12, 15] {
            for _ in 0..<20 {
                let p = Nonogramm.zufaellig(n: n, mit: &g)
                for h in p.zeilenHinweise + p.spaltenHinweise { XCTAssertLessThanOrEqual(NonogrammLayout.zeichen(h), n, "n=\(n) \(h)") }
            }
        }
    }
    func testSchlimmsterFallPasstGeschrumpftInDieHinweisspalte() {
        // Schlimmster Fall: n Zeichen, zum Beispiel „1 1 1 1 1 1 1 1“ bei 15 × 15.
        for n in [5, 8, 10, 12, 15] {
            let s = NonogrammLayout.skalaGrenze(n: n)
            let b = NonogrammLayout.geschrumpfteBreite(zeichen: n, skala: s)
            XCTAssertLessThanOrEqual(b, NonogrammLayout.hinweisBreite(n: n) * s, "n=\(n): \(b) pt passen nicht in \(NonogrammLayout.hinweisBreite(n: n) * s) pt")
        }
        XCTAssertEqual(NonogrammLayout.zeichen([1, 1, 1, 1, 1, 1, 1, 1]), 15)
        XCTAssertEqual(NonogrammLayout.zeichen([10, 3]), 4)   // „10 3“
        XCTAssertEqual(NonogrammLayout.zeichen([]), 0)
    }
}
