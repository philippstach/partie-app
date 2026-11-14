// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite (Blatt 22, EB-3): das letzte Labyrinth
import SwiftUI
import KlarGlas
import SpieleKern
import IrrgangKern

/// Das letzte Labyrinth am Ende, ganz sichtbar (auch auf Stufen mit Ausschnitt), nur lesen; dieselbe Zeichnung wie am Tisch.
struct IrrgangEndeBild: View {
    let labyrinth: Irrgang
    let groesse: CGSize

    var body: some View {
        let m = labyrinth
        let z = max(4, floor(min(groesse.width / CGFloat(m.breite), groesse.height / CGFloat(m.hoehe))))
        Canvas { ctx, size in
            IrrgangSpiel.zeichne(m, voll: true, &ctx, z: z, ox: (size.width - z * CGFloat(m.breite)) / 2, oy: (size.height - z * CGFloat(m.hoehe)) / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
