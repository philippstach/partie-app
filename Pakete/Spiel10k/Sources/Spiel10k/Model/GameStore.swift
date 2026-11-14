// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import Observation

/// Neuer persönlicher Rekord eines Spielers (bester Zug über alle Spiele), kurz einblenden.
struct RecordNotice: Equatable {
    var player: Int
    var points: Int
    var previous: Int
}

/// Eine Niete, die gerade angezeigt wird (bereits verbucht).
struct NieteNotice: Equatable {
    var player: Int
    var lostPoints: Int
    var dice: [Int]
    var locked: [Bool]
    var penalty: Int
}

@Observable
final class GameStore {
    enum Screen { case home, setup, game }

    var screen: Screen = .home

    /// Das geöffnete Spiel. Jede Änderung wird sofort gespeichert.
    var game: GameState? { didSet { if !isLoading { persist() } } }
    /// Beim Öffnen eines Spiels nicht speichern (sonst ändern sich Datum und Reihenfolge).
    private var isLoading = false
    private(set) var currentID: UUID?
    private var currentName: String?
    private var currentCreatedAt = Date()

    /// Alle gespeicherten Spiele, neueste zuerst.
    private(set) var savedGames: [GameRecord] = []

    /// Beendete Spiele als Verlauf behalten?
    var keepFinishedGames: Bool {
        didSet { defaults.set(keepFinishedGames, forKey: Self.keepFinishedKey) }
    }

    /// Snapshots vor jedem eingetragenen Zug (nur Modus „echte Würfel“).
    private(set) var undoStack: [GameState] = []

    // Vorübergehende Einblendungen
    var nieteNotice: NieteNotice?
    /// „Stechen!“ – beim Start und bei jeder weiteren Stechrunde
    var tiebreakNotice: Tiebreak?
    var nextPlayerNotice: Int?
    /// Die Partie wurde gerade entschieden → Siegerseite feiert einmal (nicht beim Öffnen alter Spiele)
    var celebrationPending = false
    /// „Neuer persönlicher Rekord“ – nur für Spieler mit mindestens einem beendeten Spiel
    var recordNotice: RecordNotice?
    /// Kurzer Hinweis auf der Startseite nach „Pausieren“
    var pausedNotice = false
    /// Per Wischen gelöschtes Spiel, das noch rückgängig gemacht werden kann (Datei existiert noch)
    private(set) var pendingDeletion: GameRecord?
    private var deletionTask: Task<Void, Never>?
    /// So lange bleibt „Rückgängig“ stehen, danach wird die Datei gelöscht (vorläufig 5 s)
    var deletionDelay: Duration = .seconds(5)
    /// Speichern ist fehlgeschlagen (z. B. Gerät voll) – einmal anzeigen
    var saveError: String?
    /// Zählt Würfe hoch, damit die Oberfläche animieren kann.
    private(set) var rollCount = 0
    /// Zählt „alle Würfel punkten – mit allen weiter“ (Hot Dice) hoch, für den eigenen Moment in der Oberfläche
    private(set) var hotDiceCount = 0
    /// Positionen der Würfel, die im letzten Wurf geworfen wurden (für die Lande-Animation)
    private(set) var lastThrown: [Int] = []

    var roller: () -> Int = { Int.random(in: 1...6) }

    private let repository: GameRepository
    private let defaults: UserDefaults
    private static let setupKey = "tenk.lastSetup.v1"
    private static let keepFinishedKey = "tenk.keepFinishedGames"
    private static let statsKey = "tenk.stats.v1"
    private static let knownKey = "tenk.knownPlayers.v1"

    /// Bekannte Personen für Vorschläge im Setup (Emoji und Farbe der letzten Wahl)
    private(set) var knownPlayers = KnownPlayers()

    /// Kurzfassungen aller beendeten Spiele (Statistik über alle Spiele)
    private(set) var summaries: [GameSummary] = []
    var hallOfFame: HallOfFame { HallOfFame(summaries: summaries) }

    init(repository: GameRepository = FileGameRepository(), defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
        keepFinishedGames = defaults.object(forKey: Self.keepFinishedKey) as? Bool ?? true
        LegacyMigration.run(defaults: defaults, repository: repository)
        savedGames = repository.loadAll()
        loadSummaries()
        loadKnownPlayers()
    }

    // MARK: - Bekannte Personen

    private func loadKnownPlayers() {
        if let data = defaults.data(forKey: Self.knownKey),
           let list = try? JSONDecoder().decode(KnownPlayers.self, from: data) {
            knownPlayers = list
        } else {
            // Erster Start mit 1.0.1: aus Statistik und gespeicherten Spielen befüllen
            knownPlayers = KnownPlayers.seeded(summaries: summaries, games: savedGames)
            saveKnownPlayers()
        }
        knownPlayers.merge(shared: Quelle10k.lesen())
    }

    private func saveKnownPlayers() {
        if let data = try? JSONEncoder().encode(knownPlayers) {
            defaults.set(data, forKey: Self.knownKey)
        }
    }

    /// „Aus Vorschlägen entfernen“ – die Statistik bleibt
    func forgetKnownPlayer(_ name: String) {
        knownPlayers.remove(PlayerName.key(name))
        saveKnownPlayers()
    }

    /// „Vorschläge zurücksetzen“ – die Statistik bleibt
    func resetKnownPlayers() {
        knownPlayers.removeAll()
        saveKnownPlayers()
    }

    // MARK: - Statistik über alle Spiele

    private func loadSummaries() {
        if let data = defaults.data(forKey: Self.statsKey),
           let list = try? JSONDecoder().decode([GameSummary].self, from: data) {
            summaries = list
        }
        // Einmalig bzw. ergänzend: beendete Spiele aus dem Verlauf übernehmen
        let known = Set(summaries.map(\.id))
        let missing = savedGames.filter { $0.state.finished && !known.contains($0.id) }
        guard !missing.isEmpty else { return }
        summaries += missing.map { GameSummary(id: $0.id, date: $0.updatedAt, game: $0.state) }
        saveSummaries()
    }

    #if DEBUG
    /// Nur für Screenshots: Statistik durch eine erfundene Vorgeschichte ersetzen
    func debugReplaceSummaries(_ list: [GameSummary]) {
        summaries = list
        saveSummaries()
    }
    #endif

    private func saveSummaries() {
        if let data = try? JSONEncoder().encode(summaries) {
            defaults.set(data, forKey: Self.statsKey)
        }
    }

    /// Hält die Statistik zum Spielstand passend: entschieden → aufnehmen, nach Rückgängig wieder raus.
    private func updateSummary(_ game: GameState, id: UUID) {
        let index = summaries.firstIndex { $0.id == id }
        switch (game.finished, index) {
        case (true, nil):
            summaries.append(GameSummary(id: id, date: Date(), game: game))
            saveSummaries()
        case (false, let i?):
            summaries.remove(at: i)
            saveSummaries()
        default:
            break
        }
    }

    // MARK: - Gespeicherte Spiele

    var pausedGames: [GameRecord] { savedGames.filter { !$0.state.finished } }
    var finishedGames: [GameRecord] { savedGames.filter { $0.state.finished } }

    func resume(_ id: UUID) {
        guard let record = savedGames.first(where: { $0.id == id }) else { return }
        undoStack = []
        nieteNotice = nil
        nextPlayerNotice = nil
        celebrationPending = false
        recordNotice = nil
        currentID = record.id
        currentName = record.name
        currentCreatedAt = record.createdAt
        isLoading = true
        game = record.state
        isLoading = false
        screen = .game
    }

    /// Spiel unterbrechen: zurück zum Start, mit kurzem Hinweis „Spiel gespeichert“.
    func pauseGame() {
        let paused = game.map { !$0.finished } ?? false
        closeGame()
        pausedNotice = paused
    }

    /// Spiel schließen (bleibt gespeichert) und zurück zum Start.
    func closeGame() {
        game = nil
        currentID = nil
        currentName = nil
        undoStack = []
        nieteNotice = nil
        nextPlayerNotice = nil
        celebrationPending = false
        recordNotice = nil
        screen = .home
    }

    func deleteGame(_ id: UUID) {
        try? repository.delete(id: id)
        savedGames.removeAll { $0.id == id }
        if id == currentID { closeGame() }
    }

    /// Löschen mit „Rückgängig“: sofort aus der Liste, die Datei erst nach `deletionDelay`.
    func deleteGameWithUndo(_ id: UUID) {
        guard let record = savedGames.first(where: { $0.id == id }) else { return }
        commitPendingDeletion()
        savedGames.removeAll { $0.id == id }
        if id == currentID { closeGame() }
        pendingDeletion = record
        let delay = deletionDelay
        deletionTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.commitPendingDeletion()
        }
    }

    func undoDeletion() {
        guard let record = pendingDeletion else { return }
        deletionTask?.cancel()
        deletionTask = nil
        pendingDeletion = nil
        savedGames.append(record)
        savedGames.sort { $0.updatedAt > $1.updatedAt }
    }

    /// Löscht die Datei endgültig – nach Ablauf, beim nächsten Löschen oder wenn die App in den Hintergrund geht.
    func commitPendingDeletion() {
        deletionTask?.cancel()
        deletionTask = nil
        guard let record = pendingDeletion else { return }
        pendingDeletion = nil
        try? repository.delete(id: record.id)
    }

    func renameGame(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard var record = savedGames.first(where: { $0.id == id }) else { return }
        record.name = trimmed.isEmpty ? nil : trimmed
        if id == currentID { currentName = record.name }
        store(record)
    }

    // MARK: - Spielstart

    func startGame(players: [Player], settings: GameSettings) {
        undoStack = []
        nieteNotice = nil
        celebrationPending = false
        recordNotice = nil
        currentID = UUID()
        currentName = nil
        currentCreatedAt = Date()
        game = GameState(players: players, settings: settings)
        saveLastSetup(players: players, settings: settings)
        knownPlayers.record(players)
        Quelle10k.melden?(players.filter { !$0.isComputer }.map(\.name))
        saveKnownPlayers()
        nextPlayerNotice = settings.nextPlayerOverlay ? 0 : nil
        screen = .game
    }

    /// Gleiche Spieler & Einstellungen, Punkte auf 0. Das beendete Spiel bleibt im Verlauf.
    /// `order`: dieselben Spieler in der gewünschten Reihenfolge (Standard: wie eben).
    func rematch(order: [Player]? = nil, settings: GameSettings? = nil) {
        guard let g = game else { return }
        let players = (order ?? g.players).map { Player(name: $0.name, avatar: $0.avatar, colorIndex: $0.colorIndex) }
        startGame(players: players, settings: settings ?? g.settings)
    }

    /// Einstellungen des laufenden Spiels ändern (Töne, Vibration, Tipp …).
    func updateSettings(_ change: (inout GameSettings) -> Void) {
        guard var g = game else { return }
        change(&g.settings)
        game = g
    }

    // MARK: - Zustand für die Oberfläche

    var turn: DiceTurn { game?.turn ?? DiceTurn() }
    /// Drilling-Regel des laufenden Spiels
    var triples: TripleRule { game?.settings.rules.triples ?? .all }
    /// Wertungsregeln des laufenden Spiels (Drillinge, Würfelzahl, Straße)
    var scoringRules: ScoringRules { game?.settings.rules.scoring ?? .standard }
    /// Punkte der aktuellen Auswahl (nil = ungültig/leer)
    var selectionScore: Int? { turn.selectionScore(scoringRules) }
    /// Punkte des Zugs inklusive aktueller Auswahl
    var turnTotal: Int { turn.total(scoringRules) }
    /// Tipp: punktbeste Auswahl im aktuellen Wurf
    var bestSelection: Set<Int> { turn.bestSelection(scoringRules) }

    /// Positionen der aktuell ausgewählten Würfel
    var selection: [Int] { turn.dice.indices.filter { turn.selected[$0] } }

    var canRoll: Bool {
        guard let g = game, !g.finished, g.offer == nil else { return false }
        return !g.turn.hasRolled || g.turn.selectionScore(g.settings.rules.scoring) != nil
    }

    var canEndTurn: Bool {
        guard let g = game, !g.finished, g.offer == nil else { return false }
        guard g.turn.hasRolled, let sel = g.turn.selectionScore(g.settings.rules.scoring) else { return false }
        return g.turn.banked + sel >= g.entryNeeded
    }

    /// Eingabeart (echte Würfel) nur zwischen den Zügen wechseln – nicht mitten im Zug.
    var canSwitchEntry: Bool {
        guard let g = game, !g.finished else { return false }
        return !g.turn.hasRolled && g.turn.banked == 0 && g.offer == nil
    }

    /// Rausgelegt-Eingabe: Punkte für diese Würfel als ein Wurf, `nil` = zählt nicht / zu viele.
    func keptScore(_ dice: [Int]) -> Int? {
        let t = turn
        guard !dice.isEmpty, dice.count <= t.openCount else { return nil }
        return Scoring.score(dice, fullThrow: t.keptFullThrow, rules: scoringRules)
    }

    /// Anzahl der Würfel, deren Augen beim nächsten Wurf eingegeben werden.
    var diceToEnter: Int { turn.nextRollCount }

    /// Auswahl im aktuellen Wurf – nur Anzeige, keine Aktion (online später „presence“).
    func toggleDie(_ i: Int) {
        guard var g = game, g.turn.hasRolled, !g.turn.locked[i] else { return }
        g.turn.selected[i].toggle()
        game = g
        play(.select)
    }

    /// Punktbeste Auswahl im aktuellen Wurf vorauswählen (nur Anzeige, wie `toggleDie`).
    func selectBest() {
        guard var g = game, g.turn.hasRolled, g.offer == nil else { return }
        let best = g.turn.bestSelection(g.settings.rules.scoring)
        g.turn.selected = g.turn.dice.indices.map { best.contains($0) }
        game = g
    }

    /// Auswahl im aktuellen Wurf zurücksetzen.
    func clearSelection() {
        guard var g = game, g.turn.selected.contains(true) else { return }
        g.turn.selected = g.turn.noneFlags
        game = g
    }

    // MARK: - Computergegner

    /// Ist gerade ein Computergegner am Zug? (Nur mit App-Würfeln.)
    var botAmZug: Bool {
        guard let g = game, !g.finished, g.settings.diceMode == .digital, g.players.indices.contains(g.current),
              botPauseBei != g.log.count else { return false }
        return g.players[g.current].isComputer
    }

    /// Notausgang: Findet der Computer keinen Zug (sollte nie passieren), übernimmt der Mensch, statt dass die Eingabe gesperrt bleibt.
    /// Gilt bis zum nächsten Logeintrag.
    private var botPauseBei: Int?

    /// Ändert sich, wenn der Computer etwas tun soll (Auslöser für den Antrieb in der Oberfläche).
    var botSchluessel: String {
        guard let g = game else { return "-" }
        return "\(g.current)|\(g.turn.hasRolled)|\(g.turn.banked)|\(g.turn.dice)|\(g.turn.selected)|\(g.offer != nil)|\(g.log.count)|\(rollCount)|\(nieteNotice != nil)|\(tiebreakNotice != nil)|\(g.finished)"
    }

    /// Ein Schritt des Computers: Angebot annehmen/ablehnen, würfeln, Auswahl zeigen, dann rauslegen/aufhören.
    /// Jeder Schritt ändert den Spielstand und löst damit den nächsten über `botSchluessel` aus.
    func computerSchritt() {
        guard botAmZug, nieteNotice == nil, tiebreakNotice == nil, let g = game,
              let level = g.players[g.current].computer else { return }
        if let offer = g.offer {
            if ComputerPlayer.accept(offer: offer, rules: g.settings.rules, level: level) { acceptOffer() } else { declineOffer() }
            return
        }
        if !g.turn.hasRolled {
            perform(.roll(keep: []))
            return
        }
        guard let move = ComputerPlayer.decide(turn: g.turn, rules: g.settings.rules, level: level,
                                               score: g.players[g.current].score, goal: g.settings.goal) else {
            botPauseBei = g.log.count
            return
        }
        let keep: [Int]
        switch move {
        case .roll(let k), .bank(let k): keep = k
        }
        // Erst die Auswahl zeigen, im nächsten Schritt ausführen
        let flags = g.turn.dice.indices.map { keep.contains($0) }
        if g.turn.selected != flags {
            var next = g
            next.turn.selected = flags
            game = next
            return
        }
        switch move {
        case .roll(let k): perform(.roll(keep: k))
        case .bank(let k):
            // Einstiegshürde: noch nicht genug Punkte zum Aufhören → weiterwürfeln
            if canEndTurn { perform(.bank(keep: k)) } else { perform(.roll(keep: k)) }
        }
    }

    // MARK: - Aktionen

    /// Führt einen Spielzug aus. Alle Änderungen am Spielstand laufen hier durch.
    func perform(_ action: GameAction) {
        guard let g = game, Self.allowed(action, in: g.settings.diceMode) else { return }
        switch action {
        case .roll(let keep): throwDice(keep: keep, values: nil)
        case .enterThrow(let keep, let dice): throwDice(keep: keep, values: dice)
        case .bank(let keep): bank(keep: keep)
        case .layOut(let dice, let bank): layOutAction(dice, bank: bank)
        case .acceptOffer: acceptOfferAction()
        case .declineOffer: declineOfferAction()
        case .points(let points, let leaveOpen): pointsAction(points, leaveOpen: leaveOpen)
        case .noPoints: noPointsAction()
        case .undo: undoAction()
        }
    }

    /// Welche Aktionen der Würfelmodus zulässt (wie der Server, Doku/MEHRSPIELER-PLAN.md §5):
    /// Würfeln nur digital, Augen und Punkte eintragen nur bei echten Würfeln.
    static func allowed(_ action: GameAction, in mode: DiceMode) -> Bool {
        switch action {
        case .roll: mode == .digital
        case .enterThrow, .layOut, .points, .noPoints: mode == .real
        case .bank, .acceptOffer, .declineOffer, .undo: true
        }
    }

    // Kurzformen für die Oberfläche: nehmen die aktuelle Auswahl als `keep`.
    func roll() { perform(.roll(keep: selection)) }
    func enterThrow(_ dice: [Int]) { perform(.enterThrow(keep: selection, dice: dice)) }
    func endTurn() { perform(.bank(keep: selection)) }
    /// Rausgelegt-Eingabe: diese Würfel rauslegen und weiterwürfeln bzw. aufhören
    func layOut(_ dice: [Int], bank: Bool) { perform(.layOut(dice: dice, bank: bank)) }
    func acceptOffer() { perform(.acceptOffer) }
    func declineOffer() { perform(.declineOffer) }
    func submitPoints(_ points: Int, leaveOpen: Int = 0) { perform(.points(points, leaveOpen: leaveOpen)) }
    func submitNoPoints() { perform(.noPoints) }
    func undo() { perform(.undo) }

    static func isValidEntry(_ points: Int) -> Bool { points > 0 && points % 50 == 0 }

    /// Rückgängig gibt es für abgeschlossene Züge und Übernahme-Entscheidungen.
    /// Bei digitalen Würfeln nie über einen neuen Wurf hinweg – das wäre Neu-Würfeln.
    var canUndo: Bool { !undoStack.isEmpty }

    // MARK: - Aktionen im Einzelnen

    /// Setzt `keep` als Auswahl im Zug; `false`, wenn sie ungültig ist.
    private func apply(keep: [Int], to t: inout DiceTurn) -> Bool {
        guard keep.allSatisfy({ t.dice.indices.contains($0) && !t.locked[$0] }) else { return false }
        t.selected = t.dice.indices.map { keep.contains($0) }
        return true
    }

    private func throwDice(keep: [Int], values: [Int]?) {
        guard var g = game, !g.finished, g.offer == nil else { return }
        var t = g.turn

        if t.hasRolled {
            // Auswahl sichern und rauslegen
            guard apply(keep: keep, to: &t), let points = t.selectionScore(g.settings.rules.scoring) else { return }
            t.banked += points
            for i in t.dice.indices where t.selected[i] { t.locked[i] = true }
            t.selected = t.noneFlags
            // Alle rausgelegt → mit allen weiter
            if t.locked.allSatisfy({ $0 }) {
                t.locked = t.noneFlags
                hotDice(g.settings)
            }
        } else if !keep.isEmpty {
            return
        }

        // Erster Wurf nach einer Übernahme zählt nie als voller Wurf (keine Straße) – auch mit allen 5.
        let firstInheritedThrow = !t.hasRolled && t.inheritedFrom != nil
        let free = t.dice.indices.filter { !t.locked[$0] }
        if let values {
            // Echte Würfel: eingegebene Augen, Tippfehler lassen sich rückgängig machen
            guard values.count == free.count, values.allSatisfy((1...6).contains) else { return }
            pushUndo(g)
            for (i, v) in zip(free, values) { t.dice[i] = v }
        } else {
            // Digital: kein Rückgängig über einen neuen Wurf hinweg
            undoStack.removeAll()
            for i in free { t.dice[i] = roller() }
        }
        t.fullThrow = free.count == t.count && !firstInheritedThrow
        lastThrown = free
        t.hasRolled = true
        rollCount += 1

        let rolled = free.map { t.dice[$0] }
        g.zaehleAugen(rolled, echt: values != nil)   // Blatt 22 (EB2, Schritt 2)
        if Scoring.canScore(rolled, rules: g.settings.rules.scoring, fullThrow: t.fullThrow) {
            // F21-009: „Punkte-Würfel vorauswählen“ gleich im selben Schritt wie der Wurf setzen (digital). Vorher kam die Auswahl erst
            // als zweite Änderung nach dem Wurf; „Weiter (N)“ und „Aufhören“ blieben dabei mit alter Auswahl gesperrt.
            if values == nil, g.settings.preselectsBest {
                let best = t.bestSelection(g.settings.rules.scoring)
                t.selected = t.dice.indices.map { best.contains($0) }
            }
            g.turn = t
            game = g
            play(.roll)
            SpielHaptik.tap()
        } else {
            let player = g.current
            let outcome = finishTurn(&g, points: 0)
            nieteNotice = NieteNotice(player: player, lostPoints: t.banked, dice: t.dice, locked: t.locked, penalty: outcome.penalty)
            game = g
            playNiete(g, penalty: outcome.penalty)
            announce(outcome)
        }
    }

    private func bank(keep: [Int]) {
        guard var g = game, !g.finished, g.offer == nil, g.turn.hasRolled else { return }
        var t = g.turn
        guard apply(keep: keep, to: &t), let selection = t.selectionScore(g.settings.rules.scoring) else { return }
        let total = t.banked + selection
        guard total >= g.entryNeeded else { return }
        pushUndo(g)
        var kept = t.dice.indices.map { t.locked[$0] || t.selected[$0] }
        let allOut = !kept.contains(false)
        // Alle 5 rausgelegt → der Nächste darf mit allen 5 übernehmen (wenn die Regel das vorsieht).
        if allOut { kept = t.noneFlags }
        let from = g.current

        let outcome = finishTurn(&g, points: total)
        if outcome.offerAllowed && (!allOut || g.settings.rules.inheritAllFive) {
            g.offer = InheritOffer(from: from, points: total, dice: t.dice, kept: kept)
        }
        game = g
        play(g.finished ? .win : .bank)
        SpielHaptik.success()
        announce(outcome)
    }

    /// Rausgelegt-Eingabe: `dice` sind die Augen der Würfel, die aus dem aktuellen Wurf rausgelegt werden.
    /// Gewertet wird genau diese Auswahl als ein Wurf. Danach weiterwürfeln oder (`bank`) aufhören.
    private func layOutAction(_ dice: [Int], bank: Bool) {
        guard var g = game, !g.finished, g.offer == nil else { return }
        var t = g.turn
        let free = t.dice.indices.filter { !t.locked[$0] }
        guard !dice.isEmpty, dice.count <= free.count, dice.allSatisfy((1...6).contains) else { return }
        let full = t.keptFullThrow
        guard let points = Scoring.score(dice, fullThrow: full, rules: g.settings.rules.scoring) else { return }
        guard !bank || t.banked + points >= g.entryNeeded else { return }
        pushUndo(g)
        for (i, v) in zip(free, dice) {
            t.dice[i] = v
            t.locked[i] = true
        }
        t.selected = t.noneFlags
        t.hasRolled = false
        t.fullThrow = full
        t.banked += points
        t.keptThrows += 1
        rollCount += 1

        guard bank else {
            // Alle rausgelegt → mit allen weiter
            if t.locked.allSatisfy({ $0 }) {
                t.locked = t.noneFlags
                hotDice(g.settings)
            } else {
                play(.select)
            }
            g.turn = t
            game = g
            SpielHaptik.tap()
            return
        }
        let total = t.banked
        var kept = t.locked
        let allOut = !kept.contains(false)
        if allOut { kept = t.noneFlags }
        let from = g.current
        let outcome = finishTurn(&g, points: total)
        if outcome.offerAllowed && (!allOut || g.settings.rules.inheritAllFive) {
            g.offer = InheritOffer(from: from, points: total, dice: t.dice, kept: kept)
        }
        game = g
        play(g.finished ? .win : .bank)
        SpielHaptik.success()
        announce(outcome)
    }

    private func acceptOfferAction() {
        guard var g = game, let offer = g.offer else { return }
        g.offer = nil
        // Mit der Würfelzahl des Angebots anlegen – sonst hätte `selected` die Standardlänge 5
        var t = DiceTurn(count: offer.dice.count)
        t.dice = offer.dice
        t.locked = offer.kept
        t.banked = offer.points
        t.inheritedFrom = offer.from
        t.inheritedPoints = offer.points
        g.turn = t
        game = g
        // Digital würfelt die App sofort; bei Augen-Eingabe trägt der Spieler den Wurf ein.
        if g.settings.diceMode == .digital { throwDice(keep: [], values: nil) }
    }

    private func declineOfferAction() {
        guard let g = game, g.offer != nil else { return }
        pushUndo(g)
        game?.offer = nil
    }

    /// Punkte-Eingabe: Nach dem Übernehmen zählen die übernommenen Punkte einmal plus die eingetippten.
    /// 1.0.1 (8): Jede Eintragung (> 0) bietet der nächsten Person die Punkte zum Übernehmen an –
    /// ohne Würfelangabe (Augen 0, alle offen), am Tisch wird echt gewürfelt. `leaveOpen` (1.0.1 (7))
    /// wird noch gelesen, aber nicht mehr ausgewertet.
    /// Steht noch ein Angebot, gilt Eintragen als „nicht übernommen“ (wie `noPoints`; vorläufig).
    private func pointsAction(_ points: Int, leaveOpen _: Int) {
        guard Self.isValidEntry(points), var g = game, !g.finished else { return }
        let count = g.settings.rules.diceCount
        let total = (g.turn.inheritedFrom == nil ? 0 : g.turn.inheritedPoints) + points
        guard total >= g.entryNeeded else { return }
        pushUndo(g)
        let from = g.current
        let outcome = finishTurn(&g, points: total)
        if outcome.offerAllowed {
            g.offer = InheritOffer(from: from, points: total, dice: Array(repeating: 0, count: count),
                                   kept: Array(repeating: false, count: count))
        }
        game = g
        play(g.finished ? .win : .bank)
        SpielHaptik.success()
        announce(outcome)
    }

    private func noPointsAction() {
        guard var g = game, !g.finished else { return }
        pushUndo(g)
        let player = g.current
        let outcome = finishTurn(&g, points: 0)
        game = g
        playNiete(g, penalty: outcome.penalty)
        if outcome.penalty > 0 {
            nieteNotice = NieteNotice(player: player, lostPoints: 0, dice: [], locked: [], penalty: outcome.penalty)
        }
        announce(outcome)
    }

    private func undoAction() {
        guard let last = undoStack.popLast() else { return }
        nieteNotice = nil
        tiebreakNotice = nil
        nextPlayerNotice = nil
        celebrationPending = false
        recordNotice = nil
        game = last
    }

    // MARK: - Intern

    struct TurnOutcome {
        var penalty = 0
        /// Darf der Nächste übernehmen? (nicht über Stechen-Grenzen hinweg)
        var offerAllowed = false
        /// Ein Stechen (oder eine weitere Stechrunde) hat gerade begonnen.
        var tiebreakStarted = false
    }

    /// Verbucht den Zug des aktuellen Spielers, prüft Sieg, Runden-Limit und Stechen und gibt weiter.
    @discardableResult
    private func finishTurn(_ g: inout GameState, points: Int) -> TurnOutcome {
        let i = g.current
        var p = g.players[i]
        var outcome = TurnOutcome()

        p.turns += 1
        if points > 0 {
            // Persönlicher Rekord: besser als alle früheren Spiele und als dieses Spiel bisher
            if let earlier = HallOfFame.personalBestTurn(p.name, in: summaries, excluding: currentID) {
                let best = max(earlier, p.bestTurn)
                if points > best { recordNotice = RecordNotice(player: i, points: points, previous: best) }
            }
            p.score += points
            p.streak = 0
            p.bestTurn = max(p.bestTurn, points)
        } else {
            p.nieten += 1
            // Im Stechen gibt es keine Strafe (und die Serie läuft nicht weiter).
            if g.tiebreak == nil {
                p.streak += 1
                if p.streak >= 3 {
                    outcome.penalty = g.settings.penalty
                    p.score -= outcome.penalty
                    p.streak = 0
                }
            }
        }
        g.players[i] = p
        g.log.append(TurnRecord(player: i, points: points, penalty: outcome.penalty, inheritedFrom: g.turn.inheritedFrom))
        g.timeline.append(g.players.map(\.score))
        g.turn = DiceTurn(count: g.settings.rules.diceCount)
        g.offer = nil

        if var tb = g.tiebreak {
            // Stechen: nur die Beteiligten, Entscheidung am Ende jeder Stechrunde
            tb.points.append(points)
            if let next = tb.nextPlayer {
                g.current = next
                outcome.offerAllowed = true
            } else {
                let best = tb.points.max() ?? 0
                let leaders = zip(tb.players, tb.points).filter { $0.1 == best }.map(\.0)
                if leaders.count == 1 {
                    g.winners = leaders
                } else {
                    tb = Tiebreak(players: leaders, round: tb.round + 1)
                    g.current = leaders[0]
                    outcome.tiebreakStarted = true
                }
            }
            g.tiebreak = tb
        } else if g.finalRoundFrom != nil || (g.settings.rules.finalRound && p.score >= g.settings.goal) {
            // Faire Schlussrunde: die Runde zu Ende spielen, dann gewinnt, wer vorne liegt
            if g.finalRoundFrom == nil { g.finalRoundFrom = i }
            if g.log.count % g.players.count == 0 {
                decideByLeaders(&g, &outcome)
            } else {
                g.current = (i + 1) % g.players.count
                outcome.offerAllowed = true
            }
        } else if p.score >= g.settings.goal {
            g.winners = [i]
        } else if g.settings.roundLimit > 0 && g.log.count >= g.settings.roundLimit * g.players.count {
            decideByLeaders(&g, &outcome)
        } else {
            g.current = (i + 1) % g.players.count
            outcome.offerAllowed = true
        }
        if g.current == i { outcome.offerAllowed = false }   // Allein (oder nur noch eine Person im Stechen): niemand, dem man Würfel anbieten könnte
        if g.finished {
            outcome.offerAllowed = false
            celebrationPending = true
        }
        return outcome
    }

    /// Ende nach Punkten (Rundenlimit, Schlussrunde): ein Führender gewinnt, sonst Stechen bzw. gemeinsamer Sieg.
    private func decideByLeaders(_ g: inout GameState, _ outcome: inout TurnOutcome) {
        let top = g.players.map(\.score).max() ?? 0
        let leaders = g.players.indices.filter { g.players[$0].score == top }
        if leaders.count == 1 || !g.settings.rules.tiebreak {
            g.winners = leaders          // ohne Stechen-Regel: gemeinsamer Sieg
        } else {
            g.tiebreak = Tiebreak(players: leaders)
            g.current = leaders[0]
            outcome.tiebreakStarted = true
        }
    }

    private func announce(_ outcome: TurnOutcome) {
        if outcome.tiebreakStarted { tiebreakNotice = game?.tiebreak }
        announceNextPlayer()
    }

    private func announceNextPlayer() {
        guard let g = game, !g.finished, g.settings.nextPlayerOverlay else { return }
        nextPlayerNotice = g.current
    }

    private func pushUndo(_ g: GameState) {
        undoStack.append(g)
        if undoStack.count > 50 { undoStack.removeFirst() }
    }

    /// Eigener Moment für „alle Würfel punkten“
    private func hotDice(_ settings: GameSettings) {
        hotDiceCount += 1
        play(.hotdice)
        SpielHaptik.success()
    }

    /// Niete-Ton; greift die Strafe nach 3 Nieten, folgt nach kurzer Pause der „Fail“-Ton (Doku/FAIL-TON.md).
    private func playNiete(_ g: GameState, penalty: Int) {
        if g.finished {
            play(.win)
            SpielHaptik.error()
            return
        }
        play(.niete)
        SpielHaptik.error()
        guard penalty > 0 else { return }
        play(.fail, after: Self.failDelay)
        SpielHaptik.penalty(after: Self.failDelay)
    }

    /// Niete-Ton (ca. 0,45 s) plus ca. 0,3 s Pause – vorläufig
    static let failDelay = 0.6

    /// Zuletzt ausgelöster Ton (auch wenn der Ton der Sammlung aus ist) – für Tests
    private(set) var lastSound: Sound?

    private func play(_ sound: Sound, after delay: Double = 0) {
        lastSound = sound
        guard game != nil else { return }
        guard delay > 0 else { return sound.play() }
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { sound.play() }
    }

    private func persist() {
        guard let game, let id = currentID else { return }
        updateSummary(game, id: id)
        if game.finished && !keepFinishedGames {
            try? repository.delete(id: id)
            savedGames.removeAll { $0.id == id }
            return
        }
        store(GameRecord(id: id, name: currentName, createdAt: currentCreatedAt, updatedAt: Date(), state: game))
    }

    private func store(_ record: GameRecord) {
        do {
            try repository.save(record)
        } catch {
            saveError = String(localized: "Der Spielstand konnte nicht gespeichert werden. Ist der Speicher des Geräts voll? Das Spiel läuft weiter, geht beim Beenden der App aber eventuell verloren.")
        }
        savedGames.removeAll { $0.id == record.id }
        savedGames.insert(record, at: 0)
        savedGames.sort { $0.updatedAt > $1.updatedAt }
    }

    // MARK: - Letzte Einrichtung merken

    struct SavedSetup: Codable {
        var players: [Player]
        var settings: GameSettings
    }

    /// Die Regeln der zuletzt gespielten Einrichtung (für „Frag nach den Regeln“ im Rahmen), ohne einen Store anzulegen.
    nonisolated static func gespeicherteRegeln(defaults: UserDefaults = .standard) -> GameRules? {
        defaults.data(forKey: setupKey).flatMap { try? JSONDecoder().decode(SavedSetup.self, from: $0) }?.settings.rules
    }

    var lastSetup: SavedSetup? {
        defaults.data(forKey: Self.setupKey).flatMap { try? JSONDecoder().decode(SavedSetup.self, from: $0) }
    }

    private func saveLastSetup(players: [Player], settings: GameSettings) {
        let clean = players.map { p -> Player in
            var c = Player(name: p.name, avatar: p.avatar, colorIndex: p.colorIndex)
            c.computer = p.computer   // sonst wird aus dem Computer beim nächsten „Neues Spiel“ ein Mensch (N-12)
            return c
        }
        if let data = try? JSONEncoder().encode(SavedSetup(players: clean, settings: settings)) {
            defaults.set(data, forKey: Self.setupKey)
        }
    }
}
