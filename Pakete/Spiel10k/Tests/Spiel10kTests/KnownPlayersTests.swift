// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Namensabgleich und bekannte Personen (Doku/SPEC-1.0.1-B.md §2).
@MainActor
struct KnownPlayersTests {
    private struct Faelle: Decodable {
        struct Fall: Decodable { let a: String; let b: String; let gleich: Bool }
        let faelle: [Fall]
    }

    /// Gemeinsame Testfälle mit Python und Kotlin: Shared/spieler/namensabgleich.json
    @Test func namensabgleich() throws {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Shared/spieler/namensabgleich.json")
        let faelle = try JSONDecoder().decode(Faelle.self, from: Data(contentsOf: url)).faelle
        #expect(faelle.count >= 13)
        for f in faelle {
            #expect(PlayerName.same(f.a, f.b) == f.gleich, "„\(f.a)“ / „\(f.b)“")
        }
    }

    @Test func placeholders() {
        #expect(PlayerName.isPlaceholder("Person 2"))
        #expect(PlayerName.isPlaceholder("Spieler 1"))
        #expect(PlayerName.isPlaceholder(" person  3 "))
        #expect(!PlayerName.isPlaceholder("Max 2"))
        #expect(!PlayerName.isPlaceholder("Person"))
        #expect(PlayerName.placeholder(0) == "Person 1")
    }

    /// Leer gelassene Namen („Person 1“) erzeugen keine Phantom-Einträge.
    @Test func placeholdersNotInHallOfFameOrKnown() {
        let game = GameState(players: [Player(name: "Person 1", avatar: "😎", colorIndex: 0),
                                       Player(name: "Anna", avatar: "🤠", colorIndex: 1)],
                             settings: GameSettings())
        let hof = HallOfFame(summaries: [GameSummary(id: UUID(), date: Date(), game: game)])
        #expect(hof.rows.map(\.name) == ["Anna"])
        #expect(HallOfFame.personalBestTurn("Person 1", in: [], excluding: nil) == nil)

        var known = KnownPlayers()
        known.record(game.players)
        #expect(known.all.map(\.name) == ["Anna"])
    }

    @Test func suggestionsOrderAndExclusion() {
        var known = KnownPlayers()
        let day: TimeInterval = 86_400
        known.record([Player(name: "Gerd", avatar: "🐺", colorIndex: 4)], at: Date(timeIntervalSince1970: 1 * day))
        known.record([Player(name: "Oma Gerda", avatar: "🦊", colorIndex: 2)], at: Date(timeIntervalSince1970: 2 * day))
        known.record([Player(name: "Angela", avatar: "👑", colorIndex: 3)], at: Date(timeIntervalSince1970: 3 * day))
        known.record([Player(name: "Max", avatar: "🤠", colorIndex: 1)], at: Date(timeIntervalSince1970: 4 * day))

        // Leeres Feld: zuletzt benutzte zuerst
        #expect(known.suggestions(for: "", excluding: []).map(\.name) == ["Max", "Angela", "Oma Gerda", "Gerd"])
        // Treffer am (Wort-)Anfang vor Treffern in der Mitte
        #expect(known.suggestions(for: "ge", excluding: []).map(\.name) == ["Oma Gerda", "Gerd", "Angela"])
        // Schon im Spiel: nicht vorschlagen
        #expect(known.suggestions(for: "ge", excluding: ["oma  gerda"]).map(\.name) == ["Gerd", "Angela"])
        #expect(known.suggestions(for: "", excluding: [], limit: 2).count == 2)
    }

    @Test func applyTakesNextFreeColor() {
        let known = KnownPlayer(name: "Oma Gerda", avatar: "🦊", colorIndex: 2, lastUsed: Date(), games: 3)
        let row = Player(name: "oma", avatar: "😎", colorIndex: 0)
        let free = KnownPlayers.apply(known, to: row, others: [Player(name: "A", avatar: "🦊", colorIndex: 1)], colorCount: 8)
        #expect(free.name == "Oma Gerda")
        #expect(free.avatar == "🦊")             // Emoji darf doppelt sein
        #expect(free.colorIndex == 2)
        let taken = KnownPlayers.apply(known, to: row, others: [Player(name: "A", avatar: "🤠", colorIndex: 2),
                                                                 Player(name: "B", avatar: "🤠", colorIndex: 3)], colorCount: 8)
        #expect(taken.colorIndex == 4)
    }

    /// Spielstart merkt sich alle; erster Start befüllt aus der Statistik; Entfernen lässt die Statistik stehen.
    @Test func storeRemembersAndForgets() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let repo = MemoryRepository()
        let store = GameStore(repository: repo, defaults: defaults)
        var s = GameSettings(goal: 1000, diceMode: .real)
        store.startGame(players: [Player(name: "Lena", avatar: "😎", colorIndex: 5),
                                  Player(name: "", avatar: "🤠", colorIndex: 1)], settings: s)
        #expect(store.knownPlayers.lookup("lena")?.colorIndex == 5)
        #expect(store.knownPlayers.all.count == 1)
        store.submitPoints(1000)
        #expect(store.hallOfFame.rows.count == 1)

        // Neuer Start (gleiche Daten): Liste bleibt gespeichert
        let again = GameStore(repository: repo, defaults: defaults)
        #expect(again.knownPlayers.lookup("Lena")?.avatar == "😎")
        again.forgetKnownPlayer("LENA")
        #expect(again.knownPlayers.lookup("Lena") == nil)
        #expect(again.hallOfFame.rows.count == 1)

        // Erster Start mit 1.0.1 (keine Liste gespeichert): aus Spielen und Statistik befüllen
        defaults.removeObject(forKey: "tenk.knownPlayers.v1")
        let seeded = GameStore(repository: repo, defaults: defaults)
        #expect(seeded.knownPlayers.lookup("Lena")?.colorIndex == 5)
        #expect(seeded.knownPlayers.lookup("Lena")?.games == 1)
        seeded.resetKnownPlayers()
        #expect(seeded.knownPlayers.all.isEmpty)
        #expect(GameStore(repository: repo, defaults: defaults).knownPlayers.all.isEmpty)
    }
}
