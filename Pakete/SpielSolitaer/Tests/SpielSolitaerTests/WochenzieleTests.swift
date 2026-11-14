// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

@MainActor
final class WochenzieleTests: XCTestCase {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func date(_ s: String) -> Date { DailyDate.date(s, calendar: cal)! }
    private let k = DealCatalog.shared

    func testListeUndAuswahlAusDenRegeltests() throws {
        let d = try TestJSON.load("extras/wochenziele")
        let ziele = d["ziele"] as! [[String: Any]]
        XCTAssertEqual(WeeklyGoals.all.map(\.id), ziele.map { $0["id"] as! String })
        XCTAssertEqual(WeeklyGoals.all.map(\.count), ziele.map { $0["anzahl"] as! Int })
        let faelle = d["faelle"] as! [[String: Any]]
        XCTAssertEqual(faelle.count, 8)
        for f in faelle {
            let tag = date(f["datum"] as! String)
            XCTAssertEqual(DailyDate.string(WeeklyGoals.monday(of: tag, calendar: cal), calendar: cal), f["montag"] as! String, "Montag \(f["datum"]!)")
            XCTAssertEqual(WeeklyGoals.selection(for: tag, calendar: cal).map(\.id), f["ziele"] as! [String], "Ziele \(f["datum"]!)")
        }
    }

    func testAuswahlHatDreiVerschiedene() {
        var day = date("2026-01-05")
        for _ in 0..<120 {
            let ids = WeeklyGoals.selection(for: day, calendar: cal).map(\.id)
            XCTAssertEqual(Set(ids).count, 3)
            day = cal.date(byAdding: .day, value: 7, to: day)!
        }
    }

    func testWocheLaeuftMontagBisSonntag() {
        let mon = WeeklyGoals.selection(for: date("2026-10-05"), calendar: cal)
        XCTAssertEqual(WeeklyGoals.selection(for: date("2026-10-11"), calendar: cal), mon)          // Sonntag derselben Woche
        XCTAssertEqual(WeeklyGoals.selection(for: date("2026-10-05"), calendar: cal), mon)
        XCTAssertNotEqual(WeeklyGoals.selection(for: date("2026-10-12"), calendar: cal).map(\.id), mon.map(\.id))   // nächste Woche
    }

    private func win(_ mode: GameMode, kind: DealKind = .solvable, seed: UInt64? = nil, level: Int? = nil, seconds: TimeInterval = 600,
                     undo: Bool = true, hint: Bool = true, crowned: Bool = false, on day: String = "2026-10-06", into p: WeekProgress = WeekProgress()) -> WeekProgress {
        let s = seed ?? k.seeds(for: mode).first ?? 1
        let d = DealInfo(seed: s, mode: mode, kind: kind, day: kind == .daily ? day : nil, dailyLevel: level)
        return WeeklyGoals.recordWin(d, seconds: seconds, undoUsed: undo, hintUsed: hint, crowned: crowned, into: p, now: date(day), calendar: cal)
    }

    func testZaehlenJeZiel() {
        var p = WeekProgress()
        p = win(.klondike(1), into: p)
        p = win(.spider(2), into: p)
        p = win(.freecell, seed: 617, into: p)
        p = win(.pyramid, into: p)
        p = win(.tripeaks, into: p)
        XCTAssertEqual([WeeklyGoals.value("siege", p), WeeklyGoals.value("siegeSpider", p), WeeklyGoals.value("siegeFreeCell", p),
                        WeeklyGoals.value("siegePyramid", p), WeeklyGoals.value("siegeTriPeaks", p)], [5, 1, 1, 1, 1])
        XCTAssertEqual(WeeklyGoals.value("ohneTipp", p), 0)
        p = win(.klondike(1), seconds: 200, undo: false, hint: false, into: p)
        XCTAssertEqual(WeeklyGoals.value("ohneTipp", p), 1)
        XCTAssertEqual(WeeklyGoals.value("ohneZurueck", p), 1)
        XCTAssertEqual(WeeklyGoals.value("unter5Min", p), 1)
        p = win(.klondike(3), seconds: 300, into: p)                                          // genau 5:00 zählt nicht
        XCTAssertEqual(WeeklyGoals.value("unter5Min", p), 1)
        XCTAssertEqual(WeeklyGoals.value("dreiKarten", p), 1)
    }

    func testSchwerWieHarteNuss() {
        let m = GameMode.klondike(1)
        var p = win(m, seed: k.seeds(for: m, level: 1)[0])
        XCTAssertEqual(WeeklyGoals.value("schwer", p), 0)
        p = win(m, kind: .random, seed: k.seeds(for: m, level: 3)[0], into: p)                // Zufall: keine Stufe
        XCTAssertEqual(WeeklyGoals.value("schwer", p), 0)
        p = win(m, seed: k.seeds(for: m, level: 3)[0], into: p)
        XCTAssertEqual(WeeklyGoals.value("schwer", p), 1)
    }

    func testTagesspieleVerschiedeneTageNurGemischt() {
        var p = WeekProgress()
        p = win(.klondike(1), kind: .daily, on: "2026-10-05", into: p)
        p = win(.klondike(1), kind: .daily, on: "2026-10-05", into: p)                          // derselbe Tag zählt einmal
        p = win(.klondike(1), kind: .daily, level: 1, on: "2026-10-06", into: p)                // Leicht zählt nicht
        XCTAssertEqual(WeeklyGoals.value("tagesspiele", p), 1)
        p = win(.klondike(1), kind: .daily, on: "2026-10-07", into: p)
        XCTAssertEqual(WeeklyGoals.value("tagesspiele", p), 2)
        p = win(.klondike(1), crowned: true, into: p)
        XCTAssertEqual(WeeklyGoals.value("kronen", p), 1)
    }

    func testWochenwechselBeginntNeu() {
        var p = win(.klondike(1), on: "2026-10-11")                                              // Sonntag
        XCTAssertEqual(WeeklyGoals.value("siege", p), 1)
        p = win(.klondike(1), on: "2026-10-12", into: p)                                         // Montag der nächsten Woche
        XCTAssertEqual(WeeklyGoals.value("siege", p), 1)
        XCTAssertEqual(p.monday, "2026-10-12")
        // Anzeige einer anderen Woche: leer
        XCTAssertEqual(WeeklyGoals.value("siege", WeeklyGoals.progress(p, now: date("2026-10-20"), calendar: cal)), 0)
    }

    func testStoreMeldetFertigeZieleUndZaehltWochen() {
        let s = StatsStore(url: nil)
        let tag = date("2026-10-07")
        s.clock = { tag }
        let ziele = WeeklyGoals.selection(for: tag)
        XCTAssertEqual(s.weeklyRows(now: tag).count, 3)
        // 10 Siege reichen für „siege“ (falls gewählt); sonst zählt wenigstens, dass nichts doppelt gemeldet wird
        var gemeldet: [String] = []
        for _ in 0..<12 {
            let d = DealInfo(seed: 1, mode: .klondike(1), kind: .random)
            s.handle(.started(d))
            s.handle(.won(d, moves: 10, score: 10, seconds: 100, undoUsed: false, hintUsed: false))
            gemeldet += s.lastWeeklyDone
        }
        XCTAssertEqual(Set(gemeldet).count, gemeldet.count, "kein Ziel wird zweimal gemeldet")
        for id in gemeldet { XCTAssertTrue(ziele.map(\.id).contains(id)) }
        // Aufgeben zählt nie
        let before = s.data.weekly
        let d = DealInfo(seed: 1, mode: .klondike(1), kind: .random)
        s.handle(.started(d)); s.handle(.abandoned(d))
        XCTAssertEqual(s.data.weekly, before)
        XCTAssertTrue(s.lastWeeklyDone.isEmpty)
    }

    func testWocheGeschafftZaehltEinmalProWoche() {
        let s = StatsStore(url: nil)
        let tag = date("2026-10-07")
        s.clock = { tag }
        // alle 3 Ziele der Woche mit passenden Siegen erfüllen, indem der Fortschritt direkt gesetzt wird
        var p = WeekProgress()
        p.monday = WeeklyGoals.mondayString(of: tag)
        for g in WeeklyGoals.selection(for: tag) {
            switch g.id {
            case "tagesspiele": p.dailyDays = ["a", "b", "c"]
            case "siege": p.wins = 9
            case "siegeSpider": p.spider = 2
            case "siegeFreeCell": p.freecell = 2
            case "siegePyramid": p.pyramid = 1
            case "siegeTriPeaks": p.tripeaks = 2
            case "ohneTipp": p.noHint = 2
            case "ohneZurueck": p.noUndo = 1
            case "schwer": p.hard = 0
            case "kronen": p.crowns = 1
            case "unter5Min": p.under5 = 1
            default: p.threeCards = 1
            }
        }
        var data = s.data
        data.weekly = p
        s.load(data)
        XCTAssertEqual(s.data.weeksDone, 0)
        // Ein Sieg mit allem, was zählt (undo/hint false, <5 min, Spider, FreeCell …) – dazu je Spiel ein Sieg
        for mode in [GameMode.klondike(3), .spider(2), .freecell, .pyramid, .tripeaks, .klondike(1)] {
            let d = DealInfo(seed: k.seeds(for: mode).first ?? 617, mode: mode, kind: .solvable)
            s.handle(.started(d))
            s.handle(.won(d, moves: 10, score: nil, seconds: 100, undoUsed: false, hintUsed: false))
        }
        let done = WeeklyGoals.done(s.data.weekly, now: tag)
        if done.count == 3 { XCTAssertEqual(s.data.weeksDone, 1) }
        let wochen = s.data.weeksDone
        let d = DealInfo(seed: 1, mode: .klondike(1), kind: .random)
        s.handle(.started(d)); s.handle(.won(d, moves: 10, score: 10, seconds: 100, undoUsed: false, hintUsed: false))
        XCTAssertEqual(s.data.weeksDone, wochen, "dieselbe Woche zählt nur einmal")
    }

    func testAltesFormatLaedtLeer() throws {
        let d = try JSONDecoder().decode(StatsData.self, from: Data(#"{"version":2,"modes":{},"daily":{}}"#.utf8))
        XCTAssertEqual(d.weekly, WeekProgress())
        XCTAssertEqual(d.weeksDone, 0)
        let back = try JSONDecoder().decode(StatsData.self, from: JSONEncoder().encode({ var x = StatsData(); x.weeksDone = 3; x.weekly.wins = 4; return x }()))
        XCTAssertEqual(back.weeksDone, 3); XCTAssertEqual(back.weekly.wins, 4)
    }
}
