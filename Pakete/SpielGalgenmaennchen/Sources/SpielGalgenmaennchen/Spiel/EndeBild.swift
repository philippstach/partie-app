// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite (Blatt 22, EB-3): das Wort und die Figur, wie sie am Ende standen
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Das Wort in großen Buchstaben (Serifenschrift) und daneben die Figur am Ende (gewonnen oder verloren), nur lesen.
struct GalgenEndeBild: View {
    let wort: String
    let uebrig: Int
    let gewonnen: Bool
    let groesse: CGSize
    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    var body: some View {
        let farbe = art == .tinte ? Tisch.elfenbein : Color.primary
        HStack(spacing: 12) {
            FigureView(remaining: uebrig, outcome: gewonnen ? .won : .lost)
                .frame(width: min(groesse.width * 0.38, groesse.height * 0.85), height: groesse.height)
            Text(verbatim: wort.uppercased())
                .font(.system(size: 34, weight: .semibold, design: .serif))
                .foregroundStyle(farbe)
                .lineLimit(2).minimumScaleFactor(0.35)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .frame(width: groesse.width, height: groesse.height)
    }
}
#endif
