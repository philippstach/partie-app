// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Einfache Anleitungsschritte für die Brett-, Karten- und Würfelspiele der Sammlung: Die Bühne zeigt Figuren
/// (Emoji oder Zeichen), die nacheinander hervortreten; eine Figur rutscht in der Schleife nach rechts.
/// Optik und Bewegung kommen aus KlarGlas.
public extension AnleitungSchritt {
    /// Erste Seite jeder Anleitung: das Ziel des Spiels in ein bis zwei Sätzen („Ziel“, Fahne auf der Bühne).
    /// Der deutsche Text ist zugleich der Übersetzungsschlüssel.
    static func ziel(_ text: LocalizedStringKey) -> AnleitungSchritt {
        AnleitungSchritt(symbol: "flag.checkered", titel: "Ziel", text: text) { fortschritt, aktiv in
            Image(systemName: "flag.checkered").font(.system(size: Design.heldSymbolGroesse, weight: .semibold)).foregroundStyle(Color.accentText)
                .rotationEffect(.degrees(aktiv ? 6 * sin(fortschritt * .pi * 2) : 0), anchor: .bottomLeading)
                .accessibilityHidden(true)
        }
    }

    /// `figuren`: Zeichen in der Reihe; `bewegt` ist der Index, der in der Schleife nach rechts rutscht (nil = keiner).
    static func figuren(symbol: String, titel: LocalizedStringKey, text: LocalizedStringKey, figuren: [String], bewegt: Int? = nil) -> AnleitungSchritt {
        AnleitungSchritt(symbol: symbol, titel: titel, text: text) { fortschritt, aktiv in
            HStack(spacing: 18) {
                ForEach(Array(figuren.enumerated()), id: \.offset) { i, f in
                    Text(verbatim: f).font(.system(size: 44))   // design:spielinhalt (Figuren auf der Anleitungsbühne)
                        .scaleEffect(aktiv && bewegt == i ? 1 + 0.18 * sin(fortschritt * .pi) : 1)
                        .offset(x: bewegt == i ? 30 * anleitungAbschnitt(fortschritt, von: 0.2, bis: 0.7) : 0)
                        .opacity(aktiv ? 0.55 + 0.45 * anleitungAbschnitt(fortschritt, von: Double(i) * 0.1, bis: Double(i) * 0.1 + 0.3) : 1)
                }
            }
        }
    }
}
#endif
