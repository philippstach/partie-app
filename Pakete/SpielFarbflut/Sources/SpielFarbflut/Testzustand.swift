// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import FarbflutKern

/// Nur Debug: Testzustand für `-testZustand`. Stufe „Leicht“ (8 × 8, 4 Farben), Brett aus festem Zufall (Seed 2); gespielt wird mit der
/// gierigen Farbwahl des Spiels (`besteFarbeGierig`, normale Züge), das Limit reicht dafür immer.
/// kurzVorEnde: ein Zug bis zum einfarbigen Feld fehlt. ende: gelöst; die Ansicht wählt danach selbst „Ergebnis“ (Ende-Karte).
public enum FarbflutTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var g = SplitMix64(seed: 2)
        var f = Farbflut(groesse: 8, farben: 4, luft: 6, mit: &g)
        for _ in 0..<500 where !f.geloest {
            var probe = f
            probe.zug(f.besteFarbeGierig())
            if probe.geloest { if art == .ende { f = probe }; break }
            f = probe
        }
        Testzustand.ablegen(FarbflutSpiel.Stand(spiel: f, stufe: 0, tages: false, tipps: 0), kennung: "farbflut", spieler: 1)
    }
}
#endif
