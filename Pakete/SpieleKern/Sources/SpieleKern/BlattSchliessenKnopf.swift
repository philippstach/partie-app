// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// T-071 (TestFlight Build 24, Eintrag 9). NICHT SYNTAXGEPRÜFT (Cloud-Chat, kein swiftc).
#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Schließen-Knopf oben rechts in der Symbolleiste eines Blatts (`ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { … } }`).
///
/// Ab iOS 26 legt die Symbolleiste selbst eine runde Glasfläche um jeden Knopf. Ein `RundKnopf` bringt seinen eigenen Kreis mit, zusammen
/// ergab das den Doppelrahmen um das X (T-071, Regeln-Blatt). Darum ab iOS 26 nur das Symbol, den einen Kreis zeichnet die Symbolleiste,
/// wie bei `SchliessenKnopf` der Hülle (App/KinderSchutz.swift). Bis iOS 18 gibt es diese Fläche nicht, dort bleibt der `RundKnopf`.
/// Nur für die Symbolleiste. Knöpfe frei auf der Fläche (Tisch, Sieger-Seite) bleiben `RundKnopf`.
public struct BlattSchliessenKnopf: View {
    let symbol: String
    let beschriftung: LocalizedStringKey
    let aktion: () -> Void

    public init(_ beschriftung: LocalizedStringKey = "Schließen", symbol: String = "xmark", aktion: @escaping () -> Void) {
        self.beschriftung = beschriftung; self.symbol = symbol; self.aktion = aktion
    }

    public var body: some View {
        if #available(iOS 26, *) {
            Button(action: aktion) { Image(systemName: symbol) }
                .accessibilityLabel(Text(beschriftung))
        } else {
            RundKnopf(symbol: symbol, beschriftung: beschriftung, klein: true, aktion: aktion)
        }
    }
}
#endif
