// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Zentrale Sperre für alles, was Spielergebnisse oder Rätsel nach außen gibt (D3 Rätsel-Link, D5 Ergebnisbild).
/// Im Kindermodus ist Teilen aus. Der Schalter liegt wie in der Hülle (`Modi.kinderKey`) in `UserDefaults`.
public enum TeilenFreigabe {
    public static let kinderKey = "kinderModus"

    public static func erlaubt(_ defaults: UserDefaults = .standard) -> Bool { !defaults.bool(forKey: kinderKey) }

    /// Gibt die Teilen-Aktion nur frei, wenn Teilen erlaubt ist. Für `teilen:`-Parameter (nil = Knopf fehlt).
    public static func aktion(_ a: @escaping () -> Void, defaults: UserDefaults = .standard) -> (() -> Void)? {
        erlaubt(defaults) ? a : nil
    }
}
