// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MuehleKern
final class MuehleLeistungTests: XCTestCase {
    func testSchwersterZugDauertNichtLange() {
        var laengster = 0.0
        #if DEBUG
        let partien = 1      // Debug ist etwa zehnmal langsamer; die Zeitgrenze wird nur im Release geprüft
        #else
        let partien = 6
        #endif
        for _ in 0..<partien {
            var s = Muehle(); var n = 0
            while !s.vorbei, n < 70 {
                if n % 5 == 0 { let t = Date(); _ = MuehleComputer.wahl(s, staerke: .schwer); laengster = max(laengster, Date().timeIntervalSince(t)) }
                s.spiele(s.zuege().randomElement()!); n += 1
            }
        }
        print("ZEIT Muehle schwer max: \(laengster)")
        #if !DEBUG
        XCTAssertLessThan(laengster, 0.5)   // Release: schwerste Stufe unter einer halben Sekunde (Debug ist deutlich langsamer)
        #endif
    }
}
