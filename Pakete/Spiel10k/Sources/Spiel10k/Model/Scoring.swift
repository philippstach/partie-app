// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Regeln, die die Wertung eines Wurfs beeinflussen.
nonisolated struct ScoringRules: Equatable, Sendable {
    var triples: TripleRule = .all
    /// 5 oder 6 Würfel
    var diceCount = 5
    /// Straße bei 6 Würfeln
    var straight6: Straight6 = .five
    /// Vier bis sechs Gleiche (Standard = bisherige Wertung)
    var multiples: MultiplesRule = .standard
    /// Drei Paare = 1.500 (nur 6 Würfel, nur im vollen Wurf)
    var threePairs = false

    static let standard = ScoringRules()
}

/// Punkteregeln für 10k (5 oder 6 Würfel).
///
/// - Eine 1 = 100, eine 5 = 50
/// - Drei Einsen = 1.000, drei gleiche andere = Augenzahl × 100
///   (Regel „Nur Einsen und Fünfen“: nur drei Einsen = 500 und drei Fünfen = 500)
/// - Vier, fünf oder sechs Gleiche = Drilling plus Einzelne; zwei Drillinge zählen als zwei Drillinge
/// - Straße nur im vollen Wurf (alle Würfel geworfen):
///   - 5 Würfel: 1–5 oder 2–6 = 1.000
///   - 6 Würfel, `.five`: eine 5er-Straße = 1.000, ein sechster Würfel zählt als 1 oder 5 einzeln dazu
///   - 6 Würfel, `.full`: nur 1–6 = `bigStraightPoints`
///
/// Gewertet wird immer nur, was aus *einem* Wurf rausgelegt wird –
/// Drillinge oder Straßen über mehrere Würfe hinweg zählen nicht.
nonisolated enum Scoring {
    static let straightPoints = 1_000
    /// Große Straße 1–6 bei 6 Würfeln. Vorläufiger Wert (Annahme), Philipp kann ihn noch ändern.
    static let bigStraightPoints = 1_500
    /// Drei Paare (nur 6 Würfel, Regel „Drei Paare“)
    static let threePairsPoints = 1_500

    private static let straights: [[Int]] = [[1, 2, 3, 4, 5], [2, 3, 4, 5, 6]]

    static func isStraight(_ values: [Int]) -> Bool {
        straights.contains(values.sorted())
    }

    /// Punkte für die aus einem Wurf rausgelegten Würfel.
    /// `nil`, wenn nichts ausgewählt ist oder ein Würfel keine Punkte bringt.
    /// - Parameter fullThrow: Wurden in diesem Wurf alle Würfel geworfen?
    static func score(_ values: [Int], fullThrow: Bool, rules: ScoringRules) -> Int? {
        guard !values.isEmpty else { return nil }
        let normal = normalScore(values, rules)
        guard fullThrow else { return normal }

        var best = normal
        if rules.threePairs, rules.diceCount == 6, isThreePairs(values) { best = max(best ?? 0, threePairsPoints) }
        if rules.diceCount == 6 {
            switch rules.straight6 {
            case .full:
                if values.sorted() == [1, 2, 3, 4, 5, 6] { best = max(best ?? 0, bigStraightPoints) }
            case .five where values.count >= 5:
                // Eine 5er-Straße aus der Auswahl, der Rest (höchstens ein Würfel) muss einzeln zählen
                for straight in straights {
                    guard let rest = values.removing(straight) else { continue }
                    guard let restScore = rest.isEmpty ? 0 : singlesScore(rest) else { continue }
                    best = max(best ?? 0, straightPoints + restScore)
                }
            case .five:
                break
            }
        } else if values.count == 5 && isStraight(values) {
            best = max(best ?? 0, straightPoints)
        }
        return best
    }

    /// Drei verschiedene Paare (sechs Würfel)
    static func isThreePairs(_ values: [Int]) -> Bool {
        guard values.count == 6 else { return false }
        var counts = Array(repeating: 0, count: 7)
        for v in values { counts[v] += 1 }
        return counts.filter { $0 == 2 }.count == 3
    }

    private static func normalScore(_ values: [Int], _ triples: TripleRule) -> Int? {
        normalScore(values, ScoringRules(triples: triples))
    }

    /// Wertung ohne Straße: Drillinge (je Augenzahl einer) und einzelne Einsen und Fünfen.
    private static func normalScore(_ values: [Int], _ rules: ScoringRules) -> Int? {
        let triples = rules.triples
        var counts = Array(repeating: 0, count: 7)
        for v in values { counts[v] += 1 }

        var points = 0
        for face in 1...6 where counts[face] >= 3 && countsAsTriple(face, triples) {
            let n = counts[face]
            switch rules.multiples {
            case .standard:
                points += tripleValue(face, triples)
                counts[face] -= 3
                // Sechs Gleiche bleiben Drilling plus Einzelne (keine zwei Drillinge derselben Zahl)
            case .doubling:
                points += tripleValue(face, triples) << (n - 3)
                counts[face] = 0
            case .fixed:
                points += n == 3 ? tripleValue(face, triples) : (n - 3) * 1_000
                counts[face] = 0
            }
        }
        points += counts[1] * 100 + counts[5] * 50
        counts[1] = 0
        counts[5] = 0

        return counts.allSatisfy { $0 == 0 } ? points : nil
    }

    /// Nur einzelne Einsen und Fünfen
    private static func singlesScore(_ values: [Int]) -> Int? {
        values.allSatisfy { $0 == 1 || $0 == 5 } ? values.reduce(0) { $0 + ($1 == 1 ? 100 : 50) } : nil
    }

    /// Kann aus diesem Wurf überhaupt etwas rausgelegt werden? `false` = Niete.
    /// (Jede Straße enthält eine 1 oder 5 und ist damit schon abgedeckt.)
    /// Mit allen Regeln: auch drei Paare zählen (nur im vollen Wurf mit 6 Würfeln).
    static func canScore(_ rolled: [Int], rules: ScoringRules, fullThrow: Bool) -> Bool {
        if canScore(rolled, triples: rules.triples) { return true }
        return fullThrow && rules.threePairs && rules.diceCount == 6 && isThreePairs(rolled)
    }

    static func canScore(_ rolled: [Int], triples: TripleRule = .all) -> Bool {
        if rolled.contains(1) || rolled.contains(5) { return true }
        return (2...6).contains { face in
            countsAsTriple(face, triples) && rolled.filter { $0 == face }.count >= 3
        }
    }

    /// Punkte für drei Gleiche: drei Einsen = 1.000 (bei „Nur Einsen und Fünfen“ 500), sonst Augenzahl × 100.
    static func tripleValue(_ face: Int, _ rule: TripleRule) -> Int {
        if face == 1 { return rule == .onesAndFives ? 500 : 1000 }
        return face * 100
    }

    /// Zählt drei Gleiche dieser Augenzahl als Drilling?
    static func countsAsTriple(_ face: Int, _ rule: TripleRule) -> Bool {
        switch rule {
        case .all: true
        case .onesAndFives: face == 1 || face == 5
        }
    }

    /// Höchstmögliche Punkte aus einem Wurf (für Hinweise).
    static func best(_ rolled: [Int], fullThrow: Bool, rules: ScoringRules) -> Int {
        bestSelection(rolled, fullThrow: fullThrow, rules: rules).points
    }

    /// Punktbeste Auswahl eines Wurfs als Positionen in `rolled` (bei 6 Würfeln 63 Kombinationen).
    /// Bei Gleichstand gewinnt die Auswahl mit weniger Würfeln (mehr bleiben zum Weiterwürfeln).
    static func bestSelection(_ rolled: [Int], fullThrow: Bool, rules: ScoringRules) -> (points: Int, indices: [Int]) {
        let n = rolled.count
        guard n > 0 else { return (0, []) }
        var best = (points: 0, indices: [Int]())
        for mask in 1..<(1 << n) {
            let indices = (0..<n).filter { mask & (1 << $0) != 0 }
            guard let s = score(indices.map { rolled[$0] }, fullThrow: fullThrow, rules: rules) else { continue }
            if s > best.points || (s == best.points && indices.count < best.indices.count) {
                best = (s, indices)
            }
        }
        return best
    }

    // MARK: - Kurzformen mit 5 Würfeln (nur Drilling-Regel), z. B. für ältere Tests

    static func score(_ values: [Int], fullThrow: Bool, triples: TripleRule = .all) -> Int? {
        score(values, fullThrow: fullThrow, rules: ScoringRules(triples: triples))
    }

    static func best(_ rolled: [Int], fullThrow: Bool, triples: TripleRule = .all) -> Int {
        best(rolled, fullThrow: fullThrow, rules: ScoringRules(triples: triples))
    }

    static func bestSelection(_ rolled: [Int], fullThrow: Bool, triples: TripleRule = .all) -> (points: Int, indices: [Int]) {
        bestSelection(rolled, fullThrow: fullThrow, rules: ScoringRules(triples: triples))
    }
}

private extension Array where Element == Int {
    /// Entfernt jedes Element von `other` einmal; `nil`, wenn eines fehlt.
    nonisolated func removing(_ other: [Int]) -> [Int]? {
        var rest = self
        for v in other {
            guard let i = rest.firstIndex(of: v) else { return nil }
            rest.remove(at: i)
        }
        return rest
    }
}
