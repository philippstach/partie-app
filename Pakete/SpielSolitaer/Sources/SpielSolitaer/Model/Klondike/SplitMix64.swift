// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

// Die seedbare Zufallsquelle `SplitMix64` kommt aus dem Kern (siehe Shared/regeltests/zufall.json).

enum Deal {
    /// Fisher-Yates von hinten: für i = 51…1 tausche Platz i mit Platz below(i + 1).
    static func shuffledDeck(seed: UInt64) -> [CardID] {
        var deck = CardID.all
        var rng = SplitMix64(seed: seed)
        for i in stride(from: 51, to: 0, by: -1) {
            deck.swapAt(i, rng.below(i + 1))
        }
        return deck
    }

    /// Geben: Zeile für Zeile; die Karte in Spalte r der Zeile r liegt offen; Karten 28…51 bilden den Stapel.
    static func deal(seed: UInt64, draw: Int) -> GameState {
        let deck = shuffledDeck(seed: seed)
        var cols = Array(repeating: Column(), count: 7)
        var pos = 0
        for r in 0..<7 {
            for c in r..<7 {
                if c == r { cols[c].up.append(deck[pos]) } else { cols[c].down.append(deck[pos]) }
                pos += 1
            }
        }
        return GameState(draw: draw, stock: Array(deck[pos...]), cols: cols)
    }
}
