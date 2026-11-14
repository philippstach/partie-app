// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import Darwin
@testable import SpielSolitaer

/// Doku/FUNKTIONSTEST.md: Zeilen, die sich ohne Bedienung prüfen lassen (Nummern in den Testnamen)
@MainActor
final class FunktionstestTests: XCTestCase {
    private func prefs() -> AppPreferences { AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!) }

    private static let modes: [GameMode] = [.klondike(1), .klondike(3), .spider(1), .spider(2), .spider(4), .freecell, .pyramid, .tripeaks, .golf, .yukon]

    // MARK: 1.12 Rückgängig: alles zurück bis zum Anfang, Zustand exakt wie vorher

    private func undoRoundtrip<R: SolitaireRules>(_ rules: R.Type, _ mode: GameMode) async {
        let store = GameStore<R>(mode: mode, prefs: prefs(), seed: 7, url: nil)
        let start = store.state
        var played = 0
        while played < 60, let m = R.hint(store.state), store.perform(m) {
            played += 1
            store.flush()
            if store.state.isWon { break }
        }
        XCTAssertGreaterThan(played, 5, "\(mode.key): es wurde gespielt")
        var steps = 0
        while store.canUndo, steps < 1000 { store.undo(); steps += 1 }
        XCTAssertEqual(store.state, start, "\(mode.key): nach \(steps) Rückgängig-Schritten wie am Anfang (Punkte, Zähler, Kette, Durchgänge)")
        XCTAssertFalse(store.canUndo, mode.key)
    }

    func test112RueckgaengigBisZumAnfangAlleModi() async {
        await undoRoundtrip(KlondikeRules.self, .klondike(1))
        await undoRoundtrip(KlondikeRules.self, .klondike(3))
        await undoRoundtrip(SpiderRules.self, .spider(1))
        await undoRoundtrip(SpiderRules.self, .spider(2))
        await undoRoundtrip(SpiderRules.self, .spider(4))
        await undoRoundtrip(FreeCellRules.self, .freecell)
        await undoRoundtrip(PyramidRules.self, .pyramid)
        await undoRoundtrip(TriPeaksRules.self, .tripeaks)
        await undoRoundtrip(GolfRules.self, .golf)
        await undoRoundtrip(YukonRules.self, .yukon)
    }

    // MARK: 1.9 Auto-Ablegen aus: nichts automatisch

    func test19AutoAblegenAusLegtNichtsAutomatischAb() async throws {
        let p = prefs(); p.autoFoundation = false
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: p, seed: 1, url: nil)
        var s = GameState()
        s.cols[0] = Column(up: [CardID(rank: 2, suit: .spades), CardID(rank: 1, suit: .spades)])
        s.cols[1] = Column(up: [CardID(rank: 1, suit: .hearts)])
        store.load(state: s)
        XCTAssertTrue(store.perform(.move(from: .column(0), to: .foundation(0), count: 1)))
        try await Task.sleep(for: .milliseconds(500))
        XCTAssertEqual(store.state.foundation, [1, 0, 0, 0], "nur der Zug des Spielers, nichts automatisch")
        XCTAssertEqual(store.state.moves, 1)
    }

    // MARK: 1.10 Fertig spielen

    func test110FertigSpielenKlondikeUndYukon() async throws {
        func col(_ suit: Suit, down to: Int) -> Column { Column(up: (to...13).reversed().map { CardID(rank: $0, suit: suit) }) }   // K … to, oben die kleinste
        let k = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        k.load(state: GameState(foundation: [10, 10, 10, 10], cols: [col(.spades, down: 11), col(.hearts, down: 11), col(.diamonds, down: 11), col(.clubs, down: 11), Column(), Column(), Column()]))
        XCTAssertTrue(k.canFinish)
        k.autoFinish()
        for _ in 0..<60 where !k.state.isWon { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertTrue(k.state.isWon, "Fertig spielen endet gewonnen (Stand: \(k.state.foundation))")
        // Nicht angeboten, solange etwas verdeckt liegt
        k.load(state: GameState(cols: [Column(down: [CardID(rank: 5, suit: .clubs)], up: [CardID(rank: 1, suit: .spades)])]))
        XCTAssertFalse(k.canFinish)

        let y = GameStore<YukonRules>(mode: .yukon, prefs: prefs(), seed: 1, url: nil)
        y.load(state: YukonState(cols: [col(.spades, down: 1)], foundation: [0, 13, 13, 13]))
        XCTAssertTrue(y.canFinish)
        y.autoFinish()
        for _ in 0..<60 where !y.state.isWon { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertTrue(y.state.isWon, "Yukon: Fertig spielen endet gewonnen (Stand: \(y.state.foundation))")
        // Yukon: nicht allein mit obersten Karten aufs Ziel lösbar (QS auf JS, As darunter) → nicht angeboten
        y.load(state: YukonState(cols: [Column(up: [CardID(rank: 1, suit: .spades), CardID(rank: 12, suit: .spades), CardID(rank: 11, suit: .spades)])]))
        XCTAssertFalse(y.canFinish)
    }

    // MARK: 2.4 Statistik zurücksetzen: nur dieser Modus, Verlauf mit

    func test24StatistikZuruecksetzenNurDieserModus() {
        let stats = StatsStore(url: nil)
        let a = DealInfo(seed: 1, mode: .klondike(1), kind: .solvable), b = DealInfo(seed: 1, mode: .spider(2), kind: .solvable)
        for d in [a, b] { stats.handle(.started(d)); stats.handle(.won(d, moves: 80, score: 100, seconds: 120)) }
        XCTAssertEqual(stats.data.history.count, 2)
        stats.reset(mode: .klondike(1))
        XCTAssertEqual(stats.stats(mode: .klondike(1)).played, 0)
        XCTAssertEqual(stats.stats(mode: .spider(2)).won, 1, "anderer Modus bleibt")
        XCTAssertEqual(stats.data.history.map(\.mode), ["spider2"], "Verlauf dieses Modus mit weg")
    }

    // MARK: 3.2 Mitternacht bei offener App: die laufende Partie bleibt ihrem Tag zugeordnet

    func test32TagesspielBleibtDemAltenTagZugeordnet() throws {
        let stats = StatsStore(url: nil)
        let cal = Calendar.solitaer
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        let day = DailyDate.string(yesterday)
        let deal = DealInfo(seed: DealCatalog.shared.dailySeed(for: yesterday)!, mode: .klondike(1), kind: .daily, day: day)
        stats.handle(.started(deal))
        stats.handle(.won(deal, moves: 100, score: 100, seconds: 90))           // gewonnen „nach Mitternacht“
        XCTAssertTrue(stats.dailyWon(.klondike).contains(day))
        XCTAssertFalse(stats.dailyWon(.klondike).contains(DailyDate.string(Date())))
    }

    // MARK: 3.7 Sommerzeit-Wechsel (Ende Oktober): kein doppelter oder fehlender Tag

    func test37SommerzeitWechselKeinDoppelterTag() throws {
        var cal = Calendar.solitaer
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        var date = cal.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 12))!
        var days: [String] = [], numbers: [Int] = [], mondays: [String] = []
        for _ in 0..<14 {
            days.append(DailyDate.string(date, calendar: cal))
            let c = cal.dateComponents([.year, .month, .day], from: date)
            numbers.append(DealCatalog.daysSinceEpoch(year: c.year!, month: c.month!, day: c.day!, calendar: cal))
            mondays.append(WeeklyGoals.mondayString(of: date, calendar: cal))
            date = cal.date(byAdding: .day, value: 1, to: date)!
        }
        XCTAssertEqual(Set(days).count, 14, "kein doppelter Tag")
        XCTAssertEqual(zip(numbers, numbers.dropFirst()).map { $1 - $0 }, Array(repeating: 1, count: 13), "Tagesspiel-Platz zählt täglich genau eins")
        XCTAssertTrue(days.contains("2026-10-25") && days.contains("2026-10-26"))
        XCTAssertEqual(mondays.first, "2026-10-19")
        XCTAssertEqual(mondays[6], "2026-10-26", "Wochenwechsel Montag 26.10. trotz Zeitumstellung am Sonntag")
        // auch der Kalender der Geräteeinstellung „Berlin“ liefert dieselben Tage wie UTC-Rechnung
        XCTAssertEqual(DailyDate.date("2026-10-25", calendar: cal).map { cal.component(.hour, from: $0) }, 0)
    }

    // MARK: 4.7 Englisch komplett

    func test47EnglischIstVollstaendig() throws {
        let url = Bundle(for: PruefungTests.self).url(forResource: "Localizable", withExtension: "xcstrings")
            ?? Bundle.main.url(forResource: "Localizable", withExtension: "xcstrings")
        // xcstrings wird beim Bauen in .strings/.stringsdict übersetzt: darum die Quelldatei neben dem Test lesen
        let source = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appending(path: "Solitaer/Localizable.xcstrings")
        _ = url
        try XCTSkipUnless(FileManager.default.fileExists(atPath: source.path), "Texte liegen im gemeinsamen Partie-Katalog (App/Ressourcen); dort prüft der Texte-Test")
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: source)) as! [String: Any]
        let strings = json["strings"] as! [String: [String: Any]]
        XCTAssertGreaterThan(strings.count, 300)
        var missing: [String] = []
        for (key, entry) in strings {
            let loc = (entry["localizations"] as? [String: Any])?["en"] as? [String: Any]
            if loc == nil, entry["comment"] == nil { missing.append(key) }
        }
        XCTAssertEqual(missing.sorted(), [], "ohne englische Übersetzung (und ohne Vermerk, dass der Text gleich bleibt)")
    }

    // MARK: 5.1 Erster Start: erste Partie ist „Leicht“

    func test51ErsterStartErstePartieLeicht() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "erststart-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let p = prefs()
        XCTAssertFalse(p.welcomeSeen)
        let app = AppModel(prefs: p, stats: StatsStore(url: nil), folder: folder, seed: nil)
        let deal = app.session.deal
        XCTAssertEqual(deal.kind, .solvable)
        XCTAssertEqual(DealCatalog.shared.level(mode: deal.mode, seed: deal.seed), 1, "erste Partie Leicht")
        XCTAssertEqual(app.session.moves, 0)
    }

    // MARK: 5.4 / 5.5 Adressen, kein Netz

    // MARK: 5.6 Leistung: Spider 4 Farben, viele Partien – kein Speicherwachstum

    private func footprint() -> Double {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let r = withUnsafeMutablePointer(to: &info) { $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count) } }
        return r == KERN_SUCCESS ? Double(info.phys_footprint) / 1_048_576 : 0
    }

    func test56SpeicherWaechstNichtUeberPartienHinweg() {
        let store = GameStore<SpiderRules>(mode: .spider(4), prefs: prefs(), seed: 3, url: nil)
        func playGame(_ seed: UInt64) {
            store.start(DealInfo(seed: seed, mode: .spider(4), kind: .random))
            for _ in 0..<120 {
                guard let m = SpiderRules.hint(store.state), store.perform(m) else { break }
                store.flush()
            }
        }
        for i in 1...8 { playGame(UInt64(i)) }                 // einlaufen lassen
        let before = footprint()
        let t0 = Date()
        for i in 9...48 { playGame(UInt64(i)) }
        let seconds = Date().timeIntervalSince(t0)
        let growth = footprint() - before
        XCTAssertLessThan(growth, 40, "Speicher wächst über 40 Partien um \(Int(growth)) MB")
        XCTAssertLessThan(seconds, 60, "40 Partien mit je bis zu 120 Zügen in \(Int(seconds)) s")
    }
}
