// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

// Der seedbare Zufallsgenerator `SplitMix64` kommt aus dem Kern (bitgleich zur Python-Referenz `Referenz/galgen.py`,
// geprüft mit `Shared/regeltests/zufall.json`).

extension RandomNumberGenerator {
    /// Ganzzahl 0..<n nach Spezifikation: `next() % n`, vorzeichenlos, 64 Bit.
    mutating func index(_ n: Int) -> Int {
        precondition(n > 0)
        return Int(next() % UInt64(n))
    }
}
