// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern

/// Nur Debug: Testzustand für `-testZustand`. Zwei Menschen, Spieler 1 beginnt. Feste Zugfolge in Spalten (1-basiert) 1-2-1-2-1-2: Spieler 1 hat drei
/// Steine übereinander in Spalte 1, Spieler 2 drei in Spalte 2. Die Partie wird über `Partie(zuege:)` mit den normalen Einwürfen aufgebaut.
/// kurzVorEnde: Spieler 1 ist dran; ein Stein in Spalte 1 gewinnt. ende: derselbe Stand, die Ansicht wirft den vierten Stein nach dem Laden selbst
/// (Gewinnreihe, Ende-Karte).
public enum ViererreiheTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var s = NeuSpiel(zweiSpieler: true, stufe: .mittel, beginner: 1, zufall: SplitMix64(seed: 3))
        if let p = try? Partie(beginner: 1, zuege: [0, 1, 0, 1, 0, 1]) { s.partie = p }
        Testzustand.ablegen(s, kennung: ViererreiheModul.kennung, spieler: 2)
    }
}
#endif
