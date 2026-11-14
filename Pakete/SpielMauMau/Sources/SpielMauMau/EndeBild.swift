// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite Mau-Mau (Blatt 22, Paket EB-1, Schritt 1). Nicht syntaxgeprüft.
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import MauMauKern

/// Bild vom Ende: links die letzte Karte, rechts je Person, was sie noch auf der Hand hatte (höchstens sechs Karten, dann „+3“).
/// Nimmt nur Werte (Karten, Namen), keine Bindungen und keine Gesten.
enum MauMauEndeBild {
    static func bild(spiel: NMauMau, sieger: Int, namen: [String]) -> EndeBild {
        let letzte = spiel.oben
        let uebrige = namen.indices.filter { $0 != sieger && !spiel.haende[$0].isEmpty }.map { ($0, namen[$0], spiel.haende[$0]) }
        return EndeBild(Text("Letzte Karte und restliche Karten"), hoehe: uebrige.count > 2 ? 200 : 150) { groesse in
            HStack(alignment: .center, spacing: 16) {
                VStack(spacing: 6) {
                    EndeBildTitel("Letzte Karte")
                    NKartenBild(karte: letzte, breite: min(60, groesse.height * 0.5))
                }
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(uebrige, id: \.0) { i, name, hand in
                        zeile(name: name, hand: hand, hoehe: (groesse.height - 8 * CGFloat(max(uebrige.count - 1, 0))) / CGFloat(max(uebrige.count, 1)), spieler: i)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: groesse.width, height: groesse.height)
        }
    }

    @ViewBuilder private static func zeile(name: String, hand: [NKarte], hoehe: CGFloat, spieler: Int) -> some View {
        let breite = max(18, min(30, (hoehe - 18) / 1.42))
        VStack(alignment: .leading, spacing: 3) {
            Text("\(name) hatte noch").font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Tisch.hinweis).lineLimit(1).minimumScaleFactor(0.7)
            HStack(spacing: 3) {
                ForEach(Array(hand.prefix(6).enumerated()), id: \.offset) { _, k in NKartenBild(karte: k, breite: breite) }
                if hand.count > 6 { Text(verbatim: "+\(hand.count - 6)").font(.system(size: 12, weight: .semibold).monospacedDigit()).foregroundStyle(Tisch.hinweis) }
            }
        }
    }
}
#endif
