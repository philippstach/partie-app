// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

/// Identifiziert einen Spieler für `.sheet(item:)`
struct PlayerRef: Identifiable, Equatable {
    let id: Int
}

extension EnvironmentValues {
    /// Öffnet die Spieler-Details; `nil` = gerade nicht möglich (z. B. während „Übernehmen?“)
    @Entry var showPlayerDetail: ((Int) -> Void)? = nil
}

/// Macht eine Spielerzeile antippbar, wenn die Details verfügbar sind.
struct PlayerDetailTap: ViewModifier {
    @Environment(\.showPlayerDetail) private var show
    let player: Int

    func body(content: Content) -> some View {
        if let show {
            content
                .contentShape(.rect)
                .onTapGesture { show(player) }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Zeigt Details zu dieser Person")
        } else {
            content
        }
    }
}

/// Spieler-Details im laufenden Spiel – nur lesend, keine Aktionen.
struct PlayerDetailSheet: View {
    let game: GameState
    let player: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let p = game.players[player]
        let stats = PlayerStats(game: game, player: player)
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Abstand.m) {
                    header(p, stats)
                    statsGrid(stats)
                    if !stats.recent.isEmpty {
                        recentTurns(stats)
                    }
                    if game.log.count > 0 {
                        ScoreChart(game: game, height: 160, interactive: false, initialHighlight: player)
                    }
                }
                .padding()
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
            .background(Color.seitenGrund)
            .navigationTitle(p.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Teile

    private func header(_ p: Player, _ s: PlayerStats) -> some View {
        HStack(spacing: 14) {
            AvatarAbzeichen(avatar: p.avatar, farbe: p.color, groesse: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(Theme.points(s.score))
                    .font(.system(.title, design: Design.zahlDesign, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(s.score < 0 ? .red : p.textColor)
                Text(placeText(s))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func placeText(_ s: PlayerStats) -> String {
        var parts = [String(localized: "Platz \(s.rank) von \(game.players.count)")]
        if s.behindLeader > 0 {
            parts.append(String(localized: "\(Theme.points(s.behindLeader)) hinter Platz 1"))
        } else if game.players.filter({ $0.score == s.score }).count > 1 {
            parts.append(String(localized: "gleichauf vorne"))
        } else {
            parts.append("vorne")
        }
        parts.append(s.toGoal > 0 ? String(localized: "noch \(Theme.points(s.toGoal)) bis zum Ziel") : String(localized: "Ziel erreicht"))
        return parts.joined(separator: " · ")
    }

    private func statsGrid(_ s: PlayerStats) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Design.Abstand.s) {
            tile(String(localized: "Bester Zug"), Theme.points(s.bestTurn))
            tile(String(localized: "Schnitt pro Zug"), s.average.map { Theme.points($0) } ?? "–")
            tile(String(localized: "Nieten gesamt"), "\(s.nieten)")
            tile(String(localized: "Nieten in Folge"), "\(s.streak)",
                 warning: s.penaltyThreatened ? String(localized: "Bei der nächsten Niete −\(Theme.points(game.settings.penalty))") : nil)
        }
    }

    private func tile(_ title: String, _ value: String, warning: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            SectionLabel(verbatim: title)
            Text(value)
                .font(.system(.title3, design: Design.zahlDesign, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(warning == nil ? AnyShapeStyle(.tint) : AnyShapeStyle(.red))
            if let warning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.red)
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .card()
        .accessibilityElement(children: .combine)
    }

    private func recentTurns(_ s: PlayerStats) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel("Letzte Züge").padding(.bottom, 2)
            ForEach(s.recent, id: \.number) { t in
                HStack(spacing: Design.Abstand.s) {
                    Text("Zug \(t.number)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    if let from = t.inheritedFrom, game.players.indices.contains(from) {
                        Text("übernommen von \(game.players[from].name)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    Spacer()
                    if t.penalty > 0 {
                        Text("Strafe −\(Theme.points(t.penalty))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                    Text(t.points > 0 ? "+\(Theme.points(t.points))" : String(localized: "Niete"))
                        .fontWeight(t.points > 0 ? .semibold : .regular)
                        .foregroundStyle(t.points > 0 ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        .monospacedDigit()
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
            }
        }
        .card()
    }
}
