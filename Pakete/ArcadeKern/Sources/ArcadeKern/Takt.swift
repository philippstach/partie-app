// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Fester Zeitschritt: Die Anzeige liefert unregelmäßige Bildzeiten, die Spiellogik rechnet immer mit `dt` (1/120 s).
/// Dadurch verhält sich jedes Spiel auf jedem Gerät gleich und ist mit Tests reproduzierbar.
public struct FesterTakt: Equatable, Sendable {
    public static let schritt = 1.0 / 120.0
    /// Längste Bildzeit, die nachgeholt wird (Rest verfällt, z. B. nach dem Wechsel in den Hintergrund).
    public static let maxBild = 0.1
    private var rest = 0.0
    public init() {}

    /// Anzahl der festen Schritte, die für die vergangene Bildzeit zu rechnen sind.
    public mutating func schritte(fuer bildzeit: Double) -> Int {
        guard bildzeit > 0 else { return 0 }
        rest += min(bildzeit, FesterTakt.maxBild)
        let n = Int(rest / FesterTakt.schritt)
        rest -= Double(n) * FesterTakt.schritt
        return n
    }
    public mutating func zuruecksetzen() { rest = 0 }
}

/// Zustand eines Arcade-Spiels. Der Rahmen steuert nur über diese Phasen.
public enum ArcadePhase: Equatable, Sendable, Codable {
    /// Wartet auf den ersten Fingertipp (Uhr steht).
    case bereit
    case laeuft
    /// Aus und vorbei; `grund` erklärt dem Spieler, woran es lag.
    case vorbei(grund: String)

    public var istVorbei: Bool { if case .vorbei = self { return true } else { return false } }
    public var laeuft: Bool { self == .laeuft }
    /// Erklärung, warum das Spiel aus ist.
    public var grund: String? { if case .vorbei(let g) = self { return g } else { return nil } }
}
