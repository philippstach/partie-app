// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SpieleKern

/// Kurze Soundeffekte. Die Dateien in `Galgenmaennchen/Sounds` sind selbst erzeugt
/// (siehe `Tools/make_sounds.py`) – keine fremden Samples, keine Lizenz nötig.
enum Sound: String, CaseIterable, SpielTon {
    case hit1, hit2, hit3, hit4, hit5, pop, hint, win, lose

    /// Treffer-Ton für die n-te Stelle (0 = erste), die Tonhöhe steigt bis zur fünften
    static func hit(step: Int) -> Sound { [hit1, hit2, hit3, hit4, hit5][min(max(step, 0), 4)] }

    static let praefix = "galgen"
    static let lautstaerke: Float = 0.9
}
