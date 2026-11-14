// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite (Blatt 22, EB-3): das gelöste Kakuro-Gitter als helles Blatt
import SwiftUI
import KlarGlas
import SpieleKern
import KakuroKern

/// Das gelöste Gitter am Ende, nur lesen: helles Blatt (`Tisch.elfenbein`), weiße Felder mit Ziffern, dunkle Hinweisfelder mit den Summen.
/// Nimmt nur den Spielstand als Wert (keine Bindungen, keine Gesten) und passt in die übergebene Innenfläche.
struct KakuroEndeBild: View {
    let spiel: Kakuro
    let groesse: CGSize

    var body: some View {
        let n = spiel.n
        let abstand: CGFloat = 2
        let rand: CGFloat = 6
        let seite = max(60, floor(min(groesse.width, groesse.height) - 2 * rand))
        let zelle = (seite - abstand * CGFloat(n - 1)) / CGFloat(n)
        VStack(spacing: abstand) {
            ForEach(0..<n, id: \.self) { z in
                HStack(spacing: abstand) {
                    ForEach(0..<n, id: \.self) { s in feld(z * n + s, zelle: zelle) }
                }
            }
        }
        .padding(rand)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Tisch.elfenbein))
        .environment(\.colorScheme, .light)   // Tinte auf hellem Papier, auch wenn die Karte dunkel gezeichnet wird
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder private func feld(_ i: Int, zelle: CGFloat) -> some View {
        if spiel.weiss[i] {
            Text(verbatim: "\(spiel.eintrag[i])")
                .font(.system(size: zelle * 0.5, weight: .semibold, design: Design.zahlDesign).monospacedDigit())
                .foregroundStyle(Color.schrift)
                .frame(width: zelle, height: zelle)
                .background(Color.white, in: .rect(cornerRadius: 3))
                .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Color.linie, lineWidth: 1))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 3).fill(Color(hell: 0x3A3A3C, dunkel: 0x3A3A3C))
                // Blatt 28: dieselbe Diagonale wie im Spiel (nur bei Summen, endet vor den Ecken)
                if spiel.hinweisWaagrecht(i) != nil || spiel.hinweisSenkrecht(i) != nil {
                    Path { p in p.move(to: CGPoint(x: zelle * 0.044, y: zelle * 0.044)); p.addLine(to: CGPoint(x: zelle * 0.956, y: zelle * 0.956)) }.stroke(Color.white.opacity(0.55), lineWidth: max(1, zelle * 0.015))
                }
                if let r = spiel.hinweisWaagrecht(i) {
                    Text(verbatim: "\(r)").font(.system(size: zelle * 0.25, weight: .bold)).foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing).padding(2)
                }
                if let u = spiel.hinweisSenkrecht(i) {
                    Text(verbatim: "\(u)").font(.system(size: zelle * 0.25, weight: .bold)).foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading).padding(2)
                }
            }
            .frame(width: zelle, height: zelle)
        }
    }
}
