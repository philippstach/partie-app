// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Prüft jede Datei aus `Shared/regeltests/yukon/` vollständig.
@MainActor
final class YukonRegeltestsTests: XCTestCase {
    private struct Names: Equatable {
        var spalten: [[[String]]]
        var ziel: [Int]
        var punkte: Int
        var zuege: Int
    }

    private func names(_ s: YukonState) -> Names {
        Names(spalten: s.cols.map { [$0.down.map(\.shortName), $0.up.map(\.shortName)] }, ziel: s.foundation, punkte: s.score, zuege: s.moves)
    }

    private func state(_ d: [String: Any]) -> YukonState {
        let cols = (d["spalten"] as? [[String: Any]] ?? []).map { Column(down: TestJSON.cards($0["verdeckt"]), up: TestJSON.cards($0["offen"])) }
        return YukonState(cols: cols, foundation: d["ziel"] as? [Int] ?? [0, 0, 0, 0], score: d["punkte"] as? Int ?? 0, moves: d["zuege"] as? Int ?? 0)
    }

    private func pile(_ s: String) -> Pile {
        let k = Int(s.dropFirst()) ?? 0
        return s.hasPrefix("S") ? .column(k) : .foundation(k)
    }

    private func move(_ d: [String: Any]) -> Move {
        .move(from: pile(d["von"] as! String), to: pile(d["nach"] as! String), count: d["anzahl"] as? Int ?? 1)
    }

    private func moves(_ any: Any?) -> [Move] { (any as? [[String: Any]] ?? []).map(move) }

    func testGeben() throws {
        let faelle = try TestJSON.cases("yukon/geben")
        XCTAssertGreaterThanOrEqual(faelle.count, 4)
        for f in faelle {
            let seed = UInt64(f["seed"] as! Int)
            let s = YukonRules.deal(seed: seed, mode: .yukon)
            XCTAssertEqual(names(s), names(state(f["zustand"] as! [String: Any])), "Seed \(seed)")
            XCTAssertEqual(s.cols.map { $0.down.count }, [0, 1, 2, 3, 4, 5, 6])
            XCTAssertEqual(s.cols.map { $0.up.count }, [1, 5, 5, 5, 5, 5, 5])
        }
    }

    func testZuege() throws {
        let faelle = try TestJSON.cases("yukon/zuege")
        XCTAssertGreaterThanOrEqual(faelle.count, 30)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            let result = YukonRules.apply(start, move(f["zug"] as! [String: Any]))
            if f["erlaubt"] as! Bool {
                let next = try XCTUnwrap(result, titel)
                XCTAssertEqual(names(next), names(state(f["danach"] as! [String: Any])), titel)
                XCTAssertEqual(next.isWon, f["gewonnen"] as! Bool, titel)
            } else {
                XCTAssertNil(result, titel)
            }
        }
    }

    func testTippen() throws {
        for f in try TestJSON.cases("yukon/tippen") {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            let expected = (f["zug"] as? [String: Any]).map(move)
            XCTAssertEqual(YukonRules.tapTarget(start, from: pile(f["quelle"] as! String), count: f["anzahl"] as? Int ?? 1), expected, titel)
        }
    }

    func testAutoAblegen() throws {
        for f in try TestJSON.cases("yukon/autoablegen") {
            let titel = f["titel"] as! String
            XCTAssertEqual(YukonRules.autoFoundationMoves(state(f["start"] as! [String: Any])), moves(f["zuege"]), titel)
            XCTAssertEqual(YukonRules.autoMoves(state(f["start"] as! [String: Any]), autoFoundation: false), [], titel)
        }
    }

    func testBeenden() throws {
        for f in try TestJSON.cases("yukon/beenden") {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            XCTAssertEqual(YukonRules.canAutoFinish(start), f["angeboten"] as! Bool, titel)
            if f["angeboten"] as! Bool { XCTAssertEqual(YukonRules.autoFinishMoves(start), moves(f["zuege"]), titel) }
        }
    }

    func testTipp() throws {
        let faelle = try TestJSON.cases("yukon/tipp")
        XCTAssertGreaterThanOrEqual(faelle.count, 20)
        for f in faelle {
            let titel = f["titel"] as! String
            let start = state(f["start"] as! [String: Any])
            XCTAssertEqual(YukonRules.hint(start), (f["tipp"] as? [String: Any]).map(move), titel)
            XCTAssertEqual(YukonRules.isStuck(start), f["festgefahren"] as! Bool, titel)
        }
    }

    func testPartien() throws {
        for f in try TestJSON.cases("yukon/partien") {
            let titel = f["titel"] as! String
            var s = YukonRules.deal(seed: UInt64(f["seed"] as! Int), mode: .yukon)
            if titel.hasPrefix("Tipp-Spieler") {
                // hint, danach automatisch ablegen, bis es keinen Tipp mehr gibt – die Liste enthält jeden Zug
                var played: [Move] = []
                while let m = YukonRules.hint(s) {
                    s = try XCTUnwrap(YukonRules.apply(s, m), titel)
                    played.append(m)
                    for a in YukonRules.autoFoundationMoves(s) { s = YukonRules.apply(s, a)!; played.append(a) }
                    XCTAssertLessThan(played.count, 1000, titel)
                }
                XCTAssertEqual(played, moves(f["zuege"]), titel)
            } else {
                for m in moves(f["zuege"]) { s = try XCTUnwrap(YukonRules.apply(s, m), "\(titel): Zug unerlaubt") }
            }
            XCTAssertEqual(names(s), names(state(f["ende"] as! [String: Any])), titel)
            XCTAssertEqual(s.isWon, f["gewonnen"] as! Bool, titel)
            if let stuck = f["festgefahren"] as? Bool { XCTAssertEqual(YukonRules.isStuck(s), stuck, titel) }
        }
    }

    func testTagesspiel() throws {
        let k = DealCatalog.shared
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        for f in try TestJSON.cases("yukon/tagesspiel") {
            let teile = (f["datum"] as! String).split(separator: "-").map { Int($0)! }
            let tage = DealCatalog.daysSinceEpoch(year: teile[0], month: teile[1], day: teile[2], calendar: cal)
            XCTAssertEqual(tage, f["tage"] as! Int)
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage, kind: .yukon), UInt64(f["seed"] as! Int), f["datum"] as! String)
        }
    }

    func testZugschriftUndZustand() throws {
        XCTAssertEqual(YukonRules.solutionMoves(from: "S2S5x3 S2Z1 Z1S4"),
                       [.move(from: .column(2), to: .column(5), count: 3), .move(from: .column(2), to: .foundation(1), count: 1),
                        .move(from: .foundation(1), to: .column(4), count: 1)])
        XCTAssertNil(YukonRules.solutionMoves(from: "S2T5"))
        // Speichern und Laden; fehlende Felder → Standardwert
        let s = YukonRules.deal(seed: 3, mode: .yukon)
        XCTAssertEqual(try JSONDecoder().decode(YukonState.self, from: JSONEncoder().encode(s)), s)
        let leer = try JSONDecoder().decode(YukonState.self, from: Data("{}".utf8))
        XCTAssertEqual(leer, YukonState())
        XCTAssertEqual(leer.cols.count, 7)
    }

    /// Jede Partie-Liste im Bundle lädt (Lehre aus Runde 4: golf.json fehlte im Projekt)
    func testJedeListeLaedtImBundle() {
        let k = DealCatalog.load()
        for mode in [GameMode.klondike(1), .klondike(3), .spider(1), .spider(2), .pyramid, .tripeaks, .golf, .yukon] {
            XCTAssertFalse(k.seeds(for: mode).isEmpty, "Liste \(mode.key) leer – fehlt sie im Xcode-Projekt?")
            XCTAssertNotNil(k.solutionLengths[k.listName(for: mode) ?? ""], "Lösungen \(mode.key)")
        }
        XCTAssertEqual(k.seeds(for: .yukon).count, 1000)
    }

    /// Die Austeil-Reihenfolge ist eine Vertauschung von 0…51
    func testAusteilReihenfolge() {
        let s = YukonRules.deal(seed: 1, mode: .yukon)
        let orders = CardID.all.compactMap { s.dealOrder(of: $0) }
        XCTAssertEqual(Set(orders), Set(0..<52))
        // Karte 0 des Decks liegt offen in Spalte 0
        XCTAssertEqual(s.dealOrder(of: s.cols[0].up[0]), 0)
    }

    /// Layout hoch und quer: jede offene Karte ist greifbar und nimmt alles darüber mit
    func testJedeOffeneKarteIstGreifbar() {
        let s = YukonRules.deal(seed: 1, mode: .yukon)
        for size in [CGSize(width: 393, height: 600), CGSize(width: 700, height: 300)] {
            let layout = YukonLayout(state: s, size: size, prefs: TablePrefs())
            for (i, col) in s.cols.enumerated() {
                for (k, c) in col.up.enumerated() {
                    XCTAssertEqual(layout.sources[c]?.pile, .column(i))
                    XCTAssertEqual(layout.sources[c]?.count, col.up.count - k)
                }
                for c in col.down { XCTAssertNil(layout.sources[c]) }
            }
            XCTAssertEqual(layout.placements.count, 52)
        }
    }
}
