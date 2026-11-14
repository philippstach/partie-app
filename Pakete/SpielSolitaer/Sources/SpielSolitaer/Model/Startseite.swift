// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Wann zeigt die App beim Start bzw. bei der Rückkehr die Startseite (Doku/SPEZIFIKATION-START.md §2)?
/// - Kaltstart (App war beendet): immer.
/// - Rückkehr aus dem Hintergrund nach weniger als 30 Minuten: nein, der Bildschirm von vorher bleibt.
/// - 30 Minuten oder mehr (oder unbekannt): ja.
enum Startseite {
    /// So lange darf die App im Hintergrund gewesen sein, ohne dass die Startseite kommt
    static let schonfrist: TimeInterval = 30 * 60
}

func zeigeStartseite(kaltstart: Bool, letzteAktivitaet: Date?, jetzt: Date) -> Bool {
    if kaltstart { return true }
    guard let letzteAktivitaet else { return true }
    return jetzt.timeIntervalSince(letzteAktivitaet) >= Startseite.schonfrist
}
