// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Laufrichtung eines Wortes.
enum Direction: String, Codable, CaseIterable, Sendable {
    case rechts, unten

    var step: (dr: Int, dc: Int) { self == .rechts ? (0, 1) : (1, 0) }
    var other: Direction { self == .rechts ? .unten : .rechts }
    /// Reihenfolge für „nächste/vorige Frage“: rechts vor unten
    var order: Int { self == .rechts ? 0 : 1 }
}

/// Stufe eines Rätsels.
enum Level: String, Codable, CaseIterable, Identifiable, Sendable {
    case leicht, mittel, schwer
    var id: String { rawValue }
}

/// Position im Gitter (Zeile 0 oben, Spalte 0 links).
struct Pos: Hashable, Codable, Comparable, Sendable {
    var r: Int
    var c: Int

    init(_ r: Int, _ c: Int) { self.r = r; self.c = c }

    static func < (a: Pos, b: Pos) -> Bool { (a.r, a.c) < (b.r, b.c) }
    func moved(_ d: Direction, by n: Int = 1) -> Pos { Pos(r + d.step.dr * n, c + d.step.dc * n) }
}

/// Eine Frage steht in einem Fragefeld und zeigt nach rechts oder unten.
/// `richtung` bleibt Text, damit ein Paket mit unbekannter Richtung geladen und vom Prüfer gemeldet werden kann.
struct Clue: Codable, Hashable, Sendable {
    var zeile: Int
    var spalte: Int
    var richtung: String
    var text: String
    /// Optionaler Kurztext fürs Kästchen; Frageleiste und VoiceOver zeigen immer `text`
    var kurz: String?

    /// Text im Kästchen: `kurz`, wenn vorhanden (leer gilt als fehlend), sonst `text`
    var boxText: String { (kurz?.isEmpty == false) ? kurz! : text }

    var direction: Direction? { Direction(rawValue: richtung) }
    var cell: Pos { Pos(zeile, spalte) }
    /// Erstes Feld des Wortes
    var start: Pos? { direction.map { cell.moved($0) } }
}

/// Ein Rätsel: Gitter mit Fragefeldern (`#`), Leerfeldern (`-`) und Lösungsbuchstaben (`A`–`Z`).
struct Puzzle: Codable, Equatable, Identifiable, Sendable {
    var id: String
    var stufe: String
    var breite: Int
    var hoehe: Int
    var gitter: [String]
    var fragen: [Clue]
    /// Lösungswort (optional): Buchstabenfelder in Lesereihenfolge als `[zeile, spalte]`
    var loesung: [[Int]]?
    /// Themen-Rätsel: id des Themas (`themen.json`), sonst nil
    var thema: String?

    init(id: String, stufe: String = "mittel", breite: Int, hoehe: Int, gitter: [String], fragen: [Clue],
         loesung: [[Int]]? = nil, thema: String? = nil) {
        self.thema = thema
        self.id = id; self.stufe = stufe; self.breite = breite; self.hoehe = hoehe
        self.gitter = gitter; self.fragen = fragen; self.loesung = loesung
    }

    /// Fehlende Felder bekommen Standardwerte, unbekannte werden ignoriert.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        stufe = try c.decodeIfPresent(String.self, forKey: .stufe) ?? "mittel"
        breite = try c.decode(Int.self, forKey: .breite)
        hoehe = try c.decode(Int.self, forKey: .hoehe)
        gitter = try c.decode([String].self, forKey: .gitter)
        fragen = try c.decodeIfPresent([Clue].self, forKey: .fragen) ?? []
        loesung = try? c.decodeIfPresent([[Int]].self, forKey: .loesung)
        thema = try? c.decodeIfPresent(String.self, forKey: .thema)
    }

    /// Felder des Lösungsworts in Lesereihenfolge (leer, wenn das Rätsel keins hat)
    var solutionCells: [Pos] { (loesung ?? []).compactMap { $0.count == 2 ? Pos($0[0], $0[1]) : nil } }

    /// Das Lösungswort aus dem Gitter (leer ohne Lösungswort)
    var solutionWordText: String { String(solutionCells.compactMap { cell($0) }) }

    var level: Level { Level(rawValue: stufe) ?? .mittel }

    // MARK: Felder

    /// Zeichen im Gitter; `nil` außerhalb
    func cell(_ p: Pos) -> Character? {
        guard p.r >= 0, p.r < hoehe, p.r < gitter.count, p.c >= 0, p.c < breite else { return nil }
        let row = gitter[p.r]
        guard p.c < row.count else { return nil }
        return row[row.index(row.startIndex, offsetBy: p.c)]
    }

    func isLetter(_ p: Pos) -> Bool {
        guard let ch = cell(p), let a = ch.asciiValue else { return false }
        return a >= 65 && a <= 90
    }

    func isClueCell(_ p: Pos) -> Bool { cell(p) == "#" }

    func solution(_ p: Pos) -> Character? { isLetter(p) ? cell(p) : nil }

    var letterCells: [Pos] {
        var out: [Pos] = []
        for r in 0..<hoehe { for c in 0..<breite where isLetter(Pos(r, c)) { out.append(Pos(r, c)) } }
        return out
    }

    // MARK: Fragen und Wörter

    /// Alle Felder des Wortes ab Startfeld in Pfeilrichtung
    func wordCells(_ clue: Clue) -> [Pos] {
        guard let d = clue.direction, var p = clue.start else { return [] }
        var out: [Pos] = []
        while isLetter(p) { out.append(p); p = p.moved(d) }
        return out
    }

    func solutionWord(_ clue: Clue) -> String {
        String(wordCells(clue).compactMap { cell($0) })
    }

    /// Fragen mit gültiger Richtung: Fragefeld zeilenweise, rechts vor unten
    var sortedClues: [Clue] {
        fragen.filter { $0.direction != nil }
            .sorted { ($0.zeile, $0.spalte, $0.direction!.order) < ($1.zeile, $1.spalte, $1.direction!.order) }
    }

    /// Die Frage, deren Wort in `direction` durch das Buchstabenfeld läuft
    func clue(at p: Pos, direction: Direction) -> Clue? {
        guard isLetter(p) else { return nil }
        var q = p
        while isLetter(q.moved(direction, by: -1)) { q = q.moved(direction, by: -1) }
        return fragen.first { $0.direction == direction && $0.start == q }
    }

    /// Fragen eines Fragefelds, rechts vor unten
    func clues(inCell p: Pos) -> [Clue] {
        fragen.filter { $0.cell == p && $0.direction != nil }.sorted { $0.direction!.order < $1.direction!.order }
    }
}

/// Ein Thema im Themenpaket (`themen.json`, Kopf `themen`)
struct ThemeInfo: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var de: String
    var en: String
    var es: String? = nil
    var fr: String? = nil
    /// SF-Symbol
    var symbol: String

    /// Name in der Sprache der Oberfläche (Deutsch, Spanisch, Französisch, sonst Englisch)
    var name: String {
        switch Locale.current.language.languageCode?.identifier {
        case "de": return de
        case "es": return es ?? en
        case "fr": return fr ?? en
        default: return en
        }
    }
}

/// Eine Paketdatei (`Shared/raetsel/*.json`).
struct PuzzlePack: Codable, Equatable, Sendable {
    var format = 1
    var paket = ""
    var version = ""
    var demo = false
    var raetsel: [Puzzle] = []
    var themen: [ThemeInfo] = []

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        format = try c.decodeIfPresent(Int.self, forKey: .format) ?? 1
        paket = try c.decodeIfPresent(String.self, forKey: .paket) ?? ""
        version = try c.decodeIfPresent(String.self, forKey: .version) ?? ""
        demo = try c.decodeIfPresent(Bool.self, forKey: .demo) ?? false
        raetsel = try c.decodeIfPresent([Puzzle].self, forKey: .raetsel) ?? []
        themen = (try? c.decodeIfPresent([ThemeInfo].self, forKey: .themen)) ?? []
    }

    static func load(from url: URL) -> PuzzlePack? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(PuzzlePack.self, from: data)
    }
}
