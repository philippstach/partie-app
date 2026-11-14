// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SpieleKern
@testable import SpielSolitaer

final class KatalogTests: XCTestCase {
    func testListenGeladen() {
        let k = DealCatalog.load()
        XCTAssertGreaterThanOrEqual(k.seeds(draw: 1).count, 1000)
        XCTAssertGreaterThanOrEqual(k.seeds(draw: 3).count, 1000)
        XCTAssertEqual(Set(k.seeds(draw: 1)).count, k.seeds(draw: 1).count)
    }

    func testTagesspiel() throws {
        let k = DealCatalog.load()
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        for f in try TestJSON.cases("tagesspiel") {
            let teile = (f["datum"] as! String).split(separator: "-").map { Int($0)! }
            let tage = DealCatalog.daysSinceEpoch(year: teile[0], month: teile[1], day: teile[2], calendar: cal)
            XCTAssertEqual(tage, f["tage"] as! Int, f["datum"] as! String)
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage), UInt64(f["seed"] as! Int), f["datum"] as! String)
        }
    }

    func testTagesspielSpider() throws {
        let k = DealCatalog.load()
        XCTAssertGreaterThanOrEqual(k.seeds(for: .spider(1)).count, 1000)
        XCTAssertGreaterThanOrEqual(k.seeds(for: .spider(2)).count, 1000)
        XCTAssertTrue(k.seeds(for: .spider(4)).isEmpty)               // 4 Farben: vorerst nur Zufall
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        for f in try TestJSON.cases("spider/tagesspiel") {
            let teile = (f["datum"] as! String).split(separator: "-").map { Int($0)! }
            let tage = DealCatalog.daysSinceEpoch(year: teile[0], month: teile[1], day: teile[2], calendar: cal)
            XCTAssertEqual(tage, f["tage"] as! Int, f["datum"] as! String)
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage, kind: .spider), UInt64(f["seed"] as! Int), f["datum"] as! String)
        }
    }

    func testAuswahlMeidetLetzte() {
        let k = DealCatalog(seeds1: [1, 2, 3, 4], seeds3: [])
        var rng = SplitMix64(seed: 5)
        for _ in 0..<50 {
            XCTAssertEqual(k.pick(draw: 1, recent: [1, 2, 3], using: &rng), 4)
        }
        // alle gesperrt → trotzdem eine Partie
        XCTAssertNotNil(k.pick(draw: 1, recent: [1, 2, 3, 4], using: &rng))
        XCTAssertNil(k.pick(draw: 3, recent: [], using: &rng))
    }
}
