// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Kurze Soundeffekte. Die Dateien in `Solitaer/Sounds` sind selbst erzeugt (siehe `Tools/make_sounds.py`).
@MainActor
enum Sound: String, CaseIterable {
    case place, foundation, flip, draw, shuffle, complete, win, invalid

    private static var lastPlayed: [Sound: Date] = [:]

    /// Bei automatischen Serien höchstens alle 0,06 s ein Ton.
    /// `volume` (0…1) überschreibt die Grundlautstärke, z. B. 0,5 beim Austeilen
    /// `pitch`: Halbtöne höher (über die Abspielgeschwindigkeit, nur für kurze Töne)
    func play(volume: Float? = nil, pitch: Int = 0) {
        guard SpieleTon.erlaubt else { return }
        let now = Date()
        guard now.timeIntervalSince(Self.lastPlayed[self] ?? .distantPast) >= 0.06 else { return }
        Self.lastPlayed[self] = now
        SpielKlang.spielen("solitaer-" + rawValue, lautstaerke: volume ?? (self == .invalid ? 0.25 : 0.5),
                           rate: Float(pow(2.0, Double(pitch) / 12.0)))
    }
}
