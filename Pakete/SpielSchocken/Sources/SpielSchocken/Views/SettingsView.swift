// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern



/// Jede Hausregel mit einem Satz Erklärung.
struct HausregelnSections: View {
    @Binding var optionen: Optionen

    var body: some View {
        Section {
            regel("Herauslegen", "Welche Würfel man nach einem Wurf beiseitelegen darf.") {
                Picker("Herauslegen", selection: $optionen.herauslegen) {
                    Text("Nur Einsen").tag(Optionen.Herauslegen.einsen)
                    Text("Beliebig").tag(Optionen.Herauslegen.beliebig)
                }
            }
            // F21-006 (sechster Anlauf): sichtbares Label; Zusammenfassen und Tippen übernimmt SchalterZeile (Stil am Formular)
            Toggle(isOn: $optionen.sechsenUmdrehen) {
                erklaerung("Sechsen umdrehen", "Zwei Sechsen ergeben eine Eins, drei Sechsen bis zu zwei Einsen. Danach wird weitergewürfelt.")
            }
            Toggle(isOn: $optionen.jule) {
                erklaerung("Jule 4-2-1", "4-2-1 ist ein besonderer Wurf: 7 Deckel, zwischen Schock aus und Schock 6.")
            }
            regel("Deckel", "So viele Deckel liegen pro Hälfte im Stock.") {
                Picker("Deckel", selection: $optionen.deckel) {
                    Text("13").tag(13)
                    Text("15").tag(15)
                }
            }
            regel("Spiellänge", "Mit Finale: zwei Hälften, bei zwei verschiedenen Verlierern ein Finale. Sonst zählt eine einzige Hälfte.") {
                Picker("Spiellänge", selection: $optionen.spiellaenge) {
                    Text("Partie mit Finale").tag(Optionen.Spiellaenge.partie)
                    Text("Nur eine Hälfte").tag(Optionen.Spiellaenge.haelfte)
                }
            }
            Button("Auf Standard zurücksetzen") { optionen = .standard }
                .disabled(optionen == .standard)
        } header: {
            Text("Hausregeln")
        } footer: {
            Text("Gilt für neue Partien und für eine Partie, in der noch nicht gewürfelt wurde.")
        }
    }

    private func erklaerung(_ titel: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(titel)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func regel<P: View>(_ titel: LocalizedStringKey, _ text: LocalizedStringKey, @ViewBuilder picker: () -> P) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            erklaerung(titel, text)
            picker().pickerStyle(.segmented).labelsHidden()
        }
    }
}
