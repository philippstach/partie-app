// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Fragetext in einem Fragefeld.
struct ClueText: View {
    let text: String
    let width: CGFloat
    let height: CGFloat
    let base: CGFloat
    var minSize: CGFloat = ClueFit.minSize
    var color: Color = .frageTinte

    var body: some View {
        let r = ClueFit.fit(text, width: width, height: height, base: base, minSize: minSize)
        Text(r.text)
            .font(.system(size: r.size, weight: .medium))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
            .fontWidth(.condensed)
            .lineSpacing(-2)
            .lineLimit(r.fits ? nil : r.lines)
            .truncationMode(.tail)
            .multilineTextAlignment(.center)
            .foregroundStyle(color)
            .frame(width: width, height: height)
    }
}
#endif
