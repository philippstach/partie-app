// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Zustand einer TriPeaks-Partie: 28 Plätze der drei Gipfel (T0 … T27, nil = weg), Stapel und Ablage (unten → oben).
/// Karten wie Klondike: Nummer 0…51 = Farbe × 13 + Wert − 1.
struct TriPeaksState: Hashable {
    static let places = 28
    /// Reihe 0: T0–T2 · Reihe 1: T3–T8 · Reihe 2: T9–T17 · Reihe 3: T18–T27
    static let rowStart = [0, 3, 9, 18, 28]
    static let peakPlaces = [0, 1, 2]
    static let scorePeak = 15
    static let scoreLastPeak = 30

    var peaks: [CardID?] = Array(repeating: nil, count: 28)
    var stock: [CardID] = []
    var waste: [CardID] = []
    /// Gipfelkarten seit dem letzten Ziehen vom Stapel
    var chain = 0
    var score = 0
    var moves = 0

    init(peaks: [CardID?]? = nil, stock: [CardID] = [], waste: [CardID] = [], chain: Int = 0, score: Int = 0, moves: Int = 0) {
        var p = peaks ?? []
        while p.count < Self.places { p.append(nil) }
        self.peaks = Array(p.prefix(Self.places))
        self.stock = stock; self.waste = waste; self.chain = chain; self.score = score; self.moves = moves
    }

    static func row(of t: Int) -> Int { rowStart.lastIndex { $0 <= t }! }
    static func index(of t: Int) -> Int { t - rowStart[row(of: t)] }

    /// ON[t] = Plätze, auf denen Karte t liegt (die sie verdeckt)
    static let on: [[Int]] = {
        var on = Array(repeating: [Int](), count: places)
        for j in 0..<10 { on[18 + j] = [j - 1, j].filter { 0 <= $0 && $0 <= 8 }.map { 9 + $0 } }
        for k in 0..<9 {
            let p = k / 3, q = k % 3
            on[9 + k] = ([[2 * p], [2 * p, 2 * p + 1], [2 * p + 1]][q]).map { 3 + $0 }
        }
        for m in 0..<6 { on[3 + m] = [m / 2] }
        return on
    }()

    /// Wer liegt auf u
    static let coveredBy: [[Int]] = (0..<places).map { u in (0..<places).filter { on[$0].contains(u) } }

    /// Platz belegt und nichts liegt mehr darauf
    func isFree(_ t: Int) -> Bool {
        peaks[t] != nil && Self.coveredBy[t].allSatisfy { peaks[$0] == nil }
    }

    var freePlaces: [Int] { (0..<Self.places).filter(isFree) }

    /// Eins höher oder niedriger, König und Ass ringsum
    static func fits(_ c: CardID, on top: CardID) -> Bool {
        let d = ((c.rank - top.rank) % 13 + 13) % 13
        return d == 1 || d == 12
    }
}

extension TriPeaksState: Codable {
    // Fehlende Felder beim Laden → Standardwert; „offen“ wird nicht gespeichert, sondern aus den Gipfeln berechnet
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        self.init(peaks: try c.decodeIfPresent([CardID?].self, forKey: .peaks),
                  stock: try c.decodeIfPresent([CardID].self, forKey: .stock) ?? [],
                  waste: try c.decodeIfPresent([CardID].self, forKey: .waste) ?? [],
                  chain: try c.decodeIfPresent(Int.self, forKey: .chain) ?? 0,
                  score: try c.decodeIfPresent(Int.self, forKey: .score) ?? 0,
                  moves: try c.decodeIfPresent(Int.self, forKey: .moves) ?? 0)
    }
    private enum Key: String, CodingKey { case peaks, stock, waste, chain, score, moves }
}

extension TriPeaksState: SolitaireState {
    var isWon: Bool { peaks.allSatisfy { $0 == nil } }
    var displayScore: Int? { score }
    var stockCount: Int { stock.count }
    var stockCardIDs: [CardID] { stock }
    var needsRecycle: Bool { false }
    /// Noch verdeckte Gipfelkarten (ein Rückgang bedeutet: es wurde aufgedeckt)
    var hiddenCardCount: Int { (0..<Self.places).filter { peaks[$0] != nil && !isFree($0) }.count }
    var chainLength: Int { chain }
    var completedFoundations: Int { Self.peakPlaces.filter { peaks[$0] == nil }.count }

    func face(of card: CardID) -> CardFace { CardFace(rank: card.rank, suit: card.suit) }

    func dealOrder(of card: CardID) -> Int? { peaks.firstIndex(of: card) }
    func dealColumn(of card: CardID) -> Int? { peaks.firstIndex(of: card).map { Self.index(of: $0) } }
    func stagger(of card: CardID, style: MoveStyle) -> Double { 0 }
}
