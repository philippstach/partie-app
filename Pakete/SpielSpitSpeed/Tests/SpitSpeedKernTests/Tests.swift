// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SpieleKern
@testable import SpitSpeedKern

final class SpitSpeedTests: XCTestCase {
    private func k(_ f: SkatKarte.Farbe, _ w: Int) -> SkatKarte { SkatKarte(f, w) }

    func testNachbarn() {
        XCTAssertTrue(SpitSpeed.nachbar(k(.herz, 5), k(.pik, 6)))
        XCTAssertTrue(SpitSpeed.nachbar(k(.herz, 5), k(.pik, 4)))
        XCTAssertTrue(SpitSpeed.nachbar(k(.herz, 14), k(.pik, 2)))      // Ass – Zwei
        XCTAssertTrue(SpitSpeed.nachbar(k(.herz, 14), k(.pik, 13)))     // Ass – König
        XCTAssertFalse(SpitSpeed.nachbar(k(.herz, 5), k(.pik, 7)))
        XCTAssertFalse(SpitSpeed.nachbar(k(.herz, 5), k(.pik, 5)))
    }
    func testAnfang() {
        var g = SystemRandomNumberGenerator(); let s = SpitSpeed(mit: &g)
        for p in 0..<2 { XCTAssertEqual(s.haende[p].count, 5); XCTAssertEqual(s.zieh[p].count, 15); XCTAssertEqual(s.reserve[p].count, 5) }
        XCTAssertEqual(s.mitte[0].count, 1)
    }
    func testLegenUndNachziehen() {
        var s = SpitSpeed(haende: [[k(.herz, 6), k(.herz, 9)], [k(.pik, 2)]], zieh: [[k(.kreuz, 3)], []], mitte: [[k(.karo, 5)], [k(.karo, 10)]])
        XCTAssertFalse(s.lege(0, hand: 1, auf: 0))
        XCTAssertTrue(s.lege(0, hand: 0, auf: 0))
        XCTAssertEqual(s.mitte[0].last, k(.herz, 6)); XCTAssertEqual(s.haende[0].count, 2)   // nachgezogen
    }
    func testGewinn() {
        var s = SpitSpeed(haende: [[k(.herz, 6)], [k(.pik, 2)]], mitte: [[k(.karo, 5)], [k(.karo, 10)]])
        XCTAssertTrue(s.lege(0, hand: 0, auf: 0)); XCTAssertEqual(s.gewinner, 0)
        XCTAssertFalse(s.lege(1, hand: 0, auf: 0))
    }
    func testFestgefahrenUndAufdecken() {
        var g = SystemRandomNumberGenerator()
        var s = SpitSpeed(haende: [[k(.herz, 9)], [k(.pik, 9)]], reserve: [[k(.kreuz, 4)], [k(.kreuz, 8)]], mitte: [[k(.karo, 5)], [k(.karo, 12)]])
        XCTAssertTrue(s.festgefahren)
        XCTAssertTrue(s.neuAufdecken(mit: &g))
        XCTAssertEqual(s.mitte[0].last, k(.kreuz, 4)); XCTAssertEqual(s.mitte[1].last, k(.kreuz, 8))
        XCTAssertTrue(s.hatZug(0))                       // 9 auf 8
        XCTAssertFalse(s.neuAufdecken(mit: &g))          // nicht mehr festgefahren
    }
    func testPartienEnden() {
        for _ in 0..<100 {
            var g = SystemRandomNumberGenerator(); var s = SpitSpeed(mit: &g); var n = 0
            while s.gewinner == nil && n < 20000 {
                n += 1
                let p = Int.random(in: 0..<2, using: &g)
                if let z = SpitSpeedComputer.zug(s, spieler: p) { XCTAssertTrue(s.lege(p, hand: z.hand, auf: z.mitte)) }
                else if s.festgefahren { s.neuAufdecken(mit: &g) }
            }
            XCTAssertNotNil(s.gewinner)
        }
    }
}

final class SpitSpeedSpeichernTests: XCTestCase {
    func testSpielstandUeberlebtDasSpeichern() throws {
        var g = SystemRandomNumberGenerator()
        var s = SpitSpeed(mit: &g)
        for _ in 0..<5 { if let z = SpitSpeedComputer.zug(s, spieler: 0) { s.lege(0, hand: z.hand, auf: z.mitte) } }
        let t = try JSONDecoder().decode(SpitSpeed.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(s, t)
    }
}

final class SpitSpeedRegelnTests: XCTestCase {
    private func k(_ f: SkatKarte.Farbe, _ w: Int) -> SkatKarte { SkatKarte(f, w) }

    func testBlattHat52KartenUndVerteilungStimmt() {
        var g = SystemRandomNumberGenerator(); let s = SpitSpeed(mit: &g)
        let alle = s.haende.flatMap { $0 } + s.zieh.flatMap { $0 } + s.reserve.flatMap { $0 } + s.mitte.flatMap { $0 }
        XCTAssertEqual(alle.count, 52); XCTAssertEqual(Set(alle).count, 52)
    }
    func testKeinZugBeiLeererMitte() {
        let s = SpitSpeed(haende: [[k(.herz, 6)], [k(.pik, 2)]], mitte: [[], []])
        XCTAssertFalse(s.kannLegen(0, hand: 0, auf: 0)); XCTAssertFalse(s.hatZug(0))
    }
    func testUngueltigerHandindexWirdIgnoriert() {
        var s = SpitSpeed(haende: [[k(.herz, 6)], [k(.pik, 2)]], mitte: [[k(.karo, 5)], [k(.karo, 10)]])
        XCTAssertFalse(s.lege(0, hand: 5, auf: 0)); XCTAssertFalse(s.lege(0, hand: -1, auf: 0))
        XCTAssertEqual(s.haende[0].count, 1)
    }
    func testNachziehenBeiLeeremStapelVerkleinertDieHand() {
        var s = SpitSpeed(haende: [[k(.herz, 6), k(.herz, 9)], [k(.pik, 2)]], mitte: [[k(.karo, 5)], [k(.karo, 10)]])
        XCTAssertTrue(s.lege(0, hand: 0, auf: 0)); XCTAssertEqual(s.haende[0].count, 1); XCTAssertNil(s.gewinner)
        XCTAssertEqual(s.restkarten(0), 1)
    }
    func testGewinnErstWennHandUndZiehstapelLeer() {
        var s = SpitSpeed(haende: [[k(.herz, 6)], [k(.pik, 2)]], zieh: [[k(.kreuz, 9)], []], mitte: [[k(.karo, 5)], [k(.karo, 10)]])
        XCTAssertTrue(s.lege(0, hand: 0, auf: 0)); XCTAssertNil(s.gewinner); XCTAssertEqual(s.haende[0], [k(.kreuz, 9)])
    }
    func testAufdeckenNichtMoeglichWennJemandZiehenKann() {
        var g = SystemRandomNumberGenerator()
        var s = SpitSpeed(haende: [[k(.herz, 6)], [k(.pik, 9)]], reserve: [[k(.kreuz, 4)], [k(.kreuz, 8)]], mitte: [[k(.karo, 5)], [k(.karo, 12)]])
        XCTAssertFalse(s.festgefahren); XCTAssertFalse(s.neuAufdecken(mit: &g))
    }
    func testLeereReserveMischtMitteNeuUndBehaeltKarten() {
        var g = SystemRandomNumberGenerator()
        var s = SpitSpeed(haende: [[k(.herz, 9)], [k(.pik, 9)]], reserve: [[], []],
                          mitte: [[k(.karo, 2), k(.karo, 3), k(.karo, 5)], [k(.karo, 12), k(.kreuz, 7), k(.kreuz, 12)]])
        let vorher = s.mitte.flatMap { $0 }.count
        XCTAssertTrue(s.neuAufdecken(mit: &g))
        XCTAssertEqual(s.mitte.flatMap { $0 }.count + s.reserve.flatMap { $0 }.count, vorher)
        XCTAssertEqual(s.mitte[0].count, 2); XCTAssertEqual(s.mitte[1].count, 2)
    }
    func testComputerZugIstInJederStufeLegal() {
        var g = SystemRandomNumberGenerator()
        for stufe in 1...3 { for _ in 0..<50 {
            let s = SpitSpeed(mit: &g)
            if let z = SpitSpeedComputer.zug(s, spieler: 0, stufe: stufe) { XCTAssertTrue(s.kannLegen(0, hand: z.hand, auf: z.mitte)) }
        } }
    }
    func testSchwerPlantEineKetteVoraus() {
        // Hand 4, 6, 7 auf der 5: Die 4 wäre eine Sackgasse, die 6 öffnet die Kette 6, 7.
        let s = SpitSpeed(haende: [[k(.herz, 4), k(.herz, 6), k(.herz, 7)], [k(.pik, 2)]], mitte: [[k(.karo, 5)], [k(.karo, 13)]])
        let z = SpitSpeedComputer.zug(s, spieler: 0, stufe: 3)!
        XCTAssertEqual(s.haende[0][z.hand], k(.herz, 6)); XCTAssertEqual(z.mitte, 0)
    }
    func testSchwerSchlaegtLeichtImSpiegel() {
        // Beide spielen abwechselnd; schwer räumt die Hand öfter zuerst leer als leicht.
        var schwer = 0, leicht = 0
        for i in 0..<300 {
            var g = SystemRandomNumberGenerator(); var s = SpitSpeed(mit: &g); var n = 0
            let schwerSeite = i % 2
            while s.gewinner == nil && n < 20000 {
                n += 1
                let p = n % 2
                if let z = SpitSpeedComputer.zug(s, spieler: p, stufe: p == schwerSeite ? 3 : 1) { s.lege(p, hand: z.hand, auf: z.mitte) }
                else if s.festgefahren { s.neuAufdecken(mit: &g) }
            }
            if s.gewinner == schwerSeite { schwer += 1 } else if s.gewinner != nil { leicht += 1 }
        }
        XCTAssertGreaterThan(schwer, leicht, "schwer \(schwer) leicht \(leicht)")
    }
}
