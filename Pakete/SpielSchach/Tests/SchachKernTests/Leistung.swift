// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchachKern
final class SchachLeistungTests: XCTestCase {
    /// Schwerste Stufe (Tiefe 4) in typischen Zufallsstellungen: längster Computerzug.
    func testSchwersterZugDauertNichtLange() {
        #if DEBUG
        let debugLauf = true      // Debug ist etwa zehnmal langsamer; die Zeitgrenze wird nur im Release geprüft
        #else
        let debugLauf = false
        #endif
        var s = Schach(); var laengster = 0.0; var n = 0
        while !(s.zuege.isEmpty || s.remis), n < (debugLauf ? 12 : 80) {
            if n % 4 == 0 { let t = Date(); _ = SchachComputer.wahl(s, staerke: .schwer); laengster = max(laengster, Date().timeIntervalSince(t)) }
            s.ziehe(n % 2 == 0 ? SchachComputer.wahl(s, tiefe: 2, fehler: 0.2)! : s.zuege.randomElement()!); n += 1
        }
        print("ZEIT Schach schwer max: \(laengster)")
        #if !DEBUG
        XCTAssertLessThan(laengster, 0.5)   // Release: schwerste Stufe unter einer halben Sekunde (Debug ist deutlich langsamer)
        #endif
    }
}
