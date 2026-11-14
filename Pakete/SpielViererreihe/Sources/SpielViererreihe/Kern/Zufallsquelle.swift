// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Woher der Zufall kommt. Zufall gibt es nur hier (testbar mit Seed oder fester Liste).
protocol Zufallsquelle: Sendable {
    /// Liefert 0 ..< n. Wird nur für n ≥ 2 aufgerufen.
    mutating func naechste(_ n: Int) -> Int
}

/// Feste Folge für Tests: `folge[i] % n` der Reihe nach.
struct ListenQuelle: Zufallsquelle, Equatable {
    let folge: [Int]
    private(set) var index = 0
    private(set) var ueberzogen = false

    init(_ folge: [Int]) { self.folge = folge }

    var aufgebraucht: Bool { index == folge.count }

    mutating func naechste(_ n: Int) -> Int {
        precondition(n >= 2)
        guard index < folge.count else { ueberzogen = true; return 0 }
        defer { index += 1 }
        return folge[index] % n
    }
}

/// Seedbarer Zufall (SplitMix64, genau wie in `Referenz/viergewinnt.py`).
/// Der Zustand wird mitgespeichert (als Text, weil er nicht in jeden JSON-Zahlentyp passt).
struct SplitMix64: Zufallsquelle, Codable, Equatable {
    var zustand: UInt64

    init(seed: UInt64) { zustand = seed }

    /// Startwert aus der Systemzeit.
    static func ausSystemzeit() -> SplitMix64 {
        SplitMix64(seed: UInt64(truncatingIfNeeded: Int64(Date().timeIntervalSince1970 * 1000)))
    }

    mutating func weiter() -> UInt64 {
        zustand = zustand &+ 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func naechste(_ n: Int) -> Int {
        precondition(n >= 2)
        return Int(weiter() % UInt64(n))
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let text = try? c.decode(String.self), let wert = UInt64(text) {
            zustand = wert
        } else if let wert = try? c.decode(UInt64.self) {
            zustand = wert
        } else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Ungültiger Zufallszustand")
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(String(zustand))
    }
}
