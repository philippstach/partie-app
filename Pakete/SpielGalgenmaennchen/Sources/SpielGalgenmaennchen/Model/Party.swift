// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Wo die Partie gerade steht (wird gespeichert, damit sie nach einem Neustart genau dort weitergeht)
enum PartyStep: String, Codable, Sendable {
    /// „Gib das Gerät an <Wortgeber>“ (nur bei eigenen Wörtern)
    case giverHandover
    /// Der Wortgeber tippt das Wort ein
    case entry
    /// „Gib das Gerät an <Rater>“
    case guesserHandover
    /// Der Rater spielt (nach einem Neustart zeigt die App erst die Übergabe, damit das Wort verdeckt bleibt)
    case playing
    /// Zwischenstand nach der Runde
    case score
}

struct PartySettings: Codable, Equatable, Sendable {
    /// Selbst ausdenken (Standard) oder Wörter aus der App
    var ownWords = true
    var category: Category?
    var difficulty: Difficulty?
    /// Runden je Spieler, 1…5
    var roundsPerPlayer = 2

    init() {}

    /// Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ownWords = try c.decodeIfPresent(Bool.self, forKey: .ownWords) ?? true
        category = try? c.decodeIfPresent(Category.self, forKey: .category)
        difficulty = try? c.decodeIfPresent(Difficulty.self, forKey: .difficulty)
        roundsPerPlayer = min(5, max(1, try c.decodeIfPresent(Int.self, forKey: .roundsPerPlayer) ?? 2))
    }
}

/// Eine Partie mit 2–4 Spielern. Reine Logik: Rollen, Punkte, Rangliste.
struct PartyMatch: Codable, Equatable, Sendable {
    static let winBase = 2
    static let giverPoints = 3
    static let maxPlayers = 4

    var names: [String]
    var settings: PartySettings
    /// Index der laufenden Runde (ab 0); nach der letzten Runde = `totalRounds`
    var round = 0
    var scores: [Int]
    var step: PartyStep
    /// Das Spiel der Runde (auch noch beendet, solange der Zwischenstand gezeigt wird)
    var game: Game?
    /// Punkte, die jeder Spieler in der letzten Runde bekommen hat (für das „+7“ im Zwischenstand)
    var lastGain: [Int]
    /// Ergebnis der letzten Runde (für den Zwischenstand)
    var lastGuesser = 0
    var lastWon = false

    init(names: [String], settings: PartySettings) {
        let clean = Array(names.prefix(Self.maxPlayers))
        self.names = clean
        self.settings = settings
        scores = Array(repeating: 0, count: clean.count)
        lastGain = Array(repeating: 0, count: clean.count)
        step = settings.ownWords ? .giverHandover : .guesserHandover
    }

    var players: Int { names.count }
    var totalRounds: Int { players * settings.roundsPerPlayer }
    var isFinished: Bool { round >= totalRounds }

    // MARK: Rollen

    /// In Runde r rät Spieler `r % n`.
    static func guesser(round: Int, players: Int) -> Int { round % players }

    /// Bei eigenen Wörtern denkt sich der nächste Spieler `(r+1) % n` das Wort aus; bei App-Wörtern gibt es keinen Wortgeber.
    static func giver(round: Int, players: Int, ownWords: Bool) -> Int? { ownWords ? (round + 1) % players : nil }

    var guesser: Int { Self.guesser(round: round, players: players) }
    var giver: Int? { Self.giver(round: round, players: players, ownWords: settings.ownWords) }

    // MARK: Punkte

    /// Rater gewinnt → 2 + übrige Ballons − Hinweise, mindestens 1. Rater verliert → 0.
    static func points(won: Bool, mistakes: Int, hints: Int) -> Int {
        won ? max(1, winBase + (8 - min(max(mistakes, 0), 8)) - hints) : 0
    }

    /// Runde auswerten: Punkte für den Rater, bei verlorener Runde mit eigenem Wort 3 Punkte für den Wortgeber.
    mutating func finishRound(won: Bool, mistakes: Int, hints: Int) {
        guard !isFinished else { return }
        var gain = Array(repeating: 0, count: players)
        gain[guesser] = Self.points(won: won, mistakes: mistakes, hints: hints)
        if !won, let giver { gain[giver] += Self.giverPoints }
        for i in 0..<players { scores[i] += gain[i] }
        lastGain = gain
        lastGuesser = guesser
        lastWon = won
        round += 1
        step = .score
    }

    // MARK: Rangliste

    /// Gleichstand = gleicher Platz (1, 1, 3): Platz = 1 + Zahl der Spieler mit mehr Punkten
    static func places(_ scores: [Int]) -> [Int] {
        scores.map { s in 1 + scores.filter { $0 > s }.count }
    }

    var places: [Int] { Self.places(scores) }

    /// Spieler nach Platz sortiert (bei Gleichstand in Spielerreihenfolge)
    var ranking: [Int] {
        names.indices.sorted { (places[$0], $0) < (places[$1], $1) }
    }
}
