// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Schweinerei (Pig): Würfle so oft du willst und sammle Punkte; bei einer 1 verfällt die Runde. Wer zuerst das Ziel erreicht, gewinnt.
public struct Schweinerei: Equatable, Sendable, Codable {
    public let ziel: Int
    public private(set) var punkte: [Int]
    public private(set) var runde = 0
    public private(set) var dran = 0
    public private(set) var letzterWurf: Int?
    public private(set) var verfallen = false

    public init(spieler: Int, ziel: Int = 100) { self.ziel = ziel; punkte = Array(repeating: 0, count: spieler) }

    public var sieger: Int? { punkte.firstIndex { $0 >= ziel } }

    public mutating func wuerfeln<G: RandomNumberGenerator>(mit g: inout G) { setzeWurf(Int.random(in: 1...6, using: &g)) }

    /// Wurf vorgeben (echte Würfel, Tests).
    public mutating func setzeWurf(_ w: Int) {
        guard sieger == nil, (1...6).contains(w) else { return }
        letzterWurf = w; verfallen = false
        if w == 1 { runde = 0; verfallen = true; naechster() } else { runde += w }
    }

    public mutating func sichern() {
        guard sieger == nil, runde > 0 else { return }
        punkte[dran] += runde; runde = 0; letzterWurf = nil; verfallen = false
        if sieger == nil { naechster() }
    }

    private mutating func naechster() { dran = (dran + 1) % punkte.count }
}

public enum SchweinereiComputer {
    /// Sichert ab 20 Punkten in der Runde oder wenn das Ziel erreicht wäre.
    /// `stufe` 1 leicht (sichert schon ab 10), 2 mittel (ab 20), 3 schwer (Schwelle nach Punktestand und Gegner, nahe am Ziel mutiger).
    public static func sichert(_ s: Schweinerei, stufe: Int = 2) -> Bool {
        let mein = s.punkte[s.dran], gegner = s.punkte.enumerated().filter { $0.offset != s.dran }.map(\.element).max() ?? 0
        if mein + s.runde >= s.ziel { return true }
        switch stufe {
        case ...1: return s.runde >= 10
        case 2: return s.runde >= 20
        default:
            var schwelle = 25.0 + Double(gegner - mein) / 8.0
            if gegner >= s.ziel - 29 { schwelle = max(schwelle, Double(s.ziel - mein)) }   // Gegner kurz vor dem Ziel: weiterwürfeln
            if mein >= s.ziel - 25 { schwelle = Double(s.ziel - mein) }                      // selbst nah dran: bis zum Ziel würfeln
            return Double(s.runde) >= max(8, schwelle)
        }
    }
}
