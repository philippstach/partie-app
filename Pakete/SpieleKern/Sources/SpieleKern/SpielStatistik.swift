// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Statistik eines einzelnen Spiels für „Ich“ (L17): Ausgang jeder Partie, Serien, Rekord, Zeiten und die letzten Partien.
/// Sie nutzt dieselben Regeln wie `StatistikDienst.bilanz` (Remis ist kein Sieg und reißt die Serie, Punktespiele ohne Wertung
/// zählen als Partie, aber weder als Sieg noch als Niederlage).
public struct SpielStatistik: Equatable, Sendable {
    public var partien = 0
    public var siege = 0
    public var niederlagen = 0
    public var remis = 0
    /// Punktespiele (Arcade) ohne Wertung: zählen als Partie, aber nicht als Sieg oder Niederlage.
    public var ohneWertung = 0
    public var serie = 0
    public var besteSerie = 0
    public var rekord: Int?
    public var durchschnittPunkte: Int?
    /// Längster Ballwechsel (Duelle); `nil`, wenn keine Kennzahl „rallye“ gemeldet wurde.
    public var rallye: Int?
    public var dauer: TimeInterval = 0
    public var letzteDatum: Date?
    /// Die jüngsten Partien, neueste zuerst.
    public var letzte: [PartieErgebnis] = []

    /// Anteil gewonnener Partien an den gewerteten (ohne „ohne Wertung“); 0 bei keiner gewerteten Partie.
    public var siegquote: Double { let g = partien - ohneWertung; return g <= 0 ? 0 : Double(siege) / Double(g) }
    /// Punktespiel: keine Partie mit Sieg oder Niederlage, aber Partien mit Punkten.
    public var istPunktespiel: Bool { ohneWertung > 0 && siege + niederlagen + remis == 0 }
    /// Durchschnittliche Dauer einer Partie mit gemeldeter Dauer; 0 ohne Zeitangaben.
    public var dauerSchnitt: TimeInterval { zeitPartien == 0 ? 0 : dauer / Double(zeitPartien) }
    public internal(set) var zeitPartien = 0
    /// Bilanz je Stufe, aufsteigend nach Stufe; nur Stufen mit mindestens einer Partie. Leer, wenn das Spiel keine Kennzahl „stufe“ meldet.
    public var stufen: [StufenBilanz] = []
    /// Gelöste Tagesrätsel (Partien mit Kennzahl „tages“).
    public var tagesGeloest = 0
}

/// Bilanz einer Stufe eines Spiels (Rätsel mit Leicht/Mittel/Schwer): gespielt, gewonnen, Bestzeit und beste Siegesserie.
public struct StufenBilanz: Equatable, Sendable, Identifiable {
    /// Stufe, wie das Spiel sie meldet (0 = leichteste).
    public var stufe: Int
    public var id: Int { stufe }
    public var partien = 0
    public var siege = 0
    public var serie = 0
    public var besteSerie = 0
    /// Kürzeste Dauer einer gewonnenen Partie mit gemeldeter Dauer.
    public var besteZeit: TimeInterval?
}

extension StufenBilanz {
    /// Bilanz je Stufe aus den Partien eines Spiels in zeitlicher Reihenfolge. `gewonnen` entscheidet je Partie über Sieg oder nicht
    /// (dieselbe Regel wie in `spielStatistik`). Tagesrätsel (Kennzahl „tages“) und Partien ohne Kennzahl „stufe“ zählen bei keiner Stufe.
    static func aus(_ partien: [PartieErgebnis], gewonnen: (PartieErgebnis) -> Bool) -> [StufenBilanz] {
        var je: [Int: StufenBilanz] = [:]
        for e in partien {
            guard e.kennzahlen["tages"] == nil, let wert = e.kennzahlen["stufe"] else { continue }
            let stufe = Kennzahl.ganz(wert)
            var b = je[stufe] ?? StufenBilanz(stufe: stufe)
            b.partien += 1
            if gewonnen(e) {
                b.siege += 1; b.serie += 1; b.besteSerie = max(b.besteSerie, b.serie)
                if e.dauer > 0 { b.besteZeit = min(b.besteZeit ?? e.dauer, e.dauer) }
            } else if !(e.teilnehmer.count == 1 && e.teilnehmer[0].platz == 0) {
                b.serie = 0   // Punktespiel ohne Wertung unterbricht die Serie nicht (wie in `bilanz`)
            }
            je[stufe] = b
        }
        return je.values.sorted { $0.stufe < $1.stufe }
    }
}

extension StatistikDienst {
    /// Alle Zahlen für die Statistik-Seite eines Spiels. `ich`: Partien dieser Person (siehe `bilanz`); ohne `ich` zählt nur,
    /// was ohne Zuordnung eindeutig ist (Einzelspiele) – Mehrspielerpartien sind dann nie ein Sieg.
    public func spielStatistik(spiel: String, ich: UUID? = nil, letzte maximum: Int = 10) -> SpielStatistik {
        var s = SpielStatistik()
        let b = bilanz(spiel: spiel, ich: ich)
        s.partien = b.partien; s.siege = b.siege; s.serie = b.serie; s.besteSerie = b.besteSerie; s.rekord = b.rekord
        var punkte: [Int] = []
        var passend: [PartieErgebnis] = []
        // Sieg für die Aufteilung in Niederlage/Remis und für die Stufen: mit `ich` der eigene erste Platz ohne Remis, sonst der Einzelsieg.
        // Eine gewonnene Einzelpartie ohne Personenzuordnung zählt für „Ich“ als Sieg (wie in `bilanz`, Fund C-010).
        func sieg(_ e: PartieErgebnis) -> Bool {
            let einzelsieg = e.teilnehmer.count == 1 && e.teilnehmer[0].platz == 1
            guard let ich else { return einzelsieg }
            return (!e.istRemis && e.teilnehmer.contains { $0.platz == 1 && $0.spielerID == ich }) || (einzelsieg && e.teilnehmer[0].spielerID == nil)
        }
        for e in ereignisse where e.spiel == spiel {
            if let ich, !(e.teilnehmer.contains { $0.spielerID == ich } || !e.teilnehmer.contains { $0.spielerID != nil }) { continue }
            passend.append(e)
            s.dauer += e.dauer
            if e.dauer > 0 { s.zeitPartien += 1 }
            let punktespiel = e.teilnehmer.count == 1 && e.teilnehmer[0].platz == 0
            let gewonnen: Bool
            gewonnen = sieg(e)
            if punktespiel { s.ohneWertung += 1 }
            else if gewonnen { }
            else if e.istRemis { s.remis += 1 }
            else { s.niederlagen += 1 }
            if let p = e.teilnehmer.compactMap(\.punkte).max(), punktespiel { punkte.append(p) }
            if let r = e.kennzahlen["rallye"] { s.rallye = max(s.rallye ?? 0, Int(r)) }
        }
        if !punkte.isEmpty { s.durchschnittPunkte = Int((Double(punkte.reduce(0, +)) / Double(punkte.count)).rounded()) }
        s.stufen = StufenBilanz.aus(passend, gewonnen: sieg)
        s.tagesGeloest = passend.filter { $0.kennzahlen["tages"] != nil && sieg($0) }.count
        s.letzteDatum = passend.map(\.datum).max()
        s.letzte = Array(passend.sorted { $0.datum > $1.datum }.prefix(maximum))
        return s
    }
}
