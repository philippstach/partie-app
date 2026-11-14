// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

@MainActor
final class TagesspielStufenTests: XCTestCase {
    private let k = DealCatalog.load()

    func testFormelAusDenRegeltests() throws {
        let faelle = try TestJSON.cases("extras/tagesspiel-stufen")
        XCTAssertEqual(faelle.count, 14)
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        for f in faelle {
            let teile = (f["datum"] as! String).split(separator: "-").map { Int($0)! }
            let tage = DealCatalog.daysSinceEpoch(year: teile[0], month: teile[1], day: teile[2], calendar: cal)
            let kind: GameKind = (f["liste"] as! String) == "spider2" ? .spider : .klondike
            let titel = "\(f["datum"]!) \(f["liste"]!)"
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage, kind: kind, level: 1), UInt64(f["leicht"] as! Int), "leicht \(titel)")
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage, kind: kind, level: 3), UInt64(f["schwer"] as! Int), "schwer \(titel)")
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: tage, kind: kind, level: nil), UInt64(f["gemischt"] as! Int), "gemischt \(titel)")
        }
    }

    func testNurKlondikeUndSpiderHabenStufen() {
        XCTAssertTrue(DealCatalog.hasDailyLevels(.klondike))
        XCTAssertTrue(DealCatalog.hasDailyLevels(.spider))
        for kind in [GameKind.freecell, .pyramid, .tripeaks, .golf, .yukon] {
            XCTAssertFalse(DealCatalog.hasDailyLevels(kind))
            XCTAssertEqual(k.dailySeed(daysSinceEpoch: 5, kind: kind, level: 1), k.dailySeed(daysSinceEpoch: 5, kind: kind), "\(kind) ignoriert die Stufe")
        }
    }

    func testStartDailyMitStufe() {
        let app = AppModel(prefs: AppPreferences(defaults: UserDefaults(suiteName: "ts-\(UUID().uuidString)")!), stats: StatsStore(url: nil), folder: nil, seed: 1)
        let day = Date()
        app.startDaily(day, kind: .klondike, level: 3)
        XCTAssertEqual(app.session.deal.kind, .daily)
        XCTAssertEqual(app.session.deal.dailyLevel, 3)
        XCTAssertEqual(DealCatalog.shared.level(mode: .klondike(1), seed: app.session.deal.seed), 3)
        app.startDaily(day, kind: .klondike)
        XCTAssertNil(app.session.deal.dailyLevel)
        app.startDaily(day, kind: .pyramid, level: 1)                          // Pyramid hat keine Stufen
        XCTAssertNil(app.session.deal.dailyLevel)
    }

    func testStatistikLeichtSchwerOhneKroneUndPokal() {
        let s = StatsStore(url: nil)
        let m = GameMode.klondike(1)
        let leicht = DealInfo(seed: k.seeds(for: m, level: 1)[0], mode: m, kind: .daily, day: "2026-10-07", dailyLevel: 1)
        let schwer = DealInfo(seed: k.seeds(for: m, level: 3)[0], mode: m, kind: .daily, day: "2026-10-07", dailyLevel: 3)
        for d in [leicht, schwer] {
            s.handle(.started(d))
            s.handle(.won(d, moves: 100, score: 100, seconds: 50, undoUsed: false, hintUsed: false))
        }
        XCTAssertEqual(s.dailyLevelWon(.klondike, level: 1), ["2026-10-07"])
        XCTAssertEqual(s.dailyLevelWon(.klondike, level: 3), ["2026-10-07"])
        XCTAssertTrue(s.dailyWon(.klondike).isEmpty)                            // Gemischt bleibt unberührt
        XCTAssertTrue(s.crowned(.klondike).isEmpty)                             // kein Tagesziel, keine Krone
        XCTAssertNil(s.lastDaily)
        XCTAssertTrue(s.dailyStarted(.klondike).isEmpty)
    }

    func testDealInfoMitStufeSpeichern() throws {
        let d = DealInfo(seed: 5, mode: .klondike(1), kind: .daily, day: "2026-10-07", dailyLevel: 1)
        XCTAssertEqual(try JSONDecoder().decode(DealInfo.self, from: JSONEncoder().encode(d)), d)
        let alt = try JSONDecoder().decode(DealInfo.self, from: Data(#"{"seed":5,"kind":"daily"}"#.utf8))
        XCTAssertNil(alt.dailyLevel)
    }
}
