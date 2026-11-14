// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Spielregeln – 1:1 die Python-Referenz `Referenz/solitaer.py`. Reine Funktionen, keine Oberfläche.
enum KlondikeRules: SolitaireRules {
    static let kind = GameKind.klondike
    static let autoMoveStyle = MoveStyle.normal

    static let scoreWasteToColumn = 5
    static let scoreToFoundation = 10
    static let scoreFlip = 5
    static let scoreFoundationToColumn = -15
    static func scoreRecycle(draw: Int) -> Int { draw == 3 ? -20 : -100 }

    // MARK: Punkte-Arten (Standard, Vegas, Vegas fortlaufend, Aus; Zeitbonus)

    /// Setzt die Punkte-Art der neuen Partie (Tagesspiel immer Standard)
    static func prepare(_ s: GameState, prefs: some SolitaireRegelOptionen, kind: DealKind) -> GameState {
        var t = s
        t.scoring = kind == .daily ? 0 : prefs.klondikeScoring
        t.dollars = GameState.vegasStart
        return t
    }

    /// Vegas: Stapel leer und kein Umdrehen mehr erlaubt → Hinweis „Keine Durchgänge mehr“
    /// Vegas: Stapel leer und kein Umdrehen mehr erlaubt (wie `stapel_gesperrt` der Referenz)
    static func stockLocked(_ s: GameState) -> Bool {
        s.isVegas && s.stock.isEmpty && s.passes + 1 >= GameState.vegasPassLimit(draw: s.draw)
    }

    static func drawBlockedMessage(_ s: GameState) -> String? {
        guard stockLocked(s), !s.waste.isEmpty else { return nil }
        return String(localized: "Keine Durchgänge mehr")
    }

    static let timeBonusMinSeconds = 30
    /// Standard-Punkte: beim Sieg 700.000 ÷ Sekunden, wenn die Zeit mindestens 30 s beträgt
    static func timeBonus(seconds: Int) -> Int { seconds >= timeBonusMinSeconds ? 700_000 / seconds : 0 }
    static func timeBonus(_ s: GameState, seconds: Int) -> Int { s.scoring == 0 ? timeBonus(seconds: seconds) : 0 }

    // MARK: Schnittstelle (SolitaireRules)

    static func deal(seed: UInt64, mode: GameMode) -> GameState { Deal.deal(seed: seed, draw: mode.option) }

    static func preDealState(_ s: GameState) -> GameState {
        var t = GameState(draw: s.draw)
        t.stock = CardID.all
        return t
    }

    static func autoMoves(_ s: GameState, autoFoundation: Bool) -> [Move] {
        autoFoundation ? autoFoundationMoves(s) : []
    }

    // MARK: Karten bewegen

    /// Die `n` Karten, die von `src` wandern würden (unten → oben), oder nil.
    static func movingCards(_ s: GameState, from src: Pile, count n: Int) -> [CardID]? {
        guard n >= 1 else { return nil }
        switch src {
        case .waste:
            guard n == 1, let c = s.waste.last else { return nil }
            return [c]
        case let .foundation(f):
            guard (0..<4).contains(f), n == 1, s.foundation[f] > 0 else { return nil }
            return [CardID(rank: s.foundation[f], suit: Suit(rawValue: f)!)]
        case let .column(i):
            guard s.cols.indices.contains(i) else { return nil }
            let up = s.cols[i].up
            guard n <= up.count else { return nil }
            let run = Array(up.suffix(n))
            for (a, b) in zip(run, run.dropFirst()) where !b.fits(on: a) { return nil }
            return run
        case .stock, .cell:
            return nil   // Klondike hat weder bewegbare Stapelkarten noch Zellen
        }
    }

    static func canPlace(_ s: GameState, _ cards: [CardID], on dst: Pile) -> Bool {
        guard let base = cards.first else { return false }
        switch dst {
        case let .foundation(f):
            return (0..<4).contains(f) && cards.count == 1 && base.suit.rawValue == f && base.rank == s.foundation[f] + 1
        case let .column(i):
            guard s.cols.indices.contains(i) else { return false }
            let col = s.cols[i]
            guard let top = col.top else { return base.rank == 13 && col.down.isEmpty }
            return base.fits(on: top)
        case .waste, .stock, .cell:
            return false
        }
    }

    /// Führt einen Zug aus; nil, wenn er nicht erlaubt ist (der alte Zustand bleibt unverändert).
    static func apply(_ s: GameState, _ move: Move) -> GameState? {
        var t = s
        switch move {
        case .draw:
            if !t.stock.isEmpty {
                let k = min(t.draw, t.stock.count)
                for _ in 0..<k { t.waste.append(t.stock.removeLast()) }
                t.fan = t.draw == 3 ? k : 1
            } else if !t.waste.isEmpty {
                // Vegas: Umdrehen nur, solange Durchgänge übrig sind
                if t.isVegas, t.passes + 1 >= GameState.vegasPassLimit(draw: t.draw) { return nil }
                t.stock = t.waste.reversed()
                t.waste = []
                t.fan = 0
                t.passes += 1
                t.score = max(0, t.score + scoreRecycle(draw: t.draw))
            } else {
                return nil
            }
            t.moves += 1
            return t

        case let .move(src, dst, n):
            guard src != dst, let cards = movingCards(t, from: src, count: n), canPlace(t, cards, on: dst) else { return nil }
            var delta = 0
            switch src {
            case .waste:
                t.waste.removeLast()
                t.fan = t.waste.isEmpty ? 0 : min(max(t.fan - 1, 1), t.waste.count)
            case let .foundation(f):
                t.foundation[f] -= 1
                delta += scoreFoundationToColumn
                if t.isVegas { t.dollars -= GameState.vegasCard }
            case let .column(i):
                t.cols[i].up.removeLast(n)
                if t.cols[i].up.isEmpty, let c = t.cols[i].down.popLast() {
                    t.cols[i].up.append(c)
                    delta += scoreFlip
                }
            case .stock, .cell:
                return nil
            }
            switch dst {
            case let .foundation(f):
                t.foundation[f] += 1
                if case .foundation = src {} else {
                    delta += scoreToFoundation
                    if t.isVegas { t.dollars += GameState.vegasCard }
                }
            case let .column(i):
                t.cols[i].up.append(contentsOf: cards)
                if src == .waste { delta += scoreWasteToColumn }
            case .waste, .stock, .cell:
                return nil
            }
            t.score = max(0, t.score + delta)
            t.moves += 1
            return t
        }
    }

    static func isLegal(_ s: GameState, _ m: Move) -> Bool { apply(s, m) != nil }

    // MARK: Antippen

    private static func columnOrder(from start: Int) -> [Int] { (0..<7).map { (start + $0) % 7 } }

    /// Antippen = bester Zug. `count` = Karten ab der angetippten bis oben. nil → Karte wackelt.
    static func tapTarget(_ s: GameState, from src: Pile, count n: Int) -> Move? {
        guard let cards = movingCards(s, from: src, count: n) else { return nil }
        if n == 1 {
            var vonZiel = false
            if case .foundation = src { vonZiel = true }
            if !vonZiel {
                let f = cards[0].suit.rawValue
                if canPlace(s, cards, on: .foundation(f)) { return .move(from: src, to: .foundation(f), count: 1) }
            }
        }
        var start = 0
        var srcColumn: Int?
        if case let .column(i) = src { start = i + 1; srcColumn = i }
        let order = columnOrder(from: start).filter { $0 != srcColumn }
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
    static func foundationMove(_ s: GameState, from src: Pile, count n: Int) -> Move? {
        guard n == 1, let cards = movingCards(s, from: src, count: 1) else { return nil }
        if case .foundation = src { return nil }
        let f = cards[0].suit.rawValue
        return canPlace(s, cards, on: .foundation(f)) ? .move(from: src, to: .foundation(f), count: 1) : nil
    }

    // MARK: Automatisch ablegen

    private static let sources: [Pile] = [.waste] + (0..<7).map { .column($0) }

    private static func topCard(_ s: GameState, _ src: Pile) -> CardID? {
        switch src {
        case .waste: s.waste.last
        case let .column(i): s.cols[i].top
        case .foundation, .stock, .cell: nil
        }
    }

    /// Sicher = keine Karte der Gegenfarbe braucht sie noch als Unterlage.
    static func isSafeForFoundation(_ s: GameState, _ c: CardID) -> Bool {
        guard c.rank == s.foundation[c.suit.rawValue] + 1 else { return false }
        if c.rank <= 2 { return true }
        let opposite = c.isRed ? [0, 3] : [1, 2]
        return opposite.allSatisfy { s.foundation[$0] >= c.rank - 1 }
    }

    static func autoFoundationMoves(_ start: GameState) -> [Move] {
        var s = start
        var out: [Move] = []
        outer: while true {
            for src in sources {
                if let c = topCard(s, src), isSafeForFoundation(s, c) {
                    let m = Move.move(from: src, to: .foundation(c.suit.rawValue), count: 1)
                    s = apply(s, m)!
                    out.append(m)
                    continue outer
                }
            }
            return out
        }
    }

    // MARK: Automatisch beenden

    static func canAutoFinish(_ s: GameState) -> Bool {
        s.stock.isEmpty && s.waste.isEmpty && s.cols.allSatisfy { $0.down.isEmpty } && !s.isWon
    }

    static func autoFinishMoves(_ start: GameState) -> [Move] {
        var s = start
        var out: [Move] = []
        while !s.isWon {
            var best: (Int, CardID)?
            for (i, col) in s.cols.enumerated() {
                if let c = col.top, c.rank == s.foundation[c.suit.rawValue] + 1, best == nil || c.rank < best!.1.rank {
                    best = (i, c)
                }
            }
            guard let (i, c) = best else { break }
            let m = Move.move(from: .column(i), to: .foundation(c.suit.rawValue), count: 1)
            s = apply(s, m)!
            out.append(m)
        }
        return out
    }

    // MARK: Tipp

    /// Erst Spalten mit passender offener Karte (links → rechts), dann leere Spalten (nur König).
    private static func firstColumnTarget(_ s: GameState, _ cards: [CardID], exclude: Pile?) -> Pile? {
        for i in 0..<7 where Pile.column(i) != exclude && !s.cols[i].up.isEmpty && canPlace(s, cards, on: .column(i)) {
            return .column(i)
        }
        for i in 0..<7 where Pile.column(i) != exclude && s.cols[i].up.isEmpty && canPlace(s, cards, on: .column(i)) {
            return .column(i)
        }
        return nil
    }

    static func hint(_ s: GameState) -> Move? {
        for src in sources {
            if let c = topCard(s, src), c.rank == s.foundation[c.suit.rawValue] + 1 {
                return .move(from: src, to: .foundation(c.suit.rawValue), count: 1)
            }
        }

        let order = (0..<7).filter { !s.cols[$0].down.isEmpty && !s.cols[$0].up.isEmpty }
            .sorted { (-s.cols[$0].down.count, $0) < (-s.cols[$1].down.count, $1) }
        for i in order {
            let n = s.cols[i].up.count
            guard let cards = movingCards(s, from: .column(i), count: n) else { continue }
            if let dst = firstColumnTarget(s, cards, exclude: .column(i)) {
                return .move(from: .column(i), to: dst, count: n)
            }
        }

        if let c = s.waste.last, let dst = firstColumnTarget(s, [c], exclude: nil) {
            return .move(from: .waste, to: dst, count: 1)
        }

        for i in 0..<7 {
            let col = s.cols[i]
            guard col.up.count > 1 else { continue }
            for n in 1..<col.up.count {
                let exposed = col.up[col.up.count - n - 1]
                guard exposed.rank == s.foundation[exposed.suit.rawValue] + 1,
                      let cards = movingCards(s, from: .column(i), count: n),
                      let dst = firstColumnTarget(s, cards, exclude: .column(i)) else { continue }
                return .move(from: .column(i), to: dst, count: n)
            }
        }

        return talonHelps(s) ? .draw : nil
    }

    private static func playableAnywhere(_ s: GameState, _ c: CardID) -> Bool {
        c.rank == s.foundation[c.suit.rawValue] + 1 || firstColumnTarget(s, [c], exclude: nil) != nil
    }

    private static func talonHelps(_ s: GameState) -> Bool {
        let total = s.stock.count + s.waste.count
        guard total > 0 else { return false }
        var t = s
        for _ in 0..<(2 * (total + 1)) {
            guard let n = apply(t, .draw) else { return false }
            t = n
            if let c = t.waste.last, playableAnywhere(t, c) { return true }
        }
        return false
    }

    static func isStuck(_ s: GameState) -> Bool { !s.isWon && hint(s) == nil }
}
