// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Vollständiger gespeicherter Stand: das Brett samt verbrauchter Zeit, Tipp-Zähler und dem Merkmal „Tagesrätsel“.
/// Früher wurde nur das Brett gespeichert; beim Fortsetzen begann die Zeit bei null, Tipps zählten nicht mehr und ein
/// Tagesrätsel galt als freies Brett (falsche Bestleistung). Alte Stände (nur das Brett) bleiben ladbar.
public struct SchiebepuzzleStand: Codable, Equatable, Sendable {
    public var puzzle: Schiebepuzzle
    /// Bisher verbrauchte Spielzeit in Sekunden.
    public var sekunden: Int
    public var tipps: Int
    public var tag: Bool

    public init(puzzle: Schiebepuzzle, sekunden: Int = 0, tipps: Int = 0, tag: Bool = false) {
        self.puzzle = puzzle; self.sekunden = sekunden; self.tipps = tipps; self.tag = tag
    }

    private enum CodingKeys: String, CodingKey { case puzzle, sekunden, tipps, tag }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if c.contains(.puzzle) {
            puzzle = try c.decode(Schiebepuzzle.self, forKey: .puzzle)
            sekunden = try c.decodeIfPresent(Int.self, forKey: .sekunden) ?? 0
            tipps = try c.decodeIfPresent(Int.self, forKey: .tipps) ?? 0
            tag = try c.decodeIfPresent(Bool.self, forKey: .tag) ?? false
        } else {
            puzzle = try Schiebepuzzle(from: decoder)   // altes Format: nur das Brett
            sekunden = 0; tipps = 0; tag = false
        }
    }

    public var istKonsistent: Bool { puzzle.istKonsistent && sekunden >= 0 && tipps >= 0 }
}
