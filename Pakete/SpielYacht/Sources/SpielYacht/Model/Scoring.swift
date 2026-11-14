// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Die 13 Felder des Wertungsblocks. Die Schlüssel (auch `kniffel`) sind mit den gemeinsamen
/// Regeltests abgestimmt und dürfen nicht umbenannt werden; in der Oberfläche heißt das Feld „Yacht“.
nonisolated enum Category: String, Codable, CaseIterable, Sendable {
    case ones, twos, threes, fours, fives, sixes
    case threeOfAKind, fourOfAKind, fullHouse, smallStraight, largeStraight, kniffel, chance
    /// Nur Yatzy: ein Paar, zwei Paare
    case onePair, twoPairs

    /// Die 13 Felder des Kniffel-Blocks (Standard). Die Felder anderer Wertungen stehen in `Variant.fields`.
    static var allCases: [Category] {
        [.ones, .twos, .threes, .fours, .fives, .sixes, .threeOfAKind, .fourOfAKind, .fullHouse, .smallStraight, .largeStraight, .kniffel, .chance]
    }

    static let upper: [Category] = [.ones, .twos, .threes, .fours, .fives, .sixes]
    static let lower: [Category] = [.threeOfAKind, .fourOfAKind, .fullHouse, .smallStraight, .largeStraight, .kniffel, .chance]

    var isUpper: Bool { Self.upper.contains(self) }

    /// Augenzahl der oberen Felder (Einser = 1 …), sonst nil.
    var face: Int? { Self.upper.firstIndex(of: self).map { $0 + 1 } }
}

/// Welche Wertung gilt: Kniffel (Standard, wie bisher), Yatzy (skandinavisch) oder die Original-Yacht (1938, ohne Chance und Bonus).
nonisolated enum Variant: String, Codable, CaseIterable, Sendable {
    case kniffel, yatzy, yacht

    /// Felder in der Reihenfolge des Blocks.
    var fields: [Category] {
        switch self {
        case .kniffel: Category.allCases
        case .yatzy: Category.upper + [.onePair, .twoPairs, .threeOfAKind, .fourOfAKind, .smallStraight, .largeStraight, .fullHouse, .chance, .kniffel]
        case .yacht: Category.upper + [.fullHouse, .fourOfAKind, .smallStraight, .largeStraight, .kniffel]
        }
    }

    /// Schwelle und Wert des oberen Bonus (Wert 0 = kein Bonus).
    var upperBonus: (threshold: Int, value: Int) {
        switch self {
        case .kniffel: (63, 35)
        case .yatzy: (63, 50)
        case .yacht: (0, 0)
        }
    }

    /// Hat die Wertung einen Joker (nur Kniffel, als Schalter)?
    var hatJoker: Bool { self == .kniffel }
}

/// Wertung nach `Doku/REGELN.md`. Reine Funktionen, keine UI.
nonisolated enum Scoring {
    /// Punkte für `dice` im Feld `category`. `joker`: Yacht als Joker gewertet
    /// (Full House, kleine und große Straße zählen dann voll).
    static func score(_ dice: [Int], _ category: Category, joker: Bool = false, variant: Variant = .kniffel) -> Int {
        if variant != .kniffel { return scoreOther(dice, category, variant) }
        var counts = [Int: Int]()
        for d in dice { counts[d, default: 0] += 1 }
        let maxSame = counts.values.max() ?? 0
        let sum = dice.reduce(0, +)
        let unique = Set(dice)

        switch category {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            let n = category.face ?? 0
            return n * (counts[n] ?? 0)
        case .threeOfAKind: return maxSame >= 3 ? sum : 0
        case .fourOfAKind: return maxSame >= 4 ? sum : 0
        case .fullHouse:
            return (counts.values.sorted() == [2, 3] || joker) ? 25 : 0
        case .smallStraight:
            let hit = (1...3).contains { a in Set([a, a + 1, a + 2, a + 3]).isSubset(of: unique) }
            return (hit || joker) ? 30 : 0
        case .largeStraight:
            let sorted = dice.sorted()
            return (sorted == [1, 2, 3, 4, 5] || sorted == [2, 3, 4, 5, 6] || joker) ? 40 : 0
        case .kniffel: return maxSame == 5 ? 50 : 0
        case .chance: return sum
        case .onePair, .twoPairs: return 0
        }
    }

    /// Yatzy und Original-Yacht (siehe `Variant`).
    private static func scoreOther(_ dice: [Int], _ category: Category, _ variant: Variant) -> Int {
        var counts = [Int: Int]()
        for d in dice { counts[d, default: 0] += 1 }
        let sum = dice.reduce(0, +)
        let sorted = dice.sorted()
        let haus = counts.values.sorted() == [2, 3]
        let klein = sorted == [1, 2, 3, 4, 5], gross = sorted == [2, 3, 4, 5, 6]
        func hoechste(_ n: Int) -> Int? { counts.filter { $0.value >= n }.keys.max() }
        let yatzy = variant == .yatzy
        switch category {
        case .ones, .twos, .threes, .fours, .fives, .sixes:
            let n = category.face ?? 0
            return n * (counts[n] ?? 0)
        case .onePair: return yatzy ? (hoechste(2).map { 2 * $0 } ?? 0) : 0
        case .twoPairs:
            let paare = counts.filter { $0.value >= 2 }.keys.sorted(by: >)
            return yatzy && paare.count >= 2 ? 2 * (paare[0] + paare[1]) : 0
        case .threeOfAKind: return yatzy ? (hoechste(3).map { 3 * $0 } ?? 0) : 0
        case .fourOfAKind: return hoechste(4).map { 4 * $0 } ?? 0
        case .fullHouse: return haus ? sum : 0
        case .smallStraight: return klein ? (yatzy ? 15 : 30) : 0
        case .largeStraight: return gross ? (yatzy ? 20 : 30) : 0
        case .kniffel: return counts.values.max() == 5 ? 50 : 0
        case .chance: return yatzy ? sum : 0
        }
    }
}
