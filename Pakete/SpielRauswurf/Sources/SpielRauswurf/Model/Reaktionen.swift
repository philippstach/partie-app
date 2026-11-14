// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Emoji-Blasen der Computer (SPEZIFIKATION 7.4, Referenz `reaktionen()` in `Referenz/maedn.py`). Rein zur Anzeige.
/// Berechnet wird einmal nach einem ganzen Spielzug, aus der Lage vorher und den Würfen; für alle Spieler,
/// angezeigt wird nur bei Computern.
enum Reaktionen {
    static let rauswerfer = "😎"
    static let knapp = "😅"
    static let daumen = "🤞"
    static let sechs = "🎉"
    static let duerre = "🙄"
    static let geschlagen = "😤"

    /// Vorrang für den Ziehenden.
    static let rang = [rauswerfer, knapp, daumen, sechs, duerre]

    /// Blasen nach einem Spielzug von Spieler `p`: {Spieler: Emoji}.
    /// - Der Ziehende bekommt höchstens eine Blase, nie dieselbe wie seine letzte (`letzte`).
    /// - Jeder, der in diesem Spielzug rausgeworfen wurde, bekommt 😤 (unabhängig von `letzte`).
    static func nachSpielzug(lageVorher: Lage, spieler p: Int, wuerfe: [Wurf], letzte: [Int: String] = [:]) -> [Int: String] {
        var lage = lageVorher
        let sitz = lage.sitze[p]
        var treffer = Set<String>()
        var opfer: [Int: String] = [:]
        var fehl = 0
        for w in wuerfe {
            guard let z = w.zug else { fehl += 1; continue }
            if let q = z.schlaegt {
                treffer.insert(rauswerfer)
                opfer[q] = geschlagen
            }
            if (0 ..< Brettmass.lauf).contains(z.von), z.nach < Brettmass.lauf, z.schlaegt == nil,
               Computer.bedroht(lage, p, feld(sitz, z.von)) {
                var nach = lage
                nach.fuehreAus(p, z)
                if !Computer.bedroht(nach, p, feld(sitz, z.nach)) { treffer.insert(knapp) }
            }
            if w.augen == 6 { treffer.insert(sechs) }
            lage.fuehreAus(p, z)
        }
        if fehl >= 3 && wuerfe.allSatisfy({ $0.zug == nil }) { treffer.insert(duerre) }
        let rest = lage.figuren[p].filter { $0 < Brettmass.zielErstes }
        if rest.count == 1, rest[0] >= Brettmass.lauf - 6, rest[0] < Brettmass.lauf { treffer.insert(daumen) }
        var ergebnis = opfer
        for e in rang where treffer.contains(e) && letzte[p] != e {
            ergebnis[p] = e
            break
        }
        return ergebnis
    }
}
