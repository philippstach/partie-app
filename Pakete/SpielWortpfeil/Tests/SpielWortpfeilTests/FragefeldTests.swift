// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import SwiftUI
@testable import SpielWortpfeil

struct FragefeldTests {
    @Test func trenntNurAnSilbengrenzen() {
        let h = ClueFit.hyphenated("Hinterseite des Körpers")
        #expect(h.contains("\u{00AD}"))
        #expect(h.replacingOccurrences(of: "\u{00AD}", with: "") == "Hinterseite des Körpers")
        #expect(!ClueFit.hyphenated("Wal Aal").contains("\u{00AD}"))   // kurze Wörter bleiben ganz
    }

    @Test func kurzerTextBleibtGroß() {
        let r = ClueFit.fit("Haus", width: 40, height: 40, base: 12)
        #expect(r.fits && r.size == 12 && r.lines == 1)
    }

    @Test func langerTextWirdKleinerAberNieUnterMindestgroesse() {
        let r = ClueFit.fit("Hinterseite des Körpers", width: 30, height: 34, base: 12)
        #expect(r.size >= ClueFit.minSize && r.size < 12)
    }

    @Test func passtNichtGibtFalseStattFalscherTrennung() {
        let r = ClueFit.fit("Donaudampfschifffahrtsgesellschaftskapitän", width: 20, height: 12, base: 10)
        #expect(!r.fits && r.size == ClueFit.minSize)
    }

    /// Gleiche Eingabe wie das Mac-Werkzeug: ein paar feste Fälle mit erwartetem Ergebnis (verhindert, dass App und Werkzeug auseinanderlaufen)
    /// Erwartete Werte stammen aus `Tools/fragefeld_messen.sh` (macOS); weichen iOS und Mac ab, ist das hier rot.
    @Test func festeBeispieleFuerDasMacWerkzeug() {
        func f(_ t: String, _ cell: CGFloat, split: Bool) -> (Bool, CGFloat) {
            let r = ClueFit.fitField(t, cell: cell, bottom: split, split: split)
            return (r.fits, r.size)
        }
        #expect(f("Haus", 36, split: true) == (true, 9.0))
        #expect(f("Zweite Tonsilbe", 36, split: true).0 == false)
        #expect(f("Zweite Tonsilbe", 36, split: false) == (true, 9.0))
        #expect(f("Hinterseite des Körpers", 36, split: false).0 == false)
        #expect(f("Kaffee", 48, split: false) == (true, 11.5))
    }

    /// Schreibt alle Fragen, die in einem kleinen Feld (36 pt) auch in Mindestschrift nicht passen, nach /tmp (für den Architekten).
    @Test func listeDerFragenDieNichtInKleineFelderPassen() throws {
        let lib = PackLibrary(directory: Shared.root.appending(path: "raetsel"))
        var lines: [String] = []
        var total = 0
        for name in PackLibrary.names {
            let puzzles = name == "taeglich" ? lib.daily : lib.puzzles(Level(rawValue: name) ?? .mittel)
            for p in puzzles {
                for clue in p.fragen {
                    total += 1
                    let split = p.clues(inCell: clue.cell).count == 2
                    let cell: CGFloat = name == "leicht" ? 48 : name == "schwer" ? 34 : 36   // reale Feldgrößen auf dem iPhone
                    let r = ClueFit.fitField(clue.boxText, cell: cell, bottom: clue.direction == .unten, split: split)
                    if !r.fits { lines.append("\(name)\t\(p.id)\t\(clue.richtung)\t\(split ? "geteilt" : "einzeln")\t\(clue.text)") }
                }
            }
        }
        let report = "Fragen, die bei den realen Feldgrößen (leicht 48, mittel/täglich 36, schwer 34 pt) auch in 8 pt (einzeln) bzw. 7 pt (geteilt) nicht passen: \(lines.count) von \(total)\n" + lines.joined(separator: "\n")
        try report.write(toFile: "/tmp/kw-nichtpassende-fragen.txt", atomically: true, encoding: .utf8)
        #expect(total > 0)
    }
}
