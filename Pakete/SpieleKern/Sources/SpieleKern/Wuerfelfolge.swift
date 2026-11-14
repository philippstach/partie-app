// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Woher die Würfel kommen (gemeinsam für Schocken und Rauswurf). Zufall gibt es nur hier (testbar mit Seed oder fester Liste).
public protocol Wuerfelfolge {
    /// Liefert 1…6.
    mutating func naechster() -> Int
}

/// Feste Folge für Tests. Zu kurze Folgen fallen auf (`ueberzogen`).
public struct WuerfelListe: Wuerfelfolge {
    public let folge: [Int]
    public private(set) var index = 0
    public private(set) var ueberzogen = false

    public init(_ folge: [Int]) { self.folge = folge }

    public var verbraucht: Int { index }

    public mutating func naechster() -> Int {
        guard index < folge.count else { ueberzogen = true; return 1 }
        defer { index += 1 }
        return folge[index]
    }
}

/// Seedbarer Zufall (SplitMix64). Der Zustand wird mitgespeichert, damit nach dem Neustart
/// dieselben Würfe kommen.
public struct WuerfelSeed: Wuerfelfolge, Codable, Equatable, Sendable {
    public var zustand: UInt64
    /// Feste Würfe, die zuerst kommen (geführte Partie), danach würfelt der Generator
    public var vorgabe: [Int] = []

    public init(seed: UInt64, vorgabe: [Int] = []) {
        zustand = seed
        self.vorgabe = vorgabe
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        zustand = try c.decode(UInt64.self, forKey: .zustand)
        vorgabe = try c.decodeIfPresent([Int].self, forKey: .vorgabe) ?? []
    }

    public mutating func naechsteZahl() -> UInt64 {
        zustand = zustand &+ 0x9E37_79B9_7F4A_7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    public mutating func naechster() -> Int {
        if !vorgabe.isEmpty { return vorgabe.removeFirst() }
        return Int(naechsteZahl() % 6) + 1
    }

    /// 0 ..< n
    public mutating func naechster(unter n: Int) -> Int { Int(naechsteZahl() % UInt64(n)) }
}
