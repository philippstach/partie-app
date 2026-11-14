// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WuerfelFunk

final class WurfTests: XCTestCase {
    func testNachrichtHinUndZurueck() throws {
        let n = FunkNachricht.wurf(FunkWurf(folge: 3, augen: [1, 6, 4]))
        XCTAssertEqual(FunkNachricht.lies(try XCTUnwrap(n.kodiert())), n)
        XCTAssertNil(FunkNachricht.lies(Data("kaputt".utf8)))
    }

    func testMelderSendetErstNachStabilemWurf() {
        var m = WurfMelder()
        for _ in 0..<5 { XCTAssertNil(m.beobachte(augen: [2, 5], sicher: true)) }
        XCTAssertEqual(m.beobachte(augen: [2, 5], sicher: true)?.augen, [2, 5])
        for _ in 0..<20 { XCTAssertNil(m.beobachte(augen: [5, 2], sicher: true), "derselbe Wurf nur einmal") }
    }

    func testMelderTrotzdemSendenZaehltWeiterUndSendetNichtDoppelt() {
        var m = WurfMelder()
        XCTAssertNil(m.erzwinge(augen: []))
        XCTAssertEqual(m.erzwinge(augen: [4, 2])?.folge, 1)
        for _ in 0..<20 { XCTAssertNil(m.beobachte(augen: [2, 4], sicher: true), "dieselben Augen nicht noch einmal") }
        for _ in 0..<5 { XCTAssertNil(m.beobachte(augen: [6, 6], sicher: true)) }
        XCTAssertEqual(m.beobachte(augen: [6, 6], sicher: true)?.folge, 2)
    }

    func testMelderUnsichereWuerfelZaehlenNicht() {
        var m = WurfMelder()
        for _ in 0..<20 { XCTAssertNil(m.beobachte(augen: [3], sicher: false)) }
    }

    func testMelderNeuerWurfMitAnderenAugen() {
        var m = WurfMelder()
        for _ in 0..<6 { _ = m.beobachte(augen: [1, 1], sicher: true) }
        var w: FunkWurf?
        for _ in 0..<6 { w = m.beobachte(augen: [3, 4], sicher: true) ?? w }
        XCTAssertEqual(w?.folge, 2)
        XCTAssertEqual(w?.augen, [3, 4])
    }

    func testMelderGleicheAugenNachWegnehmenZaehltNeu() {
        var m = WurfMelder()
        var gesendet = 0
        for _ in 0..<6 { if m.beobachte(augen: [6, 6], sicher: true) != nil { gesendet += 1 } }
        for _ in 0..<8 { _ = m.beobachte(augen: [], sicher: false) }
        for _ in 0..<6 { if m.beobachte(augen: [6, 6], sicher: true) != nil { gesendet += 1 } }
        XCTAssertEqual(gesendet, 2)
    }

    func testEmpfangIgnoriertDoppeltesUndUngueltiges() {
        var e = WurfEmpfang()
        XCTAssertEqual(e.nimm(FunkWurf(folge: 1, augen: [2, 3])), [2, 3])
        XCTAssertNil(e.nimm(FunkWurf(folge: 1, augen: [2, 3])))
        XCTAssertNil(e.nimm(FunkWurf(folge: 2, augen: [7])))
        XCTAssertNil(e.nimm(FunkWurf(folge: 3, augen: [])))
        e.neueVerbindung()
        XCTAssertEqual(e.nimm(FunkWurf(folge: 1, augen: [1])), [1])
    }
}
