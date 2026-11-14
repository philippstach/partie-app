// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Durchspiel-Runden (Build 11): ganze Partien über die Store-Aktionen, in allen Eingabearten,
/// mit 2 bis 8 Personen. Geprüft werden Invarianten nach jedem Schritt und das Neustarten der App
/// (Speichern und Laden) mitten im Spiel.
@MainActor
struct DurchspielTests {
    private enum Art: String, CaseIterable { case digital, augen, punkte }

    private func settings(_ art: Art, seed: UInt64) -> GameSettings {
        var s = GameSettings(goal: 2_000, penalty: 500,
                             diceMode: art == .digital ? .digital : .real,
                             realEntry: art == .punkte ? .points : .pips,
                             diceCount: seed.isMultiple(of: 3) ? 6 : 5)
        s.rules.triples = seed.isMultiple(of: 2) ? .all : .onesAndFives
        s.rules.finalRound = seed % 5 == 0
        s.nextPlayerOverlay = false
        return s
    }

    /// Punktestand = Summe der Züge minus Strafen, je Person
    private func pruefeStand(_ g: GameState, _ label: String) {
        for (i, p) in g.players.enumerated() {
            let summe = g.log.filter { $0.player == i }.reduce(0) { $0 + $1.points - $1.penalty }
            #expect(p.score == summe, "\(label): \(p.name) \(p.score) ≠ \(summe)")
            #expect((0...2).contains(p.streak), "\(label): Serie \(p.streak)")
        }
        #expect(g.isConsistent, "\(label): inkonsistent")
        #expect(g.timeline.last == g.players.map(\.score), "\(label): Verlauf")
        if let o = g.offer { #expect(o.from != g.current, "\(label): Angebot an sich selbst") }
    }

    /// Ein vernünftiger Zug je Eingabeart (mit etwas Zufall: übernehmen, ablehnen, Niete, Rückgängig)
    private func zug(_ store: GameStore, _ art: Art, _ rng: inout SeededGenerator) {
        guard let g = store.game else { return }
        if g.offer != nil {
            Bool.random(using: &rng) ? store.acceptOffer() : store.declineOffer()
            return
        }
        if Int.random(in: 0..<25, using: &rng) == 0 { store.undo(); return }
        switch art {
        case .punkte:
            if Int.random(in: 0..<5, using: &rng) == 0 { store.submitNoPoints() } else {
                store.submitPoints(Int.random(in: 1...12, using: &rng) * 50)
            }
        case .digital:
            if !g.turn.hasRolled { store.roll(); return }
            store.selectBest()
            if store.turnTotal >= 300 || g.turn.openCount - store.selection.count <= 1 || Bool.random(using: &rng) {
                store.endTurn()
            } else {
                store.roll()
            }
        case .augen:
            let offen = g.turn.openCount
            let wurf = (0..<offen).map { _ in Int.random(in: 1...6, using: &rng) }
            let best = Scoring.bestSelection(wurf, fullThrow: g.turn.keptFullThrow, rules: g.settings.rules.scoring)
            if best.points == 0 { store.submitNoPoints(); return }
            let raus = best.indices.map { wurf[$0] }
            store.layOut(raus, bank: g.turn.banked + best.points >= 300 || Bool.random(using: &rng))
        }
    }

    @Test(arguments: [UInt64(1), 2, 3, 5, 8, 13, 21, 34])
    func ganzePartien(seed: UInt64) throws {
        for art in Art.allCases {
            // Zwei Zufallsquellen: Würfel (im Store) und Entscheidungen (im Test) – nie gleichzeitig dieselbe
            var rng = SeededGenerator(seed: seed &* 31 &+ UInt64(art.rawValue.count))
            var wuerfel = SeededGenerator(seed: seed &* 7 &+ 3)
            let repo = MemoryRepository()
            let defaults = UserDefaults(suiteName: UUID().uuidString)!
            var store = GameStore(repository: repo, defaults: defaults)
            store.roller = { Int.random(in: 1...6, using: &wuerfel) }
            let n = 2 + Int(seed % 7)   // 2 bis 8 Personen
            store.startGame(players: (0..<n).map { Player(name: "P\($0)", avatar: "🎲", colorIndex: $0) },
                            settings: settings(art, seed: seed))
            let id = try #require(store.currentID)

            for schritt in 0..<3_000 {
                guard let g = store.game, !g.finished else { break }
                zug(store, art, &rng)
                let label = "\(art) Seed \(seed) Schritt \(schritt)"
                guard let neu = store.game else { Issue.record("\(label): Spiel weg"); return }
                pruefeStand(neu, label)
                // App mitten im Spiel beenden und neu starten: gleicher Stand aus dem Speicher
                if schritt % 37 == 0 {
                    let neustart = GameStore(repository: repo, defaults: defaults)
                    neustart.resume(id)
                    #expect(neustart.game == neu, "\(label): nach Neustart anders")
                    neustart.roller = { Int.random(in: 1...6, using: &wuerfel) }
                    store = neustart
                }
            }
            let ende = try #require(store.game)
            #expect(ende.finished, "\(art) Seed \(seed): Partie nicht entschieden")
            #expect(!ende.winners.isEmpty, "\(art) Seed \(seed): kein Sieger")
            // Statistik hat die Partie genau einmal
            #expect(store.summaries.filter { $0.id == id }.count == 1, "\(art) Seed \(seed): Statistik")
            // Revanche startet sauber
            store.rematch()
            #expect(store.game.map { !$0.finished && $0.players.allSatisfy { $0.score == 0 } } == true)
        }
    }
}
