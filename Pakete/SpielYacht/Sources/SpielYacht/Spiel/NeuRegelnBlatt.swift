// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Wertung und Regeln vor dem ersten Wurf: Kniffel (Standard), Yatzy oder Original-Yacht; bei Kniffel Joker und Yacht-Bonus.
struct NeuRegelnBlatt: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var variant = Variant.kniffel
    @State private var joker = false
    @State private var bonus = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Wertung") {
                    Picker("Wertung", selection: $variant) {
                        ForEach(Variant.allCases, id: \.self) { v in
                            Text(v.titel).tag(v)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(variant.kurz).font(.footnote).foregroundStyle(.secondary)
                }
                if variant == .kniffel {
                    Section("Zusatzregeln") {
                        // T-053 (Blatt 24): gesperrt steht der Grund darunter; der blasse Schalter selbst kommt aus dem Baukasten (KlarGlas)
                        Toggle(isOn: Binding(get: { joker || bonus }, set: { joker = $0 })) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Joker").foregroundStyle(bonus ? Color.schriftZweit : Color.schrift)
                                if bonus { Text("Gehört zum Yacht-Bonus").font(.footnote).foregroundStyle(Color.schriftZweit) }
                            }
                        }
                        .disabled(bonus)   // RT-001: der Yacht-Bonus schaltet den Joker mit ein
                        Toggle("Yacht-Bonus (100 Punkte)", isOn: $bonus)
                    }
                }
            }
            .einstellungsSchalter()   // Design-Runde 3: SchalterZeile statt System-UISwitch (wie bei Schocken)
            .navigationTitle("Wertung und Regeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Übernehmen") {
                        let r = Rules.fuer(variant, joker: joker, kniffelBonus: bonus ? 100 : 0)
                        if store.regelnVorStart(r) { NeuAblage.sichern(regeln: r) }
                        dismiss()
                    }
                }
            }
            .onAppear {
                let r = store.game?.state.rules ?? Rules.fuer(.kniffel)
                variant = r.variant; joker = r.joker; bonus = r.kniffelBonus > 0
            }
        }
    }
}
