// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// RT-004: Gespeicherte Schwierigkeit aus dem Neues-Spiel-Blatt. Ohne gespeicherten Wert gilt „Normal“ (1),
/// wie es das Blatt anzeigt (`@AppStorage`-Vorgabe); `integer(forKey:)` allein lieferte 0 und damit das Leicht-Brett.
public enum FarbflutStufenWahl {
    public static let standard = 1
    public static func gespeichert(_ schluessel: String, _ d: UserDefaults = .standard) -> Int {
        d.object(forKey: schluessel) as? Int ?? standard
    }
}
