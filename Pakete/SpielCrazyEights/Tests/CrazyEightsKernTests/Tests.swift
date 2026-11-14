// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SpieleKern
@testable import CrazyEightsKern

final class CrazyEightsTests: XCTestCase {
    private func k(_ f: SkatKarte.Farbe, _ w: Int) -> SkatKarte { SkatKarte(f, w) }

    func testAnfang() {
        var g = SystemRandomNumberGenerator(); let e = CrazyEights(mit: &g)
        XCTAssertEqual(e.haende[0].count, 7); XCTAssertEqual(e.haende[1].count, 7)
        XCTAssertNotEqual(e.oben.wert, 8)
    }
    func testLegen() {
        var e = CrazyEights(haende: [[k(.herz, 5), k(.pik, 9), k(.kreuz, 8)], [k(.karo, 3)]], oben: k(.herz, 9))
        XCTAssertEqual(e.spielbar, [0, 1, 2])
        XCTAssertFalse(e.lege(2))                        // Achter braucht Farbwunsch
        XCTAssertTrue(e.lege(1))                         // Pik 9 auf Herz 9 (gleicher Wert)
        XCTAssertEqual(e.gewuenschteFarbe, .pik); XCTAssertEqual(e.amZug, 1)
    }
    func testAchterWunsch() {
        var e = CrazyEights(haende: [[k(.kreuz, 8), k(.herz, 2)], [k(.karo, 3), k(.karo, 4)]], oben: k(.herz, 9))
        XCTAssertTrue(e.lege(0, wunsch: .karo))
        XCTAssertEqual(e.spielbar, [0, 1])               // Karo-Karten spielbar
    }
    func testZiehenBisDreiDannPassen() {
        var g = SystemRandomNumberGenerator()
        var e = CrazyEights(haende: [[k(.kreuz, 2)], [k(.karo, 3)]], oben: k(.herz, 9), vorrat: [k(.pik, 4), k(.pik, 5), k(.pik, 6), k(.pik, 7)])
        XCTAssertTrue(e.darfZiehen)
        for _ in 0..<3 { XCTAssertTrue(e.ziehe(mit: &g)) }
        XCTAssertFalse(e.ziehe(mit: &g))
        XCTAssertTrue(e.mussPassen); XCTAssertTrue(e.passe()); XCTAssertEqual(e.amZug, 1)
    }
    func testSiegUndStrafe() {
        var e = CrazyEights(haende: [[k(.herz, 5)], [k(.karo, 8), k(.pik, 14), k(.kreuz, 12)]], oben: k(.herz, 9))
        XCTAssertTrue(e.lege(0))
        XCTAssertEqual(e.gewinner, 0); XCTAssertEqual(e.punkte, 50 + 1 + 10)
    }
    func testComputerPartienEnden() {
        for _ in 0..<200 {
            var g = SystemRandomNumberGenerator(); var e = CrazyEights(mit: &g); var n = 0
            while e.gewinner == nil && n < 2000 {
                n += 1
                if let m = CrazyEightsComputer.wahl(e) { XCTAssertTrue(e.lege(m.index, wunsch: m.wunsch)) }
                else if e.darfZiehen { e.ziehe(mit: &g) }
                else { XCTAssertTrue(e.passe()) }
            }
            XCTAssertNotNil(e.gewinner)
        }
    }

    private struct Quelle: RandomNumberGenerator {
        var z: UInt64
        mutating func next() -> UInt64 { z &+= 0x9E3779B97F4A7C15; var x = z; x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9; x = (x ^ (x >> 27)) &* 0x94D049BB133111EB; return x ^ (x >> 31) }
    }
    private func siegquote(stufe0: Int, stufe1: Int, partien: Int = 800) -> Double {
        var siege = 0
        for i in 0..<partien {
            var g = Quelle(z: UInt64(i + 11)); var e = CrazyEights(mit: &g); var n = 0
            while e.gewinner == nil && n < 2000 {
                n += 1
                let stufe = e.amZug == 0 ? stufe0 : stufe1
                if let m = CrazyEightsComputer.wahl(e, stufe: stufe) { XCTAssertTrue(e.lege(m.index, wunsch: m.wunsch)) }
                else if e.darfZiehen { e.ziehe(mit: &g) } else { XCTAssertTrue(e.passe()) }
            }
            if e.gewinner == 0 { siege += 1 }
        }
        return Double(siege) / Double(partien)
    }
    func testSchwerSchlaegtLeicht() { XCTAssertGreaterThan(siegquote(stufe0: 3, stufe1: 1), 0.55) }
    func testSchwerNichtSchlechterAlsMittel() { XCTAssertGreaterThan(siegquote(stufe0: 3, stufe1: 2), 0.47) }
}

final class CrazyEightsRegelnTests: XCTestCase {
    private func k(_ f: SkatKarte.Farbe, _ w: Int) -> SkatKarte { SkatKarte(f, w) }

    func testAchterIstImmerSpielbarAuchAufFremdeFarbe() {
        let e = CrazyEights(haende: [[k(.kreuz, 8), k(.pik, 2)], [k(.karo, 3)]], oben: k(.herz, 9))
        XCTAssertEqual(e.spielbar, [0])
    }
    func testNichtPassendeKarteWirdAbgelehnt() {
        var e = CrazyEights(haende: [[k(.pik, 2), k(.herz, 5)], [k(.karo, 3)]], oben: k(.herz, 9))
        XCTAssertFalse(e.lege(0)); XCTAssertEqual(e.haende[0].count, 2); XCTAssertEqual(e.amZug, 0)
    }
    func testKarteDesGegnersImmerNurVomAmZugBetroffenen() {
        var e = CrazyEights(haende: [[k(.herz, 5), k(.pik, 4)], [k(.herz, 3), k(.karo, 3)]], oben: k(.herz, 9))
        XCTAssertTrue(e.lege(0)); XCTAssertEqual(e.amZug, 1); XCTAssertEqual(e.haende[1].count, 2)
        XCTAssertEqual(e.spielbar, [0])         // nur Herz 3 passt auf Herz 5
    }
    func testZiehenErlaubtNurOhnePassendeKarte() {
        var g = SystemRandomNumberGenerator()
        var e = CrazyEights(haende: [[k(.herz, 2)], [k(.karo, 3)]], oben: k(.herz, 9), vorrat: [k(.pik, 4)])
        XCTAssertFalse(e.darfZiehen); XCTAssertFalse(e.ziehe(mit: &g)); XCTAssertFalse(e.mussPassen)
    }
    func testZiehenEndetMitPassenWennStapelLeer() {
        var g = SystemRandomNumberGenerator()
        var e = CrazyEights(haende: [[k(.kreuz, 2)], [k(.karo, 3)]], oben: k(.herz, 9), vorrat: [])
        XCTAssertFalse(e.darfZiehen); XCTAssertTrue(e.mussPassen); XCTAssertFalse(e.ziehe(mit: &g)); XCTAssertTrue(e.passe())
    }
    func testGezogeneKarteDarfSofortGespieltWerden() {
        var g = SystemRandomNumberGenerator()
        var e = CrazyEights(haende: [[k(.kreuz, 2)], [k(.karo, 3)]], oben: k(.herz, 9), vorrat: [k(.herz, 4)])
        XCTAssertTrue(e.ziehe(mit: &g)); XCTAssertEqual(e.spielbar, [1]); XCTAssertTrue(e.lege(1)); XCTAssertEqual(e.amZug, 1)
    }
    func testPassenOhneZwangIstUnmoeglich() {
        var e = CrazyEights(haende: [[k(.herz, 2)], [k(.karo, 3)]], oben: k(.herz, 9))
        XCTAssertFalse(e.passe())
    }
    func testStrafpunkte() {
        XCTAssertEqual(CrazyEights.strafe(k(.herz, 8)), 50); XCTAssertEqual(CrazyEights.strafe(k(.herz, 13)), 10)
        XCTAssertEqual(CrazyEights.strafe(k(.herz, 11)), 10); XCTAssertEqual(CrazyEights.strafe(k(.herz, 14)), 1)
        XCTAssertEqual(CrazyEights.strafe(k(.herz, 7)), 7)
    }
    func testNachDemSiegIstKeinZugMehrMoeglich() {
        var e = CrazyEights(haende: [[k(.herz, 5)], [k(.karo, 3)]], oben: k(.herz, 9))
        XCTAssertTrue(e.lege(0)); XCTAssertTrue(e.spielbar.isEmpty); XCTAssertFalse(e.darfZiehen)
    }
}

final class CrazyEightsComputerTests: XCTestCase {
    private func k(_ f: SkatKarte.Farbe, _ w: Int) -> SkatKarte { SkatKarte(f, w) }

    func testGewinntMitLetzterKarteAuchWennAchter() {
        let e = CrazyEights(haende: [[k(.kreuz, 8)], [k(.karo, 3)]], oben: k(.herz, 9))
        for stufe in 1...3 { XCTAssertEqual(CrazyEightsComputer.wahl(e, stufe: stufe)?.index, 0) }
    }
    func testWunschfarbeIstHaeufigsteRestfarbe() {
        let e = CrazyEights(haende: [[k(.kreuz, 8), k(.pik, 2), k(.pik, 3), k(.herz, 4)], [k(.karo, 3)]], oben: k(.herz, 9))
        // Achter ist hier die einzige spielbare Karte nicht: Herz 4 passt, doch Stufe 3 behält den Achter.
        let m = CrazyEightsComputer.wahl(e, stufe: 3)!
        XCTAssertEqual(e.haende[0][m.index], k(.herz, 4))
        XCTAssertEqual(CrazyEightsComputer.haeufigsteFarbe([k(.pik, 2), k(.pik, 3), k(.herz, 4)]), .pik)
    }
    func testSchwerHebtAchterAufSolangeEsAndereKartenGibt() {
        let e = CrazyEights(haende: [[k(.kreuz, 8), k(.herz, 2), k(.herz, 3), k(.pik, 5), k(.pik, 6)], [k(.karo, 3), k(.karo, 4), k(.karo, 5)]], oben: k(.herz, 9))
        let m = CrazyEightsComputer.wahl(e, stufe: 3)!
        XCTAssertNotEqual(e.haende[0][m.index].wert, 8)
    }
    func testKeineWahlOhnePassendeKarte() {
        let e = CrazyEights(haende: [[k(.kreuz, 2)], [k(.karo, 3)]], oben: k(.herz, 9))
        XCTAssertNil(CrazyEightsComputer.wahl(e))
    }
    func testWahlIstInJederStufeLegal() {
        var g = SystemRandomNumberGenerator()
        for stufe in 1...3 { for _ in 0..<100 {
            let e = CrazyEights(mit: &g)
            if let m = CrazyEightsComputer.wahl(e, stufe: stufe) {
                var c = e; XCTAssertTrue(c.lege(m.index, wunsch: m.wunsch ?? .herz))
            }
        } }
    }

    private func partie(schwerSeite: Int, gegner: Int, _ g: inout SystemRandomNumberGenerator) -> Int? {
        var e = CrazyEights(mit: &g); var n = 0
        while e.gewinner == nil && n < 2000 {
            n += 1
            let stufe = e.amZug == schwerSeite ? 3 : gegner
            if let m = CrazyEightsComputer.wahl(e, stufe: stufe) { e.lege(m.index, wunsch: m.wunsch ?? .herz) }
            else if e.darfZiehen { e.ziehe(mit: &g) } else { e.passe() }
        }
        return e.gewinner
    }
    func testSchwerSchlaegtLeicht() {
        var g = SystemRandomNumberGenerator(); var schwer = 0, andere = 0
        for i in 0..<600 { if let w = partie(schwerSeite: i % 2, gegner: 1, &g) { if w == i % 2 { schwer += 1 } else { andere += 1 } } }
        XCTAssertGreaterThan(schwer, andere + 60, "schwer \(schwer), leicht \(andere)")
    }
    func testSchwerSchlaegtMittel() {
        var g = SystemRandomNumberGenerator(); var schwer = 0, andere = 0
        for i in 0..<4000 { if let w = partie(schwerSeite: i % 2, gegner: 2, &g) { if w == i % 2 { schwer += 1 } else { andere += 1 } } }
        // Crazy Eights ist stark vom Glück geprägt: schwer darf gegen mittel nicht schlechter abschneiden (Rauschen etwa ±1,5 %).
        XCTAssertGreaterThan(Double(schwer) / Double(schwer + andere), 0.46, "schwer \(schwer), mittel \(andere)")
    }
}
