// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if DEBUG && canImport(UIKit)
import SpieleKern
import IrrgangKern

/// Nur Debug: Testzustand für `-testZustand`. Stufe 1, Labyrinth aus festem Zufall (Seed 6); die Figur läuft mit echten Wischzügen
/// (`gleite`, immer in Richtung des Hinweises) bis vor den Ausgang.
/// kurzVorEnde: ein Wisch bis zum Ausgang fehlt (0 Punkte). ende: Ausgang erreicht, Stufenpunkte verbucht („Geschafft“); die Ansicht wählt danach
/// selbst „Lauf beenden“, daraus entsteht die Ende-Karte (Irrgang endet nur über diesen Knopf).
public enum IrrgangTestzustand {
    @MainActor
    public static func ablegen(_ art: Testzustand.Art) {
        var g = SplitMix64(seed: 6)
        var l = Irrgang(stufe: 1, mit: &g)
        var punkte = 0, gewinn = 0, geschafft = false
        for _ in 0..<300 {
            guard let r = l.hinweisRichtung() else { break }
            var probe = l
            probe.gleite(r)
            if probe.imZiel {
                if art == .ende { l.gleite(r); gewinn = l.stufenPunkte(); punkte = gewinn; geschafft = true }
                break
            }
            l.gleite(r)
        }
        Testzustand.ablegen(IrrgangStand(labyrinth: l, punkte: punkte, stufenGewinn: gewinn, geschafft: geschafft, tag: false), kennung: "irrgang", spieler: 1)
    }
}
#endif
