// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation

// MARK: - Einstellungen für alle Spiele

/// Persönliche Einstellungen, die für **alle** Spiele gelten, auch für gespeicherte und laufende.
///
/// Früher lagen sie pro Spiel in `GameSettings`. Dort bleiben die Felder bestehen, damit alte
/// Spielstände unverändert laden. Sie werden aber beim Start, beim Fortsetzen und bei jeder Änderung
/// hier mit diesen Werten überschrieben (`apply(to:)`).
@Observable
final class AppPreferences {
    struct Values: Codable, Equatable, Sendable {
        /// Kurzer Banner „Nächster Spieler“
        var nextPlayerOverlay = true
        /// Punktbeste Auswahl des aktuellen Wurfs markieren
        var bestHint = false
        /// Punktende Würfel nach dem Wurf vorauswählen, auch bei digitalen Würfeln
        var preselect = true
        /// Experimente (z. B. Regel-Chat mit Apple Intelligence), Standard aus
        var experiments = false

        init(nextPlayerOverlay: Bool = true, bestHint: Bool = false, preselect: Bool = true) {
            self.nextPlayerOverlay = nextPlayerOverlay
            self.bestHint = bestHint
            self.preselect = preselect
        }

        /// Fehlende Schlüssel (ältere Versionen) bekommen den Standardwert.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            let d = Values()
            nextPlayerOverlay = try c.decodeIfPresent(Bool.self, forKey: .nextPlayerOverlay) ?? d.nextPlayerOverlay
            bestHint = try c.decodeIfPresent(Bool.self, forKey: .bestHint) ?? d.bestHint
            preselect = try c.decodeIfPresent(Bool.self, forKey: .preselect) ?? d.preselect
            experiments = try c.decodeIfPresent(Bool.self, forKey: .experiments) ?? d.experiments
        }
    }

    var values: Values { didSet { save() } }

    var nextPlayerOverlay: Bool { get { values.nextPlayerOverlay } set { values.nextPlayerOverlay = newValue } }
    var bestHint: Bool { get { values.bestHint } set { values.bestHint = newValue } }
    var preselect: Bool { get { values.preselect } set { values.preselect = newValue } }
    var experiments: Bool { get { values.experiments } set { values.experiments = newValue } }

    static let key = "tenk.preferences.v1"
    /// Letzte Einrichtung (`GameStore.SavedSetup`) – Quelle für die einmalige Übernahme alter Werte
    static let legacySetupKey = "tenk.lastSetup.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        values = Self.load(from: defaults)
    }

    /// Gespeicherte Werte; beim ersten Start die Werte der letzten Einrichtung, sonst Standard.
    static func load(from defaults: UserDefaults) -> Values {
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: key), let values = try? decoder.decode(Values.self, from: data) {
            return values
        }
        if let data = defaults.data(forKey: legacySetupKey),
           let setup = try? decoder.decode(GameStore.SavedSetup.self, from: data) {
            let s = setup.settings
            return Values(nextPlayerOverlay: s.nextPlayerOverlay, bestHint: s.bestHint)
        }
        return Values()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(values) {
            defaults.set(data, forKey: Self.key)
        }
    }

    /// Schreibt diese Werte in die Einstellungen eines Spiels.
    func apply(to settings: inout GameSettings) {
        settings.nextPlayerOverlay = values.nextPlayerOverlay
        settings.bestHint = values.bestHint
        settings.preselectDigital = values.preselect
    }

    func applied(to settings: GameSettings) -> GameSettings {
        var s = settings
        apply(to: &s)
        return s
    }

    /// Hat das Spiel schon genau diese Werte?
    func matches(_ settings: GameSettings) -> Bool {
        applied(to: settings) == settings
    }

    /// Überträgt die Werte ins geöffnete Spiel – nur wenn sich etwas ändert, damit das Datum bleibt.
    func apply(to store: GameStore) {
        guard let game = store.game, !matches(game.settings) else { return }
        store.updateSettings { apply(to: &$0) }
    }
}

// MARK: - Regel-Vorlagen

/// Fertige Regelsätze für den schnellen Start. Der Würfel-Schalter (`diceMode`) bleibt dabei unverändert.
nonisolated enum RulePreset: String, CaseIterable, Identifiable, Sendable {
    case standard
    case short
    case onesAndFives
    case sixDice

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: String(localized: "Standard")
        case .short: String(localized: "Kurzes Spiel – 5.000")
        case .onesAndFives: String(localized: "Nur Einsen und Fünfen")
        case .sixDice: String(localized: "6 Würfel")
        }
    }

    var detail: String {
        switch self {
        case .standard: String(localized: "10.000 Punkte, alle Drillinge zählen, Strafe 500")
        case .short: String(localized: "Ziel 5.000 Punkte, sonst wie Standard")
        case .onesAndFives: String(localized: "Nur drei Einsen (500) und drei Fünfen (500) zählen als Drilling")
        case .sixDice: String(localized: "Mit 6 Würfeln, 5er-Straße, sonst wie Standard")
        }
    }

    /// Regeln der Vorlage (mit digitalen Würfeln)
    var rules: GameRules {
        switch self {
        case .standard: GameRules()
        case .short: GameRules(goal: 5_000)
        case .onesAndFives: GameRules(triples: .onesAndFives)
        case .sixDice: GameRules(diceCount: 6, straight6: .five)
        }
    }

    /// Vorlage anwenden, den Würfel-Schalter behalten.
    func apply(to current: GameRules) -> GameRules {
        var r = rules
        r.diceMode = current.diceMode
        // Zusatzregeln von „10k“ bleiben beim Wechsel der Vorlage stehen
        r.entryThreshold = current.entryThreshold
        r.multiples = current.multiples
        r.threePairs = current.threePairs
        return r
    }

    /// Entspricht `rules` genau dieser Vorlage? (Der Würfel-Schalter zählt nicht mit.)
    func matches(_ rules: GameRules) -> Bool {
        apply(to: rules) == rules
    }

    /// Die passende Vorlage oder `nil` („Eigene Regeln“).
    static func matching(_ rules: GameRules) -> RulePreset? {
        allCases.first { $0.matches(rules) }
    }
}

// MARK: - Regeln in einer Zeile

nonisolated enum RulesSummary {
    /// z. B. „10.000 Punkte · Strafe 500 · alle Drillinge · ohne Rundenlimit“
    static func text(_ rules: GameRules) -> String {
        var parts = [String(localized: "\(format(rules.goal)) Punkte")]
        if rules.diceCount == 6 {
            parts.append(rules.straight6 == .five ? String(localized: "6 Würfel · 5er-Straße") : String(localized: "6 Würfel · große Straße"))
        }
        parts.append(rules.penalty == 0 ? String(localized: "ohne Strafe") : String(localized: "Strafe \(format(rules.penalty))"))
        parts.append(rules.triples == .all ? String(localized: "alle Drillinge") : String(localized: "nur Einsen und Fünfen"))
        if rules.roundLimit == 0 {
            parts.append(String(localized: "ohne Rundenlimit"))
        } else {
            parts.append(rules.roundLimit == 1 ? String(localized: "1 Runde") : String(localized: "\(rules.roundLimit) Runden"))
            if !rules.tiebreak { parts.append(String(localized: "ohne Stechen")) }
        }
        if rules.roundLimit == 0, rules.finalRound, !rules.tiebreak { parts.append(String(localized: "ohne Stechen")) }
        if !rules.inheritAllFive { parts.append(String(localized: "ohne Übernahme mit allen \(rules.diceCount)")) }
        if rules.finalRound { parts.append(String(localized: "mit Schlussrunde")) }
        if rules.entryThreshold > 0 { parts.append(String(localized: "Einstieg ab \(format(rules.entryThreshold))")) }
        switch rules.multiples {
        case .standard: break
        case .doubling: parts.append(String(localized: "Mehrfache verdoppeln"))
        case .fixed: parts.append(String(localized: "Mehrfache fest"))
        }
        if rules.threePairs && rules.diceCount == 6 { parts.append(String(localized: "drei Paare")) }
        return parts.joined(separator: " · ")
    }

    static func format(_ value: Int) -> String {
        value.formatted(.number.locale(Locale(identifier: "de_DE")))
    }
}

// MARK: - Reihenfolge der Spieler

nonisolated enum PlayerOrder {
    /// Dreht die Reihenfolge so, dass `index` beginnt. Die Reihenfolge im Kreis bleibt gleich.
    /// Beispiel: [A, B, C, D] ab C → [C, D, A, B]
    static func starting<T>(_ items: [T], at index: Int) -> [T] {
        guard items.indices.contains(index) else { return items }
        return Array(items[index...] + items[..<index])
    }

    /// Zufällige Reihenfolge – nie die bisherige (bei 2 Spielern sonst in jedem zweiten Fall
    /// „nichts passiert“, das wirkt kaputt). Wie in der Android-App.
    static func shuffled<T: Equatable, G: RandomNumberGenerator>(_ items: [T], using generator: inout G) -> [T] {
        guard items.count >= 2 else { return items }
        let result = items.shuffled(using: &generator)
        guard result == items else { return result }
        // Gleich geblieben → einen Platz weiterdrehen: sicher anders, weiterhin zufällig verteilt
        return Array(result.dropFirst()) + [result[0]]
    }

    static func shuffled<T: Equatable>(_ items: [T]) -> [T] {
        var generator = SystemRandomNumberGenerator()
        return shuffled(items, using: &generator)
    }

    /// Position des Spielers mit den wenigsten Punkten (bei Gleichstand der erste in Sitzreihenfolge).
    static func loserIndex(_ players: [Player]) -> Int? {
        players.indices.min { players[$0].score < players[$1].score }
    }

    /// Frische Spieler (0 Punkte) in derselben Reihenfolge, z. B. für eine Revanche
    static func fresh(_ players: [Player]) -> [Player] {
        players.map { Player(name: $0.name, avatar: $0.avatar, colorIndex: $0.colorIndex) }
    }

    /// Gleiche Leute wie im Spiel `game` (Name und Avatar, Reihenfolge egal)?
    static func samePeople(_ a: [Player], _ b: [Player]) -> Bool {
        func key(_ p: Player) -> String { "\(p.avatar)|\(p.name.trimmingCharacters(in: .whitespaces))" }
        return a.count == b.count && Set(a.map(key)) == Set(b.map(key))
    }
}
