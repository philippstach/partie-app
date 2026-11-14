// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Randfälle des GameStore: ungültige Aktionen, beendete Spiele, Grenzen – und ein Zufallsspiel,
/// das nach jedem Schritt einen stimmigen Stand haben muss.
@MainActor
struct GameStoreEdgeTests {
    private func makeStore(rolls: [Int] = [], players: Int = 2, settings: GameSettings = GameSettings()) -> GameStore {
        let store = GameStore(repository: MemoryRepository(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var queue = rolls
        store.roller = { queue.isEmpty ? 2 : queue.removeFirst() }
        var s = settings
        s.nextPlayerOverlay = false
        store.startGame(players: (0..<players).map { Player(name: "P\($0)", avatar: "🎲", colorIndex: $0) }, settings: s)
        return store
    }

    /// Nach dem Sieg ändert keine Aktion mehr etwas (außer Rückgängig).
    @Test func finishedGameIgnoresActions() {
        let store = makeStore(settings: GameSettings(goal: 1_000, diceMode: .real))
        store.submitPoints(1_000)
        let finished = store.game
        #expect(finished?.finished == true)
        for action: GameAction in [.points(500), .noPoints, .enterThrow(keep: [], dice: [1, 1, 1, 5, 5]),
                                   .bank(keep: [0]), .acceptOffer, .declineOffer, .roll(keep: [])] {
            store.perform(action)
            #expect(store.game == finished, "\(action)")
        }
        store.undo()
        #expect(store.game?.finished == false)
    }

    /// `keep` mit gesperrten, doppelten Unsinns- oder fremden Positionen wird abgelehnt.
    @Test func invalidKeepIsRejected() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4, 1, 6, 6])
        store.perform(.roll(keep: []))
        let afterFirst = store.game
        store.perform(.roll(keep: [7]))           // gibt es nicht
        store.perform(.roll(keep: [-1]))
        store.perform(.roll(keep: [2]))           // 2 punktet nicht
        store.perform(.bank(keep: [0, 2]))        // 1 + 2 ist ungültig
        #expect(store.game == afterFirst)
        store.perform(.roll(keep: [0]))           // 1 rausgelegt → Würfel 0 gesperrt
        let locked = store.game
        store.perform(.bank(keep: [0]))           // gesperrter Würfel kann nicht nochmal
        #expect(store.game == locked)
    }

    /// Augen-Eingabe: falsche Anzahl oder Augen außerhalb 1–6 werden nicht eingetragen.
    @Test func invalidPipsAreRejected() {
        let store = makeStore(settings: GameSettings(diceMode: .real, realEntry: .pips))
        let start = store.game
        store.perform(.enterThrow(keep: [], dice: [1, 2, 3, 4]))
        store.perform(.enterThrow(keep: [], dice: [1, 2, 3, 4, 5, 6]))
        store.perform(.enterThrow(keep: [], dice: [0, 2, 3, 4, 5]))
        store.perform(.enterThrow(keep: [], dice: [7, 2, 3, 4, 5]))
        store.perform(.enterThrow(keep: [1], dice: [1, 2, 3, 4, 5]))   // vor dem ersten Wurf nichts rauslegen
        #expect(store.game == start)
        #expect(!store.canUndo)
    }

    /// Übernehmen/Ablehnen ohne Angebot tut nichts; solange ein Angebot offen ist, wird nicht gewürfelt.
    @Test func offerActionsNeedAnOffer() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4])
        let start = store.game
        store.acceptOffer()
        store.declineOffer()
        #expect(store.game == start)

        store.roll()
        store.perform(.bank(keep: [0, 1]))
        #expect(store.game?.offer != nil)
        let withOffer = store.game
        store.perform(.roll(keep: []))
        store.perform(.bank(keep: [0]))
        #expect(store.game == withOffer)
    }

    /// Der Rückgängig-Stapel ist begrenzt (50 Schritte) und wächst nicht unbegrenzt.
    @Test func undoStackIsCapped() {
        let store = makeStore(settings: GameSettings(goal: 50_000, diceMode: .real))
        for _ in 0..<60 { store.submitPoints(50) }
        #expect(store.undoStack.count == 50)
        for _ in 0..<50 { store.undo() }
        #expect(!store.canUndo)
        #expect(store.game?.log.count == 10)
    }

    /// Revanche: gleiche Spieler und Regeln, alle Werte auf 0, neues Spiel neben dem alten.
    @Test func rematchStartsFresh() {
        let store = makeStore(settings: GameSettings(goal: 1_000, penalty: 300, diceMode: .real, triples: .onesAndFives))
        store.submitNoPoints()
        store.submitPoints(1_000)
        let oldID = store.currentID
        store.rematch()
        let g = store.game
        #expect(store.currentID != oldID)
        #expect(g?.players.map(\.name) == ["P0", "P1"])
        #expect(g?.players.allSatisfy { $0.score == 0 && $0.nieten == 0 && $0.turns == 0 } == true)
        #expect(g?.settings.rules == GameSettings(goal: 1_000, penalty: 300, diceMode: .real, triples: .onesAndFives).rules)
        #expect(g?.finished == false && g?.log.isEmpty == true)
        #expect(store.savedGames.count == 2)
        #expect(!store.canUndo)

        // Revanche mit anderer Reihenfolge (Verlierer fängt an)
        store.submitPoints(1_000)
        let players = store.game!.players
        store.rematch(order: [players[1], players[0]])
        #expect(store.game?.players.map(\.name) == ["P1", "P0"])
        #expect(store.game?.current == 0)
    }

    /// Zufallsspiele mit allen Aktionen (auch unsinnigen): nie ein Absturz, der Stand bleibt stimmig,
    /// Punkte in der Timeline passen zu den Spielern, Rückgängig stellt genau den vorigen Stand her.
    @Test(arguments: [DiceMode.digital, .real], [UInt64(1), 7, 42, 106, 207, 342])
    func randomPlayStaysConsistent(mode: DiceMode, seed: UInt64) {
        var rng = SeededGenerator(seed: seed)
        // Seeds ab 100: mit 6 Würfeln (große Straße bei geraden Hundertern)
        let six = seed >= 100
        var settings = GameSettings(goal: 3_000, roundLimit: 6, penalty: 300, diceMode: mode, realEntry: .pips,
                                    diceCount: six ? 6 : 5, straight6: seed / 100 == 2 ? .full : .five)
        settings.rules.triples = seed.isMultiple(of: 2) ? .all : .onesAndFives
        let store = makeStore(players: 3, settings: settings)
        store.roller = { Int.random(in: 1...6, using: &rng) }

        for _ in 0..<600 {
            guard let g = store.game else { Issue.record("Spiel weg"); return }
            if g.finished { break }
            let free = g.turn.dice.indices.filter { !g.turn.locked[$0] }
            let keep = store.bestSelection.sorted()
            let action: GameAction
            switch Int.random(in: 0..<12, using: &rng) {
            case 0: action = .undo
            case 1: action = .points(Int.random(in: 0...20, using: &rng) * 50)
            case 2: action = .noPoints
            case 3: action = .bank(keep: keep)
            case 4: action = g.offer != nil ? .acceptOffer : .bank(keep: [Int.random(in: -1...5, using: &rng)])
            case 5: action = g.offer != nil && Bool.random(using: &rng) ? .acceptOffer : .declineOffer
            case 6:
                if mode == .real {
                    let n = Int.random(in: 1...max(1, g.turn.openCount), using: &rng)
                    action = .layOut(dice: (0..<n).map { _ in [1, 5, 1, 5, 2, 3, 4, 6].randomElement(using: &rng)! },
                                     bank: Bool.random(using: &rng))
                } else {
                    action = .roll(keep: [Int.random(in: 0...5, using: &rng)])   // oft ungültig
                }
            default:
                let dice = (0..<(g.turn.hasRolled ? g.turn.nextRollCount : free.count)).map { _ in Int.random(in: 1...6, using: &rng) }
                action = mode == .digital ? .roll(keep: g.turn.hasRolled ? keep : []) : .enterThrow(keep: g.turn.hasRolled ? keep : [], dice: dice)
            }
            let before = store.game
            let hadUndo = store.canUndo
            store.perform(action)
            guard let after = store.game else { Issue.record("Spiel weg nach \(action)"); return }
            #expect(after.isConsistent, "\(action)")
            #expect(after.timeline.last == after.players.map(\.score), "\(action)")
            #expect(after.log.count == after.timeline.count - 1)
            if case .undo = action, hadUndo {
                #expect(after != before)
            }
        }
    }
}
