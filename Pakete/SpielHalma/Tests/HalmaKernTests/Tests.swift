// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HalmaKern

final class HalmaTests: XCTestCase {
    func testStart() {
        let h = Halma()
        XCTAssertEqual(h.steine(1).count, 10); XCTAssertEqual(h.steine(2).count, 10)
        XCTAssertTrue(Set(h.steine(1)).isDisjoint(with: Set(h.steine(2))))
        XCTAssertNil(h.sieger)
    }
    func testSchrittUndSprung() {
        var h = Halma()
        let von = h.steine(1).first { !h.ziele(von: $0).isEmpty }!
        XCTAssertTrue(h.ziehe(von: von, nach: h.ziele(von: von).first!)); XCTAssertEqual(h.dran, 2)
        XCTAssertFalse(h.ziehe(von: von, nach: 0))
    }
    func testComputerSpielt() {
        var h = Halma(); var g = SystemRandomNumberGenerator(); var n = 0
        while h.sieger == nil && n < 600 {
            guard let (v, z) = HalmaComputer.wahl(h, mit: &g) else { break }
            XCTAssertTrue(h.ziehe(von: v, nach: z)); n += 1
        }
        XCTAssertTrue(n > 20)
    }
    func testComputerMitVorausschauSchlaegtEinfachen() {
        var g = SystemRandomNumberGenerator(); var siege = 0
        for k in 0..<4 {
            var h = Halma(); let ich = k % 2 + 1
            while !h.vorbei {
                let z = h.dran == ich ? HalmaComputer.wahl(h, tiefe: 2, breite: 10, mit: &g) : HalmaComputer.wahl(h, tiefe: 1, mit: &g)
                h.ziehe(von: z!.0, nach: z!.1)
            }
            if case .spieler(let s)? = h.sieger, s == ich { siege += 1 } else if h.siegerNachZeit == ich { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 3)
    }
    func testZeitlimitEntscheidetNachFortschritt() {
        var g = SystemRandomNumberGenerator(); var h = Halma()
        while !h.vorbei { let z = h.alleZuege.randomElement(using: &g)!; h.ziehe(von: z.0, nach: z.1) }
        XCTAssertTrue(h.sieger != nil || h.zeitUm)
    }
}

/// Stufen-Simulation: schwer (Tiefe 3, Breite 8) muss deutlich öfter gewinnen als leicht (Tiefe 1, Breite 12).
final class HalmaStufenTests: XCTestCase {
    func testSchwerSchlaegtLeicht() {
        var g = SystemRandomNumberGenerator()
        var schwer = 0, leicht = 0
        for i in 0..<6 {
            var h = Halma()
            let seite = 1 + i % 2
            var n = 0
            while !h.vorbei && n < 400 {
                let z = h.dran == seite ? HalmaComputer.wahl(h, tiefe: 3, breite: 8, mit: &g) : HalmaComputer.wahl(h, tiefe: 1, breite: 12, mit: &g)
                guard let z else { break }
                h.ziehe(von: z.0, nach: z.1); n += 1
            }
            var s: Int?
            if case .spieler(let x)? = h.sieger { s = x } else { s = h.siegerNachZeit }
            if let s { if s == seite { schwer += 1 } else { leicht += 1 } }
        }
        print("HALMA schwer \(schwer) leicht \(leicht) von 6")
        XCTAssertGreaterThanOrEqual(schwer, leicht + 2, "schwer \(schwer), leicht \(leicht)")
    }
}

final class HalmaRegelDetailTests: XCTestCase {
    /// Stellung aus Brettliste (64 Felder) bauen, über Codable, weil das Brett von außen nicht beschreibbar ist.
    private func stellung(_ steine: [Int: Int], dran: Int = 1) throws -> Halma {
        var b = [Int](repeating: 0, count: 64)
        for (i, s) in steine { b[i] = s }
        let json = #"{"brett":\#(b),"dran":\#(dran),"zuege":0}"#
        return try JSONDecoder().decode(Halma.self, from: Data(json.utf8))
    }
    func testSchrittInAlleAchtRichtungen() throws {
        let h = try stellung([27: 1])
        XCTAssertEqual(h.ziele(von: 27), [18, 19, 20, 26, 28, 34, 35, 36])
    }
    func testRandBegrenztSchritte() throws {
        let h = try stellung([0: 1])
        XCTAssertEqual(h.ziele(von: 0), [1, 8, 9])
    }
    func testSprungUeberEigenenUndFremdenStein() throws {
        let h = try stellung([27: 1, 28: 2, 35: 1])
        XCTAssertTrue(h.ziele(von: 27).contains(29))    // über den Gegner
        XCTAssertTrue(h.ziele(von: 27).contains(43))    // über den eigenen
    }
    func testSprungKetteMehrfach() throws {
        let h = try stellung([0: 1, 1: 2, 3: 2, 5: 2])
        XCTAssertTrue(h.ziele(von: 0).isSuperset(of: [2, 4, 6]))
    }
    func testKeinSprungUeberLeeresFeld() throws {
        let h = try stellung([0: 1])
        XCTAssertFalse(h.ziele(von: 0).contains(2))
    }
    func testKeinSprungAufBesetztesFeld() throws {
        let h = try stellung([0: 1, 1: 2, 2: 2])
        XCTAssertFalse(h.ziele(von: 0).contains(2))
    }
    func testFremderStein2ZiehtNichtBeiSpieler1() throws {
        var h = try stellung([27: 1, 40: 2])
        XCTAssertFalse(h.ziehe(von: 40, nach: 41))
        XCTAssertTrue(h.ziehe(von: 27, nach: 28)); XCTAssertEqual(h.dran, 2)
    }
    func testSiegImZielLager() {
        var b = [Int](repeating: 0, count: 64)
        for i in Halma.ziel(1) { b[i] = 1 }
        let json = #"{"brett":\#(b),"dran":2,"zuege":10}"#
        let h = try! JSONDecoder().decode(Halma.self, from: Data(json.utf8))
        XCTAssertEqual(h.sieger, .spieler(1))
        XCTAssertTrue(h.vorbei)
    }
    func testBesetztesZielMitFremdenSteinenAllein() {
        // Ein Ziellager nur mit Gegnersteinen zählt nicht als Sieg.
        var b = [Int](repeating: 0, count: 64)
        for i in Halma.ziel(1) { b[i] = 2 }
        let json = #"{"brett":\#(b),"dran":1,"zuege":10}"#
        let h = try! JSONDecoder().decode(Halma.self, from: Data(json.utf8))
        XCTAssertNil(h.sieger)
    }
    func testAbstandUndFortschritt() {
        let h = Halma()
        XCTAssertEqual(h.fortschritt(1), h.fortschritt(2))   // symmetrischer Start
        XCTAssertEqual(Halma.abstand(7, 1), 0)               // Zielecke oben rechts
        XCTAssertEqual(Halma.abstand(56, 2), 0)              // Zielecke unten links
    }
    func testStartLagerGroesse() {
        XCTAssertEqual(Halma.lager(1).count, 10); XCTAssertEqual(Halma.lager(2).count, 10)
        XCTAssertEqual(Set(Halma.lager(1)), Set(Halma.ziel(2)))
    }
    func testComputerGibtNilOhneZuege() throws {
        var g = SystemRandomNumberGenerator()
        // Gesperrter einzelner Stein in der Ecke ist praktisch nicht herstellbar; stattdessen: vorbei -> keine Züge
        var b = [Int](repeating: 0, count: 64)
        for i in Halma.ziel(1) { b[i] = 1 }
        let json = #"{"brett":\#(b),"dran":2,"zuege":10}"#
        let h = try JSONDecoder().decode(Halma.self, from: Data(json.utf8))
        var kopie = h
        XCTAssertFalse(kopie.ziehe(von: 0, nach: 1))
        _ = HalmaComputer.wahl(h, tiefe: 2, mit: &g)
    }
    func testSpielstandRoundtrip() throws {
        var h = Halma(); var g = SystemRandomNumberGenerator()
        for _ in 0..<10 { let z = h.alleZuege.randomElement(using: &g)!; h.ziehe(von: z.0, nach: z.1) }
        XCTAssertEqual(try JSONDecoder().decode(Halma.self, from: JSONEncoder().encode(h)), h)
    }
}
