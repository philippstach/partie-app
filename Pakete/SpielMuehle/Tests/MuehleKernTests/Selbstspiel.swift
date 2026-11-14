// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MuehleKern

/// Selbstspiel: Stufen gegeneinander, Seiten getauscht. Nur mit `BRETT_SELBSTSPIEL=<Partien je Paar>` (Release-Messung).
final class MuehleSelbstspielTests: XCTestCase {
    static func duell(_ a: (Muehle) -> MuehleZug?, _ b: (Muehle) -> MuehleZug?, partien: Int) -> (a: Int, b: Int, remis: Int) {
        var sa = 0, sb = 0, r = 0
        for i in 0..<partien {
            var m = Muehle(); var n = 0
            let aIst1 = i % 2 == 0
            while !m.vorbei, n < 400 {
                let amZug = (m.dran == 1) == aIst1 ? a : b
                guard let z = amZug(m) else { break }
                m.spiele(z); n += 1
            }
            if let s = m.sieger { if (s == 1) == aIst1 { sa += 1 } else { sb += 1 } } else { r += 1 }
        }
        return (sa, sb, r)
    }
    func testStufenReihenfolge() throws {
        guard let n = ProcessInfo.processInfo.environment["BRETT_SELBSTSPIEL"].flatMap(Int.init) else { throw XCTSkip("Messung nur auf Wunsch") }
        func spieler(_ s: MuehleStaerke) -> (Muehle) -> MuehleZug? { { MuehleComputer.wahl($0, staerke: s) } }
        let sm = Self.duell(spieler(.schwer), spieler(.mittel), partien: n)
        let ml = Self.duell(spieler(.mittel), spieler(.leicht), partien: n)
        let sl = Self.duell(spieler(.schwer), spieler(.leicht), partien: n)
        print("SELBSTSPIEL Muehle schwer-mittel \(sm) mittel-leicht \(ml) schwer-leicht \(sl)")
        XCTAssertGreaterThan(sm.a, sm.b); XCTAssertGreaterThan(ml.a, ml.b); XCTAssertGreaterThan(sl.a, sl.b)
    }
}
