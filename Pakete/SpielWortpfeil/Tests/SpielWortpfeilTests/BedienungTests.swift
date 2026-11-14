// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielWortpfeil

/// Bedienung, die nicht in Shared/regeltests steht (Hardware-Tastatur, Welle).
@MainActor
struct BedienungTests {
    static let mini = Shared.puzzle(((Shared.json("regeltests/spiel.json") as! JSON)["raetsel"])!)

    @Test func pfeilRechtsSpringtZumNaechstenBuchstabenfeldUndPasstRichtungAn() {
        var g = Game(puzzle: Self.mini)            // Cursor (1,1), Richtung unten
        g.moveCursor(.rechts, forward: true)
        #expect(g.cursor == Pos(1, 2))
        #expect(g.direction == .rechts)            // dort gibt es ein Wort nach rechts
        g.moveCursor(.rechts, forward: true)
        #expect(g.cursor == Pos(1, 3))
        g.moveCursor(.rechts, forward: true)       // (1,4) ist Leerfeld, danach Rand: bleibt stehen
        #expect(g.cursor == Pos(1, 3))
    }

    @Test func pfeilUntenUeberLeerfelderHinweg() {
        var g = Game(puzzle: Self.mini)
        g.moveCursor(.unten, forward: true)
        #expect(g.cursor == Pos(2, 1))
        g.moveCursor(.unten, forward: true)        // (3,1) ist Buchstabe
        #expect(g.cursor == Pos(3, 1))
        g.moveCursor(.unten, forward: false)
        #expect(g.cursor == Pos(2, 1))
    }

    @Test func pfeilAmRandBleibtStehen() {
        var g = Game(puzzle: Self.mini)
        g.moveCursor(.unten, forward: false)       // über (1,1) liegt das Fragefeld (0,1), davor Rand
        #expect(g.cursor == Pos(1, 1))
    }

    @Test func welleBeiRichtigemWortNurMitFehleranzeige() {
        let store = GameStoreTests.makeStore()
        store.preferences.showCorrectWords = true
        store.begin(Game(puzzle: Self.mini))
        #expect(store.wave == nil)
        store.type("oma")                          // erstes Wort (OMA, rechts oder unten je nach Start)
        #expect(store.wave != nil || store.game?.entries.count == 3)

        let store2 = GameStoreTests.makeStore()
        store2.preferences.showCorrectWords = false
        store2.begin(Game(puzzle: Self.mini))
        store2.type("ox")
        #expect(store2.wave == nil)
    }

    @Test func richtungWechselnUeberFrageleiste() {
        let store = GameStoreTests.makeStore()
        store.begin(Game(puzzle: Self.mini))
        let vorher = store.game!.direction
        store.toggleDirection()
        #expect(store.game!.direction == vorher.other)
        store.toggleDirection()
        #expect(store.game!.direction == vorher)
    }

    static let mitLoesung = Shared.puzzle(((Shared.json("regeltests/loesungswort.json") as! JSON)["spiel"] as! JSON)["raetsel"]!)

    @Test func loesungswortKomplettErstWennAlleRichtig() {
        var g = Game(puzzle: Self.mitLoesung)       // Lösungsfelder (3,2) (1,1) (3,3)
        #expect(!g.solutionComplete && g.solutionProgress == "...")
        g.entries[Pos(3, 2)] = "R"; g.entries[Pos(1, 1)] = "O"; g.entries[Pos(3, 3)] = "X"
        #expect(!g.solutionComplete)
        g.entries[Pos(3, 3)] = "T"
        #expect(g.solutionComplete && g.puzzle.solutionWordText == "ROT")
    }

    @Test func lösungszeileSpringtZumFeld() {
        let store = GameStoreTests.makeStore()
        store.begin(Game(puzzle: Self.mitLoesung))
        store.jumpToSolutionCell(0)
        #expect(store.game?.cursor == Pos(3, 2))
        store.jumpToSolutionCell(1)
        #expect(store.game?.cursor == Pos(1, 1))
        #expect(store.activeClue != nil)
    }

    @Test func kastchenZeigtKurzFrageleisteZeigtText() throws {
        let json = ##"{"zeile":0,"spalte":1,"richtung":"unten","text":"Kanton am Vierwaldstättersee","kurz":"Kanton"}"##
        let c = try JSONDecoder().decode(Clue.self, from: Data(json.utf8))
        #expect(c.boxText == "Kanton" && c.text == "Kanton am Vierwaldstättersee")
        let alt = try JSONDecoder().decode(Clue.self, from: Data(##"{"zeile":0,"spalte":1,"richtung":"unten","text":"Hund"}"##.utf8))
        #expect(alt.kurz == nil && alt.boxText == "Hund")           // alte Daten gelten weiter
        let leer = Clue(zeile: 0, spalte: 0, richtung: "rechts", text: "Hund", kurz: "")
        #expect(leer.boxText == "Hund")                              // leer = fehlt
    }

    @Test func teilenTextMitStarUndSerie() {
        let de = Locale(identifier: "de_DE")
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let datum = cal.date(from: DateComponents(year: 2026, month: 10, day: 5, hour: 12))!
        let t = ShareText.make(time: 372, hints: 0, streak: 6, isDaily: true, date: datum, locale: de)
        #expect(t.hasSuffix("★ 6:12 · Serie 6") && t.contains("5."), Comment(rawValue: t))
        let mit = ShareText.make(time: 372, hints: 2, streak: 6, isDaily: false, date: datum, locale: de)
        #expect(!mit.contains("★") && !mit.contains("Serie"), Comment(rawValue: mit))
    }
}
