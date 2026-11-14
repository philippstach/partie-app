// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import OwareKern
import SpieleKern

final class OwareZufallspartienTests: XCTestCase {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "test.oware.\(UUID())")! }
    /// Zufallspartien: nur gültige Züge, jede Partie endet, und der Stand einer beendeten Partie wird nicht wieder gesichert.
    func testZufallspartienEndenUndBeendeteStaendeWerdenNichtGesichert() {
        for _ in 0..<12 {
            for r in [OwareRegeln.standard, .kurz, .lang, .grand] {
                var s = Oware(regeln: r); var n = 0; var mittenGesichert = false
                let d = defaults()
                while !(s.vorbei), n < 2000 {
                    let z = s.zuege
            if z.isEmpty { break }
                    _ = s.spiele(z.randomElement()!)
                    n += 1
                    if n == 6, !(s.vorbei) {
                        XCTAssertTrue(SpielStand.sichernBeimVerlassen(s, spiel: "t", laeuft: !(s.vorbei), defaults: d))
                        XCTAssertEqual(SpielStand.laden(Oware.self, spiel: "t", defaults: d), s)
                        mittenGesichert = true
                    }
                }
                XCTAssertTrue(s.vorbei, "Partie endet nicht")
                SpielStand.loeschen("t", defaults: d)
                XCTAssertFalse(SpielStand.sichernBeimVerlassen(s, spiel: "t", laeuft: !(s.vorbei), defaults: d))
                XCTAssertFalse(SpielStand.vorhanden("t", defaults: d))
                _ = mittenGesichert
            }
        }
    }
}
