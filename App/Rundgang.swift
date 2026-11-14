// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

/// Testeinstieg für den automatischen UI-Rundgang (Test/Rundgang). Nur aktiv mit dem Launch-Argument `-rundgang`.
/// Alles Weitere steuern die Launch-Argumente der Systemvorgaben, ohne Code in den Spielen:
/// `-design.art klar|tinte|salon`, `-darstellung hell|dunkel` (Werte siehe `Darstellung`), `-startetMit <spiel-id>`,
/// `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`, `-AppleLanguages (de)`.
/// Zusätzlich: `-rundgangEinfuehrung` zeigt die Einführung (sonst übersprungen), `-rundgangNeu` löscht Spielstände nicht (bewusst nicht).
enum Rundgang {
    static var aktiv: Bool { ProcessInfo.processInfo.arguments.contains("-rundgang") }

    @MainActor
    static func vorbereiten() {
        guard aktiv else { return }
        let args = ProcessInfo.processInfo.arguments
        let d = UserDefaults.standard
        if !args.contains("-rundgangEinfuehrung") { d.set(Version.aktuell, forKey: "einfuehrungVersion") }
        d.set(false, forKey: Modi.kinderKey)
        d.set(false, forKey: Modi.ruheKey)
        UIView.setAnimationsEnabled(false)   // ruhige, reproduzierbare Bilder
    }
}
