// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import BackgammonKern
final class BackgammonLeistungTests: XCTestCase {
    func testSchwersterZugDauertNichtLange() {
        var g = SystemRandomNumberGenerator(); var laengster = 0.0; var s = Backgammon(); var n = 0
        while s.gewinner == nil, n < 120 {
            s.wuerfeln(mit: &g)
            let t = Date(); let folge = BackgammonComputer.zugfolge(s); laengster = max(laengster, Date().timeIntervalSince(t))
            if folge.isEmpty { s.aussetzen() } else { for z in folge { s.ziehe(z) } }
            n += 1
        }
        print("ZEIT Backgammon schwer max: \(laengster)")
        #if !DEBUG
        XCTAssertLessThan(laengster, 0.5)   // Release: schwerste Stufe unter einer halben Sekunde (Debug ist deutlich langsamer)
        #endif
    }
}
