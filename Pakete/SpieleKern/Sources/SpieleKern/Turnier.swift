// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation

/// Spieleabend-Turnier (B1): mehrere Spiele nacheinander mit gemeinsamer Gesamtwertung.
/// Plätze zählen Punkte: Bei n Spielern gibt Platz 1 n Punkte, der Letzte einen; gleiche Plätze teilen sich dieselbe Punktzahl.
public struct Turnier: Codable, Equatable, Sendable {
    public struct Runde: Codable, Equatable, Sendable, Identifiable {
        public var id = UUID()
        public var spiel: String
        /// Ergebnisse dieser Runde: Name → Platz (nur gespielt, wenn gefüllt).
        public var plaetze: [String: Int]?
        public init(spiel: String) { self.spiel = spiel }
        public var gespielt: Bool { plaetze != nil }
    }
    public struct Stand: Equatable, Sendable, Identifiable {
        public var id: String { name }
        public let name: String
        public let punkte: Int
        public let siege: Int
        public let platz: Int
    }

    /// Spieleabend: Punkte nach Platz. Duell (zu zweit): Das n-te Spiel bringt dem Sieger n Punkte, ein Remis bringt niemandem etwas;
    /// wer nicht mehr einzuholen ist, hat vorzeitig gewonnen.
    public enum Art: String, Codable, Sendable { case abend, duell }
    public var art: Art = .abend
    public var datum = Date()
    public var spieler: [String]
    public var runden: [Runde]

    public init(spieler: [String], spiele: [String], art: Art = .abend) {
        self.spieler = spieler
        self.runden = spiele.map { Runde(spiel: $0) }
        self.art = art
    }

    enum CodingKeys: String, CodingKey { case art, datum, spieler, runden }
    public init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        art = try c.decodeIfPresent(Art.self, forKey: .art) ?? .abend
        datum = try c.decodeIfPresent(Date.self, forKey: .datum) ?? Date()
        spieler = try c.decode([String].self, forKey: .spieler)
        runden = try c.decode([Runde].self, forKey: .runden)
    }

    /// Wie viele Spiele ein Duell hat, höchstens (mehr als 15 wären zu lang).
    public static let duellGrenzen = 5...15

    /// Zufällige Auswahl ohne Wiederholung, solange der Vorrat reicht; danach wird aufgefüllt.
    public static func zufallsSpiele(aus vorrat: [String], anzahl: Int) -> [String] {
        guard !vorrat.isEmpty, anzahl > 0 else { return [] }
        var ergebnis: [String] = []
        while ergebnis.count < anzahl { ergebnis += vorrat.shuffled().prefix(anzahl - ergebnis.count) }
        return ergebnis
    }

    /// Punkte, die das Spiel an Stelle `index` (ab 0) im Duell bringt.
    public static func duellGewicht(_ index: Int) -> Int { index + 1 }

    /// Punkte, die im Duell noch zu holen sind.
    public var restPunkte: Int {
        runden.enumerated().filter { !$0.element.gespielt }.reduce(0) { $0 + Self.duellGewicht($1.offset) }
    }
    public var gesamtPunkte: Int { runden.indices.reduce(0) { $0 + Self.duellGewicht($1) } }

    /// Duell vorzeitig entschieden: Der Vorsprung ist größer als alles, was noch zu holen ist.
    public var vorzeitigEntschieden: Bool {
        guard art == .duell, naechsteRunde != nil else { return false }
        let p = rangliste.map(\.punkte).sorted(by: >)
        return p.count == 2 && p[0] - p[1] > restPunkte
    }

    public var naechsteRunde: Runde? { runden.first { !$0.gespielt } }
    public var fertig: Bool { !runden.isEmpty && (naechsteRunde == nil || vorzeitigEntschieden) }

    /// Verlauf für Diagramme: Punktestand jeder Person nach jedem gespielten Spiel (Spiel 0 = Start).
    public struct Verlaufspunkt: Equatable, Sendable, Identifiable {
        public var id: String { "\(name)|\(runde)" }
        public let name: String
        public let runde: Int
        public let punkte: Int
    }
    public var verlauf: [Verlaufspunkt] {
        var stand: [String: Int] = Dictionary(uniqueKeysWithValues: spieler.map { ($0, 0) })
        var ergebnis = spieler.map { Verlaufspunkt(name: $0, runde: 0, punkte: 0) }
        for (i, r) in runden.enumerated() {
            guard let p = r.plaetze else { continue }
            for (name, platz) in p { stand[name, default: 0] += punkteFuer(platz: platz, runde: i, plaetze: p) }
            let nr = ergebnis.last.map { $0.runde + 1 } ?? 1
            ergebnis += spieler.map { Verlaufspunkt(name: $0, runde: nr, punkte: stand[$0] ?? 0) }
        }
        return ergebnis
    }

    /// Punkte einer Person in Runde `runde` (ab 0) bei diesem Platz.
    func punkteFuer(platz: Int, runde: Int, plaetze: [String: Int]) -> Int {
        if art == .duell {
            let eindeutig = Set(plaetze.values).count > 1
            return platz == 1 && eindeutig ? Self.duellGewicht(runde) : 0
        }
        return Self.punkte(platz: platz, von: spieler.count)
    }

    public var gespielteRunden: Int { runden.filter(\.gespielt).count }

    /// Punkte für einen Platz bei `anzahl` Spielern (Platz ab 1; schlechter als der letzte Platz zählt einen Punkt).
    public static func punkte(platz: Int, von anzahl: Int) -> Int { max(1, anzahl - max(1, platz) + 1) }

    /// Verbucht eine beendete Partie auf die nächste Runde, wenn sie dasselbe Spiel ist, alle Turnierspieler mitspielten und die Partie
    /// kein Abbruch ist. Namen vergleichen ohne Groß-/Kleinschreibung. Gibt zurück, ob verbucht wurde.
    @discardableResult
    public mutating func buchen(spiel: String, teilnehmer: [(name: String, platz: Int)]) -> Bool {
        guard let i = runden.firstIndex(where: { !$0.gespielt }), runden[i].spiel == spiel else { return false }
        guard teilnehmer.contains(where: { $0.platz == 1 }) else { return false }   // Abbruch
        var plaetze: [String: Int] = [:]
        for s in spieler {
            guard let t = teilnehmer.filter({ $0.name.lowercased() == s.lowercased() }).map(\.platz).min() else { return false }
            plaetze[s] = t
        }
        runden[i].plaetze = plaetze
        return true
    }

    /// Runde ohne Wertung überspringen (z. B. weil ein Spiel nicht zustande kam): zählt für niemanden.
    public mutating func ueberspringen() {
        guard let i = runden.firstIndex(where: { !$0.gespielt }) else { return }
        runden[i].plaetze = [:]
    }

    /// Gesamtwertung, beste zuerst; Gleichstand nach Punkten teilt den Platz, dann zählen die Siege als Reihenfolge.
    public var rangliste: [Stand] {
        let n = spieler.count
        var punkte: [String: Int] = [:], siege: [String: Int] = [:]
        for (i, r) in runden.enumerated() {
            guard let p = r.plaetze else { continue }
            for (name, platz) in p {
                punkte[name, default: 0] += punkteFuer(platz: platz, runde: i, plaetze: p)
                if platz == 1, Set(p.values).count > 1 || n == 1 { siege[name, default: 0] += 1 }
            }
        }
        let sortiert = spieler.map { ($0, punkte[$0] ?? 0, siege[$0] ?? 0) }
            .sorted { ($0.1, $0.2) > ($1.1, $1.2) }
        var ergebnis: [Stand] = []
        for (i, s) in sortiert.enumerated() {
            let platz = (i > 0 && sortiert[i - 1].1 == s.1 && sortiert[i - 1].2 == s.2) ? ergebnis[i - 1].platz : i + 1
            ergebnis.append(Stand(name: s.0, punkte: s.1, siege: s.2, platz: platz))
        }
        return ergebnis
    }
}

/// Das laufende Turnier der App (höchstens eines), gespeichert in den Einstellungen.
@Observable
@MainActor
public final class TurnierDienst {
    public private(set) var aktuell: Turnier?
    private let defaults: UserDefaults
    private static let schluessel = "partie.turnier"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let d = defaults.data(forKey: Self.schluessel) { aktuell = try? JSONDecoder().decode(Turnier.self, from: d) }
    }

    public func starten(_ t: Turnier) { aktuell = t; sichern() }
    public func beenden() { aktuell = nil; sichern() }
    public func ueberspringen() { aktuell?.ueberspringen(); sichern() }

    /// Von der Hülle nach jeder verbuchten Partie gerufen. Gibt `true` zurück, wenn die Partie als Turnierrunde zählt.
    @discardableResult
    public func partieBeendet(_ e: PartieErgebnis) -> Bool {
        guard var t = aktuell else { return false }
        let ok = t.buchen(spiel: e.spiel, teilnehmer: e.teilnehmer.map { ($0.name, $0.platz) })
        if ok { aktuell = t; sichern() }
        return ok
    }

    private func sichern() {
        if let aktuell, let d = try? JSONEncoder().encode(aktuell) { defaults.set(d, forKey: Self.schluessel) }
        else { defaults.removeObject(forKey: Self.schluessel) }
    }
}
