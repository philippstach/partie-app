// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Eine Farbe als reine Zahlen (0…1), damit die Logik ohne SwiftUI testbar bleibt.
struct Farbton: Equatable, Hashable, Codable, Sendable {
    var rot: Double
    var gruen: Double
    var blau: Double

    /// Aus Farbton (0…1), Sättigung und Helligkeit.
    init(farbwinkel h: Double, saettigung s: Double, helligkeit v: Double) {
        let h6 = (h - h.rounded(.down)) * 6
        let i = Int(h6) % 6
        let f = h6 - Double(Int(h6))
        let p = v * (1 - s), q = v * (1 - s * f), t = v * (1 - s * (1 - f))
        switch i {
        case 0: (rot, gruen, blau) = (v, t, p)
        case 1: (rot, gruen, blau) = (q, v, p)
        case 2: (rot, gruen, blau) = (p, v, t)
        case 3: (rot, gruen, blau) = (p, q, v)
        case 4: (rot, gruen, blau) = (t, p, v)
        default: (rot, gruen, blau) = (v, p, q)
        }
    }

    init(rot: Double, gruen: Double, blau: Double) {
        self.rot = rot; self.gruen = gruen; self.blau = blau
    }

    /// Mischung von `a` nach `b` (anteil 0…1).
    static func mischung(_ a: Farbton, _ b: Farbton, _ anteil: Double) -> Farbton {
        Farbton(rot: a.rot + (b.rot - a.rot) * anteil,
                gruen: a.gruen + (b.gruen - a.gruen) * anteil,
                blau: a.blau + (b.blau - a.blau) * anteil)
    }

    /// Wahrnehmungsnaher Abstand (gewichtetes RGB), zum Prüfen, dass Nachbarkacheln unterscheidbar sind.
    func abstand(zu o: Farbton) -> Double {
        let mr = (rot + o.rot) / 2
        let dr = rot - o.rot, dg = gruen - o.gruen, db = blau - o.blau
        return ((2 + mr) * dr * dr + 4 * dg * dg + (3 - mr) * db * db).squareRoot()
    }
}
