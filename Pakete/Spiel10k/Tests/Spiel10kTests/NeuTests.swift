// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import SpieleKern
@testable import Spiel10k

/// „10k“: Zusatzregeln (Einstieg, Mehrfache, drei Paare), Spielerleiste, Frühere Runden, Ende für den Rahmen.
struct NeuWertungTests {
    @Test func standardBleibtUnveraendert() {
        let r = ScoringRules(diceCount: 6)
        #expect(Scoring.score([4, 4, 4, 4], fullThrow: false, rules: r) == nil)   // vier Vieren: Drilling plus 4 zählt nicht
        #expect(Scoring.score([2, 2, 3, 3, 4, 4], fullThrow: true, rules: r) == nil)
        #expect(GameRules().entryThreshold == 0 && GameRules().multiples == .standard && !GameRules().threePairs)
    }

    @Test func mehrfacheVerdoppeln() {
        let r = ScoringRules(multiples: .doubling)
        #expect(Scoring.score([4, 4, 4], fullThrow: false, rules: r) == 400)
        #expect(Scoring.score([4, 4, 4, 4], fullThrow: false, rules: r) == 800)
        #expect(Scoring.score([4, 4, 4, 4, 4], fullThrow: false, rules: r) == 1_600)
        #expect(Scoring.score([1, 1, 1, 1], fullThrow: false, rules: r) == 2_000)
        #expect(Scoring.score([1, 1, 1, 1, 5], fullThrow: false, rules: r) == 2_050)
    }

    @Test func mehrfacheFest() {
        let r = ScoringRules(diceCount: 6, multiples: .fixed)
        #expect(Scoring.score([4, 4, 4], fullThrow: false, rules: r) == 400)
        #expect(Scoring.score([4, 4, 4, 4], fullThrow: false, rules: r) == 1_000)
        #expect(Scoring.score([6, 6, 6, 6, 6], fullThrow: false, rules: r) == 2_000)
        #expect(Scoring.score([2, 2, 2, 2, 2, 2], fullThrow: true, rules: r) == 3_000)
        let b = ScoringRules(triples: .onesAndFives, multiples: .fixed)
        #expect(Scoring.score([4, 4, 4, 4], fullThrow: false, rules: b) == nil)
        #expect(Scoring.score([5, 5, 5, 5], fullThrow: false, rules: b) == 1_000)
    }

    @Test func dreiPaare() {
        let r = ScoringRules(diceCount: 6, threePairs: true)
        #expect(Scoring.score([2, 2, 3, 3, 4, 4], fullThrow: true, rules: r) == 1_500)
        #expect(Scoring.score([1, 1, 3, 3, 6, 6], fullThrow: true, rules: r) == 1_500)
        #expect(Scoring.score([2, 2, 3, 3, 4, 4], fullThrow: false, rules: r) == nil)   // nur im vollen Wurf
        #expect(Scoring.score([2, 2, 2, 2, 3, 3], fullThrow: true, rules: r) == nil)    // vier und zwei sind keine drei Paare
        #expect(Scoring.canScore([2, 2, 3, 3, 4, 4], rules: r, fullThrow: true))
        #expect(!Scoring.canScore([2, 2, 3, 3, 4, 4], rules: r, fullThrow: false))
        #expect(!Scoring.canScore([2, 2, 3, 3, 4, 4], rules: ScoringRules(diceCount: 6), fullThrow: true))
        // mit 5 Würfeln ohne Wirkung
        #expect(Scoring.score([2, 2, 3, 3, 4], fullThrow: true, rules: ScoringRules(threePairs: true)) == nil)
    }

    @Test func neueRegelnBleibenImJSON() throws {
        var rules = GameRules(entryThreshold: 500, multiples: .doubling, threePairs: true)
        rules.diceCount = 6
        let back = try JSONDecoder().decode(GameRules.self, from: JSONEncoder().encode(rules))
        #expect(back == rules)
        // Alte Stände ohne die neuen Schlüssel laden mit den Standardwerten
        let alt = try JSONDecoder().decode(GameRules.self, from: Data(#"{"goal":5000}"#.utf8))
        #expect(alt.goal == 5_000 && alt.entryThreshold == 0 && alt.multiples == .standard && !alt.threePairs)
    }
}

@MainActor
struct NeuEinstiegTests {
    private func store(_ rules: GameRules, rolls: [Int] = []) -> GameStore {
        let s = GameStore(repository: MemoryRepository(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        var queue = rolls
        s.roller = { queue.isEmpty ? 2 : queue.removeFirst() }
        var settings = GameSettings()
        settings.rules = rules
        settings.nextPlayerOverlay = false
        s.startGame(players: [Player(name: "A", avatar: "🎲", colorIndex: 0), Player(name: "B", avatar: "🎲", colorIndex: 1)], settings: settings)
        return s
    }

    @Test func aufhoerenErstAbHuerde() {
        let s = store(GameRules(entryThreshold: 350), rolls: [1, 2, 2, 3, 6])
        s.roll()
        s.toggleDie(0)               // eine 1 = 100
        #expect(s.selectionScore == 100)
        #expect(!s.canEndTurn)       // 100 < 350
        s.endTurn()
        #expect(s.game?.log.isEmpty == true && s.game?.current == 0)   // abgelehnt
        #expect(s.canRoll)
    }

    @Test func nachDemEinstiegGiltKeineHuerdeMehr() {
        let s = store(GameRules(penalty: 0, entryThreshold: 350), rolls: [1, 1, 1, 2, 3])
        s.roll()
        for i in 0..<3 { s.toggleDie(i) }           // drei Einsen = 1.000
        #expect(s.canEndTurn)
        s.endTurn()
        #expect(s.game?.players[0].score == 1_000)
        #expect(s.game?.hasEntered(0) == true)
        s.declineOffer()
        // B hat noch nicht angeschrieben: Hürde gilt für B, nicht für A
        #expect(s.game?.entryNeeded == 350)
    }

    @Test func echteWuerfelPunkteBrauchenDieHuerde() {
        var rules = GameRules(entryThreshold: 500)
        rules.diceMode = .real
        let s = store(rules)
        s.submitPoints(300)
        #expect(s.game?.log.isEmpty == true)        // zu wenig, nichts gebucht
        s.submitPoints(500)
        #expect(s.game?.players[0].score == 500)
    }

    @Test func niemandWirdOhneHuerdeBehindert() {
        let s = store(GameRules())
        #expect(s.game?.entryNeeded == 0)
    }
}

struct NeuLeisteTests {
    private func spiel() -> GameState {
        var g = GameState(players: ["A", "B", "C"].enumerated().map { Player(name: $1, avatar: "🎲", colorIndex: $0) }, settings: GameSettings())
        func zug(_ p: Int, _ pts: Int, _ pen: Int = 0) { g.log.append(TurnRecord(player: p, points: pts, penalty: pen)) }
        zug(0, 350); zug(1, 0); zug(2, 100)      // Runde 1
        zug(0, 0); zug(1, 500); zug(2, 0, 500)   // Runde 2
        zug(0, 250)                              // Runde 3 begonnen
        return g
    }

    @Test func zuwachsJePerson() {
        let g = spiel()
        #expect(NeuLogik.zuwachs(g, player: 0) == .punkte(250))
        #expect(NeuLogik.zuwachs(g, player: 1) == .punkte(500))
        #expect(NeuLogik.zuwachs(g, player: 2) == .strafe(500))
        let leer = GameState(players: g.players, settings: GameSettings())
        #expect(NeuLogik.zuwachs(leer, player: 0) == .leer)
    }

    @Test func fruehereRundenOhneLetztenZug() {
        let g = spiel()
        let r = NeuLogik.fruehereRunden(g, anzahl: 2)
        #expect(r.map(\.runde) == [1, 2])
        #expect(r[0].zellen == [.punkte(350), .niete, .punkte(100)])
        #expect(r[1].zellen == [.niete, .punkte(500), .strafe(500)])   // Runde 3 hat nur den letzten Zug → noch nicht da
        #expect(NeuLogik.fruehereRunden(g, anzahl: 1).map(\.runde) == [2])
        #expect(NeuLogik.fruehereRunden(g, anzahl: 0).isEmpty)
        var kurz = g
        kurz.log = [g.log[0]]
        #expect(NeuLogik.fruehereRunden(kurz, anzahl: 3).isEmpty)
    }

    @Test func fruehereRundenImStechenLeer() {
        var g = spiel()
        g.tiebreak = Tiebreak(players: [0, 1])
        #expect(NeuLogik.fruehereRunden(g, anzahl: 2).isEmpty)
    }

    @Test func hoehenKlassen() {
        #expect(NeuLogik.fruehereRundenAnzahl(hoehe: 647, grosseSchrift: false) == 0)     // SE
        #expect(NeuLogik.fruehereRundenAnzahl(hoehe: 797, grosseSchrift: false) == 2)     // 390×844
        #expect(NeuLogik.fruehereRundenAnzahl(hoehe: 873, grosseSchrift: false) == 3)     // Pro Max
        #expect(NeuLogik.fruehereRundenAnzahl(hoehe: 873, grosseSchrift: true) == 0)
        #expect(NeuLogik.wuerfelHoechstens(hoehe: 647) == 56)
        #expect(NeuLogik.wuerfelHoechstens(hoehe: 797) == 90)
        #expect(NeuLogik.wuerfelHoechstens(hoehe: 873) == 112)
    }

    @Test func wuerfelRasterWaehltDieGroessereAnordnung() {
        // SE: 5 Würfel, 343 breit, Kante höchstens 56 → eine Reihe
        let se = NeuLogik.wuerfelRaster(n: 5, breite: 330, hoehe: 200, abstand: 10, hoechstens: 56)
        #expect(se.spalten == 5 && se.kante == 56)
        // 390: 5 Würfel, 350 breit, 90 → zwei Reihen (3+2) mit 90 statt einer Reihe mit ~62
        let mittel = NeuLogik.wuerfelRaster(n: 5, breite: 350, hoehe: 230, abstand: 10, hoechstens: 90)
        #expect(mittel.spalten == 3 && mittel.kante == 90)
        // Wenig Höhe: eine Reihe
        let flach = NeuLogik.wuerfelRaster(n: 5, breite: 350, hoehe: 70, abstand: 10, hoechstens: 90)
        #expect(flach.spalten == 5)
        // 6 Würfel: 3+3
        let sechs = NeuLogik.wuerfelRaster(n: 6, breite: 350, hoehe: 230, abstand: 10, hoechstens: 112)
        #expect(sechs.spalten == 3)
    }
}

struct NeuEndeTests {
    private func spiel(_ scores: [Int], winners: [Int]) -> GameState {
        var g = GameState(players: scores.enumerated().map { Player(name: "P\($0)", avatar: "🎲", colorIndex: $0, score: $1) }, settings: GameSettings())
        g.winners = winners
        return g
    }

    @Test func siegerZuerstDannPunkte() {
        let e = NeuLogik.ende(spiel([9_000, 10_050, 4_000], winners: [1]))
        #expect(e.reihenfolge == ["P1", "P0", "P2"])
        #expect(e.punkte == ["10.050", "9.000", "4.000"])
        #expect(e.plaetze == [1, 2, 3])
        #expect(!e.istRemis)
    }

    @Test func gemeinsamerSiegIstRemis() {
        let e = NeuLogik.ende(spiel([5_000, 5_000], winners: [0, 1]))
        #expect(e.plaetze == [1, 1])
        #expect(e.istRemis)
    }

    @Test func gleichstandNachSiegerBekommtGleichenPlatz() {
        let e = NeuLogik.ende(spiel([10_000, 3_000, 3_000], winners: [0]))
        #expect(e.plaetze == [1, 2, 2])
    }

    @Test func soloHatKeinePlaetze() {
        let e = NeuLogik.ende(spiel([10_200], winners: [0]))
        #expect(e.reihenfolge == ["P0"] && e.plaetze == nil)
    }

    /// Blatt 22 (EB2, Schritt 2): (a) die Zählung hängt am Zustand und läuft mit; (b) ein alter Stand ohne die Schlüssel lädt, Zählung nil, kein Bild.
    @Test func wuerfelZaehlungUndAlterStand() throws {
        var g = spiel([0, 0], winners: [])
        g.augen = [[0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0]]; g.augenGetippt = [0, 0]
        g.zaehleAugen([1, 1, 5], echt: true)
        #expect(g.augen?[0] == [2, 0, 0, 0, 1, 0] && g.augenGetippt == [3, 0])
        g.winners = [0]
        #expect(NeuLogik.ende(g).wuerfel?.wuerfe(0) == 3)
        var json = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(g)) as? [String: Any])
        json.removeValue(forKey: "augen"); json.removeValue(forKey: "augenGetippt")
        var alt = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        #expect(alt.augen == nil && alt.augenGetippt == nil)
        alt.zaehleAugen([3], echt: false)   // zählt nicht, stürzt nicht ab
        #expect(alt.augen == nil && NeuLogik.ende(alt).wuerfel == nil)
    }

    /// Blatt 22 (EB-2, Schritt 1): zwei Wertzeilen (Runden, Bester Zug); der Satz nennt nur das Ziel, allein gibt es keinen.
    @Test func ergebnisseiteMeldetWerteUndKurzenSatz() {
        let mehrere = NeuLogik.ende(spiel([9_000, 10_050, 4_000], winners: [1]))
        #expect(mehrere.werte.count == 2)
        #expect(mehrere.info != nil)
        let solo = NeuLogik.ende(spiel([10_200], winners: [0]))
        #expect(solo.werte.count == 2)
        #expect(solo.info == nil)
    }
}
