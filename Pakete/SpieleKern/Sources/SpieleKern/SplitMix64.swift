// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Kleiner, seedbarer Zufallsgenerator (SplitMix64): gleicher Seed, gleiche Folge, auf allen Plattformen.
/// Vorher hatte jedes Spiel eine eigene, bitgleiche Kopie (Sudoku, Galgenmännchen, Solitär). An der Folge hängen Tagesrätsel,
/// Tagespartien und geteilte Rätsel: Die Rechenvorschrift darf sich nie ändern (geprüft mit den `zufall`-Regeltests der Spiele).
public struct SplitMix64: RandomNumberGenerator, Sendable {
    private var state: UInt64

    public init(seed: UInt64) { state = seed }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// 0…n−1, schlicht per Rest (überall gleich).
    public mutating func below(_ n: Int) -> Int { Int(next() % UInt64(n)) }
}
