// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Vorschau der Sammlungs-Bausteine (Startseite „Spieleabend“), ohne App-Daten. Nur für RenderPreview/Xcode-Canvas.
#if canImport(UIKit) && DEBUG
#Preview("Spieleabend") {
    let rot = Color(red: 0.898, green: 0.282, blue: 0.302), indigo = Color(red: 0.294, green: 0.290, blue: 0.812)
    let tuerkis = Color(red: 0.047, green: 0.522, blue: 0.600), blau = Color(red: 0.184, green: 0.435, blue: 0.922)
    let pink = Color(red: 0.761, green: 0.224, blue: 0.541), orange = Color(red: 0.949, green: 0.420, blue: 0.114)
    let nacht = Color(red: 0.122, green: 0.227, blue: 0.373)
    ZStack(alignment: .bottom) {
        ScrollView {
            VStack(spacing: Theme.kartenAbstand) {
                HStack { RundKnopf(symbol: "gearshape.fill", beschriftung: "Einstellungen") {}; Spacer()
                    RundKnopf(symbol: "magnifyingglass", beschriftung: "Suchen") {}; RundKnopf(symbol: "person.2.fill", beschriftung: "Spieler") {}; RundKnopf(symbol: "dice", beschriftung: "Zufall") {} }
                StartTitel("Partie").padding(.bottom, 6)
                WeiterspielenKarte(beschreibung: "Yacht · Runde 7 von 13") {}.colorScheme(.light)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Design.Abstand.s) {
                        FilterChip("Alle 73", aktiv: true) {}
                        FilterChip("Favoriten", symbol: "heart.fill", aktiv: false) {}
                        FilterChip("Karten", punkt: rot, aktiv: false) {}
                        FilterChip("Würfel", punkt: indigo, aktiv: false) {}
                        FilterChip("Brett", punkt: tuerkis, aktiv: false) {}
                        FilterChip("Rätsel", punkt: blau, aktiv: false) {}
                    }
                }
                SpielZeile(name: "Solitär", untertitel: Text("Karten · 1 Spieler"), farbe: rot, miniatur: .kartenstapel, favorit: true) {}
                SpielZeile(name: "Mau-Mau", untertitel: Text("Karten · 2–6 Spieler"), farbe: rot, miniatur: .kartenfaecher) {}
                SpielZeile(name: "Schach", untertitel: Text("Brett · 2 Spieler"), farbe: tuerkis, miniatur: .schach) {}
                SpielZeile(name: "Yacht", untertitel: Text("Würfel · 1–4 Spieler"), farbe: indigo, miniatur: .wuerfel) {}
                SpielZeile(name: "Schocken", untertitel: Text("Würfel · 2–6 Spieler"), farbe: indigo, miniatur: .becher) {}
                SpielZeile(name: "Sudoku", untertitel: Text("Rätsel · 1 Spieler"), farbe: blau, miniatur: .zahlengitter) {}
                SpielZeile(name: "Minensuche", untertitel: Text("Rätsel · 1 Spieler"), farbe: blau, miniatur: .minen) {}
                SpielZeile(name: "Rauswurf", untertitel: Text("Brett · 2–4 Spieler"), farbe: tuerkis, miniatur: .ludo) {}
                SpielZeile(name: "Kalaha", untertitel: Text("Brett · 2 Spieler"), farbe: tuerkis, miniatur: .mulden) {}
                SpielZeile(name: "Wortpfeil", untertitel: Text("Wort · 1 Spieler"), farbe: pink, miniatur: .pfeilraetsel) {}
                SpielZeile(name: "Galgenmännchen", untertitel: Text("Wort · 1–2 Spieler"), farbe: pink, miniatur: .galgen) {}
                SpielZeile(name: "Stadt, Land, Fluss", untertitel: Text("Wort · 2–6 Spieler"), farbe: pink, miniatur: .buchstaben) {}
                SpielZeile(name: "Mauerbrecher", untertitel: Text("Arcade · 1 Spieler"), farbe: orange, miniatur: .ziegel) {}
                SpielZeile(name: "Steinfall", untertitel: Text("Arcade · 1 Spieler"), farbe: orange, miniatur: .bloecke) {}
                SpielZeile(name: "Dauerlauf", untertitel: Text("Arcade · 1 Spieler"), farbe: orange, miniatur: .laeufer) {}
                SpielZeile(name: "Ballwechsel", untertitel: Text("Arcade · 1–2 Spieler"), farbe: orange, miniatur: .schlaeger) {}
                SpielZeile(name: "Paarsuche", untertitel: Text("Karten · 1–4 Spieler"), farbe: rot, miniatur: .paare) {}
                SpielZeile(name: "Sechseck", untertitel: Text("Brett · 2 Spieler"), farbe: tuerkis, miniatur: .sechseck) {}
                SpielZeile(name: "Nonogramm", untertitel: Text("Rätsel · 1 Spieler"), farbe: blau, miniatur: .bildgitter) {}
                SpielZeile(name: "Dame", untertitel: Text("Brett · 2 Spieler"), farbe: tuerkis, miniatur: .brett) {}
            }
            .padding(.horizontal, Theme.seitenRand).padding(.bottom, 100)
        }
        .environment(\.startTitelFarbe, .white)
        .spieleabendGrund(nacht)
        Button("Neues Spiel") {}.hauptKnopf(hell: true).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
    }
    .tint(nacht)
}
#endif
