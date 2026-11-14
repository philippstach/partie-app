// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import SpieleKern
@testable import SpielGalgenmaennchen

/// „Galgenmännchen“: Sitzung im Rahmen (Allein, Tagesrätsel, Überleben, Party, eigene Wörter), Ende für den Rahmen, Ablage.
@Suite("Galgenmännchen")
struct NeuTests {
    private func wort(_ t: String, _ k: SpielGalgenmaennchen.Category = .animals, _ d: Difficulty = .easy) -> Word {
        Word(text: t, solution: Letters.upper(t), category: k, difficulty: d)
    }

    private var liste: WordList {
        WordList(language: .de, version: 1, categories: [], words: [wort("Hund"), wort("Katze"), wort("Elefant", .animals, .medium), wort("Giraffe", .animals, .hard),
                                                               wort("Apfel", .food), wort("Brot", .food), wort("Käse", .food, .medium)])
    }

    private func defaults() -> UserDefaults {
        let n = "galgen-neu-test-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: n)!
        d.removePersistentDomain(forName: n)
        return d
    }

    private func loese(_ g: inout Game) { for c in Set(g.solution.filter { g.language.alphabet.contains($0) }) { g.guess(String(c)) } }
    private func verliere(_ g: inout Game) {
        for c in g.language.alphabet where !g.solution.contains(c) { g.guess(String(c)); if g.status == .lost { break } }
    }

    // MARK: Allein, Tag, eigene Wörter

    @Test func alleinGewonnenUndVerloren() throws {
        var s = NeuStand.allein(wort("Hund"), sprache: .de, kids: false)
        #expect(s.stimmig && s.fortsetzbar && s.aktuell?.status == .playing && s.endeAllein(name: "Anna") == nil)
        var g = try #require(s.aktuell)
        loese(&g)
        s.aktuell = g
        let e = try #require(s.endeAllein(name: "Anna"))
        #expect(e.arcade?.sieg == true && e.plaetze == nil && e.info?.contains("Hund") == true)
        #expect(e.werte.count == 2 && e.bild != nil, "Blatt 22: Fehler und Hinweise als Werte, Wort und Figur als Bild")
        #expect(!s.fortsetzbar, "beendetes Einzelspiel wird nicht fortgesetzt")

        var v = NeuStand.allein(wort("Hund"), sprache: .de, kids: false)
        var g2 = try #require(v.aktuell)
        verliere(&g2)
        v.aktuell = g2
        let el = try #require(v.endeAllein(name: "Anna"))
        #expect(el.arcade?.sieg == false && el.plaetze == [2], "Niederlage zählt für die Statistik als Platz 2")
        #expect(el.info?.contains("Hund") == true, "die Lösung steht im Ende")
    }

    @Test func tagUndEigenes() throws {
        let t = NeuStand.tag(wort("Katze"), sprache: .de, tag: "2026-11-09")
        #expect(t.modus == .daily && t.tag == "2026-11-09" && t.aktuell?.mode == .daily)
        let e = NeuStand.eigenes(solution: "OMA", text: "Oma", hinweis: "Wer backt Kuchen?", sprache: .de)
        #expect(e.aktuell?.hintText == "Wer backt Kuchen?" && e.aktuell?.category == nil)
        let ohne = NeuStand.eigenes(solution: "OPA", text: "Opa", hinweis: "", sprache: .de)
        #expect(ohne.aktuell?.hintText == nil)
    }

    @Test func tagesErgebnisUndSerie() {
        let d = defaults()
        #expect(NeuAblage.tagesErgebnis("2026-11-08", .de, d) == nil)
        NeuAblage.tagVerbuchen("2026-11-08", NeuTagesErgebnis(gewonnen: true, fehler: 1, hinweise: 0, sprache: .de), d)
        NeuAblage.tagVerbuchen("2026-11-09", NeuTagesErgebnis(gewonnen: true, fehler: 0, hinweise: 1, sprache: .de), d)
        #expect(NeuAblage.tagesErgebnis("2026-11-09", .de, d)?.hinweise == 1)
        #expect(NeuAblage.tagesErgebnis("2026-11-09", .en, d) == nil, "je Sprache ein Versuch")
        #expect(NeuAblage.tagesStats(d).displayedStreak(today: "2026-11-09") == 2)
        // Zweites Ergebnis am selben Tag zählt nicht in die Serie
        NeuAblage.tagVerbuchen("2026-11-09", NeuTagesErgebnis(gewonnen: false, fehler: 8, hinweise: 0, sprache: .en), d)
        #expect(NeuAblage.tagesStats(d).played == 2)
    }

    @Test func eigeneWoerterPruefenUndSpeichern() throws {
        let d = defaults()
        let ok = try NeuAblage.eigenesWort(text: "  Schul-Hof ", hinweis: " Pause ", sprache: .de).get()
        #expect(ok.loesung == "SCHUL-HOF" && ok.text == "Schul-Hof" && ok.hinweis == "Pause")
        #expect(throws: WordInputError.self) { try NeuAblage.eigenesWort(text: "ab", hinweis: "", sprache: .de).get() }
        #expect(throws: WordInputError.self) { try NeuAblage.eigenesWort(text: "Hallo1", hinweis: "", sprache: .de).get() }
        NeuAblage.eigeneSichern([ok], d)
        #expect(NeuAblage.eigene(d) == [ok])
    }

    @Test func wortziehenMerktUndWiederholtNichtSofort() {
        let d = defaults()
        var rng = SplitMix64(seed: 5)
        var gesehen = Set<String>()
        for _ in 0..<liste.words.count {
            let w = NeuAblage.ziehe(liste, kategorie: nil, stufe: nil, sprache: .de, defaults: d, rng: &rng)
            #expect(w != nil)
            if let w { #expect(gesehen.insert(w.solution).inserted, "kein Wort doppelt, bevor alle dran waren") }
        }
        #expect(NeuAblage.ziehe(liste, kategorie: .countries, stufe: nil, sprache: .de, defaults: d, rng: &rng) == nil)
    }

    // MARK: Überleben

    @Test func ueberlebenVerbuchtEinmalUndEndet() throws {
        var s = NeuStand.ueberleben(wort("Hund"), sprache: .de)
        var g = try #require(s.aktuell)
        verliere(&g); s.aktuell = g
        s.ueberlebenVerbuchen(); s.ueberlebenVerbuchen()
        #expect(s.survival?.lives == 2 && s.survival?.played == 1, "ein Leben weg, nur einmal verbucht")
        for _ in 0..<2 {
            s.ueberlebenNaechstes(wort("Katze"))
            var h = try #require(s.aktuell)
            verliere(&h); s.aktuell = h
            s.ueberlebenVerbuchen()
        }
        #expect(s.survival?.isOver == true)
        let e = s.endeUeberleben(name: "Anna")
        #expect(e.arcade?.punkte == 0 && e.arcade?.sieg == nil && e.reihenfolge == ["Anna"])
    }

    @Test func ueberlebenBonusLeben() throws {
        var s = NeuStand.ueberleben(wort("Hund"), sprache: .de)
        var run = SurvivalRun(); run.lives = 3; s.survival = run
        var g = try #require(s.aktuell)
        loese(&g); s.aktuell = g
        s.ueberlebenVerbuchen()
        #expect(s.survival?.lives == 4 && s.bonusLeben && s.survival?.wins == 1)
    }

    // MARK: Party

    @Test func partyMitEigenenWoertern() throws {
        var s = NeuStand.party(names: ["Anna", "Ben", "Cleo"], settings: PartySettings(), sprache: .de, erstesWort: nil)
        #expect(s.stimmig && s.party?.step == .giverHandover && s.party?.giver == 1 && s.party?.guesser == 0)
        s.partyWeiter(); #expect(s.party?.step == .entry)
        s.partyWort(solution: "ELEFANT", hinweis: "Grau und groß")
        #expect(s.party?.step == .guesserHandover && s.aktuell?.hintText == "Grau und groß")
        s.partyWeiter(); #expect(s.party?.step == .playing)
        s.partyRundeBeenden(); #expect(s.party?.step == .playing, "solange das Wort läuft, nichts verbuchen")
        var g = try #require(s.aktuell); loese(&g); s.aktuell = g
        s.partyRundeBeenden()
        #expect(s.party?.step == .score && s.party?.round == 1 && (s.party?.scores[0] ?? 0) >= 3)
        s.partyNaechsteRunde(wort: nil)
        #expect(s.party?.step == .giverHandover && s.aktuell == nil && s.party?.guesser == 1)
    }

    @Test func partyMitAppWoertern() throws {
        var einst = PartySettings(); einst.ownWords = false; einst.roundsPerPlayer = 1
        var s = NeuStand.party(names: ["Anna", "Ben"], settings: einst, sprache: .de, erstesWort: wort("Hund"))
        #expect(s.party?.step == .guesserHandover && s.aktuell?.solution == "HUND")
        s.partyWeiter()
        var g = try #require(s.aktuell); verliere(&g); s.aktuell = g
        s.partyRundeBeenden()
        #expect(s.party?.scores == [0, 0], "ohne eigene Wörter bekommt niemand die Wortgeber-Punkte")
        s.partyNaechsteRunde(wort: nil); #expect(s.party?.step == .score, "ohne neues Wort bleibt der Zwischenstand")
        s.partyNaechsteRunde(wort: wort("Katze"))
        #expect(s.party?.step == .guesserHandover && s.aktuell?.solution == "KATZE")
        s.partyWeiter()
        var g2 = try #require(s.aktuell); loese(&g2); s.aktuell = g2
        s.partyRundeBeenden()
        #expect(s.party?.isFinished == true)
        let e = try #require(s.endeParty())
        #expect(e.reihenfolge == ["Ben", "Anna"] && e.punkte.first.flatMap(Int.init) ?? 0 > 0 && e.plaetze == [1, 2])
        #expect(e.werte.count == 1 && e.bild == nil, "Blatt 22: Party zeigt nur „Runden“, kein Bild")
    }

    @Test func partyGleichstandUndVerdecken() throws {
        var m = PartyMatch(names: ["A", "B"], settings: PartySettings())
        m.scores = [4, 4]; m.round = m.totalRounds
        var s = NeuStand(modus: .party, sprache: .de, party: m)
        #expect(s.endeParty()?.plaetze == [1, 1])
        // Nach einem Neustart in der Spielphase bleibt das Wort verdeckt
        var p = NeuStand.party(names: ["A", "B"], settings: PartySettings(), sprache: .de, erstesWort: nil)
        p.partyWeiter(); p.partyWort(solution: "BAUM", hinweis: nil); p.partyWeiter()
        #expect(p.party?.step == .playing)
        p.partyVerdecken()
        #expect(p.party?.step == .guesserHandover)
        s.party?.round = 0
    }

    @Test func standCodableUndPruefung() throws {
        var s = NeuStand.party(names: ["A", "B", "C"], settings: PartySettings(), sprache: .en, erstesWort: nil)
        s.partyWeiter(); s.partyWort(solution: "TREE", hinweis: "Grows")
        let d = try JSONEncoder().encode(s)
        #expect(try JSONDecoder().decode(NeuStand.self, from: d) == s)
        var kaputt = s; kaputt.party?.scores = [0]
        #expect(!kaputt.stimmig && !kaputt.fortsetzbar)
        #expect(!NeuStand(modus: .single).stimmig)
        let ud = defaults()
        SpielStand.sichern(s, spiel: NeuAblage.id, defaults: ud)
        #expect(SpielStand.laden(NeuStand.self, spiel: NeuAblage.id, defaults: ud) == s)
    }

    @Test func zufallspartienEnden() throws {
        // Viele Partien mit zufälligen Eingaben: Spiel endet immer, Ende nennt alle genau einmal
        for seed in 1...20 {
            var rng = SplitMix64(seed: UInt64(seed))
            var einst = PartySettings(); einst.ownWords = false; einst.roundsPerPlayer = 2
            let namen = ["A", "B", "C"]
            var s = NeuStand.party(names: namen, settings: einst, sprache: .de, erstesWort: liste.words[rng.index(liste.words.count)])
            var guardZaehler = 0
            while s.party?.isFinished == false, guardZaehler < 50 {
                guardZaehler += 1
                s.partyWeiter()
                var g = try #require(s.aktuell)
                var buchstaben = g.language.alphabet
                buchstaben.shuffle(using: &rng)
                for c in buchstaben where g.status == .playing { g.guess(String(c)) }
                s.aktuell = g
                s.partyRundeBeenden()
                s.partyNaechsteRunde(wort: liste.words[rng.index(liste.words.count)])
            }
            let e = try #require(s.endeParty())
            #expect(Set(e.reihenfolge) == Set(namen) && e.reihenfolge.count == 3)
        }
    }

    @MainActor @Test func modulNebenAltemModul() {
        let neu = GalgenmaennchenModul()
        #expect(neu.id == "galgenmaennchen-neu" && neu.name == "Galgenmännchen" && neu.gattung == .wort && neu.spielerzahl == 1...4)
        #expect(NeuLayout.entscheide(breite: 390, hoehe: 844, sizeClass: .compact) == .kompakt)
        #expect(NeuLayout.entscheide(breite: 1180, hoehe: 820, sizeClass: .regular) == .breitQuer)
        #expect(NeuLayout.entscheide(breite: 820, hoehe: 1180, sizeClass: .regular) == .breitHoch)
    }
}
