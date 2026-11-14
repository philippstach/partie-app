// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielViererreihe

final class ViererOnlineTests: XCTestCase {
    func testHinUndZurueck() throws {
        var p = try Partie(beginner: 1, zuege: [])
        try p.einwerfen(3); try p.einwerfen(2)
        let d = ViererOnlineDaten.kodieren(p)
        XCTAssertLessThan(d.count, 2000)
        XCTAssertEqual(ViererOnlineDaten.lesen(d), p)
    }

    func testLeereDatenSindNeuePartie() {
        let p = ViererOnlineDaten.lesen(Data())
        XCTAssertEqual(p?.zuege, [])
        XCTAssertEqual(p?.naechsterSpieler, 1)
        XCTAssertEqual(ViererOnlineDaten.lesen(nil)?.zuege, [])
    }

    func testUnlesbarOderUnstimmigIstNil() {
        XCTAssertNil(ViererOnlineDaten.lesen(Data("kaputt".utf8)))
        XCTAssertNil(ViererOnlineDaten.lesen(Data(#"{"version":1,"partie":{"beginner":1,"zuege":[9,9]}}"#.utf8)))
    }

    func testNurWeiterGekommeneStaendeWerdenUebernommen() throws {
        var eigen = try Partie(beginner: 1, zuege: []); try eigen.einwerfen(3)
        var fern = eigen; try fern.einwerfen(4)
        XCTAssertTrue(ViererOnlineDaten.uebernehmen(fern: fern, eigen: eigen))
        XCTAssertFalse(ViererOnlineDaten.uebernehmen(fern: eigen, eigen: fern), "älterer Stand")
        XCTAssertFalse(ViererOnlineDaten.uebernehmen(fern: eigen, eigen: eigen), "gleicher Stand")
        var anders = try Partie(beginner: 1, zuege: []); try anders.einwerfen(0); try anders.einwerfen(1)
        XCTAssertFalse(ViererOnlineDaten.uebernehmen(fern: anders, eigen: eigen), "andere Partie")
    }
}
