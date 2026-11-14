// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SpieleKern
import KlarGlas
import Foundation
import Observation

/// Einstellungen für alle Spiele, gespeichert in UserDefaults.
@MainActor @Observable
final class AppPreferences {
    private let defaults: UserDefaults

    /// „Wörter auf“: wirkt erst beim nächsten Spiel
    var wordLanguage: WordLanguage { didSet { defaults.set(wordLanguage.rawValue, forKey: "wordLanguage") } }


    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        wordLanguage = defaults.string(forKey: "wordLanguage").flatMap(WordLanguage.init) ?? .deviceDefault
    }
}
