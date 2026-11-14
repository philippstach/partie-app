// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SpieleKern

/// Kurze Soundeffekte. Die Dateien in `TenK/Sounds` sind selbst erzeugt
/// (siehe `Tools/make_sounds.py`) – keine fremden Samples, keine Lizenz nötig.
enum Sound: String, CaseIterable, SpielTon {
    case roll, select, bank, niete, win, hotdice, fail

    static let praefix = "10k"
}
