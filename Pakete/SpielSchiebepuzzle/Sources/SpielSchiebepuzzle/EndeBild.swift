// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite (Blatt 22, EB-3): die Kacheln in der richtigen Reihenfolge
import SwiftUI
import KlarGlas
import SpieleKern

/// Die gelöste Anordnung am Ende (1 bis n² − 1 der Reihe nach, Lücke unten rechts), nur lesen, mit denselben hellen Kacheln wie am Tisch.
struct SchiebepuzzleEndeBild: View {
    let n: Int
    let groesse: CGSize
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    var body: some View {
        let abstand: CGFloat = 6
        let seite = max(60, floor(min(groesse.width, groesse.height)))
        let kachel = (seite - CGFloat(n - 1) * abstand) / CGFloat(n)
        VStack(spacing: abstand) {
            ForEach(0..<n, id: \.self) { z in
                HStack(spacing: abstand) {
                    ForEach(0..<n, id: \.self) { s in
                        let wert = z * n + s + 1
                        if wert < n * n {
                            Text(verbatim: "\(wert)")
                                .font(.system(size: kachel * 0.42, weight: .bold, design: Design.zahlDesign).monospacedDigit())
                                .foregroundStyle(art == .tinte ? Tisch.auge : Color.white)   // wie am Tisch
                                .frame(width: kachel, height: kachel)
                                .background(art == .tinte ? Tisch.elfenbein : Color.appFlaeche, in: .rect(cornerRadius: Theme.feldRadius))
                        } else {
                            Color.clear.frame(width: kachel, height: kachel)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
