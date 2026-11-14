// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Zustand einer FreeCell-Partie: 8 Spalten (unten → oben), 4 freie Zellen, 4 Zielstapel (höchster Wert je Farbe).
/// Karten wie Klondike: Nummer 0…51 = Farbe × 13 + Wert − 1.
struct FreeCellState: Hashable {
    static let columnCount = 8
    static let cellCount = 4

    var cols: [[CardID]] = Array(repeating: [], count: 8)
    var cells: [CardID?] = [nil, nil, nil, nil]
    var foundation = [0, 0, 0, 0]
    var moves = 0
    /// Partienummer (Microsoft-Nummern 1…32000; 0 = von Hand gebaut)
    var number = 0

    init(cols: [[CardID]]? = nil, cells: [CardID?]? = nil, foundation: [Int] = [0, 0, 0, 0], moves: Int = 0, number: Int = 0) {
        self.cols = cols ?? Array(repeating: [], count: 8)
        self.cells = cells ?? [nil, nil, nil, nil]
        self.foundation = foundation; self.moves = moves; self.number = number
    }
}

extension FreeCellState: Codable {
    // Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        cols = try c.decodeIfPresent([[CardID]].self, forKey: .cols) ?? []
        cols = Array(cols.prefix(Self.columnCount))
        while cols.count < Self.columnCount { cols.append([]) }
        cells = try c.decodeIfPresent([CardID?].self, forKey: .cells) ?? []
        cells = Array(cells.prefix(Self.cellCount))
        while cells.count < Self.cellCount { cells.append(nil) }
        foundation = CardID.sanitizedFoundation(try c.decodeIfPresent([Int].self, forKey: .foundation) ?? [])
        moves = try c.decodeIfPresent(Int.self, forKey: .moves) ?? 0
        number = try c.decodeIfPresent(Int.self, forKey: .number) ?? 0
    }
    private enum Key: String, CodingKey { case cols, cells, foundation, moves, number }
}

extension FreeCellState: SolitaireState {
    var isWon: Bool { foundation.allSatisfy { $0 == 13 } }
    /// FreeCell hat keine Punkte
    var displayScore: Int? { nil }
    var stockCount: Int { 0 }
    var stockCardIDs: [CardID] { [] }
    var needsRecycle: Bool { false }
    var hiddenCardCount: Int { 0 }
    var completedFoundations: Int { foundation.filter { $0 == 13 }.count }

    func face(of card: CardID) -> CardFace { CardFace(rank: card.rank, suit: card.suit) }

    /// Geben: Karte Nummer i kommt in Spalte i mod 8 – die Reihenfolge des Austeilens ergibt sich aus Platz und Spalte
    func dealOrder(of card: CardID) -> Int? {
        for (c, col) in cols.enumerated() {
            if let p = col.firstIndex(of: card) { return p * 8 + c }
        }
        return nil
    }

    func dealColumn(of card: CardID) -> Int? { cols.firstIndex { $0.contains(card) } }

    func stagger(of card: CardID, style: MoveStyle) -> Double { 0 }
}
