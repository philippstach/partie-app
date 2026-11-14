// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

struct RulesDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppPreferences.self) private var preferences
    @Environment(GameStore.self) private var store
    @State private var bestaetigen = false
    /// Auf der Spielseite des Rahmens (`SchockenRegelnAnsicht`) aus: dort gibt es keine laufende Partie, die der Knopf ersetzen dürfte.
    /// ANNAHME (Frage an Philipp offen): Knopf dort ausgeblenden. Einblenden: `mitGefuehrter: true` in `SchockenRegelnAnsicht`.
    var mitGefuehrter = true

    /// Bauplan RS / Blatt 29: eine Regelseite für alle Spiele. Kopf: „Hausregeln, die gerade aktiv sind“ und der Knopf „Geführte Partie“ (bleiben).
    var body: some View {
        if let q = RegelLeseKatalog.quelle(fuer: "schocken") {
            RegelLeseAnsicht(quelle: q, spielName: "Schocken", spielID: "schocken", wissen: nil) {
                VStack(alignment: .leading, spacing: Design.Abstand.m) {
                    aktiveRegeln
                    if mitGefuehrter { Button {
                        if let z = store.zustand, z.phase != .partieVorbei { bestaetigen = true } else { gefuehrteStarten() }
                    } label: {
                        Label("Geführte Partie", systemImage: "graduationcap").frame(maxWidth: .infinity)
                    }
                    .sichtbarBordered().controlSize(.large) }
                }
            }
            .alert("Partie beenden?", isPresented: $bestaetigen) {
                Button("Neu beginnen", role: .destructive) { gefuehrteStarten() }
                Button("Abbrechen", role: .cancel) {}
            } message: { Text("Der Spielstand geht verloren.") }
        } else { alteSeite }
    }

    private var alteSeite: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Design.Abstand.m) {
                    block("Ziel", "Man will nicht verlieren. Wer am Ende einer Hälfte alle Deckel hat, verliert diese Hälfte. Wer zwei Hälften oder das Finale verliert, verliert die Partie.")
                    block("Ablauf einer Runde", "Alle würfeln nacheinander mit 3 Würfeln. Der Vorleger darf bis zu 3-mal werfen; wie viele Würfe er benutzt, ist für alle anderen das Maximum. Nach jedem Wurf kann man stehen lassen oder Würfel herauslegen (im Standard nur Einsen, mit der Hausregel „Beliebig“ alle) und die übrigen neu werfen. Zwei Sechsen ergeben eine Eins, drei Sechsen bis zu zwei Einsen. Wer am schlechtesten würfelt, verliert die Runde.")
                    rangfolge
                    block("Stock und Verteilen", "Solange Deckel im Stock liegen, nimmt der Verlierer so viele Deckel aus dem Stock, wie der beste Wurf wert ist. Ist der Stock leer, gibt der Gewinner dem Verlierer Deckel ab. Wer dann keine Deckel mehr hat, scheidet aus.")
                    block("Hälften und Finale", "Hälfte 1 und Hälfte 2 werden nacheinander gespielt. Hat jemand beide verloren, hat er die Partie verloren. Sonst spielen die beiden Hälften-Verlierer ein Finale gegeneinander.")
                    aktiveRegeln
                    if mitGefuehrter { Button {
                        if let z = store.zustand, z.phase != .partieVorbei { bestaetigen = true } else { gefuehrteStarten() }
                    } label: {
                        Label("Geführte Partie", systemImage: "graduationcap").frame(maxWidth: .infinity)
                    }
                    .sichtbarBordered().controlSize(.large) }
                }
                .padding()
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Color.seitenGrund)
            .alert("Partie beenden?", isPresented: $bestaetigen) {
                Button("Neu beginnen", role: .destructive) { gefuehrteStarten() }
                Button("Abbrechen", role: .cancel) {}
            } message: { Text("Der Spielstand geht verloren.") }
            .navigationTitle("Regeln")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
    }

    private func block(_ titel: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(titel)
            Text(text).font(.subheadline)
        }
        .card()
    }

    private var rangfolge: some View {
        let jule = preferences.hausregeln.jule
        var zeilen: [(wuerfel: [Int], name: String, deckel: String)] = [
            ([1, 1, 1], String(localized: "Schock aus"), preferences.hausregeln.schockAusEndet ? String(localized: "alle") : "\(preferences.hausregeln.deckel)"),
        ]
        if jule { zeilen.append(([4, 2, 1], String(localized: "Jule"), "7")) }
        zeilen += [
            ([1, 1, 6], String(localized: "Schock 6 … 2"), "6 … 2"),
            ([6, 6, 6], String(localized: "General"), "3"),
            ([4, 5, 6], String(localized: "Straße"), "2"),
            ([6, 5, 3], String(localized: "Zahl"), "1"),
        ]
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Rangfolge, vom besten zum schlechtesten")
            ForEach(zeilen.indices, id: \.self) { i in
                HStack(spacing: 10) {
                    HStack(spacing: Design.Abstand.xs) { ForEach(0..<3, id: \.self) { DieView(wert: zeilen[i].wuerfel[$0], size: 26) } }
                        .accessibilityHidden(true)
                    Text(zeilen[i].name).font(.subheadline.weight(.semibold))
                    Spacer()
                    HStack(spacing: Design.Abstand.xs) {
                        Text(zeilen[i].deckel).font(.subheadline.monospacedDigit())
                        DeckelView(size: 14)
                    }
                }
                .accessibilityElement(children: .combine)
            }
            Text("General und Straße zählen nur, wenn alle drei Würfel in einem Wurf gefallen sind. Bei gleichem Wurf gewinnt, wer weniger Würfe gebraucht hat, danach, wer früher dran war.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .card()
    }

    private var aktiveRegeln: some View {
        let o = preferences.hausregeln
        return VStack(alignment: .leading, spacing: 6) {
            SectionLabel("Hausregeln, die gerade aktiv sind")
            Text(o.herauslegen == .einsen ? "Herauslegen: nur Einsen" : "Herauslegen: beliebige Würfel").font(.subheadline)
            Text(o.sechsenUmdrehen ? "Sechsen umdrehen: an" : "Sechsen umdrehen: aus").font(.subheadline)
            Text(o.jule ? "Jule 4-2-1: an" : "Jule 4-2-1: aus").font(.subheadline)
            Text(o.schockAusEndet ? "Schock aus beendet die Hälfte: an" : "Schock aus beendet die Hälfte: aus").font(.subheadline)
            Text("Deckel: \(o.deckel)").font(.subheadline)
            Text(o.spiellaenge == .partie ? "Partie mit Finale" : "Nur eine Hälfte").font(.subheadline)
        }
        .card()
    }

    private func gefuehrteStarten() {
        preferences.gefuehrtGestartet = true
        preferences.gezeigteHinweise = []
        dismiss()
        store.gefuehrtePartie(du: String(localized: "Du"))
    }
}


/// Absturzfix (Schocken „Alle Regeln lesen“ auf der Spielseite, bugs/ABSTURZ-schocken-regeln.md): legt Store und Einstellungen selbst an,
/// weil die Spielseite des Rahmens sie nicht in die Umgebung setzt. Wie `ZehnKRegelnAnsicht` bei Zehntausend.
struct SchockenRegelnAnsicht: View {
    @State private var store = NeuAblage.neuerStore()
    @State private var preferences = AppPreferences(defaults: NeuAblage.defaults)
    var body: some View {
        RulesDetailView(mitGefuehrter: false).environment(store).environment(preferences)
    }
}
