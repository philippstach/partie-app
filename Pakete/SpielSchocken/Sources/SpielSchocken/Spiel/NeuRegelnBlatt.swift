// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Hausregeln vor dem ersten Wurf: Vorlagen „Kneipe“ und „Familie“, die bekannten Schalter und „Schock aus beendet die Hälfte“.
struct NeuRegelnBlatt: View {
    @Environment(GameStore.self) private var store
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.dismiss) private var dismiss
    @State private var optionen = Optionen.standard

    var body: some View {
        NavigationStack {
            Form {
                Section("Vorlagen") {
                    Button { optionen = NeuLogik.vorlageKneipe } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Kneipe")
                            Text("Streng: nur Einsen herauslegen, Jule 4-2-1 an.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Button { optionen = NeuLogik.vorlageFamilie } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Familie")
                            Text("Locker: Jule aus, beliebige Würfel herauslegen.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                HausregelnSections(optionen: $optionen)
                Section {
                    Toggle(isOn: $optionen.schockAusEndet) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Schock aus beendet die Hälfte")
                            Text("Aus: Schock aus gibt nur so viele Deckel wie eine Hälfte hat, das Spiel geht weiter.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .einstellungsSchalter()   // F21-006 (sechster Anlauf): SchalterZeile statt System-UISwitch
            .navigationTitle("Hausregeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        if store.regelnVorStart(optionen) { preferences.hausregeln = optionen }
                        dismiss()
                    }
                }
            }
            .onAppear { optionen = store.zustand?.optionen ?? preferences.hausregeln }
        }
    }
}
