// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation
import SwiftUI
import KlarGlas
import SpieleKern

/// Alles, was gespeichert wird. Fehlende Felder beim Laden → Standardwert.
struct SaveFile<State: SolitaireState>: Codable {
    static var currentVersion: Int { 1 }
    var version = SaveFile.currentVersion
    var state: State
    var deal: DealInfo
    var history: [State] = []
    var elapsed: Double = 0
    var recentSeeds: [UInt64] = []
    /// Fürs Tagesziel: Rückgängig bzw. Tipp in dieser Partie benutzt (alte Spielstände: false)
    var undoUsed = false
    var hintUsed = false
    /// Aufgegeben (die Partie ist zu Ende, die Lösung darf angesehen werden)
    var gaveUp = false

    init(state: State, deal: DealInfo, history: [State], elapsed: Double, recentSeeds: [UInt64] = [],
         undoUsed: Bool = false, hintUsed: Bool = false, gaveUp: Bool = false) {
        self.state = state; self.deal = deal; self.history = history; self.elapsed = elapsed; self.recentSeeds = recentSeeds
        self.undoUsed = undoUsed; self.hintUsed = hintUsed; self.gaveUp = gaveUp
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        state = try c.decode(State.self, forKey: .state)
        deal = try c.decodeIfPresent(DealInfo.self, forKey: .deal) ?? DealInfo(seed: 1, mode: .klondike(1), kind: .random)
        history = try c.decodeIfPresent([State].self, forKey: .history) ?? []
        elapsed = try c.decodeIfPresent(Double.self, forKey: .elapsed) ?? 0
        recentSeeds = try c.decodeIfPresent([UInt64].self, forKey: .recentSeeds) ?? []
        undoUsed = try c.decodeIfPresent(Bool.self, forKey: .undoUsed) ?? false
        hintUsed = try c.decodeIfPresent(Bool.self, forKey: .hintUsed) ?? false
        gaveUp = try c.decodeIfPresent(Bool.self, forKey: .gaveUp) ?? false
    }
    private enum Key: String, CodingKey { case version, state, deal, history, elapsed, recentSeeds, undoUsed, hintUsed, gaveUp }
}

/// Schreibt Spielstände im Hintergrund, atomar; das Neueste gewinnt.
actor SaveWriter {
    private let newest = NewestGeneration()

    nonisolated func nextGeneration() -> Int { newest.next() }

    /// Kodiert und schreibt im Hintergrund (nicht auf dem Haupt-Thread)
    func write<State: SolitaireState>(_ file: SaveFile<State>, to url: URL, generation: Int) -> String? {
        guard generation >= newest.value else { return nil }   // ein neuerer Stand wartet schon
        do {
            try JSONEncoder().encode(file).write(to: url, options: .atomic)
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}

private final class NewestGeneration: @unchecked Sendable {
    private let lock = NSLock()
    private var current = 0
    var value: Int { lock.withLock { current } }
    func next() -> Int { lock.withLock { current += 1; return current } }
}

/// Schwebender Text („+15“), `id` macht jede neue Anzeige zu einem eigenen Ereignis
struct Popup: Equatable {
    var id: Int
    var text: String
    var pile: Pile
}

/// Kurzer Gold-Schimmer an einem Ort
struct PlaceShimmer: Equatable {
    var id: Int
    var pile: Pile
}

/// Kurzer Hinweis über dem Tisch (TriPeaks: „Lange Kette“), 1,5 s lang
struct Toast: Equatable {
    var id: Int
    var text: String
}

/// Hinweis „max. N“ an einer Stelle des Tisches
struct LimitNote: Equatable {
    var max: Int
    var at: CGPoint
}

/// Einmalige Hinweise für Erstspieler
enum FirstHint: String, CaseIterable {
    case tap, recycle, stuck
    /// Beim ersten Öffnen jedes Spiels ein Satz zum Ziel
    case goalKlondike, goalSpider, goalFreecell, goalPyramid, goalTripeaks, goalGolf, goalYukon

    static func goal(_ kind: GameKind) -> FirstHint {
        switch kind {
        case .klondike: .goalKlondike
        case .spider: .goalSpider
        case .freecell: .goalFreecell
        case .pyramid: .goalPyramid
        case .tripeaks: .goalTripeaks
        case .golf: .goalGolf
        case .yukon: .goalYukon
        }
    }

    var text: LocalizedStringKey {
        switch self {
        case .goalKlondike: "Ziel: Alle Karten nach Farben von Ass bis König auf die vier Ziele legen."
        case .goalSpider: "Ziel: Reihen von König bis Ass in einer Farbe bilden – sie wandern von selbst ab."
        case .goalFreecell: "Ziel: Alle Karten nach Farben von Ass bis König auf die Ziele legen. Die Zellen parken Karten."
        case .goalPyramid: "Ziel: Paare entfernen, die zusammen 13 ergeben. Ein König geht allein."
        case .goalTripeaks: "Ziel: Karten auf die Ablage legen, die einen Wert höher oder niedriger sind."
        case .goalGolf: "Ziel: Die obersten Spaltenkarten auf die Ablage legen – einen Wert höher oder tiefer. Auf einen König geht nichts."
        case .goalYukon: "Ziel: Alle Karten nach Farben von Ass bis König auf die Ziele legen. Jede offene Karte darfst du samt allem darauf verschieben."
        case .tap: "Tippe eine Karte an – sie springt an den besten Platz. Du kannst sie auch ziehen."
        case .recycle: "Tippe auf den leeren Stapel, um die Ablage umzudrehen."
        case .stuck: "Nicht weiter? „Tipp“ zeigt dir einen Zug, „Zurück“ nimmt Züge zurück."
        }
    }
}

/// Alles, was die gemeinsamen Ansichten (Kopfzeile, Leiste, Sieg, Menü) vom laufenden Spiel brauchen –
/// unabhängig von der Variante. `GameStore<R>` setzt das für jede Variante um.
@MainActor
protocol GameSession: AnyObject {
    var mode: GameMode { get }
    var deal: DealInfo { get }
    var isWon: Bool { get }
    var moves: Int { get }
    var displayScore: Int? { get }
    var scoreText: String? { get }
    var scoreNegative: Bool { get }
    var timeBonus: Int { get }
    var elapsed: TimeInterval { get }
    func elapsed(at date: Date) -> TimeInterval
    var canUndo: Bool { get }
    var canFinish: Bool { get }
    var stuck: Bool { get }
    var stuckDismissed: Bool { get set }
    var justWon: Bool { get }
    var activeFirstHint: FirstHint? { get }
    var saveError: String? { get set }
    var onEvent: ((GameEvent) -> Void)? { get set }

    /// Aufgeben und Lösung ansehen (SPEZIFIKATION-EXTRAS §3)
    var gaveUp: Bool { get }
    var solutionAvailable: Bool { get }
    var solutionViewed: Bool { get }
    var replaying: Bool { get }
    var solutionIndex: Int { get }
    var solutionCount: Int { get }
    var solutionPaused: Bool { get }
    func giveUp()
    func viewSolution()
    func solutionStep(_ delta: Int)
    func toggleSolutionPause()
    func endSolution()

    func undo()
    func autoFinish()
    func showHint()
    func pauseClock()
    func resumeClock()
    /// Wartet, bis der letzte Spielstand geschrieben ist (beim Wechsel in den Hintergrund)
    func settleSaves() async
    func scheduleStartHints()
    func dismissFirstHint()
    /// Neue Partie im selben Modus
    func newGame()
    func restartSameDeal()
    func start(_ info: DealInfo)
#if DEBUG
    /// Nur Debug (`-testZustand`): bringt die Partie über die gespeicherte Lösung einer lösbaren Partie kurz vor den Sieg (`ende`: letzter Zug folgt gleich).
    func testZustand(ende: Bool)
#endif
}

@MainActor
@Observable
final class GameStore<R: SolitaireRules>: GameSession {
    static var maxHistory: Int { 2000 }
    /// Beim Speichern nur die letzten Zustände behalten (kleinere Dateien, weniger Schreiblast); im Speicher gelten 2000
    static var maxSavedHistory: Int { 300 }

    let mode: GameMode
    private(set) var state: R.State
    private(set) var deal: DealInfo
    private(set) var history: [R.State] = []
    private(set) var elapsed: TimeInterval = 0
    private(set) var recentSeeds: [UInt64] = []
    private(set) var undoUsed = false
    private(set) var hintUsed = false
    private(set) var gaveUp = false
    /// Lösung wird abgespielt (Tisch gesperrt, Automatik aus)
    private(set) var replaying = false
    private(set) var solutionViewed = false
    private(set) var solutionMoves: [Move] = []
    private(set) var solutionIndex = 0
    private(set) var solutionPaused = false
    @ObservationIgnored private var replayTask: Task<Void, Never>?
    /// Läuft die Uhr? (Zeitpunkt des Starts; gerechnet wird mit der Betriebszeit, damit eine umgestellte Geräteuhr die Spielzeit nicht verfälscht)
    private(set) var runningSince: Date?
    private var runningUptime: TimeInterval = 0
    private static var uptime: TimeInterval { ProcessInfo.processInfo.systemUptime }
    private func startClock() { runningSince = Date(); runningUptime = Self.uptime }

    /// Anzeige: Tipp, festgefahren, Austeilen
    private(set) var hint: Move?
    private(set) var hintShown = 0
    private(set) var moveStyle = MoveStyle.normal
    private(set) var activeFirstHint: FirstHint?
    private(set) var stuck = false
    /// Gerade live gewonnen (für den Wasserfall); beim Laden eines gewonnenen Spiels bleibt es false
    var justWon = false
    var stuckDismissed = false
    private(set) var dealing = false
    private(set) var showsPreDeal = false
    /// Zähler je Karte bzw. Zielstapel, damit Wackeln und Aufleuchten als Ereignis ausgelöst werden
    private(set) var shakes: [Int: Int] = [:]
    private(set) var flashes: [Int: Int] = [:]
    /// Gold-Schimmer über einem Ziel (Ass aufs leere Ziel), je Ziel ein Zähler
    private(set) var shimmers: [Int: Int] = [:]
    /// Zählt, wie oft das Austeilen übersprungen wurde (die Karten springen dann ohne Animation an ihren Platz)
    private(set) var dealSkips = 0
    /// Austeilen nicht möglich (Spider, leere Spalte): Stapel wackelt, leere Spalten blinken gold
    private(set) var stockWiggle = 0
    private(set) var blinkEmptyColumns = false
    /// „max. N“ über einer zu langen Reihe (FreeCell-Supermove), 1 s lang
    private(set) var limitNote: LimitNote?
    /// Gewählte Karte (Pyramid: der nächste Tipp auf einen Partner entfernt das Paar)
    private(set) var selected: Pile?
    /// Schwebender Bonus-Text (TriPeaks)
    private(set) var popup: Popup?
    private(set) var toast: Toast?
    /// Gold-Schimmer an einer leer geräumten Stelle (Golf: Spalte)
    private(set) var placeShimmer: PlaceShimmer?
    /// Zeitbonus der gewonnenen Partie (Klondike Standard), sonst 0
    private(set) var timeBonus = 0
    var saveError: String?
    /// Wird bei Beginn, Sieg und Verlassen einer Partie gerufen
    @ObservationIgnored var onEvent: ((GameEvent) -> Void)?

    let prefs: AppPreferences
    private let url: URL?
    private var pending: [Move] = []
    @ObservationIgnored private var lastTap: (card: CardID, at: Date, moved: Bool)?
    private var autoTask: Task<Void, Never>?
    private var hintTask: Task<Void, Never>?
    @ObservationIgnored private let writer = SaveWriter()
    @ObservationIgnored private var lastSave: Task<Void, Never>?
    @ObservationIgnored private var firstHintTask: Task<Void, Never>?
    @ObservationIgnored private var chainHaptics = true
    @ObservationIgnored private var chainIndex = 0
    @ObservationIgnored private var stepHaptic = true
    @ObservationIgnored private var chainStyle = MoveStyle.normal

    /// `url == nil`: nichts speichern (Tests, Demo). Mit `seed` startet sofort diese Partie.
    init(mode: GameMode, prefs: AppPreferences = AppPreferences(), seed: UInt64? = nil, url: URL?) {
        self.mode = mode
        self.prefs = prefs
        self.url = url
        if seed == nil, let url, let data = try? Data(contentsOf: url),
           let file = try? JSONDecoder().decode(SaveFile<R.State>.self, from: data), file.deal.mode == mode {
            state = file.state
            deal = file.deal
            history = file.history
            elapsed = file.elapsed
            recentSeeds = file.recentSeeds
            undoUsed = file.undoUsed
            hintUsed = file.hintUsed
            gaveUp = file.gaveUp
        } else {
            // Spielstand da, aber unlesbar oder für einen anderen Modus: erst eine Kopie daneben, dann neu austeilen
            if seed == nil, let url { DefectBackup.preserve(url) }
            let info = Self.makeDealInfo(mode: mode, prefs: prefs, seed: seed)
            deal = info
            state = R.prepare(R.deal(seed: info.seed, mode: mode), prefs: prefs, kind: info.kind)
        }
        updateStuck()
    }

    // MARK: Abfragen

    var isWon: Bool { state.isWon && !gaveUp }
    var solutionAvailable: Bool { SolutionLibrary.hasSolution(for: deal) }
    var solutionCount: Int { solutionMoves.count }
    var moves: Int { state.moves }
    var displayScore: Int? { state.displayScore }
    var scoreText: String? { state.scoreText }
    var scoreNegative: Bool { state.scoreNegative }
    var canUndo: Bool { !history.isEmpty && !isWon && !gaveUp }
    var canFinish: Bool { pending.isEmpty && !gaveUp && R.canAutoFinish(state) }

    func elapsed(at date: Date) -> TimeInterval {
        elapsed + (runningSince == nil ? 0 : max(0, Self.uptime - runningUptime))
    }

    // MARK: Neue Partie

    private static func makeDealInfo(mode: GameMode, prefs: AppPreferences, seed: UInt64?, recent: [UInt64] = []) -> DealInfo {
        if let seed { return DealInfo(seed: seed, mode: mode, kind: .random) }
        var rng = SystemRandomNumberGenerator()
        if prefs.solvableDeals || mode.kind == .freecell, let s = DealCatalog.shared.pick(mode: mode, level: prefs.difficulty, recent: recent, using: &rng) {
            return DealInfo(seed: s, mode: mode, kind: .solvable)
        }
        return DealInfo(seed: UInt64.random(in: 0...UInt64.max, using: &rng), mode: mode, kind: .random)
    }

    func newGame() { start(Self.makeDealInfo(mode: mode, prefs: prefs, seed: nil, recent: recentSeeds)) }

    func restartSameDeal() { start(deal) }

    func start(_ info: DealInfo) {
        flush()
        endReplayTask()
        selected = nil
        popup = nil
        placeShimmer = nil
        if state.moves > 0 || startedEmitted, !state.isWon, !gaveUp { emitAbandoned() }
        startedEmitted = false
        gaveUp = false
        replaying = false
        solutionViewed = false
        justWon = false
        deal = info
        if info.kind == .solvable { recentSeeds = Array((recentSeeds + [info.seed]).suffix(DealCatalog.recentLimit)) }
        state = R.prepare(R.deal(seed: info.seed, mode: mode), prefs: prefs, kind: info.kind)
        timeBonus = 0
        history = []
        elapsed = 0
        undoUsed = false
        hintUsed = false
        runningSince = nil
        hint = nil
        stuckDismissed = false
        updateStuck()
        save()
        // Austeilen: erst alles auf den Stapel legen, dann fliegen die Karten einzeln
        showsPreDeal = true
        dealing = true
        Sound.shuffle.play(volume: 0.5)
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(60))
            self?.showsPreDeal = false
            try? await Task.sleep(for: .milliseconds(1500))
            self?.dealing = false
        }
    }

    /// Partie verlassen oder aufgegeben: zählt als verloren; bei Vegas fortlaufend geht der Vegas-Stand der Partie in den Gesamtstand
    private func emitAbandoned() {
        if let dollars = state.accountDollars { onEvent?(.account(deal, dollars)) }
        onEvent?(.abandoned(deal))
    }

    /// Antippen während des Austeilens: sofort zum Ende springen
    func skipDeal() {
        guard dealing else { return }
        dealing = false
        showsPreDeal = false
        dealSkips += 1
    }

    /// Nur für Demo: Verlauf setzen, damit „Zurück“ im Foto aktiv ist
    func setDemoHistory(_ states: [R.State]) { history = states }

    /// Nur für Demo: Zeitbonus der Gewonnen-Karte setzen
    func setDemoTimeBonus(_ bonus: Int) { timeBonus = bonus }

    /// Nur für Demo: gespielte Zeit setzen
    func setDemoElapsed(_ seconds: TimeInterval) { elapsed = seconds; runningSince = nil }

    /// Nur für Demo und Tests: Zustand direkt setzen.
    func load(state: R.State, deal: DealInfo? = nil, hint: Move? = nil) {
        flush()
        dealing = false
        showsPreDeal = false
        self.state = state
        selected = nil
        popup = nil
        if let deal { self.deal = deal }
        self.hint = hint
        history = []
        updateStuck()
    }

    // MARK: Spielerzüge

    @discardableResult
    func perform(_ move: Move, style: MoveStyle = .normal) -> Bool {
        flush()
        guard !gaveUp, let next = R.apply(state, move) else { return false }
        selected = nil
        moveStyle = style
        activeFirstHint = nil
        pushHistory()
        // Automatische Züge gehören zum selben Schritt: erst die Kette merken, dann einmal speichern, wenn sie durch ist
        let auto = next.isWon ? [] : R.autoMoves(next, autoFoundation: prefs.autoFoundation)
        pending = auto
        stepHaptic = true
        apply(next, move: move)
        run(auto, every: .milliseconds(110), haptics: true, style: R.autoMoveStyle)
        return true
    }

    /// Antippen einer Karte: bester Zug oder Wackeln
    func tap(card: CardID, source: CardSource?) {
        flush()
        hint = nil
        guard !isWon, !gaveUp else { return }
        if R.usesSelection, let source {
            tapSelecting(card: card, source: source)
            return
        }
        // Doppeltipp (zweiter Tipp auf dieselbe Karte binnen 0,35 s): aufs Ziel, wenn möglich; sonst nichts weiter bewegen
        let now = Date()
        if let last = lastTap, last.card == card, last.moved, now.timeIntervalSince(last.at) < 0.35 {
            lastTap = nil
            if let source, let move = R.foundationMove(state, from: source.pile, count: source.count) { perform(move) }
            return
        }
        if let source, let move = R.tapTarget(state, from: source.pile, count: source.count) {
            perform(move)
            lastTap = (card, now, true)
        } else {
            shake(card)
            lastTap = (card, now, false)
        }
    }

    /// Pyramid: König und Karte mit genau einem Partner gehen sofort; sonst wählen, dann Partner antippen
    private func tapSelecting(card: CardID, source: CardSource) {
        if let sel = selected {
            if sel == source.pile { selected = nil; return }
            if let move = R.pairMove(state, sel, source.pile) { perform(move); return }
        }
        if let move = R.tapTarget(state, from: source.pile, count: source.count) {
            perform(move)
        } else {
            selected = source.pile
            SpielHaptik.select()
        }
    }

    func drawStock() {
        guard !gaveUp else { return }
        let style: MoveStyle = state.stockCount == 0 ? .recycle : .draw
        if !perform(.draw, style: style) {
            if let message = R.drawBlockedMessage(state) { showToast(message) }
            SpielHaptik.warning()
            Sound.invalid.play()
            stockWiggle += 1
            blinkEmptyColumns = true
            Task { [weak self] in
                try? await Task.sleep(for: .milliseconds(700))
                self?.blinkEmptyColumns = false
            }
        }
    }

    /// Gold-Kapsel über dem Tisch für 1,5 s
    func showToast(_ text: String) {
        let id = (toast?.id ?? 0) + 1
        toast = Toast(id: id, text: text)
        Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1500))
            if self?.toast?.id == id { self?.toast = nil }
        }
    }

    func showLimit(_ max: Int, at point: CGPoint) {
        limitNote = LimitNote(max: max, at: point)
        SpielHaptik.soft()
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            self?.limitNote = nil
        }
    }

    func shake(_ card: CardID) {
        shakes[card.number, default: 0] += 1
        Sound.invalid.play()
        SpielHaptik.warning()
    }

    func undo() {
        flush()
        guard canUndo, !gaveUp, let previous = history.popLast() else { return }
        selected = nil
        popup = nil
        moveStyle = .undo
        undoUsed = true
        state = previous
        hint = nil
        stuckDismissed = false
        updateStuck()
        save()
        SpielHaptik.tap()
    }

    func autoFinish() {
        flush()
        guard !gaveUp, R.canAutoFinish(state) else { return }
        pushHistory()
        moveStyle = .finish
        run(R.autoFinishMoves(state), every: .milliseconds(80), haptics: false, style: .finish)
    }

    func showHint() {
        guard !gaveUp else { return }
        flush()
        hint = R.hint(state)
        // Kein Tipp, aber noch Züge möglich (FreeCell, Yukon): das sagen – „Keine sinnvollen Züge mehr“ gibt es nur bei festgefahren
        if hint == nil, !state.isWon, !R.isStuck(state) { showToast(String(localized: "Kein Tipp gefunden")) }
        hintUsed = true       // fürs Tagesziel „ohne Tipp“: sofort speichern, damit ein Neustart nichts vergisst
        save()
        hintShown += 1
        hintTask?.cancel()
        hintTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(3.5))
            if !Task.isCancelled { self?.hint = nil }
        }
    }

    // MARK: Aufgeben und Lösung ansehen

    /// Aufgeben zählt als verloren (die Serie endet). Danach lässt sich bei lösbaren Partien die Lösung ansehen.
    func giveUp() {
        flush()
        guard !gaveUp, !state.isWon else { return }
        if state.moves > 0 { emitAbandoned() }
        pauseClock()
        gaveUp = true
        selected = nil
        hint = nil
        stuckDismissed = false
        stuck = false
        activeFirstHint = nil
        save()
        SpielHaptik.soft()
    }

    /// Spielt die gespeicherte Lösung von der Startaufstellung ab: genau diese Züge, Automatik aus, 0,45 s je Zug
    func viewSolution() {
        guard gaveUp, !replaying, let text = SolutionLibrary.text(for: deal), let moves = R.solutionMoves(from: text) else { return }
        flush()
        solutionMoves = moves
        solutionIndex = 0
        solutionPaused = false
        replaying = true
        moveStyle = .undo
        stateBeforeReplay = state
        state = R.deal(seed: deal.seed, mode: mode)
        startReplayTask()
    }

    private func startReplayTask() {
        endReplayTask()
        guard !solutionPaused, solutionIndex < solutionMoves.count else { return }
        replayTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.replaying, !self.solutionPaused, self.solutionIndex < self.solutionMoves.count {
                try? await Task.sleep(for: .milliseconds(450))
                if Task.isCancelled { return }
                self.replayForward()
            }
        }
    }

    private func endReplayTask() { replayTask?.cancel(); replayTask = nil }

    private func replayForward() {
        guard replaying, solutionIndex < solutionMoves.count else { return }
        let m = solutionMoves[solutionIndex]
        guard let next = R.apply(state, m) else { solutionPaused = true; return }
        moveStyle = .normal
        feedback(before: state, after: next, move: m, haptic: false)
        state = next
        solutionIndex += 1
        if solutionIndex >= solutionMoves.count { solutionPaused = true }
    }

    /// Schritt vor (+1) oder zurück (−1); die Wiedergabe pausiert dabei
    func solutionStep(_ delta: Int) {
        guard replaying else { return }
        endReplayTask()
        solutionPaused = true
        if delta > 0 {
            replayForward()
            solutionPaused = true
        } else if solutionIndex > 0 {
            // Rückwärts: von der Startaufstellung bis zum vorherigen Zug neu aufbauen (genau und billig)
            var s = R.deal(seed: deal.seed, mode: mode)
            for m in solutionMoves.prefix(solutionIndex - 1) { if let n = R.apply(s, m) { s = n } }
            moveStyle = .undo
            state = s
            solutionIndex -= 1
        }
    }

    func toggleSolutionPause() {
        guard replaying else { return }
        if solutionIndex >= solutionMoves.count {
            // Am Ende: noch einmal von vorn
            solutionIndex = 0
            moveStyle = .undo
            state = R.deal(seed: deal.seed, mode: mode)
            solutionPaused = false
            startReplayTask()
            return
        }
        solutionPaused.toggle()
        if solutionPaused { endReplayTask() } else { startReplayTask() }
    }

    /// „Fertig“: Abspielen beenden. Die Partie bleibt zu Ende; weiter mit Neues Spiel oder Gleiche Partie neu.
    func endSolution() {
        endReplayTask()
        replaying = false
        // Der aufgegebene Tisch kommt zurück, damit nicht der abgespielte (gelöste) Stand gespeichert wird
        if let vorher = stateBeforeReplay { moveStyle = .undo; state = vorher; stateBeforeReplay = nil }
        solutionViewed = true
    }

    // MARK: Erstspieler-Hinweise

    /// Zeigt einen Hinweis, falls er noch nie gezeigt wurde; verschwindet nach 6 s oder beim nächsten Zug.
    func showFirstHint(_ hint: FirstHint) {
        guard !prefs.seenHints.contains(hint.rawValue), activeFirstHint == nil else { return }
        prefs.seenHints.insert(hint.rawValue)
        activeFirstHint = hint
        firstHintTask?.cancel()
        firstHintTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            if !Task.isCancelled { self?.activeFirstHint = nil }
        }
    }

    func dismissFirstHint() { activeFirstHint = nil }

    /// Beim Start: erster Hinweis nach 2 s, bei 45 s ohne Zug der dritte.
    func scheduleStartHints() {
        // Satz zum Ziel beim ersten Öffnen dieses Spiels (erst nach der Willkommens-Karte)
        if prefs.welcomeSeen, !prefs.seenHints.contains(FirstHint.goal(R.kind).rawValue) {
            Task { [weak self] in
                try? await Task.sleep(for: .seconds(1))
                guard let self, self.state.moves == 0, !self.gaveUp else { return }
                self.showFirstHint(.goal(R.kind))
            }
        }
        guard prefs.welcomeSeen, !R.tapOnly, !prefs.seenHints.contains(FirstHint.tap.rawValue) else { return }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard let self, self.state.moves == 0 else { return }
            self.showFirstHint(.tap)
            try? await Task.sleep(for: .seconds(43))
            if self.state.moves == 0 { self.activeFirstHint = nil; self.showFirstHint(.stuck) }
        }
    }

    // MARK: Zeit

    func pauseClock() {
        guard runningSince != nil else { return }
        elapsed += max(0, Self.uptime - runningUptime)
        runningSince = nil
        save()
    }

    func resumeClock() {
        // Nach dem Aufgeben und beim Ansehen der Lösung läuft die Uhr nicht mehr (auch nicht nach Menü oder Hintergrund)
        guard runningSince == nil, state.moves > 0, !isWon, !gaveUp, !replaying else { return }
        startClock()
    }

    // MARK: Innenleben

    /// „Gespielt“ nur einmal pro Partie zählen, auch wenn man bis zur Startaufstellung zurücknimmt und neu beginnt
    private var startedEmitted = false

    /// Stand des aufgegebenen Tisches, solange die Lösung abgespielt wird
    private var stateBeforeReplay: R.State?

    private func pushHistory() {
        history.append(state)
        if history.count > Self.maxHistory { history.removeFirst(history.count - Self.maxHistory) }
    }

    private func apply(_ next: R.State, move: Move) {
        let before = state
        state = next
        hint = nil
        stuckDismissed = false
        if before.moves == 0, next.moves > 0, !startedEmitted { startedEmitted = true; onEvent?(.started(deal)) }
        if runningSince == nil, !isWon, !gaveUp, !replaying { startClock() }
        feedback(before: before, after: next, move: move, haptic: stepHaptic)
        if next.chainLength >= 10, next.chainLength > before.chainLength { onEvent?(.chain(deal, next.chainLength)) }
        if let cleared = R.clearedPile(before, next, move) { placeShimmer = PlaceShimmer(id: (placeShimmer?.id ?? 0) + 1, pile: cleared) }
        if let bonus = R.bonusPopup(before, next, move) {
            popup = Popup(id: (popup?.id ?? 0) + 1, text: bonus.text, pile: bonus.pile)
        }
        if next.isWon {
            pauseClock()
            SpielHaptik.success()
            Sound.win.play()
            justWon = true
            let bonus = R.timeBonus(next, seconds: Int(elapsed))
            timeBonus = bonus
            if let dollars = next.accountDollars { onEvent?(.account(deal, dollars)) }
            onEvent?(.won(deal, moves: next.moves, score: next.recordScore.map { $0 + bonus }, seconds: elapsed, undoUsed: undoUsed, hintUsed: hintUsed))
        }
        if next.needsRecycle, next.moves > 0 { showFirstHint(.recycle) }
        if pending.isEmpty {
            updateStuck()
            save()
        }
    }

    private func feedback(before: R.State, after: R.State, move: Move, haptic: Bool) {
        let haptics = haptic && !replaying
        let volume: Float? = replaying ? 0.25 : nil          // beim Abspielen der Lösung halb so laut, ohne Haptik
        switch move {
        case .draw:
            (before.stockCount == 0 ? Sound.shuffle : Sound.draw).play(volume: volume)
            if before.stockCount == 0 { SpielHaptik.tap(enabled: haptics) }
        case let .move(from, to, count):
            if case let .foundation(f) = to, R.movingCards(before, from: from, count: count)?.first?.rank == 1 {
                shimmers[f, default: 0] += 1
            }
            if after.revealedColumns > before.revealedColumns { SpielHaptik.soft(enabled: haptics) }
            if R.usesSelection {
                // Pyramid: Paar entfernt
                Sound.foundation.play(volume: volume)
                SpielHaptik.tap(enabled: haptics)
            } else if case let .foundation(f) = to {
                flashes[f, default: 0] += 1
                if after.completedFoundations > before.completedFoundations {
                    Sound.complete.play(volume: volume)
                    SpielHaptik.medium(enabled: haptics)
                } else {
                    Sound.foundation.play(volume: volume)
                    SpielHaptik.tap(enabled: haptics)
                }
            } else {
                Sound.place.play(volume: volume, pitch: R.soundPitch(after))
                if after.completedFoundations > before.completedFoundations { SpielHaptik.medium(enabled: haptics) }
                else { SpielHaptik.tap(enabled: haptics) }
            }
            if after.hiddenCardCount < before.hiddenCardCount { Sound.flip.play(volume: volume) }
        }
    }

    /// Kette automatischer Züge. `haptics`: nur die erste Karte der Kette gibt Haptik (Auto-Ablegen), bei „Fertig spielen“ keine.
    private func run(_ moves: [Move], every delay: Duration, haptics: Bool, style: MoveStyle = .normal) {
        guard !moves.isEmpty else { return }
        pending = moves
        chainHaptics = haptics
        chainStyle = style
        chainIndex = 0
        autoTask = Task { [weak self] in
            while let self, !self.pending.isEmpty {
                try? await Task.sleep(for: delay)
                if Task.isCancelled { return }
                self.stepPending()
            }
        }
    }

    private func stepPending() {
        let move = pending.removeFirst()
        stepHaptic = chainHaptics && chainIndex == 0
        moveStyle = chainStyle
        chainIndex += 1
        if let next = R.apply(state, move) { apply(next, move: move) }
        else if pending.isEmpty { save() }
    }

    /// Laufende automatische Züge sofort zu Ende führen (neue Eingabe wartet nicht).
    func flush() {
        autoTask?.cancel()
        while !pending.isEmpty { stepPending() }
    }

    private func updateStuck() {
        let was = stuck
        stuck = pending.isEmpty && !state.isWon && !gaveUp && R.isStuck(state)
        if stuck, !was { SpielHaptik.soft() }
    }

    /// Für Tests: wartet, bis der letzte Spielstand geschrieben ist.
    func settleSaves() async { await lastSave?.value }

    private func save() {
        // Beim Ansehen der Lösung bleibt der Spielstand vom Aufgeben stehen (der abgespielte Zwischenstand ist kein Spielstand)
        guard let url, !replaying else { return }
        let file = SaveFile(state: state, deal: deal, history: Array(history.suffix(Self.maxSavedHistory)), elapsed: elapsed(at: Date()), recentSeeds: recentSeeds,
                            undoUsed: undoUsed, hintUsed: hintUsed, gaveUp: gaveUp)
        let generation = writer.nextGeneration()
        let writer = writer
        lastSave = Task { [weak self] in
            if let message = await writer.write(file, to: url, generation: generation) { self?.saveError = message }
        }
    }
}

#if DEBUG
extension GameStore {
    /// Nur Debug (`-testZustand`): Eine lösbare Partie mit gespeicherter Lösung (fester Zufall); alle Züge der Lösung bis auf die letzten
    /// werden mit den Regeln gespielt. `ende`: nur der letzte Zug bleibt, er wird als normaler Zug gespielt (Sieg, Wasserfall, Ende-Karte).
    func testZustand(ende: Bool) {
        var rng = SplitMix64(seed: 11)
        guard let seed = DealCatalog.shared.pick(mode: mode, level: 1, recent: [], using: &rng) else { return }
        let info = DealInfo(seed: seed, mode: mode, kind: .solvable)
        start(info)
        guard let text = SolutionLibrary.text(for: info), let zuege = R.solutionMoves(from: text), zuege.count > 3 else { return }
        let offen = ende ? 1 : 3
        var s = state
        for m in zuege.dropLast(offen) { if let n = R.apply(s, m) { s = n } }
        state = s
        history = []
        save()
        if ende, let letzter = zuege.last { perform(letzter); flush() }
    }
}
#endif
