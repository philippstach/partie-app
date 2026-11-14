// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import CoreGraphics

/// Wie eine Seite aufgebaut wird (SPEZIFIKATION 17.1). Entscheidend ist die Breite, nicht das Gerät:
/// Das iPad in schmalem Split View bekommt das iPhone-Layout.
enum SeitenLayout: Equatable, Sendable {
    case kompakt, breitHoch, breitQuer
}

enum Layout {
    /// `kompakteBreite`: die Größenklasse der Breite ist „compact“.
    static func entscheide(breite: CGFloat, hoehe: CGFloat, kompakteBreite: Bool) -> SeitenLayout {
        if kompakteBreite { return .kompakt }
        return breite > hoehe ? .breitQuer : .breitHoch
    }

    /// Kantenlänge des Bretts (quadratisch inklusive Einwurf-Leiste) im Hochformat: so groß wie möglich,
    /// aber nicht höher als der verfügbare Platz abzüglich dessen, was sonst auf der Seite steht.
    static func brettKante(verfuegbareBreite: CGFloat, verfuegbareHoehe: CGFloat, hoechstens: CGFloat = 720) -> CGFloat {
        max(min(verfuegbareBreite, verfuegbareHoehe, hoechstens), 0)
    }

    /// Breite der Seitenleiste im Querformat: ein Drittel, aber zwischen 320 und 380 pt.
    static func seitenleiste(breite: CGFloat) -> CGFloat { min(max(breite / 3, 320), 380) }

    /// Anzahl Spalten eines Kachelrasters mit festen Kacheln.
    static func kachelSpalten(breite: CGFloat, kachel: CGFloat, abstand: CGFloat) -> Int {
        max(Int((breite + abstand) / (kachel + abstand)), 1)
    }
}
