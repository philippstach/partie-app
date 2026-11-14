// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielYacht

@MainActor
final class DailyDiceTests: XCTestCase {
    private var dir: URL!
    override func setUp() { dir = FileManager.default.temporaryDirectory.appending(path: "yacht-daily-\(UUID().uuidString)") }
    override func tearDown() { try? FileManager.default.removeItem(at: dir) }

    func testFolgeIstFestUndImBereich() {
        let a = (0..<200).map { DailyDice.value(key: "2026-11-04", index: $0) }
        let b = (0..<200).map { DailyDice.value(key: "2026-11-04", index: $0) }
        XCTAssertEqual(a, b)
        XCTAssertTrue(a.allSatisfy { (1...6).contains($0) })
        XCTAssertEqual(Set(a).count, 6, "alle Augenzahlen kommen vor")
        XCTAssertNotEqual(a, (0..<200).map { DailyDice.value(key: "2026-11-05", index: $0) }, "anderer Tag, andere Folge")
    }

    func testTageswuerfelSpielLiefertDieFesteFolge() throws {
        let store = GameStore(repository: FileGameRepository(directory: dir))
        store.startDailyDice(playerName: "Test")
        let key = DailyDice.todayKey()
        XCTAssertEqual(store.game?.settings.dailyKey, key)
        XCTAssertTrue(store.roll())
        let erwartet = (0..<5).map { DailyDice.value(key: key, index: $0) }
        XCTAssertEqual(store.game?.state.dice, erwartet)
        XCTAssertEqual(store.game?.state.diceDrawn, 5)
    }

    func testRueckgaengigLiefertDenselbenWurf() throws {
        let store = GameStore(repository: FileGameRepository(directory: dir))
        store.startDailyDice(playerName: "Test")
        XCTAssertTrue(store.roll())
        let ersterWurf = try XCTUnwrap(store.game?.state.dice)
        store.setHeld([0, 1])
        XCTAssertTrue(store.roll())
        XCTAssertEqual(store.game?.state.diceDrawn, 8)
        XCTAssertTrue(store.canUndoRoll)
        store.undoRoll()
        XCTAssertEqual(store.game?.state.dice, ersterWurf)
        XCTAssertEqual(store.game?.state.diceDrawn, 5, "Zähler stellt sich mit zurück")
        store.setHeld([0, 1])
        XCTAssertTrue(store.roll())
        XCTAssertEqual(store.game?.state.diceDrawn, 8)
    }

    func testAltesSpielOhneZaehlerLaedt() throws {
        let alt = Data(#"{"rules":{},"players":[],"current":0,"dice":[],"rollsUsed":0,"finished":false}"#.utf8)
        let s = try JSONDecoder().decode(GameState.self, from: alt)
        XCTAssertEqual(s.diceDrawn, 0)
        let einst = try JSONDecoder().decode(GameSettings.self, from: Data(#"{"diceMode":"digital"}"#.utf8))
        XCTAssertNil(einst.dailyKey)
    }

    /// 1.0 (P5): Das Ende eines Tageswürfel-Spiels nennt den Tageswürfel, ein normales nicht.
    func testEndeNenntTageswuerfel() throws {
        let store = GameStore(repository: FileGameRepository(directory: dir))
        store.startDailyDice(playerName: "Test")
        let tag = try XCTUnwrap(store.game)
        XCTAssertTrue(NeuLogik.ende(tag).info?.contains("Tageswürfel") ?? false)
        store.startGame(players: tag.players, settings: GameSettings())
        XCTAssertFalse(NeuLogik.ende(try XCTUnwrap(store.game)).info?.contains("Tageswürfel") ?? true)
    }
}
