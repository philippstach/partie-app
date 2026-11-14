// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Zustand einer Pyramid-Partie: 28 Plätze der Pyramide (Reihe r, Platz i = r·(r+1)/2 + i; nil = weg), Stapel und Ablage (unten → oben).
/// Karten wie Klondike: Nummer 0…51 = Farbe × 13 + Wert − 1.
struct PyramidState: Hashable {
    static let rows = 7
    static let places = 28
    static let maxPasses = 3

    var pyramid: [CardID?] = Array(repeating: nil, count: 28)
    var stock: [CardID] = []
    var waste: [CardID] = []
    /// Durchgang 1 … 3 (2 × Umdrehen)
    var passes = 1
    var moves = 0

    init(pyramid: [CardID?]? = nil, stock: [CardID] = [], waste: [CardID] = [], passes: Int = 1, moves: Int = 0) {
        var p = pyramid ?? []
        while p.count < Self.places { p.append(nil) }
        self.pyramid = Array(p.prefix(Self.places))
        self.stock = stock; self.waste = waste; self.passes = passes; self.moves = moves
    }

    static func row(of k: Int) -> Int { rowOf[k] }
    static func column(of k: Int) -> Int { colOf[k] }
    static func place(row r: Int, index i: Int) -> Int { r * (r + 1) / 2 + i }

    private static let rowOf: [Int] = (0..<rows).flatMap { r in Array(repeating: r, count: r + 1) }
    private static let colOf: [Int] = (0..<rows).flatMap { r in Array(0...r) }
    /// Die zwei Plätze direkt darunter (Reihe 6: keine)
    static let below: [[Int]] = (0..<places).map { k in
        rowOf[k] == rows - 1 ? [] : [place(row: rowOf[k] + 1, index: colOf[k]), place(row: rowOf[k] + 1, index: colOf[k] + 1)]
    }

    /// Platz belegt und beide Plätze darunter leer
    func isFree(_ k: Int) -> Bool {
        pyramid[k] != nil && Self.below[k].allSatisfy { pyramid[$0] == nil }
    }

    var freePlaces: [Int] { (0..<Self.places).filter(isFree) }
}

extension PyramidState: Codable {
    // Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        self.init(pyramid: try c.decodeIfPresent([CardID?].self, forKey: .pyramid),
                  stock: try c.decodeIfPresent([CardID].self, forKey: .stock) ?? [],
                  waste: try c.decodeIfPresent([CardID].self, forKey: .waste) ?? [],
                  passes: try c.decodeIfPresent(Int.self, forKey: .passes) ?? 1,
                  moves: try c.decodeIfPresent(Int.self, forKey: .moves) ?? 0)
    }
    private enum Key: String, CodingKey { case pyramid, stock, waste, passes, moves }
}

extension PyramidState: SolitaireState {
    var isWon: Bool { pyramid.allSatisfy { $0 == nil } }
    /// Pyramid hat keine Punkte (vorläufig)
    var displayScore: Int? { nil }
    var stockCount: Int { stock.count }
    var stockCardIDs: [CardID] { stock }
    var needsRecycle: Bool { stock.isEmpty && !waste.isEmpty && passes < Self.maxPasses }
    var hiddenCardCount: Int { 0 }
    var completedFoundations: Int { 0 }

    func face(of card: CardID) -> CardFace { CardFace(rank: card.rank, suit: card.suit) }

    /// Austeilen: Pyramide Platz für Platz
    func dealOrder(of card: CardID) -> Int? { pyramid.firstIndex(of: card) }
    func dealColumn(of card: CardID) -> Int? { pyramid.firstIndex(of: card).map { Self.colOf[$0] } }
    func stagger(of card: CardID, style: MoveStyle) -> Double { 0 }
}
