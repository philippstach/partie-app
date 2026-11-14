// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Golf – 1:1 die Python-Referenz `Referenz/golf.py` (SPEZIFIKATION-GOLF).
/// Orte als `Pile`: Spalte k = `.column(k)`. Züge: `.draw` (Stapel) · oberste Spaltenkarte auf die Ablage `.move(from: .column(k), to: .waste, count: 1)`.
enum GolfRules: SolitaireRules {
    static let kind = GameKind.golf
    static let autoMoveStyle = MoveStyle.normal
    static let tapOnly = true

    // MARK: Geben

    /// Karten 0 … 34 in die Spalten (Spalte j: j·5 … j·5+4, letzte oben), 35 auf die Ablage, 36 … 51 Stapel (51 oben)
    static func deal(seed: UInt64, mode: GameMode) -> GolfState {
        let deck = Deal.shuffledDeck(seed: seed)
        let h = GolfState.columnHeight, n = GolfState.columnCount * h
        let cols = (0..<GolfState.columnCount).map { Array(deck[$0 * h..<($0 + 1) * h]) }
        return GolfState(cols: cols, stock: Array(deck[(n + 1)...]), waste: [deck[n]])
    }

    static func preDealState(_ s: GolfState) -> GolfState { GolfState(stock: CardID.all) }

    // MARK: Züge

    /// Spalten, deren oberste Karte auf die Ablage passt, aufsteigend
    static func playable(_ s: GolfState) -> [Int] {
        guard let top = s.waste.last else { return [] }
        return (0..<GolfState.columnCount).filter { k in s.cols[k].last.map { GolfState.fits($0, on: top) } ?? false }
    }

    static func movingCards(_ s: GolfState, from: Pile, count: Int) -> [CardID]? {
        guard count == 1, case let .column(k) = from, k >= 0, k < GolfState.columnCount, let c = s.cols[k].last else { return nil }
        return [c]
    }

    static func apply(_ s: GolfState, _ m: Move) -> GolfState? {
        var t = s
        switch m {
        case .draw:
            guard let top = t.stock.popLast() else { return nil }
            t.waste.append(top)
            t.chain = 0
        case let .move(from, to, count):
            guard count == 1, to == .waste, case let .column(k) = from, k >= 0, k < GolfState.columnCount,
                  let c = s.cols[k].last, let top = s.waste.last, GolfState.fits(c, on: top) else { return nil }
            t.cols[k].removeLast()
            t.waste.append(c)
            t.chain += 1
            if t.isWon { t.score = t.stock.count }
        }
        t.moves += 1
        return t
    }

    static func legalMoves(_ s: GolfState) -> [Move] {
        var out: [Move] = playable(s).map { .move(from: .column($0), to: .waste, count: 1) }
        if !s.stock.isEmpty { out.append(.draw) }
        return out
    }

    static func tapTarget(_ s: GolfState, from: Pile, count: Int) -> Move? {
        guard movingCards(s, from: from, count: count) != nil else { return nil }
        let m = Move.move(from: from, to: .waste, count: 1)
        return isLegal(s, m) ? m : nil
    }

    static func autoMoves(_ s: GolfState, autoFoundation: Bool) -> [Move] { [] }
    static func canAutoFinish(_ s: GolfState) -> Bool { false }
    static func autoFinishMoves(_ s: GolfState) -> [Move] { [] }

    /// Ab Kette 5 je Glied einen Halbton höher, höchstens +7 (wie TriPeaks)
    static func soundPitch(_ after: GolfState) -> Int { after.chain >= 5 ? min(7, after.chain - 4) : 0 }

    /// Spalte, die dieser Zug leer geräumt hat
    static func clearedPile(_ before: GolfState, _ after: GolfState, _ m: Move) -> Pile? {
        guard case let .move(from, _, _) = m, case let .column(k) = from, k >= 0, k < GolfState.columnCount,
              !before.cols[k].isEmpty, after.cols[k].isEmpty else { return nil }
        return from
    }

    // MARK: Tipp

    /// 1. passende Spaltenkarte, nach der direkt eine weitere passt (niedrigste Spalte zuerst) 2. sonst passende, niedrigste Spalte 3. Stapel
    static func hint(_ s: GolfState) -> Move? {
        if s.isWon { return nil }
        let cand = playable(s)
        func card(_ k: Int) -> Move { .move(from: .column(k), to: .waste, count: 1) }
        for k in cand {
            if let next = apply(s, card(k)), !playable(next).isEmpty { return card(k) }
        }
        if let k = cand.first { return card(k) }
        return s.stock.isEmpty ? nil : .draw
    }

    static func isStuck(_ s: GolfState) -> Bool { !s.isWon && hint(s) == nil }

    // MARK: Lösungen (Zugschrift: `s`, `G3`)

    static func solutionMoves(from text: String) -> [Move]? {
        var out: [Move] = []
        for token in text.split(separator: " ") {
            if token == "s" { out.append(.draw); continue }
            guard token.count == 2, token.first == "G", let k = Int(token.dropFirst()), k >= 0, k < GolfState.columnCount else { return nil }
            out.append(.move(from: .column(k), to: .waste, count: 1))
        }
        return out
    }
}
