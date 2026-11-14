// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Woher die Augen kommen (Konzept 4): von der App oder von echten Würfeln, die der Spieler eintippt.
public enum WuerfelQuelle: String, Codable, CaseIterable, Sendable { case app, echt }

public struct ZufallsQuelle: RandomNumberGenerator {
    var zustand: UInt64
    public init(seed: UInt64) { zustand = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed }
    public mutating func next() -> UInt64 {
        zustand &+= 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// Becher mit n Würfeln: halten, würfeln, Verlauf. Zufall austauschbar (Tests: fester Seed).
public struct WuerfelBecher: Equatable, Sendable, Codable {
    public var augen: [Int]
    public var gehalten: [Bool]
    public private(set) var verlauf: [[Int]] = []

    public init(anzahl: Int) { augen = Array(repeating: 1, count: anzahl); gehalten = Array(repeating: false, count: anzahl) }

    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) {
        for i in augen.indices where !gehalten[i] { augen[i] = Int.random(in: 1...6, using: &g) }
        verlauf.append(augen)
    }

    /// Echte Würfel: Augen werden eingetippt (nur gültige Werte 1–6).
    public mutating func eintragen(_ neu: [Int]) -> Bool {
        guard neu.count == augen.count, neu.allSatisfy({ (1...6).contains($0) }) else { return false }
        augen = neu; verlauf.append(neu); return true
    }

    public mutating func halten(_ index: Int) { guard augen.indices.contains(index) else { return }; gehalten[index].toggle() }
    public mutating func freigeben() { gehalten = Array(repeating: false, count: augen.count) }
    public mutating func korrigiereLetzten(_ neu: [Int]) -> Bool {
        guard neu.count == augen.count, neu.allSatisfy({ (1...6).contains($0) }) else { return false }
        augen = neu; if !verlauf.isEmpty { verlauf[verlauf.count - 1] = neu }; return true
    }
}
