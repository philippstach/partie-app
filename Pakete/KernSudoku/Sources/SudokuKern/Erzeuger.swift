// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public enum SudokuStufe: String, Codable, CaseIterable, Sendable {
    case leicht, mittel, schwer, experte
}

/// Ein Rätsel mit seiner einzigen Lösung.
public struct SudokuRaetsel: Codable, Equatable, Sendable {
    public var form: SudokuForm
    public var vorgaben: [UInt8]
    public var loesung: [UInt8]
    public var stufe: SudokuStufe
    public var seed: UInt64

    public init(form: SudokuForm, vorgaben: [UInt8], loesung: [UInt8], stufe: SudokuStufe, seed: UInt64) {
        self.form = form; self.vorgaben = vorgaben; self.loesung = loesung; self.stufe = stufe; self.seed = seed
    }

    public var stimmig: Bool {
        vorgaben.count == form.zellen && loesung.count == form.zellen
            && vorgaben.allSatisfy { Int($0) <= form.n } && loesung.allSatisfy { (1...form.n).contains(Int($0)) }
    }
}

/// Erzeugt eindeutig lösbare Rätsel für alle Spielarten. Gleicher Seed und gleiche Angaben ergeben dasselbe Rätsel.
/// Die Stufe steuert die Zahl der Vorgaben; „Leicht“ verlangt zusätzlich, dass einzige Möglichkeit und einzige Stelle reichen.
public enum SudokuErzeuger {
    /// So viele Vorgaben bleiben höchstens stehen, wenn nicht mehr eindeutig wegzunehmen ist
    static func ziel(_ form: SudokuForm, _ stufe: SudokuStufe) -> Int {
        switch (form, stufe) {
        case (.kinder, .leicht): 22
        case (.kinder, .mittel): 18
        case (.kinder, _): 14
        case (.x, .leicht): 40
        case (.x, .mittel): 33
        case (.x, _): 27
        case (.klassisch, .leicht): 40
        case (.klassisch, .mittel): 34
        case (.klassisch, .schwer): 28
        case (.klassisch, .experte): 24
        }
    }

    public static func erzeuge(_ form: SudokuForm, _ stufe: SudokuStufe, seed: UInt64) -> SudokuRaetsel {
        var rng = SudokuZufall(seed: seed)
        let loesung = SudokuLoeser.zufaelligesGitter(form, using: &rng)
        let vorgaben = ausduennen(form, loesung, stufe, using: &rng)
        return SudokuRaetsel(form: form, vorgaben: vorgaben, loesung: loesung, stufe: stufe, seed: seed)
    }

    /// Nimmt punktsymmetrisch Paare weg, solange die Lösung eindeutig bleibt (bei „Leicht“ auch mit einfachen Mitteln lösbar)
    static func ausduennen(_ form: SudokuForm, _ loesung: [UInt8], _ stufe: SudokuStufe, using rng: inout SudokuZufall) -> [UInt8] {
        var gitter = loesung
        let zellen = form.zellen
        let zielAnzahl = ziel(form, stufe)
        var reihenfolge = Array(0...(zellen / 2))
        reihenfolge.shuffle(using: &rng)
        var vorhanden = zellen
        for i in reihenfolge {
            let j = zellen - 1 - i
            let schritt = i == j ? 1 : 2
            if vorhanden - schritt < zielAnzahl { continue }
            let (a, b) = (gitter[i], gitter[j])
            gitter[i] = 0; gitter[j] = 0
            let bleibt = SudokuLoeser.zaehle(form, gitter) == 1 && (stufe != .leicht || SudokuLoeser.einzelnLoesbar(form, gitter))
            if bleibt { vorhanden -= schritt } else { gitter[i] = a; gitter[j] = b }
        }
        return gitter
    }
}

/// Ergebnis der Prüfung eines selbst eingegebenen Rätsels
public enum SudokuPruefung: Equatable, Sendable {
    case leer
    /// Zellen, in denen eine Zahl in einer Einheit doppelt vorkommt
    case widerspruch(Set<Int>)
    case unloesbar
    case mehrdeutig
    case eindeutig([UInt8])

    public static func pruefe(_ form: SudokuForm, _ gitter: [UInt8]) -> SudokuPruefung {
        guard gitter.count == form.zellen else { return .unloesbar }
        if !gitter.contains(where: { $0 != 0 }) { return .leer }
        let doppelt = doppelte(form, gitter)
        if !doppelt.isEmpty { return .widerspruch(doppelt) }
        switch SudokuLoeser.zaehle(form, gitter) {
        case 0: return .unloesbar
        case 1: return .eindeutig(SudokuLoeser.loese(form, gitter) ?? gitter)
        default: return .mehrdeutig
        }
    }

    /// Zellen mit einer Zahl, die in einer Einheit ein zweites Mal vorkommt
    public static func doppelte(_ form: SudokuForm, _ gitter: [UInt8]) -> Set<Int> {
        var ergebnis = Set<Int>()
        for u in form.geometrie.einheiten {
            var gesehen = [UInt8: Int]()
            for z in u where gitter[z] != 0 {
                if let erste = gesehen[gitter[z]] { ergebnis.insert(erste); ergebnis.insert(z) } else { gesehen[gitter[z]] = z }
            }
        }
        return ergebnis
    }
}
