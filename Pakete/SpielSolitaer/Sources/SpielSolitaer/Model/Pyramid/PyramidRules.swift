// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Pyramid – 1:1 die Python-Referenz `Referenz/pyramid.py` (SPEZIFIKATION-PYRAMID).
/// Orte als `Pile`: Pyramidenplatz k = `.column(k)`, oberste Ablagekarte = `.waste`.
/// Züge: `.draw` (Stapel) · Paar `.move(from: a, to: b, count: 1)` · König allein `.move(from: a, to: a, count: 1)`.
enum PyramidRules: SolitaireRules {
    static let kind = GameKind.pyramid
    static let autoMoveStyle = MoveStyle.normal
    static let tapOnly = true
    static let usesSelection = true

    // MARK: Geben

    /// Karten 0 … 27 des gemischten Decks auf P0 … P27, Rest Stapel (Karte 51 oben)
    static func deal(seed: UInt64, mode: GameMode) -> PyramidState {
        let deck = Deal.shuffledDeck(seed: seed)
        return PyramidState(pyramid: Array(deck[..<PyramidState.places]).map { Optional($0) }, stock: Array(deck[PyramidState.places...]))
    }

    /// Startbild der Austeil-Animation: alle Karten auf dem Stapel
    static func preDealState(_ s: PyramidState) -> PyramidState {
        PyramidState(pyramid: nil, stock: CardID.all)
    }

    // MARK: Orte

    /// Karte an einem freien Ort (freie Pyramidenkarte bzw. oberste Ablagekarte)
    static func card(_ s: PyramidState, at pile: Pile) -> CardID? {
        switch pile {
        case .waste: s.waste.last
        case let .column(k): k >= 0 && k < PyramidState.places && s.isFree(k) ? s.pyramid[k] : nil
        default: nil
        }
    }

    /// Pyramide aufsteigend, dann Ablage
    private static func freeCards(_ s: PyramidState) -> [(pile: Pile, card: CardID)] {
        var out = s.freePlaces.map { (Pile.column($0), s.pyramid[$0]!) }
        if let top = s.waste.last { out.append((.waste, top)) }
        return out
    }

    /// Pyramide vor Ablage, kleinere Platznummer zuerst
    private static func order(_ p: Pile) -> Int {
        if case let .column(k) = p { return k }
        return PyramidState.places
    }

    static func canDraw(_ s: PyramidState) -> Bool {
        !s.stock.isEmpty || (s.passes < PyramidState.maxPasses && !s.waste.isEmpty)
    }

    // MARK: Züge

    static func movingCards(_ s: PyramidState, from: Pile, count: Int) -> [CardID]? {
        guard count == 1, let c = card(s, at: from) else { return nil }
        return [c]
    }

    static func apply(_ s: PyramidState, _ m: Move) -> PyramidState? {
        switch m {
        case .draw:
            var t = s
            if let top = t.stock.popLast() {
                t.waste.append(top)
            } else if t.passes < PyramidState.maxPasses, !t.waste.isEmpty {
                t.stock = t.waste.reversed()
                t.waste = []
                t.passes += 1
            } else {
                return nil
            }
            t.moves += 1
            return t
        case let .move(from, to, count):
            guard count == 1, let a = card(s, at: from) else { return nil }
            var places = [from]
            var sum = a.rank
            if to != from {
                guard let b = card(s, at: to) else { return nil }
                places.append(to)
                sum += b.rank
            }
            guard sum == 13 else { return nil }
            var t = s
            for p in places {
                if case let .column(k) = p { t.pyramid[k] = nil } else { t.waste.removeLast() }
            }
            t.moves += 1
            return t
        }
    }

    static func legalMoves(_ s: PyramidState) -> [Move] {
        let free = freeCards(s)
        var out: [Move] = free.filter { $0.card.rank == 13 }.map { .move(from: $0.pile, to: $0.pile, count: 1) }
        for (i, a) in free.enumerated() {
            for b in free[(i + 1)...] where a.card.rank + b.card.rank == 13 {
                out.append(.move(from: a.pile, to: b.pile, count: 1))
            }
        }
        if canDraw(s) { out.append(.draw) }
        return out
    }

    // MARK: Antippen

    /// Freie Partner (Summe 13) der freien Karte an `pile`: Pyramide aufsteigend, dann Ablage. König, leer, nicht frei → []
    static func partners(_ s: PyramidState, of pile: Pile) -> [Pile] {
        guard let c = card(s, at: pile), c.rank != 13 else { return [] }
        return freeCards(s).filter { $0.pile != pile && $0.card.rank + c.rank == 13 }.map(\.pile)
    }

    /// König: sofort weg; genau ein Partner: Paar weg; sonst nil (die Karte wird gewählt)
    static func tapTarget(_ s: PyramidState, from: Pile, count: Int) -> Move? {
        guard count == 1, let c = card(s, at: from) else { return nil }
        if c.rank == 13 { return .move(from: from, to: from, count: 1) }
        let p = partners(s, of: from)
        return p.count == 1 ? .move(from: from, to: p[0], count: 1) : nil
    }

    /// Zug aus zwei angetippten Orten (Wahl + Partner), nil wenn sie nicht zusammenpassen
    static func pairMove(_ s: PyramidState, _ a: Pile, _ b: Pile) -> Move? {
        let m = Move.move(from: a, to: b, count: 1)
        return a != b && isLegal(s, m) ? m : nil
    }

    static func autoMoves(_ s: PyramidState, autoFoundation: Bool) -> [Move] { [] }
    static func canAutoFinish(_ s: PyramidState) -> Bool { false }
    static func autoFinishMoves(_ s: PyramidState) -> [Move] { [] }

    // MARK: Tipp

    /// 1. freier König (höchste Platznummer zuerst, dann Ablage) 2. Paar aus zwei Pyramidenkarten (beide höchste Nummer zuerst)
    /// 3. Pyramide + Ablage 4. Stapel, wenn Ziehen geht. Gewonnen → nil.
    static func hint(_ s: PyramidState) -> Move? {
        if s.isWon { return nil }
        let free = Array(s.freePlaces.reversed())
        for k in free where s.pyramid[k]!.rank == 13 { return .move(from: .column(k), to: .column(k), count: 1) }
        if let top = s.waste.last, top.rank == 13 { return .move(from: .waste, to: .waste, count: 1) }
        for k in free {
            for j in free where j != k && s.pyramid[k]!.rank + s.pyramid[j]!.rank == 13 {
                let (a, b) = k < j ? (k, j) : (j, k)
                return .move(from: .column(a), to: .column(b), count: 1)
            }
        }
        if let top = s.waste.last {
            for k in free where s.pyramid[k]!.rank + top.rank == 13 { return .move(from: .column(k), to: .waste, count: 1) }
        }
        return canDraw(s) ? .draw : nil
    }

    static func isStuck(_ s: PyramidState) -> Bool { !s.isWon && hint(s) == nil }

    // MARK: Lösungen (Zugschrift: `s`, `P21`, `A`, `P21+P27`, `P25+A`)

    private static func place(_ token: Substring) -> Pile? {
        if token == "A" { return .waste }
        guard token.count >= 2, token.first == "P", let k = Int(token.dropFirst()), k >= 0, k < PyramidState.places,
              String(k) == token.dropFirst() else { return nil }
        return .column(k)
    }

    static func solutionMoves(from text: String) -> [Move]? {
        var out: [Move] = []
        for token in text.split(separator: " ") {
            if token == "s" { out.append(.draw); continue }
            let parts = token.split(separator: "+", omittingEmptySubsequences: false)
            guard parts.count <= 2, let a = place(parts[0]) else { return nil }
            if parts.count == 2 {
                guard let b = place(parts[1]) else { return nil }
                out.append(.move(from: a, to: b, count: 1))
            } else {
                out.append(.move(from: a, to: a, count: 1))
            }
        }
        return out
    }
}
