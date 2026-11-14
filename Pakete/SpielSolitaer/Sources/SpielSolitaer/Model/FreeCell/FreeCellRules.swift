// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Zufall wie Windows-FreeCell: state = (state × 214013 + 2531011) mod 2³¹, rand = state >> 16
struct MsRand {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Int {
        state = (state &* 214013 &+ 2_531_011) % (1 << 31)
        return Int(state >> 16)
    }
}

/// FreeCell – 1:1 die Python-Referenz `Referenz/freecell.py`.
enum FreeCellRules: SolitaireRules {
    static let kind = GameKind.freecell
    static let autoMoveStyle = MoveStyle.normal

    static let maxNumber = 32000
    static let unsolvable = [11982]

    // MARK: Geben (Microsoft-Nummern)

    /// MS-Index (Wert − 1) × 4 + f (f: 0 Kreuz, 1 Karo, 2 Herz, 3 Pik) → unsere Karte
    static func msCard(_ m: Int) -> CardID {
        CardID(rank: m / 4 + 1, suit: Suit(rawValue: 3 - m % 4)!)
    }

    /// Karte i kommt in Spalte i mod 8, oben drauf. `seed` ist die Partienummer.
    static func deal(seed: UInt64, mode: GameMode) -> FreeCellState {
        var rng = MsRand(seed: seed)
        var d = Array(0..<52)
        var cols = Array(repeating: [CardID](), count: 8)
        for i in 0..<52 {
            let rest = 52 - i
            let j = rng.next() % rest
            cols[i % 8].append(msCard(d[j]))
            d[j] = d[rest - 1]
        }
        return FreeCellState(cols: cols, number: Int(seed))
    }

    /// Startbild der Austeil-Animation: alle Karten in Spalte 0 (das Layout legt sie als Stapel in die Mitte)
    static func preDealState(_ s: FreeCellState) -> FreeCellState {
        var t = FreeCellState(number: s.number)
        t.cols[0] = CardID.all
        return t
    }

    /// Tagesspiel: ((Tage seit 01.01.2026) × 7919) mod 32000 + 1; 11982 → 11983. Rest nie negativ.
    static func dailyNumber(days t: Int) -> Int {
        let n = (((t * 7919) % maxNumber) + maxNumber) % maxNumber + 1
        return n == 11982 ? 11983 : n
    }

    // MARK: Reihen

    /// Länge der gültigen Reihe oben auf der Spalte (absteigend, Farben abwechselnd)
    static func runLength(_ col: [CardID]) -> Int {
        guard !col.isEmpty else { return 0 }
        var n = 1
        while n < col.count, col[col.count - n].fits(on: col[col.count - n - 1]) { n += 1 }
        return n
    }

    /// Höchstens so viele Karten auf einmal nach einer Spalte: (leere Zellen + 1) × 2^(leere Spalten);
    /// eine leere Ziel-Spalte zählt nicht mit
    static func maxRun(_ s: FreeCellState, toColumn j: Int) -> Int {
        let free = s.cells.filter { $0 == nil }.count
        var empty = s.cols.filter(\.isEmpty).count
        if s.cols[j].isEmpty { empty -= 1 }
        return (free + 1) << empty
    }

    // MARK: Züge

    static func movingCards(_ s: FreeCellState, from: Pile, count n: Int) -> [CardID]? {
        guard n >= 1 else { return nil }
        switch from {
        case let .cell(i):
            guard (0..<4).contains(i), n == 1, let c = s.cells[i] else { return nil }
            return [c]
        case let .column(i):
            guard (0..<8).contains(i) else { return nil }
            let col = s.cols[i]
            guard n <= col.count, n <= runLength(col) else { return nil }
            return Array(col.suffix(n))
        default:
            return nil   // vom Ziel zurück ist nicht erlaubt
        }
    }

    static func apply(_ s: FreeCellState, _ m: Move) -> FreeCellState? {
        guard case let .move(src, dst, n) = m, src != dst, let cards = movingCards(s, from: src, count: n) else { return nil }
        switch dst {
        case let .cell(j):
            if case .cell = src { return nil }          // Zelle → Zelle bringt nichts
            guard (0..<4).contains(j), n == 1, s.cells[j] == nil else { return nil }
        case let .foundation(j):
            let c = cards[0]
            guard (0..<4).contains(j), n == 1, c.suit.rawValue == j, c.rank == s.foundation[j] + 1 else { return nil }
        case let .column(j):
            guard (0..<8).contains(j) else { return nil }
            if let top = s.cols[j].last, !cards[0].fits(on: top) { return nil }
            guard n <= maxRun(s, toColumn: j) else { return nil }
        default:
            return nil
        }

        var t = s
        switch src {
        case let .cell(i): t.cells[i] = nil
        case let .column(i): t.cols[i].removeLast(n)
        default: return nil
        }
        switch dst {
        case let .cell(j): t.cells[j] = cards[0]
        case let .foundation(j): t.foundation[j] += 1
        case let .column(j): t.cols[j].append(contentsOf: cards)
        default: return nil
        }
        t.moves += 1
        return t
    }

    /// Alle erlaubten Züge (für „festgefahren“; die Reihenfolge ist nicht Teil der Regeln)
    static func legalMoves(_ s: FreeCellState) -> [Move] {
        var sources: [(Pile, Int)] = []
        for i in 0..<4 where s.cells[i] != nil { sources.append((.cell(i), 1)) }
        for i in 0..<8 where runLength(s.cols[i]) >= 1 { for n in 1...runLength(s.cols[i]) { sources.append((.column(i), n)) } }
        let targets: [Pile] = (0..<8).map { .column($0) } + (0..<4).map { .cell($0) } + (0..<4).map { .foundation($0) }
        var out: [Move] = []
        for (q, n) in sources {
            for z in targets where q != z {
                let m = Move.move(from: q, to: z, count: n)
                if apply(s, m) != nil { out.append(m) }
            }
        }
        return out
    }

    // MARK: Antippen

    /// 1. Ziel (nur n = 1) · 2. Spalte mit passender Karte, ab rechts neben der Quelle ringsum (aus Zellen ab S0) ·
    /// 3. leere Spalte (nicht, wenn die Reihe schon die ganze Spalte ist) · 4. erste freie Zelle (nur n = 1, nur aus einer Spalte)
    static func tapTarget(_ s: FreeCellState, from src: Pile, count n: Int) -> Move? {
        guard let cards = movingCards(s, from: src, count: n) else { return nil }
        if n == 1 {
            let m = Move.move(from: src, to: .foundation(cards[0].suit.rawValue), count: 1)
            if apply(s, m) != nil { return m }
        }
        var start = 0
        var srcColumn: Int?
        if case let .column(i) = src { start = i + 1; srcColumn = i }
        let order = (0..<8).map { (start + $0) % 8 }.filter { $0 != srcColumn }
        for i in order where !s.cols[i].isEmpty {
            let m = Move.move(from: src, to: .column(i), count: n)
            if apply(s, m) != nil { return m }
        }
        let whole = srcColumn.map { s.cols[$0].count == n } ?? false
        if !whole {
            for i in order where s.cols[i].isEmpty {
                let m = Move.move(from: src, to: .column(i), count: n)
                if apply(s, m) != nil { return m }
            }
        }
        if n == 1, srcColumn != nil, let k = s.cells.firstIndex(where: { $0 == nil }) {
            return .move(from: src, to: .cell(k), count: 1)
        }
        return nil
    }

    /// Doppeltipp: die Karte aufs Ziel ihrer Farbe, wenn sie dort hin darf
    static func foundationMove(_ s: FreeCellState, from src: Pile, count n: Int) -> Move? {
        guard n == 1, let cards = movingCards(s, from: src, count: 1) else { return nil }
        if case .foundation = src { return nil }
        let m = Move.move(from: src, to: .foundation(cards[0].suit.rawValue), count: 1)
        return apply(s, m) != nil ? m : nil
    }

    // MARK: Automatisch ablegen

    private static let sources: [Pile] = (0..<4).map { .cell($0) } + (0..<8).map { .column($0) }

    private static func topCard(_ s: FreeCellState, _ src: Pile) -> CardID? {
        switch src {
        case let .cell(i): s.cells[i]
        case let .column(i): s.cols[i].last
        default: nil
        }
    }

    /// Sicher = keine Karte der Gegenfarbe braucht sie noch als Unterlage (wie Klondike)
    static func isSafeForFoundation(_ s: FreeCellState, _ c: CardID) -> Bool {
        guard c.rank == s.foundation[c.suit.rawValue] + 1 else { return false }
        if c.rank <= 2 { return true }
        let opposite = c.isRed ? [0, 3] : [1, 2]
        return opposite.allSatisfy { s.foundation[$0] >= c.rank - 1 }
    }

    static func autoMoves(_ start: FreeCellState, autoFoundation: Bool) -> [Move] {
        guard autoFoundation else { return [] }
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

    // MARK: Fertig spielen

    static func canAutoFinish(_ s: FreeCellState) -> Bool {
        !s.isWon && s.cols.allSatisfy { runLength($0) == $0.count }
    }

    static func autoFinishMoves(_ start: FreeCellState) -> [Move] {
        var s = start
        var out: [Move] = []
        while !s.isWon {
            var best: (Pile, CardID)?
            for src in sources {
                if let c = topCard(s, src), c.rank == s.foundation[c.suit.rawValue] + 1, best == nil || c.rank < best!.1.rank {
                    best = (src, c)
                }
            }
            guard let (src, c) = best else { break }
            let m = Move.move(from: src, to: .foundation(c.suit.rawValue), count: 1)
            s = apply(s, m)!
            out.append(m)
        }
        return out
    }

    // MARK: Tipp

    private static func onMatching(_ col: [CardID], _ n: Int) -> Bool {
        col.count > n && col[col.count - n].fits(on: col[col.count - n - 1])
    }

    static func hint(_ s: FreeCellState) -> Move? {
        // 1. Karte aufs Ziel (Zellen vor Spalten)
        for src in sources {
            if let c = topCard(s, src), c.rank == s.foundation[c.suit.rawValue] + 1 {
                return .move(from: src, to: .foundation(c.suit.rawValue), count: 1)
            }
        }
        // 2. Reihe in eine Spalte mit passender Karte, wenn sie jetzt nicht schon auf einer passenden liegt
        for i in 0..<8 {
            let col = s.cols[i]
            let len = runLength(col)
            guard len >= 1 else { continue }
            for n in stride(from: len, through: 1, by: -1) where !onMatching(col, n) {
                for j in 0..<8 where j != i && !s.cols[j].isEmpty {
                    let m = Move.move(from: .column(i), to: .column(j), count: n)
                    if apply(s, m) != nil { return m }
                }
            }
        }
        // 3. Zelle → Spalte mit passender Karte
        for k in 0..<4 where s.cells[k] != nil {
            for j in 0..<8 where !s.cols[j].isEmpty {
                let m = Move.move(from: .cell(k), to: .column(j), count: 1)
                if apply(s, m) != nil { return m }
            }
        }
        // 4. Reihe in eine leere Spalte, wenn sie nicht die ganze Spalte ist und nicht auf einer passenden Karte liegt
        for i in 0..<8 {
            let col = s.cols[i]
            let len = runLength(col)
            guard len >= 1 else { continue }
            for n in stride(from: len, through: 1, by: -1) where n != col.count && !onMatching(col, n) {
                for j in 0..<8 where s.cols[j].isEmpty {
                    let m = Move.move(from: .column(i), to: .column(j), count: n)
                    if apply(s, m) != nil { return m }
                }
            }
        }
        // 5. Oberste Karte in eine freie Zelle, wenn die Karte darunter danach aufs Ziel kann
        if let k = s.cells.firstIndex(where: { $0 == nil }) {
            for i in 0..<8 where s.cols[i].count >= 2 {
                let under = s.cols[i][s.cols[i].count - 2]
                if under.rank == s.foundation[under.suit.rawValue] + 1 {
                    return .move(from: .column(i), to: .cell(k), count: 1)
                }
            }
        }
        // 6. Zur nächsten gebrauchten Zielkarte graben
        return dig(s)
    }

    /// Tipp-Regel 6 (wie `_graben` der Referenz): Unter allen Karten, die als Nächstes aufs Ziel gehören und nicht oben liegen, die mit den
    /// wenigsten Karten darüber (dann kleinerer Wert, dann linke Spalte). Deren oberste Karte in die erste freie Zelle, wenn sie nicht
    /// auf einer passenden Karte liegt; sonst die bewegliche Reihe in eine leere Spalte (wenn sie nicht die ganze Spalte ist).
    private static func dig(_ s: FreeCellState) -> Move? {
        var best: (above: Int, rank: Int, col: Int)?
        for su in 0..<4 {
            let r = s.foundation[su] + 1
            if r > 13 { continue }
            for i in 0..<8 {
                let col = s.cols[i]
                for (d, c) in col.enumerated() where c.suit.rawValue == su && c.rank == r {
                    let above = col.count - 1 - d
                    guard above > 0 else { continue }
                    if let b = best, (above, r, i) >= (b.above, b.rank, b.col) { continue }
                    best = (above, r, i)
                }
            }
        }
        guard let best else { return nil }
        let i = best.col, col = s.cols[i]
        if !onMatching(col, 1), let k = s.cells.firstIndex(where: { $0 == nil }) {
            return .move(from: .column(i), to: .cell(k), count: 1)
        }
        let n = runLength(col)
        if n < col.count {
            for j in 0..<8 where s.cols[j].isEmpty {
                let m = Move.move(from: .column(i), to: .column(j), count: n)
                if apply(s, m) != nil { return m }
            }
        }
        return nil
    }

    static func maxMovable(_ s: FreeCellState, to: Pile) -> Int? {
        if case let .column(j) = to, (0..<8).contains(j) { return maxRun(s, toColumn: j) }
        return nil
    }

    /// Festgefahren: nicht gewonnen und gar kein erlaubter Zug
    static func isStuck(_ s: FreeCellState) -> Bool { !s.isWon && legalMoves(s).isEmpty }
}
