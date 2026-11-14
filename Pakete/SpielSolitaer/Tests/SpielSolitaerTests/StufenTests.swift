// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SpieleKern
@testable import SpielSolitaer

@MainActor
final class StufenTests: XCTestCase {
    private let listen: [(String, GameMode)] = [("ziehen1", .klondike(1)), ("ziehen3", .klondike(3)), ("spider1", .spider(1)), ("spider2", .spider(2)), ("pyramid", .pyramid), ("tripeaks", .tripeaks), ("golf", .golf), ("yukon", .yukon)]

    func testStufenAusDenRegeltests() throws {
        let k = DealCatalog.load()
        let faelle = try TestJSON.cases("extras/stufen").filter { f in listen.contains { $0.0 == f["liste"] as! String } }
        XCTAssertEqual(faelle.count, 8)
        for f in faelle {
            let name = f["liste"] as! String
            let mode = listen.first { $0.0 == name }!.1
            let liste = k.seeds(for: mode)
            // Anzahl je Stufe
            let anzahl = f["anzahl"] as! [String: Int]
            for stufe in 1...3 {
                XCTAssertEqual(k.seeds(for: mode, level: stufe).count, anzahl[String(stufe)], "\(name) Stufe \(stufe)")
            }
            // Stufe der ersten 10 Partien in Reihenfolge der Liste
            let erste = f["erste10"] as! [[Int]]
            XCTAssertEqual(liste.prefix(10).map { [Int($0), k.level(mode: mode, seed: $0)!] }, erste, name)
        }
    }

    func testGemischtIstDieGanzeListe() {
        let k = DealCatalog.load()
        for (_, mode) in listen {
            XCTAssertEqual(k.seeds(for: mode, level: 0), k.seeds(for: mode))
            XCTAssertTrue(k.hasLevels(mode))
        }
        XCTAssertFalse(k.hasLevels(.spider(4)))
        XCTAssertFalse(k.hasLevels(.freecell))
        XCTAssertNil(k.level(mode: .spider(4), seed: 1))
    }

    func testAuswahlZiehtNurAusDerGewaehltenStufe() {
        let k = DealCatalog.load()
        var rng = SplitMix64(seed: 11)
        for stufe in 1...3 {
            for _ in 0..<40 {
                let seed = k.pick(mode: .klondike(1), level: stufe, recent: [], using: &rng)!
                XCTAssertEqual(k.level(mode: .klondike(1), seed: seed), stufe)
            }
        }
        // die zuletzt gespielten 200 werden gemieden
        let leicht = k.seeds(for: .klondike(1), level: 1)
        let gesperrt = Array(leicht.prefix(200))
        for _ in 0..<60 {
            let seed = k.pick(mode: .klondike(1), level: 1, recent: gesperrt, using: &rng)!
            XCTAssertFalse(gesperrt.contains(seed))
            XCTAssertEqual(k.level(mode: .klondike(1), seed: seed), 1)
        }
    }

    func testNeuesSpielRespektiertEinstellung() {
        let p = AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 1, url: nil)
        p.difficulty = 3
        for _ in 0..<15 {
            store.newGame()
            XCTAssertEqual(DealCatalog.shared.level(mode: .klondike(1), seed: store.deal.seed), 3)
            XCTAssertEqual(store.deal.kind, .solvable)
        }
        p.solvableDeals = false                            // „Zufällige Partien“ geht vor
        store.newGame()
        XCTAssertEqual(store.deal.kind, .random)
    }

    func testStatistikJeStufe() {
        let k = DealCatalog.shared
        let leicht = k.seeds(for: .klondike(1), level: 1)[0], schwer = k.seeds(for: .klondike(1), level: 3)[0]
        let s = StatsStore(url: nil)
        let a = DealInfo(seed: leicht, mode: .klondike(1), kind: .solvable)
        let b = DealInfo(seed: schwer, mode: .klondike(1), kind: .solvable)
        s.handle(.started(a)); s.handle(.won(a, moves: 100, score: 100, seconds: 100))
        s.handle(.started(b))
        let z = s.stats(mode: .klondike(1)).levels
        XCTAssertEqual(z["1"], { var c = LevelCount(); c.played = 1; c.won = 1; return c }())
        XCTAssertEqual(z["3"]?.played, 1)
        XCTAssertEqual(z["3"]?.won, 0)
        XCTAssertNil(z["2"])
        // Zufällige Partien zählen in keiner Stufe
        let r = DealInfo(seed: 5, mode: .klondike(1), kind: .random)
        s.handle(.started(r))
        XCTAssertEqual(s.stats(mode: .klondike(1)).levels.values.map(\.played).reduce(0, +), 2)
    }

    func testAlteStatistikOhneStufenLaedt() throws {
        let alt = "{\"version\":2,\"modes\":{\"klondike1\":{\"played\":4}},\"daily\":{}}"
        let d = try JSONDecoder().decode(StatsData.self, from: Data(alt.utf8))
        XCTAssertEqual(d.modes["klondike1"]?.played, 4)
        XCTAssertEqual(d.modes["klondike1"]?.levels, [:])
    }
}
