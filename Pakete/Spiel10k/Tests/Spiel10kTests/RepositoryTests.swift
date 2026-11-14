// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

@MainActor
struct RepositoryTests {
    private func tempRepo() -> FileGameRepository {
        FileGameRepository(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
    }

    private func record(score: Int = 0, updated: Date = Date()) -> GameRecord {
        var state = GameState(players: [Player(name: "A", avatar: "🎲", colorIndex: 0), Player(name: "B", avatar: "🎲", colorIndex: 1)],
                              settings: GameSettings())
        state.players[0].score = score
        return GameRecord(id: UUID(), name: nil, createdAt: updated, updatedAt: updated, state: state)
    }

    @Test func saveLoadDelete() throws {
        let repo = tempRepo()
        let old = record(score: 100, updated: Date(timeIntervalSince1970: 1_000))
        let new = record(score: 200, updated: Date(timeIntervalSince1970: 2_000))
        try repo.save(old)
        try repo.save(new)
        #expect(repo.loadAll().map(\.id) == [new.id, old.id])
        try repo.delete(id: old.id)
        #expect(repo.loadAll().map(\.id) == [new.id])
    }

    @Test func filesCarryFormatVersion() throws {
        let repo = tempRepo()
        let r = record()
        try repo.save(r)
        let data = try Data(contentsOf: repo.directory.appending(path: "\(r.id.uuidString).json"))
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["version"] as? Int == StoredGame.currentVersion)
    }

    /// Beendete Spiele mit geteiltem Sieg (vor Einführung des Stechens) bleiben lesbar.
    @Test func oldSharedWinStillLoads() throws {
        let repo = tempRepo()
        var r = record()
        r.state.winners = [0, 1]
        try repo.save(r)
        let loaded = try #require(repo.loadAll().first)
        #expect(loaded.state.isTie && loaded.state.finished && loaded.state.tiebreak == nil)
    }

    /// (13) „Niete“ im Code, JSON-Schlüssel bleibt „mackes“ – alte und neue Stände sind austauschbar.
    @Test func nietenKeepLegacyJSONKey() throws {
        let old = #"{"id":"\#(UUID().uuidString)","name":"Anna","avatar":"😎","colorIndex":0,"score":300,"streak":1,"mackes":4,"bestTurn":300,"turns":5}"#
        let player = try JSONDecoder().decode(Player.self, from: Data(old.utf8))
        #expect(player.nieten == 4)
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(player)) as? [String: Any]
        #expect(json?["mackes"] as? Int == 4)
        #expect(json?["nieten"] == nil)
    }

    @Test func newerFormatIsIgnored() throws {
        let repo = tempRepo()
        let r = record()
        try repo.save(r)
        let file = repo.directory.appending(path: "\(r.id.uuidString).json")
        var json = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        json["version"] = StoredGame.currentVersion + 1
        try JSONSerialization.data(withJSONObject: json).write(to: file)
        #expect(repo.loadAll().isEmpty)
    }

    /// Kaputte, leere oder fremde Dateien dürfen das Laden nicht stören – die anderen Spiele bleiben da.
    @Test func brokenFilesAreSkipped() throws {
        let repo = tempRepo()
        let good = record(score: 150)
        try repo.save(good)
        try Data("{ kaputt".utf8).write(to: repo.directory.appending(path: "\(UUID().uuidString).json"))
        try Data().write(to: repo.directory.appending(path: "\(UUID().uuidString).json"))
        try Data("[1,2,3]".utf8).write(to: repo.directory.appending(path: "\(UUID().uuidString).json"))
        try Data("egal".utf8).write(to: repo.directory.appending(path: "notiz.txt"))
        #expect(repo.loadAll().map(\.id) == [good.id])
    }

    /// Lesbare, aber unstimmige Stände (falsche Indizes) werden nicht geladen, statt später abzustürzen.
    @Test func inconsistentStatesAreSkipped() throws {
        let repo = tempRepo()
        var cases: [GameRecord] = []
        var r = record(); r.state.current = 5; cases.append(r)
        r = record(); r.state.players = []; cases.append(r)
        r = record(); r.state.turn.dice = [1, 2, 3]; cases.append(r)
        r = record(); r.state.turn.dice[0] = 9; cases.append(r)
        r = record(); r.state.winners = [7]; cases.append(r)
        r = record(); r.state.timeline = [[0]]; cases.append(r)
        r = record(); r.state.offer = InheritOffer(from: 3, points: 100, dice: [1, 2, 3, 4, 5], kept: [true, false, false, false, false]); cases.append(r)
        r = record(); r.state.tiebreak = Tiebreak(players: [0, 4]); cases.append(r)
        for c in cases {
            #expect(!c.state.isConsistent)
            try repo.save(c)
        }
        let good = record(score: 50)
        #expect(good.state.isConsistent)
        try repo.save(good)
        #expect(repo.loadAll().map(\.id) == [good.id])
    }

    /// Ein Store mit beschädigten Dateien startet normal.
    @Test func storeStartsWithBrokenFiles() throws {
        let repo = tempRepo()
        try Data("{}".utf8).write(to: repo.directory.appending(path: "\(UUID().uuidString).json"))
        let store = GameStore(repository: repo, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(store.savedGames.isEmpty)
    }

    /// Spielstand der ersten Version (UserDefaults, Feld „winner“, ohne neue Einstellungen).
    @Test func legacyGameIsMigrated() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let legacy = """
        {"players":[{"id":"\(UUID().uuidString)","name":"Anna","avatar":"😎","colorIndex":0,"score":750,"streak":1,"mackes":1,"bestTurn":750,"turns":2},
                    {"id":"\(UUID().uuidString)","name":"Ben","avatar":"🤠","colorIndex":1,"score":300,"streak":0,"mackes":0,"bestTurn":300,"turns":1}],
         "settings":{"goal":10000,"roundLimit":0,"penalty":500,"diceMode":"digital","haptics":true,"nextPlayerOverlay":true},
         "current":1,
         "turn":{"dice":[1,5,2,3,4],"locked":[false,false,false,false,false],"selected":[true,false,false,false,false],"banked":0,"hasRolled":true,"fullThrow":true,"inheritedPoints":0},
         "log":[],"timeline":[[0,0]]}
        """
        defaults.set(Data(legacy.utf8), forKey: LegacyMigration.legacyKey)
        let repo = tempRepo()
        let store = GameStore(repository: repo, defaults: defaults)

        #expect(defaults.data(forKey: LegacyMigration.legacyKey) == nil)
        #expect(store.pausedGames.count == 1)
        let state = try #require(store.pausedGames.first?.state)
        #expect(state.players.map(\.score) == [750, 300])
        #expect(state.current == 1)
        #expect(state.turn.selected[0])
        #expect(state.settings.nextPlayerOverlay == true)   // neue Einstellung → Standard
        #expect(state.settings.rules.goal == 10000)   // flaches Altformat → GameRules
        #expect(state.settings.rules.triples == .all)
        #expect(state.settings.bestHint == false)
        #expect(!state.finished)
    }
}
