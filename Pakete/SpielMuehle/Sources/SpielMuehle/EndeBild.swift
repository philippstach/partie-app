// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite (Blatt 22, EB-3): das Brett am Ende
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import MuehleKern

/// Das Mühle-Brett am Ende, nur lesen: dieselbe Zeichnung wie am Tisch (Linien, Punkte, helle und dunkle Steine), ohne Markierungen und Gesten.
struct MuehleEndeBild: View {
    /// Die 24 Punkte: 0 = frei, 1 = helle Steine, 2 = dunkle Steine
    let brett: [Int]
    let groesse: CGSize

    private func punkt(_ i: Int) -> (x: CGFloat, y: CGFloat) {
        let r = i / 8, k = i % 8, o = CGFloat(r), mitte: CGFloat = 3, m = 6 - o
        switch k {
        case 0: return (o, o); case 1: return (mitte, o); case 2: return (m, o); case 3: return (m, mitte)
        case 4: return (m, m); case 5: return (mitte, m); case 6: return (o, m); default: return (o, mitte)
        }
    }
    private func farbe(_ s: Int) -> Color { s == 1 ? Color(white: 0.88) : Color(white: 0.18) }

    var body: some View {
        let seite = max(60, floor(min(groesse.width, groesse.height)))
        let rand: CGFloat = 16
        let schritt = (seite - 2 * rand) / 6
        let p = { (i: Int) -> CGPoint in let c = punkt(i); return CGPoint(x: rand + c.x * schritt, y: rand + c.y * schritt) }
        let klar = Design.ist(.klar)
        ZStack {
            Canvas { ctx, _ in
                var weg = Path()
                for (i, ns) in Muehle.nachbarn.enumerated() { for j in ns where j > i { weg.move(to: p(i)); weg.addLine(to: p(j)) } }
                ctx.stroke(weg, with: .color(klar ? Color.secondary.opacity(0.6) : Color.linieStark), lineWidth: klar ? 2 : 1.5)
            }
            ForEach(0..<24, id: \.self) { i in
                let stein = brett[i]
                Circle().fill(stein == 0 ? (klar ? Color(.tertiarySystemFill) : Color.linieStark.opacity(0.35)) : farbe(stein))
                    .overlay(Circle().strokeBorder(stein == 0 ? .clear : (klar ? Color.primary.opacity(0.55) : (stein == 2 ? Color(white: 0.85) : Color.linieStark)), lineWidth: klar ? 2 : 1.5))
                    .frame(width: stein == 0 ? 14 : min(30, schritt * 0.52), height: stein == 0 ? 14 : min(30, schritt * 0.52))
                    .position(p(i))
            }
        }
        .frame(width: seite, height: seite)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
#endif
