// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Adressen der eigenen Partie-Seiten (Datenschutz, Hilfe und Support, Impressum). Philipp 14.11.: eigene Seiten statt der alten Wortpfeil-Seiten.
/// PLATZHALTER: Die Adressen stehen erst fest, wenn die Seiten veröffentlicht sind (Entwürfe: plan/web/). Hier an einer Stelle eintragen.
public enum PartieLinks {
    public static let datenschutz = URL(string: "https://example.invalid/partie/datenschutz")!
    public static let support = URL(string: "https://example.invalid/partie/support")!
    public static let impressum = URL(string: "https://example.invalid/partie/impressum")!
}
