// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

enum Screen: Equatable {
    /// `partySetup`: Einrichtung der Partie; `party`: ein Schritt der Partie außerhalb des Spiels (Übergabe, Eingabe, Rangliste)
    case home, game, partySetup, party
}

/// Verbindet Spiellogik, Speichern und Oberfläche. Speichert nach jeder Aktion.
@MainActor @Observable
final class GameStore {
    private let repository: GameRepository
    let preferences: AppPreferences
    /// Liefert den Seed für jede Ziehung. Im Spiel Systemzufall, in Tests fest.
    private let seedSource: () -> UInt64
    private let wordListSource: (WordLanguage) -> WordList
    private let clock: () -> Date
    private var lists: [WordLanguage: WordList] = [:]

    private(set) var data: SaveData
    var screen: Screen = .home
    /// Das Wort des Tages läuft (statt des normalen Spiels) in `game`
    private(set) var playingDaily = false
    /// Das Spiel einer Partie läuft (oder zeigt den Zwischenstand) in `game`
    private(set) var playingParty = false
    private var dailyLanguage: WordLanguage = .de
    /// Heutiger Tag „JJJJ-MM-TT“ (Ortszeit); `refreshToday()` hält ihn aktuell
    private(set) var today: String
    var saveError: String?
    /// Neutrale Meldung (z. B. keine Wörter für die Auswahl), getrennt vom Speicherfehler
    var infoMeldung: String?
    private var speicherfehlerGezeigt = false
    /// Der gerade beendete Sieg hat die beste Serie verbessert (für das Abzeichen; wird nicht gespeichert)
    var newBestStreak = false
    /// Ende-Bildschirm erst nach dem großen Moment (Sieg 1,2 s, Niederlage 1,5 s). Standard: sofort.
    private(set) var endReady = true
    /// Der letzte Zug war ein Hinweis (für das Glitzern in den Kacheln)
    private(set) var lastRevealWasHint = false
    /// Das letzte Überleben-Wort hat ein Leben zurückgebracht (für das Abzeichen; wird nicht gespeichert)
    private(set) var survivalBonus = false
    /// Erfolge, die das gerade beendete Spiel freigeschaltet hat (für den Ende-Bildschirm; wird nicht gespeichert)
    private(set) var newAchievements: [Achievement] = []
    /// Kategorie, die mit dem letzten Sieg voll wurde und deren Feier noch nicht gezeigt wurde
    private(set) var pendingCelebration: Category?

    /// „Bewegung reduzieren“: nur Überblenden, keine Wartezeiten
    var calmMotion: Bool {
        #if canImport(UIKit)
        UIAccessibility.isReduceMotionEnabled
        #else
        false
        #endif
    }

    init(repository: GameRepository = GameRepository(),
         preferences: AppPreferences = AppPreferences(),
         seedSource: @escaping () -> UInt64 = { UInt64.random(in: .min ... .max) },
         wordLists: @escaping (WordLanguage) -> WordList = GameStore.loadFromBundle,
         clock: @escaping () -> Date = { Date() }) {
        self.repository = repository
        self.preferences = preferences
        self.seedSource = seedSource
        self.wordListSource = wordLists
        self.clock = clock
        today = DayKey.string(for: clock())
        data = repository.load()
    }

    // MARK: Lesen

    /// Das Spiel auf dem Bildschirm: das Tageswort oder das normale Spiel
    var game: Game? {
        if playingDaily { return data.daily[dailyLanguage.rawValue]?.game }
        if playingParty { return data.party?.game }
        return data.game
    }

    private func setGame(_ new: Game) {
        if playingDaily { data.daily[dailyLanguage.rawValue]?.game = new }
        else if playingParty { data.party?.game = new }
        else { data.game = new }
    }
    var stats: Stats { data.stats }
    var lastWinMistakes: Int? { data.lastWinMistakes }
    var lastCategory: Category? { data.lastCategory }
    var lastDifficulty: Difficulty? { data.lastDifficulty }
    var lastKids: Bool { data.lastKids }
    /// Ein Einzelspiel, das noch läuft („Weiter“ auf dem Start)
    var runningGame: Game? { data.game.flatMap { $0.status == .playing ? $0 : nil } }

    func wordList(for language: WordLanguage) -> WordList {
        if let list = lists[language] { return list }
        let list = wordListSource(language)
        lists[language] = list
        return list
    }

    nonisolated static func loadFromBundle(_ language: WordLanguage) -> WordList {
        do {
            return try WordList.load(language)
        } catch {
            #if DEBUG
            fatalError("Wortliste \(language.rawValue) nicht ladbar: \(error)")
            #else
            return .empty
            #endif
        }
    }

    // MARK: Spiel starten

    /// Neues Einzelspiel. Ein laufendes Spiel wird dabei aufgegeben (zählt nur, wenn schon geraten wurde).
    func startGame(category: Category?, difficulty: Difficulty?, kids: Bool = false) {
        let difficulty = kids ? .easy : difficulty
        let language = preferences.wordLanguage
        let list = wordList(for: language)
        var rng = SplitMix64(seed: seedSource())
        let recent = data.recent[language.rawValue] ?? []
        guard let word = WordPicker.pick(from: list.words, category: category, difficulty: difficulty,
                                         recent: recent, rng: &rng) else {
            infoMeldung = String(localized: "Es gibt keine Wörter für diese Auswahl.")
            return
        }
        abandonRunning()
        playingDaily = false
        playingParty = false
        newBestStreak = false
        newAchievements = []
        endReady = true
        data.recent[language.rawValue] = WordPicker.remember(word.solution, in: recent)
        data.lastCategory = category
        if !kids { data.lastDifficulty = difficulty }
        data.lastKids = kids
        data.game = Game(solution: word.solution, language: language, category: word.category,
                         difficulty: word.difficulty, displayText: word.text, kids: kids)
        screen = .game
        persist()
    }

    // MARK: Überleben

    var survival: SurvivalRun? { data.survival }
    var survivalBest: Int { data.survivalBest }
    /// Die Serie läuft noch (Leben übrig)
    var survivalActive: SurvivalRun? { data.survival.flatMap { $0.isOver ? nil : $0 } }

    /// Neue Serie (ersetzt eine laufende)
    func startSurvival() {
        abandonRunning()
        data.survival = SurvivalRun()
        startSurvivalWord()
    }

    /// Serie fortsetzen: ein laufendes Wort öffnen, sonst das nächste ziehen
    func continueSurvival() {
        guard survivalActive != nil else { return }
        if let g = data.game, g.mode == .survival, g.status == .playing {
            resume()
        } else {
            // Ein laufendes Einzelspiel zählt als aufgegeben, sonst ließe sich die Serie umgehen
            abandonRunning()
            startSurvivalWord()
        }
    }

    /// Nächstes Wort der Serie in der Stufe, die zum Stand passt
    func startSurvivalWord() {
        guard let run = survivalActive else { return }
        let language = preferences.wordLanguage
        let list = wordList(for: language)
        var rng = SplitMix64(seed: seedSource())
        let recent = data.recent[language.rawValue] ?? []
        guard let word = WordPicker.pick(from: list.words, category: nil, difficulty: run.nextDifficulty,
                                         recent: recent, rng: &rng) else {
            infoMeldung = String(localized: "Es gibt keine Wörter für diese Auswahl.")
            return
        }
        playingDaily = false
        playingParty = false
        newBestStreak = false
        newAchievements = []
        survivalBonus = false
        endReady = true
        data.recent[language.rawValue] = WordPicker.remember(word.solution, in: recent)
        data.game = Game(solution: word.solution, language: language, category: word.category,
                         difficulty: word.difficulty, mode: .survival, displayText: word.text)
        screen = .game
        persist()
    }

    /// Serie beenden (nach Rückfrage oder nach dem Ende); der Rekord bleibt
    func endSurvival() {
        data.survival = nil
        if data.game?.mode == .survival { data.game = nil }
        screen = .home
        persist()
    }

    /// „Nächstes Wort“ mit der gemerkten Auswahl.
    func nextWord() { startGame(category: data.lastCategory, difficulty: data.lastDifficulty, kids: data.lastKids) }

    // MARK: Mehrspieler (Party)

    var party: PartyMatch? { data.party }
    var partyNames: [String] { data.partyNames }

    func partyName(_ index: Int) -> String {
        guard let names = data.party?.names, names.indices.contains(index) else { return "" }
        return names[index]
    }

    /// Name des Raters der Runde, die auf dem Bildschirm ist (nach dem Ende der Runde ist `round` schon weitergezählt)
    var partyGuesserName: String {
        guard let match = data.party else { return "" }
        return partyName(match.step == .score ? match.lastGuesser : match.guesser)
    }

    /// „Runde 3 von 6“
    var partyRoundNumber: Int {
        guard let match = data.party else { return 0 }
        return min(match.totalRounds, match.step == .score ? match.round : match.round + 1)
    }

    /// Neue Partie (ersetzt eine laufende). Namen werden gemerkt.
    func startParty(names: [String], settings: PartySettings) {
        let clean = names.enumerated().map { i, name -> String in
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? String(localized: "Spieler \(i + 1)") : String(trimmed.prefix(20))
        }
        data.partyNames = clean
        data.party = PartyMatch(names: clean, settings: settings)
        playingDaily = false
        playingParty = false
        newBestStreak = false
        newAchievements = []
        endReady = true
        prepareRound()
        persist()
    }

    /// Nächste Runde vorbereiten: bei eigenen Wörtern zuerst zum Wortgeber, bei App-Wörtern ein Wort ziehen
    private func prepareRound() {
        guard var match = data.party, !match.isFinished else { return }
        match.game = nil
        if match.settings.ownWords {
            match.step = .giverHandover
        } else {
            let language = preferences.wordLanguage
            let list = wordList(for: language)
            var rng = SplitMix64(seed: seedSource())
            let recent = data.recent[language.rawValue] ?? []
            guard let word = WordPicker.pick(from: list.words, category: match.settings.category,
                                             difficulty: match.settings.difficulty, recent: recent, rng: &rng) else {
                infoMeldung = String(localized: "Es gibt keine Wörter für diese Auswahl.")
                data.party = nil
                screen = .home
                return
            }
            data.recent[language.rawValue] = WordPicker.remember(word.solution, in: recent)
            match.game = Game(solution: word.solution, language: language, category: word.category,
                              difficulty: word.difficulty, mode: .party, displayText: word.text)
            match.step = .guesserHandover
        }
        data.party = match
        screen = .party
    }

    /// Übergabe bestätigt: erst zur Eingabe des Wortgebers, dann zum Spiel des Raters
    func partyContinue() {
        guard var match = data.party else { return }
        switch match.step {
        case .giverHandover:
            match.step = .entry
        case .guesserHandover:
            match.step = .playing
            data.party = match
            playingParty = true
            endReady = true
            screen = .game
            persist()
            return
        default:
            return
        }
        data.party = match
        persist()
    }

    /// Der Wortgeber hat sein Wort (und den freien Hinweis) eingegeben
    func submitPartyWord(solution: String, hintText: String?) {
        guard var match = data.party else { return }
        let hint = hintText.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(WordInput.maxHintLength)) }
        match.game = Game(solution: solution, language: preferences.wordLanguage, mode: .party,
                          hintText: hint?.isEmpty == true ? nil : hint)
        match.step = .guesserHandover
        data.party = match
        persist()
    }

    /// Nach dem Zwischenstand: nächste Runde, nach der letzten die Rangliste
    func nextPartyRound() {
        playingParty = false
        guard var match = data.party else { screen = .home; return }
        if match.isFinished {
            match.game = nil
            data.party = match
            screen = .party
        } else {
            data.party = match
            prepareRound()
        }
        persist()
    }

    /// Partie fortsetzen (Karte auf dem Start): genau dort, wo sie war; ein laufendes Wort bleibt bis zur Übergabe verdeckt
    func resumeParty() {
        guard var match = data.party else { return }
        playingDaily = false
        playingParty = false
        if match.isFinished {
            screen = .party
        } else if match.step == .score, match.game != nil {
            playingParty = true
            endReady = true
            screen = .game
        } else {
            if match.step == .playing { match.step = .guesserHandover; data.party = match }
            screen = .party
        }
        persist()
    }

    /// „Partie beenden“ (nach Rückfrage): nichts zählt
    func endParty() {
        data.party = nil
        playingParty = false
        screen = .home
        persist()
    }

    /// „Revanche“: gleiche Spieler und Einstellungen
    func rematch() {
        guard let match = data.party else { return }
        startParty(names: match.names, settings: match.settings)
    }

    // MARK: Spielen

    @discardableResult
    func guess(_ input: String) -> GuessResult {
        guard var g = game else { return .over }
        let result = g.guess(input)
        commit(g, result: result)
        return result
    }

    @discardableResult
    func solve(_ input: String) -> SolveResult {
        guard var g = game else { return .over }
        let result = g.solve(input)
        switch result {
        case .solved: commit(g, result: .hit, isSolve: true)
        case .wrong: commit(g, result: .miss, isSolve: true)
        default: break
        }
        return result
    }

    @discardableResult
    func hint(_ kind: HintKind = .random) -> Character? {
        guard var g = game else { return nil }
        var rng = SplitMix64(seed: seedSource())
        let letter = g.hint(kind, using: &rng)
        if letter != nil { commit(g, result: .hit, isHint: true) }
        return letter
    }

    private func commit(_ new: Game, result: GuessResult, isHint: Bool = false, isSolve: Bool = false) {
        guard result == .hit || result == .miss, let old = game else { return }
        setGame(new)
        if old.status == .playing, new.status != .playing {
            switch new.mode {
            case .single:
                if let level = new.difficulty {
                    let bestBefore = data.stats.bestStreak
                    data.stats.record(new.status == .won
                        ? .won(difficulty: level, mistakes: new.mistakes, hints: new.hints.count)
                        : .lost(difficulty: level, mistakes: new.mistakes, hints: new.hints.count))
                    newBestStreak = data.stats.bestStreak > bestBefore && data.stats.bestStreak > 1
                    if new.status == .won { data.lastWinMistakes = new.mistakes }
                }
            case .daily:
                // Eigene Tagesstatistik; die normale Statistik zählt das Tageswort nicht
                if let day = data.daily[dailyLanguage.rawValue]?.day {
                    data.dailyStats.record(won: new.status == .won, day: day)
                }
            case .survival:
                if var run = data.survival {
                    survivalBonus = run.finishWord(won: new.status == .won, mistakes: new.mistakes, hints: new.hints.count)
                    data.survivalBest = max(data.survivalBest, run.wins)
                    data.survival = run
                }
            case .party:
                // Punkte und Zwischenstand; Party-Runden zählen nicht in Statistik und Sammlung
                data.party?.finishRound(won: new.status == .won, mistakes: new.mistakes, hints: new.hints.count)
            }
        }
        if old.status == .playing, new.status == .won, new.mode != .party { collect(new) }
        if old.status == .playing, new.status != .playing { unlockAchievements() }
        persist()
        feedback(old: old, new: new, result: result, isHint: isHint, isSolve: isSolve)
    }

    // MARK: Erfolge

    var achievements: Set<Achievement> { Set(data.achievements.compactMap(Achievement.init(rawValue:))) }

    private func unlockAchievements() {
        let earned = Achievement.newlyEarned(in: data)
        newAchievements = earned
        data.achievements += earned.map(\.rawValue)
    }

    // MARK: Wortsammlung

    /// Sieg in die Sammlung legen; wird dadurch eine Kategorie voll, merkt sich der Store die Feier (einmalig).
    private func collect(_ game: Game) {
        let key = game.language.rawValue
        let list = wordList(for: game.language)
        var items = data.collection[key] ?? []
        let before = WordCollection.progress(of: items, in: list)
        WordCollection.add(game.solution, to: &items)
        data.collection[key] = items
        let after = WordCollection.progress(of: items, in: list)
        for category in Category.allCases where after[category]?.isComplete == true && before[category]?.isComplete != true {
            var done = data.celebrated[key] ?? []
            guard !done.contains(category.rawValue) else { continue }
            done.append(category.rawValue)
            data.celebrated[key] = done
            pendingCelebration = category
        }
    }

    func collected(for language: WordLanguage) -> [String] { data.collection[language.rawValue] ?? [] }

    func progress(for language: WordLanguage) -> [Category: CategoryProgress] {
        WordCollection.progress(of: collected(for: language), in: wordList(for: language))
    }

    /// Die Feier läuft: Ton und Erfolgs-Haptik; danach ist sie erledigt
    func beginCelebration() {
        Sound.win.play()
        SpielHaptik.success()
    }

    func celebrationShown() { pendingCelebration = nil }

    // MARK: Spielgefühl (Werte aus Doku/DESIGN.md „Spielgefühl“)

    /// Abstand der Kacheln in der Aufdeck-Welle
    static let revealStep = 0.07

    /// Taste gedrückt (Finger runter): nur Haptik, bewusst kein Ton
    func keyPressed() { SpielHaptik.selection() }

    private func after(_ delay: Double, _ block: @escaping @MainActor () -> Void) {
        guard delay > 0 else { block(); return }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            block()
        }
    }

    private func feedback(old: Game, new: Game, result: GuessResult, isHint: Bool, isSolve: Bool) {
        let calm = calmMotion
        lastRevealWasHint = isHint
        var revealed = 0

        if isHint {
            Sound.hint.play(); SpielHaptik.tap()
        } else if result == .hit {
            // Stellen von links nach rechts: je Stelle ein Ton, der um 2 Halbtöne steigt (höchstens 5), Haptik höchstens 3
            revealed = max(1, old.hiddenCount - new.hiddenCount)
            let steps = calm ? 1 : min(revealed, 5)
            for k in 0..<steps {
                after(calm ? 0 : Double(k) * Self.revealStep) {
                    Sound.hit(step: k).play()
                    if k < 3 { SpielHaptik.tap() }
                }
            }
        } else {
            // Fehler: Plopp mit weichem Impuls; ein falsches Lösen lässt 2 Ballons nacheinander platzen
            for i in 0..<(isSolve ? Game.solvePenalty : 1) {
                after(calm ? 0 : Double(i) * 0.25) {
                    Sound.pop.play(); SpielHaptik.soft(staerke: 0.7)
                }
            }
        }

        switch new.status {
        case .won:
            after(calm ? 0 : Double(revealed) * Self.revealStep + 0.2) {
                Sound.win.play(); SpielHaptik.success()
            }
            holdEnd(seconds: 1.2 + Self.revealStep * Double(max(0, revealed - 3)), for: new)
        case .lost:
            after(calm ? 0 : 0.4) { Sound.lose.play() }
            holdEnd(seconds: 1.5, for: new)
        case .playing:
            break
        }
    }

    /// Der Ende-Bildschirm kommt erst nach dem großen Moment; bei „Bewegung reduzieren“ sofort.
    private func holdEnd(seconds: Double, for game: Game) {
        guard !calmMotion else { endReady = true; return }
        endReady = false
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            if self.game?.solution == game.solution { endReady = true }
        }
    }

    // MARK: Wort des Tages

    /// Tag erneuern (beim Zeigen des Starts und wenn die App wieder aktiv wird)
    func refreshToday() {
        let now = DayKey.string(for: clock())
        if now != today { today = now }
    }

    var now: Date { clock() }

    /// Das Tageswort von heute in der aktuellen Wortsprache; ein Eintrag von einem anderen Tag gilt als „noch nicht gespielt“
    var dailyToday: DailyEntry? {
        data.daily[preferences.wordLanguage.rawValue].flatMap { $0.day == today ? $0 : nil }
    }

    var dailyStats: DailyStats { data.dailyStats }
    var dailyStreak: Int { data.dailyStats.displayedStreak(today: today) }

    /// Das Wort von heute, noch ungespielt (für Kategorie und Länge auf der Start-Karte, nie das Wort selbst zeigen)
    var dailyPreview: Word? {
        DailyWord.word(day: today, in: wordList(for: preferences.wordLanguage).words)
    }

    /// Das Tageswort öffnen: ein neues starten, ein laufendes fortsetzen oder das Ergebnis zeigen (ein Versuch pro Tag)
    func openDaily() {
        refreshToday()
        let language = preferences.wordLanguage
        if dailyToday == nil {
            guard let word = DailyWord.word(day: today, in: wordList(for: language).words) else {
                infoMeldung = String(localized: "Es gibt keine Wörter für diese Auswahl.")
                return
            }
            data.daily[language.rawValue] = DailyEntry(
                day: today,
                game: Game(solution: word.solution, language: language, category: word.category,
                           difficulty: word.difficulty, mode: .daily, displayText: word.text))
        }
        dailyLanguage = language
        playingDaily = true
        playingParty = false
        newBestStreak = false
        newAchievements = []
        endReady = true
        screen = .game
        persist()
    }

    /// Tag des Tageswortes, das gerade auf dem Bildschirm ist
    var currentDailyDay: String? { playingDaily ? data.daily[dailyLanguage.rawValue]?.day : nil }

    /// Text zum Teilen (Sprache der App, nie das Wort); nil, solange das Tageswort läuft
    func dailyShareText(for entry: DailyEntry) -> String? {
        guard entry.game.status != .playing else { return nil }
        return DailyShare.text(day: entry.day, mistakes: entry.game.mistakes, hints: entry.game.hints.count,
                               won: entry.game.status == .won, appLanguage: .appLanguage)
    }

    /// Text zum Teilen für das Tageswort auf dem Bildschirm
    func dailyShareText() -> String? {
        guard playingDaily, let entry = data.daily[dailyLanguage.rawValue] else { return nil }
        return dailyShareText(for: entry)
    }

    // MARK: Navigation

    /// Zum Start. Ein laufendes Spiel bleibt erhalten („Weiter“), ein beendetes ist erledigt.
    func goHome() {
        if playingDaily {
            playingDaily = false            // das Tageswort bleibt gespeichert, auch beendet (Ergebnis wieder aufrufbar)
        } else if playingParty {
            playingParty = false            // die Partie bleibt gespeichert („Partie fortsetzen“ auf dem Start)
        } else if data.game?.status != .playing {
            data.game = nil
        }
        if data.survival?.isOver == true { data.survival = nil }
        screen = .home
        persist()
    }

    func resetStats() {
        data.stats = Stats()
        data.lastWinMistakes = nil
        persist()
    }

    /// Laufendes Einzelspiel verwerfen (Menü der Weiterspielen-Karte, mit Rückfrage im Baustein): zählt als aufgegeben
    func discardRunningGame() {
        guard data.game?.mode == .single else { return }
        abandonRunning()
        data.game = nil
        persist()
    }

    func resume() {
        guard data.game != nil else { return }
        playingDaily = false
        playingParty = false
        screen = .game
    }

    func appMovedToBackground() { persist() }

    // MARK: Intern

    private func abandonRunning() {
        if let g = data.game, g.status == .playing, g.mode == .survival, g.guessed.count + g.wrongSolves.count > 0,
           var run = data.survival {
            // Aufgeben mitten im Wort kostet ein Leben, sonst ließe sich jede Niederlage umgehen
            run.finishWord(won: false, mistakes: g.mistakes, hints: g.hints.count)
            data.survival = run
            return
        }
        guard let g = data.game, g.status == .playing, g.mode == .single, let level = g.difficulty else { return }
        data.stats.record(.abandoned(difficulty: level, guessedCount: g.guessed.count + g.wrongSolves.count))
    }

    private func persist() {
        TagesSerieWidget.melden(praefix: "galgen", serie: data.dailyStats.streak, letzterTag: data.dailyStats.lastWin)
        do {
            try repository.save(data)
        } catch {
            // Bei vollem Speicher nur einmal pro Sitzung melden, nicht nach jedem Buchstaben
            if !speicherfehlerGezeigt { speicherfehlerGezeigt = true; saveError = error.localizedDescription }
        }
    }
}
