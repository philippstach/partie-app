// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import Baukasten

/// Gemeinsame Zusatzfunktionen der Spielefamilie (Paket `_Gemeinsam/Baukasten`, Regeln: BAUKASTEN-REGELN.md).
/// Yacht: App empfehlen, Über mich, Querverweise und Farbwahl sind an. Trinkgeld, Game Center und Erinnerung sind aus.
/// „App bewerten“ in „Über“ öffnet nur das Schreibfeld im App Store (erst mit App-Store-ID); es gibt keine eigene Vorab-Frage.
@MainActor
enum BaukastenSetup {
    static let konfig = BaukastenKonfiguration(
        appName: "Yacht",
        links: AppLinks(key: "yacht", appStoreID: nil), // App-Store-ID nach dem Anlegen der App eintragen
        standardAkzent: .indigo
    )

    /// Gewählte App-Farbe (Voreinstellung Indigo), pro Gerät gespeichert.
    static let akzent = AkzentSpeicher(standard: konfig.standardAkzent)
}

extension Color {
    /// App-Farbe als Text; folgt der gewählten Farbe (liest den beobachteten Speicher, daher zeichnen sich Ansichten neu).
    @MainActor static var gewaehlterAkzentText: Color {
        let farbe = BaukastenSetup.akzent.gewaehlt
        return Color(UIColor { trait in
            UIColor(farbe.text(trait.userInterfaceStyle == .dark ? .dark : .light))
        })
    }
}
