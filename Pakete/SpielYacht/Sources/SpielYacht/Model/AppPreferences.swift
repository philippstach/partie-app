// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

/// App-weite Einstellungen (Töne, Vibration, Animationen, Vorschau), in UserDefaults gesichert.
@Observable
final class AppPreferences {
    var reduceAnimations: Bool { didSet { defaults.set(reduceAnimations, forKey: "reduceAnimations") } }
    /// Zeigt in freien Feldern, wie viele Punkte der aktuelle Wurf bringen würde.
    var showPreview: Bool { didSet { defaults.set(showPreview, forKey: "showPreview") } }
    /// Tipp-Hilfe: zeigt nach jedem Wurf, welche Würfel man halten sollte (Standard: aus)
    var holdAdvice: Bool { didSet { defaults.set(holdAdvice, forKey: "holdAdvice") } }
    /// Chancen-Anzeige: Wahrscheinlichkeit, mit den restlichen Würfen Drilling, Vierling, Full House, Straßen oder Yacht zu schaffen (Standard: aus)
    var showChances: Bool { didSet { defaults.set(showChances, forKey: "showChances") } }
    var nextPlayerOverlay: Bool { didSet { defaults.set(nextPlayerOverlay, forKey: "nextPlayerOverlay") } }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        func flag(_ key: String, _ fallback: Bool) -> Bool {
            defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
        }
        reduceAnimations = flag("reduceAnimations", false)
        showPreview = flag("showPreview", true)
        nextPlayerOverlay = flag("nextPlayerOverlay", true)
        holdAdvice = flag("holdAdvice", false)
        showChances = flag("showChances", false)
    }
}
