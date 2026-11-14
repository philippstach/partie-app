// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SiebzehnKern

final class SiebzehnTests: XCTestCase {
    func testComputerZugGrundstrategie() {   // K-011/M-013
        XCTAssertTrue(Siebzehn.computerNimmtKarte(hand: [SKarte(0, 7), SKarte(1, 8)], bankOffen: 10))    // 15 gegen 10: Karte
        XCTAssertFalse(Siebzehn.computerNimmtKarte(hand: [SKarte(0, 7), SKarte(1, 8)], bankOffen: 5))    // 15 gegen 5: halten
        XCTAssertFalse(Siebzehn.computerNimmtKarte(hand: [SKarte(0, 7), SKarte(1, 7)], bankOffen: 2))    // 14 gegen 2: halten
        XCTAssertTrue(Siebzehn.computerNimmtKarte(hand: [SKarte(0, 8), SKarte(1, 7)].prefix(1).map { $0 }, bankOffen: 2))   // 8: immer Karte
        XCTAssertFalse(Siebzehn.computerNimmtKarte(hand: [SKarte(0, 10), SKarte(1, 13)], bankOffen: 11)) // 20: halten
        // Ein ganzer Durchgang nur mit Computerzügen endet immer
        var g = SystemRandomNumberGenerator(); var s = Siebzehn(spieler: 3)
        s.austeilen(mit: &g)
        var n = 0
        while !s.vorbei && n < 100 {
            if Siebzehn.computerNimmtKarte(hand: s.spieler[s.dran], bankOffen: s.bank.first?.augen ?? 10) { s.karte() } else { s.halten() }
            n += 1
        }
        XCTAssertTrue(s.vorbei)
    }
    func testSumme() {
        XCTAssertEqual(siebzehnSumme([SKarte(0, 14), SKarte(1, 13)]), 21)
        XCTAssertEqual(siebzehnSumme([SKarte(0, 14), SKarte(1, 14), SKarte(2, 9)]), 21)
        XCTAssertEqual(siebzehnSumme([SKarte(0, 10), SKarte(1, 13), SKarte(2, 9)]), 29)
        XCTAssertTrue(istBlackjack([SKarte(0, 14), SKarte(3, 12)])); XCTAssertFalse(istBlackjack([SKarte(0, 7), SKarte(3, 7), SKarte(1, 7)]))
    }
    func testRundeChipsSumme() {
        var g = SystemRandomNumberGenerator(); var s = Siebzehn(spieler: 2)
        for _ in 0..<50 {
            s.austeilen(mit: &g)
            var n = 0
            while !s.vorbei && n < 50 { if siebzehnSumme(s.spieler[s.dran]) < 15 { s.karte() } else { s.halten() }; n += 1 }
            XCTAssertTrue(s.vorbei); XCTAssertEqual(s.ausgaenge.count, 2)
            XCTAssertTrue(siebzehnSumme(s.bank) >= 17 || s.aktive.allSatisfy { siebzehnSumme(s.spieler[$0]) > 21 })
            if s.aktive.count < 2 { break }
        }
    }
    func testAssWirdZuEins() {
        XCTAssertEqual(siebzehnSumme([SKarte(0, 14), SKarte(1, 14), SKarte(2, 14), SKarte(3, 14)]), 14)
        XCTAssertEqual(siebzehnSumme([SKarte(0, 14), SKarte(1, 9), SKarte(2, 9)]), 19)
        XCTAssertEqual(siebzehnSumme([]), 0)
    }
    func testKartenwerteUndStapel() {
        XCTAssertEqual(SKarte.alle.count, 32); XCTAssertEqual(Set(SKarte.alle).count, 32)
        XCTAssertEqual(SKarte(0, 12).augen, 10); XCTAssertEqual(SKarte(0, 14).augen, 11)
    }
    func testChipsBleibenErhalten() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            var s = Siebzehn(spieler: 1, chips: 100)
            s.austeilen(mit: &g)
            while !s.vorbei { s.halten() }
            let erwartet: Int
            switch s.ausgaenge[0] { case .gewinn: erwartet = 110; case .blackjack: erwartet = 115; case .verlust: erwartet = 90; case .unentschieden: erwartet = 100 }
            XCTAssertEqual(s.chips[0], erwartet)
        }
    }
    func testPleiteSpielerWirdUebersprungen() {
        var g = SystemRandomNumberGenerator()
        var s = Siebzehn(spieler: 2, chips: 5)   // unter dem Einsatz
        s.austeilen(mit: &g)
        XCTAssertTrue(s.aktive.isEmpty); XCTAssertTrue(s.spieler.allSatisfy(\.isEmpty))
    }
    func testAktionenNachRundeEndeSindWirkungslos() {
        var g = SystemRandomNumberGenerator(); var s = Siebzehn(spieler: 1)
        s.austeilen(mit: &g); while !s.vorbei { s.halten() }
        let k = s.spieler[0].count; s.karte(); s.halten()
        XCTAssertEqual(s.spieler[0].count, k)
    }
}

final class SiebzehnRegelTests: XCTestCase {
    func testBankZiehtBisMindestensSiebzehn() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            var s = Siebzehn(spieler: 1)
            s.austeilen(mit: &g)
            while !s.vorbei { s.halten() }
            XCTAssertGreaterThanOrEqual(siebzehnSumme(s.bank), 17)
        }
    }
    func testBankZiehtNichtWennAlleSpielerUeberkauft() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<300 {
            var s = Siebzehn(spieler: 1)
            s.austeilen(mit: &g)
            while !s.vorbei && siebzehnSumme(s.spieler[0]) <= 21 { s.karte() }
            if s.vorbei && siebzehnSumme(s.spieler[0]) > 21 {
                XCTAssertEqual(s.bank.count, 2, "Die Bank muss nicht mehr ziehen")
                XCTAssertEqual(s.ausgaenge[0], .verlust); XCTAssertEqual(s.chips[0], 90)
            }
        }
    }
    func testZweiAssesZaehlenZwoelf() {
        XCTAssertEqual(siebzehnSumme([SKarte(0, 14), SKarte(1, 14)]), 12)
        XCTAssertFalse(istBlackjack([SKarte(0, 14), SKarte(1, 14)]))
    }
    func testDreiKartenMit21SindKeinBlackjack() {
        let h = [SKarte(0, 7), SKarte(1, 7), SKarte(2, 7)]
        XCTAssertEqual(siebzehnSumme(h), 21); XCTAssertFalse(istBlackjack(h))
    }
    func testKartenwerte() {
        XCTAssertEqual(SKarte(0, 7).augen, 7); XCTAssertEqual(SKarte(1, 10).augen, 10)
        XCTAssertEqual(SKarte(2, 11).augen, 10); XCTAssertEqual(SKarte(3, 13).augen, 10)
        XCTAssertEqual(SKarte(0, 11).name, "B"); XCTAssertEqual(SKarte(0, 14).name, "A"); XCTAssertEqual(SKarte(0, 8).symbol, "♣")
    }
    func testAusteilenGibtJedemZweiKartenUndDerBankZwei() {
        var g = SystemRandomNumberGenerator()
        let s = Siebzehn(spieler: 3, mit: &g)
        XCTAssertEqual(s.chips, [100, 100, 100])
        XCTAssertEqual(s.spieler.map(\.count), [2, 2, 2]); XCTAssertEqual(s.bank.count, 2)
        XCTAssertEqual(s.stapel.count, 32 - 8)
    }
    func testZweiSpielerGleicheChipsSummeNachHand() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<100 {
            var s = Siebzehn(spieler: 2)
            s.austeilen(mit: &g)
            while !s.vorbei { s.halten() }
            XCTAssertTrue(s.chips.allSatisfy { [85 + 5, 100, 110, 115, 90].contains($0) })
        }
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var s = Siebzehn(spieler: 2, mit: &g); s.karte()
        let neu = try JSONDecoder().decode(Siebzehn.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}

final class SiebzehnAlleinTests: XCTestCase {
    /// Allein gespielt ist nur pleite eine Niederlage; alles andere ist ein Punktespiel mit dem Chip-Stand.
    func testAlleinVerlorenNurOhneEinsatz() {
        XCTAssertTrue(Siebzehn.alleinVerloren(chips: 0))
        XCTAssertTrue(Siebzehn.alleinVerloren(chips: 5), "Rest unter dem Einsatz: es geht nicht weiter")
        XCTAssertFalse(Siebzehn.alleinVerloren(chips: Siebzehn.einsatz))
        XCTAssertFalse(Siebzehn.alleinVerloren(chips: 100))
        XCTAssertFalse(Siebzehn.alleinVerloren(chips: 60), "weniger als zu Beginn ist kein Verlust, sondern ein niedriger Punktestand")
    }
    func testPleiteHeisstKeineAktivenSpielerMehr() {
        var g = SystemRandomNumberGenerator()
        var s = Siebzehn(spieler: 1, chips: 10, mit: &g); var runden = 0
        while !Siebzehn.alleinVerloren(chips: s.chips[0]), runden < 2000 {
            while !s.vorbei { s.karte() }   // absichtlich überkaufen
            if !Siebzehn.alleinVerloren(chips: s.chips[0]) { s.austeilen(mit: &g) }
            runden += 1
        }
        XCTAssertTrue(Siebzehn.alleinVerloren(chips: s.chips[0])); XCTAssertTrue(s.aktive.isEmpty)
    }

    // MARK: 1.0 (M5) Einsatz und Verdoppeln
    func testEinsatzWirdAbgerechnet() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            var s = Siebzehn(spieler: 1, chips: 200, einsatz: 50, mit: &g)
            let vorher = s.chips[0]
            while !s.vorbei { s.halten() }
            let d = s.chips[0] - vorher
            XCTAssertTrue([0, 50, 75, -50].contains(d), "Unerwartete Auszahlung \(d)")
        }
    }
    func testNurErlaubteEinsaetze() {
        var s = Siebzehn(spieler: 1, chips: 100)
        s.setzeEinsatz(33); XCTAssertEqual(s.einsatzJeHand, 10)
        s.setzeEinsatz(25); XCTAssertEqual(s.einsatzJeHand, 25)
        XCTAssertEqual(s.moeglicheEinsaetze, [10, 25, 50, 100])
        XCTAssertEqual(Siebzehn(spieler: 1, chips: 50).moeglicheEinsaetze, [10, 25, 50])
        XCTAssertEqual(Siebzehn(spieler: 2, chips: 100).moeglicheEinsaetze, [10, 25, 50, 100])
    }
    func testVerdoppelnNurMitZweiKartenUndGenugChips() {
        var g = SystemRandomNumberGenerator()
        var s = Siebzehn(spieler: 1, chips: 15, einsatz: 10, mit: &g)
        XCTAssertFalse(s.kannVerdoppeln, "15 Chips reichen nicht für doppelten Einsatz 20")
        var t = Siebzehn(spieler: 1, chips: 100, einsatz: 10)
        t.austeilen(mit: &g)
        if t.kannVerdoppeln { t.verdoppeln(); XCTAssertEqual(t.spieler[0].count, 3); XCTAssertTrue(t.verdoppelt[0]); XCTAssertTrue(t.vorbei) }
        s.halten(); XCTAssertFalse(s.kannVerdoppeln)
    }
    func testVerdoppelnZahltDoppelt() {
        var g = SystemRandomNumberGenerator()
        var gesehen = false
        for _ in 0..<500 where !gesehen {
            var s = Siebzehn(spieler: 1, chips: 100, einsatz: 25, mit: &g)
            guard s.kannVerdoppeln else { continue }
            gesehen = true
            let vorher = s.chips[0]
            s.verdoppeln()
            XCTAssertTrue(s.vorbei); XCTAssertEqual(s.spieler[0].count, 3)
            let d = s.chips[0] - vorher
            XCTAssertTrue([0, 50, -50].contains(d), "doppelter Einsatz erwartet, war \(d)")
        }
        XCTAssertTrue(gesehen)
    }
    func testComputerVerdoppeltGrundstrategie() {   // RT-002: Schwellen fürs 32-Karten-Blatt
        func hand(_ a: Int, _ b: Int) -> [SKarte] { [SKarte(0, a), SKarte(1, b)] }
        XCTAssertTrue(Siebzehn.computerVerdoppelt(hand: hand(14, 7), bankOffen: 7))     // Ass + 7 gegen 7
        XCTAssertFalse(Siebzehn.computerVerdoppelt(hand: hand(14, 7), bankOffen: 8))    // Ass + 7 gegen 8
        XCTAssertTrue(Siebzehn.computerVerdoppelt(hand: hand(14, 8), bankOffen: 8))     // Ass + 8 gegen 8
        XCTAssertFalse(Siebzehn.computerVerdoppelt(hand: hand(14, 8), bankOffen: 9))
        XCTAssertTrue(Siebzehn.computerVerdoppelt(hand: hand(14, 9), bankOffen: 9))     // Ass + 9 gegen 9
        XCTAssertFalse(Siebzehn.computerVerdoppelt(hand: hand(14, 9), bankOffen: 10))
        XCTAssertFalse(Siebzehn.computerVerdoppelt(hand: hand(7, 8), bankOffen: 7))     // 15 ohne Ass: nie
        XCTAssertFalse(Siebzehn.computerVerdoppelt(hand: hand(10, 13), bankOffen: 7))   // 20 ohne Ass: nie
        XCTAssertFalse(Siebzehn.computerVerdoppelt(hand: hand(14, 14), bankOffen: 7))   // zwei Asse
        XCTAssertFalse(Siebzehn.computerVerdoppelt(hand: hand(14, 10), bankOffen: 7))   // 21: Siebzehn und Vier
        // Mit dem echten Blatt kommt Verdoppeln vor (vorher nie)
        var g = SystemRandomNumberGenerator(); var gesehen = false
        for _ in 0..<2000 where !gesehen {
            let s = Siebzehn(spieler: 1, mit: &g)
            if s.kannVerdoppeln, Siebzehn.computerVerdoppelt(hand: s.spieler[0], bankOffen: s.bank[0].augen) { gesehen = true }
        }
        XCTAssertTrue(gesehen)
    }
    func testAlterStandLaesstSichLesen() throws {
        var g = SystemRandomNumberGenerator(); let s = Siebzehn(spieler: 2, mit: &g)
        var j = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as! [String: Any]
        j["einsatzJeHand"] = nil; j["verdoppelt"] = nil
        let neu = try JSONDecoder().decode(Siebzehn.self, from: JSONSerialization.data(withJSONObject: j))
        XCTAssertEqual(neu.einsatzJeHand, 10); XCTAssertEqual(neu.verdoppelt, [false, false]); XCTAssertEqual(neu.chips, s.chips)
    }
}
