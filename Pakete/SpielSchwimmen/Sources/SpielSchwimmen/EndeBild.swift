// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Ergebnisseite Schwimmen (Blatt 22, Paket EB-1, Schritt 1). Nicht syntaxgeprüft.
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Bild vom Ende: das Blatt des Siegers mit seinem Namen. Nimmt nur Werte (Karten, Name), keine Bindungen und keine Gesten.
enum SchwimmenEndeBild {
    /// `nil`, wenn das Blatt des Siegers nicht aus drei Karten besteht.
    static func bild(hand: [SwKarte], name: String) -> EndeBild? {
        guard hand.count == 3 else { return nil }
        return EndeBild(Text("Blatt des Siegers"), hoehe: 150) { groesse in
            let hoehe = min(groesse.height - 24, 96)
            let breite = hoehe * 0.69
            VStack(spacing: 8) {
                Text(verbatim: name).font(.system(size: 13.5, weight: .semibold)).foregroundStyle(Tisch.elfenbein).lineLimit(1)
                HStack(spacing: 8) {
                    ForEach(Array(hand.enumerated()), id: \.offset) { _, k in
                        SkatKartenBild(SkatKarte(farbIndex: k.farbe, wert: k.wert), groesse: .normal)
                            .scaleEffect(hoehe / KartenGroesse.normal.masse.height)
                            .frame(width: breite, height: hoehe)
                    }
                }
            }
            .frame(width: groesse.width, height: groesse.height)
        }
    }
}
#endif
