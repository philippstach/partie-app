// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite Mogeln (Blatt 22, Paket EB-1, Schritt 1). Nicht syntaxgeprüft.
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import MogelnKern

/// Bild vom Ende: je Person, was sie noch auf der Hand hatte (höchstens sechs Karten, dann „+3“).
/// Nimmt nur Werte (Karten, Namen), keine Bindungen und keine Gesten.
enum MogelnEndeBild {
    /// `nil`, wenn alle anderen keine Karten mehr haben.
    static func bild(haende: [[MoKarte]], sieger: Int, namen: [String]) -> EndeBild? {
        let uebrige = namen.indices.filter { $0 != sieger && !haende[$0].isEmpty }
        guard !uebrige.isEmpty else { return nil }
        return EndeBild(Text("Restliche Karten der anderen"), hoehe: uebrige.count > 2 ? 200 : 150) { groesse in
            let zeilenHoehe = (groesse.height - 8 * CGFloat(uebrige.count - 1)) / CGFloat(uebrige.count)
            let skala = max(0.3, min(0.55, (zeilenHoehe - 18) / 76))   // Handkarte ist 52 × 76 pt
            VStack(alignment: .leading, spacing: 8) {
                ForEach(uebrige, id: \.self) { i in
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(namen[i]) hatte noch").font(.system(size: 12.5, weight: .semibold)).foregroundStyle(Tisch.hinweis).lineLimit(1).minimumScaleFactor(0.7)
                        HStack(spacing: 3) {
                            ForEach(Array(haende[i].prefix(6).enumerated()), id: \.offset) { _, k in
                                MHandKarte(karte: k).scaleEffect(skala, anchor: .topLeading).frame(width: 52 * skala, height: 76 * skala, alignment: .topLeading)
                            }
                            if haende[i].count > 6 { Text(verbatim: "+\(haende[i].count - 6)").font(.system(size: 12, weight: .semibold).monospacedDigit()).foregroundStyle(Tisch.hinweis) }
                        }
                    }
                }
            }
            .frame(width: groesse.width, height: groesse.height, alignment: .center)
        }
    }
}
#endif
