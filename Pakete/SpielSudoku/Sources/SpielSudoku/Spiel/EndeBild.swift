// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite (Blatt 22, EB-3): das gelöste Gitter als helles Blatt
import SwiftUI
import KlarGlas
import SpieleKern
import SudokuKern

/// Das gelöste Gitter am Ende, nur lesen: helles Blatt (`Tisch.elfenbein`), vorgegebene Zahlen fett in Tinte, eigene in der Eingabefarbe.
/// Nimmt nur Werte entgegen (keine Bindungen, keine Gesten); passt in die übergebene Innenfläche.
struct SudokuEndeBild: View {
    let form: SudokuForm
    let werte: [UInt8]
    let vorgaben: Set<Int>
    let groesse: CGSize

    init(partie: SudokuPartie, groesse: CGSize) {
        form = partie.form
        werte = partie.werte
        vorgaben = Set((0..<partie.werte.count).filter { partie.istVorgabe($0) })
        self.groesse = groesse
    }

    var body: some View {
        let rand: CGFloat = 6
        let seite = max(60, floor(min(groesse.width, groesse.height) - 2 * rand))
        NeuFeld(form: form, werte: werte, notizen: Array(repeating: 0, count: werte.count), fest: { vorgaben.contains($0) },
                seite: seite, gleicheZiffern: false, imBlatt: true, tippen: { _ in })
            .padding(rand)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Tisch.elfenbein))
            .environment(\.colorScheme, .light)   // Tinte auf hellem Papier, auch wenn die Karte dunkel gezeichnet wird
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
