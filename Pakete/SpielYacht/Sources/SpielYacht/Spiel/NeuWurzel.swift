// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import Baukasten
import SpieleKern
import SpielHilfen

/// „Yacht“: das Spiel im `SpielRahmen` der Sammlung. Start, Spielerwahl und Ende kommen vom Rahmen,
/// Regeln, Computer und Spielstand sind vom alten Yacht geteilt.
@MainActor
struct YachtNeuSpiel: View {
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var store: GameStore
    @State private var preferences: AppPreferences
    @State private var gemeldet = false

    init(teilnehmer: [SpielTeilnehmer], umgebung: SpielUmgebung, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.ende = ende
        self.abbrechen = abbrechen
        let store = NeuAblage.neuerStore()
        NeuAblage.starten(store, teilnehmer: teilnehmer, umgebung: umgebung)
        _store = State(initialValue: store)
        _preferences = State(initialValue: AppPreferences(defaults: NeuAblage.defaults))
    }

    var body: some View {
        NeuSpielView(abbrechen: abbrechen, ende: melden)
            .environment(store)
            .environment(preferences)
            .environment(\.akzent, BaukastenSetup.akzent.gewaehlt)
    }

    private func melden() {
        guard !gemeldet, let g = store.game, g.finished else { return }
        gemeldet = true
        // C-038 (1): Rekord erst beim Melden sichern, damit „Neuer Rekord!“ auf der Endkarte stehen bleibt
        // 1.0 (P5): Der Tageswürfel hat eine feste Folge und zählt nicht als Rekord der Wertung, sondern für die Serie (unter dem Tag der Partie)
        if let tag = g.settings.dailyKey {
            TagesSerie.melden(spiel: "yacht", tag: tag.replacingOccurrences(of: "-", with: ""),
                              ergebnis: String(localized: "\(g.total(0)) Punkte") + " · " + g.state.rules.variant.titel)
        } else if g.players.count == 1 { NeuAblage.rekordSichern(g.state.rules.variant, punkte: g.total(0)) }
        let e = NeuLogik.ende(g)
        var se = SpielEnde(reihenfolge: e.reihenfolge, punkte: e.punkte, plaetze: g.players.count > 1 ? e.plaetze : nil, info: e.info,
                           einzel: g.players.count == 1 ? .punkte : .gewonnen)   // C-035: allein ist Yacht ein Punktespiel ohne Sieg
        // Blatt 22 (EB-2, Schritt 1): Bonus oben und Dauer als Werte, der Zettel am Ende als Bild; „Yacht geworfen“ (Schritt 2)
        se.werte = (NeuEndeBild.bonusWert(g).map { [$0] } ?? []) + (NeuEndeBild.yachtWert(g).map { [$0] } ?? []) + [.dauer]
        se.bild = NeuEndeBild.bild(g)
        ende(se)
        store.deleteGame(g.id)
    }
}
