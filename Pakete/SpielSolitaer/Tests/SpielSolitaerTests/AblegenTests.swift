// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielSolitaer

/// SPEZIFIKATION-EXTRAS §6: Karten ablegen – automatisch oder selbst (Standard: Selbst)
@MainActor
final class AblegenTests: XCTestCase {
    private func defaults() -> UserDefaults { UserDefaults(suiteName: "ablegen-\(UUID().uuidString)")! }
    private func prefs(auto: Bool?) -> AppPreferences {
        let p = AppPreferences(defaults: defaults())
        if let auto { p.autoFoundation = auto }
        return p
    }

    // MARK: Einstellung und Bestandsnutzer

    func testStandardIstSelbst() {
        let p = AppPreferences(defaults: defaults())
        XCTAssertFalse(p.autoFoundation, "Standard: Selbst")
        XCTAssertFalse(p.autoPlaceNoticePending, "neuer Nutzer (Willkommen noch nicht gesehen): kein Hinweis")
    }

    func testLadenOhneWertIstSelbstBewusstGesetzterWertBleibt() {
        let d = defaults()
        d.set(true, forKey: "welcomeSeen")
        XCTAssertFalse(AppPreferences(defaults: d).autoFoundation, "ohne gespeicherten Wert: Selbst")
        d.set(true, forKey: "autoFoundation")                      // bewusst „Automatisch“ gewählt
        XCTAssertTrue(AppPreferences(defaults: d).autoFoundation)
        d.set(false, forKey: "autoFoundation")
        XCTAssertFalse(AppPreferences(defaults: d).autoFoundation)
    }

    func testHinweisFuerBestandsnutzerNurWennNieBewusstGewaehltUndNurEinmal() {
        // Bestandsnutzer: Willkommen gesehen, Schalter nie angefasst (kein gespeicherter Wert)
        let d = defaults()
        d.set(true, forKey: "welcomeSeen")
        let p = AppPreferences(defaults: d)
        XCTAssertTrue(p.autoPlaceNoticePending)
        XCTAssertFalse(p.autoFoundation)
        // gezeigt → kommt nie wieder, auch ohne Entscheidung (App beendet)
        p.markAutoPlaceNoticeShown()
        XCTAssertFalse(AppPreferences(defaults: d).autoPlaceNoticePending)

        // „Automatisch“ auf dem Hinweis → gespeichert, kein Hinweis mehr
        let d2 = defaults(); d2.set(true, forKey: "welcomeSeen")
        let p2 = AppPreferences(defaults: d2)
        p2.choosePlacing(automatic: true)
        XCTAssertTrue(p2.autoFoundation); XCTAssertFalse(p2.autoPlaceNoticePending)
        XCTAssertTrue(AppPreferences(defaults: d2).autoFoundation)
        XCTAssertFalse(AppPreferences(defaults: d2).autoPlaceNoticePending)

        // „So lassen“ → Selbst gespeichert (bewusst), kein Hinweis mehr
        let d3 = defaults(); d3.set(true, forKey: "welcomeSeen")
        let p3 = AppPreferences(defaults: d3)
        p3.choosePlacing(automatic: false)
        XCTAssertNotNil(d3.object(forKey: "autoFoundation"))
        XCTAssertFalse(AppPreferences(defaults: d3).autoPlaceNoticePending)

        // Wer den alten Schalter bewusst geändert hat (gespeicherter Wert), behält ihn und bekommt keinen Hinweis
        let d4 = defaults(); d4.set(true, forKey: "welcomeSeen"); d4.set(true, forKey: "autoFoundation")
        let p4 = AppPreferences(defaults: d4)
        XCTAssertTrue(p4.autoFoundation); XCTAssertFalse(p4.autoPlaceNoticePending)
    }

    func testErsterStartAuswahlSetztDenWert() {
        let d = defaults()
        let p = AppPreferences(defaults: d)            // neuer Nutzer
        XCTAssertFalse(p.welcomeSeen)
        p.choosePlacing(automatic: true)               // „Automatisch“ im zweiten Schritt
        p.welcomeSeen = true
        XCTAssertTrue(AppPreferences(defaults: d).autoFoundation)
        let d2 = defaults()
        let p2 = AppPreferences(defaults: d2)
        p2.choosePlacing(automatic: false)             // „Überspringen“ = Selbst
        p2.welcomeSeen = true
        let again = AppPreferences(defaults: d2)
        XCTAssertFalse(again.autoFoundation)
        XCTAssertFalse(again.autoPlaceNoticePending, "neuer Nutzer bekommt den Bestandsnutzer-Hinweis nie")
    }

    // MARK: Automatik nach dem Zug: Automatisch = sichere Karte oben, Selbst = liegt noch

    private func lauf<R: SolitaireRules>(_ rules: R.Type, _ mode: GameMode, _ state: R.State, move: Move, auto: Bool) async throws -> GameStore<R> {
        let store = GameStore<R>(mode: mode, prefs: prefs(auto: auto), seed: 1, url: nil)
        store.load(state: state)
        XCTAssertTrue(store.perform(move))
        try await Task.sleep(for: .seconds(2))     // großzügig: bei voller Auslastung kommt die zweite Automatik später
        return store
    }

    func testKlondikeEinsUndDreiKarten() async throws {
        for draw in [1, 3] {
            var s = GameState(draw: draw)
            s.cols[0] = Column(up: [CardID(rank: 2, suit: .spades), CardID(rank: 1, suit: .spades)])
            s.cols[1] = Column(up: [CardID(rank: 1, suit: .hearts)])
            let mv = Move.move(from: .column(0), to: .foundation(0), count: 1)
            let an = try await lauf(KlondikeRules.self, .klondike(draw), s, move: mv, auto: true)
            XCTAssertEqual(an.state.foundation, [2, 1, 0, 0], "Ziehen \(draw): Automatisch legt 2♠ und A♥ von selbst")
            let aus = try await lauf(KlondikeRules.self, .klondike(draw), s, move: mv, auto: false)
            XCTAssertEqual(aus.state.foundation, [1, 0, 0, 0], "Ziehen \(draw): Selbst lässt 2♠ liegen")
            XCTAssertEqual(aus.state.cols[0].up, [CardID(rank: 2, suit: .spades)])
        }
    }

    func testFreeCell() async throws {
        let s = FreeCellState(cols: [[CardID(rank: 2, suit: .spades), CardID(rank: 1, suit: .spades)], [CardID(rank: 1, suit: .hearts)]] + Array(repeating: [], count: 6))
        let mv = Move.move(from: .column(0), to: .foundation(0), count: 1)
        let an = try await lauf(FreeCellRules.self, .freecell, s, move: mv, auto: true)
        XCTAssertEqual(an.state.foundation, [2, 1, 0, 0])
        let aus = try await lauf(FreeCellRules.self, .freecell, s, move: mv, auto: false)
        XCTAssertEqual(aus.state.foundation, [1, 0, 0, 0])
        XCTAssertEqual(aus.state.cols[0], [CardID(rank: 2, suit: .spades)])
    }

    func testYukon() async throws {
        let s = YukonState(cols: [Column(up: [CardID(rank: 2, suit: .spades), CardID(rank: 1, suit: .spades)]), Column(up: [CardID(rank: 1, suit: .hearts)])])
        let mv = Move.move(from: .column(0), to: .foundation(0), count: 1)
        let an = try await lauf(YukonRules.self, .yukon, s, move: mv, auto: true)
        XCTAssertEqual(an.state.foundation, [2, 1, 0, 0])
        let aus = try await lauf(YukonRules.self, .yukon, s, move: mv, auto: false)
        XCTAssertEqual(aus.state.foundation, [1, 0, 0, 0])
        XCTAssertEqual(aus.state.cols[0].up, [CardID(rank: 2, suit: .spades)])
    }

    // MARK: Fertig spielen bleibt (auch bei „Selbst“) und ist vollständig

    func testFertigSpielenBeiSelbstVerfuegbarUndVollstaendig() async throws {
        func col(_ suit: Suit) -> Column { Column(up: [13, 12, 11].map { CardID(rank: $0, suit: suit) }) }
        let k = GameStore<KlondikeRules>(mode: .klondike(1), prefs: prefs(auto: false), seed: 1, url: nil)
        k.load(state: GameState(foundation: [10, 10, 10, 10], cols: [col(.spades), col(.hearts), col(.diamonds), col(.clubs), Column(), Column(), Column()]))
        XCTAssertTrue(k.canFinish)
        k.autoFinish()
        for _ in 0..<60 where !k.state.isWon { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertTrue(k.state.isWon, "Klondike: Fertig spielen legt alles ab")

        let y = GameStore<YukonRules>(mode: .yukon, prefs: prefs(auto: false), seed: 1, url: nil)
        y.load(state: YukonState(cols: [Column(up: (1...13).reversed().map { CardID(rank: $0, suit: .spades) })], foundation: [0, 13, 13, 13]))
        XCTAssertTrue(y.canFinish)
        y.autoFinish()
        for _ in 0..<80 where !y.state.isWon { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertTrue(y.state.isWon, "Yukon: Fertig spielen legt alles ab")

        // FreeCell: Pik und Herz als zwei abwechselnde Reihen K…A, Zellen leer, Karo und Kreuz fertig
        func run(_ first: Suit, _ second: Suit) -> [CardID] { (1...13).reversed().map { CardID(rank: $0, suit: $0 % 2 == 1 ? first : second) } }
        let f = GameStore<FreeCellRules>(mode: .freecell, prefs: prefs(auto: false), seed: 1, url: nil)
        f.load(state: FreeCellState(cols: [run(.spades, .hearts), run(.hearts, .spades)] + Array(repeating: [], count: 6), foundation: [0, 0, 13, 13]))
        XCTAssertTrue(f.canFinish)
        f.autoFinish()
        for _ in 0..<80 where !f.state.isWon { try await Task.sleep(for: .milliseconds(100)) }
        XCTAssertTrue(f.state.isWon, "FreeCell: Fertig spielen legt alles ab")
    }
}
