// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Observation

/// Ergebnis einer beendeten Partie (Konzept 4, gemeinsames Ende jeder Partie).
public struct PartieErgebnis: Identifiable, Codable, Equatable, Sendable {
    public struct Teilnehmer: Codable, Equatable, Sendable {
        public var spielerID: UUID?
        public var name: String
        public var platz: Int          // 1 = Sieger
        public var punkte: Int?
        public init(spielerID: UUID? = nil, name: String, platz: Int, punkte: Int? = nil) {
            self.spielerID = spielerID; self.name = name; self.platz = platz; self.punkte = punkte
        }
    }
    public var id: UUID
    public var spiel: String
    public var datum: Date
    public var dauer: TimeInterval
    public var teilnehmer: [Teilnehmer]
    public var kennzahlen: [String: Double]

    /// Remis: mindestens zwei Teilnehmer und alle auf Platz 1. Die Partie zählt, einen Sieg gibt es nicht.
    /// (Liegen nur einige gleichauf vorn, bleibt es für sie ein Sieg.)
    public var istRemis: Bool { Remis.gilt(plaetze: teilnehmer.map(\.platz)) }

    /// Abgebrochene Mehrpersonen-Partie: mehr als ein Teilnehmer, niemand auf Platz 1, kein Punktespiel (Platz 0).
    public var istAbbruch: Bool { teilnehmer.count > 1 && !teilnehmer.contains { $0.platz <= 1 } }

    /// Ergebnis als Text für Verlauf und VoiceOver. `sprechend` ersetzt den Pokal durch das Wort „Sieger“ (Emojis lesen Sprachausgaben
    /// vor, z. B. „Pokal“). Einzelspiele: gewonnen/verloren/Punkte; Remis und Abbruch werden benannt.
    public func ergebnisText(ichName: String, sprechend: Bool = false) -> String {
        let t = teilnehmer.sorted { $0.platz < $1.platz }
        if t.count == 1, let e = t.first {
            if e.platz == 0, let p = e.punkte { return String(localized: "\(p) Punkte") }
            if e.platz == 0 { return String(localized: "gespielt") }   // Punktespiel ohne Punktangabe: weder gewonnen noch verloren
            return e.platz == 1 ? String(localized: "gewonnen") : String(localized: "verloren")
        }
        let namen = t.map { x -> String in
            let n = x.name.isEmpty ? ichName : x.name
            guard x.platz == 1, !istRemis else { return n }
            return sprechend ? String(localized: "Sieger: \(n)") : "🏆 \(n)"
        }.joined(separator: " · ")
        if istRemis { return String(localized: "Remis") + ": " + namen }
        if istAbbruch { return String(localized: "Abgebrochen") + ": " + namen }
        return namen
    }

    public init(id: UUID = UUID(), spiel: String, datum: Date = Date(), dauer: TimeInterval = 0, teilnehmer: [Teilnehmer], kennzahlen: [String: Double] = [:]) {
        self.id = id; self.spiel = spiel; self.datum = datum; self.teilnehmer = teilnehmer
        // Nicht endliche Zahlen (NaN, unendlich) lassen das Kodieren scheitern: gar nicht erst aufnehmen
        self.dauer = Kennzahl.dauer(dauer); self.kennzahlen = Kennzahl.endlich(kennzahlen)
    }

    /// Dieselbe Partie ohne nicht endliche Zahlen (falls Felder nach dem Anlegen geändert wurden).
    public var bereinigt: PartieErgebnis {
        var e = self; e.dauer = Kennzahl.dauer(dauer); e.kennzahlen = Kennzahl.endlich(kennzahlen); return e
    }
}

/// Zahlen aus den Spielen gefahrlos verbuchen: NaN und unendlich lassen `JSONEncoder` scheitern und `Int(...)` abstürzen.
public enum Kennzahl {
    /// Nur endliche Werte bleiben.
    public static func endlich(_ k: [String: Double]) -> [String: Double] { k.filter { $0.value.isFinite } }
    /// Dauer in Sekunden: nicht endlich oder negativ wird 0.
    public static func dauer(_ d: TimeInterval) -> TimeInterval { d.isFinite && d >= 0 ? d : 0 }
    /// Ganze Zahl ohne Absturz: nicht endlich → `ersatz`, sonst auf den Bereich von `Int32` begrenzt.
    public static func ganz(_ d: Double?, ersatz: Int = 0) -> Int {
        guard let d, d.isFinite else { return ersatz }
        return Int(min(max(d, Double(Int32.min)), Double(Int32.max)))
    }
}

/// Die eine Remis-Regel für Statistik, Ende-Bildschirm und Teilen-Text: mindestens zwei Teilnehmer, alle auf Platz 1.
/// Fehlende Plätze (nil, also 1, 2, 3 …) sind nie ein Remis.
public enum Remis {
    public static func gilt(plaetze: [Int]?) -> Bool { guard let p = plaetze else { return false }; return p.count > 1 && p.allSatisfy { $0 == 1 } }
}

/// Zusammenfassung für Anzeige.
public struct StatistikSumme: Equatable, Sendable {
    public var partien = 0
    public var siege = 0
    public var dauer: TimeInterval = 0
}

/// Einheitliche Kennzahlen eines Spiels (Rätsel, Wort, Arcade und alle anderen): gespielt, gewonnen, Serie, Bestwert.
public struct SpielBilanz: Equatable, Sendable {
    public var partien = 0
    public var siege = 0
    /// Aktuelle Siegesserie (Partien in Folge gewonnen, bis zur letzten Partie).
    public var serie = 0
    public var besteSerie = 0
    /// Höchste Punktzahl; `nil`, wenn das Spiel keine Punkte meldet.
    public var rekord: Int?
    public var siegquote: Double { partien == 0 ? 0 : Double(siege) / Double(partien) }
}

/// Ereignisspeicher: alle Partien, daraus Statistik je Spiel, je Spieler, gesamt.
@Observable
@MainActor
public final class StatistikDienst {
    public private(set) var ereignisse: [PartieErgebnis] = []
    private let ablage: SpielAblageProtokoll

    public init(ablage: SpielAblageProtokoll = DefaultsAblageDaten(schluessel: "partie.statistik")) {
        self.ablage = ablage
        if let d = ablage.lesen(), let l = Verlustfrei.lesen([PartieErgebnis].self, aus: d) { ereignisse = l }
    }

    public func melden(_ e: PartieErgebnis) {
        guard !ereignisse.contains(where: { $0.id == e.id }) else { return }
        ereignisse.append(e.bereinigt)
        Verlustfrei.schreiben(ereignisse, in: ablage)
    }

    /// Fügt Partien aus einer Sicherung hinzu, die es noch nicht gibt (nach ID). `ids` legt Personen-IDs der Sicherung auf vorhandene um.
    /// Die Reihenfolge nach Datum bleibt erhalten. Gibt die Zahl der neuen Partien zurück.
    @discardableResult
    public func uebernehmen(_ partien: [PartieErgebnis], ids: [UUID: UUID] = [:]) -> Int {
        let vorhanden = Set(ereignisse.map(\.id))
        var neu: [PartieErgebnis] = []
        for var e in partien where !vorhanden.contains(e.id) {
            for i in e.teilnehmer.indices { if let id = e.teilnehmer[i].spielerID, let ziel = ids[id] { e.teilnehmer[i].spielerID = ziel } }
            neu.append(e.bereinigt)
        }
        guard !neu.isEmpty else { return 0 }
        ereignisse = (ereignisse + neu).enumerated().sorted { ($0.element.datum, $0.offset) < ($1.element.datum, $1.offset) }.map(\.element)
        Verlustfrei.schreiben(ereignisse, in: ablage)
        return neu.count
    }

    public func zuruecksetzen() { ereignisse = []; try? ablage.schreiben(nil) }

    /// Gehört die Partie zu „Ich“? Ja, wenn `ich` unter den Teilnehmern steht oder gar kein Teilnehmer einer Person zugeordnet ist
    /// (alte Partien vor dem Verzeichnis). Partien anderer Personen (auch gelöschter) zählen nicht für „Ich“.
    private func gehoertZu(_ e: PartieErgebnis, ich: UUID) -> Bool {
        e.teilnehmer.contains { $0.spielerID == ich } || !e.teilnehmer.contains { $0.spielerID != nil }
    }

    /// Einzelpartie ohne Personenzuordnung (gespielt, bevor es ein Profil gab), die gewonnen wurde. Zählt für „Ich“ als Sieg (Fund C-010).
    private func unzugeordneterEinzelsieg(_ e: PartieErgebnis) -> Bool {
        e.teilnehmer.count == 1 && e.teilnehmer[0].spielerID == nil && e.teilnehmer[0].platz == 1
    }

    /// `spieler`: Zahlen dieser Person. Ohne `spieler`: alle Partien; „Siege“ zählt dann nur Partien, die `ich` gewonnen hat
    /// (ohne `ich`: Partien mit einem Sieger – nur sinnvoll für Einzelspiele).
    public func summe(spiel: String? = nil, spieler: UUID? = nil, ich: UUID? = nil) -> StatistikSumme {
        var s = StatistikSumme()
        for e in ereignisse where spiel == nil || e.spiel == spiel {
            if let spieler {
                // Steht eine Person mehrfach in der Partie (doppelt gewählt), zählt sie einmal mit ihrem besten Platz.
                let plaetze = e.teilnehmer.filter { $0.spielerID == spieler }.map(\.platz)
                guard !plaetze.isEmpty else { continue }
                s.partien += 1; if plaetze.contains(1), !e.istRemis { s.siege += 1 }
            } else {
                if let ich, !gehoertZu(e, ich: ich) { continue }
                s.partien += 1
                if let ich { if (!e.istRemis && e.teilnehmer.contains(where: { $0.platz == 1 && $0.spielerID == ich })) || unzugeordneterEinzelsieg(e) { s.siege += 1 } }
                else if e.teilnehmer.count == 1 ? e.teilnehmer[0].platz == 1 : false { s.siege += 1 }
            }
            s.dauer += e.dauer
        }
        return s
    }

    /// Alle Kennzahlen eines Spiels für `ich` (ohne `ich`: Einzelspiel-Wertung wie in `summe`). Punktespiele ohne Wertung (Platz 0) zählen als Partie, aber nie als Sieg und unterbrechen die Serie nicht.
    public func bilanz(spiel: String, ich: UUID? = nil) -> SpielBilanz {
        var b = SpielBilanz()
        var punkte: [Int] = []
        for e in ereignisse where e.spiel == spiel {
            if let ich, !gehoertZu(e, ich: ich) { continue }
            // Bestwert nur aus den eigenen Punkten (bei zugeordneten Partien), nicht aus denen der Gegner
            if let ich, e.teilnehmer.contains(where: { $0.spielerID == ich }) { punkte += e.teilnehmer.filter { $0.spielerID == ich }.compactMap(\.punkte) }
            else { punkte += e.teilnehmer.compactMap(\.punkte) }
            b.partien += 1
            let punktespiel = e.teilnehmer.count == 1 && e.teilnehmer[0].platz == 0
            let gewonnen: Bool
            if let ich { gewonnen = (!e.istRemis && e.teilnehmer.contains { $0.platz == 1 && $0.spielerID == ich }) || unzugeordneterEinzelsieg(e) }
            else { gewonnen = e.teilnehmer.count == 1 && e.teilnehmer[0].platz == 1 }
            if gewonnen { b.siege += 1; b.serie += 1; b.besteSerie = max(b.besteSerie, b.serie) }
            else if !punktespiel { b.serie = 0 }
        }
        b.rekord = punkte.max()
        return b
    }

    /// Rekord je Stufe (Arcade): Ein Rekord auf „Leicht“ verdrängt keinen auf „Schwer“. Alte Partien ohne Stufenangabe
    /// stammen aus der Zeit vor den Stufen und zählen als „Mittel“ (2).
    public func rekord(spiel: String, stufe: Int) -> Int? {
        ereignisse.filter { $0.spiel == spiel && Kennzahl.ganz($0.kennzahlen["stufe"], ersatz: 2) == stufe }.flatMap { $0.teilnehmer.compactMap(\.punkte) }.max()
    }

    /// Durchschnitt je Stufe, siehe `rekord(spiel:stufe:)`.
    public func durchschnitt(spiel: String, stufe: Int) -> Int? {
        let werte = ereignisse.filter { $0.spiel == spiel && Kennzahl.ganz($0.kennzahlen["stufe"], ersatz: 2) == stufe }.compactMap { $0.teilnehmer.compactMap(\.punkte).max() }
        guard !werte.isEmpty else { return nil }
        return Int((Double(werte.reduce(0, +)) / Double(werte.count)).rounded())
    }

    /// Höchste je erreichte Punktzahl in diesem Spiel (Arcade-Rekord); `nil`, wenn es noch keine Wertung gibt.
    /// C-018: Bei Spielen, in denen der Sieger die wenigsten Punkte hat (Strafpunkte), ist die beste Leistung der niedrigste
    /// Siegerwert, nicht der höchste Wert aller Teilnehmer. Erkannt wird das daran, dass in einer Partie der Sieger weniger
    /// Punkte hat als ein anderer Teilnehmer.
    public func rekord(spiel: String) -> Int? {
        let partien = ereignisse.filter { $0.spiel == spiel }
        let niedrigIstBesser = partien.contains { e in
            guard e.teilnehmer.count > 1, !e.istRemis else { return false }
            let sieger = e.teilnehmer.filter { $0.platz == 1 }.compactMap(\.punkte)
            let andere = e.teilnehmer.filter { $0.platz > 1 }.compactMap(\.punkte)
            guard let w = sieger.min() else { return false }
            return andere.contains { $0 > w }
        }
        if niedrigIstBesser {
            return partien.flatMap { $0.teilnehmer.filter { $0.platz == 1 }.compactMap(\.punkte) }.min()
        }
        return partien.flatMap { $0.teilnehmer.compactMap(\.punkte) }.max()
    }

    /// Längster Ballwechsel (Duelle): größte gemeldete Kennzahl „rallye“; `nil`, wenn keine gemeldet wurde.
    public func besteRallye(spiel: String) -> Int? {
        ereignisse.filter { $0.spiel == spiel }.compactMap { $0.kennzahlen["rallye"] }.filter(\.isFinite).max().map { Kennzahl.ganz($0) }
    }

    /// Durchschnittliche Punktzahl je Partie (Arcade): je Partie zählt der höchste gemeldete Wert; `nil` ohne Wertung.
    public func durchschnitt(spiel: String) -> Int? {
        let werte = ereignisse.filter { $0.spiel == spiel }.compactMap { $0.teilnehmer.compactMap(\.punkte).max() }
        guard !werte.isEmpty else { return nil }
        return Int((Double(werte.reduce(0, +)) / Double(werte.count)).rounded())
    }

    /// Serie zwischen Spielern: Siege je Name über alle Spiele, in denen alle genannten mitspielten.
    public func serie(zwischen ids: [UUID]) -> [(UUID, Int)] {
        let passend = ereignisse.filter { e in ids.allSatisfy { id in e.teilnehmer.contains { $0.spielerID == id } } }
        return ids.map { id in (id, passend.filter { !$0.istRemis && $0.teilnehmer.contains { $0.platz == 1 && $0.spielerID == id } }.count) }
    }

    /// Duell zweier Personen über alle Partien, in denen beide mitspielten. Wer den besseren (kleineren) Platz hat, gewinnt das Duell;
    /// gleicher Platz (auch Remis oder gemeinsam abgebrochen) zählt als unentschieden.
    public struct Duell: Equatable, Sendable {
        public var partien = 0, siege = 0, niederlagen = 0, unentschieden = 0
    }
    public func duell(_ a: UUID, gegen b: UUID) -> Duell {
        var d = Duell()
        for e in ereignisse {
            let pa = e.teilnehmer.filter { $0.spielerID == a }.map(\.platz).min()
            let pb = e.teilnehmer.filter { $0.spielerID == b }.map(\.platz).min()
            guard let pa, let pb else { continue }
            d.partien += 1
            if pa < pb { d.siege += 1 } else if pa > pb { d.niederlagen += 1 } else { d.unentschieden += 1 }
        }
        return d
    }

    public func csv() -> String {
        var z = ["datum,spiel,dauer,spieler,platz,punkte"]
        let f = ISO8601DateFormatter()
        for e in ereignisse { for t in e.teilnehmer { z.append("\(f.string(from: e.datum)),\(Self.csvFeld(e.spiel)),\(Kennzahl.ganz(e.dauer)),\(Self.csvFeld(t.name)),\(t.platz),\(t.punkte.map(String.init) ?? "")") } }
        return z.joined(separator: "\n")
    }

    /// C-015: Feld nach RFC 4180 einfassen; führende = + - @ werden entschärft, damit Tabellenprogramme sie nicht als Formel lesen.
    static func csvFeld(_ text: String) -> String {
        var t = text
        if let c = t.first, "=+-@\t\r".contains(c) { t = "'" + t }
        guard t.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else { return t }
        return "\"" + t.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// Ausdrückliche Meldung eines Spiels im `SpielRahmen`: „Es wurde mindestens ein Zug gemacht.“ Die Partie gilt damit sofort als
/// begonnen (sonst erst nach `AbbruchWertung.mindestSpielzeit`). Ob „Beenden“ dann als Niederlage zählt, entscheidet die Einstellung
/// „Partie abbrechen“ (`AbbruchWertung`). Der Rahmen setzt die Meldung bei jedem Start und Fortsetzen zurück.
@MainActor
public enum SpielZug {
    private static var gemeldet: Set<String> = []
    /// Das Spiel ruft das nach dem ersten echten Zug des Spielers (nicht beim Austeilen oder Neustarten).
    public static func gemacht(_ spiel: String) { gemeldet.insert(spiel) }
    public static func hatZug(_ spiel: String) -> Bool { gemeldet.contains(spiel) }
    static func zuruecksetzen(_ spiel: String) { gemeldet.remove(spiel) }
}

/// Brücke zwischen den Spielen und der gemeinsamen Statistik: Das Spiel meldet, die Hülle verbucht (Konzept 4, `PartieErgebnis`).
public enum PartieMeldung {
    nonisolated(unsafe) public static var senke: (@MainActor (PartieErgebnis) -> Void)?
    /// C-012: Namen (klein geschrieben) der Computergegner der laufenden Partie. Sie werden nie einer Person im Spielerverzeichnis zugeordnet.
    nonisolated(unsafe) public static var computerNamen: Set<String> = []

    /// Mehrspielerspiel: `reihenfolge` = Namen vom Sieger bis zum Letzten (gleiche Plätze über `plaetze`).
    /// Ein einzelner Name: `einzel` legt fest, ob das ein Sieg (Standard), eine Niederlage oder ein Punktespiel ohne Wertung ist.
    public static func melden(spiel: String, reihenfolge: [String], punkte: [Int?] = [], plaetze: [Int]? = nil, dauer: TimeInterval = 0, kennzahlen: [String: Double] = [:], einzel: EinzelAusgang = .gewonnen) {
        let t = EndeBuchung.teilnehmer(reihenfolge: reihenfolge, punkte: punkte, plaetze: plaetze, einzel: einzel)
        let e = PartieErgebnis(spiel: spiel, dauer: dauer, teilnehmer: t, kennzahlen: kennzahlen)
        Task { @MainActor in senke?(e) }
    }

    /// Punktespiel (Arcade): zählt als Partie mit Punkten, aber ohne Sieg (Platz 0 = ohne Wertung).
    public static func punkte(spiel: String, name: String = "", punkte: Int, dauer: TimeInterval = 0, kennzahlen: [String: Double] = [:]) {
        let e = PartieErgebnis(spiel: spiel, dauer: dauer, teilnehmer: [.init(name: name, platz: 0, punkte: punkte)], kennzahlen: kennzahlen)
        Task { @MainActor in senke?(e) }
    }

    /// Abgebrochene Partie (mindestens ein Zug gemacht): Alle Menschen verlieren, kein Mensch bekommt einen Sieg.
    /// Computer stehen vorn (Platz 1); gibt es keinen, teilen sich die Menschen Platz 2, damit es kein Remis wird.
    public static func abbruch(spiel: String, teilnehmer: [(name: String, computer: Bool)], dauer: TimeInterval = 0) -> PartieErgebnis? {
        guard !teilnehmer.filter({ !$0.computer }).isEmpty else { return nil }
        let t = teilnehmer.map { PartieErgebnis.Teilnehmer(name: $0.name, platz: $0.computer ? 1 : 2) }
        return PartieErgebnis(spiel: spiel, dauer: dauer, teilnehmer: t)
    }

    /// Die Buchung für „Beenden“ mitten in der Partie nach der Einstellung „Partie abbrechen“ (`AbbruchWertung`, Standard: nie).
    /// Gebucht wird nur eine begonnene Partie (`AbbruchWertung.begonnen`) mit mindestens einem Menschen, nie im Kinder-Modus und
    /// nie in Arcade-Spielen. `.computer`: nur mit Computer am Tisch. `.immer`: auch unter Menschen und allein (allein = verloren, Platz 2).
    /// Genau dann zeigt der Rahmen auch den Hinweis „zählt als Niederlage“.
    public static func abbruchBuchung(begonnen: Bool, spiel: String, teilnehmer: [(name: String, computer: Bool)], dauer: TimeInterval = 0,
                                      wertung: AbbruchWertung = .gespeichert(),
                                      kinder: Bool = UserDefaults.standard.bool(forKey: AbbruchWertung.kinderSchluessel),
                                      arcade: Bool = false) -> PartieErgebnis? {
        let computer = teilnehmer.filter(\.computer).count
        guard wertung.bucht(begonnen: begonnen, menschen: teilnehmer.count - computer, computer: computer, kinder: kinder, arcade: arcade) else { return nil }
        return abbruch(spiel: spiel, teilnehmer: teilnehmer, dauer: dauer)
    }

    /// Einzelspiel: Ich gewinne oder verliere. Die Hülle setzt den Namen des Spielers „Ich“ ein.
    public static func einzel(spiel: String, gewonnen: Bool, dauer: TimeInterval = 0) {
        let e = PartieErgebnis(spiel: spiel, dauer: dauer, teilnehmer: [.init(name: "", platz: gewonnen ? 1 : 2)])
        Task { @MainActor in senke?(e) }
    }
}
