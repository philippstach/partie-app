// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SpieleKern

/// Kurze Soundeffekte. Die Dateien in `Sounds/` sind selbst erzeugt (`Tools/make_sounds.py`).
enum Sound: String, CaseIterable, SpielTon {
    case roll, select, flip, good, schockaus, deckel, end, klack

    static let praefix = "schocken"
}
