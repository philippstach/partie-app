// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchachKern
import SpieleKern

final class SchachZufallspartienTests: XCTestCase {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "test.schach.\(UUID())")! }
    /// Zufallspartien: nur gültige Züge, jede Partie endet, und der Stand einer beendeten Partie wird nicht wieder gesichert.
    func testZufallspartienEndenUndBeendeteStaendeWerdenNichtGesichert() {
        for _ in 0..<12 {
            for _ in 0..<1 {
                var s = Schach(); var n = 0; var mittenGesichert = false
                let d = defaults()
                while !(s.zuege.isEmpty || s.remis), n < 1500 {
                    let z = s.zuege
            if z.isEmpty { break }
                    _ = s.ziehe(z.randomElement()!)
                    n += 1
                    if n == 6, !(s.zuege.isEmpty || s.remis) {
                        XCTAssertTrue(SpielStand.sichernBeimVerlassen(s, spiel: "t", laeuft: !(s.zuege.isEmpty || s.remis), defaults: d))
                        XCTAssertEqual(SpielStand.laden(Schach.self, spiel: "t", defaults: d), s)
                        mittenGesichert = true
                    }
                }
                XCTAssertTrue(s.zuege.isEmpty || s.remis, "Partie endet nicht")
                SpielStand.loeschen("t", defaults: d)
                XCTAssertFalse(SpielStand.sichernBeimVerlassen(s, spiel: "t", laeuft: !(s.zuege.isEmpty || s.remis), defaults: d))
                XCTAssertFalse(SpielStand.vorhanden("t", defaults: d))
                _ = mittenGesichert
            }
        }
    }
    func testMattPattRemisSindEindeutig() {
        var s = Schach(); var n = 0
        while !(s.zuege.isEmpty || s.remis), n < 1500 { s.ziehe(s.zuege.randomElement()!); n += 1 }
        XCTAssertTrue(s.zuege.isEmpty || s.remis)
        if s.zuege.isEmpty { XCTAssertNotEqual(s.schachmatt, s.patt) }     // genau eines von beiden
        if s.schachmatt || s.patt { XCTAssertTrue(s.zuege.isEmpty) }
    }
}
