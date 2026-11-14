// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Stärke des Computergegners.
nonisolated enum ComputerLevel: String, Codable, CaseIterable, Sendable {
    /// Hält gleiche Würfel und nimmt das Feld mit den meisten Punkten – macht dabei Fehler.
    case einfach
    /// Spielt mit dem exakten Würfelrat (`HoldAdvisor`) und bewertet Felder nach ihrem üblichen Wert.
    case gut
}

/// Entscheidet den nächsten Schritt eines Computerspielers. Reine Funktionen, keine UI und kein Zufall außer dem
/// hineingereichten `random` (für Tests mit festem Wert).
nonisolated enum ComputerPlayer {
    /// Nächste Aktion für den Spieler, der in `state` am Zug ist.
    static func decide(_ state: GameState, level: ComputerLevel, random: () -> Double = { Double.random(in: 0..<1) }) -> Action {
        guard state.rollsUsed > 0 else { return .roll(keep: []) }
        if state.rollsUsed >= 3 { return .score(bestCategory(state, level: level, random: random)) }
        switch level {
        case .gut:
            if let advice = HoldAdvisor.advise(state) {
                if advice.keepsAll || advice.stopValue >= advice.expected {
                    return .score(bestCategory(state, level: level, random: random))
                }
                return .roll(keep: advice.keep)
            }
            return .score(bestCategory(state, level: level, random: random))
        case .einfach:
            // Gelegentlich zu früh aufhören, wenn schon ein guter Wurf liegt
            if state.dice.count == 5, Set(state.dice).count <= 2, random() < 0.4 {
                return .score(bestCategory(state, level: level, random: random))
            }
            let keep = keepMostCommon(state.dice)
            if keep.count == 5 { return .score(bestCategory(state, level: level, random: random)) }
            return .roll(keep: keep)
        }
    }

    /// Hält alle Würfel der häufigsten Augenzahl (bei Gleichstand die höhere).
    static func keepMostCommon(_ dice: [Int]) -> [Int] {
        guard dice.count == 5 else { return [] }
        var best = (face: 6, count: 0)
        for face in 1...6 {
            let n = dice.filter { $0 == face }.count
            if n > best.count || (n == best.count && n > 0 && face > best.face) { best = (face, n) }
        }
        // Eine Einzelne hält man nur, wenn sie hoch ist: sonst alles neu
        if best.count == 1 && best.face < 5 { return [] }
        return dice.indices.filter { dice[$0] == best.face }
    }

    /// Feld mit dem größten Gewinn gegenüber dem üblichen Wert; „einfach“ schaut nur auf die Punkte.
    static func bestCategory(_ state: GameState, level: ComputerLevel, random: () -> Double = { 0 }) -> Category {
        let legal = state.legalCategories
        guard !legal.isEmpty else { return .chance }
        func value(_ c: Category) -> Double {
            let points = Double(state.potentialScore(c))
            switch level {
            case .gut:
                return points - (HoldAdvisor.par(state.rules.variant)[c] ?? 0)
            case .einfach:
                return points + (points == 0 ? -100 : 0) + random() * 3
            }
        }
        return legal.max { value($0) < value($1) } ?? legal[0]
    }
}
