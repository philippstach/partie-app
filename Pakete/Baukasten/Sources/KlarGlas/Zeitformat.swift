// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

/// Spielzeit überall gleich (Konzept 3.3, Q16): `m:ss`, ab einer Stunde `h:mm:ss`, immer `monospacedDigit` beim Zeichnen.
public enum Zeitformat {
    public static func text(sekunden: Int) -> String {
        let s = max(0, sekunden)
        let h = s / 3600, m = (s % 3600) / 60, r = s % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, r) : String(format: "%d:%02d", m, r)
    }

    public static func text(_ dauer: TimeInterval) -> String {
        text(sekunden: dauer.isFinite ? Int(dauer.rounded(.down)) : 0)
    }

    /// Für VoiceOver: „4 Minuten, 12 Sekunden“ in der Systemsprache.
    public static func gesprochen(sekunden: Int) -> String {
        let f = DateComponentsFormatter()
        f.unitsStyle = .full
        f.allowedUnits = sekunden >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        f.zeroFormattingBehavior = .dropLeading
        return f.string(from: TimeInterval(max(0, sekunden))) ?? text(sekunden: sekunden)
    }
}
