// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Stadt, Land, Fluss: Zu einem Buchstaben je Kategorie ein Wort finden. Wertung: 10 Punkte, 5 bei gleicher Antwort mehrerer, 20 als Einziger.
public enum StadtLandFlussWertung {
    public static let kategorien = ["Stadt", "Land", "Fluss", "Tier", "Beruf", "Name"]
    /// Alle wählbaren Kategorien; die ersten sechs sind die Standardauswahl.
    public static let alleKategorien = kategorien + ["Pflanze", "Essen & Trinken", "Sportart", "Film oder Serie", "Marke", "Gegenstand"]
    public static let mindestKategorien = 3

    /// Gespeicherte Auswahl lesen (Namen, in fester Reihenfolge von `alleKategorien`); fehlerhafte Werte fallen auf den Standard zurück.
    public static func auswahl(gespeichert: [String]?) -> [String] {
        let g = alleKategorien.filter { (gespeichert ?? []).contains($0) }
        return g.count >= mindestKategorien ? g : kategorien
    }
    public static let buchstaben = Array("ABCDEFGHIKLMNOPRSTUWZ")

    /// Vergleichsform einer Antwort: ohne Akzente und Groß-/Kleinschreibung, ß = ss, Bindestriche und Punkte wie Leerzeichen, Mehrfach-Leerzeichen zusammengefasst.
    public static func normiert(_ s: String) -> String {
        let f = s.replacingOccurrences(of: "ß", with: "ss").replacingOccurrences(of: "ẞ", with: "SS")
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "de_DE"))
        let teile = f.split(whereSeparator: { $0.isWhitespace || $0 == "-" || $0 == "." || $0 == "," })
        return teile.joined(separator: " ")
    }

    /// Passt die Antwort zum Buchstaben (nicht leer, beginnt damit)?
    public static func plausibel(_ antwort: String, buchstabe: Character) -> Bool {
        let n = normiert(antwort)
        guard let e = n.first else { return false }
        return String(e).lowercased() == String(buchstabe).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil).lowercased()
    }

    /// Punkte einer Runde je Spieler. `antworten[spieler][kategorie]`, `gueltig[spieler][kategorie]` (Gruppe darf Antworten streichen).
    public static func punkte(antworten: [[String]], gueltig: [[Bool]], buchstabe: Character) -> [Int] {
        let sp = antworten.count
        var erg = Array(repeating: 0, count: sp)
        guard let kat = antworten.first?.count else { return erg }
        for k in 0..<kat {
            let gueltige = (0..<sp).filter { gueltig[$0][k] && plausibel(antworten[$0][k], buchstabe: buchstabe) }
            for s in gueltige {
                let a = normiert(antworten[s][k])
                let gleiche = gueltige.filter { normiert(antworten[$0][k]) == a }.count
                erg[s] += gueltige.count == 1 ? 20 : (gleiche > 1 ? 5 : 10)
            }
        }
        return erg
    }
}
