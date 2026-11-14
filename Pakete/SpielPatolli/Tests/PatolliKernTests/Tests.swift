// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import PatolliKern

final class PatolliTests: XCTestCase {
    private func bohnen(_ n: Int) -> [Bool] { (0..<5).map { $0 < n } }

    func testSchritte() {
        XCTAssertEqual(Patolli.schritte(markiert: 0), 0)
        XCTAssertEqual(Patolli.schritte(markiert: 3), 3)
        XCTAssertEqual(Patolli.schritte(markiert: 5), 10)
    }
    func testNullWurfSetztAus() {
        var p = Patolli()
        XCTAssertTrue(p.setzeWurf(bohnen(0)))
        XCTAssertEqual(p.amZug, 1); XCTAssertNil(p.wurf)
    }
    func testEinsetzenAufStartfeldUndSchritte() {
        var p = Patolli()
        p.setzeWurf(bohnen(1))
        XCTAssertEqual(p.zuege, [0])                      // alle Steine im Haus → nur einer zählt
        XCTAssertTrue(p.ziehe(0))
        XCTAssertEqual(p.stand[0][0], 0)                  // landet auf Startfeld
        XCTAssertEqual(p.amZug, 1)
    }
    func testSchlagen() {
        // Spieler 0 auf Fortschritt 13 → Feld 13; Spieler 1 auf Fortschritt 1 → Feld 13
        var p = Patolli(stand: [[10, -1, -1, -1], [1, -1, -1, -1]], amZug: 0)
        p.setzeWurf(bohnen(3))
        XCTAssertTrue(p.ziehe(0))
        XCTAssertEqual(p.stand[1][0], -1); XCTAssertEqual(p.geschlagen, 1)
    }
    func testSicheresFeldBlockiert() {
        // Spieler 1 steht auf Feld 18 (Fortschritt 6, sicher). Spieler 0 will auf Feld 18 (Fortschritt 18 = 17 + 1)
        var p = Patolli(stand: [[17, 0, -1, -1], [6, -1, -1, -1]], amZug: 0)
        p.setzeWurf(bohnen(1))
        XCTAssertFalse(p.zuege.contains(0))
        XCTAssertTrue(p.zuege.contains(1) || p.zuege.contains(2))
    }
    func testSonneGibtNochmal() {
        var p = Patolli(stand: [[0, -1, -1, -1], [-1, -1, -1, -1]], amZug: 0)
        p.setzeWurf(bohnen(3))                           // Fortschritt 3 → Feld 3 (Sonne)
        XCTAssertTrue(p.ziehe(0))
        XCTAssertEqual(p.amZug, 0)
    }
    func testFuenfBohnenNochmal() {
        var p = Patolli(stand: [[0, -1, -1, -1], [-1, -1, -1, -1]], amZug: 0)
        p.setzeWurf(bohnen(5)); XCTAssertTrue(p.ziehe(0)); XCTAssertEqual(p.amZug, 0); XCTAssertEqual(p.stand[0][0], 10)
    }
    func testZielUndSieg() {
        var p = Patolli(stand: [[24, 24, 24, 22], [-1, -1, -1, -1]], amZug: 0)
        p.setzeWurf(bohnen(4))
        XCTAssertTrue(p.ziehe(3)); XCTAssertEqual(p.gewinner, 0)
    }
    func testAlleStufenEnden() {
        for stufe in 1...3 {
            for _ in 0..<60 {
                var g = SystemRandomNumberGenerator(); var p = Patolli(); var n = 0
                while p.gewinner == nil && n < 20000 {
                    n += 1
                    if p.wurf == nil { p.wuerfle(mit: &g) }
                    if p.wurf != nil { XCTAssertTrue(p.ziehe(PatolliComputer.wahl(p, stufe: stufe)!)) }
                }
                XCTAssertNotNil(p.gewinner)
            }
        }
    }
    func testComputerPartienEnden() {
        for _ in 0..<200 {
            var g = SystemRandomNumberGenerator(); var p = Patolli(); var n = 0
            while p.gewinner == nil && n < 20000 {
                n += 1
                if p.wurf == nil { p.wuerfle(mit: &g) }
                if p.wurf != nil { XCTAssertTrue(p.ziehe(PatolliComputer.wahl(p)!)) }
            }
            XCTAssertNotNil(p.gewinner)
        }
    }
}

final class PatolliStufenDetailTests: XCTestCase {
    func testWahrscheinlichkeiten() {
        XCTAssertEqual((1...5).reduce(0.0) { $0 + PatolliComputer.wahrscheinlichkeit($1) } + PatolliComputer.wahrscheinlichkeit(10), 31.0 / 32 + 0, accuracy: 0.0001)
        XCTAssertEqual(PatolliComputer.wahrscheinlichkeit(0), 0)
        XCTAssertEqual(PatolliComputer.wahrscheinlichkeit(7), 0)
    }
    func testComputerWaehltNurErlaubteSteine() {
        var g = SystemRandomNumberGenerator()
        for stufe in 1...3 {
            var p = Patolli(); var n = 0
            while p.gewinner == nil && n < 2000 {
                if p.wurf == nil { p.wuerfle(mit: &g) }
                if p.wurf != nil, !p.zuege.isEmpty {
                    let i = PatolliComputer.wahl(p, stufe: stufe)!
                    XCTAssertTrue(p.zuege.contains(i)); p.ziehe(i)
                }
                n += 1
            }
        }
    }
    func testSchwerSchlaegtLeichtUndMittel() {
        var g = SystemRandomNumberGenerator()
        func duell(_ a: Int, _ b: Int, partien: Int) -> Int {
            var siege = 0
            for i in 0..<partien {
                var p = Patolli(); let seite = i % 2; var n = 0
                while p.gewinner == nil && n < 4000 {
                    if p.wurf == nil { p.wuerfle(mit: &g) }
                    if p.wurf != nil, !p.zuege.isEmpty { p.ziehe(PatolliComputer.wahl(p, stufe: p.amZug == seite ? a : b)!) }
                    n += 1
                }
                if p.gewinner == seite { siege += 1 }
            }
            return siege
        }
        let gegenLeicht = duell(3, 1, partien: 60)
        XCTAssertGreaterThan(gegenLeicht, 36, "schwer gegen leicht: \(gegenLeicht)/60")
        let gegenMittel = duell(3, 2, partien: 300)
        print("PATOLLI schwer gegen mittel \(gegenMittel)/300")
        XCTAssertGreaterThanOrEqual(gegenMittel, 140)
    }
}
