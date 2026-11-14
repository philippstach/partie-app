// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Merkt sich, welche Spiele eine offene Partie haben (für „Weiterspielen“ auf dem Start der Sammlung).
/// Jedes Spiel setzt den Eintrag beim Verlassen; die Hülle liest ihn.
public enum OffenesSpiel {
    private static let schluessel = "partie.offen"

    public static func setze(_ id: String, offen: Bool, defaults: UserDefaults = .standard) {
        var d = (defaults.dictionary(forKey: schluessel) as? [String: Double]) ?? [:]
        let jetzt = Date().timeIntervalSince1970
        if offen {
            // K-031: Der Zeitstempel dient nur der Reihenfolge („zuletzt gespielt zuerst“); alle 30 s genügen, sonst schreibt jeder Zug (und jede Neuberechnung) neu.
            if let alt = d[id], jetzt - alt < 30 { return }
            d[id] = jetzt
        } else {
            guard d[id] != nil else { return }   // nichts zu löschen: nicht schreiben
            d[id] = nil
        }
        defaults.set(d, forKey: schluessel)
    }

    /// Spiel-IDs mit offener Partie, zuletzt gespielte zuerst.
    public static func alle(defaults: UserDefaults = .standard) -> [String] {
        let d = (defaults.dictionary(forKey: schluessel) as? [String: Double]) ?? [:]
        return d.sorted { $0.value > $1.value }.map(\.key)
    }

    /// „Weiterspielen“ von der Startseite: Das Spiel soll gleich in der laufenden Partie öffnen, nicht erst auf seiner Spielseite
    /// (TestFlight 13.11., Nr. 6). Die Startseite merkt die Spiel-ID, die Hülle des Spiels löst den Wunsch beim Erscheinen ein.
    /// Gilt nur für diesen einen Start; ist keine Partie gespeichert, bleibt es bei der Spielseite.
    @MainActor public static var direktWunsch: String?

    @MainActor public static func direktMerken(_ id: String) { direktWunsch = id }

    /// Gibt `true` zurück (und löscht den Wunsch), wenn die Startseite für dieses Spiel „Weiterspielen“ gewählt hat.
    @MainActor public static func direktEinloesen(_ id: String) -> Bool {
        guard direktWunsch == id else { return false }
        direktWunsch = nil
        return true
    }
}
