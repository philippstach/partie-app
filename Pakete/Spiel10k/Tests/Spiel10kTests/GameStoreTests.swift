// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import Spiel10k

/// Speicher im Arbeitsspeicher für Tests.
final class MemoryRepository: GameRepository {
    var records: [UUID: GameRecord] = [:]
    func loadAll() -> [GameRecord] { records.values.sorted { $0.updatedAt > $1.updatedAt } }
    func save(_ record: GameRecord) throws { records[record.id] = record }
    func delete(id: UUID) throws { records[id] = nil }
}

/// Speicher, der immer scheitert (z. B. Gerät voll).
final class FailingRepository: GameRepository {
    struct Full: Error {}
    func loadAll() -> [GameRecord] { [] }
    func save(_ record: GameRecord) throws { throw Full() }
    func delete(id: UUID) throws {}
}

@MainActor
struct GameStoreTests {
    /// Store mit vorgegebenen Würfelergebnissen und eigenem Speicher.
    private func makeStore(rolls: [Int], players: Int = 2, settings: GameSettings = GameSettings(),
                           repository: GameRepository = MemoryRepository()) -> GameStore {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = GameStore(repository: repository, defaults: defaults)
        var queue = rolls
        store.roller = { queue.isEmpty ? 2 : queue.removeFirst() }
        var s = settings
        s.nextPlayerOverlay = false
        store.startGame(
            players: (0..<players).map { Player(name: "P\($0)", avatar: "🎲", colorIndex: $0) },
            settings: s
        )
        return store
    }

    private func select(_ store: GameStore, _ indices: Int...) {
        for i in indices { store.toggleDie(i) }
    }

    /// Fehler 2 aus der Web-Version: neu gewürfelte, ausgewählte Punkte gingen beim Beenden verloren.
    @Test func pointsFromEveryThrowCount() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4,   5, 3, 6])
        store.roll()
        select(store, 0, 1)                       // 1 + 5 = 150
        store.roll()                              // wirft Würfel 2,3,4 → 5,3,6
        select(store, 2)                          // + 50
        #expect(store.turnTotal == 200)
        store.endTurn()
        #expect(store.game?.players[0].score == 200)
    }

    /// Fehler 1 aus der Web-Version: übernommene Punkte wurden doppelt gezählt.
    @Test func inheritedPointsCountOnce() throws {
        let store = makeStore(rolls: [1, 5, 2, 3, 4,   1, 6, 6])
        store.roll()
        select(store, 0, 1)                       // 150
        store.endTurn()                           // P0 hört auf, 3 Würfel offen
        let offer = try #require(store.game?.offer)
        #expect(offer.points == 150)
        #expect(offer.openCount == 3)

        store.acceptOffer()                       // P1 wirft nur die 3 offenen Würfel → 1,6,6
        #expect(store.turn.dice == [1, 5, 1, 6, 6])
        #expect(store.turn.locked == [true, true, false, false, false])
        select(store, 2)                          // + 100
        #expect(store.turnTotal == 250)
        store.endTurn()
        #expect(store.game?.players[1].score == 250)
        #expect(store.game?.players[0].score == 150)
    }

    @Test func declinedOfferStartsFresh() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4])
        store.roll()
        select(store, 0)
        store.endTurn()
        store.declineOffer()
        #expect(store.game?.offer == nil)
        #expect(store.turn.banked == 0)
        #expect(store.canRoll)
    }

    @Test func nieteLosesTurnPoints() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4,   2, 3, 6])
        store.roll()
        select(store, 0, 1)
        store.roll()                              // 2,3,6 → Niete
        #expect(store.nieteNotice?.lostPoints == 150)
        #expect(store.game?.players[0].score == 0)
        #expect(store.game?.current == 1)
    }

    @Test func cannotRollOrEndWithoutValidSelection() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4])
        store.roll()
        #expect(!store.canRoll)                   // nichts ausgewählt
        #expect(!store.canEndTurn)
        select(store, 2)                          // eine 2 zählt nicht
        #expect(!store.canRoll)
        #expect(!store.canEndTurn)
    }

    @Test func lockedDiceCannotBeToggled() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4,   5, 3, 6])
        store.roll()
        select(store, 0)
        store.roll()
        store.toggleDie(0)
        #expect(store.turn.locked[0])
        #expect(!store.turn.selected[0])
    }

    /// Triples dürfen nicht über mehrere Würfe zusammengesetzt werden.
    @Test func noTriplesAcrossThrows() {
        let store = makeStore(rolls: [5, 2, 3, 4, 6,   5, 5, 2, 3])
        store.roll()
        select(store, 0)                          // 50
        store.roll()
        select(store, 1, 2)                       // 5 + 5 = 100 (kein 500er)
        #expect(store.turnTotal == 150)
    }

    @Test func hotDiceKeepsPointsAndRollsAllFive() {
        let store = makeStore(rolls: [1, 1, 1, 5, 5,   2, 3, 4, 6, 1])
        store.roll()
        select(store, 0, 1, 2, 3, 4)              // 1000 + 100 = 1100
        #expect(store.turn.nextRollCount == 5)
        store.roll()
        #expect(store.turn.banked == 1100)
        #expect(store.turn.locked == [false, false, false, false, false])
        select(store, 4)
        store.endTurn()
        #expect(store.game?.players[0].score == 1200)
        #expect(store.game?.offer?.openCount == 4)
    }

    @Test func straightOnlyInFullThrow() {
        let store = makeStore(rolls: [1, 2, 3, 4, 5])
        store.roll()
        select(store, 0, 1, 2, 3, 4)
        #expect(store.selectionScore == 1000)
    }

    @Test func penaltyAfterThreeMisses() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        for _ in 0..<3 {
            store.submitNoPoints()                // P0
            store.submitPoints(100)               // P1
        }
        #expect(store.game?.players[0].score == -500)
        #expect(store.game?.players[0].streak == 0)
    }

    /// Punkte-Eingabe mit Übernehmen: Angebot mit unbekannten Augen übersteht Speichern und Laden.
    @Test func pointsOfferSurvivesReload() throws {
        let repo = MemoryRepository()
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real, realEntry: .points), repository: repo)
        let id = store.currentID!
        store.submitPoints(450)
        #expect(store.game?.offer?.kept == [false, false, false, false, false])   // 1.0.1 (8): ohne Würfelangabe
        #expect(store.game?.offer?.dice == [0, 0, 0, 0, 0])
        store.acceptOffer()
        let saved = try #require(repo.records[id])
        #expect(saved.state.isConsistent)
        let reloaded = GameStore(repository: repo, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        reloaded.resume(id)
        #expect(reloaded.turn.inheritedPoints == 450)
        #expect(reloaded.turn.inheritedFrom == 0)
        reloaded.submitPoints(200)
        #expect(reloaded.game?.players[1].score == 650)
    }

    /// Eigener „Fail“-Ton nur, wenn die Strafe greift.
    @Test func failSoundOnPenalty() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        store.submitNoPoints()
        #expect(store.lastSound == .niete)
        store.submitPoints(100)
        store.submitNoPoints()
        #expect(store.lastSound == .niete)
        store.submitPoints(100)
        store.submitNoPoints()
        #expect(store.lastSound == .fail)
        #expect(store.nieteNotice?.penalty == 500)
    }

    @Test func failSoundOnPenaltyDigital() {
        // P0 dreimal Niete (2,3,4,6,2), P1 jeweils Niete dazwischen
        let store = makeStore(rolls: Array(repeating: [2, 3, 4, 6, 2], count: 6).flatMap { $0 })
        for turn in 0..<4 {
            store.roll()
            #expect(store.lastSound == .niete, "Zug \(turn)")
            store.nieteNotice = nil
        }
        store.roll()
        #expect(store.lastSound == .fail)
    }

    /// Niete-Ton auf allen Wegen: digital, Punkte-Eingabe, Würfel-Eingabe mitten im Zug (1.0.1 (8)).
    @Test func nieteSoundOnEveryPath() {
        let digital = makeStore(rolls: [2, 3, 4, 6, 2])
        digital.roll()
        #expect(digital.lastSound == .niete)

        let points = makeStore(rolls: [], settings: GameSettings(diceMode: .real, realEntry: .points))
        points.submitNoPoints()
        #expect(points.lastSound == .niete)

        let pips = makeStore(rolls: [], settings: GameSettings(diceMode: .real, realEntry: .pips))
        pips.layOut([1, 5], bank: false)
        #expect(pips.lastSound == .select)
        pips.submitNoPoints()
        #expect(pips.lastSound == .niete)
    }

    /// Jeder Ton liegt als Datei im App-Bundle.
    @Test(.enabled(if: Bundle.main.bundleURL.pathExtension == "app", "Töne liegen im App-Bundle; ohne App als Test-Host nicht prüfbar"))
    func everySoundIsBundled() {
        for sound in Sound.allCases {
            #expect(Bundle.main.url(forResource: "10k-" + sound.rawValue, withExtension: "m4a") != nil, "\(sound)")
        }
    }

    // MARK: - Strafserie (Philipps Punkt 3): Abzug bei 3, danach wieder ab 0

    /// Vier Nullzüge in Folge (echte Würfel) → genau ein Abzug.
    @Test func fourZerosPenalizeOnceReal() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        for _ in 0..<4 {
            store.submitNoPoints()                // P0
            store.submitPoints(100)               // P1
        }
        #expect(store.game?.players[0].score == -500)
        #expect(store.game?.players[0].streak == 1)
        #expect(store.game?.log.filter { $0.penalty > 0 }.count == 1)
    }

    /// Sechs Nullzüge → zweiter Abzug erst beim sechsten.
    @Test func secondPenaltyOnlyAtSixReal() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        var penalties: [Int] = []
        for turn in 1...6 {
            store.submitNoPoints()
            if store.game?.log.last?.penalty ?? 0 > 0 { penalties.append(turn) }
            store.submitPoints(100)
        }
        #expect(penalties == [3, 6])
        #expect(store.game?.players[0].score == -1000)
    }

    /// Vier Nieten in Folge mit digitalen Würfeln → genau ein Abzug.
    @Test func fourNietenPenalizeOnceDigital() {
        // P0: Niete (2,3,4,6,6); P1: 1 raus und aufhören, Angebot ablehnen
        var rolls: [Int] = []
        for _ in 0..<4 { rolls += [2, 3, 4, 6, 6,   1, 2, 3, 4, 6] }
        let store = makeStore(rolls: rolls)
        for _ in 0..<4 {
            store.roll()                          // P0 Niete
            store.roll(); select(store, 0); store.endTurn()   // P1 100
            store.declineOffer()
        }
        #expect(store.game?.players[0].score == -500)
        #expect(store.game?.players[0].streak == 1)
        #expect(store.game?.log.filter { $0.penalty > 0 }.count == 1)
    }

    /// Niete nach Übernahme zählt zur Serie (Regel d), aber auch dort nur ein Abzug bei 3.
    @Test func inheritedNietenCountOnce() {
        // P1 legt 1 raus, hört auf; P0 übernimmt und hat Niete – viermal
        var rolls: [Int] = [1, 2, 3, 4, 6]          // P0 erster Zug: 100
        for _ in 0..<4 { rolls += [1, 2, 3, 4, 6,   2, 3, 4, 6] }  // P1: 100; P0 übernimmt: Niete auf 4 Würfeln
        let store = makeStore(rolls: rolls)
        store.roll(); select(store, 0); store.endTurn(); store.declineOffer()   // P0 100
        for _ in 0..<4 {
            store.roll(); select(store, 0); store.endTurn()                     // P1 100
            store.acceptOffer()                                                  // P0 Niete
        }
        #expect(store.game?.players[0].score == 100 - 500)
        #expect(store.game?.players[0].streak == 1)
    }

    /// Undo nach dem Strafzug und erneutes Eintragen → trotzdem nur ein Abzug.
    @Test func undoAroundPenaltyKeepsSingleDeduction() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        for _ in 0..<3 { store.submitNoPoints(); store.submitPoints(100) }
        store.undo()                              // P1s Zug zurück
        store.undo()                              // Strafzug zurück
        #expect(store.game?.players[0].score == 0)
        #expect(store.game?.players[0].streak == 2)
        store.submitNoPoints()                    // Strafzug erneut
        store.submitPoints(100)
        store.submitNoPoints()                    // vierter Nullzug
        #expect(store.game?.players[0].score == -500)
        #expect(store.game?.players[0].streak == 1)
    }

    /// (2) Warnung nach 2 Nullrunden – nicht im Stechen, nicht bei Strafe 0.
    @Test func penaltyWarningRule() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        store.submitNoPoints(); store.submitPoints(100)
        #expect(store.game?.penaltyThreatened(0) == false)
        store.submitNoPoints(); store.submitPoints(100)
        #expect(store.game?.penaltyThreatened(0) == true)
        #expect(store.game?.penaltyThreatened(1) == false)

        let free = makeStore(rolls: [], settings: GameSettings(penalty: 0, diceMode: .real))
        free.submitNoPoints(); free.submitPoints(100); free.submitNoPoints(); free.submitPoints(100)
        #expect(free.game?.penaltyThreatened(0) == false)
    }

    // MARK: - Undo mit digitalen Würfeln (Punkt 1)

    /// Aufhören lässt sich zurücknehmen – Würfel und Auswahl sind wieder da, nichts wird neu gewürfelt.
    @Test func digitalUndoRestoresBankedTurn() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4])
        store.roll()
        select(store, 0, 1)
        let before = store.turn
        store.endTurn()
        #expect(store.canUndo)
        store.undo()
        #expect(store.game?.current == 0)
        #expect(store.game?.players[0].score == 0)
        #expect(store.turn == before)
        #expect(store.game?.offer == nil)
    }

    /// Nach einem neuen Wurf gibt es kein Zurück mehr (sonst ließe sich neu würfeln).
    @Test func digitalUndoNotAcrossNewThrow() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4,   1, 2, 3, 4, 6])
        store.roll(); select(store, 0, 1); store.endTurn()
        store.declineOffer()
        #expect(store.canUndo)                    // Ablehnen ist zurücknehmbar
        store.roll()                              // P1 würfelt
        #expect(!store.canUndo)
    }

    /// Eine Niete (digital) ist ein Wurf – nicht zurücknehmbar.
    @Test func digitalNieteCannotBeUndone() {
        let store = makeStore(rolls: [2, 3, 4, 6, 6])
        store.roll()
        #expect(store.game?.current == 1)
        #expect(!store.canUndo)
    }

    /// Übernehmen würfelt sofort → nicht zurücknehmbar; Ablehnen schon.
    @Test func undoDeclineRestoresOffer() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4])
        store.roll(); select(store, 0); store.endTurn()
        store.declineOffer()
        store.undo()
        #expect(store.game?.offer != nil)
    }

    /// Aktionen tragen die Auswahl selbst (`keep`) – so lassen sie sich später übers Netz schicken.
    @Test func actionsCarryKeep() {
        let store = makeStore(rolls: [1, 5, 2, 3, 4,   5, 3, 6])
        store.perform(.roll(keep: []))
        store.perform(.roll(keep: [0, 1]))        // 150 rausgelegt, 3 neu
        #expect(store.turn.banked == 150)
        store.perform(.bank(keep: [2]))           // + 50
        #expect(store.game?.players[0].score == 200)
        store.perform(.roll(keep: [3]))           // ungültig: nichts gewürfelt
        #expect(store.turn.hasRolled == false)
    }

    /// Augen-Eingabe (echte Würfel): Wurf eintragen, Tippfehler per Undo korrigierbar.
    @Test func enteredThrowIsUndoable() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real, realEntry: .pips))
        store.enterThrow([1, 5, 2, 3, 4])
        #expect(store.turn.dice == [1, 5, 2, 3, 4])
        store.undo()
        #expect(store.turn.hasRolled == false)
        store.enterThrow([2, 3, 4, 6, 6])         // Niete
        #expect(store.game?.current == 1)
        store.undo()                              // Tippfehler – zurück
        #expect(store.game?.current == 0)
    }

    @Test func tiebreakRuleOffSharesWin() {
        let store = makeStore(rolls: [], settings: GameSettings(roundLimit: 1, diceMode: .real, tiebreak: false))
        store.submitPoints(300); store.submitPoints(300)
        #expect(store.game?.winners == [0, 1])
        #expect(store.game?.tiebreak == nil)
    }

    @Test func inheritAllFiveRuleOff() {
        let store = makeStore(rolls: [1, 1, 1, 5, 5], settings: GameSettings(inheritAllFive: false))
        store.roll(); select(store, 0, 1, 2, 3, 4); store.endTurn()
        #expect(store.game?.offer == nil)
    }

    /// (4) Die Regel wirkt im Spiel: 2-2-2-3-4 ist mit „Nur Einsen und Fünfen“ eine Niete.
    @Test func tripleRuleAppliesInGame() {
        let b = makeStore(rolls: [2, 2, 2, 3, 4], settings: GameSettings(triples: .onesAndFives))
        b.roll()
        #expect(b.game?.current == 1)
        #expect(b.nieteNotice != nil)

        let a = makeStore(rolls: [2, 2, 2, 3, 4])
        a.roll()
        select(a, 0, 1, 2)
        #expect(a.selectionScore == 200)
        #expect(a.canEndTurn)
    }

    @Test func tripleRuleHintAndSelectionInB() {
        let store = makeStore(rolls: [4, 4, 4, 1, 3], settings: GameSettings(triples: .onesAndFives))
        store.roll()
        #expect(store.bestSelection == [3])
        select(store, 0, 1, 2)
        #expect(store.selectionScore == nil)
        #expect(!store.canRoll)
    }

    /// (9) Eingabeart nur zwischen den Zügen umschaltbar.
    @Test func entrySwitchOnlyBetweenTurns() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real, realEntry: .pips))
        #expect(store.canSwitchEntry)
        store.enterThrow([1, 5, 2, 3, 4])
        #expect(!store.canSwitchEntry)
        select(store, 0)
        store.endTurn()
        store.declineOffer()
        #expect(store.canSwitchEntry)
        store.updateSettings { $0.realEntry = .points }
        #expect(store.game?.settings.usesDice == false)
    }

    /// (9) Übernehmen bei Augen-Eingabe: offene Würfel werden eingetippt, nicht gewürfelt.
    @Test func acceptOfferWithPipsWaitsForEntry() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real, realEntry: .pips))
        store.enterThrow([1, 5, 2, 3, 4])
        select(store, 0, 1)
        store.endTurn()
        store.acceptOffer()
        #expect(store.turn.hasRolled == false)
        #expect(store.diceToEnter == 3)
        store.enterThrow([1, 6, 6])
        #expect(!store.turn.fullThrow)
        select(store, 2)
        #expect(store.turnTotal == 250)
    }

    @Test func winAtGoal() {
        let store = makeStore(rolls: [], settings: GameSettings(goal: 1000, diceMode: .real))
        store.submitPoints(1000)
        #expect(store.game?.winners == [0])
    }

    /// In der Web-Version griff das Limit nur bei manueller Eingabe.
    @Test func roundLimitAppliesToNieten() {
        let store = makeStore(rolls: [], settings: GameSettings(roundLimit: 1, diceMode: .real))
        store.submitPoints(300)
        store.submitNoPoints()
        #expect(store.game?.winners == [0])
    }

    @Test func invalidEntriesRejected() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        store.submitPoints(120)
        store.submitPoints(0)
        #expect(store.game?.log.isEmpty == true)
    }

    @Test func undoRestoresPreviousTurn() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        store.submitPoints(300)
        store.undo()
        #expect(store.game?.players[0].score == 0)
        #expect(store.game?.current == 0)
    }

    @Test func gameIsRestoredAfterRelaunch() {
        let repo = MemoryRepository()
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real), repository: repo)
        store.submitPoints(450)
        let reopened = GameStore(repository: repo, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        #expect(reopened.pausedGames.count == 1)
        reopened.resume(reopened.pausedGames[0].id)
        #expect(reopened.game?.players[0].score == 450)
    }

    // MARK: - Randfälle aus der Regelprüfung

    /// Mitten im Wurf (Würfel ausgewählt) schließen und neu öffnen.
    @Test func resumeMidThrowKeepsDiceAndSelection() {
        let repo = MemoryRepository()
        let store = makeStore(rolls: [1, 5, 2, 3, 4,   5, 3, 6], repository: repo)
        store.roll()
        select(store, 0, 1)
        store.roll()
        select(store, 2)
        let before = store.turn

        let reopened = GameStore(repository: repo, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        reopened.resume(reopened.pausedGames[0].id)
        #expect(reopened.turn == before)
        #expect(reopened.turnTotal == 200)
        #expect(reopened.canRoll && reopened.canEndTurn)
    }

    @Test func hotDiceThenNieteLosesEverything() {
        let store = makeStore(rolls: [1, 1, 1, 5, 5,   2, 3, 4, 6, 6])
        store.roll()
        select(store, 0, 1, 2, 3, 4)              // 1100
        store.roll()                              // alle 5 neu → Niete
        #expect(store.nieteNotice?.lostPoints == 1100)
        #expect(store.game?.players[0].score == 0)
    }

    /// Nach dem Übernehmen fallen nie alle 5 in einem Wurf → keine Straße.
    @Test func noStraightAfterInheriting() {
        let store = makeStore(rolls: [1, 2, 6, 3, 3,   3, 4, 5])
        store.roll()
        select(store, 0)                          // nur die 1 rausgelegt
        store.endTurn()
        store.acceptOffer()                       // 4 offene → 3,4,5 + … (Rest 2)
        #expect(!store.turn.fullThrow)
        #expect(Scoring.score(store.turn.dice, fullThrow: store.turn.fullThrow) == nil)
    }

    /// Regel b: Alle 5 rausgelegt und aufgehört → der Nächste übernimmt mit allen 5.
    @Test func allOutOfferRollsAllFiveWithoutStraight() throws {
        let store = makeStore(rolls: [1, 1, 1, 5, 5,   3, 1, 5, 2, 4])
        store.roll()
        select(store, 0, 1, 2, 3, 4)              // 1100
        store.endTurn()
        let offer = try #require(store.game?.offer)
        #expect(offer.allOut && offer.openCount == 5 && offer.points == 1100)
        #expect(store.game?.players[0].score == 1100)

        store.acceptOffer()                       // alle 5 neu: 3,1,5,2,4 (wäre eine Straße)
        #expect(store.turn.locked == [false, false, false, false, false])
        #expect(!store.turn.fullThrow)
        select(store, 0, 1, 2, 3, 4)
        #expect(store.selectionScore == nil) // Straße zählt nach Übernahme nicht
        store.toggleDie(0); store.toggleDie(2); store.toggleDie(3); store.toggleDie(4)
        #expect(store.turnTotal == 1200)         // 1100 übernommen (einmal) + 100
        store.endTurn()
        #expect(store.game?.players[1].score == 1200)
    }

    /// Nach der Übernahme wieder alle 5 im eigenen Zug → dann zählt die Straße wieder.
    @Test func straightCountsAgainAfterOwnHotDice() {
        let store = makeStore(rolls: [1, 1, 1, 5, 5,   1, 1, 1, 5, 5,   1, 2, 3, 4, 5])
        store.roll()
        select(store, 0, 1, 2, 3, 4)
        store.endTurn()
        store.acceptOffer()                       // 1,1,1,5,5
        select(store, 0, 1, 2, 3, 4)              // +1100, alle raus
        store.roll()                              // eigener voller Wurf: Straße
        #expect(store.turn.fullThrow)
        select(store, 0, 1, 2, 3, 4)
        #expect(store.selectionScore == 1000)
    }

    // MARK: - Stechen (Regel a)

    private func tiedRealGame(players: Int = 3, limit: Int = 1) -> GameStore {
        makeStore(rolls: [], players: players, settings: GameSettings(roundLimit: limit, diceMode: .real))
    }

    @Test func roundLimitTieStartsTiebreak() {
        let store = tiedRealGame()
        store.submitPoints(300)                   // P0
        store.submitPoints(100)                   // P1
        store.submitPoints(300)                   // P2 → P0 und P2 gleich
        #expect(store.game?.finished == false)
        #expect(store.game?.tiebreak == Tiebreak(players: [0, 2]))
        #expect(store.game?.current == 0)
        #expect(store.tiebreakNotice == Tiebreak(players: [0, 2]))
    }

    @Test func tiebreakSkipsOthersAndDecides() {
        let store = tiedRealGame()
        store.submitPoints(300); store.submitPoints(100); store.submitPoints(300)
        store.submitPoints(50)                    // P0 im Stechen
        #expect(store.game?.current == 2)         // P1 wird übersprungen
        store.submitPoints(200)                   // P2
        #expect(store.game?.winners == [2])
        #expect(store.game?.players[2].score == 500)
    }

    @Test func tiedAgainStartsNextTiebreakRound() {
        let store = tiedRealGame()
        store.submitPoints(300); store.submitPoints(100); store.submitPoints(300)
        store.submitPoints(200)
        store.submitPoints(200)
        #expect(store.game?.tiebreak == Tiebreak(players: [0, 2], round: 2))
        #expect(store.game?.current == 0)
        store.submitNoPoints()
        store.submitPoints(50)
        #expect(store.game?.winners == [2])
    }

    @Test func noPenaltyInTiebreak() {
        let store = makeStore(rolls: [], settings: GameSettings(roundLimit: 2, diceMode: .real))
        store.submitNoPoints(); store.submitNoPoints()      // Runde 1
        store.submitNoPoints(); store.submitNoPoints()      // Runde 2 → 0:0, Serie je 2
        #expect(store.game?.tiebreak != nil)
        store.submitNoPoints()                    // dritte Null – im Stechen ohne Strafe
        #expect(store.game?.players[0].score == 0)
        #expect(store.nieteNotice == nil)
    }

    @Test func noOfferIntoTiebreakButWithinIt() throws {
        let store = makeStore(rolls: [1, 5, 2, 3, 4,   1, 5, 2, 3, 4,   1, 2, 3, 4, 6], settings: GameSettings(roundLimit: 1))
        store.roll(); select(store, 0, 1); store.endTurn()
        #expect(store.game?.offer != nil)
        store.declineOffer()
        store.roll(); select(store, 0, 1); store.endTurn()  // 150:150 → Stechen
        #expect(store.game?.tiebreak != nil)
        #expect(store.game?.offer == nil)         // nicht aus der Runde ins Stechen
        store.roll(); select(store, 0); store.endTurn()     // P0 im Stechen: 100, Würfel offen
        let offer = try #require(store.game?.offer)         // innerhalb des Stechens erlaubt
        #expect(offer.from == 0 && store.game?.current == 1)
    }

    @Test func tiebreakSurvivesRelaunch() {
        let repo = MemoryRepository()
        let store = makeStore(rolls: [], players: 2, settings: GameSettings(roundLimit: 1, diceMode: .real), repository: repo)
        store.submitPoints(300); store.submitPoints(300)
        let reopened = GameStore(repository: repo, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        reopened.resume(reopened.pausedGames[0].id)
        #expect(reopened.game?.tiebreak == Tiebreak(players: [0, 1]))
        #expect(reopened.game?.inTiebreak == true)
    }

    @Test func undoWorksAcrossTiebreak() {
        let store = tiedRealGame(players: 2)
        store.submitPoints(300); store.submitPoints(300)
        store.submitPoints(100)                   // P0 im Stechen
        store.undo()
        #expect(store.game?.tiebreak == Tiebreak(players: [0, 1]))
        #expect(store.game?.current == 0)
        store.undo()                              // zurück vor den Gleichstand
        #expect(store.game?.tiebreak == nil)
        #expect(store.game?.current == 1)
    }

    @Test func penaltyCannotWinAndMayGoNegative() {
        let store = makeStore(rolls: [], settings: GameSettings(goal: 1000, penalty: 500, diceMode: .real))
        store.submitPoints(950)                   // P0
        store.submitNoPoints()                    // P1
        for _ in 0..<3 {
            store.submitNoPoints()                // P0: 3× nichts → 450
            if store.game?.current == 1 { store.submitNoPoints() }
        }
        #expect(store.game?.players[0].score == 450)
        #expect(store.game?.players[1].score == -500)
        #expect(store.game?.finished == false)
    }

    @Test func undoRevertsWinningTurn() {
        let store = makeStore(rolls: [], settings: GameSettings(goal: 1000, diceMode: .real))
        store.submitPoints(1000)
        #expect(store.game?.finished == true)
        store.undo()
        #expect(store.game?.finished == false)
        #expect(store.game?.players[0].score == 0)
    }

    // MARK: - Gespeicherte Spiele

    @Test func multipleGamesCanBePausedAndResumed() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        store.submitPoints(100)
        let first = store.currentID!
        store.closeGame()
        store.startGame(players: [Player(name: "X", avatar: "🎲", colorIndex: 0), Player(name: "Y", avatar: "🎲", colorIndex: 1)],
                        settings: GameSettings(diceMode: .real))
        store.submitPoints(250)
        store.closeGame()

        #expect(store.pausedGames.count == 2)
        store.resume(first)
        #expect(store.game?.players[0].score == 100)
        #expect(store.game?.current == 1)
    }

    /// Nur Ansehen (ohne Zug) darf Datum und Reihenfolge nicht ändern.
    @Test func resumingDoesNotTouchSaveDate() throws {
        let repo = MemoryRepository()
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real), repository: repo)
        let id = store.currentID!
        store.closeGame()
        let before = try #require(repo.records[id]).updatedAt
        store.resume(id)
        #expect(repo.records[id]?.updatedAt == before)
    }

    @Test func renameAndDelete() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real))
        let id = store.currentID!
        store.renameGame(id, to: "  Spieleabend  ")
        #expect(store.savedGames.first?.displayName == "Spieleabend")
        store.renameGame(id, to: "")
        #expect(store.savedGames.first?.displayName == "P0, P1")
        store.deleteGame(id)
        #expect(store.savedGames.isEmpty)
        #expect(store.game == nil)
    }

    /// Wischen: sofort aus der Liste, Datei erst nach Ablauf; „Rückgängig“ holt es zurück.
    @Test func deleteWithUndo() throws {
        let repo = MemoryRepository()
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real), repository: repo)
        let id = store.currentID!
        store.closeGame()
        store.deletionDelay = .seconds(3600)

        store.deleteGameWithUndo(id)
        #expect(store.savedGames.isEmpty)
        #expect(repo.records[id] != nil)          // Datei noch da
        #expect(store.pendingDeletion?.id == id)

        store.undoDeletion()
        #expect(store.savedGames.map(\.id) == [id])
        #expect(store.pendingDeletion == nil)
        #expect(repo.records[id] != nil)

        store.deleteGameWithUndo(id)
        store.commitPendingDeletion()
        #expect(repo.records[id] == nil)
        #expect(store.savedGames.isEmpty)
        store.undoDeletion()                       // zu spät: nichts passiert
        #expect(store.savedGames.isEmpty)
    }

    @Test func deleteWithUndoExpires() async throws {
        let repo = MemoryRepository()
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real), repository: repo)
        let id = store.currentID!
        store.closeGame()
        store.deletionDelay = .milliseconds(50)
        store.deleteGameWithUndo(id)
        // Unter Last kann der Ablauf später feuern: bis zu 5 s pollen statt fest zu warten
        let deadline = ContinuousClock.now + .seconds(5)
        while repo.records[id] != nil, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(repo.records[id] == nil)
        #expect(store.pendingDeletion == nil)
    }

    /// Ein zweites Löschen macht das erste endgültig.
    @Test func secondDeleteCommitsFirst() {
        let repo = MemoryRepository()
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real), repository: repo)
        let first = store.currentID!
        store.rematch()
        let second = store.currentID!
        store.closeGame()
        store.deletionDelay = .seconds(3600)
        store.deleteGameWithUndo(first)
        store.deleteGameWithUndo(second)
        #expect(repo.records[first] == nil)
        #expect(repo.records[second] != nil)
        store.undoDeletion()
        #expect(store.savedGames.map(\.id) == [second])
    }

    @Test func finishedGamesKeptOrDiscarded() {
        let store = makeStore(rolls: [], settings: GameSettings(goal: 1000, diceMode: .real))
        store.submitPoints(1000)
        #expect(store.finishedGames.count == 1)

        store.keepFinishedGames = false
        store.rematch()
        store.submitPoints(1000)
        #expect(store.finishedGames.count == 1)   // nur das erste bleibt
    }

    @Test func settingsCanChangeDuringGame() {
        let store = makeStore(rolls: [])
        store.updateSettings { $0.bestHint = true }
        #expect(store.game?.settings.bestHint == true)
        #expect(store.savedGames.first?.state.settings.bestHint == true)
    }

    /// Wie der Server: Würfeln nur digital, Augen und Punkte eintragen nur bei echten Würfeln.
    @Test func actionsMatchDiceMode() {
        let digital = makeStore(rolls: [1, 2, 3, 4, 6])
        digital.submitPoints(300)
        digital.submitNoPoints()
        digital.enterThrow([1, 1, 1, 5, 5])
        #expect(digital.game?.log.isEmpty == true)
        #expect(digital.turn.hasRolled == false)

        let real = makeStore(rolls: [1, 1, 1, 1, 1], settings: GameSettings(diceMode: .real))
        real.roll()
        #expect(real.turn.hasRolled == false)
        real.enterThrow([1, 2, 3, 3, 6])
        #expect(real.turn.hasRolled)
        // „Niete“-Knopf mitten im Zug: Zug ist verloren, nächster Spieler
        real.submitNoPoints()
        #expect(real.game?.current == 1)
        #expect(real.game?.players[0].nieten == 1)
        #expect(real.game?.players[0].score == 0)
        real.undo()
        #expect(real.game?.current == 0)
        #expect(real.turn.dice == [1, 2, 3, 3, 6])
    }

    /// enterThrow (Server, alle Augen eines Wurfs) mit „beste Auswahl“ – bleibt für die Online-Aktion bestehen.
    @Test func selectBestPreselectsScoringDice() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real, realEntry: .pips))
        #expect(store.game?.settings.preselectsBest == false)   // echte Würfel: keine Vorauswahl in der App
        store.enterThrow([1, 5, 2, 3, 6])
        store.selectBest()
        #expect(store.selection == [0, 1])
        #expect(store.turnTotal == 150)
        // Ein Würfel abgewählt – weiter mit dem Rest
        store.toggleDie(1)
        store.enterThrow([5, 5, 5, 2])
        #expect(store.turn.banked == 100)
        store.selectBest()
        #expect(store.turnTotal == 100 + 500)
        store.endTurn()
        #expect(store.game?.players[0].score == 600)
    }

    /// F21-009: Mit „Punkte-Würfel vorauswählen“ ist die Auswahl nach dem Wurf sofort da, Weiterwürfeln und Aufhören sind frei
    /// und die Zahl der übrigen Würfel passt zur Auswahl (mehrere einzelne 1er und 5er).
    @Test func preselectAfterDigitalRollIsConsistent() {
        for roll in [[5, 5, 2, 3, 6], [1, 1, 5, 2, 3], [1, 5, 5, 5, 2], [1, 2, 3, 3, 3], [1, 2, 4, 6, 6]] {
            var settings = GameSettings()
            settings.preselectDigital = true
            let store = makeStore(rolls: roll, settings: settings)
            store.roll()
            let best = store.turn.bestSelection(store.scoringRules)
            #expect(store.selection == best.sorted())
            #expect(store.selectionScore != nil)
            #expect(store.canRoll)
            #expect(store.turn.nextRollCount == roll.count - best.count || best.count == roll.count)
        }
    }

    /// F21-014: Sind nach dem Wurf alle 5 Würfel gewertet (Straße), zählt der Zug sofort 1.000 – Karte und „Aufhören“ lesen dieselbe Zahl.
    @Test func turnTotalAfterFullScoringRollMatchesBankButton() {
        for settings in [GameSettings(), { var s = GameSettings(); s.preselectDigital = true; return s }()] {
            let store = makeStore(rolls: [1, 2, 3, 4, 5], settings: settings)
            store.roll()
            if !settings.preselectsBest { for i in 0..<5 { store.toggleDie(i) } }
            #expect(store.selection.count == 5)
            #expect(store.turnTotal == 1000)
            #expect(store.canEndTurn)
        }
    }

    @Test func preselectIsOffForDigitalUnlessEnabled() {
        var settings = GameSettings()
        #expect(settings.preselectsBest == false)
        settings.preselectDigital = true
        #expect(settings.preselectsBest)
        let data = try! JSONEncoder().encode(settings)
        #expect(try! JSONDecoder().decode(GameSettings.self, from: data).preselectDigital)
    }

    /// „Pausieren“ zeigt auf der Startseite kurz „Spiel gespeichert“ – nicht nach einem beendeten Spiel.
    @Test func pauseShowsSavedNoticeOnlyForRunningGames() {
        let store = makeStore(rolls: [])
        store.pauseGame()
        #expect(store.pausedNotice)
        #expect(store.screen == .home)
        #expect(store.pausedGames.count == 1)

        let finished = makeStore(rolls: [], settings: GameSettings(goal: 1_000, diceMode: .real))
        finished.submitPoints(1_000)
        #expect(finished.game?.finished == true)
        finished.pauseGame()
        #expect(!finished.pausedNotice)
    }

    /// Scheitert das Speichern, merkt sich der Store den Fehler für einen Hinweis – das Spiel läuft weiter.
    @Test func saveFailureIsReported() {
        let store = makeStore(rolls: [], settings: GameSettings(diceMode: .real), repository: FailingRepository())
        #expect(store.saveError != nil)
        store.saveError = nil
        store.submitPoints(300)
        #expect(store.saveError != nil)
        #expect(store.game?.players[0].score == 300)
    }
}
