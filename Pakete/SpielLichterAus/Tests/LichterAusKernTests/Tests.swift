// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import LichterAusKern

final class LichterAusTests: XCTestCase {
    func testTippSchaltetKreuz() {
        var l = LichterAus(n: 5); l.tippe(12)
        XCTAssertEqual(l.anzahlAn, 5); XCTAssertTrue(l.an[7] && l.an[11] && l.an[12] && l.an[13] && l.an[17])
        l.tippe(12); XCTAssertTrue(l.geschafft); XCTAssertEqual(l.zuege, 2)
    }
    func testEcke() { var l = LichterAus(n: 5); l.tippe(0); XCTAssertEqual(l.anzahlAn, 3) }
    func testMischenLoesbar() {
        var g = SystemRandomNumberGenerator(); var l = LichterAus(); l.mischen(mit: &g)
        XCTAssertFalse(l.geschafft); XCTAssertEqual(l.zuege, 0)
    }
    func testHinweiseLoesenInHoechstensWenigenZuegen() {
        var g = SystemRandomNumberGenerator()
        for n in [3, 4, 5, 6] {
            for _ in 0..<15 {
                var l = LichterAus(n: n); l.mischen(mit: &g)
                var schritte = 0
                while !l.geschafft, let h = l.hinweis(), schritte < n * n { l.tippe(h); schritte += 1 }
                XCTAssertTrue(l.geschafft, "\(n)x\(n) nach \(schritte)")
            }
        }
    }
    func testKeinHinweisWennGeschafft() { XCTAssertNil(LichterAus(n: 5).hinweis()) }
    func testMusterDiagonalUndRund() {
        var d = LichterAus(n: 5, muster: .diagonal); d.tippe(12)
        XCTAssertEqual(d.anzahlAn, 5); XCTAssertTrue(d.an[6] && d.an[8] && d.an[16] && d.an[18] && d.an[12])
        var r = LichterAus(n: 5, muster: .rund); r.tippe(12); XCTAssertEqual(r.anzahlAn, 9)
    }
    func testAlteSpeicherstaendeLadenAlsKreuz() throws {
        let alt = #"{"n":3,"an":[true,false,false,false,false,false,false,false,false],"zuege":2}"#.data(using: .utf8)!
        let l = try JSONDecoder().decode(LichterAus.self, from: alt)
        XCTAssertEqual(l.muster, .kreuz); XCTAssertEqual(l.zuege, 2)
    }
    func testMusterLoesbarMitHinweis() {
        var g = SystemRandomNumberGenerator()
        for m in LichterAus.Muster.allCases {
            var l = LichterAus(n: 5, muster: m); l.mischen(tipps: 8, mit: &g)
            var k = 0
            while !l.geschafft, let h = l.hinweis(), k < 25 { l.tippe(h); k += 1 }
            XCTAssertTrue(l.geschafft, "\(m)")
        }
    }
}

final class LichterAusZusatzTests: XCTestCase {
    func testAlleGroessenUndMusterLoesbarUndHinweisFuehrtZumZiel() {
        var g = SystemRandomNumberGenerator()
        for n in 3...7 { for m in LichterAus.Muster.allCases {
            var l = LichterAus(n: n, muster: m); l.mischen(mit: &g)
            XCTAssertFalse(l.geschafft)
            var schritte = 0
            while !l.geschafft, let h = l.hinweis(), schritte < n * n { l.tippe(h); schritte += 1 }
            XCTAssertTrue(l.geschafft, "n=\(n) \(m)")
        } }
    }
    func testMusterGroessen() {
        XCTAssertEqual(LichterAus.Muster.kreuz.abstaende.count, 5)
        XCTAssertEqual(LichterAus.Muster.diagonal.abstaende.count, 5)
        XCTAssertEqual(LichterAus.Muster.rund.abstaende.count, 9)
    }
    func testRundInDerMitteSchaltetNeunUm() {
        var l = LichterAus(n: 5, muster: .rund); l.tippe(12)
        XCTAssertEqual(l.anzahlAn, 9)
    }
    func testDoppelterTippHebtAufUndZaehlt() {
        var l = LichterAus(n: 4); l.tippe(5); l.tippe(5)
        XCTAssertTrue(l.geschafft); XCTAssertEqual(l.zuege, 2)
    }
    func testUngueltigerTippWirdIgnoriert() {
        var l = LichterAus(n: 3); l.tippe(-1); l.tippe(99)
        XCTAssertEqual(l.zuege, 0); XCTAssertTrue(l.geschafft)
    }
    func testCodableRundlauf() throws {
        var g = SystemRandomNumberGenerator()
        var l = LichterAus(n: 6, muster: .diagonal); l.mischen(mit: &g)
        let d = try JSONEncoder().encode(l)
        XCTAssertEqual(try JSONDecoder().decode(LichterAus.self, from: d), l)
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class LichterAusKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = LichterAus(n: 5)
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = LichterAus(n: 5)
        let k = try kaputt(w, "an", [true])
        XCTAssertFalse(k.istKonsistent)
    }
}

final class SchwierigkeitMessung: XCTestCase {
    /// Mischtipps je Stufe wie in der Ansicht (0 leicht, 1 mittel, 2 schwer).
    func mischTipps(_ stufe: Int, _ m: Int) -> Int { switch stufe { case 0: return max(3, m / 5); case 2: return max(8, m * 2 / 3); default: return max(5, m / 3) } }
    func testStufenSindSpuerbarVerschieden() {
        var g = SystemRandomNumberGenerator()
        for n in [3, 4, 5, 6, 7] {
            var mittel: [Double] = []
            for stufe in 0...2 {
                var summe = 0
                for _ in 0..<60 {
                    var l = LichterAus(n: n); l.mischen(tipps: mischTipps(stufe, n * n), mit: &g)
                    var k = 0
                    while !l.geschafft, let h = l.hinweis(), k < n * n { l.tippe(h); k += 1 }
                    summe += k
                }
                mittel.append(Double(summe) / 60)
            }
            print("MESS LichterAus n=\(n) Lösungszüge leicht/mittel/schwer: \(mittel.map { String(format: "%.1f", $0) })")
            // 4×4 ist gesättigt (die längsten kürzesten Lösungen haben nur ca. 5 Tipps), dort sind mittel und schwer gleich schwer
            XCTAssertLessThan(mittel[0], mittel[1], "n=\(n)")
            if n != 4 { XCTAssertLessThan(mittel[1], mittel[2], "n=\(n)") }
        }
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = { var l = LichterAus(n: 5); l.mischen(tipps: 16, mit: &g); return l.hinweis() }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT LichterAus 5x5 Tipp (hinweis): Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = { var l = LichterAus(n: 6); l.mischen(tipps: 24, mit: &g); return l.hinweis() }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT LichterAus 6x6 Tipp (hinweis): Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = { var l = LichterAus(n: 7); l.mischen(tipps: 32, mit: &g); return l.hinweis() }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT LichterAus 7x7 Tipp (hinweis): Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}
