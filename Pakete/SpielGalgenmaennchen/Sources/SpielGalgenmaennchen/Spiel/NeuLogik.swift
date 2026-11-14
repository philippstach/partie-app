// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SwiftUI
import SpieleKern

/// „Galgenmännchen“: Zustand einer Sitzung im SpielRahmen und die Logik drumherum (ohne Oberfläche, mit Tests prüfbar).
/// Regeln, Wörter, Punkte und Serien kommen aus dem Spielkern (`Game`, `PartyMatch`, `SurvivalRun`, `WordPicker`, `DailyWord`), das unverändert bleibt (Regel A.8).
struct NeuStand: Codable, Equatable, Sendable {
    var modus: GameMode = .single
    var sprache: WordLanguage = .de
    /// Das Spiel (Allein, Tagesrätsel, Überleben); in der Party liegt es in `party.game`
    var game: Game?
    var survival: SurvivalRun?
    var party: PartyMatch?
    /// Tag des Tagesrätsels („2026-11-09“)
    var tag: String?
    /// Überleben: Das beendete Wort ist schon verbucht
    var wortVerbucht = false
    /// Überleben: Das beendete Wort hat ein Leben zurückgebracht
    var bonusLeben = false

    // MARK: Start

    static func allein(_ w: Word, sprache: WordLanguage, kids: Bool) -> NeuStand {
        NeuStand(modus: .single, sprache: sprache, game: Game(solution: w.solution, language: sprache, category: w.category, difficulty: w.difficulty,
                                                             displayText: w.text, kids: kids))
    }

    /// Eigenes Wort aus der Wortliste der Familie (ohne Kategorie, mit freiem Hinweis)
    static func eigenes(solution: String, text: String, hinweis: String?, sprache: WordLanguage) -> NeuStand {
        NeuStand(modus: .single, sprache: sprache, game: Game(solution: solution, language: sprache, hintText: hinweis?.isEmpty == true ? nil : hinweis, displayText: text))
    }

    static func tag(_ w: Word, sprache: WordLanguage, tag: String) -> NeuStand {
        NeuStand(modus: .daily, sprache: sprache, game: Game(solution: w.solution, language: sprache, category: w.category, difficulty: w.difficulty,
                                                           mode: .daily, displayText: w.text), tag: tag)
    }

    static func ueberleben(_ w: Word, sprache: WordLanguage) -> NeuStand {
        var s = NeuStand(modus: .survival, sprache: sprache, survival: SurvivalRun())
        s.game = Game(solution: w.solution, language: sprache, category: w.category, difficulty: w.difficulty, mode: .survival, displayText: w.text)
        return s
    }

    static func party(names: [String], settings: PartySettings, sprache: WordLanguage, erstesWort: Word?) -> NeuStand {
        var m = PartyMatch(names: names, settings: settings)
        if let w = erstesWort, !settings.ownWords { m.game = Self.partySpiel(w, sprache); m.step = .guesserHandover }
        return NeuStand(modus: .party, sprache: sprache, party: m)
    }

    private static func partySpiel(_ w: Word, _ sprache: WordLanguage) -> Game {
        Game(solution: w.solution, language: sprache, category: w.category, difficulty: w.difficulty, mode: .party, displayText: w.text)
    }

    // MARK: Zugriff

    /// Das Spiel, das gerade auf dem Bildschirm ist (Party: das der Runde)
    var aktuell: Game? {
        get { modus == .party ? party?.game : game }
        set { if modus == .party { party?.game = newValue } else { game = newValue } }
    }

    /// Ein neu gestartetes Spiel mit unbeendetem Stand ist stimmig; kaputte Stände werden beim Laden verworfen
    var stimmig: Bool {
        switch modus {
        case .party:
            guard let p = party, (2...PartyMatch.maxPlayers).contains(p.players), p.scores.count == p.players, p.lastGain.count == p.players else { return false }
            return p.game.map { $0.solution.count >= WordInput.minLetters } ?? true
        default:
            return game.map { !$0.solution.isEmpty } ?? false
        }
    }

    // MARK: Überleben

    /// Verbucht das beendete Wort einmal. Danach gilt `survival` mit neuen Leben.
    mutating func ueberlebenVerbuchen() {
        guard modus == .survival, !wortVerbucht, let g = game, g.status != .playing, var run = survival else { return }
        bonusLeben = run.finishWord(won: g.status == .won, mistakes: g.mistakes, hints: g.hints.count)
        survival = run
        wortVerbucht = true
    }

    mutating func ueberlebenNaechstes(_ w: Word) {
        game = Game(solution: w.solution, language: sprache, category: w.category, difficulty: w.difficulty, mode: .survival, displayText: w.text)
        wortVerbucht = false
        bonusLeben = false
    }

    // MARK: Party

    /// Übergabe bestätigt: Wortgeber → Eingabe, Rater → Spiel
    mutating func partyWeiter() {
        guard var m = party else { return }
        switch m.step {
        case .giverHandover: m.step = .entry
        case .guesserHandover: m.step = .playing
        default: return
        }
        party = m
    }

    mutating func partyWort(solution: String, hinweis: String?) {
        guard var m = party else { return }
        let h = hinweis.map { String($0.trimmingCharacters(in: .whitespacesAndNewlines).prefix(WordInput.maxHintLength)) }
        m.game = Game(solution: solution, language: sprache, mode: .party, hintText: h?.isEmpty == true ? nil : h)
        m.step = .guesserHandover
        party = m
    }

    /// Das Wort der Runde ist erraten oder gescheitert: Punkte verbuchen, Zwischenstand zeigen (einmal)
    mutating func partyRundeBeenden() {
        guard var m = party, m.step == .playing, let g = m.game, g.status != .playing else { return }
        m.finishRound(won: g.status == .won, mistakes: g.mistakes, hints: g.hints.count)
        party = m
    }

    /// Nach dem Zwischenstand: nächste Runde vorbereiten (eigene Wörter: Wortgeber; App-Wörter: `wort`). Nach der letzten Runde nichts.
    mutating func partyNaechsteRunde(wort: Word?) {
        guard var m = party, m.step == .score, !m.isFinished else { return }
        if m.settings.ownWords {
            m.game = nil
            m.step = .giverHandover
        } else if let w = wort {
            m.game = Self.partySpiel(w, sprache)
            m.step = .guesserHandover
        } else {
            return
        }
        party = m
    }

    /// Nach einem Neustart der App bleibt das Wort bis zur Übergabe verdeckt
    mutating func partyVerdecken() {
        if party?.step == .playing { party?.step = .guesserHandover }
    }

    // MARK: Ende für den Rahmen

    /// Allein, Tagesrätsel und eigene Wörter: Sieg mit Wort und Fehlern, Niederlage mit der Lösung
    func endeAllein(name: String) -> SpielEnde? {
        guard let g = game, g.status != .playing else { return nil }
        let wort = g.displayText ?? g.solution
        let gewonnen = g.status == .won
        // Blatt 22 (EB-3): der Satz nennt nur das Wort; Fehler und Hinweise stehen als Werte, die Figur als Bild
        var e = SpielEnde(reihenfolge: [name], plaetze: gewonnen ? nil : [2], info: String(localized: "Das Wort war \(wort)"), arcade: ArcadeAusgang(punkte: 8 - g.mistakes, sieg: gewonnen))
        e.werte = [EndeWert("Fehler", "\(g.mistakes)"), EndeWert("Hinweise", "\(g.hints.count)")]
        let uebrig = 8 - g.mistakes
        e.bild = EndeBild(Text("Das Wort und die Figur am Ende"), hoehe: 150) { groesse in
            GalgenEndeBild(wort: wort, uebrig: uebrig, gewonnen: gewonnen, groesse: groesse)
        }
        return e
    }

    func endeUeberleben(name: String) -> SpielEnde {
        let wins = survival?.wins ?? 0
        let grund = String(localized: "\(wins) Wörter gelöst")
        return SpielEnde(reihenfolge: [name], arcade: ArcadeAusgang(punkte: wins, sieg: nil, grund: grund, kennzahlen: ["stufe": 2]))
    }

    func endeParty() -> SpielEnde? {
        guard let m = party, m.isFinished else { return nil }
        let rang = m.ranking
        var e = SpielEnde(reihenfolge: rang.map { m.names[$0] }, punkte: rang.map { String(m.scores[$0]) }, plaetze: rang.map { m.places[$0] },
                          info: nil)
        e.werte = [EndeWert("Runden", "\(m.totalRounds)")]   // Blatt 22 (EB-3): „Runden“ ist jetzt ein Wert statt des Satzes
        return e
    }
}

// MARK: - Ablage (UserDefaults, eigene Schlüssel)

/// Ergebnis des Tagesrätsels eines Tages (ein Versuch pro Tag)
struct NeuTagesErgebnis: Codable, Equatable, Sendable {
    var gewonnen: Bool
    var fehler: Int
    var hinweise: Int
    var sprache: WordLanguage
}

/// Ein Wort der eigenen Wortliste („Familie“, „Schule“)
struct EigenesWort: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    /// Normalisierte Lösung (Großbuchstaben)
    var loesung: String
    /// Schreibweise des Eintrags
    var text: String
    var hinweis: String?
}

enum NeuAblage {
    static let id = "galgenmaennchen-neu"
    private static let recentKey = "galgen-neu.recent."
    private static let tageKey = "galgen-neu.tage"
    private static let tageStatsKey = "galgen-neu.tagesstats"
    private static let eigeneKey = "galgen-neu.eigene"

    // Zuletzt gespielte Wörter je Sprache
    static func recent(_ s: WordLanguage, _ d: UserDefaults = .standard) -> [String] { d.stringArray(forKey: recentKey + s.rawValue) ?? [] }
    static func merke(_ solution: String, _ s: WordLanguage, _ d: UserDefaults = .standard) {
        d.set(WordPicker.remember(solution, in: recent(s, d)), forKey: recentKey + s.rawValue)
    }

    // Tagesrätsel
    static func tagesErgebnis(_ tag: String, _ s: WordLanguage, _ d: UserDefaults = .standard) -> NeuTagesErgebnis? {
        guard let dict = d.data(forKey: tageKey).flatMap({ try? JSONDecoder().decode([String: NeuTagesErgebnis].self, from: $0) }) else { return nil }
        return dict["\(tag)|\(s.rawValue)"]
    }
    static func tagVerbuchen(_ tag: String, _ e: NeuTagesErgebnis, _ d: UserDefaults = .standard) {
        var dict = d.data(forKey: tageKey).flatMap { try? JSONDecoder().decode([String: NeuTagesErgebnis].self, from: $0) } ?? [:]
        dict["\(tag)|\(e.sprache.rawValue)"] = e
        if dict.count > 120 { for k in dict.keys.sorted().prefix(dict.count - 120) { dict[k] = nil } }
        if let daten = try? JSONEncoder().encode(dict) { d.set(daten, forKey: tageKey) }
        var st = tagesStats(d)
        st.record(won: e.gewonnen, day: tag)
        if let daten = try? JSONEncoder().encode(st) { d.set(daten, forKey: tageStatsKey) }
        if d === UserDefaults.standard { TagesSerieWidget.melden(praefix: "galgen", serie: st.streak, letzterTag: st.lastWin) }   // C-040: Tagesserie ans Widget
    }
    static func tagesStats(_ d: UserDefaults = .standard) -> DailyStats {
        d.data(forKey: tageStatsKey).flatMap { try? JSONDecoder().decode(DailyStats.self, from: $0) } ?? DailyStats()
    }

    // Eigene Wörter
    static func eigene(_ d: UserDefaults = .standard) -> [EigenesWort] {
        d.data(forKey: eigeneKey).flatMap { try? JSONDecoder().decode([EigenesWort].self, from: $0) } ?? []
    }
    static func eigeneSichern(_ liste: [EigenesWort], _ d: UserDefaults = .standard) {
        if let daten = try? JSONEncoder().encode(liste) { d.set(daten, forKey: eigeneKey) }
    }

    /// Prüft und normalisiert ein eigenes Wort
    static func eigenesWort(text: String, hinweis: String, sprache: WordLanguage) -> Result<EigenesWort, WordInputError> {
        switch WordInput.normalize(text, language: sprache) {
        case .failure(let f): return .failure(f)
        case .success(let l):
            let h = String(hinweis.trimmingCharacters(in: .whitespacesAndNewlines).prefix(WordInput.maxHintLength))
            return .success(EigenesWort(loesung: l, text: text.trimmingCharacters(in: .whitespacesAndNewlines), hinweis: h.isEmpty ? nil : h))
        }
    }

    /// Wortliste einer Sprache aus dem App-Paket (leer, wenn nicht ladbar)
    nonisolated(unsafe) private static var listen: [WordLanguage: WordList] = [:]
    static func liste(_ s: WordLanguage) -> WordList {
        if let l = listen[s] { return l }
        let l = (try? WordList.load(s)) ?? .empty
        if !l.words.isEmpty { listen[s] = l }
        return l
    }

    /// Zieht ein Wort der Auswahl (nicht die zuletzt gespielten) und merkt es sich
    static func ziehe(_ liste: WordList, kategorie: Category?, stufe: Difficulty?, sprache: WordLanguage, defaults: UserDefaults = .standard,
                      rng: inout some RandomNumberGenerator) -> Word? {
        guard let w = WordPicker.pick(from: liste.words, category: kategorie, difficulty: stufe, recent: recent(sprache, defaults), rng: &rng) else { return nil }
        merke(w.solution, sprache, defaults)
        return w
    }
}
