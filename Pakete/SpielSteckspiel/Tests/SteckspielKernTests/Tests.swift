// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SteckspielKern
final class SteckspielTests: XCTestCase {
    func testAufbau() {
        XCTAssertEqual(Steckspiel(brett: .kreuz).loecher.count, 33); XCTAssertEqual(Steckspiel(brett: .kreuz).uebrig, 32)
        XCTAssertEqual(Steckspiel(brett: .europa).loecher.count, 37); XCTAssertEqual(Steckspiel(brett: .europa).uebrig, 36)
    }
    func testErsteZuege() {
        let s = Steckspiel(brett: .kreuz); XCTAssertEqual(s.zuege().count, 4)
        XCTAssertTrue(s.zuege().allSatisfy { $0.nach == SPos(3, 3) })
    }
    func testZiehenUndZurueck() {
        var g = SystemRandomNumberGenerator()
        for b in Steckspiel.Brett.allCases {
            var s = Steckspiel(brett: b); let start = s
            while let z = s.zuege().randomElement(using: &g) { XCTAssertTrue(s.ziehe(z)) }
            XCTAssertTrue(s.uebrig >= 1 && s.festgefahren)
            while s.kannZurueck { s.zurueck() }
            XCTAssertEqual(s, start)
        }
    }
    func testHinweisIstLegal() {
        var s = Steckspiel(brett: .kreuz)
        for _ in 0..<12 { guard let h = s.hinweis() else { break }; XCTAssertTrue(s.ziehe(h)) }
    }
}

final class SteckspielZusatzTests: XCTestCase {
    func testStartstellungUndLochzahlen() {
        let k = Steckspiel(brett: .kreuz), e = Steckspiel(brett: .europa)
        XCTAssertEqual(k.loecher.count, 33); XCTAssertEqual(k.uebrig, 32)
        XCTAssertEqual(e.loecher.count, 37); XCTAssertEqual(e.uebrig, 36)
    }
    func testErsterZugUndZurueck() {
        var s = Steckspiel(brett: .kreuz)
        let z = s.zuege()
        XCTAssertEqual(z.count, 4)                        // vier Sprünge ins Mittelloch
        XCTAssertTrue(s.ziehe(z[0])); XCTAssertEqual(s.uebrig, 31)
        s.zurueck(); XCTAssertEqual(s.uebrig, 32); XCTAssertEqual(s.zuege, 0)
    }
    func testIllegalerZugWirdAbgelehnt() {
        var s = Steckspiel(brett: .kreuz)
        XCTAssertFalse(s.ziehe(SZug(von: SPos(0, 0), ueber: SPos(1, 0), nach: SPos(2, 0))))
        XCTAssertEqual(s.zuege, 0)
    }
    func testHinweisGibtImmerLegalenZugBisFestgefahren() {
        for b in [Steckspiel.Brett.kreuz, .europa] {
            var s = Steckspiel(brett: b); var k = 0
            while let h = s.hinweis(), k < 60 { XCTAssertTrue(s.ziehe(h)); k += 1 }
            XCTAssertTrue(s.festgefahren || s.uebrig == 1)
        }
    }
    func testRangUndPunkte() {
        var s = Steckspiel(brett: .kreuz); var k = 0
        while let h = s.hinweis(), k < 60 { s.ziehe(h); k += 1 }
        XCTAssertGreaterThanOrEqual(s.rang, 0); XCTAssertLessThanOrEqual(s.rang, 4)
        XCTAssertEqual(s.punkte, max(0, (s.loecher.count - 1 - s.uebrig) * 10) + (s.uebrig == 1 ? 100 : 0))
    }
}

final class SteckspielRegelTests: XCTestCase {
    func testSprungEntferntUebersprungenenSteckerUndSetztNeuenFlach() {
        var s = Steckspiel(brett: .kreuz)
        let z = s.zuege()[0]
        XCTAssertTrue(s.stecker.contains(z.von) && s.stecker.contains(z.ueber) && !s.stecker.contains(z.nach))
        s.ziehe(z)
        XCTAssertFalse(s.stecker.contains(z.von)); XCTAssertFalse(s.stecker.contains(z.ueber)); XCTAssertTrue(s.stecker.contains(z.nach))
    }
    func testAlleZuegeSindGeradeSpruengeUeberZweiFelder() {
        for b in Steckspiel.Brett.allCases {
            let s = Steckspiel(brett: b)
            for z in s.zuege() {
                XCTAssertEqual(abs(z.nach.x - z.von.x) + abs(z.nach.y - z.von.y), 2)
                XCTAssertEqual(z.ueber.x * 2, z.von.x + z.nach.x); XCTAssertEqual(z.ueber.y * 2, z.von.y + z.nach.y)
            }
        }
    }
    func testZugVonLeeremFeldUndAufBesetztesFeldIstUnzulaessig() {
        var s = Steckspiel(brett: .kreuz)
        XCTAssertFalse(s.ziehe(SZug(von: SPos(3, 3), ueber: SPos(3, 2), nach: SPos(3, 1))))   // Mitte ist leer
        XCTAssertFalse(s.ziehe(SZug(von: SPos(2, 3), ueber: SPos(3, 3), nach: SPos(4, 3))))   // Mitte ist kein Stecker
    }
    func testBrettIstSymmetrischUndMittelleer() {
        for b in Steckspiel.Brett.allCases {
            let s = Steckspiel(brett: b)
            for l in s.loecher { XCTAssertTrue(s.loecher.contains(SPos(6 - l.x, l.y)) && s.loecher.contains(SPos(l.x, 6 - l.y))) }
            XCTAssertFalse(s.stecker.contains(SPos(3, 3)))
        }
    }
    func testZuegeZaehlenUndZurueckSetztSieZurueck() {
        var s = Steckspiel(brett: .europa)
        s.ziehe(s.zuege()[0]); s.ziehe(s.zuege()[0])
        XCTAssertEqual(s.zuege, 2); s.zurueck(); XCTAssertEqual(s.zuege, 1)
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class SteckspielKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = Steckspiel(brett: .kreuz)
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = Steckspiel(brett: .kreuz)
        let k = try kaputt(w, "loecher", [Int]())
        XCTAssertFalse(k.istKonsistent)
    }
}
