// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum GameStatus: Equatable, Sendable { case playing, won, lost }
enum GuessResult: Equatable, Sendable { case hit, miss, alreadyGuessed, invalid, over }
/// Ergebnis von „Lösen“ (ganzes Wort raten)
enum SolveResult: Equatable, Sendable { case solved, wrong, alreadyTried, invalid, over }
/// Art des Hinweises: irgendein Buchstabe, der erste Buchstabe des Wortes oder ein Vokal
enum HintKind: String, CaseIterable, Sendable { case random, first, vowel }
enum GameMode: String, Codable, Sendable { case single, daily, party, survival }

/// Eine Runde. Reine Logik ohne Oberfläche; alles Weitere ergibt sich aus `solution` und `guessed`.
struct Game: Codable, Equatable, Sendable {
    static let maxHints = 2
    /// Kinderleicht: mehr Hinweise
    static let kidsMaxHints = 4
    static let solvePenalty = 2

    var solution: String
    var language: WordLanguage
    /// Kategorie und Stufe des Wortes (Zwei Spieler: nil)
    var category: Category?
    var difficulty: Difficulty?
    var mode: GameMode
    /// Freier Hinweis von Spieler A (Zwei Spieler)
    var hintText: String?
    /// Schreibweise für den Ende-Bildschirm (Liste: `wort`), sonst die Lösung
    var displayText: String?
    /// Alle getippten oder aufgedeckten Buchstaben in Reihenfolge
    var guessed: [Character] = []
    /// Per Hinweis aufgedeckt (Teilmenge von `guessed`)
    var hints: [Character] = []
    var maxMistakes = 8
    /// Kinderleicht-Runde (nur leichte Wörter, mehr Hinweise)
    var kids = false
    /// Falsche Lösen-Versuche (normalisiert); jeder kostet `solvePenalty` Ballons
    var wrongSolves: [String] = []

    enum CodingKeys: String, CodingKey {
        case solution, language, category, difficulty, mode, hintText, displayText, guessed, hints, maxMistakes, wrongSolves, kids
    }

    init(solution: String, language: WordLanguage, category: Category? = nil, difficulty: Difficulty? = nil,
         mode: GameMode = .single, hintText: String? = nil, displayText: String? = nil, maxMistakes: Int = 8,
         kids: Bool = false) {
        self.kids = kids
        self.solution = solution
        self.language = language
        self.category = category
        self.difficulty = difficulty
        self.mode = mode
        self.hintText = hintText
        self.displayText = displayText
        self.maxMistakes = maxMistakes
    }

    /// Fehlende Felder beim Laden → Standardwert.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        solution = try c.decode(String.self, forKey: .solution)
        language = try c.decodeIfPresent(WordLanguage.self, forKey: .language) ?? .de
        category = try c.decodeIfPresent(Category.self, forKey: .category)
        difficulty = try c.decodeIfPresent(Difficulty.self, forKey: .difficulty)
        mode = try c.decodeIfPresent(GameMode.self, forKey: .mode) ?? .single
        hintText = try c.decodeIfPresent(String.self, forKey: .hintText)
        displayText = try c.decodeIfPresent(String.self, forKey: .displayText)
        guessed = Array(try c.decodeIfPresent(String.self, forKey: .guessed) ?? "")
        hints = Array(try c.decodeIfPresent(String.self, forKey: .hints) ?? "")
        maxMistakes = try c.decodeIfPresent(Int.self, forKey: .maxMistakes) ?? 8
        wrongSolves = try c.decodeIfPresent([String].self, forKey: .wrongSolves) ?? []
        kids = try c.decodeIfPresent(Bool.self, forKey: .kids) ?? false
    }

    /// Buchstabenlisten werden als Text gespeichert (`Character` ist nicht direkt speicherbar).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(solution, forKey: .solution)
        try c.encode(language, forKey: .language)
        try c.encodeIfPresent(category, forKey: .category)
        try c.encodeIfPresent(difficulty, forKey: .difficulty)
        try c.encode(mode, forKey: .mode)
        try c.encodeIfPresent(hintText, forKey: .hintText)
        try c.encodeIfPresent(displayText, forKey: .displayText)
        try c.encode(String(guessed), forKey: .guessed)
        try c.encode(String(hints), forKey: .hints)
        try c.encode(maxMistakes, forKey: .maxMistakes)
        try c.encode(wrongSolves, forKey: .wrongSolves)
        try c.encode(kids, forKey: .kids)
    }

    // MARK: Abgeleitet

    /// Die zu erratenden Buchstaben (ohne Leerzeichen und Bindestrich)
    private var letters: Set<Character> { Set(solution.filter { language.alphabet.contains($0) }) }

    var wrongLetters: [Character] { guessed.filter { !letters.contains($0) } }
    /// Falsche Buchstaben + 2 je falschem Lösen-Versuch, höchstens `maxMistakes`
    var mistakes: Int { min(maxMistakes, wrongLetters.count + Self.solvePenalty * wrongSolves.count) }

    var status: GameStatus {
        if letters.isSubset(of: guessed) { return .won }
        if mistakes >= maxMistakes { return .lost }
        return .playing
    }

    /// Verdeckte Buchstaben als `_`; bei „verloren“ das ganze Wort.
    var display: String {
        let revealAll = status == .lost
        return String(solution.map { c in
            Letters.open.contains(c) || guessed.contains(c) || revealAll ? c : "_"
        })
    }

    /// Anzahl der noch verdeckten Stellen im Wort (für die Aufdeck-Welle)
    var hiddenCount: Int {
        solution.filter { !(Letters.open.contains($0) || guessed.contains($0)) }.count
    }

    /// Noch verdeckte Buchstaben in Alphabet-Reihenfolge
    private var hiddenLetters: [Character] {
        language.alphabet.filter { letters.contains($0) && !guessed.contains($0) }
    }

    var hintLimit: Int { kids ? Self.kidsMaxHints : Self.maxHints }

    var canHint: Bool {
        status == .playing && hints.count < hintLimit && hiddenLetters.count >= 2
    }

    // MARK: Aktionen

    @discardableResult
    mutating func guess(_ input: String) -> GuessResult {
        guard status == .playing else { return .over }
        let upper = Letters.upper(input)
        guard upper.count == 1, let c = upper.first, language.alphabet.contains(c) else { return .invalid }
        guard !guessed.contains(c) else { return .alreadyGuessed }
        guessed.append(c)
        return letters.contains(c) ? .hit : .miss
    }

    /// Ganzes Wort raten. Die Eingabe läuft durch dieselbe Normalisierung wie bei Zwei Spieler.
    @discardableResult
    mutating func solve(_ input: String) -> SolveResult {
        guard status == .playing else { return .over }
        guard case .success(let attempt) = WordInput.normalize(input, language: language) else { return .invalid }
        if attempt == solution {
            guessed.append(contentsOf: hiddenLetters)   // alle Buchstaben stehen offen
            return .solved
        }
        guard !wrongSolves.contains(attempt) else { return .alreadyTried }
        wrongSolves.append(attempt)
        return .wrong
    }

    private static let vowels: Set<Character> = ["A", "E", "I", "O", "U", "Ä", "Ö", "Ü"]

    /// Verdeckte Buchstaben, die zu dieser Hinweis-Art passen
    private func candidates(for kind: HintKind) -> [Character] {
        switch kind {
        case .random: return hiddenLetters
        case .first:
            guard let first = solution.first(where: { language.alphabet.contains($0) }) else { return [] }
            return hiddenLetters.contains(first) ? [first] : []
        case .vowel: return hiddenLetters.filter { Self.vowels.contains($0) }
        }
    }

    func canHint(_ kind: HintKind) -> Bool { canHint && !candidates(for: kind).isEmpty }

    /// Deckt einen verdeckten Buchstaben auf (alle Stellen). nil, wenn nicht möglich.
    mutating func hint(_ kind: HintKind = .random, using rng: inout some RandomNumberGenerator) -> Character? {
        guard canHint(kind) else { return nil }
        let candidates = candidates(for: kind)
        let c = candidates[rng.index(candidates.count)]
        guessed.append(c)
        hints.append(c)
        return c
    }
}
