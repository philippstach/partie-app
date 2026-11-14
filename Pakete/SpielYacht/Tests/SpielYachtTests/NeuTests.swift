// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import SpieleKern
@testable import SpielYacht

private typealias Category = SpielYacht.Category

/// „Yacht“: Wertungen Kniffel, Yatzy und Original-Yacht, Block-Größen, Computer-Stufen, Ende, Rekord.
@Suite("Yacht neu")
struct NeuTests {
    private func punkte(_ w: [Int], _ c: Category, _ v: Variant) -> Int { Scoring.score(w, c, variant: v) }

    // MARK: Felder und Bonus

    @Test func felderZahl() {
        #expect(Variant.kniffel.fields.count == 13)
        #expect(Variant.yatzy.fields.count == 15)
        #expect(Variant.yacht.fields.count == 11)
        #expect(Variant.kniffel.fields == Category.allCases)
        #expect(!Variant.yacht.fields.contains(.chance))
        #expect(Variant.yatzy.fields.contains(.onePair) && Variant.yatzy.fields.contains(.twoPairs))
    }

    @Test func bonusJeWertung() {
        #expect(Rules.fuer(.kniffel).upperBonus == 35)
        #expect(Rules.fuer(.yatzy).upperBonus == 50 && Rules.fuer(.yatzy).upperBonusThreshold == 63)
        #expect(Rules.fuer(.yacht).upperBonus == 0)
        #expect(!Rules.fuer(.yatzy, joker: true, kniffelBonus: 100).joker)         // Joker und Bonus gibt es nur bei Kniffel
        #expect(Rules.fuer(.kniffel, joker: true, kniffelBonus: 100).kniffelBonus == 100)
    }

    /// RT-001: Yacht-Bonus ohne eigenen Joker-Schalter gibt trotzdem Bonuspunkte.
    @Test func yachtBonusSchaltetJokerMitEin() throws {
        let r = Rules.fuer(.kniffel, joker: false, kniffelBonus: 100)
        #expect(r.joker && r.kniffelBonus == 100)
        #expect(!Rules.fuer(.kniffel).joker)
        var s = GameState(playerNames: ["A"], rules: r)
        s.players[0].scores[.kniffel] = 50
        try s.apply(.roll(keep: []), roller: { 4 })
        #expect(s.jokerActive)
        try s.apply(.score(.fours), roller: { 4 })
        #expect(s.totals(player: 0).kniffelBonus == 100)
    }

    @Test func alteRegelnLadenAlsKniffel() throws {
        let r = try JSONDecoder().decode(Rules.self, from: Data(#"{"joker":true,"upperBonusThreshold":63}"#.utf8))
        #expect(r.variant == .kniffel && r.joker)
        let neu = Rules.fuer(.yatzy)
        let kopie = try JSONDecoder().decode(Rules.self, from: JSONEncoder().encode(neu))
        #expect(kopie == neu)
    }

    // MARK: Yatzy

    @Test func yatzyPaare() {
        #expect(punkte([3, 3, 5, 5, 2], .onePair, .yatzy) == 10)           // das höchste Paar
        #expect(punkte([3, 3, 5, 6, 2], .onePair, .yatzy) == 6)
        #expect(punkte([1, 2, 3, 4, 6], .onePair, .yatzy) == 0)
        #expect(punkte([3, 3, 5, 5, 2], .twoPairs, .yatzy) == 16)
        #expect(punkte([4, 4, 4, 4, 2], .twoPairs, .yatzy) == 0)           // zwei verschiedene Paare
        #expect(punkte([6, 6, 4, 4, 4], .twoPairs, .yatzy) == 20)
    }

    @Test func yatzyPaschUndHaus() {
        #expect(punkte([4, 4, 4, 1, 2], .threeOfAKind, .yatzy) == 12)      // nur die drei Würfel
        #expect(punkte([6, 6, 6, 6, 1], .fourOfAKind, .yatzy) == 24)
        #expect(punkte([6, 6, 6, 1, 1], .fourOfAKind, .yatzy) == 0)
        #expect(punkte([2, 2, 5, 5, 5], .fullHouse, .yatzy) == 19)         // Summe aller Würfel
        #expect(punkte([5, 5, 5, 5, 5], .fullHouse, .yatzy) == 0)
    }

    @Test func yatzyStrassenChanceYatzy() {
        #expect(punkte([1, 2, 3, 4, 5], .smallStraight, .yatzy) == 15)
        #expect(punkte([2, 3, 4, 5, 6], .largeStraight, .yatzy) == 20)
        #expect(punkte([2, 3, 4, 5, 6], .smallStraight, .yatzy) == 0)
        #expect(punkte([1, 2, 3, 4, 6], .smallStraight, .yatzy) == 0)
        #expect(punkte([1, 3, 4, 5, 6], .chance, .yatzy) == 19)
        #expect(punkte([3, 3, 3, 3, 3], .kniffel, .yatzy) == 50)
    }

    // MARK: Original-Yacht

    @Test func yachtWertungen() {
        #expect(punkte([2, 2, 5, 5, 5], .fullHouse, .yacht) == 19)
        #expect(punkte([4, 4, 4, 4, 1], .fourOfAKind, .yacht) == 16)
        #expect(punkte([4, 4, 4, 4, 4], .fourOfAKind, .yacht) == 16)       // fünf gleiche zählen auch als vier
        #expect(punkte([1, 2, 3, 4, 5], .smallStraight, .yacht) == 30)
        #expect(punkte([2, 3, 4, 5, 6], .largeStraight, .yacht) == 30)
        #expect(punkte([6, 6, 6, 6, 6], .kniffel, .yacht) == 50)
        #expect(punkte([4, 4, 4, 1, 2], .threeOfAKind, .yacht) == 0)       // gibt es nicht
    }

    @Test func kniffelBleibtWieBisher() {
        #expect(punkte([2, 2, 5, 5, 5], .fullHouse, .kniffel) == 25)
        #expect(punkte([4, 4, 4, 4, 1], .fourOfAKind, .kniffel) == 17)
        #expect(punkte([2, 3, 4, 5, 3], .smallStraight, .kniffel) == 30)
    }

    // MARK: Partien

    private func spiele(_ v: Variant, seed: UInt64, stufe: ComputerStufe) -> GameState {
        var g = GameState(playerNames: ["A"], rules: Rules.fuer(v))
        var gen = NeuZufall(seed: seed)
        var n = 0
        while !g.finished, n < 500 {
            n += 1
            let a = NeuLogik.entscheide(g, stufe: stufe, zufall: Double.random(in: 0..<1, using: &gen), random: { Double.random(in: 0..<1, using: &gen) })
            try? g.apply(a, roller: { Int.random(in: 1...6, using: &gen) })
        }
        return g
    }

    @Test func jedeWertungSpieltBisZumEnde() {
        // Der exakte Berater ist im Debug-Build langsam: leicht für alle Wertungen, die guten Stufen je einmal
        let faelle: [(Variant, ComputerStufe)] = Variant.allCases.map { ($0, .leicht) } + [(.yatzy, .schwer), (.yacht, .mittel)]
        for (v, stufe) in faelle {
            let g = spiele(v, seed: 5, stufe: stufe)
            #expect(g.finished, "\(v) \(stufe)")
            #expect(g.players[0].scores.count == v.fields.count)
            #expect(g.isConsistent)
        }
    }

    @Test func bonusWirdVergeben() {
        var g = GameState(playerNames: ["A"], rules: Rules.fuer(.yatzy))
        for (c, w) in [(Category.ones, 3), (.twos, 3), (.threes, 3), (.fours, 3), (.fives, 3), (.sixes, 3)] {
            g.players[0].scores[c] = (c.face ?? 0) * w
        }
        #expect(g.totals(player: 0).upper == 63)
        #expect(g.totals(player: 0).bonus == 50)
        var y = GameState(playerNames: ["A"], rules: Rules.fuer(.yacht))
        for c in Category.upper { y.players[0].scores[c] = (c.face ?? 0) * 5 }
        #expect(y.totals(player: 0).bonus == 0)
    }

    @Test func legaleFelderSindDieDerWertung() {
        var g = GameState(playerNames: ["A"], rules: Rules.fuer(.yacht))
        try? g.apply(.roll(keep: []), roller: { 3 })
        #expect(Set(g.legalCategories) == Set(Variant.yacht.fields))
        #expect(!g.legalCategories.contains(.chance))
    }

    // MARK: Berater

    @Test func beraterGibtRatFuerYatzy() {
        var g = GameState(playerNames: ["A"], rules: Rules.fuer(.yatzy))
        var werte = [4, 4, 2, 5, 6, 1, 1, 1, 1, 1].makeIterator()
        try? g.apply(.roll(keep: []), roller: { werte.next() ?? 1 })
        let rat = HoldAdvisor.advise(g)
        #expect(rat != nil)
        #expect(rat?.keep.allSatisfy { (0..<5).contains($0) } == true)
    }

    // MARK: Block und Größen

    @Test func zeilenZahl() {
        #expect(NeuLogik.zeilen(Rules.fuer(.kniffel)) == 15)                           // 13 Felder + Bonus + Gesamt
        #expect(NeuLogik.zeilen(Rules.fuer(.kniffel, kniffelBonus: 100)) == 16)
        #expect(NeuLogik.zeilen(Rules.fuer(.yatzy)) == 17)
        #expect(NeuLogik.zeilen(Rules.fuer(.yacht)) == 12)                             // ohne Bonuszeile
    }

    @Test func zeilenHoeheFuelltUndBegrenzt() {
        #expect(NeuLogik.zeilenHoehe(verfuegbar: 400, zeilen: 15, grosseSchrift: false) == 400.0 / 17)
        #expect(NeuLogik.zeilenHoehe(verfuegbar: 200, zeilen: 15, grosseSchrift: false) == 22)       // nie unter 22
        #expect(NeuLogik.zeilenHoehe(verfuegbar: 900, zeilen: 12, grosseSchrift: false) == 34)       // nie über 34
        #expect(NeuLogik.zeilenHoehe(verfuegbar: 200, zeilen: 15, grosseSchrift: true) == 26)
        #expect(NeuLogik.zeilenHoehe(verfuegbar: 900, zeilen: 12, grosseSchrift: false, regular: true) == 52)   // B18 M-005: iPad bis 52
    }

    @Test func wuerfelKante() {
        #expect(NeuLogik.wuerfelKante(hoehe: 647, regular: false, grosseSchrift: false) == 48)
        #expect(NeuLogik.wuerfelKante(hoehe: 797, regular: false, grosseSchrift: false) == 64)
        #expect(NeuLogik.wuerfelKante(hoehe: 873, regular: false, grosseSchrift: false) == 72)
        #expect(NeuLogik.wuerfelKante(hoehe: 1000, regular: true, grosseSchrift: false) == 90)
        #expect(NeuLogik.wuerfelKante(hoehe: 873, regular: false, grosseSchrift: true) == 56)
    }

    // MARK: Computer-Stufen

    @Test func stufenPatzer() {
        #expect(NeuLogik.patzer(.leicht) > NeuLogik.patzer(.mittel))
        #expect(NeuLogik.patzer(.mittel) > NeuLogik.patzer(.schwer))
        #expect(NeuLogik.level(.leicht) == .einfach && NeuLogik.level(.schwer) == .gut)
    }

    // MARK: Ende und Rekord

    @Test func endeSortiertNachPunktenUndTeiltPlaetze() {
        var r = GameRecord(players: [Player(name: "Anna", avatar: "😎", colorIndex: 0), Player(name: "Ben", avatar: "🤠", colorIndex: 1), Player(name: "Cem", avatar: "🧠", colorIndex: 2)],
                           settings: GameSettings(rules: Rules.fuer(.yatzy)))
        r.state.players[0].scores = [.chance: 20]
        r.state.players[1].scores = [.chance: 30]
        r.state.players[2].scores = [.chance: 20]
        let e = NeuLogik.ende(r)
        #expect(e.reihenfolge == ["Ben", "Anna", "Cem"])
        #expect(e.plaetze == [1, 2, 2])
        #expect(e.punkte == ["30", "20", "20"])
        #expect(e.info?.hasPrefix("Yatzy") == true)
    }

    @Test func rekord() {
        #expect(!NeuLogik.istNeuerRekord(punkte: 200, bisher: nil))
        #expect(NeuLogik.istNeuerRekord(punkte: 201, bisher: 200))
        #expect(!NeuLogik.istNeuerRekord(punkte: 200, bisher: 200))
        #expect(NeuLogik.rekordSchluessel(.yatzy) != NeuLogik.rekordSchluessel(.yacht))
    }

    // MARK: Store

    @Test @MainActor func regelnVorStartWechseltDieWertung() {
        let dir = FileManager.default.temporaryDirectory.appending(path: "yacht-neu-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = GameStore(repository: FileGameRepository(directory: dir))
        store.startGame(players: [Player(name: "A", avatar: "😎", colorIndex: 0)], settings: GameSettings())
        #expect(store.vorErstemZug)
        #expect(store.regelnVorStart(Rules.fuer(.yatzy)))
        #expect(store.game?.state.rules.variant == .yatzy)
        store.roll()
        #expect(!store.vorErstemZug)
        #expect(!store.regelnVorStart(Rules.fuer(.yacht)))
        #expect(store.game?.state.rules.variant == .yatzy)
    }
}

/// Zufallsquelle mit festem Anfang, damit Tests gleich ablaufen.
struct NeuZufall: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
