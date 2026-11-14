// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import FarbcodeKern
final class FarbcodeTests: XCTestCase {
    func testBewertung() {
        XCTAssertEqual(Farbcode.bewerte(tipp: [0, 1, 2, 3], code: [0, 1, 2, 3]), .init(genau: 4, farbe: 0))
        XCTAssertEqual(Farbcode.bewerte(tipp: [1, 0, 3, 2], code: [0, 1, 2, 3]), .init(genau: 0, farbe: 4))
        XCTAssertEqual(Farbcode.bewerte(tipp: [0, 0, 1, 1], code: [0, 1, 0, 2]), .init(genau: 1, farbe: 2))
        XCTAssertEqual(Farbcode.bewerte(tipp: [2, 2, 2, 2], code: [2, 0, 0, 0]), .init(genau: 1, farbe: 0))
        XCTAssertEqual(Farbcode.bewerte(tipp: [1, 1, 0, 0], code: [0, 0, 0, 1]), .init(genau: 1, farbe: 2))
    }
    func testCodeOhneDoppelte() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<50 { let c = Farbcode(modus: .leicht, mit: &g).code; XCTAssertEqual(Set(c).count, 4) }
    }
    func testJederCodeIstMitHinweisenLoesbar() {
        var g = SystemRandomNumberGenerator()
        for m in Farbcode.Modus.allCases {
            for _ in 0..<5 {
                var f = Farbcode(modus: m, mit: &g)
                while !f.vorbei { f.rate(f.hinweis(mit: &g)!) }
                XCTAssertTrue(f.geloest, "\(m) in \(f.versuche.count)")
                XCTAssertTrue(f.versuche.count <= 8)
            }
        }
    }
    func testUngueltigerTipp() {
        var g = SystemRandomNumberGenerator(); var f = Farbcode(modus: .leicht, mit: &g)
        XCTAssertFalse(f.rate([0, 0, 1, 2])); XCTAssertFalse(f.rate([0, 1, 2])); XCTAssertFalse(f.rate([0, 1, 2, 9]))
        XCTAssertTrue(f.rate([0, 1, 2, 3]))
    }
}

final class FarbcodeZusatzTests: XCTestCase {
    func testBewertungMitDoppeltenFarben() {
        // Code 1 1 2 3, Tipp 1 2 1 1: eine Stelle genau (erste 1), zwei weitere Farben stimmen (2, 1) – die dritte 1 zählt nicht mehr
        let r = Farbcode.bewerte(tipp: [1, 2, 1, 1], code: [1, 1, 2, 3])
        XCTAssertEqual(r, Farbcode.Rueckmeldung(genau: 1, farbe: 2))
    }
    func testAlleStellenRichtigUndNichtsRichtig() {
        XCTAssertEqual(Farbcode.bewerte(tipp: [0, 1, 2, 3], code: [0, 1, 2, 3]), .init(genau: 4, farbe: 0))
        XCTAssertEqual(Farbcode.bewerte(tipp: [0, 0, 0, 0], code: [1, 1, 1, 1]), .init(genau: 0, farbe: 0))
        XCTAssertEqual(Farbcode.bewerte(tipp: [0, 1, 2, 3], code: [3, 2, 1, 0]), .init(genau: 0, farbe: 4))
    }
    func testLeichtHatKeineDoppeltenFarbenImCode() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<50 { let f = Farbcode(modus: .leicht, mit: &g); XCTAssertEqual(Set(f.code).count, f.code.count) }
    }
    func testLeichtLehntDoppelteImTippAb() {
        var f = Farbcode(code: [0, 1, 2, 3], modus: .leicht)
        XCTAssertFalse(f.rate([0, 0, 1, 2])); XCTAssertEqual(f.versuche.count, 0)
        XCTAssertTrue(f.rate([0, 1, 2, 3])); XCTAssertTrue(f.geloest)
    }
    func testUngueltigeTippsWerdenAbgelehnt() {
        var f = Farbcode(code: [0, 1, 2, 3], modus: .normal)
        XCTAssertFalse(f.rate([0, 1, 2])); XCTAssertFalse(f.rate([0, 1, 2, 9])); XCTAssertFalse(f.rate([-1, 0, 1, 2]))
    }
    func testNachDemLetztenVersuchVorbeiUndKeinTippMehr() {
        var f = Farbcode(code: [0, 0, 0, 0], modus: .normal)
        for _ in 0..<f.modus.versuche { XCTAssertTrue(f.rate([1, 1, 1, 1])) }
        XCTAssertTrue(f.vorbei); XCTAssertFalse(f.geloest); XCTAssertFalse(f.rate([0, 0, 0, 0]))
    }
    func testHinweisEnthaeltStetsDenEchtenCodeUndPasstZuAllenAntworten() {
        var g = SystemRandomNumberGenerator()
        for modus in Farbcode.Modus.allCases {
            var f = Farbcode(modus: modus, mit: &g)
            for _ in 0..<4 where !f.vorbei {
                guard let h = f.hinweis(mit: &g) else { return XCTFail("kein Hinweis") }
                XCTAssertTrue(f.moeglicheCodes().contains(f.code))
                f.rate(h)
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

final class FarbcodeKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = Farbcode(code: [0, 1, 2, 3], modus: .normal)
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = Farbcode(code: [0, 1, 2, 3], modus: .normal)
        let k = try kaputt(w, "code", [0])
        XCTAssertFalse(k.istKonsistent)
    }
}

final class SchwierigkeitMessung: XCTestCase {
    func testStufen() {
        var g = SystemRandomNumberGenerator()
        for modus in Farbcode.Modus.allCases {
            var versuche = 0.0, gewonnen = 0
            for _ in 0..<40 {
                var f = Farbcode(modus: modus, mit: &g)
                while !f.vorbei, let h = f.hinweis(mit: &g) { f.rate(h) }
                versuche += Double(f.versuche.count); if f.geloest { gewonnen += 1 }
            }
            let raum = modus.doppelt ? Int(pow(Double(modus.farben), Double(modus.laenge))) : (0..<modus.laenge).reduce(1) { $0 * (modus.farben - $1) }
            print("MESS Farbcode \(modus): Codes \(raum), Ø \(String(format: "%.1f", versuche / 40)) Versuche bei bestem Raten (von \(modus.versuche)), gelöst \(gewonnen)/40")
        }
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = { var f = Farbcode(modus: .schwer, mit: &g); for _ in 0..<3 { if let h = f.hinweis(mit: &g) { f.rate(h) } }; return f.hinweis(mit: &g) }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Farbcode moeglicheCodes schwer (nach 3 Versuchen): Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}
