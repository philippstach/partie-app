// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import Charts

struct StatsView: View {
    @Environment(GameStore.self) private var store
    /// Startet das Tagesrätsel eines Tages aus dem Archiv im Rahmen
    var starten: (Day) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                NavigationLink {
                    AchievementsView()
                } label: {
                    HStack {
                        Label("Erfolge \(store.achieved.count)/\(Achievements.all.count)", systemImage: "rosette")
                            .font(.headline).foregroundStyle(Color.kwAkzent)
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .frame(minHeight: 44)
                    .card()
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                dailyCard
                ForEach(Level.allCases) { l in levelCard(l) }
            }
            .padding(16)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color.papier)
        .navigationTitle("Archiv und Zeiten")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    /// Je Stufe: Ring gelöst/gespielt, Bestzeit, Ø Zeit, Quote „ohne Hilfe“
    private func levelCard(_ l: Level) -> some View {
        let s = store.stats[l]
        return VStack(alignment: .leading, spacing: Design.Abstand.m) {
            HStack(spacing: Design.Abstand.l) {
                ZStack {
                    ProgressRing(done: s.won, total: max(s.played, s.won))
                    Text("\(s.won)/\(max(s.played, s.won))").font(.caption2.monospacedDigit()).foregroundStyle(Color.tinte)
                }
                .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: Design.Abstand.s) {
                    SectionLabel(levelTitle(l))
                    row("Bestzeit", s.bestTime.map { Zeitformat.text($0) } ?? "–")
                    row("Durchschnitt", s.averageTime.map { Zeitformat.text($0) } ?? "–")
                    row("Ohne Hilfe", s.won > 0 ? "\(Int((Double(s.wonWithoutHelp) / Double(s.won) * 100).rounded())) %" : "–")
                }
            }
            if s.recent.count >= 2 { TimeCurve(times: s.recent, best: s.bestTime) }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Rätsel des Tages")
            VStack(alignment: .leading, spacing: 10) {
                row("Gelöst", "\(store.stats.dailySolved.count)")
                row("Aktuelle Serie", "\(store.stats.streak(today: store.today))")
                row("Beste Serie", "\(max(store.stats.bestStreak, store.stats.streak(today: store.today)))")
            }
            .accessibilityElement(children: .combine)
            MonthCalendar(solved: store.stats.dailyDays, noHelp: Set(store.stats.dailyNoHelp.compactMap(Day.init)),
                          catchUp: Set(store.stats.dailyCatchUp.compactMap(Day.init)),
                          onSelect: { day in starten(day) }, today: store.today)
        }
        .card()
        .overlay(RoundedRectangle(cornerRadius: Design.Ecke.karte).stroke(Color.kwAkzent.opacity(0.25), lineWidth: 1))
    }

    private func row(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.system(.body, design: Design.zahlDesign).monospacedDigit())
        }
        .font(.subheadline)
    }
}

/// Monatskalender mit Goldhaken an gelösten Tagen; Wischen oder Pfeile wechseln den Monat.
struct MonthCalendar: View {
    let solved: Set<Day>
    var noHelp: Set<Day> = []
    /// Nachgeholte Tage: hohler Haken
    var catchUp: Set<Day> = []
    var onSelect: (Day) -> Void = { _ in }
    let today: Day
    @State private var monthOffset = 0
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2 // Montag
        c.locale = .current
        return c
    }()

    var body: some View {
        let first = firstOfMonth()
        let days = calendar.range(of: .day, in: .month, for: first)!.count
        let lead = (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
        let cols = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
        VStack(spacing: Design.Abstand.s) {
            HStack {
                Button { monthOffset -= 1 } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .disabled(!canGoBack)
                    .accessibilityLabel("Voriger Monat")
                Spacer()
                Text(first.formatted(.dateTime.month(.wide).year())).font(.headline)
                Spacer()
                Button { monthOffset += 1 } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .disabled(monthOffset >= 0)
                    .accessibilityLabel("Nächster Monat")
            }
            LazyVGrid(columns: cols, spacing: 6) {
                ForEach(Array(calendar.veryShortWeekdaySymbols.rotated(by: calendar.firstWeekday - 1).enumerated()), id: \.offset) {
                    Text($0.element).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(Array(([Int?](repeating: nil, count: lead) + (1...days).map { Optional($0) }).enumerated()), id: \.offset) { _, entry in
                    if let d = entry {
                    let day = Day(calendar.component(.year, from: first), calendar.component(.month, from: first), d)
                    let playable = day <= today && !(day < Daily.start)
                    Button { if playable { onSelect(day) } } label: {
                        ZStack {
                            if catchUp.contains(day) {
                                // nachgeholt: hohler Haken, zählt nicht zur Serie
                                Circle().stroke(Color.kwAkzent, lineWidth: 1.5).frame(width: 26, height: 26)
                                    .overlay(Image(systemName: "checkmark").font(.caption.weight(.bold)).foregroundStyle(Color.kwAkzent))
                            } else if solved.contains(day) {
                                Circle().fill(Color.kwAkzent).frame(width: 26, height: 26)
                                    .overlay(Image(systemName: noHelp.contains(day) ? "star.fill" : "checkmark")
                                        .font(.caption.weight(.bold)).foregroundStyle(Color.kwAufAkzent))
                            } else {
                                Text("\(d)").font(.footnote.monospacedDigit())
                                    .foregroundStyle(day == today ? Color.kwAkzent : playable ? Color.tinte.opacity(0.75) : Color.secondary.opacity(0.55))
                            }
                            if day == today { Circle().stroke(Color.kwAkzent, lineWidth: 2).frame(width: 30, height: 30) }
                        }
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(!playable)
                    .accessibilityElement()
                    .accessibilityLabel(Text(day.date().formatted(.dateTime.day().month(.wide))))
                    .accessibilityValue(catchUp.contains(day) ? Text("nachgeholt") : noHelp.contains(day) ? Text("ohne Hilfe gelöst") : solved.contains(day) ? Text("gelöst") : playable ? Text("spielbar") : Text("gesperrt"))
                    } else {
                        Color.clear.frame(height: 32)
                    }
                }
            }
        }
        .contentShape(.rect)
        .gesture(DragGesture(minimumDistance: 30).onEnded { v in
            if v.translation.width > 40 { monthOffset -= 1 }
            else if v.translation.width < -40, monthOffset < 0 { monthOffset += 1 }
        })
        .animation(.default, value: monthOffset)
    }

    /// Archiv beginnt im Januar 2026
    private var canGoBack: Bool {
        let first = firstOfMonth()
        return calendar.component(.year, from: first) * 12 + calendar.component(.month, from: first)
            > Daily.start.year * 12 + Daily.start.month
    }

    private func firstOfMonth() -> Date {
        let base = calendar.date(from: DateComponents(year: today.year, month: today.month, day: 1))!
        return calendar.date(byAdding: .month, value: monthOffset, to: base)!
    }
}

private extension Array {
    func rotated(by n: Int) -> [Element] {
        guard !isEmpty else { return self }
        let k = n % count
        return Array(self[k...]) + Array(self[..<k])
    }
}


/// Kleine Zeitkurve über die letzten (bis zu 20) gelösten Rätsel; die Bestzeit ist mit einem Stern markiert.
struct TimeCurve: View {
    let times: [Double]
    let best: Double?

    var body: some View {
        let bestIndex = times.enumerated().min { $0.element < $1.element }?.offset
        VStack(alignment: .leading, spacing: Design.Abstand.xs) {
            Text("Letzte \(times.count) Rätsel").font(.caption).foregroundStyle(.secondary)
            Chart {
                ForEach(Array(times.enumerated()), id: \.offset) { i, t in
                    LineMark(x: .value("Rätsel", i), y: .value("Sekunden", t))
                        .foregroundStyle(Color.kwAkzent)
                        .interpolationMethod(.monotone)
                    if i == bestIndex {
                        PointMark(x: .value("Rätsel", i), y: .value("Sekunden", t))
                            .symbol { Image(systemName: "star.fill").font(.caption).foregroundStyle(Color.kwAkzent) }
                    }
                }
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { v in
                    AxisGridLine().foregroundStyle(Color.linie)
                    AxisValueLabel { if let s = v.as(Double.self) { Text(Zeitformat.text(s)).font(.caption2) } }
                }
            }
            .frame(height: 72)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Zeitkurve der letzten \(times.count) Rätsel")
        .accessibilityValue(best.map { String(localized: "Bestzeit \(Zeitformat.text($0))") } ?? "")
    }
}
#endif
