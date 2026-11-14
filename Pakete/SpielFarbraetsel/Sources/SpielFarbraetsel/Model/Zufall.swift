// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Zufallsquelle mit Seed (SplitMix64): gleicher Seed, gleiches Rätsel. Testbar und für das Tagesrätsel nötig.
struct Zufall: RandomNumberGenerator, Sendable {
    private var zustand: UInt64

    init(seed: UInt64) { zustand = seed }

    mutating func next() -> UInt64 {
        zustand &+= 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func kommazahl(_ bereich: ClosedRange<Double>) -> Double {
        let anteil = Double(next() >> 11) / Double(1 << 53)
        return bereich.lowerBound + (bereich.upperBound - bereich.lowerBound) * anteil
    }
}
