// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SudokuKern

/// „Sudoku“: Verbindung zwischen dem neuen Kern (`SudokuKern`, alle Spielarten) und den geteilten Teilen des Spielkerns
/// (Rätselbau mit Technik-Einstufung, Tipp-Erklärungen, Übungen, Tagesrätsel).
enum NeuBruecke {
    /// RT-041: Stufe der Schwierigkeitsleiter, auf der dieser Sieg zählt. Nur klassische Rätsel mit Stufe, weder Tages-, Übungs- noch eigene
    /// Rätsel; Kinder- und X-Sudoku schalten keine Klassisch-Stufen frei.
    static func leiterStufe(_ partie: SudokuPartie) -> Int? {
        guard partie.tagesschluessel == nil, partie.uebung == nil, !partie.eigen, partie.form == .klassisch else { return nil }
        return SudokuStufe.allCases.firstIndex(of: partie.raetsel.stufe)
    }

    static func difficulty(_ stufe: SudokuStufe) -> Difficulty {
        switch stufe {
        case .leicht: .easy
        case .mittel: .medium
        case .schwer: .hard
        case .experte: .expert
        }
    }

    static func stufe(_ d: Difficulty) -> SudokuStufe {
        switch d {
        case .easy: .leicht
        case .medium: .mittel
        case .hard: .schwer
        case .expert: .experte
        }
    }

    /// Baut ein Rätsel. Klassisch mit der Technik-Einstufung des alten Erzeugers, die anderen Spielarten mit dem neuen Kern.
    /// Läuft abseits des Hauptthreads (Schwer und Experte brauchen eine Weile).
    nonisolated static func raetsel(_ form: SudokuForm, _ stufe: SudokuStufe, seed: UInt64) -> SudokuRaetsel {
        guard form == .klassisch else { return SudokuErzeuger.erzeuge(form, stufe, seed: seed) }
        let p = Generator.generate(difficulty(stufe), seed: seed)
        return SudokuRaetsel(form: .klassisch, vorgaben: p.givens, loesung: p.solution, stufe: stufe, seed: seed)
    }

    /// Das Tagesrätsel: derselbe Bau wie in der alten App (Mittel, Seed aus dem Datum)
    nonisolated static func tagesraetsel(_ schluessel: String) -> SudokuRaetsel {
        let p = DailyPuzzle.puzzle(for: schluessel)
        return SudokuRaetsel(form: .klassisch, vorgaben: p.givens, loesung: p.solution, stufe: stufe(p.difficulty), seed: DailyPuzzle.seed(for: schluessel))
    }

    /// Das Feld im Format des Spielkerns (für Tipp-Erklärungen und Übungen)
    static func board(_ partie: SudokuPartie) -> Board {
        var b = Board(puzzle: Puzzle(givens: partie.raetsel.vorgaben, solution: partie.raetsel.loesung, difficulty: difficulty(partie.raetsel.stufe), seed: partie.raetsel.seed))
        guard partie.form.zellen == 81 else { return b }
        for i in 0..<81 { b.cells[i].value = partie.werte[i]; b.cells[i].notes = partie.notizen[i] }
        return b
    }

    // MARK: Übungen des Lernwegs

    static func technik(_ ref: SudokuUebungRef) -> Technique? { Technique(rawValue: ref.technik) }

    static func uebungPartie(_ t: Technique, _ nummer: Int) -> SudokuPartie? {
        guard let e = Exercises.exercise(t, nummer), e.values.count == 81, e.solution.count == 81 else { return nil }
        let r = SudokuRaetsel(form: .klassisch, vorgaben: e.values, loesung: e.solution, stufe: stufe(e.puzzle(for: t).difficulty), seed: UInt64(e.nr))
        return SudokuPartie(raetsel: r, uebung: SudokuUebungRef(technik: t.rawValue, nummer: nummer), startNotizen: e.masks)
    }

    static func uebungErledigt(_ partie: SudokuPartie) -> Bool {
        guard let ref = partie.uebung, let e = Exercises.exercise(for: ExerciseRef(technique: ref.technik, number: ref.nummer)) else { return false }
        return e.isDone(on: board(partie))
    }

    // MARK: Tipp

    /// Ein Tipp für die Anzeige
    struct Tipp: Equatable {
        var zelle: Int
        var ziffer: Int
        var titel: String
        var text: String
        var zusatz: String?
        var falsch: Bool
        /// Zellen des Musters (Rahmen)
        var muster: [Int]
        /// Zellen der Einheit (leicht hinterlegt)
        var einheit: [Int]
    }

    static func tipp(_ partie: SudokuPartie, bevorzugt: Int?) -> Tipp? {
        // Klassisch: die ausführlichen Erklärungen mit Technikname aus dem Spielkern
        if partie.form == .klassisch, let h = HintFinder.hint(for: board(partie), solution: partie.raetsel.loesung) {
            return Tipp(zelle: h.cell, ziffer: h.digit, titel: h.title, text: h.text, zusatz: h.note, falsch: h.kind == .mistake,
                        muster: h.pattern, einheit: h.unit)
        }
        guard let h = partie.hinweis(bevorzugt: bevorzugt) else { return nil }
        switch h.art {
        case .falsch:
            return Tipp(zelle: h.zelle, ziffer: h.ziffer, titel: String(localized: "Falsche Zahl"),
                        text: String(localized: "Diese Zahl stimmt nicht. Probier eine andere oder lösche sie."), zusatz: nil, falsch: true, muster: [], einheit: [])
        case .einzigeMoeglichkeit:
            return Tipp(zelle: h.zelle, ziffer: h.ziffer, titel: Technique.nakedSingle.title,
                        text: String(localized: "In diesem Feld passt nur noch eine Zahl."), zusatz: nil, falsch: false, muster: [], einheit: [])
        case .einzigeStelle:
            return Tipp(zelle: h.zelle, ziffer: h.ziffer, titel: Technique.hiddenSingle.title,
                        text: String(localized: "In der markierten Reihe, Spalte, Box oder Diagonale passt eine Zahl nur an diese Stelle."), zusatz: nil, falsch: false, muster: [], einheit: h.einheit)
        case .knifflig:
            let n = h.moeglichkeiten
            return Tipp(zelle: h.zelle, ziffer: h.ziffer, titel: String(localized: "Knifflig"),
                        text: String(localized: "Hier helfen die bekannten Tricks nicht mehr. Diese Zelle hat die wenigsten Möglichkeiten (\(n))."), zusatz: nil, falsch: false, muster: [], einheit: [])
        }
    }

    // MARK: Namen

    static func formName(_ f: SudokuForm) -> String {
        switch f {
        case .klassisch: String(localized: "Klassisch 9×9")
        case .kinder: String(localized: "Kinder 6×6")
        case .x: String(localized: "X-Sudoku")
        }
    }

    static func stufeName(_ s: SudokuStufe) -> String { difficulty(s).title }

    /// Titel der Partie für die Kopfzeile („Mittel“, „X-Sudoku · Leicht“, „Tagesrätsel“)
    static func titel(_ p: SudokuPartie) -> String {
        if p.tagesschluessel != nil { return String(localized: "Tagesrätsel") }
        if let ref = p.uebung, let t = technik(ref) { return t.title }
        let stufe = p.eigen ? String(localized: "Eigenes Rätsel") : stufeName(p.raetsel.stufe)
        return p.form == .klassisch ? stufe : "\(formName(p.form)) · \(stufe)"
    }
}

/// Kleine Ablage für „Sudoku“: gelöste Tage und geübte Aufgaben (eigene Schlüssel)
enum NeuAblage {
    static let id = "sudoku-neu"
    private static let tageKey = "sudoku-neu.tage"
    private static let uebungenKey = "sudoku-neu.uebungen"

    static func geloesteTage(_ d: UserDefaults = .standard) -> Set<String> { Set(d.stringArray(forKey: tageKey) ?? []) }
    static func tagGeloest(_ schluessel: String, _ d: UserDefaults = .standard) {
        var s = geloesteTage(d); s.insert(schluessel)
        d.set(Array(s), forKey: tageKey)
        TagesSerieWidget.melden(praefix: "sudoku", serie: DailyStreak.compute(solved: s, today: schluessel).length, letzterTag: s.max())   // C-016: Serie ins Widget
    }

    /// C-017: lokale Bestzeit je Spielart und Stufe (Sekunden). Game Center bleibt unverändert eine Liste.
    private static func bestKey(_ form: SudokuForm, _ stufe: SudokuStufe) -> String { "sudoku-neu.best.\(form).\(stufe)" }
    static func bestzeit(_ form: SudokuForm, _ stufe: SudokuStufe, _ d: UserDefaults = .standard) -> Int? {
        let w = d.integer(forKey: bestKey(form, stufe)); return w > 0 ? w : nil
    }
    /// Trägt die Zeit ein, wenn sie besser ist; `true` bei neuer Bestzeit (nicht beim ersten Lösen der Stufe).
    @discardableResult
    static func bestzeitMelden(_ form: SudokuForm, _ stufe: SudokuStufe, sekunden: Int, _ d: UserDefaults = .standard) -> Bool {
        guard sekunden > 0 else { return false }
        let alt = bestzeit(form, stufe, d)
        if let alt, alt <= sekunden { return false }
        d.set(sekunden, forKey: bestKey(form, stufe)); return alt != nil
    }

    static func geuebt(_ d: UserDefaults = .standard) -> Set<String> { Set(d.stringArray(forKey: uebungenKey) ?? []) }
    static func uebungGeschafft(_ ref: SudokuUebungRef, _ d: UserDefaults = .standard) {
        var s = geuebt(d); s.insert("\(ref.technik)-\(ref.nummer)")
        d.set(Array(s), forKey: uebungenKey)
    }
    static func istGeuebt(_ t: Technique, _ nummer: Int, in s: Set<String>) -> Bool { s.contains("\(t.rawValue)-\(nummer)") }
}
