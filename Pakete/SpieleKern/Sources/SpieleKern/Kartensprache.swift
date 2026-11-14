// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Sprechnamen für Spielkarten (VoiceOver): „Herz Dame“ statt „H D“; übersetzt über den String-Katalog.
public enum Kartensprache {
    /// Farbname zu einem Zeichen (♣ ♠ ♥ ♦); unbekannte Zeichen kommen unverändert zurück.
    public static func farbe(symbol: String) -> String {
        switch symbol {
        case "♣": return String(localized: "Kreuz")
        case "♠": return String(localized: "Pik")
        case "♥": return String(localized: "Herz")
        case "♦": return String(localized: "Karo")
        default: return symbol
        }
    }
    /// Rangname zu der Kurzschrift der Karten (B, D, K, A); Zahlen bleiben Zahlen.
    public static func rang(_ kurz: String) -> String {
        switch kurz {
        case "B": return String(localized: "Bube")
        case "D": return String(localized: "Dame")
        case "K": return String(localized: "König")
        case "A": return String(localized: "Ass")
        default: return kurz
        }
    }
    /// „Herz Dame“ aus Kurzschrift und Farbzeichen.
    public static func name(rang kurz: String, symbol: String) -> String { farbe(symbol: symbol) + " " + rang(kurz) }
    /// Farbname der spanischen Karten (0 Münzen, 1 Becher, 2 Schwerter, 3 Stäbe).
    public static func spanischeFarbe(_ i: Int) -> String {
        [String(localized: "Münzen"), String(localized: "Becher"), String(localized: "Schwerter"), String(localized: "Stäbe")][((i % 4) + 4) % 4]
    }
}
