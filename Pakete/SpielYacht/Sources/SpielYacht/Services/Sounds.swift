// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SpieleKern

/// Kurze Soundeffekte. Die Dateien in `Sounds/` sind selbst erzeugt – keine fremden Samples.
enum Sound: String, CaseIterable, SpielTon {
    case roll, select, score, strike, win

    static let praefix = "yacht"
}
