// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

struct Column: Hashable, Codable {
    var down: [CardID] = []   // verdeckt, unten → oben
    var up: [CardID] = []     // offen, unten → oben

    var top: CardID? { up.last }

    init(down: [CardID] = [], up: [CardID] = []) { self.down = down; self.up = up }

    // Fehlende Felder beim Laden → Standardwert
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        down = try c.decodeIfPresent([CardID].self, forKey: .down) ?? []
        up = try c.decodeIfPresent([CardID].self, forKey: .up) ?? []
    }
    private enum Key: String, CodingKey { case down, up }
}

struct GameState: Hashable, Codable {
    var draw = 1                    // 1 oder 3
    var stock: [CardID] = []          // unten → oben (oben = letzte)
    var waste: [CardID] = []
    var fan = 0                     // sichtbare Ablagekarten (nur Anzeige)
    var foundation = [0, 0, 0, 0]   // höchster Wert je Farbe, 0 = leer
    var cols = Array(repeating: Column(), count: 7)
    var score = 0
    var moves = 0
    var passes = 0
    /// Punkte-Art dieser Partie: 0 Standard · 1 Vegas · 2 Vegas fortlaufend · 3 Aus
    var scoring = 0
    /// Vegas: Stand der Partie in Vegas-Punkten (Start −52)
    var dollars = GameState.vegasStart

    static let vegasStart = -52
    static let vegasCard = 5
    /// Vegas: Durchgänge Ziehen 1 → 1, Ziehen 3 → 3
    static func vegasPassLimit(draw: Int) -> Int { draw == 1 ? 1 : 3 }
    var isVegas: Bool { scoring == 1 || scoring == 2 }

    init(draw: Int = 1, stock: [CardID] = [], waste: [CardID] = [], fan: Int = 0, foundation: [Int] = [0, 0, 0, 0],
         cols: [Column] = Array(repeating: Column(), count: 7), score: Int = 0, moves: Int = 0, passes: Int = 0,
         scoring: Int = 0, dollars: Int = GameState.vegasStart) {
        self.scoring = scoring; self.dollars = dollars
        self.draw = draw; self.stock = stock; self.waste = waste; self.fan = fan; self.foundation = foundation
        self.cols = cols; self.score = score; self.moves = moves; self.passes = passes
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        draw = try c.decodeIfPresent(Int.self, forKey: .draw) ?? 1
        stock = try c.decodeIfPresent([CardID].self, forKey: .stock) ?? []
        waste = try c.decodeIfPresent([CardID].self, forKey: .waste) ?? []
        fan = try c.decodeIfPresent(Int.self, forKey: .fan) ?? min(1, waste.count)
        foundation = CardID.sanitizedFoundation(try c.decodeIfPresent([Int].self, forKey: .foundation) ?? [])
        cols = try c.decodeIfPresent([Column].self, forKey: .cols) ?? []
        cols = Array(cols.prefix(7))
        while cols.count < 7 { cols.append(Column()) }
        score = try c.decodeIfPresent(Int.self, forKey: .score) ?? 0
        moves = try c.decodeIfPresent(Int.self, forKey: .moves) ?? 0
        passes = try c.decodeIfPresent(Int.self, forKey: .passes) ?? 0
        scoring = try c.decodeIfPresent(Int.self, forKey: .scoring) ?? 0
        dollars = try c.decodeIfPresent(Int.self, forKey: .dollars) ?? GameState.vegasStart
    }
    private enum Key: String, CodingKey { case draw, stock, waste, fan, foundation, cols, score, moves, passes, scoring, dollars }

    var isWon: Bool { foundation.allSatisfy { $0 == 13 } }
}

extension GameState: SolitaireState {
    /// Standard: Punkte · Streng: Punkte (auch negativ) · Aus: nichts
    var displayScore: Int? { scoring == 3 ? nil : isVegas ? dollars : score }
    var scoreText: String? {
        guard let v = displayScore else { return nil }
        return v < 0 ? "−\(-v)" : "\(v)"
    }
    var scoreNegative: Bool { isVegas && dollars < 0 }
    /// Rekorde („Höchste Punkte“) nur im Standard
    var recordScore: Int? { scoring == 0 ? score : nil }
    /// Vegas fortlaufend: Vegas-Stand dieser Partie, der beim Ende zum Gesamtstand zählt
    var accountDollars: Int? { scoring == 2 ? dollars : nil }
    var stockCount: Int { stock.count }
    var stockCardIDs: [CardID] { stock }
    var needsRecycle: Bool { stock.isEmpty && !waste.isEmpty }
    var hiddenCardCount: Int { cols.reduce(0) { $0 + $1.down.count } }
    var revealedColumns: Int { cols.filter { $0.down.isEmpty && !$0.up.isEmpty }.count }
    var completedFoundations: Int { foundation.filter { $0 == 13 }.count }

    func face(of card: CardID) -> CardFace { CardFace(rank: card.rank, suit: card.suit) }

    /// Reihenfolge beim Austeilen: Zeile für Zeile
    func dealOrder(of card: CardID) -> Int? {
        var n = 0
        for r in 0..<7 {
            for c in r..<7 {
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

    /// Stapel ziehen: die `fan` obersten Ablagekarten landen nacheinander (je 0,04 s)
    func stagger(of card: CardID, style: MoveStyle) -> Double {
        guard style == .draw, let i = waste.firstIndex(of: card) else { return 0 }
        let fromTop = waste.count - 1 - i
        return fromTop < fan ? Double(fan - 1 - fromTop) * 0.04 : 0
    }
}
