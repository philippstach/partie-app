// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Reproduzierbarer Zufall (SplitMix64) für Tests und Wiederholungen; im Spiel mit Zeitstempel als Startwert.
public struct ArcadeZufall: RandomNumberGenerator, Sendable, Equatable, Codable {
    private var zustand: UInt64
    public init(startwert: UInt64) { zustand = startwert &+ 0x9E37_79B9_7F4A_7C15 }
    public init() { self.init(startwert: UInt64(truncatingIfNeeded: Int(Date().timeIntervalSince1970 * 1000)) ^ UInt64.random(in: 0...UInt64.max)) }
    public mutating func next() -> UInt64 {
        zustand &+= 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    public mutating func zahl(_ bereich: ClosedRange<Double>) -> Double { Double.random(in: bereich, using: &self) }
    public mutating func ganz(_ bereich: ClosedRange<Int>) -> Int { Int.random(in: bereich, using: &self) }
    public mutating func wahr(_ wahrscheinlichkeit: Double) -> Bool { Double.random(in: 0..<1, using: &self) < wahrscheinlichkeit }
}

/// „Beutel“ statt reinem Zufall: jede Sorte kommt in jeder Runde genau einmal vor (keine endlosen Serien derselben Sorte).
public struct Beutel: Equatable, Sendable, Codable {
    private var inhalt: [Int] = []
    public let sorten: Int
    public init(sorten: Int) { self.sorten = sorten }
    public mutating func ziehe(_ z: inout ArcadeZufall) -> Int {
        if inhalt.isEmpty { inhalt = Array(0..<sorten).shuffled(using: &z) }
        return inhalt.removeLast()
    }
}
