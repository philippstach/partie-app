// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Gemeinsame Rechnung für das Auffächern der Spalten (Klondike, Spider, FreeCell).
enum FanMetrics {
    /// Ist viel Platz frei, wächst der offene Abstand bis 0,42 × Kartenhöhe – gleich für alle Spalten,
    /// so dass die längste Spalte gerade passt. Nie kleiner als der Standard `base` (× Kartenhöhe).
    static let maxOpenStep: CGFloat = 0.42

    /// - Parameters:
    ///   - columns: je Spalte Anzahl verdeckter und offener Karten
    ///   - available: Höhe von der ersten Karte bis zum unteren Rand (ohne die Höhe der letzten Karte)
    ///   - downPoints: Abstand verdeckter Karten in Punkten
    static func growingOpenStep(columns: [(down: Int, up: Int)], available: CGFloat, downPoints: CGFloat,
                                cardHeight: CGFloat, base: CGFloat, cap: CGFloat = maxOpenStep) -> CGFloat {
        var allowed = CGFloat.infinity
        for c in columns {
            let gaps = CGFloat(max(c.up - 1, 0))
            guard gaps > 0 else { continue }
            allowed = min(allowed, (available - CGFloat(c.down) * downPoints) / gaps)
        }
        return min(cardHeight * cap, max(cardHeight * base, allowed))
    }
}
