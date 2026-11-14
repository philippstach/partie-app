// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Stärke des Computergegners
nonisolated enum ComputerLevel: String, Codable, CaseIterable, Sendable {
    case einfach, gut
    /// T-098: Mischung aus einfach und gut. Bei jeder Entscheidung gilt zufällig die eine oder die andere Stufe (wie „Mittel“ bei Yacht).
    case mittel

    var title: String { switch self { case .einfach: "einfach"; case .gut: "gut"; case .mittel: "mittel" } }

    /// Die Stufe, mit der diese eine Entscheidung getroffen wird (`mittel` würfelt je Entscheidung).
    var eingesetzt: ComputerLevel { self == .mittel ? (Bool.random() ? .einfach : .gut) : self }
}

/// Entscheidung des Computers nach einem Wurf
nonisolated enum ComputerMove: Equatable, Sendable {
    /// Diese Würfel (Positionen) rauslegen und weiterwürfeln
    case roll(keep: [Int])
    /// Diese Würfel rauslegen und aufhören
    case bank(keep: [Int])
}

/// Entscheidungen des Computergegners: reine Funktionen ohne Zufall und ohne Oberfläche, damit sie testbar sind.
/// „einfach“ legt immer die punktbeste Auswahl raus und hört früh auf; „gut“ vergleicht die Möglichkeiten
/// nach dem erwarteten Gewinn (Niete-Risiko je Anzahl Restwürfel) und nimmt Angebote nur an, wenn sie sich lohnen.
nonisolated enum ComputerPlayer {
    /// Ungefähre Wahrscheinlichkeit, mit n Würfeln keine Punkte zu werfen (Drilling-Regel „alle“)
    static func nieteRisk(_ n: Int) -> Double {
        switch n {
        case ...0: 0
        case 1: 0.667
        case 2: 0.444
        case 3: 0.28
        case 4: 0.16
        case 5: 0.08
        default: 0.03
        }
    }

    /// Ungefähre Punkte, die ein weiterer erfolgreicher Wurf mit n Würfeln im Schnitt bringt
    static func averageGain(_ n: Int) -> Double {
        switch n {
        case ...1: 45
        case 2: 70
        case 3: 110
        case 4: 160
        case 5: 220
        default: 260
        }
    }

    /// Erwarteter Wert eines Zuges, wenn man `total` Punkte hat und mit `left` Würfeln weiterwirft
    static func rollValue(total: Int, left: Int, diceCount: Int) -> Double {
        // Alle rausgelegt: mit allen Würfeln weiter (kein Niete-Risiko durch Restwürfel, aber ein neuer Wurf)
        let n = left == 0 ? diceCount : left
        return (1 - nieteRisk(n)) * (Double(total) + averageGain(n))
    }

    /// Entscheidung nach einem Wurf. `turn` ist der Zug mit gewürfelten Augen (`hasRolled`).
    /// `score` ist der Punktestand des Computers, `goal` das Spielziel.
    static func decide(turn: DiceTurn, rules: GameRules, level: ComputerLevel, score: Int, goal: Int) -> ComputerMove? {
        guard turn.hasRolled else { return nil }
        let level = level.eingesetzt
        let free = turn.dice.indices.filter { !turn.locked[$0] }
        let rolled = free.map { turn.dice[$0] }
        let scoring = rules.scoring
        let best = Scoring.bestSelection(rolled, fullThrow: turn.fullThrow, rules: scoring)
        guard best.points > 0 else { return nil }
        let bestKeep = best.indices.map { free[$0] }.sorted()

        switch level {
        case .einfach:
            let total = turn.banked + best.points
            let left = free.count - bestKeep.count
            if score + total >= goal { return .bank(keep: bestKeep) }
            if left == 0 { return .roll(keep: bestKeep) }
            if total >= 350 || (left <= 2 && total >= 200) { return .bank(keep: bestKeep) }
            return .roll(keep: bestKeep)
        case .gut, .mittel:   // `mittel` ist hier schon aufgelöst
            var chosen: (value: Double, keep: [Int], bank: Bool)?
            for mask in 1..<(1 << free.count) {
                let idx = (0..<free.count).filter { mask & (1 << $0) != 0 }
                guard let pts = Scoring.score(idx.map { rolled[$0] }, fullThrow: turn.fullThrow, rules: scoring) else { continue }
                let total = turn.banked + pts
                let left = free.count - idx.count
                let keep = idx.map { free[$0] }.sorted()
                // Ziel erreicht: sofort aufhören
                if score + total >= goal {
                    if chosen == nil || !chosen!.bank || Double(total) > chosen!.value { chosen = (Double(total) + 1_000_000, keep, true) }
                    continue
                }
                let bankValue = Double(total)
                let roll = rollValue(total: total, left: left, diceCount: turn.count)
                // Alle rausgelegt: weiterwürfeln ist fast immer richtig (neuer Satz Würfel)
                let willBank = left != 0 && bankValue >= roll
                let value = willBank ? bankValue : roll
                if chosen == nil || value > chosen!.value { chosen = (value, keep, willBank) }
            }
            guard let c = chosen else { return nil }
            return c.bank ? .bank(keep: c.keep) : .roll(keep: c.keep)
        }
    }

    /// Soll der Computer das Angebot annehmen (Punkte und Würfel des Vorspielers übernehmen)?
    static func accept(offer: InheritOffer, rules: GameRules, level: ComputerLevel) -> Bool {
        let open = offer.openCount
        // Ohne Würfelangabe (Punkte-Eingabe) gibt es für den Computer nichts zu übernehmen
        guard offer.dice.contains(where: { $0 > 0 }), open > 0 else { return false }
        switch level.eingesetzt {
        case .einfach:
            return offer.points >= 500 && open >= 3
        case .gut, .mittel:   // `mittel` ist hier schon aufgelöst
            // Ein frischer Zug ist im Schnitt etwa 350 Punkte wert
            return rollValue(total: offer.points, left: open, diceCount: offer.dice.count) > 350
        }
    }
}
