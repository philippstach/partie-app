// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

/// Reine Logik der Hülle, aus den Ansichten herausgezogen, damit sie sich testen lässt (Verhalten unverändert).

/// Randwisch: vom linken Rand zurück zur Startseite, vom rechten Rand wieder ins letzte Spiel.
enum Randwisch {
    enum Aktion: Equatable { case zurueckZurStartseite, letztesSpiel }
    static let randBreite: CGFloat = 24
    static let mindestWeg: CGFloat = 90
    static let hoechstAbweichung: CGFloat = 60

    static func aktion(start: CGPoint, bewegung: CGSize, breite: CGFloat, spielOffen: Bool, letztesErlaubt: Bool) -> Aktion? {
        guard abs(bewegung.height) < hoechstAbweichung else { return nil }
        if spielOffen, start.x < randBreite, bewegung.width > mindestWeg { return .zurueckZurStartseite }
        if !spielOffen, start.x > breite - randBreite, bewegung.width < -mindestWeg, letztesErlaubt { return .letztesSpiel }
        return nil
    }
}

/// Einführung beim ersten Start und „Was ist neu?“ nach Updates.
enum Einfuehrung {
    /// Zeigen, wenn für diese Version noch keine Einführung abgeschlossen wurde.
    static func zeigen(gespeichert: String, aktuell: String) -> Bool { gespeichert != aktuell }
    /// „Was ist neu?“ statt Willkommen: wenn schon einmal eine Einführung lief oder es bereits Spieler gibt (Update von einer Version ohne Einführung).
    static func istUpdate(gespeichert: String, hatSpieler: Bool) -> Bool { !gespeichert.isEmpty || hatSpieler }
}

extension Tagesaufgabe {
    /// Die Tagesaufgabe erscheint nur, wenn sie in den Einstellungen an ist und weder Ruhe- noch Kinder-Modus an ist.
    static func sichtbar(ruhe: Bool, kinder: Bool, an: Bool = true) -> Bool { an && !ruhe && !kinder }
}
