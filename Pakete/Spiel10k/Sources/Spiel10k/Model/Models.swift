// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

nonisolated enum DiceMode: String, Codable, CaseIterable, Sendable {
    case digital, real
}

/// Welche Drillinge zählen.
nonisolated enum TripleRule: String, Codable, CaseIterable, Sendable {
    /// Drei Einsen = 1.000, andere drei Gleiche = Augenzahl × 100
    case all
    /// Nur drei Einsen (500) und drei Fünfen (500); andere Drillinge zählen nicht
    case onesAndFives
}

/// Straße bei 6 Würfeln.
nonisolated enum Straight6: String, Codable, CaseIterable, Sendable {
    /// 1-2-3-4-5 oder 2-3-4-5-6 = 1.000; der sechste Würfel zählt als 1 bzw. 5 einzeln dazu
    case five
    /// Nur 1-2-3-4-5-6 = `Scoring.bigStraightPoints`
    case full
}

/// Vier, fünf oder sechs Gleiche (nur in „10k“ wählbar; Standard = bisherige Wertung).
nonisolated enum MultiplesRule: String, Codable, CaseIterable, Sendable {
    /// Drilling plus einzelne Einsen/Fünfen (bisherige Wertung)
    case standard
    /// Der Drilling verdoppelt sich mit jedem weiteren gleichen Würfel (vier Vieren = 800)
    case doubling
    /// Feste Werte: vier Gleiche 1.000, fünf 2.000, sechs 3.000
    case fixed
}

/// Spielregeln – ab Spielstart fest. Das JSON entspricht dem `rules`-Objekt des späteren Servers
/// (Doku/MEHRSPIELER-PLAN.md, Abschnitt 6).
nonisolated struct GameRules: Codable, Equatable, Sendable {
    var goal = 10_000
    /// 0 = kein Limit
    var roundLimit = 0
    /// Strafe nach 3 Nullrunden in Folge; 0 = aus
    var penalty = 500
    var diceMode: DiceMode = .digital
    var triples: TripleRule = .all
    /// Stechen bei Gleichstand am Ende des Runden-Limits (sonst gemeinsamer Sieg)
    var tiebreak = true
    /// Wer alle Würfel rausgelegt hat und aufhört, bietet dem Nächsten alle Würfel an
    var inheritAllFive = true
    /// Anzahl der Würfel: 5 (Standard) oder 6
    var diceCount = 5
    /// Straße bei 6 Würfeln (bei 5 Würfeln ohne Bedeutung)
    var straight6: Straight6 = .five
    /// Faire Schlussrunde: Erreicht jemand das Ziel, wird die Runde zu Ende gespielt (Standard aus)
    var finalRound = false
    /// Einstiegshürde: erstes Anschreiben erst ab so vielen Punkten in einem Zug (0 = aus). Nur „10k“.
    var entryThreshold = 0
    /// Vierlinge, Fünflinge, Sechslinge (Standard = bisherige Wertung). Nur „10k“.
    var multiples: MultiplesRule = .standard
    /// Drei Paare = 1.500 (nur 6 Würfel, nur im Wurf mit allen). Nur „10k“.
    var threePairs = false

    static let allowedDiceCounts = [5, 6]
    static let entryThresholds = [0, 350, 500, 1_000]

    init(goal: Int = 10_000, roundLimit: Int = 0, penalty: Int = 500, diceMode: DiceMode = .digital,
         triples: TripleRule = .all, tiebreak: Bool = true, inheritAllFive: Bool = true,
         diceCount: Int = 5, straight6: Straight6 = .five, finalRound: Bool = false,
         entryThreshold: Int = 0, multiples: MultiplesRule = .standard, threePairs: Bool = false) {
        self.diceCount = diceCount
        self.straight6 = straight6
        self.finalRound = finalRound
        self.entryThreshold = entryThreshold
        self.multiples = multiples
        self.threePairs = threePairs
        self.goal = goal
        self.roundLimit = roundLimit
        self.penalty = penalty
        self.diceMode = diceMode
        self.triples = triples
        self.tiebreak = tiebreak
        self.inheritAllFive = inheritAllFive
    }

    /// Fehlende Schlüssel fallen auf die Standardwerte zurück.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GameRules()
        goal = try c.decodeIfPresent(Int.self, forKey: .goal) ?? d.goal
        roundLimit = try c.decodeIfPresent(Int.self, forKey: .roundLimit) ?? d.roundLimit
        penalty = try c.decodeIfPresent(Int.self, forKey: .penalty) ?? d.penalty
        diceMode = try c.decodeIfPresent(DiceMode.self, forKey: .diceMode) ?? d.diceMode
        triples = try c.decodeIfPresent(TripleRule.self, forKey: .triples) ?? d.triples
        tiebreak = try c.decodeIfPresent(Bool.self, forKey: .tiebreak) ?? d.tiebreak
        inheritAllFive = try c.decodeIfPresent(Bool.self, forKey: .inheritAllFive) ?? d.inheritAllFive
        let count = try c.decodeIfPresent(Int.self, forKey: .diceCount) ?? d.diceCount
        diceCount = Self.allowedDiceCounts.contains(count) ? count : d.diceCount
        straight6 = try c.decodeIfPresent(Straight6.self, forKey: .straight6) ?? d.straight6
        finalRound = try c.decodeIfPresent(Bool.self, forKey: .finalRound) ?? d.finalRound
        entryThreshold = try c.decodeIfPresent(Int.self, forKey: .entryThreshold) ?? d.entryThreshold
        multiples = (try? c.decodeIfPresent(MultiplesRule.self, forKey: .multiples)) ?? d.multiples
        threePairs = try c.decodeIfPresent(Bool.self, forKey: .threePairs) ?? d.threePairs
    }

    /// Regeln für die Wertung eines Wurfs
    var scoring: ScoringRules {
        ScoringRules(triples: triples, diceCount: diceCount, straight6: straight6, multiples: multiples, threePairs: threePairs)
    }
}

/// Wie bei echten Würfeln eingetragen wird – persönlich, im Spiel umschaltbar.
nonisolated enum RealEntry: String, Codable, CaseIterable, Sendable {
    /// Punkte des Zugs eintippen
    case points
    /// Nach jedem Wurf die rausgelegten Würfel eintippen (Aktion `layOut`), die App rechnet
    case pips
}

/// Regeln (fest) plus persönliche Einstellungen (jederzeit änderbar, bleiben auf dem Gerät).
nonisolated struct GameSettings: Equatable, Sendable {
    var rules = GameRules()
    /// Kurzer Banner „Nächster Spieler“
    var nextPlayerOverlay = true
    /// Punktbeste Auswahl des aktuellen Wurfs markieren
    var bestHint = false
    var realEntry: RealEntry = .points
    /// Nach jedem Wurf die punktbeste Auswahl vorauswählen – auch digital
    /// (Bei echten Würfeln tippt man nur die rausgelegten Würfel ein, dort gibt es keine Vorauswahl.)
    var preselectDigital = false

    init(goal: Int = 10_000, roundLimit: Int = 0, penalty: Int = 500, diceMode: DiceMode = .digital,
         triples: TripleRule = .all, tiebreak: Bool = true, inheritAllFive: Bool = true,
         nextPlayerOverlay: Bool = true,
         bestHint: Bool = false, realEntry: RealEntry = .points, diceCount: Int = 5, straight6: Straight6 = .five,
         finalRound: Bool = false) {
        rules = GameRules(goal: goal, roundLimit: roundLimit, penalty: penalty, diceMode: diceMode,
                          triples: triples, tiebreak: tiebreak, inheritAllFive: inheritAllFive,
                          diceCount: diceCount, straight6: straight6, finalRound: finalRound)
        self.nextPlayerOverlay = nextPlayerOverlay
        self.bestHint = bestHint
        self.realEntry = realEntry
    }

    // Kurzzugriffe auf die Regeln
    var goal: Int { get { rules.goal } set { rules.goal = newValue } }
    var roundLimit: Int { get { rules.roundLimit } set { rules.roundLimit = newValue } }
    var penalty: Int { get { rules.penalty } set { rules.penalty = newValue } }
    var diceMode: DiceMode { get { rules.diceMode } set { rules.diceMode = newValue } }

    /// Würfel werden gewürfelt bzw. als Augen eingegeben (nicht nur Punkte eingetippt).
    var usesDice: Bool { diceMode == .digital || realEntry == .pips }

    /// Digitale Würfel: punktende Würfel nach dem Wurf vorauswählen, man tippt nur noch ab,
    /// was man behalten will. Bei echten Würfeln tippt man nur die rausgelegten Würfel ein.
    var preselectsBest: Bool { diceMode == .digital && preselectDigital }
}

nonisolated extension GameSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case rules, nextPlayerOverlay, bestHint, realEntry, preselectDigital
        // altes, flaches Format (vor GameRules)
        case goal, roundLimit, penalty, diceMode
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        if let rules = try c.decodeIfPresent(GameRules.self, forKey: .rules) {
            self.rules = rules
        } else {
            rules.goal = try c.decodeIfPresent(Int.self, forKey: .goal) ?? rules.goal
            rules.roundLimit = try c.decodeIfPresent(Int.self, forKey: .roundLimit) ?? rules.roundLimit
            rules.penalty = try c.decodeIfPresent(Int.self, forKey: .penalty) ?? rules.penalty
            rules.diceMode = try c.decodeIfPresent(DiceMode.self, forKey: .diceMode) ?? rules.diceMode
        }
        nextPlayerOverlay = try c.decodeIfPresent(Bool.self, forKey: .nextPlayerOverlay) ?? nextPlayerOverlay
        bestHint = try c.decodeIfPresent(Bool.self, forKey: .bestHint) ?? bestHint
        realEntry = try c.decodeIfPresent(RealEntry.self, forKey: .realEntry) ?? realEntry
        preselectDigital = try c.decodeIfPresent(Bool.self, forKey: .preselectDigital) ?? preselectDigital
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(rules, forKey: .rules)
        try c.encode(nextPlayerOverlay, forKey: .nextPlayerOverlay)
        try c.encode(bestHint, forKey: .bestHint)
        try c.encode(realEntry, forKey: .realEntry)
        try c.encode(preselectDigital, forKey: .preselectDigital)
    }
}

nonisolated struct Player: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var name: String
    var avatar: String
    var colorIndex: Int
    var score = 0
    /// Züge in Folge ohne Punkte
    var streak = 0
    /// Anzahl Nieten (Züge ohne Punkte)
    var nieten = 0
    var bestTurn = 0
    var turns = 0
    /// Computergegner (nur mit App-Würfeln); nil = Mensch. Fehlt in älteren Spielständen.
    var computer: ComputerLevel?

    var isComputer: Bool { computer != nil }

    /// JSON-Schlüssel bleiben kompatibel: „nieten“ hieß früher „mackes“.
    enum CodingKeys: String, CodingKey {
        case id, name, avatar, colorIndex, score, streak, bestTurn, turns, computer
        case nieten = "mackes"
    }
}

nonisolated struct TurnRecord: Codable, Identifiable, Equatable, Sendable {
    var id = UUID()
    var player: Int
    /// 0 = Niete / keine Punkte
    var points: Int
    /// Abgezogene Strafpunkte (3× in Folge keine Punkte)
    var penalty = 0
    /// Würfel und Punkte von diesem Spieler übernommen (fehlt bei älteren Spielständen)
    var inheritedFrom: Int?
}

/// Zustand des laufenden Zugs mit digitalen Würfeln.
nonisolated struct DiceTurn: Codable, Equatable, Sendable {
    /// Standard-Würfelzahl (ältere Spielstände, Standardregeln)
    static let defaultCount = 5

    var dice = Array(repeating: 1, count: defaultCount)
    /// In früheren Würfen dieses Zugs rausgelegt (bzw. vom Vorspieler übernommen) – fest.
    var locked = Array(repeating: false, count: defaultCount)
    /// Im aktuellen Wurf zum Rauslegen ausgewählt.
    var selected = Array(repeating: false, count: defaultCount)
    /// Bereits gesicherte Punkte dieses Zugs (inkl. übernommener Punkte).
    var banked = 0
    var hasRolled = false
    /// Wurden im letzten Wurf alle Würfel geworfen? (Voraussetzung für Straße)
    var fullThrow = true
    /// Spieler, von dem Würfel und Punkte übernommen wurden.
    var inheritedFrom: Int?
    var inheritedPoints = 0
    /// Echte Würfel, „rausgelegte Würfel eingeben“: Anzahl der bestätigten Würfe in diesem Zug.
    var keptThrows = 0

    /// Anzahl der Würfel im Spiel (5 oder 6)
    var count: Int { dice.count }
    /// Offene (nicht rausgelegte) Würfel
    var openCount: Int { locked.filter { !$0 }.count }
    /// Rausgelegt-Eingabe: Zählt im nächsten Wurf eine Straße? Nur mit allen Würfeln
    /// und nicht im ersten Wurf nach einer Übernahme.
    var keptFullThrow: Bool { openCount == count && !(inheritedFrom != nil && keptThrows == 0) }

    var selectedValues: [Int] { dice.indices.filter { selected[$0] }.map { dice[$0] } }
    func selectionScore(_ rules: ScoringRules) -> Int? {
        Scoring.score(selectedValues, fullThrow: fullThrow, rules: rules)
    }
    func total(_ rules: ScoringRules) -> Int { banked + (selectionScore(rules) ?? 0) }
    /// Positionen der punktbesten Auswahl unter den frei gewürfelten Würfeln.
    func bestSelection(_ rules: ScoringRules) -> Set<Int> {
        guard hasRolled else { return [] }
        let free = dice.indices.filter { !locked[$0] }
        let best = Scoring.bestSelection(free.map { dice[$0] }, fullThrow: fullThrow, rules: rules)
        return Set(best.indices.map { free[$0] })
    }
    /// Würfel, die beim nächsten „Weiterwürfeln“ geworfen werden.
    var nextRollCount: Int {
        guard hasRolled else { return locked.filter { !$0 }.count }
        let open = dice.indices.filter { !locked[$0] && !selected[$0] }.count
        return open == 0 ? count : open
    }
    /// Alle Positionen frei bzw. nichts ausgewählt – passend zur Würfelzahl
    var noneFlags: [Bool] { Array(repeating: false, count: count) }
}

nonisolated extension DiceTurn {
    /// Neuer Zug mit `count` Würfeln (5 oder 6)
    init(count: Int) {
        self.init()
        dice = Array(repeating: 1, count: count)
        locked = Array(repeating: false, count: count)
        selected = Array(repeating: false, count: count)
    }
}

nonisolated extension DiceTurn {
    private enum CodingKeys: String, CodingKey {
        case dice, locked, selected, banked, hasRolled, fullThrow, inheritedFrom, inheritedPoints, keptThrows
    }

    /// Fehlende Schlüssel (ältere Spielstände, z. B. ohne `keptThrows`) bekommen den Standardwert.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = DiceTurn()
        dice = try c.decodeIfPresent([Int].self, forKey: .dice) ?? d.dice
        // Fehlende Felder passend zur Würfelzahl (5 oder 6) ergänzen
        let none = Array(repeating: false, count: dice.count)
        locked = try c.decodeIfPresent([Bool].self, forKey: .locked) ?? none
        selected = try c.decodeIfPresent([Bool].self, forKey: .selected) ?? none
        banked = try c.decodeIfPresent(Int.self, forKey: .banked) ?? d.banked
        hasRolled = try c.decodeIfPresent(Bool.self, forKey: .hasRolled) ?? d.hasRolled
        fullThrow = try c.decodeIfPresent(Bool.self, forKey: .fullThrow) ?? d.fullThrow
        inheritedFrom = try c.decodeIfPresent(Int.self, forKey: .inheritedFrom)
        inheritedPoints = try c.decodeIfPresent(Int.self, forKey: .inheritedPoints) ?? d.inheritedPoints
        keptThrows = try c.decodeIfPresent(Int.self, forKey: .keptThrows) ?? d.keptThrows
    }
}

/// Angebot an den nächsten Spieler, offene Würfel samt Punkten zu übernehmen.
nonisolated struct InheritOffer: Codable, Equatable, Sendable {
    var from: Int
    var points: Int
    var dice: [Int]
    /// Würfel, die der Vorspieler rausgelegt hat
    var kept: [Bool]
    var openCount: Int { kept.filter { !$0 }.count }
    /// Der Vorspieler hat alle 5 rausgelegt – übernommen wird mit allen 5 Würfeln.
    var allOut: Bool { !kept.contains(true) }
}

/// Stechen bei Gleichstand am Ende des Runden-Limits.
nonisolated struct Tiebreak: Codable, Equatable, Sendable {
    /// Beteiligte in Sitzreihenfolge
    var players: [Int]
    var round = 1
    /// Punkte dieser Stechrunde, in der Reihenfolge von `players`
    var points: [Int] = []

    var isComplete: Bool { points.count == players.count }
    var nextPlayer: Int? { isComplete ? nil : players[points.count] }
}

nonisolated struct GameState: Codable, Equatable, Sendable {
    var players: [Player]
    var settings: GameSettings
    var current = 0
    var turn = DiceTurn()
    var offer: InheritOffer?
    var log: [TurnRecord] = []
    /// Punktestand aller Spieler nach jedem Zug (Index 0 = Start)
    var timeline: [[Int]]
    /// Sieger. Mehrere Einträge nur noch bei alten Spielständen (vor dem Stechen).
    var winners: [Int] = []
    /// Laufendes (oder entschiedenes) Stechen
    var tiebreak: Tiebreak?
    /// Faire Schlussrunde läuft: dieser Spieler hat das Ziel zuerst erreicht (fehlt bei älteren Ständen)
    var finalRoundFrom: Int?
    /// Blatt 22 (EB2, Schritt 2): Würfelzählung für „So fielen die Würfel“. Je Person sechs Zähler (Index 0 = Einsen) und wie viele
    /// davon mit echten Würfeln eingegeben wurden. Optional: ein Stand von vor dem Update lädt mit `nil`, dann gibt es kein Bild.
    var augen: [[Int]]?
    var augenGetippt: [Int]?

    init(players: [Player], settings: GameSettings) {
        self.players = players
        self.settings = settings
        self.augen = players.map { _ in Array(repeating: 0, count: 6) }
        self.augenGetippt = players.map { _ in 0 }
        self.turn = DiceTurn(count: settings.rules.diceCount)
        self.timeline = [players.map { _ in 0 }]
    }

    /// Zählt Würfel für die Person am Zug (ein alter Stand ohne Zählung zählt nicht mit).
    mutating func zaehleAugen(_ werte: [Int], echt: Bool) {
        guard var a = augen, var g = augenGetippt, a.indices.contains(current), g.indices.contains(current), a[current].count == 6 else { return }
        for w in werte where (1...6).contains(w) { a[current][w - 1] += 1 }
        if echt { g[current] += werte.count }
        augen = a; augenGetippt = g
    }

    var finished: Bool { !winners.isEmpty }
    var isTie: Bool { winners.count > 1 }
    var roundNumber: Int { log.count / max(players.count, 1) + 1 }
    var inTiebreak: Bool { tiebreak != nil && !finished }

    /// Passt der Stand zusammen? Beschädigte oder von Hand bearbeitete Dateien mit falschen
    /// Indizes würden sonst später in der Oberfläche abstürzen – solche Stände werden nicht geladen.
    var isConsistent: Bool {
        let n = players.count
        let valid = 0..<n
        let count = settings.rules.diceCount
        // 8 = Theme.maxPlayers
        guard (1...8).contains(n), valid.contains(current) else { return false }
        guard turn.dice.count == count, turn.locked.count == count, turn.selected.count == count,
              turn.dice.allSatisfy((0...6).contains) else { return false }
        guard turn.inheritedFrom.map(valid.contains) ?? true else { return false }
        if let offer {
            guard valid.contains(offer.from), offer.dice.count == count, offer.kept.count == count,
                  offer.dice.allSatisfy((0...6).contains) else { return false }
        }
        guard finalRoundFrom.map(valid.contains) ?? true, winners.allSatisfy(valid.contains),
              log.allSatisfy({ valid.contains($0.player) && ($0.inheritedFrom.map(valid.contains) ?? true) }) else { return false }
        guard !timeline.isEmpty, timeline.allSatisfy({ $0.count == n }) else { return false }
        if let tiebreak {
            guard !tiebreak.players.isEmpty, tiebreak.players.allSatisfy(valid.contains),
                  tiebreak.points.count <= tiebreak.players.count else { return false }
        }
        return settings.goal > 0
    }

    /// Hat diese Person schon angeschrieben (ein Zug mit Punkten)? Maßgeblich für die Einstiegshürde.
    func hasEntered(_ player: Int) -> Bool {
        log.contains { $0.player == player && $0.points > 0 }
    }

    /// Mindestpunkte, die der Zug der aktuellen Person haben muss, damit sie aufhören darf (0 = keine Hürde).
    /// Gilt nur bis zum ersten Anschreiben und nicht im Stechen.
    var entryNeeded: Int {
        let t = settings.rules.entryThreshold
        guard t > 0, tiebreak == nil, players.indices.contains(current), !hasEntered(current) else { return 0 }
        return t
    }

    /// Droht diesem Spieler beim nächsten Nullzug die Strafe? (nicht im Stechen, nicht bei Strafe 0)
    func penaltyThreatened(_ player: Int) -> Bool {
        players[player].streak == 2 && settings.penalty > 0 && tiebreak == nil
    }
}

nonisolated extension GameState {
    private enum CodingKeys: String, CodingKey {
        case players, settings, current, turn, offer, log, timeline, winners, tiebreak, finalRoundFrom
        case winner // altes Format (nur ein Sieger)
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        players = try c.decode([Player].self, forKey: .players)
        settings = try c.decode(GameSettings.self, forKey: .settings)
        current = try c.decodeIfPresent(Int.self, forKey: .current) ?? 0
        turn = try c.decodeIfPresent(DiceTurn.self, forKey: .turn) ?? DiceTurn(count: settings.rules.diceCount)
        offer = try c.decodeIfPresent(InheritOffer.self, forKey: .offer)
        log = try c.decodeIfPresent([TurnRecord].self, forKey: .log) ?? []
        timeline = try c.decodeIfPresent([[Int]].self, forKey: .timeline) ?? [players.map { _ in 0 }]
        if let winners = try c.decodeIfPresent([Int].self, forKey: .winners) {
            self.winners = winners
        } else {
            winners = (try c.decodeIfPresent(Int.self, forKey: .winner)).map { [$0] } ?? []
        }
        tiebreak = try c.decodeIfPresent(Tiebreak.self, forKey: .tiebreak)
        finalRoundFrom = try c.decodeIfPresent(Int.self, forKey: .finalRoundFrom)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(players, forKey: .players)
        try c.encode(settings, forKey: .settings)
        try c.encode(current, forKey: .current)
        try c.encode(turn, forKey: .turn)
        try c.encodeIfPresent(offer, forKey: .offer)
        try c.encode(log, forKey: .log)
        try c.encode(timeline, forKey: .timeline)
        try c.encode(winners, forKey: .winners)
        try c.encodeIfPresent(tiebreak, forKey: .tiebreak)
        try c.encodeIfPresent(finalRoundFrom, forKey: .finalRoundFrom)
    }
}

/// Ein gespeichertes Spiel (laufend/pausiert oder beendet).
nonisolated struct GameRecord: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    /// Eigener Name; `nil` = automatisch aus den Spielernamen
    var name: String?
    var createdAt: Date
    var updatedAt: Date
    var state: GameState

    var displayName: String {
        if let name, !name.trimmingCharacters(in: .whitespaces).isEmpty { return name }
        return state.players.map(\.name).joined(separator: ", ")
    }
}

/// Ein Spielzug als Aktion – lokal wie später online (Doku/MEHRSPIELER-PLAN.md, Abschnitt 5).
/// `keep` = Positionen der Würfel, die aus dem aktuellen Wurf jetzt rausgelegt werden.
nonisolated enum GameAction: Codable, Equatable, Sendable {
    /// Rauslegen und weiterwürfeln (erster Wurf: `keep` leer). Digital würfelt die App.
    case roll(keep: [Int])
    /// Echte Würfel, Augen-Eingabe: rauslegen und die neu geworfenen Augen eintragen.
    case enterThrow(keep: [Int], dice: [Int])
    /// Rauslegen und aufhören – Punkte gutschreiben.
    case bank(keep: [Int])
    case acceptOffer
    case declineOffer
    /// Echte Würfel, „rausgelegte Würfel eingeben“: Augen der Würfel, die aus dem aktuellen
    /// Wurf rausgelegt werden. `bank` = danach aufhören, sonst weiterwürfeln.
    case layOut(dice: [Int], bank: Bool)
    /// Echte Würfel, Punkte-Eingabe. `leaveOpen` = so viele Würfel bleiben für die nächste
    /// Person liegen (0 = kein Angebot; Doku/SPEC-1.0.1-B.md §1)
    case points(Int, leaveOpen: Int = 0)
    case noPoints
    case undo
}

/// Flaches JSON mit `type` (Entscheidung D13), z. B. `{"type":"roll","keep":[0,2]}`
/// oder `{"type":"points","points":450}` – so wie Server und Regel-Engine es erwarten.
nonisolated extension GameAction {
    private enum CodingKeys: String, CodingKey { case type, keep, dice, points, bank, leaveOpen }

    private enum Kind: String, Codable {
        case roll, enterThrow, bank, layOut, acceptOffer, declineOffer, points, noPoints, undo
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .type) {
        case .roll: self = .roll(keep: try c.decodeIfPresent([Int].self, forKey: .keep) ?? [])
        case .enterThrow:
            self = .enterThrow(keep: try c.decodeIfPresent([Int].self, forKey: .keep) ?? [],
                               dice: try c.decode([Int].self, forKey: .dice))
        case .bank: self = .bank(keep: try c.decodeIfPresent([Int].self, forKey: .keep) ?? [])
        case .layOut:
            self = .layOut(dice: try c.decode([Int].self, forKey: .dice),
                           bank: try c.decodeIfPresent(Bool.self, forKey: .bank) ?? false)
        case .acceptOffer: self = .acceptOffer
        case .declineOffer: self = .declineOffer
        case .points:
            self = .points(try c.decode(Int.self, forKey: .points),
                           leaveOpen: try c.decodeIfPresent(Int.self, forKey: .leaveOpen) ?? 0)
        case .noPoints: self = .noPoints
        case .undo: self = .undo
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .roll(let keep):
            try c.encode(Kind.roll, forKey: .type)
            try c.encode(keep, forKey: .keep)
        case .enterThrow(let keep, let dice):
            try c.encode(Kind.enterThrow, forKey: .type)
            try c.encode(keep, forKey: .keep)
            try c.encode(dice, forKey: .dice)
        case .bank(let keep):
            try c.encode(Kind.bank, forKey: .type)
            try c.encode(keep, forKey: .keep)
        case .layOut(let dice, let bank):
            try c.encode(Kind.layOut, forKey: .type)
            try c.encode(dice, forKey: .dice)
            try c.encode(bank, forKey: .bank)
        case .acceptOffer: try c.encode(Kind.acceptOffer, forKey: .type)
        case .declineOffer: try c.encode(Kind.declineOffer, forKey: .type)
        case .points(let points, let leaveOpen):
            try c.encode(Kind.points, forKey: .type)
            try c.encode(points, forKey: .points)
            // Nur wenn gesetzt – so bleibt das JSON wie in 1.0
            if leaveOpen != 0 { try c.encode(leaveOpen, forKey: .leaveOpen) }
        case .noPoints: try c.encode(Kind.noPoints, forKey: .type)
        case .undo: try c.encode(Kind.undo, forKey: .type)
        }
    }
}

