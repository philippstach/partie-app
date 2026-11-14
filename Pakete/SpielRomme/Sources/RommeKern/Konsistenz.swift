// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Romme {
    /// Stimmigkeit eines geladenen Stands: alle 110 Karten genau einmal im Spiel, Zeiger im Bereich, jede Auslage gültig.
    /// Ein unstimmiger Stand (nach Updates oder Beschädigung) wird verworfen statt geladen.
    public var istKonsistent: Bool {
        guard (2...4).contains(haende.count), hatAusgelegt.count == haende.count, haende.indices.contains(dran) else { return false }
        let alle = haende.flatMap { $0 } + stapel + ablage + tisch.flatMap { $0 }
        let deck = RKarte.deck()
        guard alle.count == deck.count, Set(alle) == Set(deck) else { return false }
        guard tisch.allSatisfy(RommeRegeln.istMeld) else { return false }
        // 1.0 (M8): Runden und Gesamtpunkte
        guard Romme.rundenWahl.contains(rundenZiel), (1...rundenZiel).contains(runde), gesamt.count == haende.count, gesamt.allSatisfy({ $0 >= 0 }) else { return false }
        if let g = gewinner { return haende.indices.contains(g) && haende[g].isEmpty }
        return haende.allSatisfy { !$0.isEmpty }
    }
}
