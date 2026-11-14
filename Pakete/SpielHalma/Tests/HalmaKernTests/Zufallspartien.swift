// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HalmaKern
import SpieleKern

final class HalmaZufallspartienTests: XCTestCase {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "test.halma.\(UUID())")! }
    /// Zufallspartien: nur gültige Züge, jede Partie endet, und der Stand einer beendeten Partie wird nicht wieder gesichert.
    func testZufallspartienEndenUndBeendeteStaendeWerdenNichtGesichert() {
        for _ in 0..<12 {
            for _ in 0..<1 {
                var s = Halma(); var n = 0; var mittenGesichert = false
                let d = defaults()
                while !(s.vorbei), n < 1500 {
                    let z = s.alleZuege
            if z.isEmpty { break }
                    let m = z.randomElement()!; _ = s.ziehe(von: m.0, nach: m.1)
                    n += 1
                    if n == 6, !(s.vorbei) {
                        XCTAssertTrue(SpielStand.sichernBeimVerlassen(s, spiel: "t", laeuft: !(s.vorbei), defaults: d))
                        XCTAssertEqual(SpielStand.laden(Halma.self, spiel: "t", defaults: d), s)
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
