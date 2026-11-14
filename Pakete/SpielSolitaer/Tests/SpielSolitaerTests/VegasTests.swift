// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

@MainActor
final class VegasTests: XCTestCase {
    private func vegas(_ s: GameState, scoring: Int = 1) -> GameState {
        var t = s; t.scoring = scoring; t.dollars = GameState.vegasStart; return t
    }

    /// Die 16 Partien aus `vegas.json`: Dollar nach jedem Zug, Ende, Sperre
    func testPartienAusDenRegeltests() throws {
        let faelle = try TestJSON.cases("vegas").filter { ($0["art"] as! String) == "partie" }
        XCTAssertEqual(faelle.count, 16)
        for f in faelle {
            let seed = UInt64(f["seed"] as! Int), draw = f["ziehen"] as! Int
            let titel = "Seed \(seed) ziehen \(draw)"
            var s = vegas(Deal.deal(seed: seed, draw: draw))
            let verlauf = f["punkteVerlauf"] as! [Int]
            let zuege = try XCTUnwrap(SolutionNotation.moves(f["zuege"] as! String), titel)
            XCTAssertEqual(verlauf.count, zuege.count, titel)          // ein Wert nach jedem Zug
            guard verlauf.count == zuege.count else { continue }
            for (i, m) in zuege.enumerated() {
                s = try XCTUnwrap(KlondikeRules.apply(s, m), "\(titel): Zug \(i + 1) unerlaubt")
                XCTAssertEqual(s.dollars, verlauf[i], "\(titel) nach Zug \(i + 1)")
            }
            XCTAssertEqual(s.dollars, f["punkteEnde"] as! Int, titel)
            XCTAssertEqual(s.passes, f["durchgaenge"] as! Int, titel)
            XCTAssertEqual(s.isWon, f["gewonnen"] as! Bool, titel)
            if let gesperrt = f["stapelGesperrt"] as? Bool { XCTAssertEqual(KlondikeRules.stockLocked(s), gesperrt, titel) }
            if let erlaubt = f["umdrehenErlaubt"] as? Bool { XCTAssertEqual(s.stock.isEmpty && !s.waste.isEmpty && KlondikeRules.apply(s, .draw) != nil, erlaubt, titel) }
        }
    }

    func testZeitbonus() throws {
        let faelle = try TestJSON.cases("vegas").filter { ($0["art"] as! String) == "zeitbonus" }
        XCTAssertEqual(faelle.count, 9)
        for f in faelle {
            XCTAssertEqual(KlondikeRules.timeBonus(seconds: f["sekunden"] as! Int), f["bonus"] as! Int, "\(f["sekunden"]!) s")
        }
    }

    func testBonusNurImStandard() {
        var g = GameState()
        XCTAssertEqual(KlondikeRules.timeBonus(g, seconds: 60), 11666)
        g.scoring = 1
        XCTAssertEqual(KlondikeRules.timeBonus(g, seconds: 60), 0)
        g.scoring = 3
        XCTAssertEqual(KlondikeRules.timeBonus(g, seconds: 60), 0)
    }

    func testAnzeigeUndRekordePunkte() {
        var g = GameState(); g.score = 215
        XCTAssertEqual(g.scoreText, "215"); XCTAssertEqual(g.recordScore, 215); XCTAssertFalse(g.scoreNegative)
        g.scoring = 1; g.dollars = -37
        XCTAssertEqual(g.scoreText, "−37"); XCTAssertTrue(g.scoreNegative); XCTAssertNil(g.recordScore)
        g.dollars = 18
        XCTAssertEqual(g.scoreText, "18"); XCTAssertFalse(g.scoreNegative)
        g.scoring = 3
        XCTAssertNil(g.scoreText); XCTAssertNil(g.displayScore); XCTAssertNil(g.recordScore)
    }

    func testTagesspielIstImmerStandard() {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "vg-\(UUID().uuidString)")!)
        prefs.klondikeScoring = 1
        XCTAssertEqual(KlondikeRules.prepare(GameState(), prefs: prefs, kind: .daily).scoring, 0)
        XCTAssertEqual(KlondikeRules.prepare(GameState(), prefs: prefs, kind: .solvable).scoring, 1)
        let st = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs, seed: 3, url: nil)
        XCTAssertEqual(st.state.scoring, 1)
        XCTAssertEqual(st.scoreText, "−52")
        st.start(DealInfo(seed: 4, mode: .klondike(1), kind: .daily, day: "2026-10-06"))
        XCTAssertEqual(st.state.scoring, 0)
    }

    func testRueckgaengigNimmtDollarMit() {
        var g = GameState()
        g.cols[0] = Column(down: [], up: [TestJSON.card("AH")])
        g = vegas(g)
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "vg-\(UUID().uuidString)")!)
        let st = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs, seed: 1, url: nil)
        st.load(state: g)
        st.perform(.move(from: .column(0), to: .foundation(1), count: 1))
        XCTAssertEqual(st.state.dollars, -47)
        st.undo()
        XCTAssertEqual(st.state.dollars, -52)
    }

    func testFortlaufendesKonto() {
        let s = StatsStore(url: nil)
        let d = DealInfo(seed: 5, mode: .klondike(1), kind: .solvable)
        s.handle(.started(d))
        s.handle(.account(d, -32))
        s.handle(.abandoned(d))                                          // Partie 1 verloren: −32 $
        s.handle(.started(d))
        s.handle(.account(d, 48))
        s.handle(.won(d, moves: 100, score: nil, seconds: 100, undoUsed: false, hintUsed: false))    // Partie 2 gewonnen: +48 $
        XCTAssertEqual(s.vegasAccount(.klondike(1)), 16)
        XCTAssertEqual(s.vegasAccount(.klondike(3)), 0)                  // je Zieh-Art ein Konto
        XCTAssertNil(s.stats(mode: .klondike(1)).highScore)              // Vegas zählt nicht für „Höchste Punkte“
        s.resetVegasAccount(.klondike(1))
        XCTAssertEqual(s.vegasAccount(.klondike(1)), 0)
    }

    func testKontoWirdBeiAufgebenUndNeuemSpielBuchungsereignis() {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "vg-\(UUID().uuidString)")!)
        prefs.klondikeScoring = 2
        prefs.autoFoundation = false                                   // sonst legt die Automatik ein Ass und ändert den Stand
        let st = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs, seed: 2, url: nil)
        var accounts: [Int] = []
        st.onEvent = { if case let .account(_, d) = $0 { accounts.append(d) } }
        st.drawStock()
        st.giveUp()
        XCTAssertEqual(accounts, [-52])
        st.newGame(); st.drawStock()
        st.newGame()                                                     // neue Partie nach angefangener: wieder verbucht
        XCTAssertEqual(accounts, [-52, -52])
    }

    func testKeineDurchgaengeMehr() {
        var g = GameState(draw: 1)
        g.waste = [TestJSON.card("5S")]
        g = vegas(g)
        XCTAssertNil(KlondikeRules.apply(g, .draw))                       // 1 Durchgang bei Ziehen 1: kein Umdrehen
        XCTAssertNotNil(KlondikeRules.drawBlockedMessage(g))
        var t = GameState(draw: 3)
        t.waste = [TestJSON.card("5S")]; t.passes = 1
        t = vegas(t)
        XCTAssertNotNil(KlondikeRules.apply(t, .draw))                    // Ziehen 3: 3 Durchgänge, hier erst der 2.
        t.passes = 2
        XCTAssertNil(KlondikeRules.apply(t, .draw))
        XCTAssertNotNil(KlondikeRules.apply(GameState(draw: 1, waste: [TestJSON.card("5S")]), .draw))   // Standard: unbegrenzt
    }
}
