// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Ein Tipp: eine Zelle, die richtige Zahl und warum.
public struct SudokuHinweis: Equatable, Sendable {
    public enum Art: Equatable, Sendable {
        /// Eine Zahl im Feld ist falsch
        case falsch
        /// In der Zelle passt nur eine Zahl
        case einzigeMoeglichkeit
        /// Die Zahl passt in einer Einheit nur an diese Stelle
        case einzigeStelle
        /// Einfache Schritte reichen nicht mehr: die Zelle mit den wenigsten Möglichkeiten
        case knifflig
    }
    public var art: Art
    public var zelle: Int
    public var ziffer: Int
    /// Zellen der Einheit bei „einzige Stelle“
    public var einheit: [Int]
    /// Wie viele Zahlen in der Zelle noch passen
    public var moeglichkeiten: Int

    public static func naechster(_ form: SudokuForm, werte: [UInt8], loesung: [UInt8], bevorzugt: Int? = nil) -> SudokuHinweis? {
        let n = form.zellen
        guard werte.count == n, loesung.count == n else { return nil }
        if let falsch = (0..<n).first(where: { werte[$0] != 0 && werte[$0] != loesung[$0] }) {
            return SudokuHinweis(art: .falsch, zelle: falsch, ziffer: Int(loesung[falsch]), einheit: [], moeglichkeiten: 0)
        }
        let k = SudokuLoeser.kandidaten(form, werte)
        let offen = (0..<n).filter { werte[$0] == 0 }
        guard !offen.isEmpty else { return nil }
        // Zuerst die gewählte Zelle, wenn dort eine Zahl zwingend ist
        let einzel = offen.filter { k[$0].nonzeroBitCount == 1 }
        if let z = bevorzugt.flatMap({ einzel.contains($0) ? $0 : nil }) ?? einzel.first {
            return SudokuHinweis(art: .einzigeMoeglichkeit, zelle: z, ziffer: Int(loesung[z]), einheit: [], moeglichkeiten: 1)
        }
        var stellen: [SudokuHinweis] = []
        for u in form.geometrie.einheiten {
            for d in 1...form.n {
                let b = SudokuForm.bit(d)
                if u.contains(where: { werte[$0] == UInt8(d) }) { continue }
                let orte = u.filter { werte[$0] == 0 && k[$0] & b != 0 }
                if orte.count == 1 {
                    stellen.append(SudokuHinweis(art: .einzigeStelle, zelle: orte[0], ziffer: d, einheit: u, moeglichkeiten: k[orte[0]].nonzeroBitCount))
                }
            }
        }
        if let s = stellen.first(where: { $0.zelle == bevorzugt }) ?? stellen.first { return s }
        let z = offen.min(by: { (k[$0].nonzeroBitCount, $0) < (k[$1].nonzeroBitCount, $1) })!
        return SudokuHinweis(art: .knifflig, zelle: z, ziffer: Int(loesung[z]), einheit: [], moeglichkeiten: max(2, k[z].nonzeroBitCount))
    }
}
