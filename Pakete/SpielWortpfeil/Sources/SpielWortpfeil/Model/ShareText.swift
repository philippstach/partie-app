// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Text zum Teilen eines Ergebnisses (nur Text über das System-Teilen, kein Bild, kein Server).
enum ShareText {
    /// „Kreuzworträtsel 5. Okt. ★ 6:12 · Serie 6“ – Stern nur ohne Hilfe, Serie nur beim Tagesrätsel
    static func make(time: Double, hints: Int, streak: Int, isDaily: Bool, date: Date, locale: Locale = .current) -> String {
        let day = date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
        var text = "\(String(localized: "Kreuzworträtsel")) \(day) \(hints == 0 ? "★ " : "")\(Zeitformat.text(time))"
        if isDaily, streak > 0 { text += " · \(String(localized: "Serie")) \(streak)" }
        return text
    }
}
