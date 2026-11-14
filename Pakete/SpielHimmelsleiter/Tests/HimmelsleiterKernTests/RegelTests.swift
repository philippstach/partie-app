// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HimmelsleiterKern

final class HimmelsleiterRegelTests: XCTestCase {
    func testNormalerZugWechseltSpieler() {
        var s = Himmelsleiter(spieler: 2)
        s.zug(wurf: 2)
        XCTAssertEqual(s.positionen, [2, 0]); XCTAssertEqual(s.amZug, 1)
    }

    func testLeiterBringtNachOben() {
        var s = Himmelsleiter(spieler: 2)
        s.zug(wurf: 4)
        XCTAssertEqual(s.positionen[0], 27); XCTAssertEqual(s.meldung, "Leiter hinauf!")
    }

    func testRutscheBringtNachUnten() {
        var s = Himmelsleiter(spieler: 2)
        s.zug(wurf: 4)      // 27 (Leiter)
        s.zug(wurf: 1)      // zweiter Spieler: 1
        s.zug(wurf: 2)      // 29 → Rutsche nach 9
        XCTAssertEqual(s.positionen[0], 9); XCTAssertEqual(s.meldung, "Wolkenrutsche hinab!")
    }

    func testSechsGibtExtrawurf() {
        var s = Himmelsleiter(spieler: 2)
        s.zug(wurf: 6)
        XCTAssertEqual(s.amZug, 0); XCTAssertTrue(s.meldung.contains("Extrawurf"))
    }

    func testDreimalSechsSetztAus() {
        var s = Himmelsleiter(spieler: 2)
        s.zug(wurf: 6); s.zug(wurf: 6)
        let vorher = s.positionen[0]
        s.zug(wurf: 6)
        XCTAssertEqual(s.positionen[0], vorher, "Der dritte Sechser zählt nicht")
        XCTAssertEqual(s.amZug, 1)
    }

    func testZielMussNichtGenauGetroffenWerden() {
        var s = Himmelsleiter(spieler: 2)
        // Spieler 1 nahe ans Ziel bringen, Spieler 2 bleibt mit Einsen zurück.
        s.zug(wurf: 3); s.zug(wurf: 1)
        var z = 0
        while s.sieger == nil && z < 500 {
            s.zug(wurf: s.amZug == 0 ? 5 : 1); z += 1
        }
        XCTAssertEqual(s.sieger, 0)
        XCTAssertEqual(s.positionen[0], Himmelsleiter.ziel)
    }

    func testNachSiegGibtEsKeineZuegeMehr() {
        var s = Himmelsleiter(spieler: 2)
        var z = 0
        while s.sieger == nil && z < 5000 { s.zug(wurf: Int.random(in: 1...6)); z += 1 }
        let stand = s
        s.zug(wurf: 3)
        XCTAssertEqual(s, stand)
    }

    func testUngueltigerWurfWirdIgnoriert() {
        var s = Himmelsleiter(spieler: 3)
        let stand = s
        s.zug(wurf: 0); s.zug(wurf: 7)
        XCTAssertEqual(s, stand)
    }

    func testSpielerzahlWirdBegrenzt() {
        XCTAssertEqual(Himmelsleiter(spieler: 1).spieler, 2)
        XCTAssertEqual(Himmelsleiter(spieler: 9).spieler, 4)
    }

    func testSpielstandIstCodierbar() throws {
        var s = Himmelsleiter(spieler: 3)
        s.zug(wurf: 5); s.zug(wurf: 6)
        let neu = try JSONDecoder().decode(Himmelsleiter.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}
