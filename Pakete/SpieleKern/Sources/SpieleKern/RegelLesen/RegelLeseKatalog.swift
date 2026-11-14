// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Bauplan RL-K: Woher die Seite „Alle Regeln lesen“ den gegliederten Text eines Spiels nimmt. Die App setzt den Lieferanten beim Start
/// (nur auf Deutsch liefert er etwas); ohne Text bleibt die heutige Seite.
public enum RegelLeseKatalog {
    private static let sperre = NSLock()
    nonisolated(unsafe) private static var _lieferant: (@Sendable (String) -> String?)?

    public static var lieferant: (@Sendable (String) -> String?)? {
        get { sperre.lock(); defer { sperre.unlock() }; return _lieferant }
        set { sperre.lock(); _lieferant = newValue; sperre.unlock() }
    }

    public static func quelle(fuer id: String) -> String? { lieferant?(RegelWissenKatalog.grundID(id)) }
}
