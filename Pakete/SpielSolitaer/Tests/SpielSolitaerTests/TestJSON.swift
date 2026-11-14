// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
@testable import SpielSolitaer

/// Liest das JSON-Format der gemeinsamen Testfälle (`Shared/regeltests/*.json`, deutsche Schlüssel).
enum TestJSON {
    static func load(_ name: String, file: String = #filePath) throws -> [String: Any] {
        // …/iOS/SolitaerTests/TestJSON.swift → …/Shared/regeltests/<name>.json
        var url = URL(fileURLWithPath: file)
        for _ in 0..<3 { url.deleteLastPathComponent() }
        url.append(path: "Shared/regeltests/\(name).json")
        let data = try Data(contentsOf: url)
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }

    static func cases(_ name: String, file: String = #filePath) throws -> [[String: Any]] {
        try load(name, file: file)["faelle"] as! [[String: Any]]
    }

    static func card(_ s: String) -> CardID {
        let chars = Array(s)
        return CardID(rank: CardID.rankLetters.firstIndex(of: chars[0])! + 1, suit: Suit(rawValue: CardID.suitLetters.firstIndex(of: chars[1])!)!)
    }

    static func cards(_ any: Any?) -> [CardID] { (any as? [String] ?? []).map(card) }

    static func state(_ d: [String: Any]) -> GameState {
        let ablage = cards(d["ablage"])
        let cols = (d["spalten"] as! [[String: Any]]).map { Column(down: cards($0["verdeckt"]), up: cards($0["offen"])) }
        return GameState(draw: d["ziehen"] as! Int, stock: cards(d["stapel"]), waste: ablage,
                         fan: d["faecher"] as? Int ?? min(1, ablage.count), foundation: d["ziel"] as! [Int], cols: cols,
                         score: d["punkte"] as? Int ?? 0, moves: d["zuege"] as? Int ?? 0, passes: d["durchgaenge"] as? Int ?? 0)
    }

    static func place(_ s: String) -> Pile {
        switch s.first! {
        case "A": .waste
        case "S": .column(Int(String(s.dropFirst()))!)
        default: .foundation(Int(String(s.dropFirst()))!)
        }
    }

    static func move(_ d: [String: Any]) -> Move {
        if d["von"] as! String == "stapel" { return .draw }
        return .move(from: place(d["von"] as! String), to: place(d["nach"] as! String), count: d["anzahl"] as? Int ?? 1)
    }

    static func moves(_ any: Any?) -> [Move] { (any as? [[String: Any]] ?? []).map(move) }
}
