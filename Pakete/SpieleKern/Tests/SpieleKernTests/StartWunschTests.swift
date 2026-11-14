// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// KI-8: „Neue Partie“ per Siri/Kurzbefehl: Aufstellung aus Menschen- und Computerzahl.
final class StartWunschTests: XCTestCase {
    private let namen = ["Anna", "Ben", "Cem"]

    func testNichtsGewuenschtGiltDieVorgabeDesSpiels() {
        XCTAssertNil(StartWunsch().aufstellung(spielerzahl: 2...4, computerErlaubt: true, vorgabeNamen: namen))
    }

    func testEinzelspielBrauchtKeineAufstellung() {
        XCTAssertNil(StartWunsch(menschen: 3, computer: 1).aufstellung(spielerzahl: 1...1, computerErlaubt: false, vorgabeNamen: namen))
    }

    func testEinMenschGegenEinenComputer() {
        let a = StartWunsch(menschen: 1, computer: 1).aufstellung(spielerzahl: 2...2, computerErlaubt: true, vorgabeNamen: namen)
        XCTAssertEqual(a, [.init(name: "Anna", computer: false), .init(name: "Computer", computer: true)])
    }

    func testNurComputerGenanntErgibtEinenMenschenDazu() {
        let a = StartWunsch(computer: 2).aufstellung(spielerzahl: 2...4, computerErlaubt: true, vorgabeNamen: namen)
        XCTAssertEqual(a?.map(\.computer), [false, true, true])
    }

    func testComputerOhneComputerSpielWerdenWeggelassen() {
        let a = StartWunsch(menschen: 2, computer: 3).aufstellung(spielerzahl: 2...4, computerErlaubt: false, vorgabeNamen: namen)
        XCTAssertEqual(a?.map(\.name), ["Anna", "Ben"])
        XCTAssertNil(StartWunsch(computer: 2).aufstellung(spielerzahl: 2...4, computerErlaubt: false, vorgabeNamen: namen), "ohne Menschenzahl und ohne Computer bleibt die Vorgabe")
    }

    func testZuVieleWerdenGekuerztZuerstDieComputer() {
        let a = StartWunsch(menschen: 3, computer: 3).aufstellung(spielerzahl: 2...4, computerErlaubt: true, vorgabeNamen: namen)
        XCTAssertEqual(a?.count, 4)
        XCTAssertEqual(a?.filter(\.computer).count, 1)
        let b = StartWunsch(menschen: 9, computer: 0).aufstellung(spielerzahl: 2...4, computerErlaubt: true, vorgabeNamen: namen)
        XCTAssertEqual(b?.count, 4)
    }

    func testZuWenigeWerdenMitMenschenAufgefuellt() {
        let a = StartWunsch(menschen: 1).aufstellung(spielerzahl: 2...4, computerErlaubt: false, vorgabeNamen: namen)
        XCTAssertEqual(a?.map(\.name), ["Anna", "Ben"])
    }

    func testFehlendeNamenBleibenLeer() {
        let a = StartWunsch(menschen: 3).aufstellung(spielerzahl: 2...6, computerErlaubt: false, vorgabeNamen: ["Anna"])
        XCTAssertEqual(a?.map(\.name), ["Anna", "", ""])
    }

    @MainActor func testWunschGiltEinmalNurFuerDasSpielUndEineMinute() {
        let t0 = Date(timeIntervalSince1970: 1_000)
        StartWunschPost.merken("maumau-neu", StartWunsch(computer: 1), jetzt: t0)
        XCTAssertNil(StartWunschPost.einloesen("yacht-neu", jetzt: t0))
        XCTAssertEqual(StartWunschPost.einloesen("maumau-neu", jetzt: t0.addingTimeInterval(5)), StartWunsch(computer: 1))
        XCTAssertNil(StartWunschPost.einloesen("maumau-neu", jetzt: t0.addingTimeInterval(6)), "nur einmal")
        StartWunschPost.merken("maumau-neu", StartWunsch(computer: 1), jetzt: t0)
        XCTAssertNil(StartWunschPost.einloesen("maumau-neu", jetzt: t0.addingTimeInterval(61)), "zu alt")
    }
}
