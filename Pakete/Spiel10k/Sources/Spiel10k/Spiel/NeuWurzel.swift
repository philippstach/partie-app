// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// „10k“: das Spiel im `SpielRahmen` der Sammlung. Start, Spielerwahl und Ende kommen vom Rahmen,
/// der Spielbildschirm (`NeuSpielView`) und der Kern (`GameStore`) sind von 10k geteilt.
@MainActor
public struct ZehnKNeuSpiel: View {
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var store: GameStore
    @State private var preferences: AppPreferences
    @State private var gemeldet = false

    public init(teilnehmer: [SpielTeilnehmer], umgebung: SpielUmgebung, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.ende = ende
        self.abbrechen = abbrechen
        let prefs = AppPreferences(defaults: NeuAblage.defaults)
        let store = NeuAblage.neuerStore()
        NeuAblage.starten(store, teilnehmer: teilnehmer, umgebung: umgebung, preferences: prefs)
        _store = State(initialValue: store)
        _preferences = State(initialValue: prefs)
    }

    public var body: some View {
        NeuSpielView(abbrechen: abbrechen)
            .environment(store)
            .environment(preferences)
            .onAppear { preferences.apply(to: store) }
            .onChange(of: preferences.values) { preferences.apply(to: store) }
            // Partie entschieden und letzte Einblendung vorbei → Rahmen zeigt das Ende
            .onChange(of: beendet) { _, jetzt in
                guard jetzt, !gemeldet, let g = store.game else { return }
                gemeldet = true
                let partieID = store.currentID
                Task {
                    try? await Task.sleep(for: .milliseconds(900))
                    ende(NeuLogik.ende(g))
                    if let partieID { store.deleteGame(partieID) }   // C-042: beendete Partien bleiben nicht als Datei liegen (wie bei Yacht neu)
                }
            }
    }

    private var beendet: Bool {
        guard let g = store.game else { return false }
        return g.finished && store.nieteNotice == nil && store.tiebreakNotice == nil
    }
}
