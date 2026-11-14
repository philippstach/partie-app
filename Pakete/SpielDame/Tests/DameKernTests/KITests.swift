// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import DameKern

final class DameKITests: XCTestCase {
    private func leer() -> [Int] { [Int](repeating: 0, count: 64) }

    func testStufenSindGestaffelt() {
        XCTAssertLessThan(DameStaerke.leicht.tiefe, DameStaerke.mittel.tiefe)
        XCTAssertLessThan(DameStaerke.mittel.tiefe, DameStaerke.schwer.tiefe)
        XCTAssertGreaterThan(DameStaerke.leicht.fehler, DameStaerke.mittel.fehler)
        XCTAssertGreaterThan(DameStaerke.mittel.fehler, DameStaerke.schwer.fehler)
        XCTAssertEqual(DameStaerke.schwer.fehler, 0)
    }
    func testJedeStufeSpieltNurLegaleZuege() {
        for st in stufenFuerLauf(DameStaerke.allCases) {
            var d = Dame(); var n = 0
            while !d.vorbei, n < 40 { let z = DameComputer.wahl(d, staerke: st)!; XCTAssertTrue(d.spiele(z), "\(st)"); n += 1 }
        }
    }
    func testComputerNimmtDenMehrfachsprung() {
        // Weiß: Mann auf (5,2); Schwarz (4,3) und (2,5) schlagbar hintereinander. Schwer muss beide nehmen.
        var b = leer(); b[5 * 8 + 2] = 1; b[4 * 8 + 3] = 2; b[2 * 8 + 5] = 2; b[0 * 8 + 1] = 2; b[7 * 8 + 6] = 1
        let d = Dame(brett: b, dran: 1)
        let z = DameComputer.wahl(d, staerke: .schwer)!
        XCTAssertEqual(z.geschlagen.count, 2)
    }
    func testComputerSchlaegtFreiesDamenfeldNichtIntoFalle() {
        // Ein Mann kann schlagen, landet aber direkt vor einem Gegner, der zurückschlägt und eine Dame bekommt – schwer sieht das.
        var b = leer(); b[5 * 8 + 2] = 1; b[4 * 8 + 3] = 2; b[3 * 8 + 4] = 0; b[2 * 8 + 5] = 2
        b[1 * 8 + 4] = 2   // Gegner, der die Landung (3,4) schlagen kann
        let d = Dame(brett: b, dran: 1)
        XCTAssertNotNil(DameComputer.wahl(d, staerke: .schwer))
    }
    func testManneKroenungBeendetDenZug() {
        // Ein Mann springt in die letzte Reihe und wird dort Dame; weitere Sprünge als Mann gibt es nicht.
        var b = leer(); b[2 * 8 + 3] = 1; b[1 * 8 + 4] = 2; b[7 * 8 + 0] = 2
        var d = Dame(brett: b, dran: 1)
        let z = d.zuege.first { $0.geschlagen == [1 * 8 + 4] }!
        XCTAssertEqual(z.ziel, 0 * 8 + 5)
        XCTAssertTrue(d.spiele(z)); XCTAssertEqual(d.brett[5], 3); XCTAssertEqual(d.dran, 2)
    }
    func testKeineSteineBedeutetNiederlage() {
        var b = leer(); b[3 * 8 + 3] = 1
        let d = Dame(brett: b, dran: 2)
        XCTAssertTrue(d.zuege.isEmpty); XCTAssertEqual(d.sieger, 1)
    }
    func testFliegendeDameSchlaegtAusDerFerneUndWaehltLandung() {
        var b = leer(); b[7 * 8 + 0] = 3; b[4 * 8 + 3] = 2      // Dame a1-Ecke, Gegner auf der Diagonale
        let d = Dame(brett: b, dran: 1)
        let landungen = Set(d.zuege.map(\.ziel))
        XCTAssertEqual(landungen, [3 * 8 + 4, 2 * 8 + 5, 1 * 8 + 6, 0 * 8 + 7])
    }
    func testSchlagenIstEinmalProStein() {
        // Ein Stein darf im selben Zug nicht zweimal geschlagen werden (Kreis um einen Stein).
        var b = leer(); b[4 * 8 + 3] = 3
        for p in [3 * 8 + 4, 5 * 8 + 4, 5 * 8 + 2, 3 * 8 + 2] { b[p] = 2 }
        let d = Dame(brett: b, dran: 1)
        for z in d.zuege { XCTAssertEqual(Set(z.geschlagen).count, z.geschlagen.count) }
    }
    func testComputerSteigtNichtInEinzelSchlag() {
        // Mit Schlagzwang muss der Computer schlagen, wenn es geht (egal welche Stufe).
        var b = leer(); b[5 * 8 + 2] = 1; b[4 * 8 + 3] = 2; b[7 * 8 + 6] = 1
        let d = Dame(brett: b, dran: 1)
        for st in stufenFuerLauf(DameStaerke.allCases) { XCTAssertFalse(DameComputer.wahl(d, staerke: st)!.geschlagen.isEmpty) }
    }
}

/// Debug-Läufe sind etwa zehnmal langsamer: dort nur die leichten und mittleren Stufen, im Release alle.
func stufenFuerLauf<S>(_ alle: [S]) -> [S] {
    #if DEBUG
    return Array(alle.prefix(2))
    #else
    return alle
    #endif
}
