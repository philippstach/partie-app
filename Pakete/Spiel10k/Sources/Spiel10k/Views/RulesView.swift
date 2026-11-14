// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

struct RulesDetailView: View {
    @Environment(\.dismiss) private var dismiss
    /// Einführung ab dieser Seite (Kapitel)
    @State private var intro: IntroStart?
    @Environment(AppPreferences.self) private var preferences
    @Environment(GameStore.self) private var store

    /// Regeln des laufenden Spiels; `nil` = allgemeine Regeln mit Varianten
    var active: GameRules? = nil

    private var rules: [(String, String)] { RulesText.sections(for: active) }

    /// Bauplan RS / Blatt 29: eine Regelseite für alle Spiele. Kopf: die Zeile „Einführung ansehen“; „Einzelne Kapitel“ entfällt (der Knopf „Inhalt“ ersetzt sie).
    var body: some View {
        if let q = RegelLeseKatalog.quelle(fuer: "10k") {
            RegelLeseAnsicht(quelle: q, spielName: "Zehntausend", spielID: "10k", wissen: ZehnkRegelWissen(rules: chatRules, imSpiel: active != nil)) {
                Button { intro = IntroStart(page: 0) } label: {
                    Label("Einführung ansehen", systemImage: "sparkles").frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain).padding(12)
                .background(Color.kartenGrund, in: .rect(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.linie, lineWidth: 1))
            }
            .einfuehrung(item: $intro) { start in OnboardingView(rules: introRules, startPage: start.page) }
        } else { alteSeite }
    }

    private var alteSeite: some View {
        NavigationStack {
            List {
                Section {
                    Button("Einführung ansehen", systemImage: "sparkles") { intro = IntroStart(page: 0) }
                    DisclosureGroup("Einzelne Kapitel") {
                        ForEach(OnboardingPage.chapters(for: introRules), id: \.index) { chapter in
                            Button("\(chapter.index + 1). \(chapter.title)") { intro = IntroStart(page: chapter.index) }
                        }
                    }
                }
                Section {
                    Text("Zehntausend ist ein Würfelklassiker. Auch bekannt als 10k, Zonk oder Farkle.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ForEach(rules, id: \.0) { title, text in
                    VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                        Text(NSLocalizedString(title, comment: "Regelabschnitt")).font(.headline).foregroundStyle(.tint)
                        Text(text).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .einfuehrung(item: $intro) { start in OnboardingView(rules: introRules, startPage: start.page) }
            .navigationTitle(active == nil ? String(localized: "Regeln") : String(localized: "Regeln dieses Spiels"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    BlattSchliessenKnopf { dismiss() }   // Fund 23/26/76: überall dasselbe runde Schließen-Kreuz statt Textknopf „Fertig“
                }
            }
        }
        // KI-3: Knopf „Frag nach den Regeln“ unten, wie in allen Spielen (nur mit Apple Intelligence sichtbar).
        // Aus dem Regelblatt des Rahmens heraus sitzt die Leiste schon dort; dann bleibt es bei einer.
        .regelFrageLeiste(spielID: "10k", wissen: ZehnkRegelWissen(rules: chatRules, imSpiel: active != nil))
    }
}

private struct IntroStart: Identifiable {
    let page: Int
    var id: Int { page }
}

private extension RulesDetailView {
    /// Einführung mit den Regeln dieses Spiels, sonst Standard
    var introRules: GameRules { active ?? GameRules() }

    /// Chat: Regeln dieses Spiels, sonst die zuletzt eingestellten
    var chatRules: GameRules { active ?? store.lastSetup?.settings.rules ?? GameRules() }
}
