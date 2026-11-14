// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// „Schocken“: das Spiel im `SpielRahmen` der Sammlung. Start, Spielerwahl und Ende kommen vom Rahmen,
/// Kern (Regeln, Computer, Spielstand) und die kleinen Bausteine (Würfel, Deckel, Eingabe) sind vom alten Schocken geteilt.
@MainActor
struct SchockenNeuSpiel: View {
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var store: GameStore
    @State private var preferences: AppPreferences
    @State private var abendStore: AbendStore
    @State private var gemeldet = false

    init(teilnehmer: [SpielTeilnehmer], umgebung: SpielUmgebung, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.ende = ende
        self.abbrechen = abbrechen
        let prefs = AppPreferences(defaults: NeuAblage.defaults)
        let store = NeuAblage.neuerStore()
        NeuAblage.starten(store, teilnehmer: teilnehmer, umgebung: umgebung, preferences: prefs)
        _store = State(initialValue: store)
        _preferences = State(initialValue: prefs)
        _abendStore = State(initialValue: AbendStore(defaults: NeuAblage.defaults))
    }

    var body: some View {
        NeuSpielView(abbrechen: abbrechen, ende: melden)
            .environment(store)
            .environment(preferences)
            .environment(abendStore)
            .onChange(of: store.zustand?.phase) { _, phase in
                if phase == .partieVorbei { store.abendErfassen(in: abendStore) }
            }
            .onAppear { if store.zustand?.phase == .partieVorbei { store.abendErfassen(in: abendStore) } }
    }

    private func melden() {
        guard !gemeldet, let z = store.zustand, z.phase == .partieVorbei else { return }
        gemeldet = true
        let e = NeuLogik.ende(z)
        var se = SpielEnde(reihenfolge: e.reihenfolge, punkte: e.punkte, plaetze: e.plaetze, info: e.info)
        // Blatt 22 (EB-2, Schritt 2): Runden, Schock aus, Dauer; Würfelbild aus der Zählung (ein alter Stand hat keine: dann kein Bild)
        se.werte = [EndeWert("Runden", "\(z.rundenGesamt)"), EndeWert("Schock aus", "\(z.zaehler.schockAus.reduce(0, +))"), .dauer]
        se.wuerfel = z.wuerfelBilanz
        ende(se)
        store.beenden()
    }
}
