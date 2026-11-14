// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
#if canImport(UIKit)
import SwiftUI
#endif

/// Einstellung „Gerät weitergeben“: Bei Spielen ohne verdeckte Informationen blendet sich die Meldung nach kurzer Zeit selbst aus.
/// Bei Spielen mit geheimen Karten bleibt immer die Bestätigung „Bereit“ (der Nächste soll nicht mitlesen).
public enum WeitergabeEinstellung {
    public static let schluessel = "partie.weitergabeAutomatisch"
    /// Wie lange die Meldung bei offenen Spielen stehen bleibt.
    public static let anzeigedauer: Duration = .milliseconds(1500)

    public static func automatisch(defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: schluessel) as? Bool ?? true
    }
}

#if canImport(UIKit)
/// Fertiger Schalter für die Einstellungen (in eine `Form`/`Section` setzen).
public struct WeitergabeSchalter: View {
    @AppStorage(WeitergabeEinstellung.schluessel) private var automatisch = true
    public init() {}
    public var body: some View {
        Toggle(isOn: $automatisch) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weitergabe-Meldung automatisch ausblenden")
                Text("Gilt nur für Spiele ohne verdeckte Karten. Bei geheimen Karten bleibt immer „Bereit“.").font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}
#endif
