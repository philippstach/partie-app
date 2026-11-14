// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// KI-N (Blatt 18 „Neue Partie sagen“): Die Ansage „Mau-Mau zu dritt“ merkt sich die Spielerzahl für die Spielseite vor.
/// `SpielRahmen` belegt die Spielerliste damit vor (Plätze nur auffüllen oder kürzen, Namen wie bisher). Die Vormerkung gilt zehn Minuten
/// und endet mit dem Start der Partie. Es startet nichts von selbst.
public enum SpielerVormerkung {
    private static func schluessel(_ spiel: String) -> String { "partie.ansage.spieler.\(spiel)" }
    private static let gueltig: TimeInterval = 600

    public static func merken(_ anzahl: Int, fuer spiel: String, jetzt: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(["n": anzahl, "bis": jetzt.timeIntervalSince1970 + gueltig], forKey: schluessel(spiel))
    }

    /// Gemerkte Zahl, solange sie gilt. Liest nur (der Rahmen wird mehrfach gebildet), gelöscht wird beim Start der Partie.
    public static func lesen(fuer spiel: String, jetzt: Date = Date(), defaults: UserDefaults = .standard) -> Int? {
        guard let d = defaults.dictionary(forKey: schluessel(spiel)), let n = d["n"] as? Int, let bis = d["bis"] as? Double, bis > jetzt.timeIntervalSince1970 else { return nil }
        return n
    }

    public static func loeschen(fuer spiel: String, defaults: UserDefaults = .standard) { defaults.removeObject(forKey: schluessel(spiel)) }
}
