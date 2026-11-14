// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WendespielKern
import SpieleKern

final class WendespielZufallspartienTests: XCTestCase {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "test.wendespiel.\(UUID())")! }
    /// Zufallspartien: nur gültige Züge, jede Partie endet, und der Stand einer beendeten Partie wird nicht wieder gesichert.
    func testZufallspartienEndenUndBeendeteStaendeWerdenNichtGesichert() {
        for _ in 0..<12 {
            for r in [false, true] {
                var s = Wendespiel(verkehrt: r); var n = 0; var mittenGesichert = false
                let d = defaults()
                while !(s.beendet), n < 200 {
                    let z = s.zuege
            if z.isEmpty { break }
                    _ = s.setze(z.randomElement()!)
                    n += 1
                    if n == 6, !(s.beendet) {
                        XCTAssertTrue(SpielStand.sichernBeimVerlassen(s, spiel: "t", laeuft: !(s.beendet), defaults: d))
                        XCTAssertEqual(SpielStand.laden(Wendespiel.self, spiel: "t", defaults: d), s)
                        mittenGesichert = true
                    }
                }
                XCTAssertTrue(s.beendet, "Partie endet nicht")
                SpielStand.loeschen("t", defaults: d)
                XCTAssertFalse(SpielStand.sichernBeimVerlassen(s, spiel: "t", laeuft: !(s.beendet), defaults: d))
                XCTAssertFalse(SpielStand.vorhanden("t", defaults: d))
                _ = mittenGesichert
            }
        }
    }
}
