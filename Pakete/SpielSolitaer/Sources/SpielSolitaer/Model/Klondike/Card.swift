// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

enum Suit: Int, CaseIterable, Codable {
    case spades, hearts, diamonds, clubs

    var isRed: Bool { self == .hearts || self == .diamonds }

    var symbol: String {
        switch self {
        case .spades: "♠"
        case .hearts: "♥"
        case .diamonds: "♦"
        case .clubs: "♣"
        }
    }

    var name: String {
        switch self {
        case .spades: String(localized: "Pik")
        case .hearts: String(localized: "Herz")
        case .diamonds: String(localized: "Karo")
        case .clubs: String(localized: "Kreuz")
        }
    }
}

/// Karte 0…51 = Farbe × 13 + Wert − 1 (Farben: Pik, Herz, Karo, Kreuz).
struct CardID: Hashable, Codable, Identifiable {
    let number: Int

    init(_ number: Int) { self.number = number }
    init(rank: Int, suit: Suit) { number = suit.rawValue * 13 + rank - 1 }

    /// Gültig sind 0…103 (52 Karten, bei Spider zwei Decks); alles andere ist ein beschädigter Spielstand → Laden schlägt fehl, neue Partie
    init(from decoder: Decoder) throws {
        let n = try decoder.singleValueContainer().decode(Int.self)
        guard (0..<104).contains(n) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Kartennummer \(n) außerhalb von 0…103"))
        }
        number = n
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(number)
    }

    var id: Int { number }
    var suit: Suit { Suit(rawValue: number % 52 / 13) ?? .spades }
    /// 1 = Ass … 11 = Bube, 12 = Dame, 13 = König
    var rank: Int { number % 13 + 1 }
    var isRed: Bool { suit.isRed }

    static let all = (0..<52).map(CardID.init)

    /// Ziele aus einem Spielstand: genau 4 Werte zwischen 0 und 13 (fehlende → 0, zu große werden begrenzt)
    static func sanitizedFoundation(_ f: [Int]) -> [Int] {
        (0..<4).map { $0 < f.count ? min(max(f[$0], 0), 13) : 0 }
    }

    /// Darf diese Karte in einer Spalte auf `under` liegen? Eins kleiner, andere Farbe.
    func fits(on under: CardID) -> Bool { rank == under.rank - 1 && isRed != under.isRed }

    /// Kurzschrift der Tests, z. B. „TH“ = Herz-Zehn
    var shortName: String { String(CardID.rankLetters[rank - 1]) + String(CardID.suitLetters[suit.rawValue]) }
    static let rankLetters = Array("A23456789TJQK")
    static let suitLetters = Array("SHDC")
}
