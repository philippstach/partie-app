// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielYacht

/// Liest die gemeinsamen Regeltests aus `Shared/regeltests` (dieselben wie bei Android).
final class RegeltestsTests: XCTestCase {
    private var regeltests: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Shared/regeltests")
    }

    func testWertung() throws {
        let data = try Data(contentsOf: regeltests.appending(path: "wertung.json"))
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let cases = try XCTUnwrap(root["wertung"] as? [[String: Any]])
        XCTAssertGreaterThanOrEqual(cases.count, 44)
        for c in cases {
            let dice = c["dice"] as! [Int]
            let category = try XCTUnwrap(Category(rawValue: c["category"] as! String))
            let score = Scoring.score(dice, category, joker: c["joker"] as! Bool)
            XCTAssertEqual(score, c["expectedScore"] as? Int, c["name"] as? String ?? "")
        }
    }

    func testPartien() throws {
        let dir = regeltests.appending(path: "partien")
        let files = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }.sorted { $0.path < $1.path }
        XCTAssertGreaterThanOrEqual(files.count, 13)
        for file in files { try runGame(file) }
    }

    private func runGame(_ file: URL) throws {
        let name = file.lastPathComponent
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        let rulesJSON = try JSONSerialization.data(withJSONObject: root["rules"] ?? [:])
        let rules = try JSONDecoder().decode(Rules.self, from: rulesJSON)
        var game = GameState(playerNames: root["players"] as! [String], rules: rules)
        var feed = (root["dice"] as! [Int])[...]
        let roller: () -> Int = { feed.popFirst() ?? 1_000 }   // 1000 fällt im Vergleich sofort auf

        for (n, step) in (root["steps"] as! [[String: Any]]).enumerated() {
            let a = step["action"] as! [String: Any]
            let action: Action = a["type"] as! String == "roll"
                ? .roll(keep: a["keep"] as! [Int])
                : .score(Category(rawValue: a["category"] as! String)!)
            let before = game, feedBefore = feed.count
            let label = "\(name) Schritt \(n + 1)"
            if step["error"] as? Bool == true {
                XCTAssertThrowsError(try game.apply(action, roller: roller), label)
                XCTAssertEqual(game, before, label)
                XCTAssertEqual(feed.count, feedBefore, "\(label): Würfel verbraucht")
                continue
            }
            try game.apply(action, roller: roller)
            if let e = step["expect"] as? [String: Any] {
                if let v = e["current"] as? Int { XCTAssertEqual(game.current, v, label) }
                if let v = e["dice"] as? [Int] { XCTAssertEqual(game.dice, v, label) }
                if let v = e["rollsUsed"] as? Int { XCTAssertEqual(game.rollsUsed, v, label) }
            }
        }
        XCTAssertTrue(feed.isEmpty, "\(name): Würfel übrig")
        let exp = root["expected"] as! [String: Any]
        if let f = exp["finished"] as? Bool { XCTAssertEqual(game.finished, f, name) }
        if let scores = exp["scores"] as? [[String: Int]] {
            for (i, s) in scores.enumerated() {
                let got = Dictionary(uniqueKeysWithValues: game.players[i].scores.map { ($0.key.rawValue, $0.value) })
                XCTAssertEqual(got, s, "\(name) Spieler \(i)")
            }
        }
        if let totals = exp["totals"] as? [[String: Int]] {
            for (i, t) in totals.enumerated() {
                let g = game.totals(player: i)
                XCTAssertEqual(g.upper, t["upper"], name); XCTAssertEqual(g.bonus, t["bonus"], name)
                XCTAssertEqual(g.lower, t["lower"], name); XCTAssertEqual(g.kniffelBonus, t["kniffelBonus"], name)
                XCTAssertEqual(g.total, t["total"], name)
            }
        }
    }
}
