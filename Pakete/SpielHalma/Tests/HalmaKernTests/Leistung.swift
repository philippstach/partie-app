// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import HalmaKern
final class HalmaLeistungTests: XCTestCase {
    func testSchwersterZugDauertNichtLange() {
        var g = SystemRandomNumberGenerator(); var laengster = 0.0
        for _ in 0..<4 {
            var s = Halma(); var n = 0
            while !s.vorbei, n < 80 {
                if n % 8 == 0 { let t = Date(); _ = HalmaComputer.wahl(s, tiefe: 3, breite: 8, mit: &g); laengster = max(laengster, Date().timeIntervalSince(t)) }
                let m = s.alleZuege.randomElement()!; s.ziehe(von: m.0, nach: m.1); n += 1
            }
        }
        print("ZEIT Halma schwer max: \(laengster)")
        #if !DEBUG
        XCTAssertLessThan(laengster, 0.5)   // Release: schwerste Stufe unter einer halben Sekunde (Debug ist deutlich langsamer)
        #endif
    }
}
