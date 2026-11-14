// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Charts
import SwiftUI
import KlarGlas
import SpieleKern

/// Spielverlauf als Liniendiagramm (Gesamtpunkte nach jedem Zug). Spieler lassen sich antippen.
struct ScoreChart: View {
    let record: GameRecord
    var height: CGFloat = 220
    /// Fürs Teilen-Bild: ohne Auswahl
    var interactive = true
    @State private var highlighted: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Spielverlauf")

            Chart {
                ForEach(record.players.indices, id: \.self) { i in
                    ForEach(Array(record.timeline.enumerated()), id: \.offset) { t, scores in
                        LineMark(x: .value("Zug", t), y: .value("Punkte", scores[i]), series: .value("Spieler", i))
                            .foregroundStyle(record.players[i].color.opacity(opacity(i)))
                            .lineStyle(StrokeStyle(lineWidth: highlighted == i ? 3.5 : 2, lineCap: .round))
                            .interpolationMethod(.monotone)
                    }
                }
            }
            .chartLegend(.hidden)
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }   // Fund 74: Rundenachse sichtbar und beschriftet
            .chartXAxisLabel(String(localized: "Runde"), alignment: .center)
            .frame(height: height)
            .animation(.easeInOut(duration: 0.2), value: highlighted)
            .accessibilityLabel("Spielverlauf")
            .accessibilityValue(record.players.indices.map { "\(record.players[$0].name) \(record.total($0)) Punkte" }.joined(separator: ", "))

            legend
        }
        .card()
    }

    private func opacity(_ i: Int) -> Double {
        guard let highlighted else { return 1 }
        return highlighted == i ? 1 : 0.15
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: Design.Abstand.s, alignment: .leading)], alignment: .leading, spacing: Design.Abstand.s) {
            ForEach(record.players.indices, id: \.self) { i in
                let p = record.players[i]
                Button {
                    guard interactive else { return }
                    highlighted = highlighted == i ? nil : i
                } label: {
                    HStack(spacing: 6) {
                        Circle().fill(p.color).frame(width: 10, height: 10)
                        Text(verbatim: p.avatar.count == 1 && p.name.hasPrefix(p.avatar) ? p.name : "\(p.avatar) \(p.name)")   // Fund 74: kein doppelter Anfangsbuchstabe („L Lena“)
                            .font(.footnote.weight(highlighted == i ? .bold : .regular))
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(highlighted == i ? p.color.opacity(0.2) : Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                    .frame(minHeight: Theme.tapSize)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .disabled(!interactive)
                .accessibilityLabel(p.name)
                .accessibilityAddTraits(highlighted == i ? .isSelected : [])
                .accessibilityHint("Hebt den Verlauf dieses Spielers hervor")
            }
        }
    }
}

/// Spielverlauf im laufenden Spiel.
struct HistorySheet: View {
    let record: GameRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Abstand.m) {
                    if record.timeline.count < 2 {
                        ContentUnavailableView("Noch keine Züge", systemImage: "chart.xyaxis.line",
                                               description: Text("Nach dem ersten Zug siehst du hier den Verlauf."))
                            .padding(.top, 40)
                    } else {
                        ScoreChart(record: record)
                    }
                }
                .padding()
            }
            .background(Color.seitenGrund)
            .navigationTitle("Spielverlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}
