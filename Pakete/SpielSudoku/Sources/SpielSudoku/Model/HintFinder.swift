// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Ein Tipp: zeigt eine Zelle und erklärt in einem Satz, warum.
struct Hint: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        /// Eine Zahl im Feld ist falsch
        case mistake
        /// Der nächste Schritt des Logik-Lösers
        case step
        /// Die bekannten Techniken greifen nicht mehr
        case guess
    }

    var kind: Kind
    var cell: Int
    /// Die richtige Zahl der Zelle
    var digit: Int
    var technique: Technique?
    var title: String
    var text: String
    /// Zellen, die das Muster bilden (Rahmen in der App-Farbe)
    var pattern: [Int]
    /// Die Einheit(en) des Schritts, leicht in der App-Farbe hinterlegt
    var unit: [Int] = []
    /// Kandidaten, die der Streich-Schritt entfernt (Notizen werden rot durchgestrichen)
    var eliminations: [Elimination] = []
    /// Nur Färben: Zellen der Farbe 0 (gefüllt), die übrigen Musterzellen sind Farbe 1 (gestrichelt umrandet)
    var color0: [Int] = []
    /// W1d: Geister-Notizen, solange der Tipp offen ist: Musterzelle → Ziffern, die als blasse Notiz erscheinen, wenn der Spieler
    /// sie nicht notiert hat. Nur Anzeige, die Notizen des Spielers bleiben unverändert.
    var ghosts: [Int: UInt16] = [:]
    /// W1c: zweiter Satz unter der Erklärung („Danach hilft nur Probieren …“)
    var note: String?

    struct Elimination: Equatable, Sendable {
        var cell: Int
        var mask: UInt16
    }
}

enum HintFinder {
    /// Der nächste sinnvolle Tipp für das Feld. Zuerst falsche Zahlen, dann der nächste Logik-Schritt.
    /// Braucht ein nicht fertiges Feld.
    static func hint(for board: Board, solution: [UInt8]) -> Hint? {
        if let wrong = (0..<81).first(where: { board.cells[$0].value != 0 && board.cells[$0].value != solution[$0] }) {
            return Hint(kind: .mistake, cell: wrong, digit: Int(solution[wrong]), technique: nil,
                        title: String(localized: "Falsche Zahl"),
                        text: String(localized: "Diese Zahl stimmt nicht. Probier eine andere oder lösche sie."),
                        pattern: [])
        }

        let tip = nextTip(values: board.values, solution: solution)
        guard let cell = tip.cell else { return nil }
        let shown = tip.step
        let pattern: [Int] = shown.map { (step: LogicStep) -> [Int] in
            if let unit = step.unit, step.technique == .hiddenSingle { return Units.all[unit] }
            return step.pattern
        } ?? []
        switch tip.art {
        case .number:
            let step = shown!
            return Hint(kind: .step, cell: cell, digit: tip.digit, technique: step.technique, title: step.technique.title,
                        text: step.explanation(reveal: false), pattern: pattern.filter { $0 != cell },
                        unit: unitCells(of: step),
                        eliminations: step.eliminations.map { .init(cell: $0.cell, mask: $0.mask) }, color0: step.color0,
                        ghosts: ghosts(technique: step.technique, pattern: step.pattern, digits: step.digits, candidates: tip.candidates))
        case .eliminate, .fewest:
            // W1c: keine Zahl mehr in Sicht. Gab es Streich-Schritte, zeigt der Tipp den schwersten; dazu der Hinweis aufs Probieren.
            let n = tip.possibilities
            let guess = String(localized: "Danach hilft nur Probieren: Diese Zelle hat die wenigsten Möglichkeiten (\(n)).")
            guard let step = shown else {
                return Hint(kind: .guess, cell: cell, digit: tip.digit, technique: nil, title: String(localized: "Knifflig"),
                            text: String(localized: "Hier helfen die bekannten Tricks nicht mehr. Diese Zelle hat die wenigsten Möglichkeiten (\(n))."),
                            pattern: [])
            }
            return Hint(kind: .guess, cell: cell, digit: tip.digit, technique: step.technique, title: step.technique.title,
                        text: step.explanation(reveal: false), pattern: pattern, unit: unitCells(of: step),
                        eliminations: step.eliminations.map { .init(cell: $0.cell, mask: $0.mask) }, color0: step.color0,
                        ghosts: ghosts(technique: step.technique, pattern: step.pattern, digits: step.digits, candidates: tip.candidates),
                        note: guess)
        }
    }

    /// Ergebnis der Tipp-Regel (W1c), unabhängig von der Darstellung. Gemeinsamer Testfall: `Shared/regeltests/tipps.json`.
    struct Tip {
        enum Art { case number, eliminate, fewest }
        var art: Art
        var cell: Int?
        var digit: Int
        /// Der gezeigte Schritt (schwerster Streich-Schritt, bei einer Zahl auch der Zahl-Schritt selbst)
        var step: LogicStep?
        var possibilities: Int = 0
        /// Kandidaten des Löser-Standes, in dem der gezeigte Schritt gefunden wurde (für die Geister-Notizen)
        var candidates: [UInt16] = []
    }

    /// Geister-Notizen für Streich-Tipps: in den Musterzellen die Tipp-Ziffern (beim XY-Flügel alle Kandidaten der drei Zellen)
    static func ghosts(technique: Technique, pattern: [Int], digits: UInt16, candidates: [UInt16]) -> [Int: UInt16] {
        guard technique != .nakedSingle, technique != .hiddenSingle, candidates.count == 81 else { return [:] }
        var result = [Int: UInt16]()
        for cell in pattern {
            let mask = technique == .xyWing ? candidates[cell] : digits & candidates[cell]
            if mask != 0 { result[cell] = mask }
        }
        return result
    }

    /// Der Löser startet frisch aus den Werten (Stufe 4). Gezeigt wird der schwerste Streich-Schritt vor der nächsten Zahl
    /// (höchste Stufe, bei gleicher Stufe der erste). Folgt keine Zahl mehr: Zielzelle mit den wenigsten Kandidaten nach allen
    /// Streichungen (bei Gleichstand die kleinste Nummer).
    static func nextTip(values: [UInt8], solution: [UInt8]) -> Tip {
        var logic = LogicBoard(grid: values)
        var hardest: LogicStep?
        var hardestCandidates = [UInt16]()
        for _ in 0..<400 {
            guard !logic.isSolved, let step = logic.nextStep(maxLevel: 4) else { break }
            if let place = step.placement {
                return Tip(art: .number, cell: place.cell, digit: place.digit, step: hardest ?? step,
                           candidates: hardest == nil ? logic.candidates : hardestCandidates)
            }
            if hardest == nil || step.technique.level > hardest!.technique.level { hardest = step; hardestCandidates = logic.candidates }
            logic.apply(step)
        }
        let open = (0..<81).filter { values[$0] == 0 }
        guard let cell = open.min(by: { logic.candidates[$0].nonzeroBitCount < logic.candidates[$1].nonzeroBitCount }) else {
            return Tip(art: .fewest, cell: nil, digit: 0, step: nil)
        }
        return Tip(art: hardest == nil ? .fewest : .eliminate, cell: cell, digit: Int(solution[cell]), step: hardest,
                   possibilities: max(2, logic.candidates[cell].nonzeroBitCount), candidates: hardestCandidates)
    }

    /// Zellen der Einheit eines Schritts. Beim X-Wing (ohne Einheit) die beiden Grundlinien.
    static func unitCells(of step: LogicStep) -> [Int] {
        if let unit = step.unit { return Units.all[unit] }
        guard step.technique == .xWing, step.pattern.count == 4 else { return [] }
        let rows = Set(step.pattern.map(Units.row)), cols = Set(step.pattern.map(Units.col))
        // Gestrichen wird in den Deckungslinien; die Grundlinien sind die anderen
        let rowBased = step.eliminations.allSatisfy { cols.contains(Units.col($0.cell)) }
        return rowBased ? rows.flatMap { Units.rows[$0] } : cols.flatMap { Units.cols[$0] }
    }
}
