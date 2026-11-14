// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Zufallsquelle mit Seed (SplitMix64): gleicher Seed, gleiche Folge. Macht Brettbau und Tests wiederholbar.
public struct SeedZufall: RandomNumberGenerator, Sendable {
    private var zustand: UInt64
    public init(seed: UInt64) { zustand = seed }
    public mutating func next() -> UInt64 {
        zustand &+= 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

public struct Position: Hashable, Codable, Sendable {
    public let zeile: Int
    public let spalte: Int
    public init(zeile: Int, spalte: Int) { self.zeile = zeile; self.spalte = spalte }
}

public struct Brettmass: Hashable, Codable, Sendable {
    public let zeilen: Int
    public let spalten: Int
    public let minen: Int
    public init(zeilen: Int, spalten: Int, minen: Int) { self.zeilen = zeilen; self.spalten = spalten; self.minen = minen }

    public var felder: Int { zeilen * spalten }
    public func index(_ p: Position) -> Int { p.zeile * spalten + p.spalte }
    public func position(_ i: Int) -> Position { Position(zeile: i / spalten, spalte: i % spalten) }

    /// Indizes der (bis zu acht) Nachbarfelder.
    public func nachbarn(_ i: Int) -> [Int] {
        let z = i / spalten, s = i % spalten
        var r: [Int] = []
        r.reserveCapacity(8)
        for dz in -1...1 {
            for ds in -1...1 where !(dz == 0 && ds == 0) {
                let nz = z + dz, ns = s + ds
                if nz >= 0, nz < zeilen, ns >= 0, ns < spalten { r.append(nz * spalten + ns) }
            }
        }
        return r
    }
}

public enum Stufe: String, CaseIterable, Codable, Sendable, Identifiable {
    case leicht, mittel, schwer
    public var id: String { rawValue }

    public var mass: Brettmass {
        switch self {
        case .leicht: Brettmass(zeilen: 9, spalten: 7, minen: 8)
        case .mittel: Brettmass(zeilen: 14, spalten: 9, minen: 22)
        case .schwer: Brettmass(zeilen: 18, spalten: 11, minen: 44)
        }
    }
}
