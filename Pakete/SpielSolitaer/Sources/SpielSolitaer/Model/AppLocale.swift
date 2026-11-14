// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Sprache der App (Deutsch/Englisch) für Datumsformate: Region und App-Sprache können abweichen
/// (z. B. deutsche Region, englische App) – dann soll „Monday, October 5“ stehen, nicht „Monday, 5. October“.
enum AppLocale {
    static var current: Locale {
        Locale(identifier: Bundle.main.preferredLocalizations.first ?? "de")
    }

    static var calendar: Calendar {
        var c = Calendar.solitaer
        c.locale = current
        return c
    }
}


extension Calendar {
    /// Alle Tages- und Wochenrechnungen (Tagesspiel, Kalender, Pokal, Tages- und Wochenziele, Serien) laufen im gregorianischen Kalender
    /// der Ortszeit – auch wenn das Gerät auf einen buddhistischen, japanischen oder anderen Kalender eingestellt ist.
    /// Sonst stimmen Jahr und Tagesspiel nicht mehr (z. B. 2569 statt 2026).
    static var solitaer: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        c.firstWeekday = 2          // Wochen beginnen am Montag
        c.minimumDaysInFirstWeek = 4
        return c
    }
}
