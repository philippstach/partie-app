// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSchwimmen

struct Saat: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s ^ (s >> 29) }
}

final class KernTests: XCTestCase {
    typealias K = SwKarte
    let std = SchwimmenRegeln.standard

    func testPunkte() {
        XCTAssertEqual(swPunkte([K(2, 14), K(2, 13), K(2, 10)], std), 31)
        XCTAssertEqual(swPunkte([K(2, 14), K(1, 14), K(3, 14)], std), 30.5)
        var r = std; r.dreiGleiche = 30
        XCTAssertEqual(swPunkte([K(2, 9), K(1, 9), K(3, 9)], r), 30)
        XCTAssertEqual(swPunkte([K(2, 7), K(1, 8), K(2, 9)], std), 16)
        XCTAssertEqual(swBesteFarbe([K(2, 7), K(1, 8), K(2, 9)]), 2)
        XCTAssertNil(swBesteFarbe([K(2, 9), K(1, 9), K(3, 9)]))
    }

    func testDreiAssen33UndFeuer() {
        var r = std; r.dreiAssen33 = true
        let asse = [K(0, 14), K(1, 14), K(2, 14)]
        XCTAssertEqual(swPunkte(asse, r), 33); XCTAssertTrue(swIstFeuer(asse, r))
        XCTAssertEqual(swPunkte(asse, std), 30.5); XCTAssertFalse(swIstFeuer(asse, std))
        XCTAssertTrue(swIstFeuer([K(2, 14), K(2, 13), K(2, 10)], std))
        XCTAssertFalse(swIstFeuer([K(2, 9), K(1, 9), K(3, 9)], r), "Nur drei Asse sind 33")
    }

    func testFeuerBeendetRundeSofortUndKostetLeben() {
        var s = SchwimmenNeu(regeln: std, leben: [3, 3, 3], hand: [[K(2, 14), K(2, 13), K(0, 7)], [K(0, 8), K(1, 9), K(2, 10)], [K(0, 9), K(1, 10), K(2, 8)]],
                             tisch: [K(2, 10), K(1, 7), K(3, 8)], dran: 0)
        s.tauscheEine(hand: 2, tisch: 0)
        XCTAssertTrue(s.rundeVorbei); XCTAssertEqual(s.feuerVon, 0)
        XCTAssertEqual(s.leben, [3, 2, 2])
    }

    func testFeuerNurBeimKlopfen() {
        var r = std; r.feuerSofort = false
        var s = SchwimmenNeu(regeln: r, leben: [3, 3], hand: [[K(2, 14), K(2, 13), K(0, 7)], [K(0, 8), K(1, 9), K(2, 10)]], tisch: [K(2, 10), K(1, 7), K(3, 8)], dran: 0)
        s.tauscheEine(hand: 2, tisch: 0)
        XCTAssertFalse(s.rundeVorbei)
        XCTAssertEqual(s.dran, 1)
    }

    func testKlopfenLetzteRundeUndNiedrigsterVerliert() {
        var s = SchwimmenNeu(regeln: std, leben: [3, 3, 3], hand: [[K(2, 14), K(2, 9), K(0, 7)], [K(0, 8), K(1, 9), K(2, 10)], [K(0, 9), K(1, 10), K(2, 8)]], tisch: [K(2, 10), K(1, 7), K(3, 8)], dran: 0)
        s.klopfen(); XCTAssertEqual(s.klopfer, 0); XCTAssertFalse(s.kannKlopfen)
        s.schieben(); XCTAssertFalse(s.rundeVorbei)
        s.schieben(); XCTAssertTrue(s.rundeVorbei)
        XCTAssertEqual(s.punkte, [20, 10, 10])
        XCTAssertEqual(s.verlierer, [1, 2]); XCTAssertEqual(s.leben, [3, 2, 2])
    }

    func testGleichstandOhneLebensverlust() {
        var s = SchwimmenNeu(regeln: std, leben: [3, 3], hand: [[K(0, 7), K(1, 8), K(2, 9)], [K(0, 9), K(1, 7), K(2, 8)]], tisch: [K(2, 10), K(1, 7), K(3, 8)], dran: 0)
        s.klopfen(); s.schieben()
        XCTAssertTrue(s.rundeVorbei); XCTAssertEqual(s.leben, [3, 3]); XCTAssertEqual(s.verlierer, [])
    }

    func testSchiebenLimit() {
        var r = std; r.schiebenLimit = 1
        var s = SchwimmenNeu(regeln: r, leben: [3, 3], hand: [[K(0, 7), K(1, 8), K(2, 9)], [K(0, 9), K(1, 7), K(2, 8)]], tisch: [K(2, 10), K(1, 7), K(3, 8)], dran: 0)
        XCTAssertTrue(s.schieben()); XCTAssertTrue(s.schieben())
        XCTAssertFalse(s.kannSchieben, "Spieler 0 hat sein eines Schieben verbraucht")
        XCTAssertFalse(s.schieben())
    }

    func testSchwimmenUndAusscheiden() {
        var s = SchwimmenNeu(regeln: std, leben: [0, 1], hand: [[K(0, 7), K(1, 8), K(2, 9)], [K(0, 14), K(0, 13), K(2, 10)]], tisch: [K(2, 10), K(1, 7), K(3, 8)], dran: 0)
        XCTAssertTrue(s.schwimmt(0))
        s.klopfen(); s.schieben()
        XCTAssertEqual(s.leben[0], -1); XCTAssertEqual(s.sieger, 1)
    }

    func testPunktemodusSummeUndEnde() {
        var r = std; r.modus = .punkte; r.runden = 2
        var g = Saat(s: 5)
        var s = SchwimmenNeu(spieler: 3, regeln: r, mit: &g)
        var guardZaehler = 0
        while !s.spielZuEnde && guardZaehler < 20000 {
            if s.rundeVorbei { s.neueRunde(mit: &g) } else { s.fuehreAus(s.computerWahl(stufe: 2, mit: &g)) }
            guardZaehler += 1
        }
        XCTAssertTrue(s.spielZuEnde); XCTAssertEqual(s.runde, 2)
        XCTAssertNotNil(s.sieger)
        XCTAssertEqual(s.rangfolge.first, s.sieger)
        XCTAssertGreaterThan(s.summen.reduce(0, +), 0)
    }

    func testVorschau() {
        let s = SchwimmenNeu(regeln: std, leben: [3, 3], hand: [[K(2, 7), K(2, 8), K(0, 9)], [K(0, 9), K(1, 7), K(2, 8)]], tisch: [K(2, 14), K(1, 7), K(3, 8)], dran: 0)
        XCTAssertEqual(s.vorschauEine(hand: 2, tisch: 0), 26)
        XCTAssertEqual(s.vorschauAlle(), 11)
    }

    func testComputerSpieltAlleVariantenZuEnde() {
        for seed in 1...40 as ClosedRange<UInt64> {
            var g = Saat(s: seed)
            var r = std
            r.leben = seed % 2 == 0 ? 4 : 3
            r.feuerSofort = seed % 3 != 0
            r.dreiAssen33 = seed % 5 == 0
            r.schiebenLimit = seed % 4 == 0 ? 1 : nil
            r.dreiGleiche = seed % 7 == 0 ? 30 : 30.5
            if seed % 6 == 0 { r.modus = .punkte; r.runden = 3 }
            var s = SchwimmenNeu(spieler: 2 + Int(seed % 5), regeln: r, mit: &g)
            var n = 0
            while !s.spielZuEnde && n < 50000 {
                if s.rundeVorbei { s.neueRunde(mit: &g) }
                else { XCTAssertTrue(s.fuehreAus(s.computerWahl(stufe: Int(seed % 3) + 1, mit: &g)), "seed \(seed)") }
                n += 1
            }
            XCTAssertTrue(s.spielZuEnde, "seed \(seed) endet nicht")
        }
    }

    /// B18 (F-AWS-K-005): „Zweimal sofort 31“ war ein Zufallstreffer, kein Mischfehler. Beim Austeilen ist 31 für eine Hand etwa
    /// 0,5 % wahrscheinlich (24 von 4960 Händen); bei zwei Spielern also rund 1 % der Runden.
    func testSofort31BeimAusteilenIstSelten() {
        var g = SystemRandomNumberGenerator()
        let runden = 20000
        var feuer = 0
        for _ in 0..<runden { if SchwimmenNeu(spieler: 2, regeln: std, mit: &g).feuerVon != nil { feuer += 1 } }
        let anteil = Double(feuer) / Double(runden)
        XCTAssertGreaterThan(anteil, 0.003); XCTAssertLessThan(anteil, 0.02)
    }

    /// Jede Karte kommt in jeder Runde genau einmal vor (Hände, Tisch, Stapel), auch nach dem Mischen mit dem Systemgenerator.
    func testAusteilenVerteiltAlle32KartenEinmal() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            let s = SchwimmenNeu(spieler: 3, regeln: std, mit: &g)
            let alle = s.hand.flatMap { $0 } + s.tisch + s.stapel
            XCTAssertEqual(Set(alle).count, 32); XCTAssertEqual(alle.count, 32)
        }
    }

    func testCodable() throws {
        var g = Saat(s: 3)
        let s = SchwimmenNeu(spieler: 4, regeln: std, mit: &g)
        XCTAssertEqual(try JSONDecoder().decode(SchwimmenNeu.self, from: JSONEncoder().encode(s)), s)
    }
}
