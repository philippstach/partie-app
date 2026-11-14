// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SiebzehnKern

/// T-085: Hat die Bank mit den ersten zwei Karten Siebzehn und Vier, wird sofort aufgedeckt und abgerechnet. Nicht syntaxgeprüft.
final class BankBlackjackTests: XCTestCase {
    func testBankBlackjackRechnetSofortAb() {
        var g = SystemRandomNumberGenerator()
        var s = Siebzehn(spieler: 2)
        var gesehen = 0
        for _ in 0..<2000 {
            if s.aktive.count < 2 { s = Siebzehn(spieler: 2) }
            s.austeilen(mit: &g)
            if istBlackjack(s.bank) {
                gesehen += 1
                XCTAssertTrue(s.vorbei); XCTAssertTrue(s.bankDran)
                XCTAssertEqual(s.bank.count, 2)
                XCTAssertEqual(s.ausgaenge.count, 2)
            }
            while !s.vorbei {
                if s.spieler[s.dran].count >= 2 { s.halten() } else { break }
            }
        }
        XCTAssertGreaterThan(gesehen, 0)
    }
}
