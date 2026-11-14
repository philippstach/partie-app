// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas
import Baukasten

/// Gemeinsame Zusatzfunktionen der Spielefamilie (Paket `_Gemeinsam/Baukasten`, Regeln: BAUKASTEN-REGELN.md).
/// Rauswurf: Farbwahl, App empfehlen, Über mich und Querverweise sind an. Trinkgeld und Game Center sind aus,
/// ein Tagesrätsel mit Erinnerung gibt es nicht. Die Bewertungsanfrage läuft über den Zähler des Baukastens.
@MainActor
enum BaukastenSetup {
    static let konfig = BaukastenKonfiguration(
        appName: "Rauswurf",
        // App-Store-ID (6829894944) erst eintragen, wenn die App live ist: sonst führen „Bewerten“ und „Empfehlen“ ins Leere.
        links: AppLinks(key: "rauswurf", appStoreID: nil),
        standardAkzent: .tuerkis
    )

    /// Gewählte App-Farbe (Voreinstellung Türkis), pro Gerät gespeichert.
    static let akzent: AkzentSpeicher = {
        let speicher = AkzentSpeicher(standard: konfig.standardAkzent)
        // Eine früher gewählte, jetzt nicht mehr wählbare Farbe (zu nah an einer Spielerfarbe) zurücksetzen
        if ausgenommeneFarben.contains(speicher.gewaehlt.id) { speicher.gewaehlt = speicher.standard }
        return speicher
    }()

    /// Diese App-Farben sehen den Sitzfarben im Brett (Blau, Grün, Koralle, Violett) zu ähnlich (Farbabstand unter 20):
    /// Grün, Rot und Violett. Die gewählte App-Farbe soll nie wie eine Spielerfarbe aussehen.
    static let ausgenommeneFarben: Set<String> = ["gruen", "rot", "violett"]

    static let bewertung = BewertungsZaehler()
}

extension Color {
    /// App-Farbe als Text; folgt der gewählten Farbe.
    @MainActor static var gewaehlterAkzentText: Color {
        let farbe = BaukastenSetup.akzent.gewaehlt
        return Color(UIColor { trait in
            UIColor(farbe.text(trait.userInterfaceStyle == .dark ? .dark : .light))
        })
    }
}
