// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Spielregeln Yukon – 1:1 die Python-Referenz `Referenz/yukon.py` (SPEZIFIKATION-YUKON.md). Reine Funktionen, keine Oberfläche.
enum YukonRules: SolitaireRules {
    static let kind = GameKind.yukon
    static let autoMoveStyle = MoveStyle.normal

    static let scoreToFoundation = 10
    static let scoreFlip = 5
    static let scoreFoundationToColumn = -15
    private static let columns = YukonState.columnCount

    // MARK: Geben

    /// Mischen wie Klondike. Teil 1 (Deck 0…27) wie Klondike, Teil 2 (Deck 28…51): vier Zeilen, je Zeile Spalte 1…6 eine offene Karte.
    static func deal(seed: UInt64, mode: GameMode) -> YukonState {
        let deck = Deal.shuffledDeck(seed: seed)
        var cols = Array(repeating: Column(), count: columns)
        var pos = 0
        for r in 0..<columns {
            for c in r..<columns {
                if c == r { cols[c].up.append(deck[pos]) } else { cols[c].down.append(deck[pos]) }
                pos += 1
            }
        }
        for _ in 0..<4 {
            for c in 1..<columns {
                cols[c].up.append(deck[pos])
                pos += 1
            }
        }
        return YukonState(cols: cols)
    }

    /// Startbild der Austeil-Animation: alle Karten verdeckt in Spalte 0 (das Layout legt sie als Stapel oben in die Mitte)
    static func preDealState(_ s: YukonState) -> YukonState {
        var t = YukonState()
        t.cols[0] = Column(down: CardID.all, up: [])
        return t
    }

    // MARK: Karten bewegen

    /// Die `n` Karten, die von `src` wandern würden (unten → oben). Aus einer Spalte: die n obersten offenen Karten, egal in welcher Reihenfolge.
    static func movingCards(_ s: YukonState, from src: Pile, count n: Int) -> [CardID]? {
        guard n >= 1 else { return nil }
        switch src {
        case let .foundation(f):
            guard n == 1, f >= 0, f < 4, s.foundation[f] > 0 else { return nil }
            return [CardID(rank: s.foundation[f], suit: Suit(rawValue: f)!)]
        case let .column(i):
            guard i >= 0, i < columns, n <= s.cols[i].up.count else { return nil }
            return Array(s.cols[i].up.suffix(n))
        case .stock, .waste, .cell:
            return nil
        }
    }

    static func canPlace(_ s: YukonState, _ cards: [CardID], on dst: Pile) -> Bool {
        guard let base = cards.first else { return false }
        switch dst {
        case let .foundation(f):
            return f >= 0 && f < 4 && cards.count == 1 && base.suit.rawValue == f && base.rank == s.foundation[f] + 1
        case let .column(i):
            guard i >= 0, i < columns else { return false }
            let col = s.cols[i]
            guard let top = col.top else { return base.rank == 13 && col.down.isEmpty }
            return base.fits(on: top)
        case .stock, .waste, .cell:
            return false
        }
    }

    /// Führt einen Zug aus; nil, wenn er nicht erlaubt ist (der alte Zustand bleibt unverändert).
    static func apply(_ s: YukonState, _ move: Move) -> YukonState? {
        guard case let .move(src, dst, n) = move, src != dst,
              let cards = movingCards(s, from: src, count: n), canPlace(s, cards, on: dst) else { return nil }
        var t = s
        var delta = 0
        switch src {
        case let .foundation(f):
            t.foundation[f] -= 1
            delta += scoreFoundationToColumn
        case let .column(i):
            t.cols[i].up.removeLast(n)
            if t.cols[i].up.isEmpty, let c = t.cols[i].down.popLast() {
                t.cols[i].up.append(c)
                delta += scoreFlip
            }
        default:
            return nil
        }
        switch dst {
        case let .foundation(f):
            t.foundation[f] += 1
            if case .foundation = src {} else { delta += scoreToFoundation }
        case let .column(i):
            t.cols[i].up.append(contentsOf: cards)
        default:
            return nil
        }
        t.score = max(0, t.score + delta)
        t.moves += 1
        return t
    }

    static func isLegal(_ s: YukonState, _ m: Move) -> Bool { apply(s, m) != nil }

    // MARK: Antippen

    /// Antippen = bester Zug. `count` = Karten ab der angetippten bis oben. nil → Karte wackelt.
    static func tapTarget(_ s: YukonState, from src: Pile, count n: Int) -> Move? {
        guard let cards = movingCards(s, from: src, count: n) else { return nil }
        var fromFoundation = false
        if case .foundation = src { fromFoundation = true }
        if n == 1, !fromFoundation {
            let f = cards[0].suit.rawValue
            if canPlace(s, cards, on: .foundation(f)) { return .move(from: src, to: .foundation(f), count: 1) }
        }
        var start = 0
        var srcColumn: Int?
        if case let .column(i) = src { start = i + 1; srcColumn = i }
        let order = (0..<columns).map { (start + $0) % columns }.filter { $0 != srcColumn }
        for i in order where !s.cols[i].up.isEmpty && canPlace(s, cards, on: .column(i)) {
            return .move(from: src, to: .column(i), count: n)
        }
        if cards[0].rank == 13 {
            if let i = srcColumn, s.cols[i].down.isEmpty, s.cols[i].up.count == n { return nil }
            for i in order where s.cols[i].up.isEmpty && s.cols[i].down.isEmpty {
                return .move(from: src, to: .column(i), count: n)
            }
        }
        return nil
    }

    /// Doppeltipp: die Karte aufs Ziel ihrer Farbe, wenn sie dort hin darf (nur einzelne Karten, nicht vom Ziel)
    static func foundationMove(_ s: YukonState, from src: Pile, count n: Int) -> Move? {
        guard n == 1, let cards = movingCards(s, from: src, count: 1) else { return nil }
        if case .foundation = src { return nil }
        let f = cards[0].suit.rawValue
        return canPlace(s, cards, on: .foundation(f)) ? .move(from: src, to: .foundation(f), count: 1) : nil
    }

    // MARK: Automatisch ablegen

    /// Sicher = keine Karte der Gegenfarbe braucht sie noch als Unterlage (wie Klondike).
    static func isSafeForFoundation(_ s: YukonState, _ c: CardID) -> Bool {
        guard c.rank == s.foundation[c.suit.rawValue] + 1 else { return false }
        if c.rank <= 2 { return true }
        let opposite = c.isRed ? [0, 3] : [1, 2]
        return opposite.allSatisfy { s.foundation[$0] >= c.rank - 1 }
    }

    static func autoMoves(_ s: YukonState, autoFoundation: Bool) -> [Move] {
        autoFoundation ? autoFoundationMoves(s) : []
    }

    static func autoFoundationMoves(_ start: YukonState) -> [Move] {
        var s = start
        var out: [Move] = []
        outer: while true {
            for i in 0..<columns {
                if let c = s.cols[i].top, isSafeForFoundation(s, c) {
                    let m = Move.move(from: .column(i), to: .foundation(c.suit.rawValue), count: 1)
                    s = apply(s, m)!
                    out.append(m)
                    continue outer
                }
            }
            return out
        }
    }

    // MARK: Fertig spielen

    /// Je Schritt die oberste Karte mit dem kleinsten Wert, die aufs Ziel passt; bei Gleichstand die linke Spalte. nil = reicht nicht bis zum Sieg.
    private static func finishMoves(_ start: YukonState) -> [Move]? {
        var s = start
        var out: [Move] = []
        while !s.isWon {
            var best: (Int, CardID)?
            for (i, col) in s.cols.enumerated() {
                if let c = col.top, c.rank == s.foundation[c.suit.rawValue] + 1, best == nil || c.rank < best!.1.rank { best = (i, c) }
            }
            guard let (i, c) = best else { return nil }
            let m = Move.move(from: .column(i), to: .foundation(c.suit.rawValue), count: 1)
            s = apply(s, m)!
            out.append(m)
        }
        return out
    }

    static func canAutoFinish(_ s: YukonState) -> Bool {
        !s.isWon && s.cols.allSatisfy { $0.down.isEmpty } && finishMoves(s) != nil
    }

    static func autoFinishMoves(_ s: YukonState) -> [Move] { finishMoves(s) ?? [] }

    // MARK: Tipp

    /// Erst Spalten mit passender offener Karte (links → rechts), dann leere Spalten (nur König).
    private static func firstColumnTarget(_ s: YukonState, _ cards: [CardID], exclude: Int) -> Int? {
        for j in 0..<columns where j != exclude && !s.cols[j].up.isEmpty && canPlace(s, cards, on: .column(j)) { return j }
        for j in 0..<columns where j != exclude && s.cols[j].up.isEmpty && canPlace(s, cards, on: .column(j)) { return j }
        return nil
    }

    private static func toFoundation(_ i: Int, _ c: CardID) -> Move {
        .move(from: .column(i), to: .foundation(c.suit.rawValue), count: 1)
    }

    static func hint(_ s: YukonState) -> Move? {
        if s.isWon { return nil }
        // 1. Aufdecken: alle offenen Karten einer Spalte mit verdeckten Karten weg, kürzeste Gruppe zuerst
        let order = (0..<columns).filter { !s.cols[$0].down.isEmpty && !s.cols[$0].up.isEmpty }
            .sorted { (s.cols[$0].up.count, $0) < (s.cols[$1].up.count, $1) }
        for i in order {
            let cards = s.cols[i].up
            if cards.count == 1, canPlace(s, cards, on: .foundation(cards[0].suit.rawValue)) { return toFoundation(i, cards[0]) }
            if let j = firstColumnTarget(s, cards, exclude: i) { return .move(from: .column(i), to: .column(j), count: cards.count) }
        }
        // 2. sichere Karte aufs Ziel
        for i in 0..<columns { if let c = s.cols[i].top, isSafeForFoundation(s, c) { return toFoundation(i, c) } }
        // 3. König mit Karten darunter in eine leere Spalte
        if let empty = (0..<columns).first(where: { s.cols[$0].up.isEmpty && s.cols[$0].down.isEmpty }) {
            for i in 0..<columns where !s.cols[i].down.isEmpty {
                let up = s.cols[i].up
                if up.count > 1, let k = (1..<up.count).first(where: { up[$0].rank == 13 }) {
                    return .move(from: .column(i), to: .column(empty), count: up.count - k)
                }
            }
        }
        // 4. irgendeine oberste Karte, die aufs Ziel passt
        for i in 0..<columns {
            if let c = s.cols[i].top, c.rank == s.foundation[c.suit.rawValue] + 1 { return toFoundation(i, c) }
        }
        // 5. Gruppe, die auf einer nicht passenden Karte liegt, auf eine passende Karte
        for i in 0..<columns {
            let up = s.cols[i].up
            guard up.count > 1 else { continue }
            for k in 1..<up.count where !up[k].fits(on: up[k - 1]) {
                for j in 0..<columns where j != i && !s.cols[j].up.isEmpty && canPlace(s, Array(up[k...]), on: .column(j)) {
                    return .move(from: .column(i), to: .column(j), count: up.count - k)
                }
            }
        }
        // 6. Keine leere Spalte, aber ein König in einer Spalte mit verdeckten Karten: eine ganze offene Spalte wegräumen
        let hasEmpty = (0..<columns).contains { s.cols[$0].up.isEmpty && s.cols[$0].down.isEmpty }
        let kingBuried = s.cols.contains { !$0.down.isEmpty && $0.up.contains { $0.rank == 13 } }
        if !hasEmpty, kingBuried {
            for i in 0..<columns where s.cols[i].down.isEmpty && !s.cols[i].up.isEmpty {
                for j in 0..<columns where j != i && !s.cols[j].up.isEmpty && canPlace(s, s.cols[i].up, on: .column(j)) {
                    return .move(from: .column(i), to: .column(j), count: s.cols[i].up.count)
                }
            }
        }
        return nil
    }

    // MARK: Festgefahren

    /// Sinnvoll = Spalte → Ziel, oder Spalte → Spalte, die aufdeckt / eine Spalte leert (Ziel nicht leer) / eine Karte von einer
    /// nicht passenden Unterlage holt / eine Karte freilegt, die aufs Ziel kann. Pendelnde Züge zählen nicht.
    private static func isUseful(_ s: YukonState, from i: Int, count n: Int, to j: Int) -> Bool {
        let col = s.cols[i]
        let k = col.up.count - n
        if k == 0 {
            if !col.down.isEmpty { return true }
            return !s.cols[j].up.isEmpty
        }
        let under = col.up[k - 1], base = col.up[k]
        if !base.fits(on: under) { return true }
        return under.rank == s.foundation[under.suit.rawValue] + 1
    }

    static func isStuck(_ s: YukonState) -> Bool {
        if s.isWon { return false }
        for i in 0..<columns {
            if let c = s.cols[i].top, c.rank == s.foundation[c.suit.rawValue] + 1 { return false }
        }
        for i in 0..<columns {
            let up = s.cols[i].up
            for k in 0..<up.count {
                let cards = Array(up[k...])
                for j in 0..<columns where j != i && canPlace(s, cards, on: .column(j)) {
                    if isUseful(s, from: i, count: cards.count, to: j) { return false }
                }
            }
        }
        return true
    }
}
