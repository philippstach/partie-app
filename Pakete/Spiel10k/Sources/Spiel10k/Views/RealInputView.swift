// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

/// Echte Würfel, Eingabeart „Punkte eintippen“ (1.0.1, Doku/SPEC-1.0.1-B.md §1): große Punkte-Kacheln,
/// die sich aufaddieren, die Summe groß darüber. Nach dem Eintragen bietet die App der nächsten Person
/// 3 s lang „Übernehmen +X“ an (`PointsOfferBanner` in der Leiste unten).
/// „Niete“ und „Eintragen“ stehen in der festen Leiste unten (`RealActionBar`).
struct RealInputView: View {
    @Environment(GameStore.self) private var store
    @Environment(TurnInput.self) private var input
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.tischGross) private var tischGross

    /// Kacheln: jeder Tipp addiert
    static let tiles = [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 1_000]

    var body: some View {
        VStack(spacing: 14) {
            if let inherited = inheritedInfo {
                Label("+\(Theme.points(inherited.points)) übernommen von \(inherited.name)",
                      systemImage: "arrow.down.forward.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.1), in: .rect(cornerRadius: 10))
            }

            display

            tileGrid
        }
        .card()
        .sensoryFeedback(.selection, trigger: input.tiles.count) { _, _ in store.game != nil && SpieleHaptik.erlaubt }
    }

    /// Nach dem Übernehmen: übernommene Punkte und von wem
    private var inheritedInfo: (points: Int, name: String)? {
        let t = store.turn
        guard let from = t.inheritedFrom, let game = store.game, game.players.indices.contains(from) else { return nil }
        return (t.inheritedPoints, game.players[from].name)
    }

    // MARK: - Summe

    private var display: some View {
        VStack(spacing: 2) {
            SectionLabel(verbatim: inheritedInfo == nil ? String(localized: "Punkte dieses Zugs") : String(localized: "Dazu in diesem Zug"))
            HStack(spacing: Design.Abstand.m) {
                Text(Theme.points(input.points))
                    .font(.system(size: tischGross ? 96 : 64, weight: .heavy, design: Design.zahlDesign))   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                    .monospacedDigit()
                    .foregroundStyle(input.points == 0 ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.tint))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: input.points)
                    .accessibilityLabel("Summe \(input.points) Punkte")
            }
            .frame(maxWidth: .infinity)
            .overlay(alignment: .trailing) {
                Button {
                    withAnimation(.snappy) { input.removeLastTile() }
                } label: {
                    Image(systemName: "delete.left")
                        .font(.title2.weight(.semibold))
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(PointsKeyStyle())
                .foregroundStyle(.secondary)
                .disabled(input.tiles.isEmpty)
                .accessibilityLabel("Letzte Kachel entfernen")
                .keyboardShortcut(sizeClass == .regular ? KeyboardShortcut(.delete, modifiers: []) : nil)
            }

            HStack(spacing: Design.Abstand.s) {
                // Hinweis darf umbrechen (SE: wurde vorne abgeschnitten, Build 11); nur die lange
                // Aufschlüsselung „100 + 100 + 50 …“ wird vorne gekürzt, damit das Neueste sichtbar bleibt
                Text(breakdown)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(input.tiles.isEmpty ? 2 : 1)
                    .truncationMode(input.tiles.isEmpty ? .tail : .head)
                if !input.tiles.isEmpty {
                    Button("Leeren") { withAnimation(.snappy) { input.clearTiles() } }
                        .font(.footnote.weight(.semibold))
                        .buttonStyle(.borderless)
                }
            }
            .frame(minHeight: 22)
        }
    }

    /// „100 + 100 + 50“ bzw. ein kurzer Hinweis, solange nichts getippt ist
    private var breakdown: String {
        input.tiles.isEmpty
            ? String(localized: "Tippe auf die Kacheln, sie werden zusammengezählt.")
            : input.tiles.map { Theme.points($0) }.joined(separator: " + ")
    }

    // MARK: - Kacheln

    private var tileGrid: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(0..<3) { row in
                GridRow {
                    ForEach(0..<3) { col in tile(Self.tiles[row * 3 + col]) }
                }
            }
            GridRow {
                tile(500)
                tile(1_000).gridCellColumns(2)
            }
        }
        // Spieltisch: feste große Kacheln mittig statt über die volle Breite (SPEC-1.1 §3)
        .frame(maxWidth: tischGross ? 600 : .infinity)
    }

    private func tile(_ value: Int) -> some View {
        Button {
            withAnimation(.snappy) { input.addTile(value) }
        } label: {
            Text("+\(Theme.points(value))")
                .font(.system(tischGross ? .title : .title3, design: Design.zahlDesign, weight: .bold))
                .monospacedDigit()
                .lineLimit(1).minimumScaleFactor(0.7)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, minHeight: tischGross ? 96 : 54)
                .background(Color.accentColor.opacity(value == 1_000 ? 0.2 : 0.12), in: .rect(cornerRadius: Design.Ecke.feld))
        }
        .buttonStyle(PointsKeyStyle())
        .hoverEffect(.lift)
        .accessibilityLabel("plus \(value)")
    }
}

/// Feste Leiste unten bei „Punkte eintippen“: „Niete“ und „Eintragen“ gleich groß.
struct RealActionBar: View {
    @Environment(GameStore.self) private var store
    @Environment(TurnInput.self) private var input
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.tischGross) private var tischGross

    private var valid: Bool { GameStore.isValidEntry(input.points) }

    /// Nebeneinander, bei sehr großer Schrift untereinander
    var body: some View {
        VStack(spacing: 10) {
            if let offer = store.game?.offer, let game = store.game {
                PointsOfferBanner(offer: offer, game: game)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            buttons
        }
        .animation(.snappy, value: store.game?.offer)
    }

    private var buttons: some View {
        AdaptiveStack {
            Button(role: .destructive) {
                input.niete(store)
            } label: {
                Label("Niete", systemImage: "xmark.octagon")
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
            }
            .zweitKnopf()
            .tint(.red)
            .disabled(input.cooldown)
            .accessibilityHint("Zug ohne Punkte beenden, dann ist die nächste Person dran")

            Button {
                withAnimation(.snappy) { input.submitPoints(store) }
            } label: {
                Text(valid ? String(localized: "Eintragen +\(Theme.points(input.points))") : String(localized: "Eintragen"))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .minimumScaleFactor(0.75)
                    .frame(maxWidth: .infinity)
            }
            .hauptKnopf()
            .disabled(!valid || input.cooldown)
            .keyboardShortcut(sizeClass == .regular ? KeyboardShortcut(.return, modifiers: []) : nil)
        }
        .controlSize(tischGross ? .extraLarge : .large)
        .font(.headline)
    }
}

/// Taste, die beim Drücken sichtbar nachgibt (wie die Augen-Tasten).
private struct PointsKeyStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? 1 : 0.4)
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
            .contentShape(.rect)
    }
}

/// Punkte eintippen (1.0.1 (8)): „Übernehmen +X“ für die nächste Person, ca. 3 s (VoiceOver 10 s).
/// Antippen übernimmt; sonst verfällt das Angebot. Eintragen oder Niete gilt ebenfalls als „nicht übernommen“.
struct PointsOfferBanner: View {
    @Environment(GameStore.self) private var store
    let offer: InheritOffer
    let game: GameState
    @State private var progress: CGFloat = 1

    static func duration(voiceOver: Bool) -> Double { voiceOver ? 10 : 3 }

    var body: some View {
        let from = game.players.indices.contains(offer.from) ? game.players[offer.from].name : ""
        Button {
            store.acceptOffer()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.down.forward.circle.fill").font(.title2)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Übernehmen +\(Theme.points(offer.points))").font(.headline)
                    Text("von \(from) · sonst einfach eintippen").font(.caption).opacity(0.85)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color.onAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.accentColor, in: .rect(cornerRadius: 14))
            .overlay(alignment: .bottomLeading) {
                // Ablaufbalken
                GeometryReader { geo in
                    Capsule().fill(Color.onAccent.opacity(0.5))
                        .frame(width: geo.size.width * progress, height: 3)
                }
                .frame(height: 3)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
                .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Übernehmen: plus \(offer.points) Punkte von \(from)")
        .accessibilityHint("Ohne Antippen verfällt das Angebot.")
        .task(id: offer) {
            let seconds = Self.duration(voiceOver: UIAccessibility.isVoiceOverRunning)
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: String(localized: "Übernehmen möglich: plus \(offer.points) Punkte von \(from)"))
            }
            progress = 1
            withAnimation(.linear(duration: seconds)) { progress = 0 }
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, store.game?.offer == offer else { return }
            withAnimation(.snappy) { store.declineOffer() }
        }
    }
}
