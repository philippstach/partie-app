// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Varianten und Schwellen. Fehlende Schlüssel in gespeicherten Ständen fallen auf den Standard zurück.
nonisolated struct Rules: Codable, Equatable, Sendable {
    var joker = false
    /// Punkte je zusätzlichem Yacht (0 = Yacht-Bonus aus)
    var kniffelBonus = 0
    var upperBonusThreshold = 63
    var upperBonus = 35
    /// Welche Wertung gilt (Standard: Kniffel, wie in allen bisherigen Spielständen)
    var variant = Variant.kniffel

    /// Regeln einer Wertung mit deren Bonus-Werten; Joker und Yacht-Bonus bleiben aus.
    /// Der Yacht-Bonus schaltet den Joker immer mit ein (sonst gäbe es nie einen Bonus; RT-001).
    static func fuer(_ variant: Variant, joker: Bool = false, kniffelBonus: Int = 0) -> Rules {
        let b = variant.upperBonus
        var r = Rules(joker: (joker || kniffelBonus > 0) && variant.hatJoker, kniffelBonus: variant.hatJoker ? kniffelBonus : 0, upperBonusThreshold: b.threshold, upperBonus: b.value)
        r.variant = variant
        return r
    }

    init(joker: Bool = false, kniffelBonus: Int = 0, upperBonusThreshold: Int = 63, upperBonus: Int = 35) {
        self.joker = joker
        self.kniffelBonus = kniffelBonus
        self.upperBonusThreshold = upperBonusThreshold
        self.upperBonus = upperBonus
    }

    enum CodingKeys: String, CodingKey { case joker, kniffelBonus, upperBonusThreshold, upperBonus, variant }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        joker = try c.decodeIfPresent(Bool.self, forKey: .joker) ?? false
        kniffelBonus = try c.decodeIfPresent(Int.self, forKey: .kniffelBonus) ?? 0
        upperBonusThreshold = try c.decodeIfPresent(Int.self, forKey: .upperBonusThreshold) ?? 63
        upperBonus = try c.decodeIfPresent(Int.self, forKey: .upperBonus) ?? 35
        variant = (try? c.decodeIfPresent(Variant.self, forKey: .variant)) ?? .kniffel
    }
}

nonisolated enum Action: Equatable, Sendable {
    case roll(keep: [Int])
    case score(Category)
}

nonisolated enum GameError: Error, Equatable, Sendable {
    case noRollLeft
    case invalidKeep
    case notRolledYet
    case categoryNotAllowed
}

nonisolated struct Totals: Equatable, Sendable {
    var upper = 0, bonus = 0, lower = 0, kniffelBonus = 0, total = 0
}
