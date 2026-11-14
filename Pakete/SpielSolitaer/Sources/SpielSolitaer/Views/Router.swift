// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation
import Observation

enum MenuRoute: Hashable { case daily, stats, settings, rules, games, pickDeal }

/// Welche Blätter über dem Tisch offen sind
@Observable
final class Router {
    var showMenu = false
    /// Startseite über dem Tisch (Kaltstart, Haus-Knopf, ≥ 30 Minuten im Hintergrund); beim allerersten Start gleich das Spiel
    var showStart = true
    /// Navigationspfad der Startseite (Tagesspiel, Statistik, Regeln, Einstellungen)
    var startPath: [MenuRoute] = []
    /// Spiel, dessen Tagesspiel-Kalender die Startseite öffnet (Kapseln im Schaufenster); nil = laufendes Spiel
    var startDailyKind: GameKind?
    /// Spiele-Übersicht als eigenes Blatt (vom Spielnamen in der Kopfzeile)
    var showGames = false
    var path: [MenuRoute] = []
    /// Alles schließen und in die Partie gehen (aus Menü, Spiele-Blatt und Startseite)
    func leaveToGame() {
        showMenu = false
        showGames = false
        showStart = false
        startPath = []
    }
    /// Nur für Demo: Monat, den der Kalender zuerst zeigt
    var dailyMonth: Date?
    /// Nur für Demo: Einstellungen zuerst zum Abschnitt „Aussehen“ scrollen
    var scrollToAppearance = false
    /// Nur für Demo: Statistik zuerst zur Karte „Erfolge“ scrollen
    var scrollToAchievements = false
    /// Nur für Demo: Statistik zuerst zur Karte „Verlauf“ scrollen
    var scrollToHistory = false
    /// Nur für Demo: Spiele-Übersicht ganz nach unten gescrollt (alle sieben Kacheln im Bild)
    var scrollGamesToEnd = false
    /// Nur für Demo: Einstellungen zuerst zur Gruppe „Spiel“ scrollen
    var scrollToGameSettings = false
    /// Nur für Demo: Willkommens-Karte gleich im zweiten Schritt („Karten ablegen“)
    var welcomeStartsAtPlacing = false
    /// Nur für Demo: Hinweis „Neu: Karten legst du jetzt selbst ab“ sofort zeigen
    var forceAutoPlaceNotice = false
}
