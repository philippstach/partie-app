// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Echte Würfel, „rausgelegte Würfel eintippen“ (Aktion `layOut`), auch über TurnInput wie die Oberfläche.
@MainActor
struct PipFlowTests {
    private func makeStore(_ settings: GameSettings = GameSettings(diceMode: .real, realEntry: .pips), players: Int = 2) -> (GameStore, TurnInput) {
        let store = GameStore(repository: MemoryRepository(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var s = settings
        s.nextPlayerOverlay = false
        store.startGame(players: (0..<players).map { Player(name: "P\($0)", avatar: "", colorIndex: $0) }, settings: s)
        return (store, TurnInput())
    }

    private func type(_ pips: [Int], _ store: GameStore, _ input: TurnInput) {
        for p in pips { input.addPip(p, store: store) }
    }

    /// Philipps Fall (Regression): 1, 1 rauslegen → weiter mit 3 → 1, 5 → 350, nicht 1.050.
    @Test func philippsCase() {
        let (store, input) = makeStore()
        type([1, 1], store, input)
        #expect(input.pendingScore(store) == 200)
        input.layOut(store, bank: false)
        #expect(store.turn.banked == 200)
        #expect(store.turn.openCount == 3)
        #expect(store.turn.keptThrows == 1)
        type([1, 5], store, input)
        #expect(input.pendingScore(store) == 150)
        input.layOut(store, bank: true)
        #expect(store.game?.players[0].score == 350)
        #expect(store.game?.current == 1)
    }

    /// Nie mehr Würfel als offen; nur gültige Auswahlen lassen sich bestätigen.
    @Test func onlyValidSelections() {
        let (store, input) = makeStore()
        type([2], store, input)
        #expect(input.pendingScore(store) == nil)
        input.layOut(store, bank: false)
        #expect(store.turn.banked == 0 && !store.canUndo)
        input.removeLastPip()
        type([1, 1, 1, 5, 5, 5], store, input)          // 6. Taste wird ignoriert
        #expect(input.pending == [1, 1, 1, 5, 5])
        let start = store.game
        store.perform(.layOut(dice: [], bank: false))
        store.perform(.layOut(dice: [1, 1, 1, 5, 5, 5], bank: false))
        store.perform(.layOut(dice: [0], bank: false))
        store.perform(.layOut(dice: [1, 7], bank: false))
        store.perform(.layOut(dice: [1, 3], bank: false))
        #expect(store.game == start)
    }

    /// Straße nur mit allen 5 im vollen Wurf – nicht aus 3 offenen, nicht direkt nach einer Übernahme.
    @Test func straightOnlyInFullThrow() {
        let (store, _) = makeStore()
        #expect(store.keptScore([1, 2, 3, 4, 5]) == 1_000)
        #expect(store.keptScore([2, 3, 4, 5, 6]) == 1_000)
        store.layOut([5, 5], bank: false)
        #expect(store.keptScore([2, 3, 4]) == nil)
        // Übernahme mit allen 5: erster Wurf ohne Straße
        store.layOut([1, 1, 1], bank: true)            // alle 5 raus → Angebot mit allen 5
        #expect(store.game?.offer?.allOut == true)
        store.acceptOffer()
        #expect(store.turn.openCount == 5 && store.turn.banked == 1_100)
        #expect(store.keptScore([1, 2, 3, 4, 5]) == nil)     // keine Straße, 2–4 zählen nicht
        #expect(store.keptScore([1, 5]) == 150)
        #expect(store.keptScore([2, 3, 4, 5, 6]) == nil)
        store.layOut([1], bank: false)
        #expect(store.keptScore([2, 3, 4, 5]) == nil)
    }

    /// Alle 5 rausgelegt → mit allen 5 weiter, dann zählt eine Straße wieder.
    @Test func hotDice() {
        let (store, input) = makeStore()
        type([1, 1, 1], store, input)
        input.layOut(store, bank: false)
        type([5, 5], store, input)
        input.layOut(store, bank: false)
        #expect(store.turn.banked == 1_100)
        #expect(store.turn.openCount == 5)
        #expect(store.keptScore([2, 3, 4, 5, 6]) == 1_000)
        store.layOut([2, 3, 4, 5, 6], bank: true)
        #expect(store.game?.players[0].score == 2_100)
    }

    /// Übernahme offener Würfel: Punkte des Vorspielers gelten, es geht mit den offenen Würfeln weiter.
    @Test func inheritOpenDice() {
        let (store, _) = makeStore()
        store.layOut([1, 5], bank: true)                 // 150, 3 offen
        let offer = store.game?.offer
        #expect(offer?.points == 150 && offer?.openCount == 3)
        store.acceptOffer()
        #expect(store.turn.banked == 150 && store.turn.openCount == 3 && store.turn.inheritedFrom == 0)
        store.layOut([1], bank: true)
        #expect(store.game?.players[1].score == 250)
    }

    /// Niete-Knopf: Zug ohne Punkte, gesicherte Punkte sind weg; rückgängig pro bestätigtem Wurf.
    @Test func nieteAndUndoPerThrow() {
        let (store, input) = makeStore()
        type([1, 1], store, input)
        input.layOut(store, bank: false)
        type([5], store, input)
        input.layOut(store, bank: false)
        #expect(store.turn.banked == 250)
        input.niete(store)
        #expect(store.game?.players[0].score == 0 && store.game?.players[0].nieten == 1)
        #expect(store.game?.current == 1)
        store.undo()                                     // Niete zurück
        #expect(store.turn.banked == 250 && store.game?.current == 0)
        store.undo()                                     // zweiter Wurf zurück
        #expect(store.turn.banked == 200 && store.turn.keptThrows == 1)
        store.undo()                                     // erster Wurf zurück
        #expect(store.turn.banked == 0 && store.turn.openCount == 5)
    }

    /// Nur bei echten Würfeln erlaubt.
    @Test func layOutNeedsRealDice() {
        let (store, _) = makeStore(GameSettings())
        store.layOut([1], bank: true)
        #expect(store.game?.log.isEmpty == true)
    }

    /// Alte Spielstände ohne `keptThrows` laden weiter.
    @Test func turnWithoutKeptThrowsDecodes() throws {
        let json = #"{"dice":[1,1,2,3,4],"locked":[true,true,false,false,false],"selected":[false,false,false,false,false],"banked":200,"hasRolled":false,"fullThrow":true,"inheritedPoints":0}"#
        let turn = try JSONDecoder().decode(DiceTurn.self, from: Data(json.utf8))
        #expect(turn.keptThrows == 0 && turn.banked == 200 && turn.openCount == 3)
    }
}
