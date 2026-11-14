// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// TriPeaks – 1:1 die Python-Referenz `Referenz/tripeaks.py` (SPEZIFIKATION-TRIPEAKS).
/// Orte als `Pile`: Gipfelplatz t = `.column(t)`. Züge: `.draw` (Stapel) · freie Karte auf die Ablage `.move(from: .column(t), to: .waste, count: 1)`.
enum TriPeaksRules: SolitaireRules {
    static let kind = GameKind.tripeaks
    static let autoMoveStyle = MoveStyle.normal
    static let tapOnly = true

    // MARK: Geben

    /// Karten 0 … 27 auf T0 … T27, Karte 28 auf die Ablage, 29 … 51 Stapel (51 oben)
    static func deal(seed: UInt64, mode: GameMode) -> TriPeaksState {
        let deck = Deal.shuffledDeck(seed: seed)
        let n = TriPeaksState.places
        return TriPeaksState(peaks: deck[..<n].map { Optional($0) }, stock: Array(deck[(n + 1)...]), waste: [deck[n]])
    }

    static func preDealState(_ s: TriPeaksState) -> TriPeaksState {
        TriPeaksState(peaks: nil, stock: CardID.all)
    }

    // MARK: Züge

    /// Freie Karten, die auf die Ablage passen, aufsteigend
    static func playable(_ s: TriPeaksState) -> [Int] {
        guard let top = s.waste.last else { return [] }
        return s.freePlaces.filter { TriPeaksState.fits(s.peaks[$0]!, on: top) }
    }

    static func movingCards(_ s: TriPeaksState, from: Pile, count: Int) -> [CardID]? {
        guard count == 1, case let .column(t) = from, t >= 0, t < TriPeaksState.places, s.isFree(t), let c = s.peaks[t] else { return nil }
        return [c]
    }

    static func apply(_ s: TriPeaksState, _ m: Move) -> TriPeaksState? {
        var t = s
        switch m {
        case .draw:
            guard let top = t.stock.popLast() else { return nil }
            t.waste.append(top)
            t.chain = 0
        case let .move(from, to, count):
            guard count == 1, to == .waste, case let .column(k) = from, k >= 0, k < TriPeaksState.places,
                  s.isFree(k), let c = s.peaks[k], let top = s.waste.last, TriPeaksState.fits(c, on: top) else { return nil }
            t.peaks[k] = nil
            t.waste.append(c)
            t.chain += 1
            t.score += t.chain
            if TriPeaksState.peakPlaces.contains(k) {
                t.score += TriPeaksState.peakPlaces.allSatisfy({ t.peaks[$0] == nil }) ? TriPeaksState.scoreLastPeak : TriPeaksState.scorePeak
            }
        }
        t.moves += 1
        return t
    }

    static func legalMoves(_ s: TriPeaksState) -> [Move] {
        var out: [Move] = playable(s).map { .move(from: .column($0), to: .waste, count: 1) }
        if !s.stock.isEmpty { out.append(.draw) }
        return out
    }

    static func tapTarget(_ s: TriPeaksState, from: Pile, count: Int) -> Move? {
        guard movingCards(s, from: from, count: count) != nil else { return nil }
        let m = Move.move(from: from, to: .waste, count: 1)
        return isLegal(s, m) ? m : nil
    }

    /// Gipfel geräumt: „+15“, beim letzten „+30“ – dort, wo die Gipfelkarte lag
    static func bonusPopup(_ before: TriPeaksState, _ after: TriPeaksState, _ m: Move) -> (text: String, pile: Pile)? {
        guard case let .move(from, _, _) = m, case let .column(k) = from, TriPeaksState.peakPlaces.contains(k) else { return nil }
        let bonus = after.score - before.score - after.chain
        return bonus > 0 ? ("+\(bonus)", from) : nil
    }

    /// Ab Kette 5 je Glied einen Halbton höher, höchstens +7
    static func soundPitch(_ after: TriPeaksState) -> Int { after.chain >= 5 ? min(7, after.chain - 4) : 0 }

    static func autoMoves(_ s: TriPeaksState, autoFoundation: Bool) -> [Move] { [] }
    static func canAutoFinish(_ s: TriPeaksState) -> Bool { false }
    static func autoFinishMoves(_ s: TriPeaksState) -> [Move] { [] }

    // MARK: Tipp

    /// Macht die Wegnahme von t eine Karte frei?
    static func freesCard(_ s: TriPeaksState, _ t: Int) -> Bool {
        TriPeaksState.on[t].contains { u in
            s.peaks[u] != nil && TriPeaksState.coveredBy[u].allSatisfy { $0 == t || s.peaks[$0] == nil }
        }
    }

    /// 1. passende freie Karte, die eine Karte frei macht 2. danach geht eine weitere 3. irgendeine (jeweils niedrigste Platznummer)
    /// 4. Stapel, wenn nicht leer. Gewonnen → nil.
    static func hint(_ s: TriPeaksState) -> Move? {
        if s.isWon { return nil }
        let cand = playable(s)
        func card(_ t: Int) -> Move { .move(from: .column(t), to: .waste, count: 1) }
        for t in cand where freesCard(s, t) { return card(t) }
        for t in cand {
            if let next = apply(s, card(t)), !playable(next).isEmpty { return card(t) }
        }
        if let t = cand.first { return card(t) }
        return s.stock.isEmpty ? nil : .draw
    }

    static func isStuck(_ s: TriPeaksState) -> Bool { !s.isWon && hint(s) == nil }

    // MARK: Lösungen (Zugschrift: `s`, `T21`)

    static func solutionMoves(from text: String) -> [Move]? {
        var out: [Move] = []
        for token in text.split(separator: " ") {
            if token == "s" { out.append(.draw); continue }
            guard token.count >= 2, token.first == "T", let k = Int(token.dropFirst()), k >= 0, k < TriPeaksState.places,
                  String(k) == token.dropFirst() else { return nil }
            out.append(.move(from: .column(k), to: .waste, count: 1))
        }
        return out
    }
}
