// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// Einstellungen, gespeichert in UserDefaults.
@MainActor @Observable
final class AppPreferences {
    private let defaults: UserDefaults

    /// Falsche Buchstaben sofort rot färben (Standard: aus)
    var showErrors: Bool { didSet { defaults.set(showErrors, forKey: "showErrors") } }
    /// Anfangsbuchstaben stehen schon drin (Standard: aus)
    var startHelp: Bool { didSet { defaults.set(startHelp, forKey: "startHelp") } }
    /// Richtige Wörter leuchten kurz auf (Standard: aus)
    var showCorrectWords: Bool { didSet { defaults.set(showCorrectWords, forKey: "showCorrectWords") } }
    /// Einführung für Neulinge schon gesehen
    var introSeen: Bool { didSet { defaults.set(introSeen, forKey: "introSeen") } }
    /// Erinnerung ans Tagesrätsel (nur nach Zustimmung)
    var reminderOn: Bool { didSet { defaults.set(reminderOn, forKey: "reminderOn") } }
    /// Uhrzeit der Erinnerung in Minuten ab Mitternacht (Standard 9:00)
    var reminderMinutes: Int { didSet { defaults.set(reminderMinutes, forKey: "reminderMinutes") } }
    /// Vorschläge zur Stufe nach dem Gewinnen (Lernkurve)
    var suggestions: Bool { didSet { defaults.set(suggestions, forKey: "suggestions") } }
    var showTimer: Bool { didSet { defaults.set(showTimer, forKey: "showTimer") } }

    /// Zuletzt gewählte Zoomstufe je Schwierigkeitsstufe (1 = Übersicht)
    func zoom(for level: Level) -> Double {
        let z = defaults.object(forKey: "zoom-\(level.rawValue)") as? Double ?? 1
        return min(2, max(1, z))
    }

    func setZoom(_ zoom: Double, for level: Level) {
        defaults.set(min(2, max(1, zoom)), forKey: "zoom-\(level.rawValue)")
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showErrors = defaults.object(forKey: "showErrors") as? Bool ?? false
        startHelp = defaults.object(forKey: "startHelp") as? Bool ?? false
        showCorrectWords = defaults.object(forKey: "showCorrectWords") as? Bool ?? false
        introSeen = defaults.object(forKey: "introSeen") as? Bool ?? false
        reminderOn = defaults.object(forKey: "reminderOn") as? Bool ?? false
        reminderMinutes = defaults.object(forKey: "reminderMinutes") as? Int ?? 540
        suggestions = defaults.object(forKey: "suggestions") as? Bool ?? true
        showTimer = defaults.object(forKey: "showTimer") as? Bool ?? true
    }
}
