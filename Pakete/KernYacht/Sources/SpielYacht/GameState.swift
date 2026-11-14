// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

nonisolated struct PlayerState: Codable, Equatable, Sendable {
    var name: String
    /// Feld ⇒ Punkte. Fehlt ein Feld, ist es frei; 0 heißt gestrichen (oder nichts getroffen).
    var scores: [Category: Int] = [:]
    var extraKniffels = 0

    init(name: String) { self.name = name }

    enum CodingKeys: String, CodingKey { case name, scores, extraKniffels }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        // Als Wörterbuch mit Text-Schlüsseln gespeichert; unbekannte Felder werden ignoriert.
        let raw = try c.decodeIfPresent([String: Int].self, forKey: .scores) ?? [:]
        scores = Dictionary(uniqueKeysWithValues: raw.compactMap { key, value in
            Category(rawValue: key).map { ($0, value) }
        })
        extraKniffels = try c.decodeIfPresent(Int.self, forKey: .extraKniffels) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encode(Dictionary(uniqueKeysWithValues: scores.map { ($0.key.rawValue, $0.value) }), forKey: .scores)
        try c.encode(extraKniffels, forKey: .extraKniffels)
    }
}

/// Der gesamte Regelzustand einer Partie. Kein UI, keine Zufallsquelle: Würfel kommen als `roller` herein.
nonisolated struct GameState: Codable, Equatable, Sendable {
    var rules = Rules()
    var players: [PlayerState] = []
    var current = 0
    /// Leer vor dem ersten Wurf
    var dice: [Int] = []
    var rollsUsed = 0
    var finished = false
    /// Wie viele Würfel bisher aus der festen Tageswürfel-Folge gezogen wurden (Rückgängig stellt es mit zurück)
    var diceDrawn = 0

    init(playerNames: [String], rules: Rules = Rules()) {
        self.rules = rules
        self.players = playerNames.map(PlayerState.init)
    }

    enum CodingKeys: String, CodingKey { case rules, players, current, dice, rollsUsed, finished, diceDrawn }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rules = try c.decodeIfPresent(Rules.self, forKey: .rules) ?? Rules()
        players = try c.decodeIfPresent([PlayerState].self, forKey: .players) ?? []
        current = try c.decodeIfPresent(Int.self, forKey: .current) ?? 0
        dice = try c.decodeIfPresent([Int].self, forKey: .dice) ?? []
        rollsUsed = try c.decodeIfPresent(Int.self, forKey: .rollsUsed) ?? 0
        finished = try c.decodeIfPresent(Bool.self, forKey: .finished) ?? false
        diceDrawn = max(0, try c.decodeIfPresent(Int.self, forKey: .diceDrawn) ?? 0)
    }

    /// Schutz vor beschädigten Ständen: Nur ein stimmiger Zustand darf geladen werden.
    var isConsistent: Bool {
        guard (1...8).contains(players.count), (0..<players.count).contains(current),
              (0...3).contains(rollsUsed) else { return false }
        if rollsUsed == 0 { guard dice.isEmpty else { return false } }
        else { guard dice.count == 5, dice.allSatisfy({ (1...6).contains($0) }) else { return false } }
        // Beendet genau dann, wenn alle Felder belegt sind (sonst hängt die Partie oder zeigt ein Ergebnis mit Lücken)
        guard finished == players.allSatisfy({ $0.scores.count == rules.variant.fields.count }) else { return false }
        guard players.allSatisfy({ $0.extraKniffels >= 0 && $0.scores.values.allSatisfy { $0 >= 0 } }) else { return false }
        return true
    }

    var currentPlayer: PlayerState { players[current] }

    /// Alle fünf Würfel zeigen dasselbe (Yacht gewürfelt).
    var isYacht: Bool { dice.count == 5 && Set(dice).count == 1 }

    // MARK: Regeln

    /// Yacht gewürfelt, Yacht-Feld schon belegt und Joker an.
    var jokerActive: Bool {
        guard rules.joker, rollsUsed > 0, isYacht else { return false }
        return currentPlayer.scores[.kniffel] != nil
    }

    /// Felder, die jetzt gewählt werden dürfen (leer vor dem ersten Wurf).
    var legalCategories: [Category] {
        guard rollsUsed > 0, !finished else { return [] }
        let taken = currentPlayer.scores
        let free = rules.variant.fields.filter { taken[$0] == nil }
        guard jokerActive else { return free }
        if let up = Category.upper[safe: dice[0] - 1], taken[up] == nil { return [up] }
        let low = free.filter { !$0.isUpper }
        return low.isEmpty ? free : low
    }

    /// Vorschau für die Oberfläche; berücksichtigt den Joker.
    func potentialScore(_ category: Category) -> Int {
        guard dice.count == 5 else { return 0 }
        return Scoring.score(dice, category, joker: jokerActive && !category.isUpper, variant: rules.variant)
    }

    func totals(player i: Int) -> Totals {
        let p = players[i]
        func sum(_ cats: [Category]) -> Int { cats.reduce(0) { $0 + (p.scores[$1] ?? 0) } }
        var t = Totals()
        t.upper = sum(Category.upper)
        t.bonus = t.upper >= rules.upperBonusThreshold ? rules.upperBonus : 0
        t.lower = sum(rules.variant.fields.filter { !$0.isUpper })
        t.kniffelBonus = p.extraKniffels * rules.kniffelBonus
        t.total = t.upper + t.bonus + t.lower + t.kniffelBonus
        return t
    }

    // MARK: Aktionen

    /// Führt eine Aktion aus. Bei Fehler bleibt der Zustand unverändert und kein Würfel wird verbraucht.
    mutating func apply(_ action: Action, roller: () -> Int) throws {
        switch action {
        case .roll(let keep):
            guard !finished, rollsUsed < 3 else { throw GameError.noRollLeft }
            if rollsUsed == 0 {
                guard keep.isEmpty else { throw GameError.invalidKeep }
                dice = (0..<5).map { _ in roller() }
            } else {
                guard Set(keep).count == keep.count, keep.allSatisfy({ (0..<5).contains($0) }) else {
                    throw GameError.invalidKeep
                }
                // Neue Würfel in Positionsreihenfolge ziehen (Vorgabe der gemeinsamen Tests)
                dice = dice.enumerated().map { keep.contains($0.offset) ? $0.element : roller() }
            }
            rollsUsed += 1
        case .score(let category):
            guard rollsUsed > 0 else { throw GameError.notRolledYet }
            guard legalCategories.contains(category) else { throw GameError.categoryNotAllowed }
            let joker = jokerActive
            if joker, players[current].scores[.kniffel] == 50, rules.kniffelBonus > 0 {
                players[current].extraKniffels += 1
            }
            players[current].scores[category] = Scoring.score(dice, category, joker: joker && !category.isUpper, variant: rules.variant)
            dice = []
            rollsUsed = 0
            if players.allSatisfy({ $0.scores.count == rules.variant.fields.count }) {
                finished = true
            } else {
                current = (current + 1) % players.count
            }
        }
    }
}

nonisolated extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
