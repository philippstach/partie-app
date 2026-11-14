// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielYacht

@MainActor
final class GameStoreTests: XCTestCase {
    private var dir: URL!

    override func setUp() {
        dir = FileManager.default.temporaryDirectory.appending(path: "yacht-test-\(UUID().uuidString)")
    }

    override func tearDown() { try? FileManager.default.removeItem(at: dir) }

    private func makeStore(dice: [Int] = []) -> GameStore {
        let store = GameStore(repository: FileGameRepository(directory: dir))
        var feed = dice[...]
        store.roller = { feed.popFirst() ?? 3 }
        return store
    }

    private let players = [Player(name: "Anna", avatar: "😎", colorIndex: 0), Player(name: "Ben", avatar: "🤠", colorIndex: 1)]

    func testSpeichernUndWeiterspielen() {
        let store = makeStore(dice: [1, 2, 3, 4, 5])
        store.startGame(players: players, settings: GameSettings())
        XCTAssertTrue(store.roll())
        XCTAssertTrue(store.score(.chance))
        // „App-Neustart“: ein neuer Store liest dieselbe Ablage
        let again = GameStore(repository: FileGameRepository(directory: dir))
        XCTAssertEqual(again.records.count, 1)
        let r = again.records[0]
        XCTAssertEqual(r.state.players[0].scores[.chance], 15)
        XCTAssertEqual(r.state.current, 1)
        XCTAssertEqual(r.timeline.last, [15, 0])
        XCTAssertNotNil(r.undo)
    }

    func testBeschaedigterStandWirdUebersprungen() throws {
        let store = makeStore()
        store.startGame(players: players, settings: GameSettings())
        try Data("{kaputt".utf8).write(to: dir.appending(path: "\(UUID().uuidString).json"))
        // Stimmiges JSON, aber unmöglicher Zustand (Wurfzähler 9)
        var bad = GameRecord(players: players, settings: GameSettings())
        bad.state.rollsUsed = 9
        try FileGameRepository(directory: dir).save(bad)
        let again = GameStore(repository: FileGameRepository(directory: dir))
        XCTAssertEqual(again.records.count, 1)
    }

    func testAlterStandMitFehlendenFeldernLaedt() throws {
        let json = """
        {"version":1,"record":{"players":[{"name":"Solo"}],"state":{"players":[{"name":"Solo"}]}}}
        """
        let record = try XCTUnwrap(FileGameRepository.decode(Data(json.utf8)))
        XCTAssertEqual(record.players[0].name, "Solo")
        XCTAssertEqual(record.state.rules, Rules())
        XCTAssertEqual(record.timeline, [[0]])
    }

    func testRueckgaengigNachFeldEintragen() {
        let store = makeStore(dice: [6, 6, 6, 6, 6])
        store.startGame(players: players, settings: GameSettings())
        store.roll()
        store.score(.kniffel)
        XCTAssertEqual(store.game?.state.current, 1)
        store.undo()
        XCTAssertEqual(store.game?.state.current, 0)
        XCTAssertEqual(store.game?.state.dice, [6, 6, 6, 6, 6])
        XCTAssertEqual(store.game?.state.rollsUsed, 1)
        XCTAssertNil(store.game?.state.players[0].scores[.kniffel])
        XCTAssertEqual(store.game?.timeline.count, 1)
        XCTAssertFalse(store.canUndo)
    }

    func testHaltenUndDritterWurf() {
        let store = makeStore(dice: [1, 2, 3, 4, 5, 6, 6])
        store.startGame(players: [players[0]], settings: GameSettings())
        store.toggleHold(0)                       // vor dem ersten Wurf: nichts zu halten
        XCTAssertEqual(store.game?.held, [])
        store.roll()
        store.toggleHold(0); store.toggleHold(1); store.toggleHold(2); store.toggleHold(3)
        store.roll()
        XCTAssertEqual(store.game?.state.dice, [1, 2, 3, 4, 6])
        XCTAssertEqual(store.game?.held, [0, 1, 2, 3], "TF24-08: Gehaltene bleiben nach dem Wurf gehalten")
        store.toggleHold(0); store.roll()
        XCTAssertEqual(store.game?.held, [], "nach dem dritten Wurf ist nichts mehr gehalten")
        store.toggleHold(1)                       // nach dem dritten Wurf nicht mehr möglich
        XCTAssertEqual(store.game?.held, [])
        XCTAssertFalse(store.roll())
    }

    func testHaltenSchalterAus() {
        UserDefaults.standard.set(false, forKey: "wuerfelBleibenGehalten")
        defer { UserDefaults.standard.removeObject(forKey: "wuerfelBleibenGehalten") }
        let store = makeStore(dice: [1, 2, 3, 4, 5, 6, 6])
        store.startGame(players: [players[0]], settings: GameSettings())
        store.roll()
        store.toggleHold(0); store.toggleHold(1)
        store.roll()
        XCTAssertEqual(store.game?.held, [], "Schalter aus: Auswahl wird nach dem Wurf geleert (wie früher)")
    }

    func testEchteWuerfelUndKorrektur() {
        let store = makeStore()
        store.startGame(players: [players[0]], settings: GameSettings(diceMode: .real))
        XCTAssertFalse(store.roll(), "digitales Würfeln ist im Echtwürfel-Modus gesperrt")
        XCTAssertFalse(store.rollReal([1, 2, 3]), "zu wenige Augen")
        XCTAssertFalse(store.rollReal([1, 2, 3, 4, 7]), "ungültige Augenzahl")
        XCTAssertTrue(store.rollReal([2, 2, 2, 5, 6]))
        XCTAssertEqual(store.game?.state.dice, [2, 2, 2, 5, 6])
        store.undoRoll()
        XCTAssertEqual(store.game?.state.rollsUsed, 0)
        XCTAssertTrue(store.rollReal([1, 1, 1, 1, 1]))
        store.toggleHold(0); store.toggleHold(1)
        XCTAssertTrue(store.rollReal([6, 6, 6]))
        XCTAssertEqual(store.game?.state.dice, [1, 1, 6, 6, 6])
    }

    func testPartieBisSiegerUndStatistik() {
        let store = makeStore()
        store.startGame(players: players, settings: GameSettings())
        var n = 0
        store.roller = { n += 1; return (n % 6) + 1 }
        while let g = store.game, !g.finished {
            store.roll()
            store.score(store.game!.state.legalCategories[0])
        }
        let g = store.game!
        XCTAssertTrue(g.finished)
        XCTAssertEqual(g.timeline.count, 27)
        XCTAssertFalse(g.winners.isEmpty)
        XCTAssertEqual(store.records.count, 1)
    }

    func testLoeschen() {
        let store = makeStore()
        store.startGame(players: players, settings: GameSettings())
        let id = store.game!.id
        store.deleteGame(id)
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertTrue(GameStore(repository: FileGameRepository(directory: dir)).records.isEmpty)
    }

    func testAlleGehaltenWuerfeltNicht() {
        let store = makeStore(dice: [1, 2, 3, 4, 5, 6])
        store.startGame(players: [players[0]], settings: GameSettings())
        store.roll()
        (0..<5).forEach { store.toggleHold($0) }
        XCTAssertFalse(store.roll(), "mit fünf gehaltenen Würfeln wäre der Wurf verschwendet")
        XCTAssertEqual(store.game?.state.rollsUsed, 1)
    }

    func testBeschaedigterRueckgaengigStandWirdVerworfen() throws {
        var rec = GameRecord(players: players, settings: GameSettings())
        var bad = Snapshot(state: rec.state, held: [], timeline: rec.timeline)
        bad.state.rollsUsed = 9
        rec.undo = bad
        let repo = FileGameRepository(directory: dir)
        try repo.save(rec)
        let loaded = try XCTUnwrap(repo.loadAll().first)
        XCTAssertNil(loaded.undo)
    }

    func testUmbenennenTrimmt() {
        let store = makeStore()
        store.startGame(players: players, settings: GameSettings())
        let id = store.game!.id
        store.renameGame(id, to: "  Sonntag \n")
        XCTAssertEqual(store.game?.name, "Sonntag")
        store.renameGame(id, to: "   ")
        XCTAssertNil(store.game?.name)
    }

    func testYachtErkennung() {
        var s = GameState(playerNames: ["A"])
        XCTAssertFalse(s.isYacht)
        s.dice = [4, 4, 4, 4, 4]
        XCTAssertTrue(s.isYacht)
        s.dice = [4, 4, 4, 4, 3]
        XCTAssertFalse(s.isYacht)
    }
}
