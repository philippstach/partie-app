// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

final class LoesungenTests: XCTestCase {
    func testZugschrift() {
        XCTAssertEqual(SolutionNotation.move("s"), .draw)
        XCTAssertEqual(SolutionNotation.move("AZ2"), .move(from: .waste, to: .foundation(2), count: 1))
        XCTAssertEqual(SolutionNotation.move("AS4"), .move(from: .waste, to: .column(4), count: 1))
        XCTAssertEqual(SolutionNotation.move("S4Z3"), .move(from: .column(4), to: .foundation(3), count: 1))
        XCTAssertEqual(SolutionNotation.move("S1S0x4"), .move(from: .column(1), to: .column(0), count: 4))
        XCTAssertEqual(SolutionNotation.move("S0S9x13"), .move(from: .column(0), to: .column(9), count: 13))
        XCTAssertEqual(SolutionNotation.move("S2Z"), .move(from: .column(2), to: .foundation(0), count: 13))     // Spider-Abräumen
        XCTAssertNil(SolutionNotation.move("X3S1"))
        XCTAssertNil(SolutionNotation.move("S1S2y"))
        XCTAssertEqual(SolutionNotation.moves("s S1S0x2 AZ0")?.count, 3)
        XCTAssertNil(SolutionNotation.moves("s kaputt"))
    }

    private func spielen(_ state: GameState, _ moves: [Move]) -> GameState? {
        var s = state
        for m in moves { guard let n = KlondikeRules.apply(s, m) else { return nil }; s = n }
        return s
    }

    private func spielen(_ state: SpiderState, _ moves: [Move]) -> SpiderState? {
        var s = state
        for m in moves { guard let n = SpiderRules.apply(s, m) else { return nil }; s = n }
        return s
    }

    /// Die 12 Fälle aus den Regeltests: von der Startaufstellung, genau diese Züge, ohne Automatik → gewonnen
    func testRegeltestFaelle() throws {
        let bekannt = ["ziehen1", "ziehen3", "spider1", "spider2", "pyramid", "tripeaks", "golf", "yukon"]
        let faelle = try TestJSON.cases("extras/loesungen").filter { bekannt.contains($0["liste"] as! String) }
        XCTAssertEqual(faelle.count, 24)
        for f in faelle {
            let liste = f["liste"] as! String, seed = UInt64(f["seed"] as! Int)
            if liste == "pyramid" {
                let z = try XCTUnwrap(PyramidRules.solutionMoves(from: f["zuege"] as! String), "pyramid \(seed)")
                var s = PyramidRules.deal(seed: seed, mode: .pyramid)
                for m in z { s = try XCTUnwrap(PyramidRules.apply(s, m), "pyramid \(seed): Zug unerlaubt") }
                XCTAssertTrue(s.isWon, "pyramid \(seed)")
                continue
            }
            if liste == "yukon" {
                let z = try XCTUnwrap(YukonRules.solutionMoves(from: f["zuege"] as! String), "yukon \(seed)")
                var s = YukonRules.deal(seed: seed, mode: .yukon)
                for m in z { s = try XCTUnwrap(YukonRules.apply(s, m), "yukon \(seed): Zug unerlaubt") }
                XCTAssertTrue(s.isWon, "yukon \(seed)")
                continue
            }
            if liste == "golf" {
                let z = try XCTUnwrap(GolfRules.solutionMoves(from: f["zuege"] as! String), "golf \(seed)")
                var s = GolfRules.deal(seed: seed, mode: .golf)
                for m in z { s = try XCTUnwrap(GolfRules.apply(s, m), "golf \(seed): Zug unerlaubt") }
                XCTAssertTrue(s.isWon, "golf \(seed)")
                continue
            }
            if liste == "tripeaks" {
                let z = try XCTUnwrap(TriPeaksRules.solutionMoves(from: f["zuege"] as! String), "tripeaks \(seed)")
                var s = TriPeaksRules.deal(seed: seed, mode: .tripeaks)
                for m in z { s = try XCTUnwrap(TriPeaksRules.apply(s, m), "tripeaks \(seed): Zug unerlaubt") }
                XCTAssertTrue(s.isWon, "tripeaks \(seed)")
                continue
            }
            let zuege = try XCTUnwrap(SolutionNotation.moves(f["zuege"] as! String), "\(liste) \(seed)")
            switch liste {
            case "ziehen1", "ziehen3":
                let s = try XCTUnwrap(spielen(Deal.deal(seed: seed, draw: liste == "ziehen3" ? 3 : 1), zuege), "\(liste) \(seed): Zug unerlaubt")
                XCTAssertTrue(s.isWon, "\(liste) \(seed)")
            default:
                let farben = liste == "spider1" ? 1 : 2
                let s = try XCTUnwrap(spielen(SpiderRules.deal(seed: seed, mode: .spider(farben)), zuege), "\(liste) \(seed): Zug unerlaubt")
                XCTAssertTrue(s.isWon, "\(liste) \(seed)")
            }
        }
    }

    /// Alle 1.000 Pyramid-Lösungen gewinnen, in Reihenfolge der Liste, Länge wie angegeben
    func testAllePyramidLoesungenGewinnen() {
        let k = DealCatalog.shared
        let loesungen = SolutionLibrary.all(listName: "pyramid", parse: PyramidRules.solutionMoves)
        XCTAssertEqual(loesungen.map(\.seed), k.seeds(for: .pyramid))
        for (seed, moves) in loesungen {
            var s = PyramidRules.deal(seed: seed, mode: .pyramid)
            for m in moves { if let n = PyramidRules.apply(s, m) { s = n } else { XCTFail("pyramid \(seed): Zug unerlaubt"); break } }
            XCTAssertTrue(s.isWon, "pyramid \(seed)")
            if let laenge = k.solutionLengths["pyramid"]?[seed] { XCTAssertEqual(moves.count, laenge, "pyramid \(seed): Länge") }
        }
    }

    /// Alle TriPeaks-Lösungen gewinnen, in Reihenfolge der Liste, Länge wie angegeben
    func testAlleTriPeaksLoesungenGewinnen() {
        let k = DealCatalog.shared
        let loesungen = SolutionLibrary.all(listName: "tripeaks", parse: TriPeaksRules.solutionMoves)
        XCTAssertEqual(loesungen.map(\.seed), k.seeds(for: .tripeaks))
        XCTAssertFalse(loesungen.isEmpty)
        for (seed, moves) in loesungen {
            var s = TriPeaksRules.deal(seed: seed, mode: .tripeaks)
            for m in moves { if let n = TriPeaksRules.apply(s, m) { s = n } else { XCTFail("tripeaks \(seed): Zug unerlaubt"); break } }
            XCTAssertTrue(s.isWon, "tripeaks \(seed)")
            if let laenge = k.solutionLengths["tripeaks"]?[seed] { XCTAssertEqual(moves.count, laenge, "tripeaks \(seed): Länge") }
        }
    }

    /// Alle Yukon-Lösungen gewinnen, in Reihenfolge der Liste, Länge wie angegeben
    func testAlleYukonLoesungenGewinnen() {
        let k = DealCatalog.shared
        let loesungen = SolutionLibrary.all(listName: "yukon", parse: YukonRules.solutionMoves)
        XCTAssertEqual(loesungen.map(\.seed), k.seeds(for: .yukon))
        XCTAssertEqual(loesungen.count, 1000)
        for (seed, moves) in loesungen {
            var s = YukonRules.deal(seed: seed, mode: .yukon)
            for m in moves { if let n = YukonRules.apply(s, m) { s = n } else { XCTFail("yukon \(seed): Zug unerlaubt"); break } }
            XCTAssertTrue(s.isWon, "yukon \(seed)")
            if let laenge = k.solutionLengths["yukon"]?[seed] { XCTAssertEqual(moves.count, laenge, "yukon \(seed): Länge") }
        }
    }

    /// Alle Golf-Lösungen gewinnen, in Reihenfolge der Liste, Länge wie angegeben
    func testAlleGolfLoesungenGewinnen() {
        let k = DealCatalog.shared
        let loesungen = SolutionLibrary.all(listName: "golf", parse: GolfRules.solutionMoves)
        XCTAssertEqual(loesungen.map(\.seed), k.seeds(for: .golf))
        XCTAssertFalse(loesungen.isEmpty)
        for (seed, moves) in loesungen {
            var s = GolfRules.deal(seed: seed, mode: .golf)
            for m in moves { if let n = GolfRules.apply(s, m) { s = n } else { XCTFail("golf \(seed): Zug unerlaubt"); break } }
            XCTAssertTrue(s.isWon, "golf \(seed)")
            if let laenge = k.solutionLengths["golf"]?[seed] { XCTAssertEqual(moves.count, laenge, "golf \(seed): Länge") }
        }
    }

    /// Eigener Test über ALLE Lösungen aller Listen (4 × 1.000)
    func testAlleLoesungenGewinnen() {
        let k = DealCatalog.shared
        for (name, mode) in [("ziehen1", GameMode.klondike(1)), ("ziehen3", .klondike(3)), ("spider1", .spider(1)), ("spider2", .spider(2))] {
            let loesungen = SolutionLibrary.all(listName: name)
            XCTAssertEqual(loesungen.map(\.seed), k.seeds(for: mode), "\(name): gleiche Reihenfolge wie die Liste")
            for (seed, moves) in loesungen {
                if mode.kind == .klondike {
                    XCTAssertTrue(spielen(Deal.deal(seed: seed, draw: mode.option), moves)?.isWon == true, "\(name) \(seed)")
                } else {
                    XCTAssertTrue(spielen(SpiderRules.deal(seed: seed, mode: mode), moves)?.isWon == true, "\(name) \(seed)")
                }
                // Länge passt zur Angabe der Liste (Spider: ohne die 8 Abräum-Züge)
                if let laenge = k.solutionLengths[name]?[seed] {
                    XCTAssertEqual(moves.count, laenge, "\(name) \(seed): Länge")
                }
            }
        }
    }

    func testBibliothekFindetLoesungDerPartie() {
        let deal = DealInfo(seed: 2, mode: .klondike(1), kind: .solvable)
        XCTAssertTrue(SolutionLibrary.hasSolution(for: deal))
        XCTAssertNotNil(SolutionLibrary.moves(for: deal))
        XCTAssertFalse(SolutionLibrary.hasSolution(for: DealInfo(seed: 2, mode: .klondike(1), kind: .random)))      // Zufall: keine Lösung
        XCTAssertFalse(SolutionLibrary.hasSolution(for: DealInfo(seed: 617, mode: .freecell, kind: .solvable)))
        XCTAssertFalse(SolutionLibrary.hasSolution(for: DealInfo(seed: 5, mode: .spider(4), kind: .random)))
        XCTAssertNil(SolutionLibrary.moves(for: DealInfo(seed: 999_999_999, mode: .klondike(1), kind: .solvable)))
    }
}

@MainActor
final class AufgebenTests: XCTestCase {
    private func prefs() -> AppPreferences { AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!) }

    private func spiel() -> (GameStore<KlondikeRules>, [GameEvent]) {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        var s = KlondikeRules.deal(seed: 2, mode: .klondike(1))
        for _ in 0..<10 { guard let m = KlondikeRules.hint(s), let n = KlondikeRules.apply(s, m) else { break }; s = n }
        store.load(state: s, deal: DealInfo(seed: 2, mode: .klondike(1), kind: .solvable))
        return (store, [])
    }

    func testAufgebenZaehltEinmalAlsVerlorenUndSperrtDenTisch() {
        let (store, _) = spiel()
        var abgebrochen = 0
        store.onEvent = { if case .abandoned = $0 { abgebrochen += 1 } }
        let vorher = store.state
        store.giveUp()
        XCTAssertTrue(store.gaveUp)
        XCTAssertEqual(abgebrochen, 1)
        store.giveUp()                                            // zweites Mal: nichts
        XCTAssertEqual(abgebrochen, 1)
        XCTAssertFalse(store.perform(.draw))                      // Tisch gesperrt
        XCTAssertFalse(store.canUndo)
        store.drawStock()
        XCTAssertEqual(store.state, vorher)
        // Neues Spiel nach dem Aufgeben zählt nicht noch einmal als abgebrochen
        store.newGame()
        XCTAssertEqual(abgebrochen, 1)
        XCTAssertFalse(store.gaveUp)
    }

    func testAufgebenOhneZugZaehltNicht() {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        var abgebrochen = 0
        store.onEvent = { if case .abandoned = $0 { abgebrochen += 1 } }
        store.giveUp()
        XCTAssertEqual(abgebrochen, 0)
    }

    func testLoesungAbspielenBisZumSieg() throws {
        let (store, _) = spiel()
        XCTAssertFalse(store.solutionAvailable == false)
        store.giveUp()
        XCTAssertTrue(store.solutionAvailable)
        store.viewSolution()
        XCTAssertTrue(store.replaying)
        XCTAssertEqual(store.state, KlondikeRules.deal(seed: 2, mode: .klondike(1)))        // von der Startaufstellung
        XCTAssertEqual(store.solutionIndex, 0)
        XCTAssertGreaterThan(store.solutionCount, 100)
        // Schritt vor, Schritt zurück
        store.solutionStep(1); store.solutionStep(1); store.solutionStep(1)
        XCTAssertEqual(store.solutionIndex, 3)
        XCTAssertTrue(store.solutionPaused)
        let nachDrei = store.state
        store.solutionStep(1)
        store.solutionStep(-1)
        XCTAssertEqual(store.state, nachDrei)                                                // zurück = genau der Zustand davor
        XCTAssertEqual(store.solutionIndex, 3)
        // bis zum Ende
        for _ in 0..<store.solutionCount { store.solutionStep(1) }
        XCTAssertEqual(store.solutionIndex, store.solutionCount)
        XCTAssertTrue(store.state.isWon)
        XCTAssertFalse(store.isWon, "während des Abspielens und danach gibt es keine Gewonnen-Karte")
        store.endSolution()
        XCTAssertFalse(store.replaying)
        XCTAssertTrue(store.solutionViewed)
        XCTAssertFalse(store.isWon)
        XCTAssertTrue(store.gaveUp)                                                           // Partie bleibt zu Ende
    }

    func testZurueckAmAnfangUndAbspielenAmEndeStartetNeu() {
        let (store, _) = spiel()
        store.giveUp(); store.viewSolution()
        store.solutionStep(-1)
        XCTAssertEqual(store.solutionIndex, 0)
        for _ in 0..<store.solutionCount { store.solutionStep(1) }
        store.toggleSolutionPause()                         // am Ende: noch einmal von vorn
        XCTAssertEqual(store.solutionIndex, 0)
        XCTAssertFalse(store.solutionPaused)
        store.toggleSolutionPause()
        XCTAssertTrue(store.solutionPaused)
        store.endSolution()
    }

    func testKeineLoesungBeiZufallUndFreeCell() {
        let p = prefs()
        let zufall = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 7, url: nil)    // seed → Zufallspartie
        zufall.drawStock()
        zufall.giveUp()
        XCTAssertFalse(zufall.solutionAvailable)
        zufall.viewSolution()
        XCTAssertFalse(zufall.replaying)
        let fc = GameStore<FreeCellRules>(mode: .freecell, prefs: p, seed: 617, url: nil)
        XCTAssertFalse(fc.solutionAvailable)
    }

    func testAufgegebenWirdGespeichertUndGeladen() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "aufgeben-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let p = prefs()
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 4, url: url)
        store.drawStock()
        store.giveUp()
        await store.settleSaves()
        let geladen = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, url: url)
        XCTAssertTrue(geladen.gaveUp)
    }
}
