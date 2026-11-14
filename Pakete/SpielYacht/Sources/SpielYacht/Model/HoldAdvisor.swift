// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Rat, welche Würfel man halten sollte.
nonisolated struct HoldAdvice: Equatable, Sendable {
    /// Positionen (0–4) der Würfel, die gehalten werden sollen. Alle fünf = nicht mehr würfeln, Feld wählen.
    var keep: [Int]
    /// Erwarteter Nutzen dieses Rates (Punkte über dem Durchschnittswert des gewählten Feldes, siehe `HoldAdvisor`)
    var expected: Double
    /// Nutzen, wenn man jetzt aufhört und das beste Feld nimmt
    var stopValue: Double

    var keepsAll: Bool { keep.count == 5 }
}

/// Berechnet über alle 252 Würfelmuster exakt den Erwartungswert der restlichen Würfe.
///
/// Nutzen eines Endwurfs = bestes freies Feld (Punkte − üblicher Durchschnitt des Feldes). Der Abzug verhindert,
/// dass „Chance“ immer gewinnt und dass man für ein Feld mit 0 Punkten gelobt wird, das man später besser
/// belegen könnte. Die Durchschnittswerte stammen aus der bekannten Strategie fürs Solo-Spiel; sie sind eine
/// Näherung für „Was ist das Feld später wert?“. Die Würfelrechnung selbst ist exakt, die Feldbewertung nicht.
nonisolated enum HoldAdvisor {
    static let par: [Category: Double] = [
        .ones: 2.11, .twos: 5.28, .threes: 8.57, .fours: 12.09, .fives: 15.69, .sixes: 19.19,
        .threeOfAKind: 21.66, .fourOfAKind: 13.10, .fullHouse: 22.59, .smallStraight: 29.46,
        .largeStraight: 32.71, .kniffel: 16.87, .chance: 22.01,
    ]

    /// Üblicher Wert der Felder in Yatzy und Original-Yacht: Näherungen nach dem Muster der Kniffel-Tabelle
    /// (obere Felder wie dort, die übrigen aus Erfahrungswerten für die jeweilige Punktezahl).
    static let parYatzy: [Category: Double] = [
        .ones: 2.11, .twos: 5.28, .threes: 8.57, .fours: 12.09, .fives: 15.69, .sixes: 19.19,
        .onePair: 9.5, .twoPairs: 11.0, .threeOfAKind: 12.0, .fourOfAKind: 6.5, .smallStraight: 8.0,
        .largeStraight: 10.0, .fullHouse: 15.5, .chance: 22.0, .kniffel: 12.0,
    ]
    static let parYacht: [Category: Double] = [
        .ones: 2.11, .twos: 5.28, .threes: 8.57, .fours: 12.09, .fives: 15.69, .sixes: 19.19,
        .fullHouse: 16.0, .fourOfAKind: 8.0, .smallStraight: 14.0, .largeStraight: 14.0, .kniffel: 12.0,
    ]

    static func par(_ variant: Variant) -> [Category: Double] {
        switch variant {
        case .kniffel: par
        case .yatzy: parYatzy
        case .yacht: parYacht
        }
    }

    // MARK: Würfelmuster als Zähler je Augenzahl

    /// Schlüssel eines Musters: Anzahl je Augenzahl 1…6 zur Basis 6.
    private static func key(_ c: [Int]) -> Int { c.reduce(0) { $0 * 6 + $1 } }

    private static func dice(_ c: [Int]) -> [Int] {
        (0..<6).flatMap { Array(repeating: $0 + 1, count: c[$0]) }
    }

    /// Alle Verteilungen von `n` Würfeln auf sechs Augenzahlen mit Wahrscheinlichkeit.
    private static let outcomes: [[(counts: [Int], p: Double)]] = (0...5).map { n in
        var list: [(counts: [Int], p: Double)] = []
        func fact(_ k: Int) -> Double { k <= 1 ? 1 : Double(k) * fact(k - 1) }
        func go(_ face: Int, _ left: Int, _ cur: [Int]) {
            if face == 5 {
                let c = cur + [left]
                let ways = fact(n) / c.reduce(1.0) { $0 * fact($1) }
                list.append((c, ways / pow(6, Double(n))))
                return
            }
            for k in 0...left { go(face + 1, left - k, cur + [k]) }
        }
        go(0, n, [])
        return list
    }

    /// Alle Muster aus fünf Würfeln (252).
    private static let patterns: [[Int]] = outcomes[5].map(\.counts)

    // MARK: Nutzen eines Endwurfs

    private static func utility(_ counts: [Int], state: GameState) -> Double {
        let d = dice(counts)
        let taken = state.currentPlayer.scores
        let yacht = counts.max() == 5
        let joker = state.rules.joker && yacht && taken[.kniffel] != nil
        let variant = state.rules.variant
        let par = Self.par(variant)
        var free = variant.fields.filter { taken[$0] == nil }
        if joker {
            // Gleiche Auswahl wie `GameState.legalCategories`
            if let up = Category.upper[safe: d[0] - 1], taken[up] == nil { free = [up] }
            else {
                let low = free.filter { !$0.isUpper }
                if !low.isEmpty { free = low }
            }
        }
        return free.map { Double(Scoring.score(d, $0, joker: joker && !$0.isUpper, variant: variant)) - (par[$0] ?? 0) }.max() ?? 0
    }

    // MARK: Rechnung

    /// Rat für den aktuellen Zustand; nil, wenn nichts mehr zu würfeln ist.
    static func advise(_ state: GameState) -> HoldAdvice? {
        guard !state.finished, state.dice.count == 5, (1...2).contains(state.rollsUsed) else { return nil }
        let rollsLeft = 3 - state.rollsUsed

        // value[level][key]: Nutzen bei bestem Halten mit `level` Würfen vor sich
        var value: [[Int: Double]] = [[:]]
        for c in patterns { value[0][key(c)] = utility(c, state: state) }
        let current = (1...6).map { v in state.dice.filter { $0 == v }.count }

        func subsets(of c: [Int]) -> [[Int]] {
            var result: [[Int]] = [[]]
            for face in 0..<6 {
                result = result.flatMap { prefix in (0...c[face]).map { prefix + [$0] } }
            }
            return result
        }

        /// Erwartungswert, wenn man `keep` behält und den Rest wirft; `next` = Werte nach dem Wurf.
        func expectation(keep: [Int], next: [Int: Double]) -> Double {
            let n = 5 - keep.reduce(0, +)
            var sum = 0.0
            for o in outcomes[n] {
                let merged = (0..<6).map { keep[$0] + o.counts[$0] }
                sum += o.p * (next[key(merged)] ?? 0)
            }
            return sum
        }

        // Stufen bis zur vorletzten: für jedes Muster das beste Halten
        if rollsLeft == 2 {
            var level1: [Int: Double] = [:]
            for c in patterns {
                level1[key(c)] = subsets(of: c).map { expectation(keep: $0, next: value[0]) }.max() ?? 0
            }
            value.append(level1)
        }
        let next = value[rollsLeft - 1]

        var best = (keep: current, v: -Double.infinity)
        for k in subsets(of: current) {
            let v = expectation(keep: k, next: next)
            // Bei Gleichstand lieber mehr Würfel behalten (weniger Zufall, einfacherer Rat)
            if v > best.v + 1e-12 || (abs(v - best.v) <= 1e-12 && k.reduce(0, +) > best.keep.reduce(0, +)) {
                best = (k, v)
            }
        }

        // Zählmuster zurück in Positionen übersetzen
        var left = best.keep
        var positions: [Int] = []
        for (i, d) in state.dice.enumerated() where left[d - 1] > 0 {
            positions.append(i)
            left[d - 1] -= 1
        }
        return HoldAdvice(keep: positions, expected: best.v,
                          stopValue: value[0][key(current)] ?? 0)
    }

    // MARK: Chancen

    /// Felder, für die eine Chance angezeigt wird
    static let chanceFelder: [Category] = [.threeOfAKind, .fourOfAKind, .fullHouse, .smallStraight, .largeStraight, .kniffel]

    static func chanceFelder(_ variant: Variant) -> [Category] {
        variant.fields.filter { chanceFelder.contains($0) || ($0 == .onePair || $0 == .twoPairs) }
    }

    /// Wahrscheinlichkeit (0…1), mit den restlichen Würfen das Feld `target` zu füllen (Punkte > 0), wenn man dafür bestmöglich
    /// hält. Exakt über alle 252 Würfelmuster. nil, wenn nichts mehr zu würfeln ist oder das Feld belegt ist.
    static func chance(_ state: GameState, target: Category) -> Double? {
        guard !state.finished, state.dice.count == 5, (1...2).contains(state.rollsUsed),
              state.currentPlayer.scores[target] == nil else { return nil }
        let rollsLeft = 3 - state.rollsUsed
        func hit(_ c: [Int]) -> Double { Scoring.score(dice(c), target, joker: false, variant: state.rules.variant) > 0 ? 1 : 0 }
        func subsets(of c: [Int]) -> [[Int]] {
            var result: [[Int]] = [[]]
            for face in 0..<6 { result = result.flatMap { prefix in (0...c[face]).map { prefix + [$0] } } }
            return result
        }
        func expectation(keep: [Int], next: [Int: Double]) -> Double {
            let n = 5 - keep.reduce(0, +)
            var sum = 0.0
            for o in outcomes[n] {
                let merged = (0..<6).map { keep[$0] + o.counts[$0] }
                sum += o.p * (next[key(merged)] ?? 0)
            }
            return sum
        }
        var stufe0: [Int: Double] = [:]
        for c in patterns { stufe0[key(c)] = hit(c) }
        let current = (1...6).map { v in state.dice.filter { $0 == v }.count }
        var next = stufe0
        if rollsLeft == 2 {
            var stufe1: [Int: Double] = [:]
            for c in patterns { stufe1[key(c)] = subsets(of: c).map { expectation(keep: $0, next: stufe0) }.max() ?? 0 }
            next = stufe1
        }
        return subsets(of: current).map { expectation(keep: $0, next: next) }.max() ?? 0
    }

    /// Chancen aller freien Felder der Liste
    static func chancen(_ state: GameState) -> [Category: Double] {
        var out: [Category: Double] = [:]
        for c in chanceFelder(state.rules.variant) { if let p = chance(state, target: c) { out[c] = p } }
        return out
    }
}
