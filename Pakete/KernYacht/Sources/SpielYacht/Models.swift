// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

nonisolated struct Player: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var avatar: String
    var colorIndex: Int
    /// Nil = Mensch, sonst Computergegner dieser Stärke
    var computer: ComputerLevel?

    init(id: UUID = UUID(), name: String, avatar: String, colorIndex: Int, computer: ComputerLevel? = nil) {
        self.id = id; self.name = name; self.avatar = avatar; self.colorIndex = colorIndex; self.computer = computer
    }

    var isComputer: Bool { computer != nil }

    enum CodingKeys: String, CodingKey { case id, name, avatar, colorIndex, computer }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Spieler"
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar) ?? "🎲"
        colorIndex = max(0, try c.decodeIfPresent(Int.self, forKey: .colorIndex) ?? 0)
        computer = (try? c.decodeIfPresent(ComputerLevel.self, forKey: .computer)) ?? nil
    }
}

/// Woher die Würfel kommen: App oder echte Würfel am Tisch (Augen werden eingetippt).
nonisolated enum DiceMode: String, Codable, Sendable {
    case digital, real
}

nonisolated struct GameSettings: Codable, Equatable, Sendable {
    var rules = Rules()
    var diceMode = DiceMode.digital
    /// Tageswürfel: Tag („2026-11-04“), dessen feste Würfelfolge gilt; nil = normales Spiel
    var dailyKey: String?

    init(rules: Rules = Rules(), diceMode: DiceMode = .digital, dailyKey: String? = nil) {
        self.rules = rules; self.diceMode = diceMode; self.dailyKey = dailyKey
    }

    enum CodingKeys: String, CodingKey { case rules, diceMode, dailyKey }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rules = try c.decodeIfPresent(Rules.self, forKey: .rules) ?? Rules()
        diceMode = (try? c.decodeIfPresent(DiceMode.self, forKey: .diceMode)) ?? .digital
        dailyKey = (try? c.decodeIfPresent(String.self, forKey: .dailyKey)) ?? nil
    }
}

/// Zwischenstand für „Rückgängig“ (Feld eintragen) und „Wurf korrigieren“ (echte Würfel).
nonisolated struct Snapshot: Codable, Equatable, Sendable {
    var state: GameState
    var held: [Int]
    var timeline: [[Int]]

    func isConsistent(playerCount: Int) -> Bool {
        state.isConsistent && state.players.count == playerCount && held.allSatisfy { (0..<5).contains($0) }
            && !timeline.isEmpty && timeline.allSatisfy { $0.count == playerCount }
    }
}

/// Eine Partie samt allem, was die Oberfläche zum Weiterspielen braucht.
nonisolated struct GameRecord: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var name: String?
    var createdAt = Date()
    var updatedAt = Date()
    var players: [Player]
    var settings: GameSettings
    var state: GameState
    /// Angetippte (zu haltende) Würfel, nur Anzeige
    var held: [Int] = []
    /// Gesamtpunkte aller Spieler nach jedem Zug (Zeile 0 = Start), für den Verlauf
    var timeline: [[Int]]
    var undo: Snapshot?
    var preRoll: Snapshot?

    init(players: [Player], settings: GameSettings, now: Date = Date()) {
        self.players = players
        self.settings = settings
        self.state = GameState(playerNames: players.map(\.name), rules: settings.rules)
        self.timeline = [Array(repeating: 0, count: players.count)]
        self.createdAt = now
        self.updatedAt = now
    }

    enum CodingKeys: String, CodingKey {
        case id, name, createdAt, updatedAt, players, settings, state, held, timeline, undo, preRoll
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try c.decodeIfPresent(String.self, forKey: .name)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        players = try c.decodeIfPresent([Player].self, forKey: .players) ?? []
        settings = try c.decodeIfPresent(GameSettings.self, forKey: .settings) ?? GameSettings()
        state = try c.decode(GameState.self, forKey: .state)
        held = try c.decodeIfPresent([Int].self, forKey: .held) ?? []
        timeline = try c.decodeIfPresent([[Int]].self, forKey: .timeline)
            ?? [Array(repeating: 0, count: players.count)]
        // Beschädigte Zwischenstände verwerfen: „Rückgängig“ darf nie einen unmöglichen Zustand zurückholen
        undo = (try? c.decodeIfPresent(Snapshot.self, forKey: .undo)).flatMap { $0.isConsistent(playerCount: players.count) ? $0 : nil }
        preRoll = (try? c.decodeIfPresent(Snapshot.self, forKey: .preRoll)).flatMap { $0.isConsistent(playerCount: players.count) ? $0 : nil }
    }

    /// Nur stimmige Stände dürfen geladen werden (sonst Absturzgefahr in der Oberfläche).
    var isConsistent: Bool {
        state.isConsistent && players.count == state.players.count
            && held.allSatisfy { (0..<5).contains($0) }
            && timeline.allSatisfy { $0.count == players.count } && !timeline.isEmpty
    }

    var displayName: String {
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty { return name }
        return players.map(\.name).joined(separator: ", ")
    }

    var finished: Bool { state.finished }

    /// Indizes der Spieler mit der höchsten Summe (mehrere bei Gleichstand).
    var winners: [Int] {
        let totals = players.indices.map { state.totals(player: $0).total }
        guard let best = totals.max() else { return [] }
        return totals.indices.filter { totals[$0] == best }
    }

    var isTie: Bool { players.count > 1 && winners.count > 1 }

    func total(_ i: Int) -> Int { state.totals(player: i).total }

    /// Wie oft der Spieler ein Yacht gewertet hat (Feld mit 50 plus zusätzliche).
    func yachts(_ i: Int) -> Int {
        (state.players[i].scores[.kniffel] == 50 ? 1 : 0) + state.players[i].extraKniffels
    }

    var filledRounds: Int { state.players.map(\.scores.count).min() ?? 0 }
}

/// Anzeigenamen und Kurzerklärungen der Felder. Das Feld mit dem internen Schlüssel `kniffel` heißt in der Oberfläche „Yacht“.
extension Category {
    var title: String {
        switch self {
        case .ones: String(localized: "Einser")
        case .twos: String(localized: "Zweier")
        case .threes: String(localized: "Dreier")
        case .fours: String(localized: "Vierer")
        case .fives: String(localized: "Fünfer")
        case .sixes: String(localized: "Sechser")
        case .threeOfAKind: String(localized: "Dreierpasch")
        case .fourOfAKind: String(localized: "Viererpasch")
        case .fullHouse: String(localized: "Full House")
        case .smallStraight: String(localized: "Kleine Straße")
        case .largeStraight: String(localized: "Große Straße")
        case .kniffel: String(localized: "Yacht")
        case .chance: String(localized: "Chance")
        case .onePair: String(localized: "Ein Paar")
        case .twoPairs: String(localized: "Zwei Paare")
        }
    }

    var explanation: String {
        switch self {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            String(localized: "Summe aller Würfel mit der Augenzahl \(face ?? 0)")
        case .threeOfAKind: String(localized: "Mindestens 3 gleiche: Summe aller Würfel")
        case .fourOfAKind: String(localized: "Mindestens 4 gleiche: Summe aller Würfel")
        case .fullHouse: String(localized: "3 gleiche und 2 gleiche: 25 Punkte")
        case .smallStraight: String(localized: "4 aufeinanderfolgende: 30 Punkte")
        case .largeStraight: String(localized: "5 aufeinanderfolgende: 40 Punkte")
        case .kniffel: String(localized: "5 gleiche: 50 Punkte")
        case .chance: String(localized: "Summe aller Würfel")
        case .onePair, .twoPairs: ""
        }
    }
}

/// Namen und Erklärungen je Wertung (Yatzy und Yacht rechnen einige Felder anders als Kniffel).
extension Category {
    func title(_ v: Variant) -> String {
        switch self {
        case .onePair: String(localized: "Ein Paar")
        case .twoPairs: String(localized: "Zwei Paare")
        case .kniffel where v == .yatzy: String(localized: "Yatzy")
        default: title
        }
    }

    func explanation(_ v: Variant) -> String {
        switch v {
        case .kniffel: return explanation
        case .yatzy:
            switch self {
            case .onePair: return String(localized: "Zwei gleiche: Summe der beiden (das höchste Paar)")
            case .twoPairs: return String(localized: "Zwei verschiedene Paare: Summe der vier Würfel")
            case .threeOfAKind: return String(localized: "Drei gleiche: Summe dieser drei Würfel")
            case .fourOfAKind: return String(localized: "Vier gleiche: Summe dieser vier Würfel")
            case .fullHouse: return String(localized: "Drei und zwei gleiche: Summe aller Würfel")
            case .smallStraight: return String(localized: "1-2-3-4-5: 15 Punkte")
            case .largeStraight: return String(localized: "2-3-4-5-6: 20 Punkte")
            case .kniffel: return String(localized: "Fünf gleiche: 50 Punkte")
            default: return explanation
            }
        case .yacht:
            switch self {
            case .fourOfAKind: return String(localized: "Vier gleiche: Summe dieser vier Würfel")
            case .fullHouse: return String(localized: "Drei und zwei gleiche: Summe aller Würfel")
            case .smallStraight: return String(localized: "1-2-3-4-5: 30 Punkte")
            case .largeStraight: return String(localized: "2-3-4-5-6: 30 Punkte")
            case .kniffel: return String(localized: "Fünf gleiche: 50 Punkte")
            default: return explanation
            }
        }
    }
}

extension Variant {
    var titel: String {
        switch self {
        case .kniffel: String(localized: "Klassisch")
        case .yatzy: String(localized: "Yatzy")
        case .yacht: String(localized: "Original-Yacht")
        }
    }

    var kurz: String {
        switch self {
        case .kniffel: String(localized: "13 Felder, Bonus 35, Chance und Full House 25")
        case .yatzy: String(localized: "15 Felder, Paare, Bonus 50, Straßen 15 und 20")
        case .yacht: String(localized: "11 Felder, ohne Chance und Bonus, Straßen 30")
        }
    }
}
