// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Einblendungen über dem Tisch: Erst-Hinweis, „Fertig spielen“, Festgefahren, Aufgegeben. Je eine kleine Karte, nie über den Karten.
struct NeuHinweise: View {
    var maxBreite: CGFloat
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var store: any GameSession { app.session }
    private var uebergang: AnyTransition { reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity) }
    private var bewegung: Animation { reduceMotion ? .linear(duration: 0.15) : .spring(response: 0.35, dampingFraction: 0.85) }

    var body: some View {
        VStack(spacing: Design.Abstand.m) {
            if store.gaveUp, !store.replaying { aufgegeben.transition(uebergang) }
            if let h = store.activeFirstHint, !router.showMenu, !store.isWon, !store.stuck, !store.gaveUp { erstHinweis(h).transition(uebergang) }
            if store.stuck, !store.stuckDismissed, !store.isWon, !store.gaveUp { festgefahren.transition(uebergang) }
        }
        .frame(maxWidth: maxBreite)
        .padding(.horizontal, 12).padding(.bottom, 10)
        .animation(bewegung, value: store.activeFirstHint)
        .animation(bewegung, value: store.stuck && !store.stuckDismissed)
        .animation(bewegung, value: store.gaveUp)
    }

    @ViewBuilder private func erstHinweis(_ hint: FirstHint) -> some View {
        if Design.ist(.tinte) {
            // Design-Runde 3: heller, runder Hinweis auf dem Filz statt des schwarzen Kastens
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "lightbulb.fill").foregroundStyle(Color.yellow)
                Text(hint.text).font(.caption).foregroundStyle(Color.white.opacity(0.92))
                Spacer(minLength: 0)
            }
            .padding(14).frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.13), in: .rect(cornerRadius: 18, style: .continuous))
            .onTapGesture { store.dismissFirstHint() }
            .accessibilityElement(children: .combine)
        } else {
            erstHinweisAlt(hint)
        }
    }

    private func erstHinweisAlt(_ hint: FirstHint) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").foregroundStyle(Color.accentText)
            Text(hint.text).font(.caption).foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity)
        .glasFlaeche(.rect(cornerRadius: Design.Ecke.karte))
        .onTapGesture { store.dismissFirstHint() }
        .accessibilityElement(children: .combine)
    }

    private var festgefahren: some View {
        karte {
            Text("Keine sinnvollen Züge mehr").font(.headline)
            HStack(spacing: Design.Abstand.s) {
                if store.canUndo { Button("Zurück") { store.undo() }.tischNebenKnopf().buttonBorderShape(.capsule) }
                Button("Neues Spiel") { app.newGame() }.hauptKnopf()
                Button("Gleiche Partie") { app.restartSameDeal() }.tischNebenKnopf().buttonBorderShape(.capsule)
            }
        }
        .gesture(DragGesture().onEnded { if $0.translation.height > 30 { store.stuckDismissed = true } })
    }

    private var aufgegebenText: LocalizedStringKey {
        if store.solutionViewed { return "Lösung angesehen." }
        if store.solutionAvailable { return "Diese Partie war lösbar. Lösung ansehen?" }
        if store.mode.kind == .freecell { return "Alle FreeCell-Partien außer 11982 sind lösbar." }
        return "Für zufällige Partien gibt es keine gespeicherte Lösung."
    }

    private var aufgegeben: some View {
        karte {
            Text(aufgegebenText).font(.headline).multilineTextAlignment(.center)
            HStack(spacing: Design.Abstand.s) {
                if store.solutionAvailable, !store.solutionViewed {
                    Button("Ansehen") { store.viewSolution() }.hauptKnopf()
                    Button("Neues Spiel") { app.newGame() }.tischNebenKnopf().buttonBorderShape(.capsule)
                } else {
                    Button("Neues Spiel") { app.newGame() }.hauptKnopf()
                    Button("Gleiche Partie") { app.restartSameDeal() }.tischNebenKnopf().buttonBorderShape(.capsule)
                }
            }
        }
    }

    private func karte<Inhalt: View>(@ViewBuilder _ inhalt: () -> Inhalt) -> some View {
        VStack(spacing: Design.Abstand.m, content: inhalt)
            .font(.system(.subheadline, design: Design.zahlDesign).weight(.semibold))
            .foregroundStyle(.primary)
            .padding(16).frame(maxWidth: .infinity)
            .glasFlaeche(.rect(cornerRadius: Theme.leistenRadius))
    }
}

/// Abspieler der Lösung: „Zug 34 / 172“, ◀ ⏸/▶ ▶ und „Fertig“
struct NeuAbspieler: View {
    @Environment(AppModel.self) private var app
    private var store: any GameSession { app.session }

    var body: some View {
        VStack(spacing: Design.Abstand.xs) {
            Text("Zug \(store.solutionIndex) / \(store.solutionCount)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            HStack {
                knopf("chevron.left.circle", "Schritt zurück", gesperrt: store.solutionIndex == 0) { store.solutionStep(-1) }
                Spacer()
                knopf(store.solutionPaused ? "play.circle.fill" : "pause.circle.fill", store.solutionPaused ? "Abspielen" : "Pause", gross: true) { store.toggleSolutionPause() }
                Spacer()
                knopf("chevron.right.circle", "Schritt vor", gesperrt: store.solutionIndex >= store.solutionCount) { store.solutionStep(1) }
                Spacer()
                Button("Fertig") { store.endSolution() }.font(.headline).frame(minHeight: Theme.tapSize)
            }
        }
        .buttonStyle(.plain).foregroundStyle(Color.accentText)
        .padding(.horizontal, 28).padding(.bottom, 6).frame(minHeight: 72)
    }

    private func knopf(_ symbol: String, _ titel: LocalizedStringKey, gesperrt: Bool = false, gross: Bool = false, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            Image(systemName: symbol).font(gross ? .largeTitle : .title).frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize)
        }
        .disabled(gesperrt).accessibilityLabel(Text(titel))
    }
}
