// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Spider (1, 2 oder 4 Farben) – 1:1 die Python-Referenz `Referenz/spider.py`.
enum SpiderRules: SolitaireRules {
    static let kind = GameKind.spider
    static let autoMoveStyle = MoveStyle.complete

    static let scoreMove = -1
    static let scoreRun = 100

    // MARK: Geben

    /// Fisher-Yates von hinten über 104 Karten: für i = 103…1 tausche i mit below(i + 1).
    static func shuffledDeck(seed: UInt64) -> [CardID] {
        var deck = (0..<104).map(CardID.init)
        var rng = SplitMix64(seed: seed)
        for i in stride(from: 103, to: 0, by: -1) { deck.swapAt(i, rng.below(i + 1)) }
        return deck
    }

    /// Zeile für Zeile; S0–S3 bekommen 6, S4–S9 bekommen 5 Karten, die letzte jeder Spalte liegt offen. Rest (50) = Stapel, Platz 103 oben.
    static func deal(seed: UInt64, mode: GameMode) -> SpiderState {
        let deck = shuffledDeck(seed: seed)
        var cols = Array(repeating: Column(), count: 10)
        var pos = 0
        for r in 0..<6 {
            for c in 0..<10 {
                let height = c < 4 ? 6 : 5
                if r < height {
                    if r == height - 1 { cols[c].up.append(deck[pos]) } else { cols[c].down.append(deck[pos]) }
                    pos += 1
                }
            }
        }
        return SpiderState(suits: mode.option, stock: Array(deck[pos...]), cols: cols)
    }

    static func preDealState(_ s: SpiderState) -> SpiderState {
        SpiderState(suits: s.suits, stock: (0..<104).map(CardID.init))
    }

    // MARK: Reihen

    /// Länge der obersten Reihe gleicher Farbe, absteigend (die man als Ganzes bewegen darf)
    static func runLength(_ s: SpiderState, _ col: Column) -> Int {
        let up = col.up
        guard !up.isEmpty else { return 0 }
        var n = 1
        while n < up.count {
            let a = up[up.count - n - 1], b = up[up.count - n]
            if s.rank(b) == s.rank(a) - 1, s.suit(a) == s.suit(b) { n += 1 } else { break }
        }
        return n
    }

    /// Liegen oben 13 offene Karten König → Ass derselben Farbe?
    static func isCompleteRun(_ s: SpiderState, _ col: Column) -> Bool {
        guard col.up.count >= 13 else { return false }
        let top13 = Array(col.up.suffix(13))
        return s.rank(top13[0]) == 13 && runLength(s, Column(down: [], up: top13)) == 13
    }

    private static func isEmpty(_ col: Column) -> Bool { col.up.isEmpty && col.down.isEmpty }

    private static func flip(_ col: inout Column) {
        if col.up.isEmpty, let c = col.down.popLast() { col.up.append(c) }
    }

    // MARK: Züge

    static func movingCards(_ s: SpiderState, from: Pile, count n: Int) -> [CardID]? {
        guard case let .column(i) = from, (0..<10).contains(i), n >= 1, n <= runLength(s, s.cols[i]) else { return nil }
        return Array(s.cols[i].up.suffix(n))
    }

    static func apply(_ s: SpiderState, _ m: Move) -> SpiderState? {
        var t = s
        switch m {
        case .draw:
            guard t.stock.count >= t.cols.count, !t.cols.contains(where: isEmpty) else { return nil }
            for i in t.cols.indices { t.cols[i].up.append(t.stock.removeLast()) }
            t.deals += 1
            t.moves += 1
            t.score = max(0, t.score + scoreMove)
            return t

        case let .move(src, dst, n):
            guard case let .column(si) = src, (0..<10).contains(si) else { return nil }
            if case .foundation = dst {
                // Fertige Reihe abräumen (kein Spielerzug)
                guard n == 13, isCompleteRun(t, t.cols[si]) else { return nil }
                let removed = Array(t.cols[si].up.suffix(13))
                let suit = t.suit(removed.last!)
                t.cols[si].up.removeLast(13)
                flip(&t.cols[si])
                t.done.append(DoneRun(suit: suit, cards: removed))
                t.score += scoreRun
                return t
            }
            guard case let .column(di) = dst, (0..<10).contains(di), si != di, n >= 1, n <= runLength(t, t.cols[si]) else { return nil }
            let base = t.cols[si].up[t.cols[si].up.count - n]
            if let top = t.cols[di].up.last, t.rank(top) != t.rank(base) + 1 { return nil }
            let moving = Array(t.cols[si].up.suffix(n))
            t.cols[si].up.removeLast(n)
            flip(&t.cols[si])
            t.cols[di].up.append(contentsOf: moving)
            t.moves += 1
            t.score = max(0, t.score + scoreMove)
            return t
        }
    }

    /// Nach jedem Zug: fertige Reihen wandern ab, Spalten von links, wiederholt bis nichts mehr geht (immer, unabhängig von Einstellungen).
    static func autoMoves(_ start: SpiderState, autoFoundation: Bool) -> [Move] {
        var s = start
        var out: [Move] = []
        var changed = true
        while changed {
            changed = false
            for i in s.cols.indices where isCompleteRun(s, s.cols[i]) {
                let m = Move.move(from: .column(i), to: .foundation(s.done.count), count: 13)
                s = apply(s, m)!
                out.append(m)
                changed = true
                break
            }
        }
        return out
    }

    static func canAutoFinish(_ s: SpiderState) -> Bool { false }
    static func autoFinishMoves(_ s: SpiderState) -> [Move] { [] }

    // MARK: Antippen

    /// 1. Spalte, deren oberste Karte eins höher ist und dieselbe Farbe hat · 2. eins höher, beliebige Farbe ·
    /// 3. leere Spalte (nicht, wenn die Reihe schon die ganze Spalte ist). Suche ab der Spalte rechts neben der Quelle, ringsum.
    static func tapTarget(_ s: SpiderState, from: Pile, count n: Int) -> Move? {
        guard case let .column(i) = from else { return nil }
        let col = s.cols[i]
        guard n >= 1, n <= runLength(s, col) else { return nil }
        let base = col.up[col.up.count - n]
        let order = (1..<10).map { (i + $0) % 10 }
        for same in [true, false] {
            for j in order {
                if let top = s.cols[j].up.last, s.rank(top) == s.rank(base) + 1, !same || s.suit(top) == s.suit(base) {
                    return .move(from: from, to: .column(j), count: n)
                }
            }
        }
        if !(n == col.up.count && col.down.isEmpty) {
            for j in order where isEmpty(s.cols[j]) { return .move(from: from, to: .column(j), count: n) }
        }
        return nil
    }

    // MARK: Tipp

    /// Alle beweglichen Reihen: (Spalte, Anzahl), Spalten links → rechts, lange Reihen zuerst
    private static func runs(_ s: SpiderState) -> [(i: Int, n: Int)] {
        var out: [(Int, Int)] = []
        for i in s.cols.indices {
            let len = runLength(s, s.cols[i])
            if len >= 1 { for n in stride(from: len, through: 1, by: -1) { out.append((i, n)) } }
        }
        return out
    }

    static func hint(_ s: SpiderState) -> Move? {
        func fits(_ j: Int, _ base: CardID, same: Bool) -> Bool {
            guard let top = s.cols[j].up.last else { return false }
            return s.rank(top) == s.rank(base) + 1 && (!same || s.suit(top) == s.suit(base))
        }
        func mv(_ i: Int, _ j: Int, _ n: Int) -> Move { .move(from: .column(i), to: .column(j), count: n) }

        // 1. Reihe auf passende Karte, die eine verdeckte Karte freilegt (gleiche Farbe zuerst)
        for (i, n) in runs(s) {
            let col = s.cols[i]
            if n == col.up.count, !col.down.isEmpty {
                let base = col.up[col.up.count - n]
                for same in [true, false] {
                    for j in 0..<10 where j != i && fits(j, base, same: same) { return mv(i, j, n) }
                }
            }
        }
        // 2. und 3.
        for rule in [2, 3] {
            for (i, n) in runs(s) {
                let col = s.cols[i]
                let base = col.up[col.up.count - n]
                let under: CardID? = n < col.up.count ? col.up[col.up.count - n - 1] : nil
                let sits = under.map { s.rank($0) == s.rank(base) + 1 } ?? false
                let sitsSame = sits && under.map { s.suit($0) == s.suit(base) } == true
                // Mit Stapel nie eine Spalte leer räumen: Regel 6 füllt sie gleich wieder, der Tipp würde endlos pendeln
                let leavesEmpty = under == nil && col.down.isEmpty
                let empties = leavesEmpty && s.stock.isEmpty
                for j in 0..<10 where j != i {
                    if rule == 2, fits(j, base, same: true), !sitsSame, !(leavesEmpty && !s.stock.isEmpty) { return mv(i, j, n) }
                    if rule == 3, fits(j, base, same: false), (!sits && under != nil) || empties { return mv(i, j, n) }
                }
            }
        }
        // 4. Reihe in eine leere Spalte, wenn darunter eine verdeckte Karte frei wird
        let empty = (0..<10).filter { isEmpty(s.cols[$0]) }
        if let target = empty.first {
            for (i, n) in runs(s) where n == s.cols[i].up.count && !s.cols[i].down.isEmpty { return mv(i, target, n) }
        }
        // 5. und 6.
        if !s.stock.isEmpty {
            guard let target = empty.first else { return .draw }
            let tallest = (0..<10).max { a, b in
                let ca = s.cols[a].down.count + s.cols[a].up.count, cb = s.cols[b].down.count + s.cols[b].up.count
                return ca != cb ? ca < cb : a > b      // höchste Spalte, bei Gleichstand die linke
            }!
            if s.cols[tallest].down.count + s.cols[tallest].up.count >= 2 { return mv(tallest, target, 1) }
        }
        return nil
    }

    static func isStuck(_ s: SpiderState) -> Bool { !s.isWon && hint(s) == nil }
}
