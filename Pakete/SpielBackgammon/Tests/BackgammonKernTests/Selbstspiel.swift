// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import BackgammonKern

/// Selbstspiel: Stufen gegeneinander, Seiten getauscht, gleiche Würfel-Quelle. Nur mit `BRETT_SELBSTSPIEL=<Partien je Paar>` (Release-Messung).
final class BackgammonSelbstspielTests: XCTestCase {
    static func duell(_ a: (Backgammon) -> [BgZug], _ b: (Backgammon) -> [BgZug], partien: Int) -> (a: Int, b: Int) {
        var sa = 0, sb = 0
        var g = SystemRandomNumberGenerator()
        for i in 0..<partien {
            var s = Backgammon(); var runden = 0
            let aIst1 = i % 2 == 0
            while s.gewinner == nil, runden < 600 {
                s.wuerfeln(mit: &g)
                let folge = ((s.dran == 1) == aIst1 ? a : b)(s)
                if folge.isEmpty { s.aussetzen() } else { for z in folge { s.ziehe(z) } ; if !s.wuerfel.isEmpty { s.aussetzen() } }
                runden += 1
            }
            if let w = s.gewinner { if (w == 1) == aIst1 { sa += 1 } else { sb += 1 } }
        }
        return (sa, sb)
    }
    func testStufenReihenfolge() throws {
        guard let n = ProcessInfo.processInfo.environment["BRETT_SELBSTSPIEL"].flatMap(Int.init) else { throw XCTSkip("Messung nur auf Wunsch") }
        var g = SystemRandomNumberGenerator()
        func spieler(_ s: BackgammonStaerke) -> (Backgammon) -> [BgZug] { { BackgammonComputer.zugfolge($0, staerke: s) } }
        _ = g.next()
        let sm = Self.duell(spieler(.schwer), spieler(.mittel), partien: n)
        let ml = Self.duell(spieler(.mittel), spieler(.leicht), partien: n)
        let sl = Self.duell(spieler(.schwer), spieler(.leicht), partien: n)
        print("SELBSTSPIEL Backgammon schwer-mittel \(sm) mittel-leicht \(ml) schwer-leicht \(sl)")
        XCTAssertGreaterThan(sm.a, sm.b); XCTAssertGreaterThan(ml.a, ml.b); XCTAssertGreaterThan(sl.a, sl.b)
    }

    func testNeueBewertungSchlaegtAlte() throws {
        guard let n = ProcessInfo.processInfo.environment["BRETT_SELBSTSPIEL"].flatMap(Int.init) else { throw XCTSkip("Messung nur auf Wunsch") }
        let r = Self.duell({ BackgammonComputer.zugfolge($0, art: .neu) }, { BackgammonComputer.zugfolge($0, art: .alt) }, partien: n)
        print("SELBSTSPIEL Backgammon neu-gegen-alt \(r)")
        XCTAssertGreaterThanOrEqual(r.a, r.b)
    }
}
