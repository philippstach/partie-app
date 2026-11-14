// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import DameKern

/// Selbstspiel: Stufen gegeneinander, Seiten getauscht. Nur mit `BRETT_SELBSTSPIEL=<Partien je Paar>` (Release-Messung).
final class DameSelbstspielTests: XCTestCase {
    static func duell(_ a: (Dame) -> DamenZug?, _ b: (Dame) -> DamenZug?, partien: Int) -> (a: Int, b: Int, remis: Int) {
        var sa = 0, sb = 0, r = 0
        for i in 0..<partien {
            var d = Dame(); var n = 0
            let aIst1 = i % 2 == 0
            while !d.vorbei, n < 300 {
                let amZug = (d.dran == 1) == aIst1 ? a : b
                guard let z = amZug(d) else { break }
                d.spiele(z); n += 1
            }
            if let s = d.sieger { if (s == 1) == aIst1 { sa += 1 } else { sb += 1 } } else { r += 1 }
        }
        return (sa, sb, r)
    }
    func testStufenReihenfolge() throws {
        guard let n = ProcessInfo.processInfo.environment["BRETT_SELBSTSPIEL"].flatMap(Int.init) else { throw XCTSkip("Messung nur auf Wunsch") }
        func spieler(_ s: DameStaerke) -> (Dame) -> DamenZug? { { DameComputer.wahl($0, staerke: s) } }
        let sm = Self.duell(spieler(.schwer), spieler(.mittel), partien: n)
        let ml = Self.duell(spieler(.mittel), spieler(.leicht), partien: n)
        let sl = Self.duell(spieler(.schwer), spieler(.leicht), partien: n)
        print("SELBSTSPIEL Dame schwer-mittel \(sm) mittel-leicht \(ml) schwer-leicht \(sl)")
        XCTAssertGreaterThan(sm.a, sm.b); XCTAssertGreaterThan(ml.a, ml.b); XCTAssertGreaterThan(sl.a, sl.b)
    }
}
