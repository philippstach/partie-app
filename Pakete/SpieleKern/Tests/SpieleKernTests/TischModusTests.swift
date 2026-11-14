// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpieleKern

/// E8: Plätze und Drehung der Namensschilder im Tisch-Modus.
final class TischModusTests: XCTestCase {
    func testZweiPersonenGegenueber() {
        XCTAssertEqual(TischModus.plaetze(anzahl: 2), [.init(rand: .unten, grad: 0), .init(rand: .oben, grad: 180)])
    }

    func testDreiUndVierImUhrzeigersinn() {
        XCTAssertEqual(TischModus.plaetze(anzahl: 3).map(\.rand), [.unten, .links, .rechts])
        XCTAssertEqual(TischModus.plaetze(anzahl: 4).map(\.rand), [.unten, .links, .oben, .rechts])
    }

    func testJederRandHatPassendeDrehung() {
        for sitz in TischModus.plaetze(anzahl: 4) {
            switch sitz.rand {
            case .unten: XCTAssertEqual(sitz.grad, 0)
            case .links: XCTAssertEqual(sitz.grad, 90)
            case .oben: XCTAssertEqual(sitz.grad, 180)
            case .rechts: XCTAssertEqual(sitz.grad, -90)
            }
        }
    }

    func testPlatzzahlenAusserhalbDerGrenzenHabenKeinenTisch() {
        XCTAssertTrue(TischModus.plaetze(anzahl: 1).isEmpty)
        XCTAssertTrue(TischModus.plaetze(anzahl: 5).isEmpty)
        XCTAssertTrue(TischModus.plaetze(anzahl: 0).isEmpty)
    }

    func testPasstNurAufDemIPadMitZweiBisVierMenschen() {
        XCTAssertTrue(TischModus.passt(menschen: 2, istIPad: true))
        XCTAssertTrue(TischModus.passt(menschen: 4, istIPad: true))
        XCTAssertFalse(TischModus.passt(menschen: 1, istIPad: true))
        XCTAssertFalse(TischModus.passt(menschen: 5, istIPad: true))
        XCTAssertFalse(TischModus.passt(menschen: 3, istIPad: false))
    }
}
