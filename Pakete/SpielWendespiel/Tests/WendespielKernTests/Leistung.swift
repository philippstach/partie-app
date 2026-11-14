// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WendespielKern
final class WendespielLeistungTests: XCTestCase {
    func testSchwersterZugDauertNichtLange() {
        var laengster = 0.0
        for _ in 0..<6 {
            var s = Wendespiel(); var n = 0
            while !s.beendet, n < 60 {
                if n % 6 == 0 { let t = Date(); _ = WendespielComputer.wahl(s, tiefe: 4); laengster = max(laengster, Date().timeIntervalSince(t)) }
                s.setze(s.zuege.randomElement()!); n += 1
            }
        }
        print("ZEIT Wendespiel schwer max: \(laengster)")
        #if !DEBUG
        XCTAssertLessThan(laengster, 0.5)   // Release: schwerste Stufe unter einer halben Sekunde (Debug ist deutlich langsamer)
        #endif
    }
}
