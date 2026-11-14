// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import BackgammonKern
import SpieleKern

final class BackgammonZufallspartienTests: XCTestCase {
    /// Zufallspartien: nur gültige Züge, jede Partie endet, Steine bleiben erhalten, ein beendeter Stand wird nicht wieder gesichert.
    func testZufallspartienEndenUndBeendeteStaendeWerdenNichtGesichert() {
        var g = SystemRandomNumberGenerator()
        for regeln in [BgRegeln.standard, .nardy, .plakoto] {
            var s = Backgammon(regeln: regeln); var runden = 0
            let d = UserDefaults(suiteName: "test.bg.\(UUID())")!
            while s.gewinner == nil, runden < 6000 {
                s.wuerfeln(mit: &g)
                var schritte = 0
                while schritte < 10 {
                    let z = s.zuege
                    if z.isEmpty { s.aussetzen(); break }
                    XCTAssertTrue(s.ziehe(z.randomElement()!)); schritte += 1
                    if s.gewinner != nil || s.wuerfel.isEmpty { break }
                }
                runden += 1
                if runden == 4 { XCTAssertTrue(SpielStand.sichernBeimVerlassen(s, spiel: "bg", laeuft: s.gewinner == nil, defaults: d)) }
            }
            XCTAssertNotNil(s.gewinner, "Partie endet nicht (\(regeln.pin ? "Plakoto" : regeln.kopfRegel ? "Nardy" : "Standard"))")
            SpielStand.loeschen("bg", defaults: d)
            XCTAssertFalse(SpielStand.sichernBeimVerlassen(s, spiel: "bg", laeuft: s.gewinner == nil, defaults: d))
            XCTAssertFalse(SpielStand.vorhanden("bg", defaults: d))
        }
    }
}
