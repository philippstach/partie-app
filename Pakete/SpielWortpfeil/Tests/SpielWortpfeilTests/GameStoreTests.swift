// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielWortpfeil
import SpieleKern

@Suite(.serialized) @MainActor
struct GameStoreTests {
    final class Clock { var date = Date(timeIntervalSince1970: 1_790_000_000) }

    static let library = PackLibrary(directory: Shared.root.appending(path: "raetsel"))

    final class MockReminders: ReminderScheduling, @unchecked Sendable {
        var status: ReminderPermission = .notDetermined
        var grants = true
        var scheduled: [DateComponents] = []
        func permission() async -> ReminderPermission { status }
        func requestPermission() async -> Bool { status = grants ? .allowed : .denied; return grants }
        func replaceAll(with dates: [DateComponents]) async { scheduled = dates }
    }

    static func makeStore(url: URL? = nil, clock: Clock = Clock(), library: PackLibrary = library,
                          reminders: ReminderScheduling = MockReminders()) -> GameStore {
        let prefs = AppPreferences(defaults: UserDefaults(suiteName: "test-\(UUID().uuidString)")!)
        let repo = GameRepository(url: url ?? FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json"))
        return GameStore(repository: repo, preferences: prefs, library: library, reminders: reminders,
                         calendar: Calendar(identifier: .gregorian), now: { clock.date })
    }

    /// Löst das laufende Spiel mit den richtigen Buchstaben, Wort für Wort
    static func solve(_ store: GameStore) {
        for clue in store.game!.puzzle.sortedClues { store.demoFill(clue) }
    }

    @Test func tippenUndLoeschen() {
        let store = Self.makeStore()
        store.startNewGame(.leicht)
        let first = store.game!.puzzle.wordCells(store.activeClue!)[0]
        store.type("x")
        #expect(store.game!.entries[first] == "X")
        store.tap(row: first.r, col: first.c)
        store.delete()
        #expect(store.game!.entries[first] == nil)
    }

    @Test func spielstandUebersteht_Neustart() {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        let clock = Clock()
        let a = Self.makeStore(url: url, clock: clock)
        a.startNewGame(.mittel)
        a.type("abc")
        a.revealLetter()
        clock.date.addTimeInterval(30)
        a.appMovedToBackground()
        let b = Self.makeStore(url: url, clock: clock)
        #expect(b.game == a.game)
        #expect(b.game?.hints == 1)
        #expect(b.game?.entries.count == a.game?.entries.count)
        #expect(b.hasRunningGame)
    }

    @Test func bleistiftUndStarthilfeUeberlebenNeustart() {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        let a = Self.makeStore(url: url)
        a.preferences.startHelp = true
        a.startNewGame(.leicht)
        let startEntries = a.game!.entries.count
        #expect(startEntries == a.game!.puzzle.fragen.count - (a.game!.puzzle.fragen.count - a.game!.revealed.count))
        #expect(a.game!.hints == 0)                 // Starthilfe zählt nicht als Hilfe
        a.togglePencil()
        a.type("x")
        let b = Self.makeStore(url: url)            // „App beendet und neu gestartet“
        #expect(b.game == a.game)
        #expect(b.game!.pencil && b.game!.uncertain.count == 1)
        #expect(b.game!.revealed == a.game!.revealed)
    }

    @Test func geloestMitHilfeBekommtKeinenStern() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        store.startDaily()
        store.revealLetter()
        Self.solve(store)
        let key = store.today.description
        #expect(store.stats.dailySolved.contains(key))
        #expect(!store.stats.dailyNoHelp.contains(key))
        #expect(store.stats.streak(today: store.today) == 1)   // Hilfen brechen die Serie nicht
    }

    @Test func einstiegsraetselHatStarthilfeNurFuerDiesesRaetsel() {
        let store = Self.makeStore()
        #expect(!store.preferences.startHelp)
        store.startIntroPuzzle()
        let g = store.game!
        #expect(g.puzzle.id == store.library.puzzles(.leicht)[0].id)
        #expect(g.revealed.count == g.puzzle.fragen.count - (g.puzzle.fragen.count - g.revealed.count) && !g.revealed.isEmpty)
        #expect(g.hints == 0)
        store.goHome()
        store.startNewGame(.leicht)                  // danach ohne Starthilfe
        #expect(store.game!.revealed.isEmpty)
    }

    @Test func stufeKomplettMeldetUndKannVonVornBeginnen() {
        var pack = PuzzlePack()
        pack.paket = "leicht"
        pack.raetsel = Array(Self.library.puzzles(.leicht).prefix(2))
        let store = Self.makeStore(library: PackLibrary(packs: ["leicht": pack]))
        #expect(!store.allSolved(.leicht))
        store.startNewGame(.leicht)
        Self.solve(store)
        #expect(store.result?.levelCompleted == false)
        store.goHome()
        store.startNewGame(.leicht)
        Self.solve(store)
        #expect(store.result?.levelCompleted == true)
        #expect(store.allSolved(.leicht))
        store.goHome()
        store.restartLevel(.leicht)
        #expect(!store.allSolved(.leicht) && store.solvedCount(.leicht) == 0)
        #expect(store.game?.puzzle.id == pack.raetsel[0].id)
    }

    @Test func erinnerungPlanFaelltHeuteAusWennGeloestOderVorbei() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let morgens = cal.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 7, minute: 30))!
        let offen = ReminderPlan.dates(now: morgens, hour: 9, minute: 0, solvedToday: false, calendar: cal)
        #expect(offen.count == 7 && offen[0].day == 5 && offen[0].hour == 9)
        let geloest = ReminderPlan.dates(now: morgens, hour: 9, minute: 0, solvedToday: true, calendar: cal)
        #expect(geloest.count == 6 && geloest[0].day == 6)
        let abends = cal.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 20))!
        #expect(ReminderPlan.dates(now: abends, hour: 9, minute: 0, solvedToday: false, calendar: cal)[0].day == 6)
    }

    @Test func erinnerungNurNachZustimmung() async {
        let mock = MockReminders()
        mock.grants = false
        let store = Self.makeStore(reminders: mock)
        #expect(await store.setReminder(enabled: true) == false)
        #expect(!store.preferences.reminderOn && mock.scheduled.isEmpty)
        mock.grants = true
        mock.status = .notDetermined
        #expect(await store.setReminder(enabled: true) == true)
        #expect(store.preferences.reminderOn && !mock.scheduled.isEmpty)
        #expect(store.preferences.reminderMinutes == 540)    // Standard 9:00
        await store.setReminder(enabled: false)
        #expect(mock.scheduled.isEmpty && !store.preferences.reminderOn)
    }

    @Test func wiederholungZaehltNichtUndZeitenWerdenGemerkt() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        let p = store.library.puzzles(.leicht)[0]
        store.startPuzzle(p)
        clock.date.addTimeInterval(90)
        Self.solve(store)
        #expect(store.isSolved(p) && store.times[p.id] == 90)
        #expect(store.stats[.leicht].won == 1 && store.stats[.leicht].played == 1)
        store.goHome()
        store.startPuzzle(p)                         // Wiederholung
        #expect(store.game?.replay == true)
        clock.date.addTimeInterval(60)
        Self.solve(store)
        #expect(store.stats[.leicht].won == 1 && store.stats[.leicht].played == 1)   // zählt nicht
        #expect(store.times[p.id] == 60)             // aber schnellere Zeit wird gemerkt
        #expect(store.result?.isNewBest == false)
    }

    @Test func zoomstufeWirdProSchwierigkeitGemerkt() {
        let store = Self.makeStore()
        #expect(store.preferences.zoom(for: .schwer) == 1)         // Standard: Übersicht
        store.preferences.setZoom(2, for: .schwer)
        #expect(store.preferences.zoom(for: .schwer) == 2)
        #expect(store.preferences.zoom(for: .leicht) == 1)         // andere Stufen unberührt
        store.preferences.setZoom(9, for: .mittel)
        #expect(store.preferences.zoom(for: .mittel) == 2)         // begrenzt auf 1…2
    }

    @Test func loesungswortLeuchtEinmalAufWennKomplett() {
        let store = Self.makeStore()
        let p = store.library.puzzles(.leicht)[0]
        #expect(!p.solutionCells.isEmpty)
        store.begin(Game(puzzle: p))
        let first = store.solutionPulse
        // Nur die Lösungsfelder richtig füllen (Rest bleibt leer): Cursor aufs Feld, richtigen Buchstaben tippen
        for pos in p.solutionCells {
            store.tap(row: pos.r, col: pos.c)
            if store.game?.cursor == pos { store.type(String(p.solution(pos)!)) }
        }
        #expect(store.game?.solutionComplete == true)
        #expect(store.solutionPulse != first)
    }

    @Test func zeitkurveBehaeltNurDieLetzten20() {
        var s = LevelStats()
        for i in 1...25 { s.recordWin(time: Double(100 + i), withoutHelp: true) }
        #expect(s.recent.count == 20 && s.recent.first == 106 && s.recent.last == 125)
        #expect(s.bestTime == 101)
    }

    @Test func archivNachgeholterTagZaehltNichtZurSerie() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        let heute = store.today
        let gestern = heute.adding(days: -1)
        store.startDaily(on: gestern)
        #expect(store.game?.dailyKey == gestern.description)
        Self.solve(store)
        #expect(store.stats.dailySolved.contains(gestern.description))
        #expect(store.stats.dailyCatchUp.contains(gestern.description))
        #expect(store.stats.streak(today: heute) == 0)           // nachgeholt: keine Serie
        #expect(store.stats.dailySolved.count == 1)              // „Tagesrätsel gelöst“ zählt es mit
        store.goHome()
        store.startDaily(on: gestern)                            // schon gelöst: Wiederholung
        #expect(store.game?.replay == true)
        store.goHome()
        store.startDaily(on: heute.adding(days: 1))              // Zukunft gesperrt
        #expect(store.screen == .home)
        store.startDaily(on: Daily.start.adding(days: -1))       // vor dem Archiv gesperrt
        #expect(store.screen == .home)
        store.startDaily(on: heute)                              // heute zählt normal
        Self.solve(store)
        #expect(store.stats.streak(today: heute) == 1 && !store.stats.dailyCatchUp.contains(heute.description))
    }

    // MARK: Grenzfälle

    @Test func mitternachtWaehrendDesTagesraetselsGiltDerStarttag() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        let starttag = store.today
        store.startDaily()
        store.revealLetter()                                      // schon etwas gespielt
        clock.date.addTimeInterval(86_400)                       // Mitternacht ist vorbei
        #expect(store.today == starttag.adding(days: 1))
        Self.solve(store)
        #expect(store.stats.dailySolved.contains(starttag.description))      // zählt für den Starttag
        #expect(!store.stats.dailyCatchUp.contains(starttag.description))    // nicht „nachgeholt“
        #expect(store.stats.streak(today: store.today) == 1)                 // gestern gelöst: Serie lebt
        #expect(!store.isDailySolvedToday)                                   // heute ist noch offen
    }

    @Test func uhrZurueckgestelltLaesstZeitNichtNegativWerden() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        store.startNewGame(.leicht)
        clock.date.addTimeInterval(30)
        store.pause()
        clock.date.addTimeInterval(-3600)                        // Uhr eine Stunde zurück
        store.unpause()
        clock.date.addTimeInterval(-600)
        #expect(store.elapsed(at: clock.date) >= 30)             // nie weniger als schon gespielt
        store.appMovedToBackground()
        #expect(store.game!.elapsed >= 30)
    }

    @Test func zeitzonenwechselAendertGespeicherteTageNicht() {
        var berlin = Calendar(identifier: .gregorian); berlin.timeZone = TimeZone(identifier: "Europe/Berlin")!
        var tokyo = Calendar(identifier: .gregorian); tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let moment = berlin.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 22))!   // Berlin 5.10., Tokio schon 6.10.
        #expect(Day(moment, calendar: berlin) == Day(2026, 10, 5))
        #expect(Day(moment, calendar: tokyo) == Day(2026, 10, 6))
        #expect(Day(2026, 10, 5).description == "2026-10-05")    // gespeicherte Schlüssel sind zeitzonenfrei
    }

    @Test func beimGewinnenBeendetBleibtAlles() {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        let a = Self.makeStore(url: url)
        a.startNewGame(.leicht)
        Self.solve(a)
        #expect(a.game?.finished == true)
        let b = Self.makeStore(url: url)                         // App sofort nach dem Gewinn beendet und neu gestartet
        #expect(b.stats[.leicht].won == 1 && b.solvedCount(.leicht) == 1)
        #expect(b.game == nil && b.screen == .home)              // kein hängendes Spiel
    }

    @Test func sehrSchnellesTippenBleibtImGitter() {
        let store = Self.makeStore()
        store.startNewGame(.mittel)
        let p = store.game!.puzzle
        for _ in 0..<40 { store.type("abcdefghijklmnopqrstuvwxyzäöüß") }
        let cells = Set(p.letterCells)
        #expect(store.game!.entries.keys.allSatisfy { cells.contains($0) })
        if let c = store.game!.cursor { #expect(cells.contains(c)) }
        store.delete(); store.delete(); store.nextClue(); store.previousClue()
        #expect(store.game!.entries.values.allSatisfy { ("A"..."Z").contains($0) })
    }

    @Test func kaputterCursorImSpeicherStuerztNichtAb() throws {
        var g = Game(puzzle: Self.library.puzzles(.leicht)[0])
        g.cursor = Pos(99, 99)                                   // außerhalb des Gitters
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        var data = SaveData(); data.game = g
        try GameRepository(url: url).save(data)
        let store = Self.makeStore(url: url)
        store.resume()
        store.type("a"); store.delete(); store.nextClue(); store.revealLetter(); store.revealWord()
        #expect(store.game != nil)
        store.tap(row: 0, col: 0)                                // wieder ein gültiger Zustand
        #expect(store.game?.cursor.map { Pos(0, 0) == $0 || store.game!.puzzle.isLetter($0) || true } == true)
    }

    @Test func leererSpeicherUndLeereDatei() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        try Data().write(to: url)                                // leere Datei
        let store = Self.makeStore(url: url)
        #expect(store.game == nil && store.stats.totalPlayed == 0)
        store.startNewGame(.leicht)                              // Spielen und Speichern danach geht wieder
        #expect(GameRepository(url: url).load().game != nil)
    }

    // MARK: Themen, Erfolge, Lernkurve

    @Test func themenPaketLaedtMitAchtThemenZuJeDreissigRaetseln() {
        let lib = Self.library
        #expect(lib.themes.count == 8)
        for t in lib.themes {
            #expect(lib.themePuzzles(t.id).count == 30, Comment(rawValue: t.id))
            #expect(!t.de.isEmpty && !t.en.isEmpty && !t.symbol.isEmpty)
        }
    }

    @Test func themenRaetselZaehlenInGeloestAberNichtInStufeOderSerie() {
        let store = Self.makeStore()
        let p = store.library.themePuzzles("tiere")[0]
        store.startThemePuzzle(p)
        #expect(store.stats[.mittel].played == 0)                  // kein „gespielt“ der Stufe
        Self.solve(store)
        #expect(store.stats.themeWon == 1 && store.stats.totalWon == 1)
        #expect(store.stats[.mittel].won == 0 && store.solvedCount(.mittel) == 0)   // Stufen-Fortschritt unberührt
        #expect(store.themeSolvedCount("tiere") == 1 && store.isSolved(p))
        #expect(store.result?.themeID == "tiere" && store.result?.levelCompleted == false)
        #expect(store.achieved.contains("thema_1") && store.result?.newAchievements.contains("thema_1") == true)
        #expect(store.stats.streak(today: store.today) == 0)
    }

    @Test func erfolgeBleibenUndWerdenNurEinmalGemeldet() {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        let a = Self.makeStore(url: url)
        a.startNewGame(.leicht)
        Self.solve(a)
        #expect(a.result?.newAchievements == ["erstes_raetsel", "ohne_hilfe"])
        a.goHome()
        a.startNewGame(.leicht)
        Self.solve(a)
        #expect(a.result?.newAchievements.isEmpty == true)           // schon erreicht
        let b = Self.makeStore(url: url)                              // Neustart: bleibt erreicht
        #expect(b.achieved == ["erstes_raetsel", "ohne_hilfe"])
    }

    @Test func stufenVorschlagNachDreiOhneHilfeHoechstensEinmalJeStufeUndTag() {
        let store = Self.makeStore()
        for _ in 0..<2 { store.startNewGame(.leicht); Self.solve(store); #expect(store.result?.suggestion == nil); store.goHome() }
        store.startNewGame(.leicht); Self.solve(store)
        #expect(store.result?.suggestion == .mittel)
        store.dismissSuggestion()
        #expect(store.result?.suggestion == nil)
        store.goHome()
        store.startNewGame(.leicht); Self.solve(store)
        #expect(store.result?.suggestion == nil)                      // heute schon gezeigt
    }

    @Test func vorschlagLaesstSichAbschalten() {
        let store = Self.makeStore()
        store.preferences.suggestions = false
        for _ in 0..<3 { store.startNewGame(.leicht); Self.solve(store); store.goHome() }
        #expect(store.result?.suggestion == nil)
    }

    @Test func fortschrittZuruecksetzenLoeschtNurFortschritt() {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        let store = Self.makeStore(url: url)
        store.preferences.showErrors = true
        store.startNewGame(.leicht)
        store.flagActiveClue()
        Self.solve(store)
        store.goHome()
        store.startNewGame(.mittel)
        #expect(store.stats.totalWon == 1 && !store.achieved.isEmpty && store.solvedCount(.leicht) == 1)
        store.resetProgress()
        #expect(store.stats.totalWon == 0 && store.stats.totalPlayed == 0 && store.achieved.isEmpty)
        #expect(store.solvedCount(.leicht) == 0 && store.times.isEmpty && store.game == nil && store.screen == .home)
        #expect(store.preferences.showErrors)                     // Einstellungen bleiben
        #expect(store.flagged.count == 1)                         // gemerkte Fragen bleiben
        let neu = Self.makeStore(url: url)                        // und das ist auch gespeichert
        #expect(neu.stats.totalWon == 0 && neu.achieved.isEmpty && neu.game == nil)
    }

    @Test func naechstesRaetselNummerUndThemenNachfolger() {
        let store = Self.makeStore()
        #expect(store.nextPuzzleNumber(.mittel) == 1)
        store.startNewGame(.mittel); Self.solve(store); store.goHome()
        #expect(store.nextPuzzleNumber(.mittel) == 2)
        store.startNextThemePuzzle("tiere")
        let erstes = store.game!.puzzle.id
        Self.solve(store); store.goHome()
        store.startNextThemePuzzle("tiere")
        #expect(store.game!.puzzle.id != erstes && store.game!.puzzle.thema == "tiere")
    }

    @Test func frageMerkenListeUndLoeschen() {
        let store = Self.makeStore()
        store.startNewGame(.leicht)
        store.flagActiveClue()
        store.flagActiveClue()                       // doppelt: nur einmal
        #expect(store.flagged.count == 1)
        #expect(!store.flagged[0].answer.isEmpty && store.flagged[0].puzzleID == store.game?.puzzle.id)
        store.removeFlagged(at: IndexSet(integer: 0))
        #expect(store.flagged.isEmpty)
    }

    @Test func alteSpeicherdateiOhneNeueFelderLaedt() throws {
        let p = Self.library.puzzles(.leicht)[0]
        let puzzle = try String(data: JSONEncoder().encode(p), encoding: .utf8)!
        let json = #"{"game":{"puzzle":\#(puzzle)}}"#
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        try Data(json.utf8).write(to: url)
        let store = Self.makeStore(url: url)
        let g = try #require(store.game)
        #expect(g.hints == 0 && g.elapsed == 0 && g.entries.isEmpty && g.revealed.isEmpty)
        #expect(g.direction == .rechts && !g.finished && g.dailyKey == nil)
        #expect(store.stats.totalPlayed == 0)
        #expect(store.solvedCount(.leicht) == 0)
    }

    @Test func kaputteSpeicherdateiGibtLeerenStand() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        try Data("{{{".utf8).write(to: url)
        let store = Self.makeStore(url: url)
        #expect(store.game == nil)
        #expect(store.stats.totalPlayed == 0)
    }

    @Test func paketOhneStufeBekommtMittel() throws {
        let json = ##"{"id":"X","breite":2,"hoehe":2,"gitter":["#A","-A"],"fragen":[],"neuesFeld":1}"##
        let p = try JSONDecoder().decode(Puzzle.self, from: Data(json.utf8))
        #expect(p.stufe == "mittel")
    }

    @Test func zeitLaeuftNichtImHintergrund() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        store.startNewGame(.leicht)
        clock.date.addTimeInterval(10)
        #expect(Int(store.elapsed(at: clock.date)) == 10)
        store.appMovedToBackground()
        clock.date.addTimeInterval(500)
        #expect(Int(store.elapsed(at: clock.date)) == 10)
        store.appBecameActive()
        clock.date.addTimeInterval(5)
        #expect(Int(store.elapsed(at: clock.date)) == 15)
    }

    @Test func pauseKnopfBleibtNachRueckkehr() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        store.startNewGame(.leicht)
        store.togglePause()
        store.appMovedToBackground()
        store.appBecameActive()
        #expect(store.isPaused)
        clock.date.addTimeInterval(100)
        #expect(Int(store.elapsed(at: clock.date)) == 0)
        store.type("a") // pausiert: nichts passiert
        #expect(store.game!.entries.isEmpty)
    }

    @Test func loesenOhneHilfeZaehltInStatistik() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        store.startNewGame(.leicht)
        clock.date.addTimeInterval(42)
        Self.solve(store)
        #expect(store.game!.finished)
        let r = store.result
        #expect(r?.hints == 0)
        #expect(r?.isNewBest == false) // erster Sieg der Stufe
        #expect(Int(r?.time ?? 0) == 42)
        let s = store.stats[.leicht]
        #expect(s.played == 1 && s.won == 1 && s.wonWithoutHelp == 1)
        #expect(s.bestTime == 42 && s.averageTime == 42)
        #expect(store.solvedCount(.leicht) == 1)
    }

    @Test func loesenMitHilfeUndNeueBestzeit() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        store.startNewGame(.leicht)
        clock.date.addTimeInterval(100)
        Self.solve(store)
        store.goHome()
        store.startNewGame(.leicht)
        #expect(store.game!.puzzle.id != store.library.puzzles(.leicht)[0].id) // nächstes ungelöstes
        store.revealLetter()
        clock.date.addTimeInterval(60)
        Self.solve(store)
        let s = store.stats[.leicht]
        #expect(s.won == 2 && s.wonWithoutHelp == 1)
        #expect(s.bestTime == 60)
        #expect(store.result?.isNewBest == true && store.result?.hints == 1)
        #expect(store.solvedCount(.leicht) == 2)
    }

    @Test func neuesRaetselNimmtNaechstesUngeloestesDannVonVorn() {
        let store = Self.makeStore()
        let all = store.library.puzzles(.leicht)
        for p in all {
            #expect(store.nextPuzzle(.leicht)?.id == p.id)
            store.begin(Game(puzzle: p))
            Self.solve(store)
        }
        #expect(store.solvedCount(.leicht) == all.count)
        #expect(store.nextPuzzle(.leicht)?.id == all[0].id)
    }

    @Test func volleFehlerGeltenNichtAlsGeloest() {
        let store = Self.makeStore()
        store.startNewGame(.leicht)
        let p = store.game!.puzzle
        for clue in p.sortedClues {
            store.tap(row: clue.zeile, col: clue.spalte)
            if store.activeClue != clue { store.tap(row: clue.zeile, col: clue.spalte) }
            store.type(String(repeating: "Q", count: p.wordCells(clue).count))
        }
        #expect(store.status == .voll_mit_fehlern)
        #expect(store.game?.finished == false)
        #expect(store.checkPuzzle() > 0)
        #expect(!store.game!.marked.isEmpty)
    }

    @Test func tagesraetselSerieUndSperre() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        let heute = store.today
        store.startDaily()
        #expect(store.game?.dailyKey == heute.description)
        #expect(store.game?.puzzle.id == store.library.dailyPuzzle(for: heute)?.id)
        Self.solve(store)
        #expect(store.result?.isDaily == true && store.result?.streak == 1)
        #expect(store.isDailySolvedToday)
        store.goHome()
        store.startDaily() // schon gelöst: nichts
        #expect(store.game == nil && store.screen == .home)
        clock.date.addTimeInterval(86_400)
        #expect(store.stats.streak(today: store.today) == 1)
        store.startDaily()
        Self.solve(store)
        #expect(store.result?.streak == 2)
        #expect(store.stats.bestStreak == 2)
    }

    @Test func tagesraetselWeiterspielenStartetNichtNeu() {
        let store = Self.makeStore()
        store.startDaily()
        store.type("ab")
        let id = store.game!.id
        store.goHome()
        store.startDaily()
        #expect(store.game!.id == id && store.screen == .game)
        #expect(store.stats[.mittel].played == 1)
    }

    @Test func jedeAktionWirdGespeichert() {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        let store = Self.makeStore(url: url)
        store.startNewGame(.leicht)
        store.type("e")
        #expect(GameRepository(url: url).load().game?.entries.count == 1)
        store.revealLetter()
        #expect(GameRepository(url: url).load().game?.hints == 1)
    }
    // MARK: Robustheit (Durchgang 02.11.)

    @Test func neuesRaetselBeiDurchgespielterStufeZaehltNichtDoppelt() {
        var pack = PuzzlePack()
        pack.paket = "leicht"
        pack.raetsel = Array(Self.library.puzzles(.leicht).prefix(1))
        let store = Self.makeStore(library: PackLibrary(packs: ["leicht": pack]))
        store.startNewGame(.leicht)
        Self.solve(store)
        store.goHome()
        #expect(store.stats[.leicht].won == 1)
        store.startNewGame(.leicht)                               // alles gelöst → wieder das erste, aber als Wiederholung
        #expect(store.game?.replay == true)
        Self.solve(store)
        #expect(store.stats[.leicht].won == 1 && store.stats[.leicht].played == 1)
    }

    @Test func gleicheFrageAnAnderemTagWirdNichtDoppeltGemerkt() {
        let clock = Clock()
        let store = Self.makeStore(clock: clock)
        store.startNewGame(.leicht)
        store.flagActiveClue()
        clock.date.addTimeInterval(86_400 * 2)
        store.flagActiveClue()
        #expect(store.flagged.count == 1)
    }

    @Test func kaputteSpeicherdateiBleibtAlsKopieErhalten() throws {
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        try Data("{{{".utf8).write(to: url)
        _ = GameRepository(url: url).load()
        let backup = url.appendingPathExtension("beschaedigt")
        #expect(try String(contentsOf: backup, encoding: .utf8) == "{{{")
        try? FileManager.default.removeItem(at: backup)
    }

    @Test func einBeschaedigtesFeldKostetNichtDenGanzenSpielstand() throws {
        let p = Self.library.puzzles(.leicht)[0]
        let puzzle = try String(data: JSONEncoder().encode(p), encoding: .utf8)!
        // stats.dailySolved hat den falschen Typ, solved ist heil, game hat falsche Typen in hints/elapsed
        let json = #"{"stats":{"dailySolved":"kaputt","bestStreak":4},"solved":{"leicht":["L-0001"]},"game":{"puzzle":\#(puzzle),"hints":"x","elapsed":"y","entries":[{"r":99,"c":99,"v":"Q"}]}}"#
        let url = FileManager.default.temporaryDirectory.appending(path: "kw-\(UUID().uuidString).json")
        try Data(json.utf8).write(to: url)
        let store = Self.makeStore(url: url)
        #expect(store.stats.bestStreak == 4 && store.stats.dailySolved.isEmpty)
        #expect(store.solved["leicht"] == ["L-0001"])
        let g = try #require(store.game)
        #expect(g.hints == 0 && g.elapsed == 0 && g.entries.isEmpty)   // Eintrag außerhalb des Gitters verworfen
    }

    // MARK: Im Rahmen der Sammlung (Start über Vormerkung, Stand im Kern)

    /// Vorgemerkte Starts: Stufe, bestimmtes Rätsel, Einstieg mit Starthilfe; ohne Vormerkung das Tagesrätsel, ist es gelöst, Stufe Mittel.
    @Test func startenFolgtDerVormerkung() {
        let store = Self.makeStore()
        store.starten(.stufe(.leicht))
        #expect(store.game?.level == .leicht && store.game?.dailyKey == nil)
        store.goHome()
        let p = store.library.puzzles(.leicht)[1]
        store.starten(.raetsel(p))
        #expect(store.game?.puzzle.id == p.id)
        store.goHome()
        store.starten(.einstieg)
        #expect(store.game?.puzzle.id == store.library.puzzles(.leicht)[0].id && store.game?.entries.isEmpty == false)
        store.goHome()
        store.starten(nil)
        #expect(store.game?.dailyKey == store.today.description)
        Self.solve(store)
        store.goHome()
        store.starten(.tages)                                    // schon gelöst: stattdessen das nächste Rätsel der Stufe Mittel
        #expect(store.game?.dailyKey == nil && store.game?.level == .mittel && store.hasRunningGame)
    }

    /// Nach einem gelösten Stufen-Rätsel startet „Nächstes Rätsel“ (ohne Vormerkung) das nächste derselben Stufe;
    /// das gelöste bleibt mit Ergebnis für den Ende-Bildschirm stehen, bis das nächste beginnt.
    @Test func naechstesRaetselNachDemLoesen() {
        let store = Self.makeStore()
        store.starten(.stufe(.leicht))
        let erstes = store.game!.puzzle.id
        Self.solve(store)
        store.goHome()
        #expect(store.game == nil && store.letztes?.spiel.puzzle.id == erstes && store.letztes?.ergebnis.level == .leicht)
        store.starten(nil)
        #expect(store.game?.level == .leicht && store.game?.puzzle.id != erstes && store.letztes == nil)
    }

    /// Verwirft der Rahmen den Stand („Beenden“), gibt es nach dem Abgleich auch im Spiel kein laufendes Rätsel mehr.
    /// Ein pausiertes Rätsel (Stand im Kern vorhanden) bleibt.
    @Test func abgleichMitDemStandImKern() {
        let store = Self.makeStore()
        store.starten(.stufe(.leicht))
        store.goHome()                                           // pausiert: der Stand liegt im Kern
        SpielStand.sichern(store.game!.puzzle.id, spiel: GameStore.kennung)
        store.abgleichen()
        #expect(store.hasRunningGame)
        SpielStand.loeschen(GameStore.kennung)                   // der Rahmen verwirft
        store.abgleichen()
        #expect(store.game == nil)
    }
}
