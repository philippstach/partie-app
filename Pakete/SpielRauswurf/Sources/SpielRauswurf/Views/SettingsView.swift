// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas
import Baukasten


/// Hausregeln als eigene Seite (aus „Neue Partie“).
struct HausregelnView: View {
    @Binding var optionen: Optionen
    /// RT-010: Zahl der Mitspielenden, wenn bekannt (Teams gelten nur mit genau vier).
    var spieler: Int? = nil

    var body: some View {
        // F21-006 (sechster Anlauf): Ohne eigenen Stil zeigte die Form einen System-UISwitch, der als namenloses Kind unter der Zeile lag.
        // SchalterZeile (KlarGlas) zeichnet keinen UISwitch: eine Zeile = ein Element mit Namen.
        Form { HausregelnSections(optionen: $optionen, spieler: spieler) }
            .einstellungsSchalter()
            .navigationTitle(L("setup.hausregeln"))
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// Spielart (Familie · Offiziell · Kinder · Schnell · Streng) als Menü mit Erklärung; „Eigene Regeln“, wenn nichts passt.
struct SpielartWahl: View {
    @Binding var optionen: Optionen

    var body: some View {
        let aktuell = Spielart.erkennen(optionen)
        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            // N-004 (zweiter Anlauf): Vorher ein `Menu` mit eigener Beschriftung; `.accessibilityLabel` am Menu kam am Gerät nicht an
            // (Build 19, iPad mini: Knopf ohne Namen). Jetzt der Auswahl-Knopf des Systems: Er trägt den Titel „Spielart“ als Namen
            // und die gewählte Spielart als Wert, auch wenn die Beschriftung ausgeblendet ist. Der Text links ist nur Optik.
            HStack(spacing: 6) {
                Text(L("preset.titel")).foregroundStyle(.primary).accessibilityHidden(true)
                Spacer(minLength: 8)
                Picker(L("preset.titel"), selection: Binding(get: { aktuell }, set: { if let a = $0 { optionen = a.optionen } })) {
                    ForEach(Spielart.allCases) { art in Text(L("preset.\(art.rawValue)")).tag(Optional(art)) }
                    if aktuell == nil { Text(L("preset.eigene")).tag(Optional<Spielart>.none) }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .tint(Color.appFlaeche)
            }
            .frame(minHeight: Theme.tapSize)
            Text(aktuell.map { L("preset.\($0.rawValue).info") } ?? optionen.kurzfassung)
                .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Jede Hausregel mit einem Satz Erklärung.
struct HausregelnSections: View {
    @Binding var optionen: Optionen
    var spieler: Int? = nil
    /// RT-010: Mit Teams endet die Partie, sobald ein Team fertig ist; „Spielende“ hat dann keine Wirkung (Partie.teamsAktiv).
    private var teamsAktiv: Bool { optionen.teams && spieler == 4 }

    var body: some View {
        Section {
            SpielartWahl(optionen: $optionen)
        } header: {
            Text(L("preset.titel"))
        }
        Section {
            schalter("regel.rausPflicht", $optionen.rausPflicht)
            schalter("regel.startfeldRaeumen", $optionen.startfeldRaeumen)
            schalter("regel.schlagpflicht", $optionen.schlagpflicht)
            schalter("regel.dreiVersuche", $optionen.dreiVersuche)
            schalter("regel.sechsNochmal", $optionen.sechsNochmal)
            schalter("regel.zielUeberspringen", $optionen.zielUeberspringen)
            schalter("regel.startMitFigur", $optionen.startMitFigur)
            schalter("regel.rauswerfen", $optionen.rauswerfen)
            schalter("regel.teams", $optionen.teams)
            VStack(alignment: .leading, spacing: 6) {
                Text(L("regel.figuren"))
                Picker(L("regel.figuren"), selection: $optionen.figuren) {
                    ForEach([4, 3, 2], id: \.self) { Text("\($0)").tag($0) }
                }
                .pickerStyle(.segmented).labelsHidden()
                Text(L("regel.figuren.info")).font(.caption).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(L("regel.spielende"))
                Picker(L("regel.spielende"), selection: $optionen.spielende) {
                    Text(L("regel.spielende.erster")).tag(Optionen.Spielende.erster)
                    Text(L("regel.spielende.alle")).tag(Optionen.Spielende.alle)
                }
                .pickerStyle(.segmented).labelsHidden()
            }
            .disabled(teamsAktiv)   // RT-010: ausgegraut statt wirkungslos (nicht entfernt)
            Button(L("regel.zuruecksetzen")) { optionen = .standard }
                .disabled(optionen == .standard)
        } header: {
            Text(L("einst.hausregeln"))
        } footer: {
            Text(L("regel.abNaechster"))
        }
    }

    private func schalter(_ schluessel: String, _ wert: Binding<Bool>) -> some View {
        // F21-006 (sechster Anlauf): sichtbares Label (Name + Erklärung); Zusammenfassen und Tippen übernimmt SchalterZeile.
        Toggle(isOn: wert) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L(schluessel))
                Text(L(schluessel + ".info")).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
