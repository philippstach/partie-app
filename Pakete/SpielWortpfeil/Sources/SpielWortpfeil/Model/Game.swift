// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum GameStatus: String, Codable, Sendable { case laeuft, voll_mit_fehlern, geloest }

/// Ein laufendes oder beendetes Spiel samt Rätsel (damit ein Paket-Update es nicht kaputt macht).
/// Reine Logik ohne Oberfläche, Regeln siehe Doku/SPEZIFIKATION.md.
struct Game: Codable, Equatable, Identifiable, Sendable {
    var id = UUID()
    var puzzle: Puzzle
    var entries: [Pos: Character] = [:]
    var cursor: Pos?
    var direction: Direction = .rechts
    var revealed: Set<Pos> = []
    /// Von „prüfen“ als falsch erkannte Felder
    var marked: Set<Pos> = []
    var hints = 0
    /// Mit Bleistift eingetragene (unsichere) Felder
    var uncertain: Set<Pos> = []
    var pencil = false
    /// Gespielte Zeit in Sekunden bis zum letzten Speichern
    var elapsed: Double = 0
    var finished = false
    /// Tagesrätsel: Datum „2026-10-04“, sonst `nil`
    var dailyKey: String?
    /// Ein schon gelöstes Rätsel noch einmal gespielt: zählt nicht in Statistik und Fortschritt
    var replay = false
    /// Aus dem Archiv gestartetes Tagesrätsel vergangener Tage: zählt nicht zur Serie
    var archive = false

    /// `startHelp`: Anfangsbuchstabe jedes Wortes ist vorgegeben (gesperrt, zählt nicht als Hilfe)
    init(puzzle: Puzzle, dailyKey: String? = nil, startHelp: Bool = false) {
        self.puzzle = puzzle
        self.dailyKey = dailyKey
        if startHelp {
            for clue in puzzle.fragen {
                if let first = puzzle.wordCells(clue).first, let ch = puzzle.solution(first) {
                    entries[first] = ch
                    revealed.insert(first)
                }
            }
        }
        if let first = puzzle.sortedClues.first { jump(to: first) }
    }

    // MARK: Codable (fehlende Felder → Standardwert)

    private struct EntryRecord: Codable { var r: Int; var c: Int; var v: String }

    private enum Keys: String, CodingKey {
        case id, puzzle, entries, cursor, direction, revealed, marked, hints, uncertain, pencil, elapsed, finished, dailyKey, replay, archive
    }

    init(from decoder: Decoder) throws {
        let k = try decoder.container(keyedBy: Keys.self)
        id = k.lenient(UUID.self, .id, default: UUID())
        puzzle = try k.decode(Puzzle.self, forKey: .puzzle)
        let records = k.lenient([EntryRecord].self, .entries, default: [])
        for e in records { if let ch = e.v.first { entries[Pos(e.r, e.c)] = ch } }
        cursor = k.lenient(Pos?.self, .cursor, default: nil)
        direction = k.lenient(Direction.self, .direction, default: .rechts)
        revealed = k.lenient(Set<Pos>.self, .revealed, default: [])
        marked = k.lenient(Set<Pos>.self, .marked, default: [])
        hints = k.lenient(Int.self, .hints, default: 0)
        uncertain = k.lenient(Set<Pos>.self, .uncertain, default: [])
        pencil = k.lenient(Bool.self, .pencil, default: false)
        elapsed = k.lenient(Double.self, .elapsed, default: 0)
        finished = k.lenient(Bool.self, .finished, default: false)
        dailyKey = k.lenient(String?.self, .dailyKey, default: nil)
        replay = k.lenient(Bool.self, .replay, default: false)
        archive = k.lenient(Bool.self, .archive, default: false)
        // Beschädigte Spielstände glätten: nur Buchstabenfelder des Rätsels, nur A–Z, sinnvolle Zeit
        entries = entries.filter { puzzle.isLetter($0.key) && ("A"..."Z").contains($0.value) }
        revealed = revealed.filter { puzzle.isLetter($0) }
        marked = marked.filter { puzzle.isLetter($0) }
        uncertain = uncertain.filter { puzzle.isLetter($0) }
        hints = max(0, hints)
        if !elapsed.isFinite || elapsed < 0 { elapsed = 0 }
        if let c = cursor, !puzzle.isLetter(c) {
            cursor = nil
            if let first = puzzle.sortedClues.first { jump(to: first) }
        }
    }

    func encode(to encoder: Encoder) throws {
        var k = encoder.container(keyedBy: Keys.self)
        try k.encode(id, forKey: .id)
        try k.encode(puzzle, forKey: .puzzle)
        try k.encode(entries.sorted { $0.key < $1.key }.map { EntryRecord(r: $0.key.r, c: $0.key.c, v: String($0.value)) },
                     forKey: .entries)
        try k.encodeIfPresent(cursor, forKey: .cursor)
        try k.encode(direction, forKey: .direction)
        try k.encode(revealed.sorted(), forKey: .revealed)
        try k.encode(marked.sorted(), forKey: .marked)
        try k.encode(hints, forKey: .hints)
        try k.encode(uncertain.sorted(), forKey: .uncertain)
        try k.encode(pencil, forKey: .pencil)
        try k.encode(elapsed, forKey: .elapsed)
        try k.encode(finished, forKey: .finished)
        try k.encodeIfPresent(dailyKey, forKey: .dailyKey)
        try k.encode(replay, forKey: .replay)
        try k.encode(archive, forKey: .archive)
    }

    // MARK: Abgeleitete Werte

    var level: Level { puzzle.level }

    var activeClue: Clue? {
        cursor.flatMap { puzzle.clue(at: $0, direction: direction) }
    }

    var activeCells: [Pos] { activeClue.map { puzzle.wordCells($0) } ?? [] }

    /// Felder mit Eintrag, der nicht zur Lösung passt
    var wrongCells: [Pos] {
        entries.filter { $0.value != puzzle.solution($0.key) }.map(\.key).sorted()
    }

    var status: GameStatus {
        if puzzle.letterCells.contains(where: { entries[$0] == nil }) { return .laeuft }
        return wrongCells.isEmpty ? .geloest : .voll_mit_fehlern
    }

    /// Einträge des Lösungsworts, `.` für leer (leer ohne Lösungswort)
    var solutionProgress: String {
        String(puzzle.solutionCells.map { entries[$0] ?? "." })
    }

    /// Lösungswort vollständig und richtig
    var solutionComplete: Bool {
        let cells = puzzle.solutionCells
        return !cells.isEmpty && cells.allSatisfy { entries[$0] != nil && entries[$0] == puzzle.solution($0) }
    }

    /// Anteil gefüllter Buchstabenfelder (0…1)
    var progress: Double {
        let cells = puzzle.letterCells
        guard !cells.isEmpty else { return 1 }
        return Double(cells.filter { entries[$0] != nil }.count) / Double(cells.count)
    }

    // MARK: Aktionen

    mutating func tap(_ p: Pos) {
        if puzzle.isLetter(p) {
            if cursor == p {
                if puzzle.clue(at: p, direction: direction.other) != nil { direction = direction.other }
                return
            }
            cursor = p
            if puzzle.clue(at: p, direction: direction) == nil { direction = direction.other }
            return
        }
        let clues = puzzle.clues(inCell: p)
        guard var target = clues.first else { return }
        if clues.count == 2, activeClue == clues[0] { target = clues[1] }
        jump(to: target)
    }

    /// Getippte Zeichen: ä ergibt AE usw.; Rest verfällt, wenn der Cursor nicht weiterkommt.
    mutating func type(_ text: String) {
        for ch in Normalizer.normalize(text) {
            if !place(ch) { break }
        }
    }

    mutating func togglePencil() { pencil.toggle() }

    mutating func delete() {
        guard let cur = cursor else { return }
        if entries[cur] != nil, !revealed.contains(cur) { clear(cur); return }
        let cells = activeCells
        guard let i = cells.firstIndex(of: cur), i > 0 else { return }
        cursor = cells[i - 1]
        if !revealed.contains(cells[i - 1]) { clear(cells[i - 1]) }
    }

    mutating func moveToClue(step: Int) {
        let clues = puzzle.sortedClues
        guard !clues.isEmpty else { return }
        let i = activeClue.flatMap { clues.firstIndex(of: $0) } ?? -1
        jump(to: clues[(((i + step) % clues.count) + clues.count) % clues.count])
    }

    /// Pfeiltaste (Hardware-Tastatur): nächstes Buchstabenfeld in dieser Richtung; die Richtung passt sich an.
    /// `forward` false = nach links bzw. oben.
    mutating func moveCursor(_ d: Direction, forward: Bool) {
        guard let cur = cursor else { return }
        let n = forward ? 1 : -1
        var q = cur.moved(d, by: n)
        while puzzle.cell(q) != nil, !puzzle.isLetter(q) { q = q.moved(d, by: n) }
        guard puzzle.isLetter(q) else { return }
        cursor = q
        if puzzle.clue(at: q, direction: d) != nil { direction = d }
        else if puzzle.clue(at: q, direction: direction) == nil { direction = d.other }
    }

    mutating func revealLetter() {
        guard let cur = cursor, !revealed.contains(cur), let solution = puzzle.solution(cur) else { return }
        entries[cur] = solution
        revealed.insert(cur)
        marked.remove(cur)
        uncertain.remove(cur)
        hints += 1
    }

    /// Alle noch nicht aufgedeckten Felder des aktiven Wortes bekommen die Lösung (gesperrt), Hilfen +1 (nur bei Änderung);
    /// danach Sprung zur nächsten Frage mit Lücke wie nach einem vollen Wort.
    mutating func revealWord() {
        let cells = activeCells.filter { !revealed.contains($0) }
        guard !cells.isEmpty, let active = activeClue else { return }
        for pos in cells {
            entries[pos] = puzzle.solution(pos)
            revealed.insert(pos)
            marked.remove(pos)
            uncertain.remove(pos)
        }
        hints += 1
        let clues = puzzle.sortedClues
        guard let start = clues.firstIndex(of: active) else { return }
        for k in 1...clues.count {
            let next = clues[(start + k) % clues.count]
            if puzzle.wordCells(next).contains(where: { entries[$0] == nil }) { jump(to: next); break }
        }
    }

    @discardableResult
    mutating func checkWord() -> Int {
        let wrong = Set(wrongCells)
        let bad = activeCells.filter { entries[$0] != nil && wrong.contains($0) }
        marked.formUnion(bad)
        hints += 1
        return bad.count
    }

    @discardableResult
    mutating func checkPuzzle() -> Int {
        let wrong = wrongCells
        marked.formUnion(wrong)
        hints += 1
        return wrong.count
    }

    // MARK: Intern

    mutating func jump(to clue: Clue) {
        let cells = puzzle.wordCells(clue)
        guard let first = cells.first, let d = clue.direction else { return }
        direction = d
        cursor = cells.first { entries[$0] == nil } ?? first
    }

    /// Schreibt `ch` und bewegt den Cursor (kluger Cursor). `false`: Rest einer Mehrfacheingabe verfällt.
    /// - Wort war schon voll (Korrektur): ein Feld weiter, am Wortende bleibt der Cursor stehen.
    /// - Sonst: nächstes leeres Feld hinter der Stelle, gibt es keins, das erste leere davor.
    /// - Ist das Wort danach voll: Sprung zur nächsten Frage mit Lücke (ringförmig), sonst bleibt der Cursor.
    private mutating func place(_ ch: Character) -> Bool {
        guard let cur = cursor else { return false }
        let cells = activeCells
        guard var i = cells.firstIndex(of: cur) else { return false }
        while i < cells.count, revealed.contains(cells[i]) { i += 1 }
        if i == cells.count { return false }
        let wasFull = cells.allSatisfy { entries[$0] != nil }
        entries[cells[i]] = ch
        marked.remove(cells[i])
        if pencil { uncertain.insert(cells[i]) } else { uncertain.remove(cells[i]) }
        if wasFull {
            cursor = cells[min(i + 1, cells.count - 1)]
            return i + 1 < cells.count
        }
        let empty = cells.indices.filter { entries[cells[$0]] == nil }
        if !empty.isEmpty {
            cursor = cells[empty.first { $0 > i } ?? empty[0]]
            return true
        }
        cursor = cells[i]
        let clues = puzzle.sortedClues
        if let active = activeClue, let start = clues.firstIndex(of: active) {
            for k in 1...clues.count {
                let next = clues[(start + k) % clues.count]
                if puzzle.wordCells(next).contains(where: { entries[$0] == nil }) { jump(to: next); break }
            }
        }
        return false
    }

    private mutating func clear(_ p: Pos) {
        entries[p] = nil
        marked.remove(p)
        uncertain.remove(p)
    }
}
