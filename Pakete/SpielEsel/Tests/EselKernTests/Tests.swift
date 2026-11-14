// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SpieleKern
@testable import EselKern
final class EselTests: XCTestCase {
    func testAusteilen() {
        var g = SystemRandomNumberGenerator()
        for n in 3...5 { let s = Esel(spieler: n, mit: &g); XCTAssertTrue(s.haende.allSatisfy { $0.count == 4 }); XCTAssertFalse(s.jemandHatVierling) }
    }
    func testReichenBehaeltVierKarten() {
        var g = SystemRandomNumberGenerator(); var s = Esel(spieler: 4, mit: &g)
        s.reiche((0..<4).map { s.computerAbgabe($0, mit: &g) })
        XCTAssertTrue(s.haende.allSatisfy { $0.count == 4 }); XCTAssertEqual(s.runde, 1)
    }
    func testComputerFindenVierlingUndEselWirdBestimmt() {
        for n in 3...5 {
            for _ in 0..<50 {
                var g = SystemRandomNumberGenerator(); var s = Esel(spieler: n, mit: &g); var z = 0
                while !s.jemandHatVierling && z < 500 { s.reiche((0..<n).map { s.computerAbgabe($0, mit: &g) }); z += 1 }
                XCTAssertTrue(s.jemandHatVierling, "\(n) Spieler")
                let erster = (0..<n).first { s.hatVierling($0) }!
                XCTAssertTrue(s.greife(erster))
                for i in (0..<n).shuffled() where i != erster { s.greife(i) }
                XCTAssertTrue(s.vorbei); XCTAssertNotNil(s.esel); XCTAssertEqual(s.griffe.count, n - 1)
            }
        }
    }
    func testGriffOhneVierlingNichtErlaubt() {
        var g = SystemRandomNumberGenerator(); var s = Esel(spieler: 3, mit: &g)
        XCTAssertFalse(s.greife(0))
    }

    private struct Quelle: RandomNumberGenerator {
        var z: UInt64
        mutating func next() -> UInt64 { z &+= 0x9E3779B97F4A7C15; var x = z; x = (x ^ (x >> 30)) &* 0xBF58476D1CE4E5B9; x = (x ^ (x >> 27)) &* 0x94D049BB133111EB; return x ^ (x >> 31) }
    }
    /// Spieler 0 gibt mit der Strategie weiter, die drei anderen zufällig: Spieler 0 hat deutlich öfter zuerst den Vierling als 1 von 4.
    func testStrategieHatOeftererZuerstDenVierling() {
        var vorn = 0; let partien = 600
        for i in 0..<partien {
            var g = Quelle(z: UInt64(i + 3)); var s = Esel(spieler: 4, mit: &g); var z = 0
            while !s.jemandHatVierling && z < 500 {
                var wahl = (0..<4).map { s.haende[$0].indices.randomElement(using: &g)! }
                wahl[0] = s.computerAbgabe(0, mit: &g)
                s.reiche(wahl); z += 1
            }
            if s.hatVierling(0) { vorn += 1 }
        }
        XCTAssertGreaterThan(Double(vorn) / Double(partien), 0.4, "Spieler 0 zuerst: \(vorn) von \(partien)")
    }
}

final class EselRegelTests: XCTestCase {
    private func hand(_ w: [Int]) -> [SkatKarte] { zip(SkatKarte.Farbe.allCases, w).map { SkatKarte($0, $1) } }
    private func vier(_ w: Int) -> [SkatKarte] { SkatKarte.Farbe.allCases.map { SkatKarte($0, w) } }

    func testVierlingErkennen() {
        XCTAssertTrue(Esel.hatVierling(vier(14)))
        XCTAssertFalse(Esel.hatVierling(hand([14, 14, 14, 13])))
        XCTAssertFalse(Esel.hatVierling(Array(vier(14).prefix(3))))
    }
    func testReichenGibtKartenAnDenNachbarnWeiter() {
        var s = Esel(haende: [hand([14, 13, 12, 11]), hand([2, 3, 4, 5]), hand([6, 7, 8, 9])])
        s.reiche([0, 1, 2])
        XCTAssertEqual(s.haende[1].last, SkatKarte(.kreuz, 14), "Spieler 0 gibt an Spieler 1")
        XCTAssertEqual(s.haende[2].last, SkatKarte(.pik, 3)); XCTAssertEqual(s.haende[0].last, SkatKarte(.herz, 8))
        XCTAssertTrue(s.haende.allSatisfy { $0.count == 4 }); XCTAssertEqual(s.runde, 1)
    }
    func testReichenMitFalscherAuswahlzahlTutNichts() {
        var s = Esel(haende: [hand([14, 13, 12, 11]), hand([2, 3, 4, 5]), hand([6, 7, 8, 9])])
        let vorher = s
        s.reiche([0, 1])
        XCTAssertEqual(s, vorher)
    }
    func testNachEinemVierlingWirdNichtMehrGereicht() {
        var s = Esel(haende: [vier(14), hand([2, 3, 4, 5]), hand([6, 7, 8, 9])])
        let vorher = s
        s.reiche([0, 0, 0])
        XCTAssertEqual(s, vorher)
    }
    func testErsterGriffNurMitVierling() {
        var s = Esel(haende: [vier(14), hand([2, 3, 4, 5]), hand([6, 7, 8, 9])])
        XCTAssertFalse(s.greife(1), "Ohne Vierling nicht als Erster")
        XCTAssertTrue(s.greife(0))
        XCTAssertTrue(s.greife(1)); XCTAssertFalse(s.greife(1), "Doppelt greifen zählt nicht")
    }
    func testLetzterNachdemAndereGegriffenHabenIstDerEsel() {
        var s = Esel(haende: [vier(14), hand([2, 3, 4, 5]), hand([6, 7, 8, 9])])
        s.greife(0); s.greife(2)
        XCTAssertTrue(s.vorbei); XCTAssertEqual(s.esel, 1); XCTAssertFalse(s.greife(1))
    }
    func testOhneVierlingGibtEsKeinenGriff() {
        var s = Esel(haende: [hand([14, 13, 12, 11]), hand([2, 3, 4, 5]), hand([6, 7, 8, 9])])
        XCTAssertFalse(s.greife(0)); XCTAssertNil(s.esel)
    }
    func testComputerGibtDieSeltenstenKartenAb() {
        var g = SystemRandomNumberGenerator()
        let s = Esel(haende: [hand([14, 14, 14, 9]), hand([2, 3, 4, 5]), hand([6, 7, 8, 9])])
        for _ in 0..<20 { XCTAssertEqual(s.computerAbgabe(0, mit: &g), 3, "Die einzelne 9 geht weiter") }
    }
    func testRaengeEntsprechenDerSpielerzahl() {
        var g = SystemRandomNumberGenerator()
        for n in 3...5 {
            let s = Esel(spieler: n, mit: &g)
            XCTAssertEqual(Set(s.haende.flatMap { $0.map(\.wert) }).count, n)
        }
        XCTAssertEqual(Esel(spieler: 1, mit: &g).spieler, 3); XCTAssertEqual(Esel(spieler: 9, mit: &g).spieler, 5)
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var s = Esel(spieler: 4, mit: &g); s.reiche([0, 0, 0, 0])
        let neu = try JSONDecoder().decode(Esel.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}
