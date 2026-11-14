// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielGalgenmaennchen

// MARK: tageswort.json

struct TageswortRegelTests {
    struct Datei: Decodable {
        struct Wort: Decodable { let sprache: String; let tag: String; let loesung: String }
        struct Ereignis: Decodable { let tag: String; let gewonnen: Bool }
        struct Erwartet: Decodable {
            let gespielt: Int; let gewonnen: Int; let serie: Int; let besteSerie: Int
            let letzterSieg: String; let letzterTag: String
        }
        struct Statistik: Decodable {
            let name: String; let ereignisse: [Ereignis]; let heute: String
            let erwartet: Erwartet; let serieAnzeige: Int
        }
        struct Teilen: Decodable {
            let tag: String; let fehler: Int; let hinweise: Int; let gewonnen: Bool
            let appSprache: String; let text: String
        }
        let maxStufe: Int
        let listenVersion: Int
        let woerter: [Wort]
        let statistik: [Statistik]
        let teilen: [Teilen]
    }

    @Test func woerterJeDatumUndSprache() throws {
        let datei: Datei = try Fixtures.load("tageswort")
        #expect(datei.maxStufe == DailyWord.maxDifficulty)
        #expect(datei.woerter.count >= 10)
        for w in datei.woerter {
            let list = try WordList.load(WordLanguage(rawValue: w.sprache)!)
            #expect(datei.listenVersion == list.version, "Listenversion \(w.sprache)")
            #expect(DailyWord.word(day: w.tag, in: list.words)?.solution == w.loesung, "\(w.sprache) \(w.tag)")
        }
    }

    @Test func statistikUndAngezeigteSerie() throws {
        let datei: Datei = try Fixtures.load("tageswort")
        #expect(datei.statistik.count >= 6)
        for f in datei.statistik {
            var stats = DailyStats()
            for e in f.ereignisse { stats.record(won: e.gewonnen, day: e.tag) }
            #expect(stats.played == f.erwartet.gespielt, "\(f.name): gespielt")
            #expect(stats.won == f.erwartet.gewonnen, "\(f.name): gewonnen")
            #expect(stats.streak == f.erwartet.serie, "\(f.name): Serie")
            #expect(stats.bestStreak == f.erwartet.besteSerie, "\(f.name): beste Serie")
            #expect(stats.lastWin == f.erwartet.letzterSieg, "\(f.name): letzter Sieg")
            #expect(stats.lastDay == f.erwartet.letzterTag, "\(f.name): letzter Tag")
            #expect(stats.displayedStreak(today: f.heute) == f.serieAnzeige, "\(f.name): angezeigte Serie")
        }
    }

    @Test func teilenTextExakt() throws {
        let datei: Datei = try Fixtures.load("tageswort")
        #expect(datei.teilen.count >= 8)
        for t in datei.teilen {
            let text = DailyShare.text(day: t.tag, mistakes: t.fehler, hints: t.hinweise, won: t.gewonnen,
                                       appLanguage: WordLanguage(rawValue: t.appSprache)!)
            #expect(text == t.text, "\(t.appSprache) \(t.fehler) Fehler, \(t.hinweise) Hinweise")
        }
    }
}

// MARK: Tage

struct DayKeyTests {
    @Test func gesternUeberMonatsJahresUndSchaltgrenze() {
        #expect(DayKey.previous("2026-10-05") == "2026-10-04")
        #expect(DayKey.previous("2026-10-01") == "2026-09-30")
        #expect(DayKey.previous("2027-01-01") == "2026-12-31")
        #expect(DayKey.previous("2028-03-01") == "2028-02-29")
        #expect(DayKey.previous("2027-03-01") == "2027-02-28")
    }

    @Test func seedIstDasDatumAlsZahl() {
        #expect(DayKey.seed("2026-10-04") == 20261004)
        #expect(DayKey.seed("2028-02-29") == 20280229)
    }

    @Test func tagsschluesselInOrtszeit() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        // 23:30 Uhr in Berlin ist noch derselbe Tag, auch wenn es in UTC schon später ist
        let late = cal.date(from: DateComponents(year: 2026, month: 10, day: 4, hour: 23, minute: 30))!
        #expect(DayKey.string(for: late, calendar: cal) == "2026-10-04")
        let early = cal.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 0, minute: 10))!
        #expect(DayKey.string(for: early, calendar: cal) == "2026-10-05")
    }
}

// MARK: Store

@MainActor
struct TageswortStoreTests {
    final class Clock { var date: Date; init(_ date: Date) { self.date = date } }

    private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: 12))!
    }

    private func url() -> URL { FileManager.default.temporaryDirectory.appending(path: "galgen-daily-\(UUID()).json") }

    private func makeStore(url: URL, clock: Clock, language: WordLanguage = .de) -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        prefs.wordLanguage = language
        var seed: UInt64 = 1
        return GameStore(repository: GameRepository(url: url), preferences: prefs,
                         seedSource: { defer { seed += 1 }; return seed }, clock: { clock.date })
    }

    private func win(_ store: GameStore) {
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
    }

    @Test func tageswortLaeuftNebenDemEinzelspielUndUeberlebtNeustart() throws {
        let file = url(), clock = Clock(day(2026, 10, 4))
        let store = makeStore(url: file, clock: clock)
        store.startGame(category: nil, difficulty: nil)
        let single = try #require(store.game)
        store.guess(String(single.solution.first!))
        store.goHome()

        store.openDaily()
        #expect(store.playingDaily)
        let daily = try #require(store.game)
        #expect(daily.mode == .daily)
        #expect(daily.solution != single.solution || true)
        store.guess(String(daily.solution.first!))
        store.goHome()
        #expect(!store.playingDaily)
        #expect(store.runningGame?.solution == single.solution)     // das Einzelspiel läuft unverändert weiter

        let reloaded = makeStore(url: file, clock: clock)
        #expect(reloaded.runningGame?.solution == single.solution)
        #expect(reloaded.dailyToday?.game.solution == daily.solution)
        #expect(reloaded.dailyToday?.game.guessed.count == 1)
    }

    @Test(.enabled(if: nurAufDemTelefon)) func tageswortSiegZaehltInTagesStatistikNichtInDerNormalen() {
        let clock = Clock(day(2026, 10, 4))
        let store = makeStore(url: url(), clock: clock)
        store.openDaily()
        win(store)
        #expect(store.game?.status == .won)
        #expect(store.dailyStats.played == 1 && store.dailyStats.won == 1 && store.dailyStats.streak == 1)
        #expect(store.stats.played == 0 && store.stats.won == 0)
        #expect(store.dailyStreak == 1)
        #expect(store.dailyShareText()?.contains("Wort des Tages 04.10.2026") == true)
    }

    @Test func einVersuchProTagUndGesternGiltAlsNichtGespielt() throws {
        let clock = Clock(day(2026, 10, 4))
        let store = makeStore(url: url(), clock: clock)
        store.openDaily()
        let first = try #require(store.game).solution
        win(store)
        store.goHome()

        store.openDaily()                                  // dasselbe beendete Spiel, kein neuer Versuch
        #expect(store.game?.solution == first)
        #expect(store.game?.status == .won)
        #expect(store.dailyStats.played == 1)
        store.goHome()

        clock.date = day(2026, 10, 5)                      // nächster Tag
        store.refreshToday()
        #expect(store.dailyToday == nil)                   // „noch nicht gespielt“
        store.openDaily()
        #expect(store.game?.status == .playing)
        #expect(store.game?.guessed.isEmpty == true)
        win(store)
        #expect(store.dailyStats.streak == 2)

        clock.date = day(2026, 10, 8)                      // zwei Tage verpasst: angezeigte Serie 0
        store.refreshToday()
        #expect(store.dailyStreak == 0)
    }

    @Test(.enabled(if: nurAufDemTelefon)) func tageswortNachFehlerUndHinweisImTeilenText() throws {
        let clock = Clock(day(2026, 10, 4))
        let store = makeStore(url: url(), clock: clock)
        store.openDaily()
        #expect(store.dailyShareText() == nil)             // solange es läuft, gibt es nichts zu teilen
        while store.game?.status == .playing {
            let g = store.game!
            store.guess(String(g.language.alphabet.first { !g.solution.contains($0) && !g.guessed.contains($0) }!))
        }
        #expect(store.game?.status == .lost)
        #expect(store.dailyStats.played == 1 && store.dailyStats.won == 0 && store.dailyStats.streak == 0)
        let text = try #require(store.dailyShareText())
        #expect(text.hasSuffix("💥💥💥💥💥💥💥💥\nNicht erraten"))
        #expect(!text.contains(store.game!.solution))      // das Wort selbst wird nie geteilt
    }

    @Test func aeltererSpielstandOhneTageswortLaedt() throws {
        let file = url()
        try Data(#"{"version":1,"stats":{"played":3,"won":2}}"#.utf8).write(to: file)
        let store = makeStore(url: file, clock: Clock(day(2026, 10, 4)))
        #expect(store.stats.played == 3)
        #expect(store.dailyToday == nil)
        #expect(store.dailyStats == DailyStats())
    }
}

// MARK: sammlung.json

struct SammlungRegelTests {
    struct Datei: Decodable {
        struct Stand: Decodable { let erraten: Int; let gesamt: Int }
        let sprache: String
        let siege: [String]
        let gesammelt: [String]
        let fortschritt: [String: Stand]
    }

    @Test func siegeSammelnOhneDoppelteUndFortschrittJeKategorie() throws {
        let datei: Datei = try Fixtures.load("sammlung")
        let list = try WordList.load(WordLanguage(rawValue: datei.sprache)!)
        var collected: [String] = []
        for sieg in datei.siege { WordCollection.add(sieg, to: &collected) }
        #expect(collected == datei.gesammelt)
        let progress = WordCollection.progress(of: collected, in: list)
        #expect(datei.fortschritt.count == Category.allCases.count)
        for (id, stand) in datei.fortschritt {
            let category = try #require(Category(rawValue: id))
            #expect(progress[category]?.found == stand.erraten, "\(id): erraten")
            #expect(progress[category]?.total == stand.gesamt, "\(id): gesamt")
        }
    }
}

@MainActor
struct SammlungStoreTests {
    private func url() -> URL { FileManager.default.temporaryDirectory.appending(path: "galgen-coll-\(UUID()).json") }

    private func makeStore(url: URL, language: WordLanguage = .de) -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "test-\(UUID())")!)
        prefs.wordLanguage = language
        var seed: UInt64 = 1
        return GameStore(repository: GameRepository(url: url), preferences: prefs, seedSource: { defer { seed += 1 }; return seed })
    }

    private func win(_ store: GameStore) {
        for c in store.game!.solution where c != " " && c != "-" { store.guess(String(c)) }
    }

    @Test func einzelspielSiegKommtInDieSammlungNichtBeiNiederlageOderParty() throws {
        let store = makeStore(url: url())
        store.startGame(category: nil, difficulty: nil)
        let solution = try #require(store.game).solution
        win(store)
        #expect(store.collected(for: .de) == [solution])
        #expect(store.collected(for: .en).isEmpty)

        store.startParty(names: ["Anna", "Ben"], settings: PartySettings())
        store.partyContinue()                                    // Wortgeber
        store.submitPartyWord(solution: "SCHNEE", hintText: nil)
        store.partyContinue()                                    // Rater
        win(store)
        #expect(store.collected(for: .de) == [solution])      // Party-Runden sammeln nicht

        store.goHome()
        store.startGame(category: nil, difficulty: nil)
        while store.game?.status == .playing {
            let g = store.game!
            store.guess(String(g.language.alphabet.first { !g.solution.contains($0) && !g.guessed.contains($0) }!))
        }
        #expect(store.collected(for: .de) == [solution])      // Niederlage sammelt nicht
    }

    @Test func tageswortSiegKommtInDieSammlung() throws {
        let store = makeStore(url: url())
        store.openDaily()
        let solution = try #require(store.game).solution
        win(store)
        #expect(store.collected(for: .de) == [solution])
    }

    @Test func volleKategorieWirdEinmaligGefeiert() throws {
        // Spielstand: alle Tiere außer einem schon gesammelt, das letzte Tier läuft gerade
        let list = try WordList.load(.de)
        let animals = list.words.filter { $0.category == .animals }
        let last = try #require(animals.last)
        var data = SaveData()
        data.collection["de"] = animals.dropLast().map(\.solution)
        data.game = Game(solution: last.solution, language: .de, category: .animals, difficulty: last.difficulty,
                         displayText: last.text)
        let file = url()
        try GameRepository(url: file).save(data)

        let store = makeStore(url: file)
        #expect(store.pendingCelebration == nil)
        #expect(store.progress(for: .de)[.animals]?.isComplete == false)
        win(store)
        #expect(store.progress(for: .de)[.animals]?.isComplete == true)
        #expect(store.pendingCelebration == .animals)
        store.celebrationShown()
        #expect(store.pendingCelebration == nil)

        // nach einem Neustart und weiteren Siegen wird dieselbe Kategorie nicht noch einmal gefeiert
        let reloaded = makeStore(url: file)
        reloaded.startGame(category: .animals, difficulty: nil)
        #expect(reloaded.pendingCelebration == nil)
        #expect(reloaded.progress(for: .de)[.animals]?.isComplete == true)
        #expect(try #require(GameRepository(url: file).load().celebrated["de"]) == ["animals"])
    }

    @Test func aeltererSpielstandOhneSammlungLaedt() throws {
        let file = url()
        try Data(#"{"version":1}"#.utf8).write(to: file)
        let store = makeStore(url: file)
        #expect(store.collected(for: .de).isEmpty)
        #expect(store.progress(for: .de)[.animals]?.found == 0)
    }
}
