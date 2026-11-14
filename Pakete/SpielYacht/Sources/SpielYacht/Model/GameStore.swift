// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

nonisolated enum Screen: Equatable, Sendable { case home, setup, game }

/// Hält alle Spiele, führt Aktionen aus und speichert nach jeder Aktion.
@Observable
final class GameStore {
    private(set) var records: [GameRecord] = []
    var screen = Screen.home
    private(set) var currentID: UUID?
    /// Spieler, der gerade „dran“ gekommen ist (für das kurze Einblenden), sonst nil
    var nextPlayerNotice: Int?
    var saveError: String?
    /// Kurze Bestätigung auf der Startseite nach „Pausieren“
    var pausedNotice = false
    /// Zuletzt benutzte Spieler und Regeln fürs nächste Setup
    private(set) var lastSetup: (players: [Player], settings: GameSettings)?

    @ObservationIgnored let repository: GameRepository
    /// Würfelquelle; in Tests ersetzbar.
    @ObservationIgnored var roller: () -> Int = { Int.random(in: 1...6) }

    init(repository: GameRepository = FileGameRepository()) {
        self.repository = repository
        records = repository.loadAll()
        if let last = records.first {
            lastSetup = (last.players.map { var p = $0; p.id = UUID(); return p }, last.settings)
        }
    }

    /// Nur „Yacht“: Stufe des Computers (bei „mittel“ patzt er ab und zu).
    @ObservationIgnored var neuStufe: ComputerStufe?

    // MARK: Lesen

    /// „Yacht“: Ist die Partie noch unberührt (Wertung und Regeln änderbar)?
    var vorErstemZug: Bool {
        guard let g = game else { return false }
        return g.state.rollsUsed == 0 && g.state.players.allSatisfy { $0.scores.isEmpty } && !g.finished
    }

    /// „Yacht“: Wertung und Regeln ändern, solange noch nichts eingetragen ist. Baut dieselbe Partie neu auf.
    @discardableResult
    func regelnVorStart(_ rules: Rules) -> Bool {
        guard var r = game, vorErstemZug else { return false }
        r.settings.rules = rules
        r.state = GameState(playerNames: r.players.map(\.name), rules: rules)
        r.timeline = [Array(repeating: 0, count: r.players.count)]
        r.held = []; r.undo = nil; r.preRoll = nil
        commit(r)
        return true
    }

    var game: GameRecord? { records.first { $0.id == currentID } }
    var pausedGames: [GameRecord] { records.filter { !$0.finished } }
    var finishedGames: [GameRecord] { records.filter(\.finished) }
    /// Nur eigene Züge zurücknehmen: ein Computerzug würde sonst mit neuen Würfeln wiederholt.
    var canUndo: Bool {
        guard let g = game, let u = g.undo, g.players.indices.contains(u.state.current) else { return false }
        return !g.players[u.state.current].isComputer
    }
    var canUndoRoll: Bool { game?.preRoll != nil }

    // MARK: Spiel anlegen und öffnen

    func startGame(players: [Player], settings: GameSettings) {
        let record = GameRecord(players: players, settings: settings)
        records.insert(record, at: 0)
        currentID = record.id
        lastSetup = (players, settings)
        persist(record)
        screen = .game
    }

    /// Tageswürfel: ein Solo-Spiel mit der festen Würfelfolge von heute
    func startDailyDice(playerName: String) {
        var settings = GameSettings()
        settings.dailyKey = DailyDice.todayKey()
        SpielerQuelle.technischeNamen.insert(playerName.lowercased())   // S1-010
        startGame(players: [Player(name: playerName, avatar: Theme.avatars[0], colorIndex: 0)], settings: settings)
    }

    /// Heutiges Tageswürfel-Ergebnis (bestes beendetes Spiel von heute), falls vorhanden
    var dailyDiceResultToday: Int? {
        let key = DailyDice.todayKey()
        return records.filter { $0.finished && $0.settings.dailyKey == key }
            .map { $0.state.totals(player: 0).total }.max()
    }

    func rematch(order: [Player], settings: GameSettings) {
        closeGame()
        var settings = settings
        if settings.dailyKey != nil { settings.dailyKey = DailyDice.todayKey() }   // Tageswürfel: noch einmal mit der Folge von heute
        startGame(players: order, settings: settings)
    }

    func resume(_ id: UUID) {
        guard records.contains(where: { $0.id == id }) else { return }
        currentID = id
        screen = .game
    }

    /// Zurück zur Startseite; der Stand ist schon gespeichert.
    func pause() {
        pausedNotice = !(game?.finished ?? true)
        closeGame()
    }

    func closeGame() {
        currentID = nil
        nextPlayerNotice = nil
        screen = .home
    }

    func deleteGame(_ id: UUID) {
        if currentID == id { currentID = nil }
        records.removeAll { $0.id == id }
        do { try repository.delete(id: id) } catch { saveError = String(localized: "Das Spiel konnte nicht gelöscht werden.") }
    }

    func renameGame(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        mutate(id) { $0.name = trimmed.isEmpty ? nil : trimmed }
    }

    // MARK: Aktionen im Spiel

    /// Würfel antippen: halten oder loslassen (nur nach dem ersten und vor dem letzten Wurf).
    func toggleHold(_ index: Int) {
        mutate { r in
            guard r.state.rollsUsed > 0, r.state.rollsUsed < 3, !r.state.finished, (0..<5).contains(index) else { return }
            if let i = r.held.firstIndex(of: index) { r.held.remove(at: i) } else { r.held.append(index) }
        }
    }

    /// Computerzug: Würfel zeigen, welche gehalten werden.
    func setHeld(_ keep: [Int]) { mutate { $0.held = keep.sorted() } }

    /// Computerzug: würfelt immer mit der App-Würfelquelle, auch wenn Menschen echte Würfel benutzen.
    @discardableResult
    func computerRoll(keep: [Int]) -> Bool { performRoll(keep: keep.sorted(), roller: roller) }

    /// Digital würfeln (gehaltene Würfel bleiben).
    @discardableResult
    func roll() -> Bool {
        guard let r = game, r.settings.diceMode == .digital else { return false }
        return performRoll(keep: r.held.sorted(), roller: roller)
    }

    /// Echte Würfel: `values` sind die neuen Augen der nicht gehaltenen Positionen, aufsteigend.
    @discardableResult
    func rollReal(_ values: [Int]) -> Bool {
        guard let r = game, r.settings.diceMode == .real else { return false }
        let needed = r.state.rollsUsed == 0 ? 5 : 5 - r.held.count
        guard values.count == needed, values.allSatisfy({ (1...6).contains($0) }) else { return false }
        var rest = values[...]
        return performRoll(keep: r.held.sorted(), roller: { rest.popFirst() ?? 1 })
    }

    static var gehalteneBleiben: Bool { UserDefaults.standard.object(forKey: "wuerfelBleibenGehalten") as? Bool ?? true }

    private func performRoll(keep: [Int], roller: () -> Int) -> Bool {
        guard var r = game else { return false }
        // Alle fünf gehalten: ein Wurf würde nur einen von drei Würfen verbrauchen, ohne etwas zu ändern
        guard keep.count < 5 else { return false }
        let before = Snapshot(state: r.state, held: r.held, timeline: r.timeline)
        // Tageswürfel: feste Folge des Tages statt Zufall; der Zähler gehört zum Spielstand (Rückgängig stellt ihn zurück)
        if let key = r.settings.dailyKey {
            var drawn = r.state.diceDrawn
            do {
                try r.state.apply(.roll(keep: keep), roller: { defer { drawn += 1 }; return DailyDice.value(key: key, index: drawn) })
            } catch { return false }
            r.state.diceDrawn = drawn
        } else {
            do { try r.state.apply(.roll(keep: keep), roller: roller) } catch { return false }
        }
        r.preRoll = before
        // TF24-08: Gehaltene Würfel bleiben nach dem Wurf gehalten (Standard); man kann sie weiter antippen.
        // Nach dem dritten Wurf gibt es nichts mehr zu halten.
        // Einstellungen > Spielen > „Gehaltene Würfel bleiben liegen“ (Schlüssel wuerfelBleibenGehalten, Standard an); aus = wie früher, jedes Mal neu wählen.
        if r.state.rollsUsed >= 3 || !Self.gehalteneBleiben { r.held = [] }
        commit(r)
        return true
    }

    /// Echte Würfel: den letzten Wurf verwerfen, um ihn neu einzutippen.
    func undoRoll() {
        guard var r = game, let s = r.preRoll else { return }
        r.state = s.state; r.held = s.held; r.timeline = s.timeline; r.preRoll = nil
        commit(r)
    }

    /// Feld eintragen (auch Streichen mit 0 Punkten, wenn nichts passt).
    @discardableResult
    func score(_ category: Category) -> Bool {
        guard var r = game else { return false }
        let before = Snapshot(state: r.state, held: r.held, timeline: r.timeline)
        do { try r.state.apply(.score(category), roller: { 1 }) } catch { return false }
        r.undo = before
        r.preRoll = nil
        r.held = []
        r.timeline.append(r.players.indices.map { r.state.totals(player: $0).total })
        commit(r)
        nextPlayerNotice = (r.state.finished || r.players.count < 2) ? nil : r.state.current
        return true
    }

    /// Ein Schritt zurück direkt nach „Feld eintragen“.
    func undo() {
        guard var r = game, let s = r.undo else { return }
        r.state = s.state; r.held = s.held; r.timeline = s.timeline; r.undo = nil; r.preRoll = nil
        nextPlayerNotice = nil
        commit(r)
    }

    // MARK: Intern

    private func mutate(_ id: UUID? = nil, _ change: (inout GameRecord) -> Void) {
        guard let id = id ?? currentID, var r = records.first(where: { $0.id == id }) else { return }
        change(&r)
        commit(r)
    }

    private func commit(_ record: GameRecord) {
        var r = record
        r.updatedAt = Date()
        if let i = records.firstIndex(where: { $0.id == r.id }) { records[i] = r }
        persist(r)
    }

    private func persist(_ record: GameRecord) {
        do { try repository.save(record) } catch {
            saveError = String(localized: "Der Spielstand konnte nicht gespeichert werden. Ist der Speicher voll?")
        }
    }
}
