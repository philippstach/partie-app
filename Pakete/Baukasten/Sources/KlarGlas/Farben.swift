// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

/// Die Hex-Werte der Spielefamilie an einer Stelle (DESIGN.md A.1; dieselben Werte wie `AkzentFarbe` im Produkt `Baukasten`,
/// `design_pruefung.py` SOLL und `accenttext_soll.json`). Apps und Pakete nehmen diese Namen statt eigener Literale,
/// dann bleibt `design_pruefung.py` (Hex-Literale) still. `fläche` ist die App-Farbe, `textHell`/`textDunkel` kleiner Text (≥ 4,5:1).
public enum Familienfarbe: String, CaseIterable, Sendable {
    case blau, orange, gruen, rot, violett, pink, tuerkis, braun, indigo, schiefer, limette
    /// Hülle der Sammlung Partie (Nachtblau) und neutrales Graphit – keine App-Farben, deshalb nicht in `spieler`.
    case nachtblau, graphit

    public var flaeche: UInt32 {
        switch self {
        case .blau: 0x2F6FEB; case .orange: 0xF26B1D; case .gruen: 0x14A06F; case .rot: 0xE5484D
        case .violett: 0x7A52D1; case .pink: 0xC2398A; case .tuerkis: 0x0C8599; case .braun: 0x9A5B2E
        case .indigo: 0x4B4ACF; case .schiefer: 0x4F6377; case .limette: 0x5E8F00
        case .nachtblau: 0x1F3A5F; case .graphit: 0x2B2D33
        }
    }
    public var textHell: UInt32 {
        switch self {
        case .blau: 0x275BC1; case .orange: 0xA24813; case .gruen: 0x0E704E; case .rot: 0xAD363A
        case .violett: 0x6D49BB; case .pink: 0xA63176; case .tuerkis: 0x0A6A7A; case .braun: 0x8B522A
        case .indigo: 0x4B4ACF; case .schiefer: 0x4E6276; case .limette: 0x476C00
        case .nachtblau: 0x1F3A5F; case .graphit: 0x2B2D33
        }
    }
    public var textDunkel: UInt32 {
        switch self {
        case .blau: 0x77A1F2; case .orange: 0xF5894A; case .gruen: 0x4CB792; case .rot: 0xED8285
        case .violett: 0xAC93E2; case .pink: 0xD985B7; case .tuerkis: 0x5DAEBB; case .braun: 0xC0987C
        case .indigo: 0x9897E3; case .schiefer: 0x95A1AD; case .limette: 0x8CAF49
        case .nachtblau: 0x9DB4D6; case .graphit: 0xC9CBD1
        }
    }
    public var color: Color { Color(hex: flaeche) }

    /// Die elf App-Farben in der Reihenfolge der Spielerfarben (ohne Nachtblau und Graphit).
    public static let spieler: [Familienfarbe] = [.blau, .orange, .gruen, .rot, .violett, .pink, .tuerkis, .braun, .indigo, .schiefer, .limette]

    /// Die Familienfarbe zu einem gespeicherten Hex-Wert (z. B. aus der App Group fürs Widget).
    public static func mit(hex: UInt32) -> Familienfarbe? { allCases.first { $0.flaeche == hex } }
}

public extension Color {
    /// Farbe zu einem gespeicherten Familien-Hex (Widget, Spielerfarben); unbekannte Werte werden direkt umgesetzt.
    static func familie(_ hex: UInt32) -> Color { Familienfarbe.mit(hex: hex)?.color ?? Color(hex: hex) }
}
