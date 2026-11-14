// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

struct ComputerPlayerTests {
    private func turn(dice: [Int], banked: Int = 0, locked: [Bool]? = nil) -> DiceTurn {
        var t = DiceTurn(count: dice.count)
        t.dice = dice
        t.hasRolled = true
        if let locked { t.locked = locked }
        return t
    }

    @Test func gutLegtSinnvollRausUndWuerfeltMitVielenWuerfelnWeiter() {
        // 1 und 5 liegen, drei Würfel bleiben: bei 150 Punkten lohnt weiterwürfeln
        let m = ComputerPlayer.decide(turn: turn(dice: [2, 3, 4, 6, 1]), rules: GameRules(), level: .gut, score: 0, goal: 10_000)
        #expect(m == .roll(keep: [4]))
    }

    @Test func gutHoertAufWennGenugPunkteUndFastKeineWuerfelBleiben() {
        // Dreier-Sechs plus 1 und 5: 750 Punkte, ein Würfel bleibt → aufhören
        let m = ComputerPlayer.decide(turn: turn(dice: [6, 6, 6, 1, 2]), rules: GameRules(), level: .gut, score: 0, goal: 10_000)
        if case .bank = m { } else { Issue.record("erwartet bank, war \(String(describing: m))") }
    }

    @Test func alleRausgelegtFuehrtZumWeiterwuerfeln() {
        // 1 1 1 5 5 = 1100: alle fünf zählen → mit allen weiter
        let m = ComputerPlayer.decide(turn: turn(dice: [1, 1, 1, 5, 5]), rules: GameRules(), level: .gut, score: 0, goal: 10_000)
        if case .roll(let keep) = m { #expect(keep.count == 5) } else { Issue.record("erwartet roll mit allen, war \(String(describing: m))") }
    }

    @Test func zielErreichtBeendetImmer() {
        for level in ComputerLevel.allCases {
            let m = ComputerPlayer.decide(turn: turn(dice: [1, 2, 3, 4, 6]), rules: GameRules(), level: level, score: 9_950, goal: 10_000)
            if case .bank = m { } else { Issue.record("\(level): erwartet bank, war \(String(describing: m))") }
        }
    }

    @Test func nieteGibtKeinZug() {
        for level in ComputerLevel.allCases {
            #expect(ComputerPlayer.decide(turn: turn(dice: [2, 3, 4, 4, 6]), rules: GameRules(), level: level, score: 0, goal: 10_000) == nil)
        }
    }

    @Test func angebotWirdNurBeiLohnendenPunktenAngenommen() {
        // Viele Punkte, drei freie Würfel: gut nimmt an, einfach auch
        let gross = InheritOffer(from: 0, points: 900, dice: [1, 1, 1, 2, 3], kept: [true, true, true, false, false])
        #expect(ComputerPlayer.accept(offer: gross, rules: GameRules(), level: .gut))
        // Wenige Punkte, nur ein freier Würfel: ablehnen
        let klein = InheritOffer(from: 0, points: 100, dice: [1, 2, 3, 4, 5], kept: [true, true, true, true, false])
        #expect(!ComputerPlayer.accept(offer: klein, rules: GameRules(), level: .gut))
        #expect(!ComputerPlayer.accept(offer: klein, rules: GameRules(), level: .einfach))
        // Punkte-Eingabe (Augen 0): nichts zu übernehmen
        let leer = InheritOffer(from: 0, points: 900, dice: [0, 0, 0, 0, 0], kept: [false, false, false, false, false])
        #expect(!ComputerPlayer.accept(offer: leer, rules: GameRules(), level: .gut))
    }

    @Test func spielerCodableMitUndOhneComputer() throws {
        var p = Player(name: "Robo", avatar: "🤖", colorIndex: 1)
        p.computer = .gut
        let neu = try JSONDecoder().decode(Player.self, from: JSONEncoder().encode(p))
        #expect(neu.computer == .gut && neu.isComputer)
        // Ältere Spielstände ohne das Feld
        let alt = Data(#"{"id":"11111111-1111-1111-1111-111111111111","name":"Anna","avatar":"😎","colorIndex":0,"score":0,"streak":0,"bestTurn":0,"turns":0,"mackes":0}"#.utf8)
        let anna = try JSONDecoder().decode(Player.self, from: alt)
        #expect(anna.computer == nil && !anna.isComputer)
    }

    @MainActor
    @Test(arguments: [UInt64(1), 2, 3, 4, 5, 6])
    func computerGegenComputerSpieltBisZumEnde(seed: UInt64) throws {
        var wuerfel = SeededGenerator(seed: seed &* 13 &+ 5)
        let store = GameStore(repository: MemoryRepository(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        store.roller = { Int.random(in: 1...6, using: &wuerfel) }
        var a = Player(name: "A", avatar: "🤖", colorIndex: 0); a.computer = .einfach
        var b = Player(name: "B", avatar: "🤖", colorIndex: 1); b.computer = .gut
        var s = GameSettings(goal: 3_000, penalty: 500, diceMode: .digital, diceCount: seed.isMultiple(of: 2) ? 6 : 5)
        s.nextPlayerOverlay = false
        store.startGame(players: [a, b], settings: s)
        var schritte = 0
        while let g = store.game, !g.finished, schritte < 20_000 {
            store.nieteNotice = nil; store.tiebreakNotice = nil
            #expect(store.botAmZug)
            store.computerSchritt()
            schritte += 1
            if let neu = store.game { #expect(neu.isConsistent) }
        }
        let ende = try #require(store.game)
        #expect(ende.finished && !ende.winners.isEmpty, "Seed \(seed): nach \(schritte) Schritten nicht entschieden")
    }
}
