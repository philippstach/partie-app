// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Tischkarte: der Stock, Hälfte und Runde, der Wurf, der zu schlagen ist. Eine Zeile hoch (SE 52 pt).
struct NeuTischKarte: View {
    let z: Spielzustand
    var kompakt = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        HStack(spacing: Design.Abstand.m) {
            VStack(spacing: 0) {
                StockView(anzahl: z.haelfte.stock).scaleEffect(kompakt ? 0.65 : 1)
                    .frame(width: 44, height: kompakt ? 34 : 52)   // B18 K-019: Stapel (34 + 1,5 pt je Deckel) ragt nicht mehr in „Stock N“
                Text("Stock \(z.haelfte.stock)").font(.caption2.weight(.semibold)).tischHinweis(zeilen: 1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Stock, \(z.haelfte.stock) Deckel")
            VStack(alignment: .leading, spacing: 2) {
                zuSchlagen
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12).padding(.vertical, kompakt ? 4 : 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tischFlaeche(16)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var zuSchlagen: some View {
        if let ref = z.zuSchlagen, z.phase != .rundenwertung, let s = z.runde.zuege.first(where: { $0.ergebnis == ref })?.spieler {
            Text("Zu schlagen: \(ref.wertung.name) (\(z.namen[s]), \(wuerfeText(ref.wuerfe)))")
                .font(.footnote).foregroundStyle((Tisch.aktiv ? Tisch.elfenbein : Color.accentText)).lineLimit(typeSize.isAccessibilitySize && !Tisch.aktiv ? 5 : 2).minimumScaleFactor(0.8).fixedSize(horizontal: false, vertical: true)   // B18 G-007/N-015: bei großer Schrift umbrechen statt abschneiden; Tinte: höchstens zwei Zeilen (Punkt 4)
        } else if z.phase == .rundenwertung {
            Text("Runde gewertet").font(.footnote).tischHinweis()
        } else if z.runde.position == 0 {
            Text("Der Vorleger bestimmt, wie oft gewürfelt wird").font(.footnote).lineLimit(typeSize.isAccessibilitySize && !Tisch.aktiv ? 5 : 2).minimumScaleFactor(0.8).fixedSize(horizontal: false, vertical: true).tischHinweis()   // B18 G-007/N-015: bei großer Schrift umbrechen statt abschneiden
        } else {
            Text("Noch nichts zu schlagen").font(.footnote).fixedSize(horizontal: false, vertical: true).tischHinweis()
        }
    }
}
