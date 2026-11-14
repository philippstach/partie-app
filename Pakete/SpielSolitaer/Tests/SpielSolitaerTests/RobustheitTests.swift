// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Code-Prüfung der riskanten Stellen: beschädigte Spielstände, Indexzugriffe, Leistung bei Spider
@MainActor
final class RobustheitTests: XCTestCase {
    func testKartennummerAusserhalbWirdAbgelehnt() {
        XCTAssertThrowsError(try JSONDecoder().decode([CardID].self, from: Data("[3, 52, 104]".utf8)))
        XCTAssertThrowsError(try JSONDecoder().decode([CardID].self, from: Data("[-1]".utf8)))
        XCTAssertNoThrow(try JSONDecoder().decode([CardID].self, from: Data("[0, 51, 103]".utf8)))
    }

    func testBeschaedigteZielwerteWerdenBegrenzt() throws {
        XCTAssertEqual(CardID.sanitizedFoundation([99, -4, 13]), [13, 0, 13, 0])
        let k = try JSONDecoder().decode(GameState.self, from: Data(#"{"foundation": [20, -1], "cols": [{},{},{},{},{},{},{},{},{}]}"#.utf8))
        XCTAssertEqual(k.foundation, [13, 0, 0, 0])
        XCTAssertEqual(k.cols.count, 7)
        let f = try JSONDecoder().decode(FreeCellState.self, from: Data(#"{"foundation": [5, 5, 5, 5, 5], "cells": [null,null,null,null,null,null]}"#.utf8))
        XCTAssertEqual(f.foundation, [5, 5, 5, 5])
        XCTAssertEqual(f.cells.count, 4)
        let y = try JSONDecoder().decode(YukonState.self, from: Data(#"{"foundation": [14]}"#.utf8))
        XCTAssertEqual(y.foundation, [13, 0, 0, 0])
        let s = try JSONDecoder().decode(SpiderState.self, from: Data(#"{"suits": 0}"#.utf8))
        XCTAssertEqual(s.suits, 2)
    }

    func testFalscheOrtsnummernStuerzenNichtAb() {
        let k = Deal.deal(seed: 1, draw: 1)
        for bad in [-1, 7, 99] {
            XCTAssertNil(KlondikeRules.apply(k, .move(from: .column(bad), to: .column(0), count: 1)), "Spalte \(bad)")
            XCTAssertNil(KlondikeRules.apply(k, .move(from: .column(0), to: .column(bad), count: 1)))
            XCTAssertNil(KlondikeRules.apply(k, .move(from: .foundation(bad), to: .column(0), count: 1)))
            XCTAssertNil(KlondikeRules.apply(k, .move(from: .column(0), to: .foundation(bad), count: 1)))
        }
        XCTAssertNil(KlondikeRules.tapTarget(k, from: .column(9), count: 1))
        let f = FreeCellRules.deal(seed: 1, mode: .freecell)
        XCTAssertNil(FreeCellRules.apply(f, .move(from: .column(12), to: .cell(0), count: 1)))
        let s = SpiderRules.deal(seed: 1, mode: .spider(2))
        XCTAssertNil(SpiderRules.apply(s, .move(from: .column(10), to: .column(0), count: 1)))
        XCTAssertNil(SpiderRules.apply(s, .move(from: .column(0), to: .column(10), count: 1)))
        let y = YukonRules.deal(seed: 1, mode: .yukon)
        XCTAssertNil(YukonRules.apply(y, .move(from: .column(8), to: .column(0), count: 1)))
        let p = PyramidRules.deal(seed: 1, mode: .pyramid)
        XCTAssertNil(PyramidRules.apply(p, .move(from: .column(99), to: .waste, count: 1)))
        let t = TriPeaksRules.deal(seed: 1, mode: .tripeaks)
        XCTAssertNil(TriPeaksRules.apply(t, .move(from: .column(-3), to: .waste, count: 1)))
        let g = GolfRules.deal(seed: 1, mode: .golf)
        XCTAssertNil(GolfRules.apply(g, .move(from: .column(7), to: .waste, count: 1)))
    }

    /// Spider mit 4 Farben: Tipp, „festgefahren“ und Layout nach jedem Zug einer ganzen Tipp-Partie bleiben schnell
    func testSpiderLeistung() {
        var s = SpiderRules.deal(seed: 3, mode: .spider(4))
        var hintTime = 0.0, layoutTime = 0.0, steps = 0
        let size = CGSize(width: 393, height: 600), wide = CGSize(width: 700, height: 330)
        while steps < 400 {
            let t0 = Date()
            let m = SpiderRules.hint(s)
            _ = SpiderRules.isStuck(s)
            hintTime = max(hintTime, Date().timeIntervalSince(t0))
            let t1 = Date()
            _ = SpiderLayout(state: s, size: size, prefs: TablePrefs())
            _ = SpiderLayout(state: s, size: wide, prefs: TablePrefs())
            layoutTime = max(layoutTime, Date().timeIntervalSince(t1))
            guard let m, let n = SpiderRules.apply(s, m) else { break }
            s = n; steps += 1
        }
        XCTAssertGreaterThan(steps, 20)
        XCTAssertLessThan(hintTime, 0.25, "Tipp + festgefahren je Zug höchstens 0,25 s (längster: \(hintTime))")
        XCTAssertLessThan(layoutTime, 0.05, "Layout hoch + quer je Zug höchstens 0,05 s (längster: \(layoutTime))")
    }
}
