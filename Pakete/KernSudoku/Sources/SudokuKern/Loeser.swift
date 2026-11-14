// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Lösungssuche (Backtracking mit Bitmasken) für alle Spielarten. Ein Gitter ist ein Array mit n² Zahlen, 0 = leer.
public enum SudokuLoeser {
    public static func loese(_ form: SudokuForm, _ gitter: [UInt8]) -> [UInt8]? {
        var s = Suche(form, gitter, limit: 1)
        s?.lauf()
        return s?.loesung
    }

    /// Zählt Lösungen und bricht bei `limit` ab (Standard 2: „eindeutig?“)
    public static func zaehle(_ form: SudokuForm, _ gitter: [UInt8], limit: Int = 2) -> Int {
        var s = Suche(form, gitter, limit: limit)
        s?.lauf()
        return s?.anzahl ?? 0
    }

    /// Ein zufälliges, vollständig gefülltes, gültiges Gitter
    public static func zufaelligesGitter(_ form: SudokuForm, using rng: inout SudokuZufall) -> [UInt8] {
        var s = Suche(form, [UInt8](repeating: 0, count: form.zellen), limit: 1)!
        s.rng = rng
        s.lauf()
        rng = s.rng!
        return s.loesung!
    }

    /// Kandidaten aller Zellen nur aus den Zahlen im Gitter (gefüllte Zellen: 0)
    public static func kandidaten(_ form: SudokuForm, _ gitter: [UInt8]) -> [UInt16] {
        let g = form.geometrie
        return (0..<form.zellen).map { z in
            guard gitter[z] == 0 else { return 0 }
            var benutzt: UInt16 = 0
            for p in g.nachbarn[z] where gitter[p] != 0 { benutzt |= SudokuForm.bit(Int(gitter[p])) }
            return ~benutzt & form.alle
        }
    }

    /// Ist das Rätsel allein mit „einzige Möglichkeit“ und „einzige Stelle“ lösbar?
    public static func einzelnLoesbar(_ form: SudokuForm, _ start: [UInt8]) -> Bool {
        let g = form.geometrie
        var w = start
        while true {
            if !w.contains(0) { return true }
            let k = kandidaten(form, w)
            var geaendert = false
            for z in 0..<form.zellen where w[z] == 0 {
                if k[z].nonzeroBitCount == 1 { w[z] = UInt8(k[z].trailingZeroBitCount + 1); geaendert = true; break }
            }
            if geaendert { continue }
            suche: for u in g.einheiten {
                for d in 1...form.n {
                    let b = SudokuForm.bit(d)
                    if u.contains(where: { w[$0] == UInt8(d) }) { continue }
                    let orte = u.filter { w[$0] == 0 && k[$0] & b != 0 }
                    if orte.count == 1 { w[orte[0]] = UInt8(d); geaendert = true; break suche }
                }
            }
            if !geaendert { return false }
        }
    }

    private struct Suche {
        let form: SudokuForm
        let g: SudokuGeometrie
        var werte: [UInt8]
        var benutzt: [UInt16]
        let limit: Int
        var anzahl = 0
        var loesung: [UInt8]?
        var rng: SudokuZufall?

        init?(_ form: SudokuForm, _ gitter: [UInt8], limit: Int) {
            guard gitter.count == form.zellen else { return nil }
            self.form = form
            g = form.geometrie
            werte = gitter
            self.limit = limit
            benutzt = [UInt16](repeating: 0, count: g.einheiten.count)
            for z in 0..<form.zellen where gitter[z] != 0 {
                guard Int(gitter[z]) <= form.n else { return nil }
                let bit = SudokuForm.bit(Int(gitter[z]))
                for u in g.einheitenJeZelle[z] {
                    if benutzt[u] & bit != 0 { return nil }
                    benutzt[u] |= bit
                }
            }
        }

        func maske(_ z: Int) -> UInt16 {
            var b: UInt16 = 0
            for u in g.einheitenJeZelle[z] { b |= benutzt[u] }
            return ~b & form.alle
        }

        mutating func lauf() {
            var beste = -1
            var besteMaske: UInt16 = 0
            var besteAnzahl = 99
            for z in 0..<form.zellen where werte[z] == 0 {
                let m = maske(z)
                let n = m.nonzeroBitCount
                if n < besteAnzahl {
                    beste = z; besteMaske = m; besteAnzahl = n
                    if n <= 1 { break }
                }
            }
            if beste < 0 {
                anzahl += 1
                if loesung == nil { loesung = werte }
                return
            }
            if besteAnzahl == 0 { return }
            var ziffern = form.ziffern(besteMaske)
            if rng != nil { ziffern.shuffle(using: &rng!) }
            let einh = g.einheitenJeZelle[beste]
            for d in ziffern {
                let bit = SudokuForm.bit(d)
                werte[beste] = UInt8(d)
                for u in einh { benutzt[u] |= bit }
                lauf()
                for u in einh { benutzt[u] &= ~bit }
                werte[beste] = 0
                if anzahl >= limit { return }
            }
        }
    }
}
