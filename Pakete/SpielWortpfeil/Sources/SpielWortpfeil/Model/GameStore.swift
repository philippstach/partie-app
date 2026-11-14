// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Zustand der ganzen App: laufendes Spiel, Statistik, Fortschritt. Jede Aktion wird sofort gespeichert.
@MainActor @Observable
final class GameStore {
    enum Screen { case home, game }

    /// Eine kurze Gold-Welle über ein gerade richtig gelöstes Wort
    struct Wave: Equatable {
        var id = UUID()
        var cells: [Pos]
        /// Millisekunden Verzögerung von Feld zu Feld
        var step = 45
    }

    /// Kennung im Kern (`SpielStand`, Statistik, Rahmen).
    static let kennung = "wortpfeil"

    /// Was die nächste Partie im Rahmen spielen soll. Die Startkarten merken es vor und rufen dann den Rahmen (`SpielStartAktionen.neu`).
    enum Start: Equatable {
        case tages
        case archiv(Day)
        case stufe(Level)
        /// Stufe ist durchgespielt: Liste leeren und beim ersten Rätsel beginnen
        case stufeVonVorn(Level)
        case raetsel(Puzzle)
        case einstieg
    }
    var vorgemerkt: Start?
    /// Ergebnis und Endstand des zuletzt gelösten Rätsels für den Ende-Bildschirm des Rahmens (bis zum nächsten Start).
    private(set) var letztes: (ergebnis: WinResult, spiel: Game)?

    var screen: Screen = .home
    private(set) var game: Game?
    private(set) var stats = Stats()
    private(set) var solved: [String: Set<String>] = [:]
    private(set) var result: WinResult?
    private(set) var isPaused = false
    private(set) var wave: Wave?
    /// Felder, die nach „prüfen“ kurz schütteln
    private(set) var shake: Wave?
    /// Wechselt, wenn das Lösungswort gerade vollständig und richtig geworden ist (Aufleuchten)
    private(set) var solutionPulse = UUID()
    /// Nach dem Lösen läuft kurz die Gold-Welle, danach kommt der Gewonnen-Bildschirm
    private(set) var celebrating = false
    private(set) var flagged: [FlaggedClue] = []
    /// Beste Lösungszeit je Rätsel-ID (für die Rätselliste)
    private(set) var times: [String: Double] = [:]
    private(set) var achieved: [String] = []
    private var suggestionDays: [String: String] = [:]
    private(set) var reminderPermission: ReminderPermission = .notDetermined
    private let reminders: ReminderScheduling
    /// Zeit steht still (Bildtests)
    var freezeTime = false
    var saveError: String?

    let preferences: AppPreferences
    private(set) var library: PackLibrary
    /// Die Rätselpakete werden im Hintergrund geladen, damit die App sofort startet
    private(set) var packsLoading = false
    /// Erhöht sich bei Tageswechsel, damit die Oberfläche das neue Datum zeigt
    private(set) var dayRevision = 0
    private var midnightTask: Task<Void, Never>?
    private let repository: GameRepository
    private let now: () -> Date
    private let calendar: Calendar
    private var runningSince: Date?

    init(repository: GameRepository = GameRepository(), preferences: AppPreferences = AppPreferences(),
         library: PackLibrary? = nil, reminders: ReminderScheduling = SystemReminders(), calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.repository = repository
        self.preferences = preferences
        if let library {
            self.library = library
        } else {
            self.library = PackLibrary(packs: [:])
            packsLoading = true
        }
        self.calendar = calendar
        self.reminders = reminders
        self.now = now
        let saved = repository.load()
        stats = saved.stats
        solved = saved.solved
        flagged = saved.flagged
        times = saved.times
        achieved = saved.achieved
        suggestionDays = saved.suggestionDays
        if let g = saved.game, !g.finished { game = g }
        if packsLoading {
            Task {
                let loaded = await Task.detached(priority: .userInitiated) { PackLibrary.bundled() }.value
                self.library = loaded
                self.packsLoading = false
            }
        }
    }

    /// Aktueller Zeitpunkt (für Anzeige und Teilen)
    var currentDate: Date { now() }

    var today: Day { Day(now(), calendar: calendar) }

    // MARK: Zeit

    /// Gespielte Zeit zum Zeitpunkt `date`
    func elapsed(at date: Date) -> Double {
        guard let game else { return 0 }
        if freezeTime { return game.elapsed }
        guard let since = runningSince else { return game.elapsed }
        return game.elapsed + max(0, date.timeIntervalSince(since))
    }

    private func startClock() {
        guard let g = game, !g.finished, runningSince == nil, !freezeTime else { return }
        runningSince = now()
    }

    private func stopClock() {
        guard game != nil, let since = runningSince else { return }
        game!.elapsed += max(0, now().timeIntervalSince(since))
        runningSince = nil
    }

    func pause() {
        guard game != nil, !isPaused else { return }
        stopClock()
        isPaused = true
        save()
    }

    func unpause() {
        guard game != nil, isPaused else { return }
        isPaused = false
        startClock()
    }

    /// App geht in den Hintergrund: Zeit anhalten, speichern
    func appMovedToBackground() {
        if screen == .game, game?.finished == false { pause() } else { stopClock(); save() }
    }

    /// Plant einen Anstoß für den nächsten Mitternacht (Uhr/Zeitzone werden dabei jedes Mal neu gelesen)
    private func scheduleMidnightTick() {
        midnightTask?.cancel()
        let start = calendar.startOfDay(for: now())
        guard let next = calendar.date(byAdding: .day, value: 1, to: start) else { return }
        let wait = max(1, next.timeIntervalSince(now()))
        midnightTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled, let self else { return }
            self.dayRevision += 1
            self.scheduleMidnightTick()
            await self.refreshReminders()
        }
    }

    func appBecameActive() {
        dayRevision += 1
        scheduleMidnightTick()
        Task { await refreshReminders() }
        if screen == .game, game?.finished == false, !isPausedByUser { unpause() }
    }

    /// Pause per Knopf bleibt, auch wenn die App zurückkommt
    var isPausedByUser = false

    // MARK: Spiel starten und beenden

    var hasRunningGame: Bool { game.map { !$0.finished } ?? false }

    /// Das nächste noch nicht gelöste Rätsel des Pakets in Paketreihenfolge, sonst wieder das erste.
    func nextPuzzle(_ level: Level) -> Puzzle? {
        let all = library.puzzles(level)
        let done = solved[level.rawValue] ?? []
        return all.first { !done.contains($0.id) } ?? all.first
    }

    func startNewGame(_ level: Level) {
        guard let puzzle = nextPuzzle(level) else { return }
        var g = Game(puzzle: puzzle, startHelp: preferences.startHelp)
        g.replay = isSolved(puzzle)   // ist die Stufe durchgespielt, beginnt „Neues Rätsel“ wieder vorn und zählt dann nicht doppelt
        begin(g)
    }

    /// Einstiegsrätsel für Neulinge: das erste Leicht-Rätsel mit Starthilfe (nur für dieses Rätsel)
    func startIntroPuzzle() {
        guard let puzzle = library.puzzles(.leicht).first else { return }
        begin(Game(puzzle: puzzle, startHelp: true))
    }

    var isDailySolvedToday: Bool { stats.dailySolved.contains(today.description) }

    /// Rätsel des Tages. Ist es schon gelöst, passiert nichts.
    func startDaily() {
        let day = today
        guard !isDailySolvedToday, let puzzle = library.dailyPuzzle(for: day) else { return }
        if let g = game, !g.finished, g.dailyKey == day.description { resume(); return }
        begin(Game(puzzle: puzzle, dailyKey: day.description, startHelp: preferences.startHelp))
    }

    /// Archiv: das Tagesrätsel eines vergangenen Tages (ab 01.01.2026 bis heute) spielen. Nachgeholte Tage zählen nicht zur Serie,
    /// schon gelöste lassen sich wiederholen (zählen dann nicht). Zukünftige Tage sind gesperrt.
    func startDaily(on day: Day) {
        guard day <= today, !(day < Daily.start), let puzzle = library.dailyPuzzle(for: day) else { return }
        if day == today { startDaily(); return }
        if let g = game, !g.finished, g.dailyKey == day.description { resume(); return }
        var g = Game(puzzle: puzzle, dailyKey: day.description, startHelp: preferences.startHelp)
        g.replay = stats.dailySolved.contains(day.description)
        g.archive = true
        begin(g)
    }

    /// Startet ein bestimmtes Spiel (auch für Tests und Demo).
    func begin(_ newGame: Game) {
        // Die Sammlungs-Statistik bucht der Rahmen (Ende und „Beenden“), nicht mehr das Spiel selbst.
        game = newGame
        letztes = nil
        if !newGame.replay, newGame.puzzle.thema == nil { stats[newGame.level].played += 1 }
        result = nil
        isPaused = false
        isPausedByUser = false
        runningSince = nil
        screen = .game
        startClock()
        save()
    }

    func resume() {
        guard game != nil else { return }
        screen = .game
        isPaused = false
        isPausedByUser = false
        startClock()
    }

    func goHome() {
        stopClock()
        isPaused = false
        screen = .home
        if game?.finished == true { game = nil }
        save()
    }

    /// Pause-Knopf
    func togglePause() {
        if isPaused { isPausedByUser = false; unpause() } else { isPausedByUser = true; pause() }
    }

    // MARK: Aktionen im Spiel

    func tap(row: Int, col: Int) {
        let before = game?.direction
        act { $0.tap(Pos(row, col)) }
        if let before, before != game?.direction { SpielHaptik.tap() }   // kurzer Tick beim Richtungswechsel
    }
    func type(_ text: String) { act { $0.type(text) } }
    func delete() { act { $0.delete() } }
    func nextClue() { act { $0.moveToClue(step: 1) } }
    func previousClue() { act { $0.moveToClue(step: -1) } }
    func revealLetter() { act { $0.revealLetter() } }
    func togglePencil() { act { $0.togglePencil() } }
    func revealWord() { act { $0.revealWord() } }

    /// Lösungszeile: Sprung zum Feld im Gitter (zuerst sein waagerechtes Wort, sonst das senkrechte)
    func jumpToSolutionCell(_ index: Int) {
        guard let g = game, g.puzzle.solutionCells.indices.contains(index) else { return }
        let pos = g.puzzle.solutionCells[index]
        act { game in
            game.cursor = pos
            if game.puzzle.clue(at: pos, direction: .rechts) != nil { game.direction = .rechts }
            else if game.puzzle.clue(at: pos, direction: .unten) != nil { game.direction = .unten }
        }
    }

    /// Pfeiltasten der Hardware-Tastatur
    func moveCursor(_ d: Direction, forward: Bool) { act { $0.moveCursor(d, forward: forward) } }

    /// Richtung am Cursor wechseln (Antippen der Frageleiste)
    func toggleDirection() {
        defer { SpielHaptik.tap() }
        act { g in
            guard let cur = g.cursor, g.puzzle.clue(at: cur, direction: g.direction.other) != nil else { return }
            g.direction = g.direction.other
        }
    }

    @discardableResult
    func checkWord() -> Int {
        var n = 0
        let before = game?.marked ?? []
        act { n = $0.checkWord() }
        startShake(before)
        return n
    }

    @discardableResult
    func checkPuzzle() -> Int {
        var n = 0
        let before = game?.marked ?? []
        act { n = $0.checkPuzzle() }
        startShake(before)
        return n
    }

    private func startShake(_ before: Set<Pos>) {
        let new = (game?.marked ?? []).subtracting(before)
        if !new.isEmpty { shake = Wave(cells: new.sorted(), step: 0) }
    }

    /// Alles, was das Gitter zum Zeichnen braucht
    var gridData: GridData {
        var d = GridData(game: game!, showErrors: preferences.showErrors)
        d.shake = shake
        return d
    }

    var activeClue: Clue? { game?.activeClue }
    var activeCells: [Pos] { game?.activeCells ?? [] }
    var wrongCells: [Pos] { game?.wrongCells ?? [] }
    var status: GameStatus { game?.status ?? .laeuft }
    var progress: Double { game?.progress ?? 0 }

    /// Führt eine Aktion aus, prüft auf Sieg und speichert.
    private func act(_ change: (inout Game) -> Void) {
        guard var g = game, !g.finished, !isPaused else { return }
        let before = completedWords(g)
        let hadSolution = g.solutionComplete
        change(&g)
        game = g
        if !hadSolution, g.solutionComplete, g.status != .geloest {
            solutionPulse = UUID()
            SpielHaptik.success()
            Sound.word.play()
        }
        if preferences.showCorrectWords, let done = completedWords(g).subtracting(before).first {
            wave = Wave(cells: g.puzzle.wordCells(done))
            SpielHaptik.tap()
            Sound.word.play()
        }
        if g.status == .geloest { win() }
        save()
    }

    /// Fragen, deren Wort vollständig richtig steht
    private func completedWords(_ g: Game) -> Set<Clue> {
        Set(g.puzzle.sortedClues.filter { clue in
            let cells = g.puzzle.wordCells(clue)
            return !cells.isEmpty && cells.allSatisfy { g.entries[$0] == g.puzzle.solution($0) }
        })
    }

    private func win() {
        stopClock()
        guard var g = game else { return }
        g.finished = true
        game = g
        isPaused = false
        let withoutHelp = g.hints == 0
        celebrate(g)
        var best = false
        let isThemed = g.puzzle.thema != nil
        if !g.replay {
            if isThemed {
                stats.themeWon += 1
                solved["themen", default: []].insert(g.puzzle.id)
            } else {
                var s = stats[g.level]
                best = s.recordWin(time: g.elapsed, withoutHelp: withoutHelp)
                stats[g.level] = s
                solved[g.puzzle.level.rawValue, default: []].insert(g.puzzle.id)
            }
        }
        if g.dailyKey == nil || !g.replay { times[g.puzzle.id] = min(times[g.puzzle.id] ?? .infinity, g.elapsed) }
        var streak = 0
        if let key = g.dailyKey, !g.replay {
            // Mitternacht während des Spiels: es gilt der Starttag; nur Archiv-Rätsel sind „nachgeholt“
            if g.archive { stats.dailyCatchUp.insert(key) }
            stats.dailySolved.insert(key)
            if withoutHelp { stats.dailyNoHelp.insert(key) }
            stats.dailyTimes[key] = g.elapsed
            streak = stats.streak(today: today)
            stats.bestStreak = max(stats.bestStreak, Daily.bestStreak(solved: stats.streakDays))
            Task { await refreshReminders() }   // heute gelöst: Erinnerung für heute entfällt
        }
        // Erfolge: einmal erreicht = bleibt; neu erreichte werden nach dem Gewinnen einmal gezeigt
        var newOnes: [String] = []
        if !g.replay {
            let reached = currentAchievements
            newOnes = reached.filter { !achieved.contains($0) }
            achieved.append(contentsOf: newOnes)
        }
        // Lernkurve: nur nach Stufen-Rätseln (nicht Tages-, Themen- oder Wiederholungs-Rätseln)
        var suggestion: Level?
        if !g.replay, !isThemed, g.dailyKey == nil {
            var hints = stats.recentHints[g.level.rawValue] ?? []
            hints.append(g.hints)
            stats.recentHints[g.level.rawValue] = Array(hints.suffix(5))
            if preferences.suggestions, suggestionDays[g.level.rawValue] != today.description,
               let s = Recommendation.suggest(level: g.level, hints: hints), totalCount(s) > 0 {
                suggestion = s
                suggestionDays[g.level.rawValue] = today.description
            }
        }
        let r = WinResult(level: g.level, time: g.elapsed, hints: g.hints, isNewBest: best,
                          isDaily: g.dailyKey != nil, streak: streak, themeID: g.puzzle.thema,
                          newAchievements: newOnes, suggestion: suggestion,
                          levelCompleted: !g.replay && !isThemed && g.dailyKey == nil && solvedCount(g.level) >= totalCount(g.level) && totalCount(g.level) > 0)
        result = r
        letztes = (r, g)
    }

    /// Stufen-Vorschlag verwerfen („Später“)
    func dismissSuggestion() { result?.suggestion = nil; letztes?.ergebnis.suggestion = nil }

    // MARK: Start im Rahmen

    /// Startet, was vorgemerkt wurde. Ohne Vormerkung: das nächste Rätsel passend zum zuletzt gelösten, sonst `starteStandard`.
    /// Läuft danach kein Rätsel (z. B. Tagesrätsel schon gelöst), greift ebenfalls `starteStandard`.
    func starten(_ wunsch: Start?) {
        let zuletzt = letztes?.ergebnis
        switch wunsch {
        case .tages: startDaily()
        case .archiv(let tag): startDaily(on: tag)
        case .stufe(let l): startNewGame(l)
        case .stufeVonVorn(let l): restartLevel(l)
        case .raetsel(let p): startPuzzle(p)
        case .einstieg: startIntroPuzzle()
        case nil:
            guard let r = zuletzt else { starteStandard(); return }
            if r.levelCompleted { restartLevel(r.level) }
            else if let t = r.themeID { startNextThemePuzzle(t) }
            else { startNewGame(r.level) }
        }
        if !hasRunningGame { starteStandard() }
    }

    /// Das heutige Tagesrätsel, solange es offen ist; sonst das nächste Rätsel der Stufe Mittel (oder der ersten Stufe mit Rätseln).
    func starteStandard() {
        if !isDailySolvedToday, library.dailyPuzzle(for: today) != nil { startDaily(); return }
        if let l = ([.mittel] + Level.allCases).first(where: { totalCount($0) > 0 }) { startNewGame(l) }
    }

    /// Abgleich mit dem Rahmen: Hat er den Stand verworfen („Beenden“ oder neue Partie), gibt es auch hier kein laufendes Rätsel mehr.
    func abgleichen() {
        guard hasRunningGame, !SpielStand.vorhanden(Self.kennung) else { return }
        game = nil
        runningSince = nil
        isPaused = false
        save()
    }

    /// Das nächste noch nicht gelöste Rätsel eines Themas (sonst das erste)
    func startNextThemePuzzle(_ id: String) {
        let all = library.themePuzzles(id)
        guard let p = all.first(where: { !isSolved($0) }) ?? all.first else { return }
        startPuzzle(p)
    }

    /// Ein Themen-Rätsel aus der Liste spielen
    func startThemePuzzle(_ puzzle: Puzzle) { startPuzzle(puzzle) }

    /// Gold-Welle über das ganze Gitter, dann erst der Gewonnen-Bildschirm
    private func celebrate(_ g: Game) {
        let cells = g.puzzle.letterCells
        guard !cells.isEmpty else { return }
        wave = Wave(cells: cells, step: max(4, min(45, 900 / cells.count)))
        celebrating = true
        SpielHaptik.success()
        Sound.win.play()
        Task {
            try? await Task.sleep(for: .milliseconds(1500))
            celebrating = false
        }
    }

    // MARK: Erinnerung ans Tagesrätsel

    /// Erinnerung ein- oder ausschalten; fragt beim ersten Mal nach der Erlaubnis. Gibt zurück, ob sie jetzt an ist.
    @discardableResult
    func setReminder(enabled: Bool) async -> Bool {
        if !enabled {
            preferences.reminderOn = false
            await reminders.replaceAll(with: [])
            return false
        }
        var perm = await reminders.permission()
        if perm == .notDetermined { _ = await reminders.requestPermission(); perm = await reminders.permission() }
        reminderPermission = perm
        guard perm == .allowed else { preferences.reminderOn = false; return false }
        preferences.reminderOn = true
        await refreshReminders()
        return true
    }

    /// Plant die nächsten Erinnerungen neu (nach Start, Uhrzeit-Änderung und gelöstem Tagesrätsel)
    func refreshReminders() async {
        reminderPermission = await reminders.permission()
        guard preferences.reminderOn, reminderPermission == .allowed else { return }
        let m = preferences.reminderMinutes
        let dates = ReminderPlan.dates(now: now(), hour: m / 60, minute: m % 60, solvedToday: isDailySolvedToday, calendar: calendar)
        await reminders.replaceAll(with: dates)
    }

    // MARK: Frage merken

    /// Merkt die aktive Frage zum späteren Melden vor (nur auf dem Gerät).
    func flagActiveClue() {
        guard let g = game, let c = g.activeClue else { return }
        let entry = FlaggedClue(puzzleID: g.puzzle.id, clue: c.text, answer: g.puzzle.solutionWord(c), date: today.description)
        if !flagged.contains(where: { $0.id == entry.id }) { flagged.append(entry) }
        save()
    }

    /// Fortschritt zurücksetzen: Statistik, Erfolge, gelöste Rätsel, Zeiten und Vorschläge. Einstellungen und gemerkte Fragen bleiben;
    /// ein laufendes Spiel wird beendet.
    func resetProgress() {
        stats = Stats()
        solved = [:]
        times = [:]
        achieved = []
        suggestionDays = [:]
        result = nil
        game = nil
        runningSince = nil
        isPaused = false
        screen = .home
        save()
        Task { await refreshReminders() }
    }

    /// Eine gemerkte Frage entfernen (Wischen in der Liste)
    func removeFlagged(at offsets: IndexSet) {
        for i in offsets.sorted(by: >) where flagged.indices.contains(i) { flagged.remove(at: i) }
        save()
    }

    // MARK: Fortschritt

    func solvedCount(_ level: Level) -> Int {
        let ids = Set(library.puzzles(level).map(\.id))
        return (solved[level.rawValue] ?? []).intersection(ids).count
    }

    /// Ein bestimmtes Rätsel aus der Liste spielen (gelöste lassen sich wiederholen, zählen dann nicht mehr)
    func startPuzzle(_ puzzle: Puzzle) {
        var g = Game(puzzle: puzzle, startHelp: preferences.startHelp)
        g.replay = isSolved(puzzle)
        begin(g)
    }

    /// Themen-Rätsel haben eine eigene Liste („themen“), alle anderen die ihrer Stufe
    private func solvedKey(_ p: Puzzle) -> String { p.thema != nil ? "themen" : p.level.rawValue }

    func isSolved(_ puzzle: Puzzle) -> Bool { (solved[solvedKey(puzzle)] ?? []).contains(puzzle.id) }

    func themeSolvedCount(_ id: String) -> Int { library.themePuzzles(id).filter(isSolved).count }

    /// Erfolge, die gerade erreicht sind (aus der Statistik berechnet)
    var currentAchievements: [String] { Achievements.reached(achievementInput) }

    var achievementInput: AchievementInput {
        var i = AchievementInput()
        for l in Level.allCases {
            i.solved[l] = min(stats[l].won, solvedCount(l))   // verschiedene Rätsel, nicht Wiederholungen
            i.withoutHelp[l] = stats[l].wonWithoutHelp
            i.bestTime[l] = stats[l].bestTime ?? 0
            i.packSize[l] = library.puzzles(l).count
        }
        i.bestStreak = max(stats.bestStreak, stats.streak(today: today))
        i.dailySolved = stats.dailySolved.count
        i.themesSolved = stats.themeWon
        return i
    }

    /// Nummer des Rätsels, das „Neues Rätsel“ als Nächstes nimmt (1-basiert in Paketreihenfolge)
    func nextPuzzleNumber(_ level: Level) -> Int? {
        guard let next = nextPuzzle(level) else { return nil }
        return (library.puzzles(level).firstIndex { $0.id == next.id }).map { $0 + 1 }
    }

    func allSolved(_ level: Level) -> Bool { totalCount(level) > 0 && solvedCount(level) >= totalCount(level) }

    /// Von vorn beginnen: gelöst-Liste der Stufe leeren und das erste Rätsel starten
    func restartLevel(_ level: Level) {
        solved[level.rawValue] = []
        save()
        startNewGame(level)
    }

    func totalCount(_ level: Level) -> Int { library.puzzles(level).count }

    // MARK: Speichern

    func save() {
        TagesSerieWidget.melden(praefix: "kreuzwort", serie: stats.streak(today: today), letzterTag: stats.streakDays.max()?.description)
        var snapshot = game
        if var g = snapshot, runningSince != nil { g.elapsed = elapsed(at: now()); snapshot = g }
        var data = SaveData()
        data.game = snapshot
        data.stats = stats
        data.solved = solved
        data.flagged = flagged
        data.times = times
        data.achieved = achieved
        data.suggestionDays = suggestionDays
        do { try repository.save(data); saveError = nil } catch { saveError = error.localizedDescription }
        // Der Rahmen bietet „Partie fortsetzen“ an, solange im Kern ein Stand liegt. Das Rätsel selbst steht in der eigenen Datei,
        // im Kern genügt die Kennung des Rätsels. Einen bewusst verworfenen Stand legt das Speichern nicht wieder an.
        if let g = game, !g.finished {
            if !SpielStand.verworfen.contains(Self.kennung) { SpielStand.sichern(g.puzzle.id, spiel: Self.kennung) }
        } else {
            SpielStand.loeschen(Self.kennung)
        }
    }
}

#if DEBUG
extension GameStore {
    /// Nur Demo und Tests: das Wort der Frage richtig ausfüllen (Buchstabe für Buchstabe am Cursor)
    func demoFill(_ clue: Clue) {
        tap(row: clue.zeile, col: clue.spalte)
        if activeClue != clue { tap(row: clue.zeile, col: clue.spalte) }
        guard let p = game?.puzzle else { return }
        let cells = p.wordCells(clue)
        let word = Array(p.solutionWord(clue))
        while activeClue == clue, let cur = game?.cursor, let i = cells.firstIndex(of: cur),
              cells.contains(where: { game?.entries[$0] == nil }) {
            let before = game?.entries[cur]
            type(String(word[i]))
            if before == game?.entries[cur], game?.entries[cur] != word[i] { break }
        }
    }

    /// Nur für Demo-Szenarien: Statistik und Fortschritt vorgeben
    func demoSeed(stats: Stats, solved: [String: Set<String>], times: [String: Double] = [:], achieved: [String]? = nil) {
        self.stats = stats
        self.achieved = achieved ?? currentAchievements
        self.solved = solved
        self.times = times
    }

    func demoSetElapsed(_ seconds: Double) {
        game?.elapsed = seconds
    }
}
#endif
