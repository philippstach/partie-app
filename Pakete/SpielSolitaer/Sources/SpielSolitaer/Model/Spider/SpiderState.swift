// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Eine fertige Reihe (König bis Ass derselben Farbe), die abgeräumt wurde.
/// `cards` kennt die 13 Karten (für die Flug-Animation); in Testzuständen aus JSON ist sie leer.
struct DoneRun: Codable, Hashable {
    var suit: Int
    var cards: [CardID] = []
}

/// Zustand einer Spider-Partie (1, 2 oder 4 Farben). Karten 0…103: Satz = Nummer ÷ 13, Wert = Nummer mod 13 + 1.
struct SpiderState: Hashable {
    static let columnCount = 10
    static let startScore = 500

    var suits = 2                      // 1, 2 oder 4
    var stock: [CardID] = []           // oben = letzte
    var cols = Array(repeating: Column(), count: 10)
    var done: [DoneRun] = []
    var score = SpiderState.startScore
    var moves = 0                      // Spielerzüge (Abräumen zählt nicht)
    var deals = 0                      // wie oft vom Stapel ausgeteilt

    init(suits: Int = 2, stock: [CardID] = [], cols: [Column]? = nil, done: [DoneRun] = [],
         score: Int = SpiderState.startScore, moves: Int = 0, deals: Int = 0) {
        self.suits = suits; self.stock = stock; self.done = done
        self.cols = cols ?? Array(repeating: Column(), count: 10)
        self.score = score; self.moves = moves; self.deals = deals
    }

    /// Farbe (0 Pik, 1 Herz, 2 Karo, 3 Kreuz) einer Karte: 1 Farbe immer Pik · 2 Farben gerade Sätze Pik, ungerade Herz · 4 Farben Satz mod 4
    static func suit(of card: CardID, suits: Int) -> Int {
        let set = card.number / 13
        switch suits {
        case 1: return 0
        case 2: return set % 2
        default: return set % 4
        }
    }

    static func rank(of card: CardID) -> Int { card.number % 13 + 1 }

    func suit(_ card: CardID) -> Int { Self.suit(of: card, suits: suits) }
    func rank(_ card: CardID) -> Int { Self.rank(of: card) }
}

extension SpiderState: Codable {
    // Fehlende Felder beim Laden → Standardwert (`score` 500)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        let n = try c.decodeIfPresent(Int.self, forKey: .suits) ?? 2
        suits = [1, 2, 4].contains(n) ? n : 2          // nur 1, 2 oder 4 Farben (sonst Division durch 0 bei der Farbe)
        stock = try c.decodeIfPresent([CardID].self, forKey: .stock) ?? []
        cols = try c.decodeIfPresent([Column].self, forKey: .cols) ?? []
        cols = Array(cols.prefix(Self.columnCount))
        while cols.count < Self.columnCount { cols.append(Column()) }
        done = try c.decodeIfPresent([DoneRun].self, forKey: .done) ?? []
        score = try c.decodeIfPresent(Int.self, forKey: .score) ?? Self.startScore
        moves = try c.decodeIfPresent(Int.self, forKey: .moves) ?? 0
        deals = try c.decodeIfPresent(Int.self, forKey: .deals) ?? 0
    }
    private enum Key: String, CodingKey { case suits, stock, cols, done, score, moves, deals }
}

extension SpiderState: SolitaireState {
    var isWon: Bool { done.count == 8 }
    var displayScore: Int? { score }
    var stockCount: Int { stock.count }
    var stockCardIDs: [CardID] { stock }
    var needsRecycle: Bool { false }
    var hiddenCardCount: Int { cols.reduce(0) { $0 + $1.down.count } }
    var completedFoundations: Int { done.count }

    func face(of card: CardID) -> CardFace {
        CardFace(rank: rank(card), suit: Suit(rawValue: suit(card))!)
    }

    /// Austeilen: Zeile für Zeile, Spalte 0…9 (S0–S3 bekommen 6, S4–S9 bekommen 5 Karten)
    func dealOrder(of card: CardID) -> Int? {
        var n = 0
        for r in 0..<6 {
            for c in 0..<10 where r < (c < 4 ? 6 : 5) {
                let all = cols[c].down + cols[c].up
                if r < all.count, all[r] == card { return n }
                n += 1
            }
        }
        return nil
    }

    func dealColumn(of card: CardID) -> Int? {
        for (i, c) in cols.enumerated() where (c.down + c.up).contains(card) { return i }
        return nil
    }

    /// Stapel ausgeteilt: die 10 neuen Karten (oberste je Spalte) landen nacheinander, je 0,04 s.
    /// Reihe abgeräumt: die 13 Karten fliegen nacheinander vom Ass bis zum König ab, je 0,035 s.
    func stagger(of card: CardID, style: MoveStyle) -> Double {
        switch style {
        case .draw:
            guard let c = dealColumn(of: card), cols[c].up.last == card else { return 0 }
            return Double(c) * 0.04
        case .complete:
            guard done.contains(where: { $0.cards.contains(card) }) else { return 0 }
            return Double(rank(card) - 1) * 0.035
        default:
            return 0
        }
    }
}
