// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Ordnet die erkannten Augen den Plätzen des Wurfs zu.
public enum WuerfelZuordnung {
    /// - Parameters:
    ///   - erkannt: Augen im Foto in Lesereihenfolge.
    ///   - gehalten: Augen der gehaltenen Würfel, die vielleicht mit auf dem Foto liegen.
    ///   - plaetze: Anzahl der Würfel, die neu eingetragen werden.
    /// - Returns: höchstens `plaetze` Werte; liegen die gehaltenen Würfel mit auf dem Tisch, werden sie zuerst abgezogen.
    public static func zuordnen(erkannt: [Int], gehalten: [Int], plaetze: Int) -> [Int] {
        zuordnenMitPosition(erkannt: erkannt, gehalten: gehalten, plaetze: plaetze).map { erkannt[$0] }
    }

    /// Wie `zuordnen`, liefert aber die Positionen in `erkannt` (damit etwa Bildausschnitte zu denselben Würfeln passen).
    public static func zuordnenMitPosition(erkannt: [Int], gehalten: [Int], plaetze: Int) -> [Int] {
        var rest = Array(erkannt.indices)
        if erkannt.count == plaetze + gehalten.count {
            var ok = true
            var kopie = rest
            for g in gehalten {
                if let i = kopie.firstIndex(where: { erkannt[$0] == g }) { kopie.remove(at: i) } else { ok = false; break }
            }
            if ok { rest = kopie }
        }
        return Array(rest.prefix(plaetze))
    }
}
