// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Zustand einer Golf-Partie: 7 Spalten zu je 5 offenen Karten (unten → oben), Stapel und Ablage (unten → oben).
/// Karten wie Klondike: Nummer 0…51 = Farbe × 13 + Wert − 1.
struct GolfState: Hashable {
    static let columnCount = 7
    static let columnHeight = 5

    var cols: [[CardID]] = Array(repeating: [], count: 7)
    var stock: [CardID] = []
    var waste: [CardID] = []
    /// Spaltenkarten seit dem letzten Ziehen vom Stapel (nur zur Anzeige, keine Punkte)
    var chain = 0
    /// Beim Sieg: übrige Stapelkarten
    var score = 0
    var moves = 0

    init(cols: [[CardID]]? = nil, stock: [CardID] = [], waste: [CardID] = [], chain: Int = 0, score: Int = 0, moves: Int = 0) {
        var c = Array((cols ?? []).prefix(Self.columnCount))
        while c.count < Self.columnCount { c.append([]) }
        self.cols = c
        self.stock = stock; self.waste = waste; self.chain = chain; self.score = score; self.moves = moves
    }

    /// Eins höher oder niedriger, kein Ringsum; auf einen König darf nichts
    static func fits(_ c: CardID, on top: CardID) -> Bool { top.rank != 13 && abs(c.rank - top.rank) == 1 }

    var cardsLeft: Int { cols.reduce(0) { $0 + $1.count } }
}

extension GolfState: Codable {
    // Fehlende Felder beim Laden → Standardwert (fehlende Spalten = leer)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        self.init(cols: try c.decodeIfPresent([[CardID]].self, forKey: .cols),
                  stock: try c.decodeIfPresent([CardID].self, forKey: .stock) ?? [],
                  waste: try c.decodeIfPresent([CardID].self, forKey: .waste) ?? [],
                  chain: try c.decodeIfPresent(Int.self, forKey: .chain) ?? 0,
                  score: try c.decodeIfPresent(Int.self, forKey: .score) ?? 0,
                  moves: try c.decodeIfPresent(Int.self, forKey: .moves) ?? 0)
    }
    private enum Key: String, CodingKey { case cols, stock, waste, chain, score, moves }
}

extension GolfState: SolitaireState {
    var isWon: Bool { cols.allSatisfy(\.isEmpty) }
    /// Punkte = übrige Stapelkarten, erst beim Sieg
    var displayScore: Int? { isWon ? score : nil }
    var stockCount: Int { stock.count }
    var stockCardIDs: [CardID] { stock }
    var needsRecycle: Bool { false }
    var hiddenCardCount: Int { 0 }
    var completedFoundations: Int { 0 }

    func face(of card: CardID) -> CardFace { CardFace(rank: card.rank, suit: card.suit) }

    /// Austeilen: Zeile für Zeile (unterste Karte jeder Spalte zuerst)
    func dealOrder(of card: CardID) -> Int? {
        for (c, col) in cols.enumerated() {
            if let p = col.firstIndex(of: card) { return p * Self.columnCount + c }
        }
        return nil
    }
    func dealColumn(of card: CardID) -> Int? { cols.firstIndex { $0.contains(card) } }
    func stagger(of card: CardID, style: MoveStyle) -> Double { 0 }
}
