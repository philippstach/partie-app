// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// Build 25, neue Regeltexte (plan/regeln-neu). NICHT SYNTAXGEPRÜFT (Cloud-Chat, kein swiftc).
#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Neue deutsche Wischanleitungen (Build 25): Sie gelten nur, solange die App Deutsch zeigt. Englisch, Spanisch und Französisch
/// behalten die alten, übersetzten Seiten, bis Philipp die deutschen Texte abgenommen hat und übersetzt ist.
/// Der Lesetext unter „Alle Regeln lesen“ braucht das nicht: Dort setzt der Katalog nur den deutschen Wert des alten Schlüssels neu.
public enum RegelTexteNeu {
    /// Zeigt die App gerade Deutsch?
    public static var aktiv: Bool { Bundle.main.preferredLocalizations.first == "de" }
    /// `.mitAnleitung(RegelTexteNeu.anleitung(neu: [...], alt: [...]))`
    public static func anleitung(neu: [AnleitungSchritt], alt: [AnleitungSchritt]) -> [AnleitungSchritt] { aktiv ? neu : alt }
}

public extension SpielRahmen {
    /// Neue erste Seite „Ziel“ nur auf Deutsch (längerer Text als die Zielkarte der Spielseite); sonst bleibt die alte Zielseite.
    func mitZielSchrittNeu(_ schritt: AnleitungSchritt) -> Self { RegelTexteNeu.aktiv ? mitZielSchritt(schritt) : self }
}
#endif
