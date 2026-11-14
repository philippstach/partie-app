// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Text, den „Teilen“ auf dem Ende-Bildschirm jedes Spiels weitergibt (Messenger, Notizen, Mail). Reine Textlogik, ohne UIKit.
public enum ErgebnisText {
    /// Für Spiele mit eigenem Ende-Bildschirm: Titel und Untertitel des Bildschirms als Ergebnis, z. B. „Viererreihe: Gewonnen! – 4 Steine“.
    public static func einfach(spiel: String, titel: String, untertitel: String = "") -> String {
        let ergebnis = untertitel.isEmpty ? titel : "\(titel) – \(untertitel)"
        return "\(spiel): \(ergebnis)\n" + String(localized: "Gespielt mit Partie")
    }

    /// - Parameters:
    ///   - spiel: Name des Spiels.
    ///   - reihenfolge: Namen vom Sieger zum Letzten.
    ///   - punkte: Punkte als Text je Platz (kann leer sein).
    ///   - plaetze: gleiche Plätze (z. B. `[1, 1, 3]`), sonst 1, 2, 3 …
    ///   - arcadePunkte: bei Punktespielen die erreichten Punkte; `arcadeSieg == nil` heißt Punktespiel.
    ///   - arcadeSieg: bei Duellen Sieg oder Niederlage.
    ///   - neuerRekord: nur für Punktespiele.
    ///   - einzel: bei genau einem Namen: gewonnen (Standard), verloren oder Punktespiel ohne Wertung.
    public static func text(spiel: String, reihenfolge: [String], punkte: [String] = [], plaetze: [Int]? = nil,
                            arcadePunkte: Int? = nil, arcadeSieg: Bool? = nil, neuerRekord: Bool = false, einzel: EinzelAusgang = .gewonnen) -> String {
        var zeilen: [String] = []
        if let p = arcadePunkte, arcadeSieg == nil {
            zeilen.append(neuerRekord ? String(localized: "\(spiel): Neuer Rekord mit \(p) Punkten!") : String(localized: "\(spiel): \(p) Punkte"))
        } else if arcadePunkte != nil, let sieg = arcadeSieg {
            zeilen.append(sieg ? String(localized: "\(spiel): Gewonnen!") : String(localized: "\(spiel): Verloren"))
        } else if reihenfolge.count > 1 {
            let remis = Remis.gilt(plaetze: plaetze.map { EndeBuchung.plaetze($0, anzahl: reihenfolge.count) })
            zeilen.append(remis ? String(localized: "\(spiel): Remis") : String(localized: "\(spiel): \(reihenfolge[0]) gewinnt"))
            for (i, name) in reihenfolge.enumerated() {
                let platz = EndeBuchung.platz(plaetze, i)
                let p = i < punkte.count ? punkte[i] : ""
                zeilen.append("\(platz). \(name)" + (p.isEmpty ? "" : " – \(p)"))
            }
        } else if EndeBuchung.einzelGilt(reihenfolge), einzel == .verloren {
            zeilen.append(String(localized: "\(spiel): Verloren"))
        } else if EndeBuchung.einzelGilt(reihenfolge), einzel == .punkte {
            // Punktespiel ohne Sieg: Punkte nennen, wenn das Spiel eine Zahl gemeldet hat
            if let p = punkte.first.flatMap(EndeBuchung.zahl) {
                zeilen.append(neuerRekord ? String(localized: "\(spiel): Neuer Rekord mit \(p) Punkten!") : String(localized: "\(spiel): \(p) Punkte"))
            } else {
                zeilen.append(String(localized: "\(spiel): Partie beendet"))
            }
        } else {
            zeilen.append(String(localized: "\(spiel): Geschafft!"))
        }
        zeilen.append(String(localized: "Gespielt mit Partie"))
        return zeilen.joined(separator: "\n")
    }
}
