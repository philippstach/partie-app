// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import Charts

/// Statistik → „VERLAUF“: Siege je Woche (letzte 8 Wochen) und die Zeiten der letzten 20 Siege
struct HistoryCard: View {
    @Environment(StatsStore.self) private var stats
    let mode: GameMode

    var body: some View {
        let list = stats.data.history
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("Verlauf")
            if StatsHistory.hasEnough(list, mode: mode) {
                weekChart(StatsHistory.weekly(list, mode: mode))
                let times = StatsHistory.recentWinTimes(list, mode: mode)
                if times.count >= 2 { timeChart(times) }
            } else {
                Text("Spiel ein paar Partien, dann erscheint hier dein Verlauf.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .card()
    }

    private func weekChart(_ weeks: [WeekBucket]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Siege je Woche").font(.subheadline.weight(.medium))
            Chart {
                ForEach(weeks) { w in
                    BarMark(x: .value("Woche", w.start, unit: .weekOfYear), y: .value("Siege", w.wins))
                        .foregroundStyle(Color.appFarbe)
                    BarMark(x: .value("Woche", w.start, unit: .weekOfYear), y: .value("Niederlagen", w.losses))
                        .foregroundStyle(Color.secondary.opacity(0.35))
                }
            }
            .chartXAxis { AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in AxisValueLabel(format: .dateTime.day().month(.defaultDigits).locale(AppLocale.current)) } }
            .chartYAxis { AxisMarks(position: .leading) }
            .frame(height: 130)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: Self.weekSummary(weeks)))
            HStack(spacing: 14) {
                legend(Color.appFarbe, "Siege")
                legend(Color.secondary.opacity(0.35), "Nicht gewonnen")
            }
        }
    }

    private func timeChart(_ times: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Zeit der Siege").font(.subheadline.weight(.medium))
            Chart {
                ForEach(Array(times.enumerated()), id: \.offset) { i, t in
                    LineMark(x: .value("Sieg", i + 1), y: .value("Sekunden", t)).foregroundStyle(Color.appFarbe)
                    PointMark(x: .value("Sieg", i + 1), y: .value("Sekunden", t)).foregroundStyle(Color.appFarbe).symbolSize(18)
                }
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { v in
                    AxisGridLine()
                    AxisValueLabel { if let s = v.as(Double.self) { Text(verbatim: Zeitformat.text(s)) } }
                }
            }
            .frame(height: 110)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: Self.timeSummary(times)))
        }
    }

    private func legend(_ color: Color, _ text: LocalizedStringKey) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text).font(.caption).foregroundStyle(.secondary)
        }
    }

    // MARK: Zusammenfassung für VoiceOver

    /// „In den letzten 8 Wochen 23 Siege, beste Woche 7“
    static func weekSummary(_ weeks: [WeekBucket]) -> String {
        let total = weeks.reduce(0) { $0 + $1.wins }
        let best = weeks.map(\.wins).max() ?? 0
        return String(localized: "In den letzten \(StatsHistory.weeks) Wochen \(total) Siege, beste Woche \(best)")
    }

    /// „Zeit der letzten 12 Siege: schnellste 3:12, langsamste 9:40“
    static func timeSummary(_ times: [Double]) -> String {
        guard let fast = times.min(), let slow = times.max() else { return "" }
        return String(localized: "Zeit der letzten \(times.count) Siege: schnellste \(Zeitformat.text(fast)), langsamste \(Zeitformat.text(slow))")
    }
}

/// Statistik → „DEINE BESTEN 10“: schnellste Siege; Antippen startet die Partie noch einmal (nur nummerierte Partien)
struct TopTenCard: View {
    @Environment(AppModel.self) private var app
    @Environment(StatsStore.self) private var stats
    @Environment(Router.self) private var router
    let mode: GameMode
    @State private var replay: HistoryEntry?

    var body: some View {
        let top = StatsHistory.top10(stats.data.history, mode: mode)
        if !top.isEmpty {
            VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                SectionLabel("Deine besten 10")
                ForEach(Array(top.enumerated()), id: \.offset) { i, e in
                    row(i + 1, e)
                    if i < top.count - 1 { Divider() }
                }
            }
            .card()
            .confirmationDialog("Diese Partie nochmal spielen?", isPresented: Binding(get: { replay != nil }, set: { if !$0 { replay = nil } }),
                                titleVisibility: .visible) {
                Button("Spielen") {
                    if let n = replay?.number, app.startNumbered(n, mode: mode) { router.leaveToGame() }
                    replay = nil
                }
                Button("Abbrechen", role: .cancel) { replay = nil }
            } message: {
                if let n = replay?.number { Text("Partie #\(n)") }
            }
        }
    }

    private func row(_ rank: Int, _ e: HistoryEntry) -> some View {
        let date = DailyDate.date(e.date).map { $0.formatted(.dateTime.day().month(.abbreviated).locale(AppLocale.current)) } ?? e.date
        let time = Zeitformat.text(e.time ?? 0)
        let tappable = e.number != nil
        return Button { if tappable { replay = e } } label: {
            HStack(spacing: 10) {
                Text(verbatim: "\(rank).").font(.system(.subheadline, design: Design.zahlDesign).weight(.bold)).foregroundStyle(rank == 1 ? Color.appFarbe : .secondary)
                    .frame(width: 26, alignment: .leading)
                Text(verbatim: time).font(.system(.body, design: Design.zahlDesign).weight(.semibold)).monospacedDigit()
                Spacer()
                Text(verbatim: date).font(.caption).foregroundStyle(.secondary)
                if let n = e.number {
                    Text("Partie #\(n)").font(.caption).foregroundStyle(.secondary)
                    Image(systemName: "arrow.counterclockwise").font(.caption).foregroundStyle(Color.appFarbe)
                }
            }
            .frame(minHeight: Theme.tapSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!tappable)
        .accessibilityLabel(Text(verbatim: "\(rank). \(time), \(date)" + (e.number.map { ", " + String(localized: "Partie #\($0)") } ?? "")))
    }
}
