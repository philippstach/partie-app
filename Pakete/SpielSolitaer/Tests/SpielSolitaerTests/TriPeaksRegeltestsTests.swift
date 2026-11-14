// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Prüft jede Datei aus `Shared/regeltests/tripeaks/` vollständig.
@MainActor
final class TriPeaksRegeltestsTests: XCTestCase {
    private struct Names: Equatable {
        var gipfel: [String?]
        var offen: [Bool]
        var stapel: [String]
        var ablage: [String]
        var kette: Int
        var punkte: Int
        var zuege: Int
    }

    private func names(_ s: TriPeaksState) -> Names {
        Names(gipfel: s.peaks.map { $0?.shortName }, offen: (0..<28).map(s.isFree), stapel: s.stock.map(\.shortName),
              ablage: s.waste.map(\.shortName), kette: s.chain, punkte: s.score, zuege: s.moves)
    }

    private func state(_ d: [String: Any]) -> TriPeaksState {
        let pk = (d["gipfel"] as? [Any] ?? []).map { ($0 as? String).map(TestJSON.card) }
        return TriPeaksState(peaks: pk, stock: TestJSON.cards(d["stapel"]), waste: TestJSON.cards(d["ablage"]),
                             chain: d["kette"] as? Int ?? 0, score: d["punkte"] as? Int ?? 0, moves: d["zuege"] as? Int ?? 0)
    }

    /// „offen“ der Tests muss genau dem entsprechen, was wir aus den Gipfeln berechnen
    private func names(json d: [String: Any]) -> Names {
        let n = names(state(d))
        if let offen = d["offen"] as? [Bool] { XCTAssertEqual(offen, n.offen, "offen") }
        return n
    }

    private func move(_ d: [String: Any]) -> Move {
        let von = d["von"] as! String
        if von == "stapel" { return .draw }
        guard von.hasPrefix("T"), let k = Int(von.dropFirst()), String(k) == von.dropFirst() else { return .move(from: .column(99), to: .waste, count: 1) }
        return .move(from: .column(k), to: .waste, count: 1)
    }

    func testGeben() throws {
        for f in try TestJSON.cases("tripeaks/geben") {
            let seed = UInt64(f["seed"] as! Int)
            XCTAssertEqual(names(TriPeaksRules.deal(seed: seed, mode: .tripeaks)), names(json: f["zustand"] as! [String: Any]), "Seed \(seed)")
        }
    }

    func testZuege() throws {
        let faelle = try TestJSON.cases("tripeaks/zuege")
        XCTAssertGreaterThanOrEqual(faelle.count, 20)
        for f in faelle {
            let titel = f["titel"] as! String
            let result = TriPeaksRules.apply(state(f["start"] as! [String: Any]), move(f["zug"] as! [String: Any]))
            if f["erlaubt"] as! Bool {
                let next = try XCTUnwrap(result, titel)
                XCTAssertEqual(names(next), names(json: f["danach"] as! [String: Any]), titel)
                XCTAssertEqual(next.isWon, f["gewonnen"] as! Bool, titel)
            } else {
                XCTAssertNil(result, titel)
            }
        }
    }

    func testTipp() throws {
        let faelle = try TestJSON.cases("tripeaks/tipp")
        XCTAssertGreaterThanOrEqual(faelle.count, 8)
        for f in faelle {
            let titel = f["titel"] as! String
            let s = state(f["start"] as! [String: Any])
            if let t = f["tipp"] as? [String: Any] {
                XCTAssertEqual(TriPeaksRules.hint(s), move(t), titel)
            } else {
                XCTAssertNil(TriPeaksRules.hint(s), titel)
            }
            XCTAssertEqual(TriPeaksRules.isStuck(s), f["festgefahren"] as! Bool, titel)
        }
    }

    func testPartien() throws {
        for f in try TestJSON.cases("tripeaks/partien") {
            let titel = f["titel"] as! String
            var s = TriPeaksRules.deal(seed: UInt64(f["seed"] as! Int), mode: .tripeaks)
            for z in f["zuege"] as! [[String: Any]] {
                s = try XCTUnwrap(TriPeaksRules.apply(s, move(z)), "\(titel): Zug unerlaubt")
            }
            XCTAssertEqual(names(s), names(json: f["ende"] as! [String: Any]), titel)
            XCTAssertEqual(s.isWon, f["gewonnen"] as! Bool, titel)
            if let stuck = f["festgefahren"] as? Bool { XCTAssertEqual(TriPeaksRules.isStuck(s), stuck, titel) }
        }
    }

    func testTagesspiel() throws {
        let k = DealCatalog.load()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        for f in try TestJSON.cases("tripeaks/tagesspiel") {
            let teile = (f["datum"] as! String).split(separator: "-").map { Int($0)! }
            let tage = DealCatalog.daysSinceEpoch(year: teile[0], month: teile[1], day: teile[2], calendar: cal)
            XCTAssertEqual(tage, f["tage"] as! Int)
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage, kind: .tripeaks), UInt64(f["seed"] as! Int), f["datum"] as! String)
        }
    }

    func testZugschrift() {
        XCTAssertEqual(TriPeaksRules.solutionMoves(from: "T25 s T0"),
                       [.move(from: .column(25), to: .waste, count: 1), .draw, .move(from: .column(0), to: .waste, count: 1)])
        XCTAssertNil(TriPeaksRules.solutionMoves(from: "T28"))
        XCTAssertNil(TriPeaksRules.solutionMoves(from: "P3"))
    }

    func testSpielstandMitFehlendenFeldern() throws {
        let s = try JSONDecoder().decode(TriPeaksState.self, from: Data("{}".utf8))
        XCTAssertEqual(s.peaks.count, 28)
        XCTAssertEqual(s.chain, 0)
        XCTAssertEqual(s.score, 0)
    }

    func testTippenImStore() {
        var s = TriPeaksState()
        s.peaks[18] = TestJSON.card("6H"); s.peaks[19] = TestJSON.card("9C")
        s.waste = [TestJSON.card("5S")]
        let store = GameStore<TriPeaksRules>(mode: .tripeaks, prefs: AppPreferences(), seed: 1, url: nil)
        store.load(state: s)
        store.tap(card: TestJSON.card("9C"), source: CardSource(pile: .column(19), count: 1))     // passt nicht
        XCTAssertEqual(store.moves, 0)
        store.tap(card: TestJSON.card("6H"), source: CardSource(pile: .column(18), count: 1))
        XCTAssertEqual(store.moves, 1)
        XCTAssertEqual(store.state.score, 1)
        XCTAssertNil(store.selected)
    }

    func testBonusTextUndTonhoehe() {
        var s = TriPeaksState()
        s.peaks[0] = TestJSON.card("6H"); s.peaks[1] = TestJSON.card("6C"); s.peaks[2] = TestJSON.card("QD")
        s.waste = [TestJSON.card("5S")]
        s.chain = 2
        let m = Move.move(from: .column(0), to: .waste, count: 1)
        let n = TriPeaksRules.apply(s, m)!
        let popup = TriPeaksRules.bonusPopup(s, n, m)
        XCTAssertEqual(popup?.text, "+15")
        XCTAssertEqual(popup?.pile, .column(0))
        // letzter Gipfel: +30
        var l = TriPeaksState()
        l.peaks[2] = TestJSON.card("6H"); l.waste = [TestJSON.card("5S")]
        let ml = Move.move(from: .column(2), to: .waste, count: 1)
        XCTAssertEqual(TriPeaksRules.bonusPopup(l, TriPeaksRules.apply(l, ml)!, ml)?.text, "+30")
        // normale Karte: kein Bonus
        var k = TriPeaksState()
        k.peaks[18] = TestJSON.card("6H"); k.waste = [TestJSON.card("5S")]
        let mk = Move.move(from: .column(18), to: .waste, count: 1)
        XCTAssertNil(TriPeaksRules.bonusPopup(k, TriPeaksRules.apply(k, mk)!, mk))
        // Tonhöhe: Kette 4 → 0, 5 → +1, 11 → +7, 20 → +7
        func pitch(_ c: Int) -> Int { var t = TriPeaksState(); t.chain = c; return TriPeaksRules.soundPitch(t) }
        XCTAssertEqual([pitch(1), pitch(4), pitch(5), pitch(11), pitch(20)], [0, 0, 1, 7, 7])
    }
}
