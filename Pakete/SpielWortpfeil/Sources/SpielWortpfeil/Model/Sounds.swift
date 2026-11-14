// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import KlarGlas
import SpieleKern

/// Kurze Soundeffekte. Die Dateien in `Kreuzwortraetsel/Sounds` sind selbst erzeugt
/// (siehe `Tools/make_sounds.py`) – keine fremden Samples, keine Lizenz nötig.
@MainActor
enum Sound: String, CaseIterable {
    case key, word, win

    private static var lastPlayed: [Sound: Date] = [:]

    /// Lautstärke: Taste leise, Wort mittel, Gewinn am vollsten
    private var volume: Float {
        switch self {
        case .key: 0.30
        case .word: 0.45
        case .win: 0.60
        }
    }

    /// Bei schnellem Tippen nicht jeden Anschlag vertonen
    private var minInterval: TimeInterval { self == .key ? 0.06 : 0 }

    func play() {
        guard SpieleTon.erlaubt else { return }
        let now = Date()
        if let last = Self.lastPlayed[self], now.timeIntervalSince(last) < minInterval { return }
        Self.lastPlayed[self] = now
        SpielKlang.spielen("wortpfeil-" + rawValue, lautstaerke: volume)
    }
}
