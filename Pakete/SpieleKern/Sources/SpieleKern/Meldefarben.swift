// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

/// Meldefarben der Spiele als Rollen: Klar & Glas behält die Systemfarben (Darstellung unverändert),
/// Tinte und Salon nehmen feste Farbpaare des Designs (hell/dunkel), damit kein Systemrot und -grün aus der Reihe fällt.
public extension Color {
    /// Fehler, Niete, Strafe, falsche Zahl.
    static var meldungRot: Color { Design.art == .klar ? Color.red : FarbPaar(0xB3261E, 0xF28B82).color }
    /// Treffer, Gewinn, Pluspunkte.
    static var meldungGruen: Color { Design.art == .klar ? Color.green : FarbPaar(0x2F7D4F, 0x6FCF97).color }
}

public extension ShapeStyle where Self == AnyShapeStyle {
    /// Betonte Schrift: Klar & Glas die Akzentfarbe der Ansicht (`.tint`), Tinte und Salon die Akzent-Schriftfarbe des Designs.
    static var spielAkzent: AnyShapeStyle { Design.art == .klar ? AnyShapeStyle(.tint) : AnyShapeStyle(Color.accentText) }
}
