// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics

/// Aufteilung einer Hand in ein Raster ohne Überlappung: jede Karte liegt ganz frei, Zahl und Zeichen sind immer lesbar.
/// Reine Rechnung (testbar). Von den angebotenen Kartengrößen (größte zuerst) wird die größte genommen, bei der alle Zeilen
/// in `hoechstHoehe` passen. Passt auch die kleinste nicht, bleibt sie und das Raster scrollt senkrecht (`passt == false`).
public struct RasterMasse: Equatable, Sendable {
    public var karte: CGSize
    /// Karten je Zeile, gleichmäßig verteilt (10 Karten bei Platz für 7 → 5 + 5 statt 7 + 3).
    public var spalten: Int
    public var zeilen: Int
    public var abstand: CGFloat
    public var passt: Bool

    public var hoehe: CGFloat { zeilen == 0 ? 0 : CGFloat(zeilen) * karte.height + CGFloat(zeilen - 1) * abstand }

    public static func berechne(anzahl: Int, breite: CGFloat, groessen: [CGSize], abstand: CGFloat = 6, hoechstHoehe: CGFloat) -> RasterMasse {
        precondition(!groessen.isEmpty)
        var letzte = RasterMasse(karte: groessen[groessen.count - 1], spalten: 1, zeilen: 0, abstand: abstand, passt: true)
        for g in groessen {
            let moeglich = max(Int((breite + abstand) / (g.width + abstand)), 1)
            let zeilen = anzahl == 0 ? 0 : (anzahl + moeglich - 1) / moeglich
            let spalten = zeilen == 0 ? moeglich : (anzahl + zeilen - 1) / zeilen
            let m = RasterMasse(karte: g, spalten: spalten, zeilen: zeilen, abstand: abstand, passt: true)
            if m.hoehe <= hoechstHoehe + 0.5 { return m }
            letzte = m
        }
        letzte.passt = false
        return letzte
    }
}
