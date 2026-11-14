// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

// Design-Runde 3 (Umbau E): Regeln der Partie auf der Spielseite (R4), Regeln mit Einführung und Regel-Frage (R5),
// Bestenliste. Die alten Funktionen aus dem Code sind damit wieder erreichbar. Die Spiellogik bleibt unberührt.

/// Karte „Regeln der Partie“ auf der Spielseite: fertige Pakete und „Eigene“. Die Wahl wird für die nächste Partie gespeichert.
public struct ZehnKStartOptionen: View {
    @State private var regeln = NeuAblage.regeln()
    @State private var eigeneOffen = false
    @State private var bestenOffen = false

    public init() {}

    private var paket: RulePreset? { RulePreset.matching(regeln) }
    private var eigeneAktiv: Bool { paket == nil || regeln.entryThreshold > 0 || regeln.multiples != .standard || regeln.threePairs }

    public var body: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Text("Regeln der Partie").font(.headline)
            VStack(spacing: Design.Abstand.xs) {
                ForEach(RulePreset.allCases) { p in zeile(p) }
                eigeneZeile
            }
            Text(RulesSummary.text(regeln)).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            HStack {
                Button("Bestenliste", systemImage: "trophy") { bestenOffen = true }
                Spacer(minLength: 0)
            }
            .font(.subheadline)
        }
        .padding(Design.Abstand.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.feldGrund, in: .rect(cornerRadius: 16))
        .sheet(isPresented: $eigeneOffen) {
            NeuRegelnBlatt(rules: $regeln) { eigeneOffen = false }.formBlatt(gross: true)
        }
        .sheet(isPresented: $bestenOffen) { NeuBestenliste().formBlatt() }
        .onChange(of: regeln) { _, neu in NeuAblage.sichern(regeln: neu) }
    }

    private func zeile(_ p: RulePreset) -> some View {
        let aktiv = paket == p && !eigeneAktiv
        return Button {
            regeln = p.apply(to: GameRules())
        } label: {
            HStack(spacing: 10) {
                Image(systemName: aktiv ? "checkmark.circle.fill" : "circle").foregroundStyle(aktiv ? Color.accentColor : Color.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(verbatim: p.title).font(.subheadline.weight(.semibold))
                    Text(verbatim: p.detail).font(.caption).foregroundStyle(.secondary).lineLimit(3).fixedSize(horizontal: false, vertical: true)   // T-036: nicht mit „…“ kürzen
                }
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(aktiv ? .isSelected : [])
    }

    private var eigeneZeile: some View {
        Button { eigeneOffen = true } label: {
            HStack(spacing: 10) {
                Image(systemName: eigeneAktiv ? "checkmark.circle.fill" : "slider.horizontal.3").foregroundStyle(eigeneAktiv ? Color.accentColor : Color.secondary)
                Text("Eigene Regeln …").font(.subheadline.weight(.semibold))
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(eigeneAktiv ? .isSelected : [])
    }
}

/// „Alle Regeln lesen“ auf der Spielseite: die ausführliche Regelseite mit Einführung und „Frag nach den Regeln“.
public struct ZehnKRegelnAnsicht: View {
    @State private var store = NeuAblage.neuerStore()
    @State private var preferences = AppPreferences(defaults: NeuAblage.defaults)

    public init() {}

    public var body: some View {
        RulesDetailView(active: NeuAblage.regeln())
            .environment(store)
            .environment(preferences)
    }
}

/// Bestenliste und Rekorde über alle beendeten Partien.
struct NeuBestenliste: View {
    @State private var store = NeuAblage.neuerStore()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let hall = store.hallOfFame
        NavigationStack {
            List {
                if hall.gameCount == 0 {
                    Text("Noch keine beendete Partie. Nach dem ersten Spiel stehen hier Rekorde und Siege.").foregroundStyle(.secondary)
                } else {
                    Section("Rekorde") {
                        if let r = hall.bestTurn { rekord("Bester Zug", r) }
                        if let r = hall.highestFinal { rekord("Höchster Endstand", r) }
                        if let r = hall.longestStreak { rekord("Längste Siegesserie", r) }
                    }
                    Section("Siege") {
                        ForEach(hall.rows.prefix(10)) { z in
                            HStack {
                                Text(verbatim: z.avatar)
                                Text(verbatim: z.name)
                                Spacer(minLength: 8)
                                Text("\(z.wins) von \(z.games)").foregroundStyle(.secondary).monospacedDigit()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Bestenliste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
    }

    private func rekord(_ titel: LocalizedStringKey, _ r: HallOfFame.Record) -> some View {
        HStack {
            Text(titel)
            Spacer(minLength: 8)
            Text(verbatim: "\(r.avatar) \(r.name) · \(Theme.points(r.value))").foregroundStyle(.secondary).monospacedDigit()
        }
    }
}
