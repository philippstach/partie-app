// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Charts
import SwiftUI
import KlarGlas

/// Spielverlauf als Liniendiagramm. Spieler lassen sich antippen, um sie hervorzuheben;
/// erneutes Tippen hebt die Auswahl auf.
struct ScoreChart: View {
    let game: GameState
    var height: CGFloat = 220
    /// Für das Teilen-Bild: ohne Auswahl-Legende
    var interactive = true
    @State private var highlighted: Int?

    init(game: GameState, height: CGFloat = 220, interactive: Bool = true, initialHighlight: Int? = nil) {
        self.game = game
        self.height = height
        self.interactive = interactive
        _highlighted = State(initialValue: initialHighlight)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Spielverlauf")

            Chart {
                ForEach(game.players.indices, id: \.self) { i in
                    ForEach(Array(game.timeline.enumerated()), id: \.offset) { t, scores in
                        if scores.indices.contains(i) {
                            LineMark(
                                x: .value("Zug", t),
                                y: .value("Punkte", scores[i]),
                                series: .value("Person", i)
                            )
                            .foregroundStyle(game.players[i].color.opacity(opacity(i)))
                            .lineStyle(StrokeStyle(lineWidth: highlighted == i ? 3.5 : 2, lineCap: .round))
                            .interpolationMethod(.monotone)
                        }
                    }
                }
                if let h = highlighted, let last = game.timeline.last, last.indices.contains(h) {
                    PointMark(x: .value("Zug", game.timeline.count - 1), y: .value("Punkte", last[h]))
                        .foregroundStyle(game.players[h].color)
                        .symbolSize(90)
                        .annotation(position: .top, alignment: .trailing) {
                            Text(Theme.points(last[h]))
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.background, in: RoundedRectangle(cornerRadius: 6))
                        }
                }
            }
            .chartLegend(.hidden)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks { v in
                    AxisGridLine()
                    AxisValueLabel { if let n = v.as(Int.self) { Text(Self.axisLabel(n)) } }
                }
            }
            .frame(height: height)
            .animation(.easeInOut(duration: 0.2), value: highlighted)

            legend
            if interactive, let h = highlighted {
                details(game.players[h])
                    .transition(.opacity)
            }
        }
        .card()
    }

    /// Kurze Achsenbeschriftung: 500, 1k, 1,5k, 10k – nie zweimal dasselbe für verschiedene Werte
    static func axisLabel(_ n: Int) -> String {
        guard abs(n) >= 1000 else { return "\(n)" }
        let k = Double(n) / 1000
        return k.formatted(.number.precision(.fractionLength(0...1)).locale(Locale(identifier: "de_DE"))) + "k"
    }

    private func opacity(_ i: Int) -> Double {
        guard let highlighted else { return 1 }
        return highlighted == i ? 1 : 0.15
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: Design.Abstand.s, alignment: .leading)], alignment: .leading, spacing: Design.Abstand.s) {
            ForEach(game.players.indices, id: \.self) { i in
                let p = game.players[i]
                let on = highlighted == nil || highlighted == i
                Button {
                    guard interactive else { return }
                    highlighted = highlighted == i ? nil : i
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(p.color).frame(width: 10, height: 10)
                        Text("\(p.avatar) \(p.name)")
                            .font(.footnote.weight(highlighted == i ? .bold : .regular))
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(highlighted == i ? p.color.opacity(0.2) : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                    .frame(minHeight: 44)
                    .contentShape(.rect)
                    .opacity(on ? 1 : 0.45)
                }
                .buttonStyle(.plain)
                .disabled(!interactive)
                .accessibilityLabel(p.name)
                .accessibilityAddTraits(highlighted == i ? .isSelected : [])
                .accessibilityHint("Hebt den Verlauf dieser Person hervor")
            }
        }
    }

    private func details(_ p: Player) -> some View {
        HStack(spacing: Design.Abstand.l) {
            detail("Punkte", Theme.points(p.score))
            detail(String(localized: "Bester Zug"), Theme.points(p.bestTurn))
            detail("Nieten", "\(p.nieten)")
            detail(String(localized: "Züge"), "\(p.turns)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            SectionLabel(verbatim: title)
            Text(value).font(.system(.headline, design: Design.zahlDesign)).monospacedDigit()
        }
    }
}

/// Spielverlauf im laufenden Spiel: Diagramm und alle Züge.
struct HistorySheet: View {
    let game: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Abstand.m) {
                    if game.log.isEmpty {
                        ContentUnavailableView("Noch keine Züge", systemImage: "chart.xyaxis.line",
                                               description: Text("Nach dem ersten Zug siehst du hier den Verlauf."))
                            .padding(.top, 40)
                    } else {
                        ScoreChart(game: game)
                        HistoryCard(game: game, limit: nil)
                    }
                }
                .padding()
            }
            .background(Color.seitenGrund)
            .navigationTitle("Spielverlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}
