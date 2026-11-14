// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import SudokuKern

/// Nur Debug: Testzustand für `-testZustand`. Klassisches Sudoku, Stufe leicht, Rätsel aus festem Seed (5); alle leeren Zellen bis auf die
/// letzte werden mit den richtigen Ziffern über `setze` eingetragen (95 s Spielzeit).
/// kurzVorEnde: eine Zelle fehlt. ende: gleicher Stand, die Ansicht trägt die letzte Ziffer nach dem Laden selbst ein (gelöst, Ende-Karte).
public enum SudokuTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var p = SudokuPartie(raetsel: NeuBruecke.raetsel(.klassisch, .leicht, seed: 5))
        let leer = p.werte.indices.filter { p.werte[$0] == 0 }
        for z in leer.dropLast() { p.setze(z, Int(p.raetsel.loesung[z])) }
        p.verstrichen = 95
        Testzustand.ablegen(p, kennung: NeuAblage.id, spieler: 1)
    }
}
#endif
