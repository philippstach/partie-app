// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

final class TageszielTests: XCTestCase {
    private func game(_ s: String) -> DailyGame { DailyGame(rawValue: s)! }

    func testAlleFaelleAusDenRegeltests() throws {
        let faelle = try TestJSON.cases("extras/tagesziel")
        XCTAssertEqual(faelle.count, 56)
        let katalog = DealCatalog.load()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        for f in faelle {
            let titel = "\(f["datum"]!) \(f["spiel"]!)"
            let teile = (f["datum"] as! String).split(separator: "-").map { Int($0)! }
            let nummer = DailyGoalCalc.dateNumber(year: teile[0], month: teile[1], day: teile[2])
            let spiel = game(f["spiel"] as! String)
            XCTAssertEqual(nummer * 10 + spiel.number, f["seed"] as! Int, titel)
            XCTAssertEqual(DailyGoalCalc.index(game: spiel, dateNumber: nummer), f["ziel"] as! Int, titel)

            // Lösungslänge der Tagespartie (nur Klondike und Spider haben Listen)
            var laenge: Int?
            if let partie = f["partieSeed"] as? Int, let kind = [DailyGame.klondike: GameKind.klondike, .spider: .spider][spiel] {
                let datum = cal.date(from: DateComponents(year: teile[0], month: teile[1], day: teile[2]))!
                XCTAssertEqual(katalog.dailySeed(for: datum, kind: kind, calendar: cal), UInt64(partie), "Tagespartie \(titel)")
                laenge = katalog.solutionLength(kind: kind, seed: UInt64(partie))
                XCTAssertNotNil(laenge, "Lösungslänge \(titel)")
            }
            let ziel = DailyGoalCalc.goal(game: spiel, dateNumber: nummer, solutionMoves: laenge)
            XCTAssertEqual(ziel.artKey, f["art"] as! String, titel)
            if let grenze = f["grenze"] as? Int {
                XCTAssertEqual(ziel, .moves(limit: grenze), titel)
            }
        }
    }

    func testZielErreicht() {
        XCTAssertTrue(DailyGoal.win.isReached(moves: 500, seconds: 9999, undoUsed: true, hintUsed: true))
        XCTAssertTrue(DailyGoal.moves(limit: 100).isReached(moves: 100, seconds: 0, undoUsed: true, hintUsed: true))
        XCTAssertFalse(DailyGoal.moves(limit: 100).isReached(moves: 101, seconds: 0, undoUsed: false, hintUsed: false))
        XCTAssertTrue(DailyGoal.noUndo.isReached(moves: 1, seconds: 1, undoUsed: false, hintUsed: true))
        XCTAssertFalse(DailyGoal.noUndo.isReached(moves: 1, seconds: 1, undoUsed: true, hintUsed: false))
        XCTAssertTrue(DailyGoal.noHint.isReached(moves: 1, seconds: 1, undoUsed: true, hintUsed: false))
        XCTAssertFalse(DailyGoal.noHint.isReached(moves: 1, seconds: 1, undoUsed: false, hintUsed: true))
        // „unter 6 Minuten“ zählt ganze Sekunden wie angezeigt: 5:59 ja, 6:00 nein
        XCTAssertTrue(DailyGoal.underMinutes(6).isReached(moves: 1, seconds: 359.9, undoUsed: false, hintUsed: false))
        XCTAssertFalse(DailyGoal.underMinutes(6).isReached(moves: 1, seconds: 360, undoUsed: false, hintUsed: false))
    }

    func testAufrundenOhneRundungsfehler() {
        XCTAssertEqual(DailyGoalCalc.ceilTimes14(145), 203)     // 145 × 1,4 = 203,0 genau
        XCTAssertEqual(DailyGoalCalc.ceilTimes14(167), 234)     // 233,8 → 234
        XCTAssertEqual(DailyGoalCalc.ceilTimes14(1), 2)
    }

    func testFehlendeLoesungMachtAusZuegeGewinnen() {
        // Datum mit Ziel 1 für Klondike suchen und ohne Lösungslänge auswerten
        for tag in 1...31 {
            let n = DailyGoalCalc.dateNumber(year: 2026, month: 1, day: tag)
            if DailyGoalCalc.index(game: .klondike, dateNumber: n) == 1 {
                XCTAssertEqual(DailyGoalCalc.goal(game: .klondike, dateNumber: n, solutionMoves: nil), .win)
                return
            }
        }
        XCTFail("kein Tag mit Ziel 1 im Januar gefunden")
    }
}

@MainActor
final class KronenTests: XCTestCase {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone.current
        return c
    }

    /// Ein Tag im Januar 2026, an dem das Klondike-Tagesziel die gewünschte Nummer hat
    private func day(withKlondikeGoal index: Int) -> (Date, String) {
        for tag in 1...31 {
            let date = cal.date(from: DateComponents(year: 2026, month: 1, day: tag))!
            if DailyGoalCalc.index(game: .klondike, dateNumber: DailyGoalCalc.dateNumber(of: date, calendar: cal)) == index {
                return (date, DailyDate.string(date, calendar: cal))
            }
        }
        fatalError("kein Tag gefunden")
    }

    private func daily(_ key: String) -> DealInfo { DealInfo(seed: 2, mode: .klondike(1), kind: .daily, day: key) }

    func testKroneNurWennZielErreicht() {
        let (_, key) = day(withKlondikeGoal: 2)               // „ohne Rückgängig“
        let s = StatsStore(url: nil)
        s.handle(.started(daily(key)))
        s.handle(.won(daily(key), moves: 100, score: 100, seconds: 100, undoUsed: true, hintUsed: false))
        XCTAssertEqual(s.lastDaily?.goal, .noUndo)
        XCTAssertEqual(s.lastDaily?.crowned, false)
        XCTAssertTrue(s.dailyWon(.klondike).contains(key))                 // Haken trotzdem
        XCTAssertTrue(s.crowned(.klondike).isEmpty)

        s.handle(.started(daily(key)))
        s.handle(.won(daily(key), moves: 100, score: 100, seconds: 100, undoUsed: false, hintUsed: true))
        XCTAssertEqual(s.lastDaily?.crowned, true)
        XCTAssertEqual(s.crowned(.klondike), [key])
        // gleicher Tag noch einmal: bleibt eine Krone
        s.handle(.won(daily(key), moves: 100, score: 100, seconds: 100, undoUsed: false, hintUsed: false))
        XCTAssertEqual(s.crownCount(.klondike), 1)
    }

    func testZeitZielUndGewinnenZiel() {
        let (_, schnell) = day(withKlondikeGoal: 3)            // „unter 6 Minuten“
        let s = StatsStore(url: nil)
        s.handle(.won(daily(schnell), moves: 100, score: 100, seconds: 361, undoUsed: false, hintUsed: false))
        XCTAssertEqual(s.lastDaily?.crowned, false)
        s.handle(.won(daily(schnell), moves: 100, score: 100, seconds: 359, undoUsed: true, hintUsed: true))
        XCTAssertEqual(s.lastDaily?.crowned, true)

        let (_, einfach) = day(withKlondikeGoal: 0)            // „gewinnen“
        s.handle(.won(daily(einfach), moves: 999, score: 0, seconds: 9999, undoUsed: true, hintUsed: true))
        XCTAssertEqual(s.lastDaily?.crowned, true)
    }

    func testNormalePartieBringtKeineKrone() {
        let s = StatsStore(url: nil)
        s.handle(.won(DealInfo(seed: 3, mode: .klondike(1), kind: .solvable), moves: 100, score: 100, seconds: 100))
        XCTAssertNil(s.lastDaily)
        XCTAssertEqual(s.crownCount(.klondike), 0)
    }

    func testMonatspokale() {
        let s = StatsStore(url: nil)
        func krone(_ monat: Int, _ tag: Int) -> String { String(format: "2026-%02d-%02d", monat, tag) }
        var d = StatsData()
        d.daily["klondike", default: DailyRecord()].crowned = Set((1...9).map { krone(1, $0) })
        s.load(d)
        XCTAssertNil(s.cup(kind: .klondike, year: 2026, month: 1))                      // 9 Kronen: noch nichts
        d.daily["klondike"]!.crowned.insert(krone(1, 10))
        s.load(d)
        XCTAssertEqual(s.cup(kind: .klondike, year: 2026, month: 1), .bronze)           // ab 10
        d.daily["klondike"]!.crowned = Set((1...20).map { krone(1, $0) })
        s.load(d)
        XCTAssertEqual(s.cup(kind: .klondike, year: 2026, month: 1), .silver)           // ab 20
        d.daily["klondike"]!.crowned = Set((1...31).map { krone(1, $0) })
        s.load(d)
        XCTAssertEqual(s.cup(kind: .klondike, year: 2026, month: 1), .gold)             // alle 31 Tage
        // Februar hat 28 Tage: 28 Kronen = Gold
        d.daily["klondike"]!.crowned = Set((1...28).map { krone(2, $0) })
        s.load(d)
        XCTAssertEqual(s.cup(kind: .klondike, year: 2026, month: 2), .gold)
        // je Spiel getrennt
        XCTAssertNil(s.cup(kind: .spider, year: 2026, month: 2))
    }

    func testPokaleZaehlenJeStufe() {
        let s = StatsStore(url: nil)
        var d = StatsData()
        var kronen = Set<String>()
        for t in 1...10 { kronen.insert(String(format: "2026-01-%02d", t)) }     // Bronze
        for t in 1...20 { kronen.insert(String(format: "2026-02-%02d", t)) }     // Silber
        for t in 1...31 { kronen.insert(String(format: "2026-03-%02d", t)) }     // Gold
        for t in 1...5 { kronen.insert(String(format: "2026-04-%02d", t)) }      // keiner
        d.daily["klondike", default: DailyRecord()].crowned = kronen
        s.load(d)
        XCTAssertEqual(s.cupTotals(kind: .klondike), [.bronze: 1, .silver: 1, .gold: 1])
        XCTAssertEqual(s.crownCount(.klondike), 66)
    }

    func testNeuerPokalWirdGemeldet() {
        // 9 Kronen im Januar, die 10. bringt Bronze
        let s = StatsStore(url: nil)
        var d = StatsData()
        d.daily["klondike", default: DailyRecord()].crowned = Set((2...10).map { String(format: "2026-01-%02d", $0) })
        s.load(d)
        let (_, key) = day(withKlondikeGoal: 0)
        XCTAssertTrue(key.hasPrefix("2026-01"))
        if !s.crowned(.klondike).contains(key) {
            s.handle(.won(daily(key), moves: 100, score: 100, seconds: 100))
            XCTAssertEqual(s.lastDaily?.newCup, .bronze)
        }
    }

    func testAlteDateienOhneKronenLaden() throws {
        // Statistik ohne `crowned`: Kronen starten leer
        let alt = "{\"version\":2,\"modes\":{},\"daily\":{\"klondike\":{\"won\":[\"2026-10-04\"],\"started\":[]}}}"
        let data = try JSONDecoder().decode(StatsData.self, from: Data(alt.utf8))
        XCTAssertEqual(data.daily["klondike"]?.won, ["2026-10-04"])
        XCTAssertEqual(data.daily["klondike"]?.crowned, [])
    }
}

@MainActor
final class TippUndRueckgaengigTests: XCTestCase {
    private func prefs() -> AppPreferences { AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!) }

    func testMerkerFuerUndoUndTipp() {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        XCTAssertFalse(store.undoUsed)
        XCTAssertFalse(store.hintUsed)
        store.drawStock()
        store.showHint()
        XCTAssertTrue(store.hintUsed)
        XCTAssertFalse(store.undoUsed)
        store.undo()
        XCTAssertTrue(store.undoUsed)
        store.newGame()
        XCTAssertFalse(store.undoUsed)                                       // neue Partie: wieder frisch
        XCTAssertFalse(store.hintUsed)
    }

    func testGewonnenMeldetMerkerImEreignis() {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        var s = GameState(draw: 1, foundation: [13, 13, 13, 12])
        s.cols[0] = Column(up: [CardID(rank: 13, suit: .clubs)])
        store.load(state: s)
        store.drawStock()                                                    // kein Zug möglich im leeren Stapel – egal
        store.showHint()
        var gemeldet: (undo: Bool, hint: Bool)?
        store.onEvent = { if case let .won(_, _, _, _, undo, hint) = $0 { gemeldet = (undo, hint) } }
        store.perform(.move(from: .column(0), to: .foundation(3), count: 1))
        XCTAssertEqual(gemeldet?.hint, true)
        XCTAssertEqual(gemeldet?.undo, false)
    }

    func testSpeichernUndLadenMerkerUndAlteDateien() async throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "merker-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let p = prefs()
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 4, url: url)
        store.drawStock()
        store.showHint()
        await store.settleSaves()
        let geladen = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, url: url)
        XCTAssertTrue(geladen.hintUsed)
        XCTAssertFalse(geladen.undoUsed)
        // alter Spielstand ohne die Felder
        let state = Deal.deal(seed: 3, draw: 1)
        let json = "{\"state\":\(String(data: try JSONEncoder().encode(state), encoding: .utf8)!),\"deal\":{\"seed\":3,\"draw\":1,\"kind\":\"random\"}}"
        try json.write(to: url, atomically: true, encoding: .utf8)
        let alt = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, url: url)
        XCTAssertFalse(alt.hintUsed)
        XCTAssertFalse(alt.undoUsed)
    }
}
