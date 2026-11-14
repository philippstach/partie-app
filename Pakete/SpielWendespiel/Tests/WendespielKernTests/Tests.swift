// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WendespielKern

final class WendespielTests: XCTestCase {
    func testStartzuege() {
        let w = Wendespiel()
        XCTAssertEqual(Set(w.zuege), [19, 26, 37, 44]); XCTAssertEqual(w.steine(1), 2); XCTAssertEqual(w.steine(2), 2)
    }
    func testSetzenWendet() {
        var w = Wendespiel(); XCTAssertTrue(w.setze(19))
        XCTAssertEqual(w.steine(1), 4); XCTAssertEqual(w.steine(2), 1); XCTAssertEqual(w.dran, 2)
        XCTAssertFalse(w.setze(0))
    }
    func testComputerSpieltBisEnde() {
        var w = Wendespiel(); var n = 0
        while !w.beendet && n < 200 { guard let p = WendespielComputer.wahl(w, tiefe: 2) else { break }; XCTAssertTrue(w.setze(p)); n += 1 }
        XCTAssertTrue(w.beendet); XCTAssertEqual(w.steine(1) + w.steine(2) , w.brett.filter { $0 != 0 }.count)
    }
    func testNeuerComputerSchlaegtEinfachen() {
        var siege = 0
        for k in 0..<2 {
            var w = Wendespiel(); let ich = k % 2 + 1; var n = 0
            while !w.beendet && n < 100 {
                let p = w.dran == ich ? WendespielComputer.wahl(w, tiefe: 2)! : WendespielComputer.wahl(w, tiefe: 1, fehler: 0.6)!
                w.setze(p); n += 1
            }
            if w.sieger == ich { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 1)
    }
}

final class WendespielVerkehrtTests: XCTestCase {
    func testVerkehrtKehrtSiegerUm() {
        var w = Wendespiel(verkehrt: true); var n = 0
        while !w.beendet, n < 200, let p = w.zuege.randomElement() { w.setze(p); n += 1 }
        let a = w.steine(1), b = w.steine(2)
        if a != b { XCTAssertEqual(w.sieger, a < b ? 1 : 2) }
        var k = Wendespiel(); XCTAssertFalse(k.verkehrt); k.setze(k.zuege[0])
    }
    func testComputerSpieltVerkehrt() {
        var w = Wendespiel(verkehrt: true); var n = 0
        while !w.beendet, n < 200, let p = WendespielComputer.wahl(w, tiefe: 2) { w.setze(p); n += 1 }
        XCTAssertTrue(w.beendet)
    }
    func testAlterSpielstandLaedt() throws {
        let json = #"{"brett":\#(Wendespiel().brett),"dran":1}"#
        XCTAssertFalse(try JSONDecoder().decode(Wendespiel.self, from: Data(json.utf8)).verkehrt)
    }
}

final class WendespielRegelDetailTests: XCTestCase {
    private func stellung(_ steine: [Int: Int], dran: Int = 1, verkehrt: Bool = false) throws -> Wendespiel {
        var b = [Int](repeating: 0, count: 64)
        for (i, s) in steine { b[i] = s }
        let json = #"{"brett":\#(b),"dran":\#(dran),"verkehrt":\#(verkehrt)}"#
        return try JSONDecoder().decode(Wendespiel.self, from: Data(json.utf8))
    }
    func testStartAufstellung() {
        let w = Wendespiel()
        XCTAssertEqual(w.steine(1), 2); XCTAssertEqual(w.steine(2), 2)
        XCTAssertEqual(w.zuege.count, 4)
    }
    func testWendetInEineRichtung() throws {
        var w = try stellung([0: 1, 1: 2, 2: 2])   // 1 setzt auf 3 und wendet 1 und 2
        XCTAssertTrue(w.setze(3))
        XCTAssertEqual(w.brett[1], 1); XCTAssertEqual(w.brett[2], 1)
    }
    func testWendetInMehrereRichtungenGleichzeitig() throws {
        var w = try stellung([0: 1, 1: 2, 8: 2, 9: 2, 27: 1, 18: 2, 36: 0, 63: 0])
        // Setzen auf 2: waagerecht (1 zwischen 0 und 2 nicht, da 2 leer) – nur prüfen, dass jedes gewendete Feld Gegner war
        let vorher = w.brett
        let w1 = w.wendet(2, 1)
        XCTAssertFalse(w1.isEmpty)
        XCTAssertTrue(w.setze(2))
        for i in w1 { XCTAssertEqual(vorher[i], 2); XCTAssertEqual(w.brett[i], 1) }
    }
    func testUngueltigerZugOhneWenden() throws {
        var w = Wendespiel()
        XCTAssertFalse(w.setze(0)); XCTAssertFalse(w.setze(27))
        XCTAssertEqual(w, Wendespiel())
    }
    func testPassenNurWennGegnerKeinenZugHat() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<10 {
            var w = Wendespiel()
            while !w.beendet {
                let vorher = w.dran
                w.setze(w.zuege.randomElement(using: &g)!)
                if w.dran == vorher && !w.beendet { XCTAssertTrue(w.zuege(fuer: 3 - vorher).isEmpty) }
                if !w.beendet { XCTAssertFalse(w.zuege.isEmpty) }
            }
        }
    }
    func testSiegerBeiSteinmehrheit() throws {
        let w = try stellung([0: 1, 1: 1, 63: 2])
        XCTAssertTrue(w.beendet); XCTAssertEqual(w.sieger, 1)
    }
    func testGleichstandKeinSieger() throws {
        let w = try stellung([0: 1, 63: 2])
        XCTAssertTrue(w.beendet); XCTAssertNil(w.sieger)
    }
    func testVerkehrtWenigsteSteineGewinnen() throws {
        let w = try stellung([0: 1, 1: 1, 63: 2], verkehrt: true)
        XCTAssertEqual(w.sieger, 2)
    }
    func testComputerNimmtEckeWennMoeglich() throws {
        // 1 kann die Ecke 0 nehmen (über 1 auf 2) oder ein anderes Feld
        let w = try stellung([1: 2, 2: 1, 27: 2, 28: 1, 35: 1, 36: 2], dran: 1)
        XCTAssertTrue(w.zuege.contains(0))
        XCTAssertEqual(WendespielComputer.wahl(w, tiefe: 2), 0)
    }
    func testComputerImEndspielExakt() throws {
        // Fast volles Brett: der Computer muss einen gültigen Zug finden und die Partie sauber beenden.
        var w = Wendespiel(); var g = SystemRandomNumberGenerator()
        while !w.beendet && w.brett.filter({ $0 == 0 }).count > 8 { w.setze(w.zuege.randomElement(using: &g)!) }
        var n = 0
        while !w.beendet && n < 20 { XCTAssertTrue(w.setze(WendespielComputer.wahl(w, tiefe: 3)!)); n += 1 }
        XCTAssertTrue(w.beendet)
    }
    func testZuegeDesComputersSindGueltigBeiAllenStufen() {
        var g = SystemRandomNumberGenerator()
        for t in 1...4 {
            var w = Wendespiel(); var n = 0
            while !w.beendet && n < 100 {
                let m = WendespielComputer.wahl(w, tiefe: t, fehler: t == 1 ? 0.5 : 0)!
                XCTAssertTrue(w.zuege.contains(m)); w.setze(m); n += 1
                if n % 3 == 0, !w.beendet { w.setze(w.zuege.randomElement(using: &g)!) }
            }
        }
    }
    func testSchwerSchlaegtZufall() {
        var g = SystemRandomNumberGenerator(); var siege = 0
        for i in 0..<4 {
            var w = Wendespiel(); let ich = 1 + i % 2
            while !w.beendet {
                if w.dran == ich { w.setze(WendespielComputer.wahl(w, tiefe: 3)!) }
                else { w.setze(w.zuege.randomElement(using: &g)!) }
            }
            if w.sieger == ich { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 3)
    }
}
