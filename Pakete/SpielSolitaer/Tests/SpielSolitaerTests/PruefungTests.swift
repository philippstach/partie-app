// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// Prüfrunde vor dem Store: Funde aus Doku/PRUEFUNG-CODE.md (Nummern in den Testnamen)
@MainActor
final class PruefungTests: XCTestCase {
    private func prefs() -> AppPreferences { AppPreferences(defaults: UserDefaults(suiteName: UUID().uuidString)!) }
    private func folder() -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "pruefung-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private func defects(in folder: URL, prefix: String) -> [URL] {
        ((try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []).filter { $0.lastPathComponent.hasPrefix(prefix + "-defekt-") }
    }

    // MARK: 1 – unlesbare Statistik wird gesichert, nicht überschrieben

    func test01UnlesbareStatistikWirdGesichert() throws {
        let dir = folder(), url = dir.appending(path: "statistik.json")
        let garbage = Data("{ das ist keine Statistik".utf8)
        try garbage.write(to: url)
        let stats = StatsStore(url: url)
        let backups = defects(in: dir, prefix: "statistik")
        XCTAssertEqual(backups.count, 1, "Kopie der unlesbaren Datei")
        XCTAssertEqual(try Data(contentsOf: backups[0]), garbage)
        // Der nächste Zug überschreibt statistik.json, die Kopie bleibt
        let deal = DealInfo(seed: 1, mode: .klondike(1), kind: .solvable)
        stats.handle(.started(deal))
        stats.handle(.won(deal, moves: 100, score: 100, seconds: 90))
        XCTAssertNotEqual(try Data(contentsOf: url), garbage)
        XCTAssertEqual(try Data(contentsOf: backups[0]), garbage)
        // Eine gesunde Datei erzeugt keine Kopie
        let again = StatsStore(url: url)
        XCTAssertEqual(again.stats(mode: .klondike(1)).won, 1)
        XCTAssertEqual(defects(in: dir, prefix: "statistik").count, 1)
    }

    func test01FehlendeStatistikErzeugtKeineKopie() {
        let dir = folder()
        _ = StatsStore(url: dir.appending(path: "statistik.json"))
        XCTAssertTrue(defects(in: dir, prefix: "statistik").isEmpty)
    }

    // MARK: 2 – unlesbarer Spielstand wird gesichert

    func test02UnlesbarerSpielstandWirdGesichert() throws {
        let dir = folder(), url = dir.appending(path: "spiel-klondike1.json")
        let garbage = Data(#"{"version": 1, "state": {"cols": [{"down": [999]}]}}"#.utf8)       // Kartennummer 999: beschädigt
        try garbage.write(to: url)
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), url: url)
        let backups = defects(in: dir, prefix: "spiel-klondike1")
        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(try Data(contentsOf: backups[0]), garbage)
        XCTAssertEqual(store.state.moves, 0, "neu ausgeteilt")
    }

    func test02GesunderSpielstandErzeugtKeineKopie() async throws {
        let dir = folder(), url = dir.appending(path: "spiel-klondike1.json")
        let a = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 5, url: url)
        a.drawStock()
        await a.settleSaves()
        let b = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), url: url)
        XCTAssertEqual(b.state, a.state)
        XCTAssertTrue(defects(in: dir, prefix: "spiel-klondike1").isEmpty)
    }

    // MARK: 5 – nach dem Aufgeben läuft die Uhr nicht weiter, Lösung ansehen speichert nicht

    func test05UhrNachAufgebenUndLoesungAnsehen() async throws {
        let dir = folder(), url = dir.appending(path: "spiel-klondike1.json")
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: url)
        store.start(DealInfo(seed: DealCatalog.shared.seeds(draw: 1)[0], mode: .klondike(1), kind: .solvable))
        store.drawStock()
        XCTAssertNotNil(store.runningSince)
        store.giveUp()
        XCTAssertNil(store.runningSince)
        store.resumeClock()                                            // Menü zu / App zurück
        XCTAssertNil(store.runningSince, "Uhr bleibt nach dem Aufgeben aus")
        await store.settleSaves()
        let saved = try Data(contentsOf: url)
        store.viewSolution()
        XCTAssertTrue(store.replaying)
        store.solutionStep(1); store.solutionStep(1); store.solutionStep(1)
        store.pauseClock(); store.resumeClock()
        XCTAssertNil(store.runningSince, "Uhr bleibt beim Ansehen der Lösung aus")
        await store.settleSaves()
        XCTAssertEqual(try Data(contentsOf: url), saved, "Zwischenstand der Lösung wird nicht als Spielstand gespeichert")
    }

    // MARK: 9 – gregorianischer Kalender, auch bei buddhistischem Gerätekalender

    func test09GregorianischerKalenderUndTagesspiel() {
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = .current
        let date = Calendar.solitaer.date(from: DateComponents(year: 2026, month: 10, day: 11))!
        // Ohne den zentralen Kalender käme „2569-10-11“
        XCTAssertEqual(DailyDate.string(date, calendar: buddhist), "2569-10-11")
        XCTAssertEqual(DailyDate.string(date), "2026-10-11")
        XCTAssertEqual(DailyDate.date("2026-10-11").map { Calendar.solitaer.component(.year, from: $0) }, 2026)
        // Tagesspiel und Wochenziel hängen am Datum: gleiche Partie wie im Regeltest
        let k = DealCatalog.shared
        XCTAssertEqual(k.dailySeed(for: date), k.dailySeed(daysSinceEpoch: DealCatalog.daysSinceEpoch(year: 2026, month: 10, day: 11, calendar: .solitaer)))
        XCTAssertEqual(WeeklyGoals.mondayString(of: date), "2026-10-05")
        XCTAssertEqual(Calendar.solitaer.firstWeekday, 2)
    }

    // MARK: 10 – nur die erste Krone eines Tages zählt

    func test10ZweiteKroneDesselbenTagesZaehltNicht() throws {
        let stats = StatsStore(url: nil)
        let kind = GameKind.klondike
        let day = DailyDate.string(Date())
        // Ein Tag, dessen Ziel „gewinnen“ ist, finden (Ziel hängt vom Datum ab)
        var target: String?
        var date = Date()
        for i in 0..<60 {
            let d = Calendar.solitaer.date(byAdding: .day, value: -i, to: date)!
            if let goal = DailyGoalCalc.goal(kind: kind, date: d), goal == .win { target = DailyDate.string(d); date = d; break }
        }
        let tag = try XCTUnwrap(target, "Tag mit Ziel „gewinnen“")
        _ = day
        let seed = DealCatalog.shared.dailySeed(for: date, kind: kind)!
        let deal = DealInfo(seed: seed, mode: .klondike(1), kind: .daily, day: tag)
        stats.handle(.started(deal))
        stats.handle(.won(deal, moves: 100, score: 100, seconds: 90))
        XCTAssertEqual(stats.crownCount(kind), 1)
        XCTAssertTrue(stats.lastAchievements.contains(.krone))
        let weeklyBefore = stats.data.weekly.crowns
        stats.handle(.started(deal))
        stats.handle(.won(deal, moves: 100, score: 100, seconds: 90))
        XCTAssertEqual(stats.crownCount(kind), 1, "derselbe Tag nur einmal gekrönt")
        XCTAssertFalse(stats.lastAchievements.contains(.krone), "kein zweites Krone-Abzeichen")
        XCTAssertEqual(stats.data.weekly.crowns, weeklyBefore, "Wochenziel „Kronen“ zählt nicht doppelt")
        XCTAssertTrue(stats.lastDaily?.crowned == true, "die Gewonnen-Karte zeigt weiter „Krone!“")
    }

    // MARK: 6 – Uhr bleibt bei offenem Blatt aus (Logik am Store; die Ansicht ruft resumeClock nur ohne Blatt)

    func test06UhrIstNachPauseAus() {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        store.drawStock()
        store.pauseClock()
        XCTAssertNil(store.runningSince)
    }

    // MARK: 8 – Spielzeit ist unabhängig von der Geräteuhr

    func test08SpielzeitNutztBetriebszeit() async throws {
        let store = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(), seed: 1, url: nil)
        store.drawStock()
        try await Task.sleep(for: .milliseconds(300))
        let a = store.elapsed(at: Date())
        let farFuture = store.elapsed(at: Date().addingTimeInterval(86_400 * 365))          // „Geräteuhr umgestellt“
        let farPast = store.elapsed(at: Date().addingTimeInterval(-86_400 * 365))
        XCTAssertEqual(farFuture, a, accuracy: 0.2)
        XCTAssertEqual(farPast, a, accuracy: 0.2)
        XCTAssertGreaterThanOrEqual(a, 0.25)
    }

    // MARK: 11 – „Weiterspielen“ ohne Stores anzulegen und ohne Lesen im Zeichnen

    func test11RunningKeysLegtNichtsAnUndLiestDateien() async throws {
        let dir = folder()
        let app = AppModel(prefs: prefs(), stats: StatsStore(url: nil), folder: dir, seed: nil)
        let before = app.session.mode
        XCTAssertFalse(app.isRunning(.golf), "kein Store angelegt, nichts gelesen")
        XCTAssertEqual(app.session.mode, before)
        // eine gespeicherte, angefangene Golf-Partie auf der Platte
        let golf = GameStore<GolfRules>(mode: .golf, prefs: prefs(), seed: 1, url: AppModel.url(in: dir, mode: .golf))
        golf.start(DealInfo(seed: DealCatalog.shared.seeds(for: .golf)[0], mode: .golf, kind: .solvable))
        _ = golf.perform(GolfRules.hint(golf.state) ?? .draw)
        await golf.settleSaves()
        let keys = await app.runningKeys(for: [.golf, .yukon, .klondike(1)])
        XCTAssertTrue(keys.contains("golf"))
        XCTAssertFalse(keys.contains("yukon"))
    }

    // MARK: 12 – großes Foto wird beim Lesen verkleinert

    func test12GrossesFotoWirdBeimLesenVerkleinert() throws {
        let format = UIGraphicsImageRendererFormat.default(); format.scale = 1
        let big = UIGraphicsImageRenderer(size: CGSize(width: 6000, height: 4000), format: format).image { ctx in
            UIColor.orange.setFill(); ctx.fill(CGRect(x: 0, y: 0, width: 6000, height: 4000))
        }
        let jpeg = try XCTUnwrap(big.jpegData(compressionQuality: 0.7))
        let out = try XCTUnwrap(UIImage(data: try XCTUnwrap(PhotoTable.process(jpeg))))
        XCTAssertLessThanOrEqual(max(out.size.width, out.size.height), 1600)
        XCTAssertEqual(out.size.width / out.size.height, 1.5, accuracy: 0.01)
    }

    // MARK: 15 – Wasserfall rechnet nach langem Hintergrund nicht alles nach

    func test15WasserfallRechnetNichtAllesNach() {
        let cards = (0..<52).map { (face: CardFace(rank: $0 % 13 + 1, suit: Suit(rawValue: $0 / 13)!), origin: CGPoint(x: 100, y: 100)) }
        let sim = WaterfallSim(cards: cards, cardSize: CGSize(width: 50, height: 70), bounds: CGSize(width: 400, height: 600))
        // Das Bild fragt höchstens 0,5 s nach der aktuellen Zeit (siehe WaterfallView)
        sim.advance(to: min(10_000, sim.time + 0.5))
        XCTAssertLessThanOrEqual(sim.time, 0.51)
    }

    // MARK: 7 – bricht das System ein Ziehen ab, löst `end()` die Drehsperre

    func test07ZiehenEndeLoestDrehsperre() {
        OrientationLock.lock()
        XCTAssertNotEqual(OrientationLock.mask, OrientationLock.unlocked, "gesperrt")
        let drag = DragModel()
        drag.place = .column(0)
        drag.end()                                   // wie bei Anruf, Kontrollzentrum, Hintergrund (TableView ruft es dann auf)
        XCTAssertEqual(OrientationLock.mask, OrientationLock.unlocked, "Sperre gelöst")
        XCTAssertNil(drag.place)
    }

    // MARK: Tipp leer, Spiel nicht festgefahren → „Kein Tipp gefunden“ (nie „Keine Züge mehr“)

    private func leererTippOhneFestgefahren<R: SolitaireRules>(_ rules: R.Type, _ mode: GameMode) -> R.State? {
        for seed in UInt64(1)...300 {
            var s = R.deal(seed: seed, mode: mode)
            for _ in 0..<400 {
                guard let m = R.hint(s), let n = R.apply(s, m) else { break }
                s = n
                for a in R.autoMoves(s, autoFoundation: true) { if let n2 = R.apply(s, a) { s = n2 } }
            }
            if !s.isWon, R.hint(s) == nil, !R.isStuck(s) { return s }
        }
        return nil
    }

    func testLeererTippOhneFestgefahrenZeigtKeinTippGefunden() throws {
        var found = 0
        func check<R: SolitaireRules>(_ rules: R.Type, _ mode: GameMode) {
            guard let s = leererTippOhneFestgefahren(rules, mode) else { return }
            found += 1
            let store = GameStore<R>(mode: mode, prefs: prefs(), seed: 1, url: nil)
            store.load(state: s)
            XCTAssertFalse(store.stuck, "\(mode.key): nicht festgefahren, also keine Leiste „Keine sinnvollen Züge mehr“")
            store.showHint()
            XCTAssertEqual(store.toast?.text, String(localized: "Kein Tipp gefunden"), mode.key)
            XCTAssertNil(store.hint)
        }
        check(FreeCellRules.self, .freecell)
        check(YukonRules.self, .yukon)
        check(KlondikeRules.self, .klondike(1))
        check(SpiderRules.self, .spider(2))
        try XCTSkipIf(found == 0, "kein Beispielzustand gefunden (Tipp leer, aber nicht festgefahren)")
        XCTAssertGreaterThan(found, 0)
    }

    /// Spider-Tipp pendelt nicht mehr: 60 Tipp-Partien, kein Zustand kehrt wieder
    func testSpiderTippPendeltNicht() {
        var loops = 0
        for seed in UInt64(1)...60 {
            var s = SpiderRules.deal(seed: seed, mode: .spider(2))
            var seen: Set<SpiderState> = [s]
            for _ in 0..<600 {
                guard let m = SpiderRules.hint(s), let n = SpiderRules.apply(s, m) else { break }
                s = n
                for a in SpiderRules.autoMoves(s, autoFoundation: true) { if let n2 = SpiderRules.apply(s, a) { s = n2 } }
                var key = s; key.moves = 0; key.score = 0
                if !seen.insert(key).inserted { loops += 1; break }
            }
        }
        XCTAssertEqual(loops, 0, "Partien, in denen der Tipp im Kreis lief")
    }
}
