// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Gemeinsame Regeltests mit dem Server (Shared/regeltests, siehe README dort).
/// Dieselben JSON-Dateien prüft `Server/regeln/tests` in Python.
/// Ohne den Ordner (z. B. vor dem Merge der Regeltests) werden die Tests übersprungen.
nonisolated private let regelRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent().deletingLastPathComponent()
    .appendingPathComponent("Shared/regeltests")

@MainActor
@Suite(.enabled(if: FileManager.default.fileExists(atPath: regelRoot.path)))
struct RegelTests {
    nonisolated static var root: URL { regelRoot }

    nonisolated static var partien: [String] {
        let dir = root.appendingPathComponent("partien")
        let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return files.filter { $0.hasSuffix(".json") }.sorted()
    }

    // MARK: - Wertung

    private struct Wertung: Decodable {
        struct Score: Decodable {
            let name: String; let dice: [Int]; let fullThrow: Bool; let triples: TripleRule; let expectedScore: Int?
            let diceCount: Int?; let straight6: Straight6?
            var rules: ScoringRules { ScoringRules(triples: triples, diceCount: diceCount ?? 5, straight6: straight6 ?? .five) }
        }
        struct Niete: Decodable { let name: String; let dice: [Int]; let triples: TripleRule; let expectedCanScore: Bool }
        struct Best: Decodable {
            let name: String; let dice: [Int]; let fullThrow: Bool; let triples: TripleRule
            let expectedPoints: Int; let expectedIndices: [Int]
            let diceCount: Int?; let straight6: Straight6?
            var rules: ScoringRules { ScoringRules(triples: triples, diceCount: diceCount ?? 5, straight6: straight6 ?? .five) }
        }
        let wertung: [Score]
        let nieten: [Niete]
        let besteAuswahl: [Best]
    }

    private func loadWertung() throws -> Wertung {
        try JSONDecoder().decode(Wertung.self, from: Data(contentsOf: Self.root.appendingPathComponent("wertung.json")))
    }

    @Test func wertung() throws {
        let w = try loadWertung()
        #expect(!w.wertung.isEmpty)
        for c in w.wertung {
            #expect(Scoring.score(c.dice, fullThrow: c.fullThrow, rules: c.rules) == c.expectedScore, "\(c.name)")
        }
    }

    @Test func nieten() throws {
        for c in try loadWertung().nieten {
            #expect(Scoring.canScore(c.dice, triples: c.triples) == c.expectedCanScore, "\(c.name)")
        }
    }

    @Test func besteAuswahl() throws {
        for c in try loadWertung().besteAuswahl {
            let best = Scoring.bestSelection(c.dice, fullThrow: c.fullThrow, rules: c.rules)
            #expect(best.points == c.expectedPoints, "\(c.name)")
            #expect(best.indices.sorted() == c.expectedIndices.sorted(), "\(c.name)")
        }
    }

    // MARK: - Partien

    @Test(arguments: partien)
    func partie(_ file: String) throws {
        let data = try Data(contentsOf: Self.root.appendingPathComponent("partien").appendingPathComponent(file))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])

        let rulesData = try JSONSerialization.data(withJSONObject: json["rules"] ?? [:])
        var settings = GameSettings()
        settings.rules = try JSONDecoder().decode(GameRules.self, from: rulesData)
        settings.realEntry = .pips
        settings.nextPlayerOverlay = false

        let dice = json["dice"] as? [Int] ?? []
        var used = 0
        let store = GameStore(repository: MemoryRepository(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        store.roller = {
            defer { used += 1 }
            return used < dice.count ? dice[used] : 0
        }
        let names = json["players"] as? [String] ?? []
        store.startGame(players: names.enumerated().map { Player(name: $1, avatar: "", colorIndex: $0) }, settings: settings)

        let steps = json["steps"] as? [[String: Any]] ?? []
        for (n, step) in steps.enumerated() {
            let label = "\(file) Schritt \(n + 1)"
            let actionData = try JSONSerialization.data(withJSONObject: step["action"] ?? [:])
            let action = try JSONDecoder().decode(GameAction.self, from: actionData)

            let before = store.game
            let usedBefore = used
            store.perform(action)
            if step["error"] as? Bool == true {
                #expect(store.game == before, "\(label): \(action) hätte abgelehnt werden müssen")
                #expect(used == usedBefore, "\(label): bei abgelehnter Aktion gewürfelt")
            }
            if let expect = step["expect"] as? [String: Any] {
                try check(store, expect, label)
            }
        }
        if let expected = json["expected"] as? [String: Any] {
            try check(store, expected, "\(file) Ende")
        }
        #expect(used == dice.count, "\(file): \(used) von \(dice.count) Würfeln verbraucht")
    }

    /// Vergleicht nur die angegebenen Schlüssel (Tabelle im README).
    private func check(_ store: GameStore, _ expect: [String: Any], _ label: String) throws {
        let game = try #require(store.game)
        for (key, value) in expect {
            let actual: Any?
            switch key {
            case "current": actual = game.current
            case "winners": actual = game.winners
            case "finalRoundFrom": actual = game.finalRoundFrom
            case "timeline": actual = game.timeline
            case "scores": actual = game.players.map(\.score)
            case "players": actual = try plain(game.players)
            case "turn": actual = try plain(game.turn)
            case "offer": actual = try game.offer.map(plain)
            case "tiebreak": actual = try game.tiebreak.map(plain)
            case "log": actual = game.log.map { [$0.player, $0.points, $0.penalty] }
            case "canUndo": actual = store.canUndo
            default:
                Issue.record("\(label): unbekannter Schlüssel \(key)")
                continue
            }
            #expect(Self.matches(actual, value), "\(label): \(key) ist \(String(describing: actual)), erwartet \(value)")
        }
    }

    /// Swift-Wert als JSON-Objekt (gleiche Schlüssel wie beim Speichern, z. B. `mackes`).
    private func plain<T: Encodable>(_ value: T) throws -> Any {
        try JSONSerialization.jsonObject(with: JSONEncoder().encode(value), options: .fragmentsAllowed)
    }

    /// Teil-Vergleich: Objekte prüfen nur die erwarteten Schlüssel, `null` heißt „nicht gesetzt“.
    nonisolated static func matches(_ actual: Any?, _ expected: Any) -> Bool {
        switch expected {
        case is NSNull:
            return actual == nil || actual is NSNull
        case let e as [String: Any]:
            guard let a = actual as? [String: Any] else { return false }
            return e.allSatisfy { key, value in matches(a[key], value) }
        case let e as [Any]:
            guard let a = actual as? [Any], a.count == e.count else { return false }
            return zip(a, e).allSatisfy { matches($0, $1) }
        default:
            guard let a = actual else { return false }
            if let e = expected as? NSNumber, let a = a as? NSNumber { return e == a }
            if let e = expected as? String, let a = a as? String { return e == a }
            if let e = expected as? NSNumber {
                if let a = a as? Int { return e.intValue == a && !isBool(e) }
                if let a = a as? Bool { return e.boolValue == a && isBool(e) }
            }
            return false
        }
    }

    private nonisolated static func isBool(_ n: NSNumber) -> Bool {
        CFGetTypeID(n) == CFBooleanGetTypeID()
    }
}
