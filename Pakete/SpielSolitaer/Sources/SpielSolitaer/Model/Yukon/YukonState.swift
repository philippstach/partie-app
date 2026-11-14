// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Zustand einer Yukon-Partie: 7 Spalten (verdeckt + offen, unten → oben) und 4 Zielstapel (höchster Wert je Farbe).
/// Karten wie Klondike: Nummer 0…51 = Farbe × 13 + Wert − 1. Kein Stapel, keine Ablage.
struct YukonState: Hashable {
    static let columnCount = 7

    var cols: [Column] = Array(repeating: Column(), count: 7)
    var foundation = [0, 0, 0, 0]
    var score = 0
    var moves = 0

    init(cols: [Column]? = nil, foundation: [Int] = [0, 0, 0, 0], score: Int = 0, moves: Int = 0) {
        var c = Array((cols ?? []).prefix(Self.columnCount))
        while c.count < Self.columnCount { c.append(Column()) }
        self.cols = c
        self.foundation = foundation; self.score = score; self.moves = moves
    }
}

extension YukonState: Codable {
    // Fehlende Felder beim Laden → Standardwert (fehlende Spalten = leer, Ziele = 0)
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        let f = CardID.sanitizedFoundation(try c.decodeIfPresent([Int].self, forKey: .foundation) ?? [])
        self.init(cols: try c.decodeIfPresent([Column].self, forKey: .cols), foundation: f,
                  score: try c.decodeIfPresent(Int.self, forKey: .score) ?? 0,
                  moves: try c.decodeIfPresent(Int.self, forKey: .moves) ?? 0)
    }
    private enum Key: String, CodingKey { case cols, foundation, score, moves }
}

extension YukonState: SolitaireState {
    var isWon: Bool { foundation.allSatisfy { $0 == 13 } }
    var displayScore: Int? { score }
    var stockCount: Int { 0 }
    var stockCardIDs: [CardID] { [] }
    var needsRecycle: Bool { false }
    var hiddenCardCount: Int { cols.reduce(0) { $0 + $1.down.count } }
    var revealedColumns: Int { cols.filter { $0.down.isEmpty && !$0.up.isEmpty }.count }
    var completedFoundations: Int { foundation.filter { $0 == 13 }.count }

    func face(of card: CardID) -> CardFace { CardFace(rank: card.rank, suit: card.suit) }

    /// Austeilen: erst wie Klondike Zeile für Zeile (Spalte r bekommt in Zeile r ihre erste offene Karte),
    /// dann vier Zeilen offener Karten auf Spalte 1 … 6
    func dealOrder(of card: CardID) -> Int? {
        for (c, col) in cols.enumerated() {
            guard let p = (col.down + col.up).firstIndex(of: card) else { continue }
            if p <= c {
                // Teil 1: Zeilen 0 … c−1 enthalten je (7 − r) Karten; in Zeile p liegt Spalte c an Platz c − p
                var n = 0
                for r in 0..<p { n += 7 - r }
                return n + (c - p)
            }
            return 28 + (p - c - 1) * 6 + (c - 1)
        }
        return nil
    }

    func dealColumn(of card: CardID) -> Int? { cols.firstIndex { ($0.down + $0.up).contains(card) } }
    func stagger(of card: CardID, style: MoveStyle) -> Double { 0 }
}
