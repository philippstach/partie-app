// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Alles, was das Gitter zum Zeichnen braucht (laufendes Spiel oder fertig ausgefülltes Beispiel).
struct GridData {
    var puzzle: Puzzle
    var entries: [Pos: Character] = [:]
    var cursor: Pos?
    var activeCells: Set<Pos> = []
    var activeClue: Clue?
    var revealed: Set<Pos> = []
    var marked: Set<Pos> = []
    /// Falsche Felder, die rot gezeigt werden („Fehler sofort zeigen“)
    var shownWrong: Set<Pos> = []
    /// Mit Bleistift eingetragen: grau und dünn
    var uncertain: Set<Pos> = []
    /// Felder, die gerade schütteln
    var shake: GameStore.Wave?
    /// Lösungswort-Felder mit ihrer Nummer (1…n)
    var solutionIndex: [Pos: Int] = [:]

    init(puzzle: Puzzle, entries: [Pos: Character] = [:]) {
        self.puzzle = puzzle
        self.entries = entries
        solutionIndex = Dictionary(uniqueKeysWithValues: puzzle.solutionCells.enumerated().map { ($1, $0 + 1) })
    }

    init(game: Game, showErrors: Bool) {
        puzzle = game.puzzle
        solutionIndex = Dictionary(uniqueKeysWithValues: game.puzzle.solutionCells.enumerated().map { ($1, $0 + 1) })
        entries = game.entries
        cursor = game.cursor
        activeCells = Set(game.activeCells)
        activeClue = game.activeClue
        revealed = game.revealed
        marked = game.marked
        uncertain = game.uncertain
        shownWrong = showErrors ? Set(game.wrongCells) : []
    }

    /// Das fertig gelöste Rätsel (Regeln-Bildschirm)
    static func solved(_ puzzle: Puzzle) -> GridData {
        var d = GridData(puzzle: puzzle)
        for p in puzzle.letterCells { d.entries[p] = puzzle.solution(p) }
        return d
    }
}
