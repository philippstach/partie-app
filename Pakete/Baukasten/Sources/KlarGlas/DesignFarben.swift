// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// Designwechsel (KlarGlas 2.17): die Farbrollen. Spiele und Hülle schreiben `Color.seitenGrund` statt
// `Color(.systemGroupedBackground)` usw. In `klar` geben die Rollen die Systemfarben selbst zurück (kein Hex),
// damit sich am bisherigen Aussehen nichts ändert; in Tinte und Salon die Werte aus `DesignWerte`.
// Jede Rolle liest das gewählte Design: Ansichten, die sie in `body` benutzen, zeichnen sich beim Wechsel neu.

public extension Color {
    /// Farbe mit einem Wert für die helle und einem für die dunkle Darstellung.
    init(hell: UInt32, dunkel: UInt32) {
        guard hell != dunkel else { self.init(hex: hell); return }
        #if canImport(UIKit)
        self.init(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hexWert: dunkel) : UIColor(hexWert: hell) })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { erscheinung in
            let h = erscheinung.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dunkel : hell
            return NSColor(srgbRed: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)
        })
        #else
        self.init(hex: hell)
        #endif
    }

    /// Grund einer Seite (klar: `systemGroupedBackground`).
    static var seitenGrund: Color { Design.werte.seitenGrund?.color ?? system(.seite) }
    /// Grund von Flächen und Spielkarten-Papier (klar: `secondarySystemGroupedBackground`).
    static var kartenGrund: Color { Design.werte.kartenGrund?.color ?? system(.karte) }
    /// Grund von Kacheln, Chips und der aktiven Spalte (klar: `tertiarySystemGroupedBackground`).
    static var feldGrund: Color { Design.werte.feldGrund?.color ?? system(.feld) }
    /// Feine Linie zwischen Zeilen (klar: `separator`).
    static var linie: Color { Design.werte.linie?.color ?? system(.linie) }
    /// Starke Linie: Abschnittsanfang, Tabellenkopf, Blockgrenzen (klar: `separator`).
    static var linieStark: Color { Design.werte.linieStark?.color ?? system(.linie) }
    /// Schrift (klar: `label`).
    static var schrift: Color { Design.werte.schrift?.color ?? system(.schrift) }
    /// Zweite Schriftfarbe für Nebenzeilen (klar: `secondaryLabel`).
    static var schriftZweit: Color { Design.werte.schriftZweit?.color ?? system(.schriftZweit) }
    /// Blasse Schrift: ausgeschaltet, Platzhalter (klar: `tertiaryLabel`).
    static var schriftBlass: Color { Design.werte.schriftBlass?.color ?? system(.schriftBlass) }

    /// Fläche des Hauptknopfs: klar die App-Farbe, Tinte immer Tinte, Salon in der Hülle Espresso und im Spiel die Spielart-Farbe.
    static var knopfFlaeche: Color {
        let w = Design.werte
        switch w.art {
        case .klar: return .appFlaeche
        case .tinte: return w.knopf?.color ?? .appFlaeche
        case .salon: return Design.spielFarben?.flaeche ?? w.knopf?.color ?? .appFlaeche
        }
    }
    /// Schrift auf dem Hauptknopf (klar: Weiß).
    static var schriftAufKnopf: Color {
        let w = Design.werte
        switch w.art {
        case .klar: return .onAccent
        case .tinte: return w.schriftAufKnopf?.color ?? .onAccent
        case .salon: return Design.spielFarben?.aufFlaeche ?? w.schriftAufKnopf?.color ?? .onAccent
        }
    }

    private enum SystemRolle { case seite, karte, feld, linie, schrift, schriftZweit, schriftBlass }

    private static func system(_ rolle: SystemRolle) -> Color {
        #if canImport(UIKit)
        switch rolle {
        case .seite: Color(.systemGroupedBackground)
        case .karte: Color(.secondarySystemGroupedBackground)
        case .feld: Color(.tertiarySystemGroupedBackground)
        case .linie: Color(.separator)
        case .schrift: Color(.label)
        case .schriftZweit: Color(.secondaryLabel)
        case .schriftBlass: Color(.tertiaryLabel)
        }
        #else
        // Nur für `swift test` auf dem Mac (die Ansichten gibt es dort nicht).
        switch rolle {
        case .seite, .karte, .feld: Color.clear
        case .linie: Color.gray
        case .schrift: Color.primary
        case .schriftZweit, .schriftBlass: Color.secondary
        }
        #endif
    }
}

#if canImport(UIKit)
extension UIColor {
    convenience init(hexWert h: UInt32) {
        self.init(red: CGFloat((h >> 16) & 0xFF) / 255, green: CGFloat((h >> 8) & 0xFF) / 255, blue: CGFloat(h & 0xFF) / 255, alpha: 1)
    }
}
#endif
