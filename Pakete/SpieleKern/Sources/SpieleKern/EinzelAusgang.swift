// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import ArcadeKern

/// Ausgang eines Einzelspiels (genau ein Name in `SpielEnde.reihenfolge`, kein Arcade-Ausgang).
/// Bei mehreren Namen und bei Arcade-Spielen (`SpielEnde.arcade`) hat der Wert keine Wirkung.
public enum EinzelAusgang: Equatable, Sendable {
    /// Wie bisher: Platz 1, „Geschafft!“, zählt als Sieg.
    case gewonnen
    /// Niederlage: Platz 2, „Verloren“, kein Sieg, die Siegesserie endet, keine Bestzeit im Game Center.
    case verloren
    /// Punktespiel ohne Sieg oder Niederlage: Platz 0 (ohne Wertung), „Partie beendet“ bzw. „Neuer Rekord!“,
    /// zählt als Partie, nie als Sieg und unterbricht die Serie nicht. Die Punkte gehen in Bestwert und Bestenliste.
    case punkte
}

/// Reine Entscheidungslogik des Rahmens am Ende einer Partie: Was wird verbucht, was steht auf dem Ende-Bildschirm.
/// Ohne Oberfläche, damit sie mit `swift test` geprüft werden kann.
public enum EndeBuchung {
    /// Überschrift des Ende-Bildschirms (ohne Arcade).
    public enum Titel: Equatable, Sendable { case sieger(String), remis, geschafft, verloren, beendet, neuerRekord }

    /// Punkte aus dem Anzeigetext eines Spiels („1.250“, „−3“, „12 Punkte“); `nil`, wenn keine Zahl darin steht.
    public static func zahl(_ text: String) -> Int? {
        // C-026: Dezimalkomma mit ein oder zwei Nachkommastellen („92,5“) ist keine Tausenderzahl: runden statt Ziffern verketten
        if let r = text.range(of: #"\d+,\d{1,2}(?!\d)"#, options: .regularExpression),
           let d = Double(text[r].replacingOccurrences(of: ",", with: ".")) {
            return Int(d.rounded()) * (text[..<r.lowerBound].last.map { $0 == "-" || $0 == "−" } == true ? -1 : 1)
        }
        return Int(text.filter { $0.isNumber || $0 == "-" || $0 == "−" }.replacingOccurrences(of: "−", with: "-"))
    }

    /// Platz des Namens an Stelle `i` (F4): der gemeldete Platz, wenn `plaetze` so weit reicht, sonst `i + 1`.
    /// Meldet ein Spiel weniger Plätze als Namen, stürzt nichts ab; die übrigen stehen in Meldereihenfolge dahinter.
    public static func platz(_ plaetze: [Int]?, _ i: Int) -> Int {
        if let p = plaetze, p.indices.contains(i) { return p[i] }
        return i + 1
    }

    /// Alle Plätze in voller Länge (`anzahl` Namen), siehe `platz`.
    public static func plaetze(_ plaetze: [Int]?, anzahl: Int) -> [Int] { (0..<max(anzahl, 0)).map { platz(plaetze, $0) } }

    /// Greift der Einzel-Ausgang? Nur bei genau einem Namen.
    public static func einzelGilt(_ reihenfolge: [String]) -> Bool { reihenfolge.count == 1 }

    /// Teilnehmer für die Statistik. Mehrere Namen: Plätze aus `plaetze`, sonst 1, 2, 3 …
    /// Ein Name: `einzel` entscheidet (gewonnen = gemeldeter Platz bzw. 1, verloren = 2, punkte = 0).
    public static func teilnehmer(reihenfolge: [String], punkte: [Int?] = [], plaetze: [Int]? = nil, einzel: EinzelAusgang = .gewonnen) -> [PartieErgebnis.Teilnehmer] {
        reihenfolge.enumerated().map { i, n in
            var platz = Self.platz(plaetze, i)
            if einzelGilt(reihenfolge) {
                switch einzel {
                case .gewonnen: break
                case .verloren: platz = 2
                case .punkte: platz = 0
                }
            }
            return PartieErgebnis.Teilnehmer(name: n, platz: platz, punkte: i < punkte.count ? punkte[i] : nil)
        }
    }

    /// Neuer Bestwert im Punktespiel? Nur mit `einzel == .punkte`, einer Zahl in den Punkten und mehr als bisher.
    public static func neuerRekord(reihenfolge: [String], punkte: [String], einzel: EinzelAusgang, bisher: Int?) -> Bool {
        guard einzelGilt(reihenfolge), einzel == .punkte, let p = punkte.first.flatMap(zahl) else { return false }
        return Rekord.istNeu(punkte: p, bisher: bisher)
    }

    /// Überschrift: Mehrspieler wie bisher (Sieger oder Remis), Einzelspiel nach `einzel`.
    public static func titel(reihenfolge: [String], remis: Bool, einzel: EinzelAusgang = .gewonnen, neuerRekord: Bool = false) -> Titel {
        if remis { return .remis }
        if reihenfolge.count > 1 { return .sieger(reihenfolge[0]) }
        guard einzelGilt(reihenfolge) else { return .geschafft }
        switch einzel {
        case .gewonnen: return .geschafft
        case .verloren: return .verloren
        case .punkte: return neuerRekord ? .neuerRekord : .beendet
        }
    }
}
