// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchachKern

/// Selbstspiel: Stufen gegeneinander, Seiten getauscht. Nur mit `BRETT_SELBSTSPIEL=<Partien je Paar>` (Release-Messung).
/// Nach 160 Halbzügen wird nach Material entschieden (ab 3 Bauern Vorsprung gewonnen, sonst Remis).
final class SchachSelbstspielTests: XCTestCase {
    static func material(_ s: Schach) -> Int { s.brett.reduce(0) { $0 + ($1 > 0 ? 1 : -1) * (SchachComputer.wert[abs($1)]) * ($1 == 0 ? 0 : 1) } }
    static func duell(_ a: (Schach) -> SchachZug?, _ b: (Schach) -> SchachZug?, partien: Int) -> (a: Int, b: Int, remis: Int) {
        var sa = 0, sb = 0, r = 0
        for i in 0..<partien {
            var s = Schach(); var n = 0
            let aIstWeiss = i % 2 == 0
            // Eröffnung zufällig auffächern (vier Halbzüge), damit nicht jede Partie gleich verläuft
            for _ in 0..<4 { s.ziehe(s.zuege.randomElement()!) }
            while !s.zuege.isEmpty, !s.remis, n < 160 {
                let amZug = (s.dran == 1) == aIstWeiss ? a : b
                guard let z = amZug(s) else { break }
                s.ziehe(z); n += 1
            }
            var weiss: Int? = nil     // +1 Weiß gewinnt, −1 Schwarz gewinnt
            if s.schachmatt { weiss = -s.dran } else if !s.remis, !s.zuege.isEmpty {
                let m = material(s); if abs(m) >= 300 { weiss = m > 0 ? 1 : -1 }
            }
            if let w = weiss { if (w == 1) == aIstWeiss { sa += 1 } else { sb += 1 } } else { r += 1 }
        }
        return (sa, sb, r)
    }
    func testStufenReihenfolge() throws {
        guard let n = ProcessInfo.processInfo.environment["BRETT_SELBSTSPIEL"].flatMap(Int.init) else { throw XCTSkip("Messung nur auf Wunsch") }
        func spieler(_ s: SchachStaerke) -> (Schach) -> SchachZug? { { SchachComputer.wahl($0, staerke: s) } }
        let sm = Self.duell(spieler(.schwer), spieler(.mittel), partien: n)
        let ml = Self.duell(spieler(.mittel), spieler(.leicht), partien: n)
        let sl = Self.duell(spieler(.schwer), spieler(.leicht), partien: n)
        print("SELBSTSPIEL Schach schwer-mittel \(sm) mittel-leicht \(ml) schwer-leicht \(sl)")
        XCTAssertGreaterThan(sm.a, sm.b); XCTAssertGreaterThan(ml.a, ml.b); XCTAssertGreaterThan(sl.a, sl.b)
    }

    /// Neue Bewertung gegen die alte bei gleicher Tiefe (Messung wie oben).
    func testNeueBewertungSchlaegtAlte() throws {
        guard let n = ProcessInfo.processInfo.environment["BRETT_SELBSTSPIEL"].flatMap(Int.init) else { throw XCTSkip("Messung nur auf Wunsch") }
        let r = Self.duell({ SchachComputer.wahl($0, tiefe: 3, fehler: 0, art: .neu) }, { SchachComputer.wahl($0, tiefe: 3, fehler: 0, art: .alt) }, partien: n)
        print("SELBSTSPIEL Schach neu-gegen-alt \(r)")
        XCTAssertGreaterThanOrEqual(r.a, r.b)
    }
}
