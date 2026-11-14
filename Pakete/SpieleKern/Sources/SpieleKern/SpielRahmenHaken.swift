// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Einhängepunkt der Hülle für den Spielstart (Startseite „Spieleabend“): liefert zu einer Spiel-ID die Spielart-Farbe und die
/// Miniatur, die `SpielRahmen` unter dem Titel als Bildfeld zeigt. Ohne Haken bleibt der Start wie bisher. Beim App-Start setzen.
public enum SpielRahmenHaken {
    public struct Bild {
        public let farbe: Color; public let miniatur: Miniatur
        /// Name der Spielart („Würfel“), für die Startseite in Tinte und Salon.
        public let spielart: String?
        public init(farbe: Color, miniatur: Miniatur, spielart: String? = nil) { self.farbe = farbe; self.miniatur = miniatur; self.spielart = spielart }
    }
    nonisolated(unsafe) public static var bild: (@MainActor (String) -> Bild?)?
    /// Ist das Spiel ein Arcade-Spiel? Dort bucht „Beenden“ nie eine Niederlage (Einstellung „Partie abbrechen“). Ohne Haken: nein.
    nonisolated(unsafe) public static var istArcade: (@MainActor (String) -> Bool)?
}

#if canImport(UIKit)
/// Motiv für den Ende-Bildschirm (Spieleabend): Bildfeld in Spielart-Farbe mit Miniatur und Pokal (oder eigenem Zeichen) unten rechts.
/// Ohne Haken (außerhalb der Sammlung) zeigt es nichts; der `SiegerBildschirm` fällt dann auf seinen Symbolkreis zurück.
public struct SpielBildMotiv: View {
    let id: String
    var symbol = "trophy.fill"
    var hoehe: CGFloat = 120
    public init(id: String, symbol: String = "trophy.fill", hoehe: CGFloat = 120) { self.id = id; self.symbol = symbol; self.hoehe = hoehe }
    public var body: some View {
        // Salon: Die Gewinnerseite ist selbst eine Farbseite mit Porträt; ein zweiter Farbblock entfällt.
        if Design.ist(.salon) {
            EmptyView()
        } else if let b = SpielRahmenHaken.bild?(id) {
            SpielBild(farbe: b.farbe, miniatur: b.miniatur, hoehe: hoehe)
                .overlay(alignment: .bottomTrailing) {
                    if Design.ist(.klar) {
                        Image(systemName: symbol).font(.title3.weight(.semibold)).foregroundStyle(b.farbe)
                            .frame(width: 40, height: 40).background(.white, in: Circle()).padding(10).accessibilityHidden(true)
                    }
                }
        }
    }
}
#endif
