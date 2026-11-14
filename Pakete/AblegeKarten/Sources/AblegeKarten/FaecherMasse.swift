// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics

/// Aufteilung einer Hand in Fächer-Zeilen: überlappende Karten, bei vielen Karten zweilagig.
/// Reine Rechnung (testbar): `zeilen` sagt, welche Karten (Indizes) in welche Zeile kommen, `schritt` den Abstand der linken Kanten.
public struct FaecherMasse: Equatable, Sendable {
    public var zeilen: [Range<Int>]
    public var schritt: CGFloat
    public var kartenBreite: CGFloat

    /// - Parameters:
    ///   - mindestSchritt: kleinster Abstand zweier Karten, damit die Zahl noch lesbar bleibt.
    ///   - maxZeilen: bei mehr Karten, als `maxZeilen` Zeilen mit `mindestSchritt` fassen, bleibt der Schritt am Minimum und der Fächer wird scrollbar (`passt == false`).
    public static func berechne(anzahl: Int, breite: CGFloat, kartenBreite: CGFloat, mindestSchritt: CGFloat = 26, hoechstSchritt: CGFloat? = nil, maxZeilen: Int = 2) -> FaecherMasse {
        guard anzahl > 0, breite > 0 else { return FaecherMasse(zeilen: [], schritt: 0, kartenBreite: kartenBreite) }
        let hoechst = hoechstSchritt ?? kartenBreite + 6
        // Karten je Zeile bei Mindestschritt
        let jeZeileMax = max(Int((breite - kartenBreite) / mindestSchritt) + 1, 1)
        let zeilenAnzahl = min(max((anzahl + jeZeileMax - 1) / jeZeileMax, 1), maxZeilen)
        let jeZeile = (anzahl + zeilenAnzahl - 1) / zeilenAnzahl
        var zeilen: [Range<Int>] = []
        var start = 0
        while start < anzahl { let ende = min(start + jeZeile, anzahl); zeilen.append(start..<ende); start = ende }
        let schritt = jeZeile <= 1 ? 0 : min(max((breite - kartenBreite) / CGFloat(jeZeile - 1), mindestSchritt), hoechst)
        return FaecherMasse(zeilen: zeilen, schritt: schritt, kartenBreite: kartenBreite)
    }

    /// Breite der längsten Zeile.
    public var inhaltsBreite: CGFloat {
        let n = zeilen.map(\.count).max() ?? 0
        return n == 0 ? 0 : kartenBreite + CGFloat(n - 1) * schritt
    }
}
