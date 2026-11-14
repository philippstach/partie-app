// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

extension GameMode {
    /// Name mit Modus für den Teilen-Text: „Klondike“, „Klondike (3 Karten)“, „Spider (2 Farben)“
    var shareName: String {
        switch kind {
        case .klondike: option == 3 ? "\(kind.title) (" + String(localized: "3 Karten") + ")" : kind.title
        case .spider: "\(kind.title) (" + (option == 1 ? String(localized: "1 Farbe") : String(localized: "\(option) Farben")) + ")"
        default: kind.title
        }
    }
}

extension GameMode {
    /// „Klondike · 1 Karte“, „Spider · 2 Farben“, sonst nur der Name
    var titleLine: String {
        switch kind {
        case .klondike: "\(kind.title) · " + (option == 3 ? String(localized: "3 Karten") : String(localized: "1 Karte"))
        case .spider: "\(kind.title) · " + (option == 1 ? String(localized: "1 Farbe") : String(localized: "\(option) Farben"))
        default: kind.title
        }
    }
}

/// Menü → „Partie wählen…“: Nummer eingeben, die lösbare Partie dieser Nummer im gewählten Spiel starten.
struct PickDealView: View {
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @State private var text = ""
    @State private var shakes = 0
    @State private var invalid = false
    @FocusState private var focused: Bool

    private var mode: GameMode { app.newGameMode }
    private var maxNumber: Int { DealCatalog.shared.maxNumber(mode: mode) ?? 0 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SectionLabel("Partie wählen")
                Text(verbatim: mode.titleLine).font(.system(.title3, design: Design.zahlDesign).weight(.bold))
                Text("Gib eine Nummer von 1 bis \(maxNumber) ein.").font(.subheadline).foregroundStyle(.secondary)
                TextField("Nummer", text: $text)
                    .keyboardType(.numberPad)
                    .focused($focused)
                    .font(.system(.title, design: Design.zahlDesign).weight(.bold)).monospacedDigit()
                    .padding(12)
                    .background(Color(.tertiarySystemFill), in: .rect(cornerRadius: Design.Ecke.feld))
                    .overlay { if invalid { RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(Color(.systemRed).opacity(0.14)) } }
                    .keyframeAnimator(initialValue: 0.0, trigger: shakes) { content, dx in content.offset(x: dx) } keyframes: { _ in
                        KeyframeTrack {
                            CubicKeyframe(8, duration: 0.05)
                            CubicKeyframe(-8, duration: 0.08)
                            CubicKeyframe(8, duration: 0.08)
                            CubicKeyframe(0, duration: 0.05)
                        }
                    }
                    .onChange(of: text) { _, new in
                        text = String(new.filter(\.isNumber).prefix(6))
                        invalid = false
                    }
                    .onSubmit(start)
                if invalid {
                    Text("Ungültig – 1 bis \(maxNumber)").font(.caption).foregroundStyle(.red)
                }
                Button(action: start) { Text("Spielen").frame(maxWidth: .infinity) }
                    .hauptKnopf().controlSize(.large)
                Text("Die laufende Partie wird beendet. Statistik und Stufen zählen wie bei jeder lösbaren Partie, das Tagesspiel bleibt unberührt.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .card()
            .padding(16)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color.seitenGrund)
        .navigationTitle("Partie wählen")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
    }

    private func start() {
        if let n = Int(text), app.startNumbered(n, mode: mode) {
            router.path = []
            router.leaveToGame()
        } else {
            invalid = true
            shakes += 1
            SpielHaptik.warning()
        }
    }
}
