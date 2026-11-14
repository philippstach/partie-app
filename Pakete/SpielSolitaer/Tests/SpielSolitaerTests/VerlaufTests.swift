// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

@MainActor
final class VerlaufTests: XCTestCase {
    private let k = DealCatalog.shared
    private func deal(_ mode: GameMode = .klondike(1), number: Int = 5, kind: DealKind = .solvable) -> DealInfo {
        DealInfo(seed: k.seed(mode: mode, number: number) ?? 99, mode: mode, kind: kind)
    }

    func testEintragBeiSiegUndNiederlageUndAufgeben() {
        let s = StatsStore(url: nil)
        let d = deal()
        s.handle(.started(d))
        s.handle(.won(d, moves: 90, score: 500, seconds: 200, undoUsed: false, hintUsed: false))
        s.handle(.started(d)); s.handle(.abandoned(d))                         // Niederlage (Neu/Aufgeben)
        XCTAssertEqual(s.data.history.count, 2)
        let win = s.data.history[0], loss = s.data.history[1]
        XCTAssertTrue(win.won); XCTAssertEqual(win.time, 200); XCTAssertEqual(win.moves, 90); XCTAssertEqual(win.score, 500)
        XCTAssertEqual(win.number, 5); XCTAssertEqual(win.mode, "klondike1"); XCTAssertNotNil(win.level)
        XCTAssertFalse(loss.won); XCTAssertNil(loss.time)
    }

    func testZufallspartieHatKeineNummer() {
        let s = StatsStore(url: nil)
        let d = DealInfo(seed: 123_456_789, mode: .klondike(1), kind: .random)
        s.handle(.started(d))
        s.handle(.won(d, moves: 80, score: 400, seconds: 100, undoUsed: false, hintUsed: false))
        XCTAssertNil(s.data.history[0].number)
        XCTAssertNil(s.data.history[0].level)
    }

    func testBegrenzungAuf2000() {
        var list: [HistoryEntry] = []
        for i in 0..<2100 { StatsHistory.append(HistoryEntry(date: "2026-10-06", mode: "klondike1", won: true, time: Double(i)), to: &list) }
        XCTAssertEqual(list.count, 2000)
        XCTAssertEqual(list.first?.time, 100)                                    // die ältesten 100 sind herausgefallen
        XCTAssertEqual(list.last?.time, 2099)
    }

    func testWochenSummen() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2026, month: 10, day: 7))!      // Mittwoch
        let list = [
            HistoryEntry(date: "2026-10-05", mode: "klondike1", won: true, time: 100),       // diese Woche (Mo)
            HistoryEntry(date: "2026-10-07", mode: "klondike1", won: true, time: 90),
            HistoryEntry(date: "2026-10-06", mode: "klondike1", won: false),
            HistoryEntry(date: "2026-09-30", mode: "klondike1", won: true, time: 80),       // Vorwoche
            HistoryEntry(date: "2026-10-06", mode: "spider2", won: true, time: 70),          // anderer Modus
            HistoryEntry(date: "2026-06-01", mode: "klondike1", won: true, time: 60),        // zu alt
        ]
        let weeks = StatsHistory.weekly(list, mode: .klondike(1), today: today, calendar: cal)
        XCTAssertEqual(weeks.count, 8)
        XCTAssertEqual(weeks.last, WeekBucket(start: cal.date(from: DateComponents(year: 2026, month: 10, day: 5))!, wins: 2, losses: 1))
        XCTAssertEqual(weeks[6].wins, 1)
        XCTAssertEqual(weeks.reduce(0) { $0 + $1.wins }, 3)
        XCTAssertEqual(HistoryCard.weekSummary(weeks), String(localized: "In den letzten 8 Wochen 3 Siege, beste Woche 2"))
    }

    func testBesteZehnSortiert() {
        var list: [HistoryEntry] = []
        for t in [300.0, 120, 450, 120, 200, 210, 220, 230, 240, 250, 260, 270] {
            list.append(HistoryEntry(date: "2026-10-\(String(format: "%02d", list.count + 1))", mode: "klondike1", won: true, time: t, number: list.count + 1))
        }
        list.append(HistoryEntry(date: "2026-10-20", mode: "klondike1", won: false))          // Niederlage zählt nicht
        list.append(HistoryEntry(date: "2026-10-21", mode: "spider2", won: true, time: 5))   // anderer Modus
        let top = StatsHistory.top10(list, mode: .klondike(1))
        XCTAssertEqual(top.count, 10)
        XCTAssertEqual(top.compactMap(\.time), [120, 120, 200, 210, 220, 230, 240, 250, 260, 270])
        XCTAssertEqual(top[0].number, 2)                                                       // gleiche Zeit: der frühere zuerst
        XCTAssertEqual(top[1].number, 4)
    }

    func testRecentWinTimesUndGenug() {
        var list: [HistoryEntry] = []
        for i in 0..<25 { list.append(HistoryEntry(date: "2026-10-06", mode: "klondike1", won: true, time: Double(i))) }
        let t = StatsHistory.recentWinTimes(list, mode: .klondike(1))
        XCTAssertEqual(t.count, 20)
        XCTAssertEqual(t.first, 5)
        XCTAssertFalse(StatsHistory.hasEnough(Array(list.prefix(2)), mode: .klondike(1)))
        XCTAssertTrue(StatsHistory.hasEnough(Array(list.prefix(3)), mode: .klondike(1)))
    }

    func testAltesFormatLaedtLeerUndSpeichert() throws {
        let d = try JSONDecoder().decode(StatsData.self, from: Data(#"{"version":2,"modes":{},"daily":{}}"#.utf8))
        XCTAssertTrue(d.history.isEmpty)
        var data = StatsData()
        data.history = [HistoryEntry(date: "2026-10-06", mode: "freecell", won: true, time: 12.5, moves: 99, score: nil, number: 617)]
        let back = try JSONDecoder().decode(StatsData.self, from: JSONEncoder().encode(data))
        XCTAssertEqual(back.history, data.history)
    }

    func testZuruecksetzenLoeschtVerlaufDesModus() {
        let s = StatsStore(url: nil)
        let a = deal(.klondike(1)), b = deal(.klondike(3))
        for d in [a, b] {
            s.handle(.started(d))
            s.handle(.won(d, moves: 1, score: 1, seconds: 1, undoUsed: false, hintUsed: false))
        }
        s.reset(mode: .klondike(1))
        XCTAssertEqual(s.data.history.map(\.mode), ["klondike3"])
    }

    func testStartPerNummerAusBestenZehn() {
        let app = AppModel(prefs: AppPreferences(defaults: UserDefaults(suiteName: "vl-\(UUID().uuidString)")!), stats: StatsStore(url: nil), folder: nil, seed: 1)
        XCTAssertTrue(app.startNumbered(7, mode: .klondike(1)))
        XCTAssertEqual(app.session.deal.number, "7")
    }
}
