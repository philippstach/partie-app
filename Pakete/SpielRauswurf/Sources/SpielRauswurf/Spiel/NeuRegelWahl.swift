// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Karten im Neues-Spiel-Blatt des Rahmens: Spielart, Hausregeln, Teams und (mit Computern) die Stärke.
/// B18: Es gibt nur noch EINEN Startschritt; die frühere Seite „Regeln dieser Partie“ mit eigenem „Los geht's“ entfällt.
/// Die Werte liegen in den Einstellungen des Spiels und werden beim Start der Partie gelesen.
struct RauswurfOptionen: View {
    static let liebSchluessel = "rauswurf.neu.lieb"
    let eintraege: [SpielerEintrag]
    @State private var prefs = RauswurfOptionen.einstellungen()
    @State private var stufe = ComputerStufe.gespeichert(NeuLogik.id)
    @AppStorage(RauswurfOptionen.liebSchluessel) private var lieb = false
    @State private var hausregeln = false
    @Environment(\.dynamicTypeSize) private var schriftGroesse

    static func einstellungen() -> AppPreferences {
        AppPreferences(defaults: UserDefaults(suiteName: "de.philippstach.partie.rauswurf-neu") ?? .standard)
    }

    private var hatComputer: Bool { eintraege.contains { $0.art == "computer" } }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Spielart", systemImage: "square.grid.2x2").font(.headline).foregroundStyle(Color.accentText)
                SpielartWahl(optionen: Bindable(prefs).hausregeln)
                Button { hausregeln = true } label: {
                    // A-005: In den Bedienungshilfe-Größen stehen Kurzfassung und „Hausregeln“ untereinander statt nebeneinander (die Zeile wurde zu hoch und lag unter „Los geht's“)
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text(prefs.hausregeln.kurzfassung).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                            Spacer()
                            Text("Hausregeln").font(.subheadline.weight(.semibold))
                            Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color(.tertiaryLabel))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Hausregeln").font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(Color(.tertiaryLabel))
                            }
                            Text(prefs.hausregeln.kurzfassung).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.leading)
                        }
                    }
                    .frame(minHeight: Theme.tapSize).contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Hausregeln"))
                .accessibilityValue(Text(prefs.hausregeln.kurzfassung))
            }
            .frame(maxWidth: .infinity, alignment: .leading).card()
            if eintraege.count == 4 { teamsKarte }
            if hatComputer {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Stärke des Computers", systemImage: "cpu").font(.headline).foregroundStyle(Color.accentText)
                    // N-017: Das Segment wächst nicht mit der Schrift; in den Bedienungshilfe-Größen stattdessen ein Menü mit vollem Text
                    if schriftGroesse.isAccessibilitySize {
                        ComputerStufePicker(spiel: NeuLogik.id, stufe: $stufe).pickerStyle(.menu).labelsHidden().disabled(lieb)
                    } else {
                        ComputerStufePicker(spiel: NeuLogik.id, stufe: $stufe).pickerStyle(.segmented).labelsHidden().disabled(lieb)
                    }
                    Toggle("Computer lässt Menschen gewinnen", isOn: $lieb).font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading).card()
            }
        }
        .sheet(isPresented: $hausregeln) {
            NavigationStack { HausregelnView(optionen: Bindable(prefs).hausregeln, spieler: eintraege.count).einstellungsSchliessen() }
        }
    }

    /// B6: Bei vier Spielern Teams 2 gegen 2 mit sichtbarer Paarung (gegenübersitzende Plätze 1+3 gegen 2+4).
    private var teamsKarte: some View {
        let n = eintraege.map { $0.name.isEmpty ? String(localized: "Spieler") : $0.name }
        return VStack(alignment: .leading, spacing: 10) {
            // T-051: Ein einfacher Toggle in einer Karte außerhalb eines Formulars schaltet nur über den kleinen System-Schalter rechts,
            // ein Tipp auf die Zeile (Text, Symbol) tat nichts. Wie in den Regelblättern der anderen Spiele: SchalterZeile, die ganze Zeile
            // ist ein Element mit Namen und schaltet. Der Wert wird ausdrücklich zurückgeschrieben (ganzes `Optionen`, damit das `didSet`
            // der Einstellungen sicher speichert).
            Toggle(isOn: Binding(get: { prefs.hausregeln.teams }, set: { neu in var o = prefs.hausregeln; o.teams = neu; prefs.hausregeln = o })) {
                Label("Teams 2 gegen 2", systemImage: "person.2.fill").font(.headline).foregroundStyle(Color.accentText)
            }
            .einstellungsSchalter()
            if prefs.hausregeln.teams {
                Text("\(n[0]) + \(n[2]) gegen \(n[1]) + \(n[3])").font(.subheadline.weight(.semibold))
                Text("Gegenübersitzende spielen zusammen. Ein fertiger Spieler setzt aus, sein Partner spielt weiter. Den Partner schlägst du nicht. Das Team gewinnt, sobald beide alle Figuren im Ziel haben.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).card()
    }
}
