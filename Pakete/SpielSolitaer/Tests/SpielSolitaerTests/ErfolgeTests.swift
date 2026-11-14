// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

@MainActor
final class ErfolgeTests: XCTestCase {
    private let k = DealCatalog.shared

    private func deal(_ mode: GameMode, kind: DealKind = .solvable, seed: UInt64? = nil) -> DealInfo {
        DealInfo(seed: seed ?? k.seeds(for: mode).first ?? 1, mode: mode, kind: kind)
    }

    private func seedOfLevel(_ level: Int, _ mode: GameMode) -> UInt64 { k.seeds(for: mode, level: level).first! }

    /// Sieg buchen und die neuen Abzeichen zurückgeben
    @discardableResult
    private func win(_ s: StatsStore, _ d: DealInfo, seconds: TimeInterval = 600, undo: Bool = true, hint: Bool = true) -> [Achievement] {
        s.handle(.started(d))
        s.handle(.won(d, moves: 100, score: nil, seconds: seconds, undoUsed: undo, hintUsed: hint))
        return s.lastAchievements
    }

    // MARK: je Erfolg positiv und negativ

    func testErsterSieg() {
        let s = StatsStore(url: nil)
        XCTAssertEqual(s.earnedCount, 0)
        s.handle(.started(deal(.klondike(1))))
        XCTAssertNil(s.earned(.ersterSieg))
        XCTAssertEqual(win(s, deal(.klondike(1))), [.ersterSieg])
    }

    func testOhneZurueckUndOhneTipp() {
        let s = StatsStore(url: nil)
        XCTAssertEqual(Set(win(s, deal(.klondike(1)), undo: false, hint: true)), [.ersterSieg, .ohneZurueck])
        XCTAssertEqual(win(s, deal(.klondike(1)), undo: true, hint: false), [.ohneTipp])
        XCTAssertEqual(win(s, deal(.klondike(1)), undo: true, hint: true), [])       // beides benutzt: nichts Neues
    }

    func testBlitzNurKlondikeUnterDreiMinuten() {
        let s = StatsStore(url: nil)
        XCTAssertFalse(win(s, deal(.klondike(1)), seconds: 180).contains(.blitz))      // genau 3:00 reicht nicht
        XCTAssertFalse(win(s, deal(.spider(1)), seconds: 60).contains(.blitz))          // Spider zählt nicht
        XCTAssertTrue(win(s, deal(.klondike(1)), seconds: 179.9).contains(.blitz))
    }

    func testDreiKartenUndSpinne4() {
        let s = StatsStore(url: nil)
        XCTAssertFalse(win(s, deal(.klondike(1))).contains(.dreiKarten))
        XCTAssertTrue(win(s, deal(.klondike(3))).contains(.dreiKarten))
        XCTAssertFalse(win(s, deal(.spider(2))).contains(.spinne4))
        XCTAssertTrue(win(s, DealInfo(seed: 5, mode: .spider(4), kind: .random)).contains(.spinne4))
    }

    func testSchwerNurBeiStufe3() {
        let s = StatsStore(url: nil)
        let m = GameMode.klondike(1)
        XCTAssertFalse(win(s, deal(m, seed: seedOfLevel(1, m))).contains(.schwer))
        XCTAssertFalse(win(s, deal(m, seed: seedOfLevel(2, m))).contains(.schwer))
        XCTAssertFalse(win(s, deal(m, kind: .random, seed: seedOfLevel(3, m))).contains(.schwer))     // Zufall hat keine Stufe
        XCTAssertTrue(win(s, deal(m, seed: seedOfLevel(3, m))).contains(.schwer))
    }

    func testFreeCellFlink() {
        let s = StatsStore(url: nil)
        XCTAssertFalse(win(s, deal(.freecell, seed: 617), seconds: 300).contains(.freecellFlink))
        XCTAssertFalse(win(s, deal(.klondike(1)), seconds: 100).contains(.freecellFlink))
        XCTAssertTrue(win(s, deal(.freecell, seed: 617), seconds: 299).contains(.freecellFlink))
    }

    func testAlleFuenf() {
        let s = StatsStore(url: nil)
        for m in [GameMode.klondike(1), .spider(2), .freecell, .pyramid, .tripeaks, .golf] {
            XCTAssertFalse(win(s, deal(m, seed: m.kind == .freecell ? 617 : nil)).contains(.alleFuenf), m.key)
        }
        XCTAssertTrue(win(s, deal(.yukon)).contains(.alleFuenf))                    // jetzt: alle sieben Spiele
        XCTAssertNotNil(s.earned(.alleFuenf))
    }

    func testSerien() {
        let s = StatsStore(url: nil)
        let d = deal(.klondike(1))
        for i in 1...4 { XCTAssertFalse(win(s, d).contains(.serie5), "Sieg \(i)") }
        XCTAssertTrue(win(s, d).contains(.serie5))                                       // 5. Sieg in Folge
        for _ in 6...9 { XCTAssertFalse(win(s, d).contains(.serie10)) }
        XCTAssertTrue(win(s, d).contains(.serie10))
    }

    func testSerieBrichtBeiAufgebenUndZaehltJeModus() {
        let s = StatsStore(url: nil)
        let d = deal(.klondike(1))
        for _ in 1...4 { win(s, d) }
        s.handle(.started(d)); s.handle(.abandoned(d))                                   // Aufgeben beendet die Serie
        XCTAssertFalse(win(s, d).contains(.serie5))
        for _ in 1...4 { win(s, deal(.spider(2))) }                                     // andere Serie in einem anderen Modus
        XCTAssertFalse(s.earned(.serie5) != nil)
    }

    func testHundert() {
        var data = StatsData()
        data.modes["klondike1"] = { var m = ModeStats(); m.won = 99; return m }()
        let s = StatsStore(url: nil)
        s.load(data)
        XCTAssertNil(s.earned(.hundert))
        XCTAssertTrue(win(s, deal(.klondike(1))).contains(.hundert))                   // 100. Sieg
    }

    func testKetteZehn() {
        let s = StatsStore(url: nil)
        s.handle(.chain(deal(.tripeaks), 9))
        XCTAssertTrue(s.lastChainAchievements.isEmpty)
        XCTAssertNil(s.earned(.kette10))
        s.handle(.chain(deal(.tripeaks), 10))                                              // sofort, auch ohne Sieg
        XCTAssertEqual(s.lastChainAchievements, [.kette10])
        s.handle(.chain(deal(.tripeaks), 11))
        XCTAssertTrue(s.lastChainAchievements.isEmpty)                                    // nicht doppelt
    }

    func testKroneUndGoldpokal() {
        let ev = Achievements.newAchievements(.crown, data: StatsData(), earned: [])
        XCTAssertEqual(ev, [.krone])
        XCTAssertEqual(Achievements.newAchievements(.cup(.gold), data: StatsData(), earned: []), [.goldpokal])
        XCTAssertEqual(Achievements.newAchievements(.cup(.silver), data: StatsData(), earned: []), [])
        XCTAssertEqual(Achievements.newAchievements(.crown, data: StatsData(), earned: ["krone"]), [])
    }

    // MARK: Verhalten

    func testKeinDoppeltesVergeben() {
        let s = StatsStore(url: nil)
        XCTAssertEqual(win(s, deal(.klondike(1)), undo: false, hint: false).count, 3)      // ersterSieg, ohneZurueck, ohneTipp
        XCTAssertEqual(win(s, deal(.klondike(1)), undo: false, hint: false), [])
        let datum = s.earned(.ersterSieg)
        win(s, deal(.klondike(1)))
        XCTAssertEqual(s.earned(.ersterSieg), datum)                                       // Datum bleibt das erste
    }

    func testAufgebenZaehltNie() {
        let s = StatsStore(url: nil)
        let d = deal(.klondike(1))
        s.handle(.started(d))
        s.handle(.abandoned(d))
        XCTAssertEqual(s.earnedCount, 0)
        XCTAssertTrue(s.lastAchievements.isEmpty)
    }

    func testKroneImTagesspielBringtAbzeichen() {
        // Tagesspiel Klondike gewinnen und Ziel erreichen: Krone → Abzeichen „Gekrönt“
        let s = StatsStore(url: nil)
        var cal = Calendar.current
        cal.timeZone = .current
        // ein Tag, dessen Ziel „gewinnen“ ist
        for tag in 1...28 {
            let date = cal.date(from: DateComponents(year: 2026, month: 3, day: tag))!
            guard DailyGoalCalc.goal(kind: .klondike, date: date) == .win else { continue }
            let seed = k.dailySeed(for: date, kind: .klondike)!
            let d = DealInfo(seed: seed, mode: .klondike(1), kind: .daily, day: DailyDate.string(date))
            s.handle(.started(d))
            s.handle(.won(d, moves: 100, score: 0, seconds: 100, undoUsed: false, hintUsed: false))
            XCTAssertTrue(s.lastAchievements.contains(.krone))
            return
        }
        XCTFail("kein Tag mit Ziel „gewinnen“ gefunden")
    }

    // MARK: Nachholen, Speichern

    func testNachholenAusDerStatistik() {
        var data = StatsData()
        var a = ModeStats(); a.won = 12; a.bestStreak = 6
        var b = ModeStats(); b.won = 1
        data.modes["klondike3"] = a
        data.modes["spider4"] = b
        data.daily["klondike"] = { var r = DailyRecord(); r.crowned = ["2026-10-01"]; return r }()
        let url = FileManager.default.temporaryDirectory.appending(path: "nachholen-\(UUID().uuidString).json")
        try? JSONEncoder().encode(data).write(to: url)
        let s = StatsStore(url: url)
        for id in [Achievement.ersterSieg, .dreiKarten, .spinne4, .serie5, .krone] { XCTAssertNotNil(s.earned(id), id.rawValue) }
        for id in [Achievement.serie10, .hundert, .alleFuenf, .ohneZurueck, .blitz, .kette10, .goldpokal] { XCTAssertNil(s.earned(id), id.rawValue) }
        XCTAssertTrue(s.lastAchievements.isEmpty)                                          // still, ohne Hinweis
        // gespeichert und beim nächsten Start wieder da
        let s2 = StatsStore(url: url)
        XCTAssertEqual(s2.earnedCount, s.earnedCount)
    }

    func testAltesFormatOhneErfolgeLaedtLeer() throws {
        let json = #"{"version":2,"modes":{},"daily":{}}"#
        let d = try JSONDecoder().decode(StatsData.self, from: Data(json.utf8))
        XCTAssertTrue(d.achievements.isEmpty)
    }

    func testAlle15HabenTextUndSymbol() {
        XCTAssertEqual(Achievement.allCases.count, 15)
        for a in Achievement.allCases {
            XCTAssertFalse(a.title.isEmpty); XCTAssertFalse(a.condition.isEmpty)
            XCTAssertNotNil(UIImage(systemName: a.symbol), a.symbol)
        }
    }
}
