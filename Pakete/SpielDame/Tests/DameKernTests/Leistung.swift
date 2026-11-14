// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import DameKern
final class DameLeistungTests: XCTestCase {
    func testSchwersterZugDauertNichtLange() {
        var laengster = 0.0
        #if DEBUG
        let partien = 1      // Debug ist etwa zehnmal langsamer; die Zeitgrenze wird nur im Release geprüft
        #else
        let partien = 6
        #endif
        for _ in 0..<partien {
            var s = Dame(); var n = 0
            while !s.vorbei, n < 60 {
                if n % 6 == 0 { let t = Date(); _ = DameComputer.wahl(s, staerke: .schwer); laengster = max(laengster, Date().timeIntervalSince(t)) }
                s.spiele(s.zuege.randomElement()!); n += 1
            }
        }
        print("ZEIT Dame schwer max: \(laengster)")
        #if !DEBUG
        XCTAssertLessThan(laengster, 0.5)   // Release: schwerste Stufe unter einer halben Sekunde (Debug ist deutlich langsamer)
        #endif
    }
}
