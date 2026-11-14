// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// E5: Live Activity nur bei mindestens zwei Menschen; Zugwechsel und Ende laufen über die Haken der Hülle.
@MainActor
final class LaufendePartieTests: XCTestCase {
    override func setUp() async throws {
        LaufendePartie.beenden()
        LaufendePartie.beginnHaken = nil; LaufendePartie.aenderungHaken = nil; LaufendePartie.endeHaken = nil
    }
    override func tearDown() async throws { LaufendePartie.beenden(); LaufendePartie.beginnHaken = nil; LaufendePartie.aenderungHaken = nil; LaufendePartie.endeHaken = nil }

    func testEinzelspielerStartetKeineAktivitaet() {
        var beginn = 0
        LaufendePartie.beginnHaken = { _ in beginn += 1 }
        LaufendePartie.beginnen(spielID: "sudoku", spielName: "Sudoku", menschen: ["Anna"])
        XCTAssertEqual(beginn, 0)
        XCTAssertNil(LaufendePartie.aktuell)
    }

    func testZweiMenschenStartenMitErstemAmZug() {
        var gesehen: LaufendePartie.Zustand?
        LaufendePartie.beginnHaken = { gesehen = $0 }
        LaufendePartie.beginnen(spielID: "yacht", spielName: "Yacht", menschen: ["Anna", "Ben"])
        XCTAssertEqual(gesehen?.amZug, "Anna")
        XCTAssertEqual(gesehen?.spieler, ["Anna", "Ben"])
        XCTAssertEqual(LaufendePartie.aktuell?.spielID, "yacht")
    }

    func testZugwechselMeldetNurAenderungen() {
        var aenderungen: [String?] = []
        LaufendePartie.aenderungHaken = { aenderungen.append($0.amZug) }
        LaufendePartie.beginnen(spielID: "yacht", spielName: "Yacht", menschen: ["Anna", "Ben"])
        LaufendePartie.zug(amZug: "Ben", stand: "Anna 12 · Ben 8")
        LaufendePartie.zug(amZug: "Ben", stand: "Anna 12 · Ben 8")   // unverändert: keine Meldung
        LaufendePartie.zug(amZug: "Anna")
        XCTAssertEqual(aenderungen, ["Ben", "Anna"])
        XCTAssertNil(LaufendePartie.aktuell?.stand)
    }

    func testZugOhneLaufendePartieTutNichts() {
        var n = 0
        LaufendePartie.aenderungHaken = { _ in n += 1 }
        LaufendePartie.zug(amZug: "Anna")
        XCTAssertEqual(n, 0)
    }

    func testEndeEinmalMelden() {
        var ende = 0
        LaufendePartie.endeHaken = { ende += 1 }
        LaufendePartie.beginnen(spielID: "yacht", spielName: "Yacht", menschen: ["Anna", "Ben"])
        LaufendePartie.beenden(); LaufendePartie.beenden()
        XCTAssertEqual(ende, 1)
        XCTAssertNil(LaufendePartie.aktuell)
    }

    func testNeuerStartMitEinemMenschenBeendetAlteAktivitaet() {
        var ende = 0
        LaufendePartie.endeHaken = { ende += 1 }
        LaufendePartie.beginnen(spielID: "yacht", spielName: "Yacht", menschen: ["Anna", "Ben"])
        LaufendePartie.beginnen(spielID: "yacht", spielName: "Yacht", menschen: ["Anna"])
        XCTAssertEqual(ende, 1)
    }
}
