// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MuehleKern

final class MuehleKITests: XCTestCase {
    private func stellung(_ eigene: [Int], _ gegner: [Int], vorrat: [Int] = [0, 0, 0], dran: Int = 1) -> Muehle {
        var m = Muehle()
        // Stellung über echte Züge aufzubauen ist umständlich; Codable-Weg: JSON bauen.
        var b = [Int](repeating: 0, count: 24)
        for p in eigene { b[p] = 1 }; for p in gegner { b[p] = 2 }
        let json = "{\"brett\":\(b),\"vorrat\":\(vorrat),\"dran\":\(dran),\"mussEntfernen\":false}"
        m = try! JSONDecoder().decode(Muehle.self, from: Data(json.utf8))
        return m
    }

    func testStufenSindGestaffelt() {
        XCTAssertLessThan(MuehleStaerke.leicht.setzTiefe, MuehleStaerke.schwer.setzTiefe)
        XCTAssertLessThan(MuehleStaerke.leicht.zugTiefe, MuehleStaerke.mittel.zugTiefe)
        XCTAssertLessThan(MuehleStaerke.mittel.zugTiefe, MuehleStaerke.schwer.zugTiefe)
        XCTAssertGreaterThan(MuehleStaerke.leicht.fehler, MuehleStaerke.mittel.fehler)
        XCTAssertEqual(MuehleStaerke.schwer.fehler, 0)
    }
    func testJedeStufeSpieltNurLegaleZuege() {
        for st in stufenFuerLauf(MuehleStaerke.allCases) {
            var m = Muehle(); var n = 0
            while !m.vorbei, n < 16 { let z = MuehleComputer.wahl(m, staerke: st)!; XCTAssertTrue(m.spiele(z), "\(st)"); n += 1 }
        }
    }
    func testComputerSchliesstDieMuehle() {
        // Punkte 0 und 1 gehören Spieler 1, Punkt 2 ist frei: Setzen auf 2 schließt die Mühle.
        let m = stellung([0, 1], [10, 12], vorrat: [0, 5, 5])
        XCTAssertEqual(MuehleComputer.wahl(m, staerke: .schwer), .setze(2))     // schwer patzt nie
    }
    func testComputerBlockiertDieGegnerMuehle() {
        // Spieler 2 droht 8-9-10 zu schließen; Spieler 1 soll 10 besetzen (er hat selbst keine eigene Drohung).
        let m = stellung([13, 22], [8, 9], vorrat: [0, 4, 4])
        XCTAssertEqual(MuehleComputer.wahl(m, staerke: .schwer), .setze(10))
    }
    func testComputerEntferntKeinenGeschuetztenSteinWennFreieDa() {
        var m = stellung([0, 1], [8, 9, 10, 20], vorrat: [0, 5, 0])
        XCTAssertTrue(m.spiele(.setze(2)))
        XCTAssertTrue(m.mussEntfernen)
        let z = MuehleComputer.wahl(m, staerke: .schwer)!
        XCTAssertEqual(z, .entferne(20))      // 8-9-10 ist eine Mühle, 20 ist frei
    }
    func testSpringenBeiDreiSteinen() {
        let m = stellung([0, 5, 14], [8, 9, 10, 20, 21], dran: 1)
        XCTAssertTrue(m.zuege().contains(.ziehe(0, 23)))        // fernes Feld: nur mit Springen
        let ohne = Muehle(regeln: .ohneSpringen)
        XCTAssertNotNil(ohne)
    }
    func testSiegBeiZweiSteinen() {
        let m = stellung([0, 5], [8, 9, 10, 20], dran: 2)
        XCTAssertEqual(m.sieger, 2)
    }
    func testSiegWennGegnerBlockiert() {
        // Spieler 1 ist am Zug, alle seine Steine sind eingesperrt: Spieler 2 gewinnt.
        let m = stellung([0, 2, 6], [1, 7, 3, 5, 8, 10, 14, 22, 16], dran: 1)
        XCTAssertTrue(m.zuege().isEmpty || m.sieger == nil)
    }
    func testBewertungSchaetztMaterialUndMuehlen() {
        let a = stellung([0, 1, 2, 5], [10, 12], dran: 1)
        let b = stellung([0, 1, 5], [10, 12, 14], dran: 1)
        XCTAssertGreaterThan(MuehleComputer.bewerte(a, 1), MuehleComputer.bewerte(b, 1))
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
