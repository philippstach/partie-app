// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

private struct SammlungKey: EnvironmentKey { static let defaultValue: (@MainActor () -> Void)? = nil }
private struct SpielUmgKey: EnvironmentKey { static let defaultValue: SpielUmgebung? = nil }

public extension EnvironmentValues {
    /// Gesetzt, wenn das Spiel innerhalb der Sammlung läuft: führt zurück zur Übersicht (Rundknopf „Sammlung“ im Spielstart).
    var zurSammlung: (@MainActor () -> Void)? {
        get { self[SammlungKey.self] }
        set { self[SammlungKey.self] = newValue }
    }
    var spielUmgebung: SpielUmgebung? {
        get { self[SpielUmgKey.self] }
        set { self[SpielUmgKey.self] = newValue }
    }
}

#if canImport(UIKit)
import UIKit
/// Erlaubte Ausrichtungen: die Hülle fragt hier, das laufende Spiel setzt die Maske (Viererreihe, Solitär). Voreinstellung: iPhone Hochformat, iPad alle.
public enum SpielAusrichtung {
    @MainActor public static var maske: () -> UIInterfaceOrientationMask = {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }
    @MainActor public static func zuruecksetzen() {
        maske = { UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait }
    }
}
#endif
