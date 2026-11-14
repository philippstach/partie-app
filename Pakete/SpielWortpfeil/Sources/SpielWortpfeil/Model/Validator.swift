// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Prüft, ob ein Rätsel gültig ist. Liefert sortierte Fehlercodes (leer = gültig), siehe Doku/SPEZIFIKATION.md.
enum Validator {
    static let maxClueLength = 30

    static func check(_ p: Puzzle) -> [String] {
        var errors = Set<String>()
        if Level(rawValue: p.stufe) == nil { errors.insert("stufe_unbekannt") }

        let rows = p.gitter.map { Array($0.unicodeScalars) }
        if rows.count != p.hoehe || rows.contains(where: { $0.count != p.breite }) {
            errors.insert("gitter_groesse")
            return errors.sorted()
        }
        for row in rows {
            for ch in row where !(ch == "#" || ch == "-" || (ch.value >= 65 && ch.value <= 90)) {
                errors.insert("gitter_zeichen")
                return errors.sorted()
            }
        }

        var seen = Set<Clue3>()
        var words: [String] = []
        for clue in p.fragen {
            guard clue.direction != nil else { errors.insert("richtung_unbekannt"); continue }
            guard p.isClueCell(clue.cell) else { errors.insert("frage_nicht_im_fragefeld"); continue }
            if !seen.insert(Clue3(clue)).inserted { errors.insert("frage_doppelt") }
            if clue.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors.insert("fragetext_leer") }
            if clue.text.unicodeScalars.count > maxClueLength { errors.insert("fragetext_zu_lang") }
            if let k = clue.kurz, !k.isEmpty {
                if k.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { errors.insert("fragetext_leer") }
                if k.unicodeScalars.count > maxClueLength { errors.insert("fragetext_zu_lang") }
            }
            if p.wordCells(clue).count < 2 { errors.insert("wort_zu_kurz"); continue }
            words.append(p.solutionWord(clue))
        }

        var starts = Set<RunKey>()
        for clue in p.fragen {
            if let d = clue.direction, let s = clue.start { starts.insert(RunKey(d, s)) }
        }
        var covered = Set<Pos>()
        for run in runs(p) {
            if !starts.contains(RunKey(run.direction, run.start)) { errors.insert("wort_ohne_frage") }
            for i in 0..<run.length { covered.insert(run.start.moved(run.direction, by: i)) }
        }
        if p.letterCells.contains(where: { !covered.contains($0) }) { errors.insert("buchstabe_ohne_wort") }

        for r in 0..<p.hoehe {
            for c in 0..<p.breite where p.isClueCell(Pos(r, c)) && p.clues(inCell: Pos(r, c)).isEmpty {
                errors.insert("fragefeld_ohne_frage")
            }
        }
        if Set(words).count != words.count { errors.insert("wort_doppelt") }
        if let l = p.loesung, !l.isEmpty {
            let cells = p.solutionCells
            if cells.count != l.count || Set(cells).count != cells.count
                || !(3...12).contains(cells.count) || cells.contains(where: { !p.isLetter($0) }) {
                errors.insert("loesung_ungueltig")
            }
        }
        return errors.sorted()
    }

    private struct Clue3: Hashable {
        let r: Int, c: Int, d: String
        init(_ clue: Clue) { r = clue.zeile; c = clue.spalte; d = clue.richtung }
    }

    private struct RunKey: Hashable {
        let d: Direction, p: Pos
        init(_ d: Direction, _ p: Pos) { self.d = d; self.p = p }
    }

    /// Alle zusammenhängenden Buchstabenfolgen ab Länge 2
    private static func runs(_ p: Puzzle) -> [(direction: Direction, start: Pos, length: Int)] {
        var out: [(Direction, Pos, Int)] = []
        for d in Direction.allCases {
            for cell in p.letterCells where !p.isLetter(cell.moved(d, by: -1)) {
                var n = 0
                while p.isLetter(cell.moved(d, by: n)) { n += 1 }
                if n >= 2 { out.append((d, cell, n)) }
            }
        }
        return out
    }
}
