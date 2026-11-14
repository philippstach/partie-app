// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Tempo der Computer-Züge: Pause pro Schritt. Vorher je eine Kopie in Schocken und Rauswurf.
/// 1.0 (M2): Eine Einstellung „Tempo des Computers“ für alle Spiele (Einstellungen → Spielen). Spiele mit eigenen
/// festen Pausen rechnen sie über `ComputerTempo.angepasst(_:)` um. Rauswurf und Schocken behalten ihre eigene Wahl.
public enum ComputerTempo: String, CaseIterable, Codable, Sendable {
    case langsam, normal, schnell

    public var pause: Duration {
        switch self {
        case .langsam: .milliseconds(1200)
        case .normal: .milliseconds(700)
        case .schnell: .milliseconds(300)
        }
    }

    /// Faktor auf die festen Pausen der Spiele (normal = wie bisher).
    public var faktor: Double {
        switch self {
        case .langsam: 1.6
        case .normal: 1.0
        case .schnell: 0.4
        }
    }

    /// Anzeigename in den Einstellungen.
    public var titel: String {
        switch self {
        case .langsam: String(localized: "Langsam")
        case .normal: String(localized: "Normal")
        case .schnell: String(localized: "Schnell")
        }
    }

    /// Schlüssel der globalen Einstellung (UserDefaults / `@AppStorage`).
    public static let schluessel = "computerTempo"

    /// Gewählte globale Einstellung (Standard: normal).
    public static var global: ComputerTempo {
        UserDefaults.standard.string(forKey: schluessel).flatMap(ComputerTempo.init(rawValue:)) ?? .normal
    }

    /// Feste Pause eines Spiels nach der globalen Einstellung umgerechnet.
    public static func angepasst(_ pause: Duration) -> Duration {
        let f = global.faktor
        if f == 1 { return pause }
        let (s, atto) = pause.components
        let ms = Double(s) * 1000 + Double(atto) / 1e15
        return .milliseconds(Int((ms * f).rounded()))
    }

    /// Wie `angepasst(_:)`, für Stellen mit Nanosekunden.
    public static func angepasst(nanosekunden: UInt64) -> UInt64 {
        UInt64((Double(nanosekunden) * global.faktor).rounded())
    }

    /// Wartet die angepasste Pause (Abbruch der Aufgabe wird wie bei `Task.sleep` ignoriert).
    public static func warte(_ pause: Duration) async {
        try? await Task.sleep(for: angepasst(pause))
    }
}
