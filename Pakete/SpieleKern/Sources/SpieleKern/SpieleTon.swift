// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// F10: Gemeinsamer Ton-Schalter der Sammlung (Einstellungen › Ton). Aus = alle Soundeffekte stumm, egal was ein Spiel selbst einstellt.
public enum SpieleTon {
    public static let schluessel = "toeneAn"
    public static var erlaubt: Bool { UserDefaults.standard.object(forKey: schluessel) as? Bool ?? true }
}

/// Gemeinsamer Haptik-Schalter der Sammlung (Einstellungen › Ton & Haptik). Aus = keine Impulse bei Spielereignissen.
public enum SpieleHaptik {
    public static let schluessel = "haptikAn"
    public static var erlaubt: Bool { UserDefaults.standard.object(forKey: schluessel) as? Bool ?? true }
}
