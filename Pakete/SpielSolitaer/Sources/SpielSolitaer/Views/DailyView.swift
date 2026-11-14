// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Monatskalender des Tagesspiels: gewonnen = goldener Kreis mit Haken, heute = goldener Ring, angefangen = Punkt.
struct DailyView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(AppModel.self) private var app
    @Environment(StatsStore.self) private var stats
    @Environment(Router.self) private var router
    @State private var month: Date
    @State private var kind: GameKind
    /// Gewählter Tag (nur bei Spielen mit Leicht/Gemischt/Schwer; sonst startet das Antippen sofort)
    @State private var selected: Date = .now
    private let calendar = AppLocale.calendar

    init(month: Date? = nil, kind: GameKind = .klondike) {
        _month = State(initialValue: Self.firstOfMonth(month ?? .now))
        _kind = State(initialValue: kind)
    }

    static func firstOfMonth(_ d: Date) -> Date {
        Calendar.solitaer.date(from: Calendar.solitaer.dateComponents([.year, .month], from: d))!
    }

    var body: some View {
        ScrollView {
            VStack(spacing: Design.Abstand.l) {
            GameKindCapsules(selection: $kind)
            VStack(alignment: .leading, spacing: Design.Abstand.m) {
                // Bei sehr großer Schrift untereinander statt nebeneinander (sonst bricht jedes Wort einzeln um)
                (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout())) {
                    SectionLabel("Tagesspiel")
                    if !typeSize.isAccessibilitySize { Spacer() }
                    Text("\(wonInMonth) gewonnen").font(.caption).foregroundStyle(.secondary)
                    CupView(cup: stats.cup(kind: kind, year: monthYear, month: monthNumber),
                            crowns: stats.crownsInMonth(kind: kind, year: monthYear, month: monthNumber),
                            daysInMonth: stats.daysInMonth(year: monthYear, month: monthNumber))
                }
                HStack {
                    Button("Vorheriger Monat", systemImage: "chevron.left") { shift(-1) }
                        .labelStyle(.iconOnly).frame(width: Theme.tapSize, height: Theme.tapSize)
                    Spacer()
                    Text(month.formatted(.dateTime.month(.wide).year().locale(AppLocale.current))).font(.headline)
                    Spacer()
                    Button("Nächster Monat", systemImage: "chevron.right") { shift(1) }
                        .labelStyle(.iconOnly).frame(width: Theme.tapSize, height: Theme.tapSize)
                        .disabled(!canGoForward)
                }
                HStack(spacing: Design.Abstand.xs) {
                    ForEach(0..<7, id: \.self) { i in
                        Text(weekdaySymbols[i]).font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                    }
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Design.Abstand.xs), count: 7), spacing: 6) {
                    ForEach(cells.indices, id: \.self) { i in
                        if let day = cells[i] { dayCell(day) } else { Color.clear.frame(height: Theme.tapSize) }
                    }
                }
                CupProgress(cup: stats.cup(kind: kind, year: monthYear, month: monthNumber),
                            crowns: stats.crownsInMonth(kind: kind, year: monthYear, month: monthNumber),
                            daysInMonth: stats.daysInMonth(year: monthYear, month: monthNumber))
                Text(DealCatalog.hasDailyLevels(kind) ? LocalizedStringKey("Tippe auf einen Tag, dann auf eine Stufe.") : LocalizedStringKey("Tippe auf einen Tag, um sein Tagesspiel zu spielen."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            .card()
            if DealCatalog.hasDailyLevels(kind) { levelCard }
            VStack(alignment: .leading, spacing: Design.Abstand.m) {
                SectionLabel("Serie")
                HStack(spacing: 0) {
                    bigStreak(stats.dailyStreak(kind: kind), "Aktuell")
                    bigStreak(stats.bestDailyStreak(kind: kind), "Beste")
                }
                Text(monthLine).font(.footnote).foregroundStyle(.secondary)
            }
            .card()
            .accessibilityElement(children: .combine)
            }
            .padding(16)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .background(Color.seitenGrund)
        .navigationTitle("Tagesspiel")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var weekdaySymbols: [String] {
        let s = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(s[first...] + s[..<first])
    }

    private var cells: [Date?] {
        let days = calendar.range(of: .day, in: .month, for: month)!.count
        let weekday = calendar.component(.weekday, from: month)
        let lead = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: lead) + (0..<days).map { calendar.date(byAdding: .day, value: $0, to: month)! }
    }

    private var wonInMonth: Int {
        let prefix = DailyDate.string(month).prefix(7)
        return stats.dailyWon(kind).filter { $0.hasPrefix(prefix) }.count
    }

    private var monthYear: Int { calendar.component(.year, from: month) }
    private var monthNumber: Int { calendar.component(.month, from: month) }

    private var canGoForward: Bool { Self.firstOfMonth(.now) > month }

    private func shift(_ delta: Int) {
        month = calendar.date(byAdding: .month, value: delta, to: month) ?? month
    }

    private func dayCell(_ day: Date) -> some View {
        let key = DailyDate.string(day)
        let won = stats.dailyWon(kind).contains(key)
        let started = stats.dailyStarted(kind).contains(key)
        let crowned = stats.crowned(kind).contains(key)
        let today = calendar.isDateInToday(day)
        let future = day > .now && !today
        let isSelected = DealCatalog.hasDailyLevels(kind) && calendar.isDate(day, inSameDayAs: selected)
        let easy = stats.dailyLevelWon(kind, level: 1).contains(key)
        let hard = stats.dailyLevelWon(kind, level: 3).contains(key)
        return Button {
            if DealCatalog.hasDailyLevels(kind) {
                selected = day
            } else {
                app.startDaily(day, kind: kind)
                router.leaveToGame()
            }
        } label: {
            ZStack {
                if isSelected { Circle().fill(Color.appFarbe.opacity(0.18)).padding(-1) }
                if DealCatalog.hasDailyLevels(kind), easy || hard {
                    // nur wenn eine Stufe gewonnen wurde (sonst unruhig): zwei kleine Punkte: links Leicht, rechts Schwer – Gold, wenn gewonnen
                    HStack(spacing: 5) {
                        Circle().fill(easy ? Color.appFarbe : Color.secondary.opacity(0.25)).frame(width: 5, height: 5)
                        Circle().fill(hard ? Color.appFarbe : Color.secondary.opacity(0.25)).frame(width: 5, height: 5)
                    }
                    .offset(y: 27)
                }
                if won { Circle().fill(Color.appFarbe) }
                if today { Circle().strokeBorder(Color.appFarbe, lineWidth: 2.5).padding(won ? -3 : 0) }
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(.subheadline, design: Design.zahlDesign).monospacedDigit().weight(won ? .bold : .regular))
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)       // Zahl muss in den Kreis passen
                    .foregroundStyle(won ? Color.onAccent : (future ? Color.secondary.opacity(0.5) : Color.primary))
                if won {
                    // Krone (Tagesziel erreicht) statt Haken
                    Image(systemName: crowned ? "crown.fill" : "checkmark").font(.caption2.weight(.heavy))
                        .foregroundStyle(Color.onAccent)
                        .offset(y: 13)
                } else if started {
                    Circle().fill(Color.appFarbe).frame(width: 5, height: 5).offset(y: 14)
                }
            }
            .padding(2)
            .frame(height: Theme.tapSize + (DealCatalog.hasDailyLevels(kind) ? 10 : 0))
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(future)
        .accessibilityLabel(day.formatted(.dateTime.day().month(.wide).locale(AppLocale.current)) + (crowned ? ", " + String(localized: "Krone") : won ? ", " + String(localized: "Gewonnen") : ""))
    }

    /// „Diesen Monat: 4 von 5 Tagen“ – bei laufendem Monat zählen die Tage bis heute
    private var monthLine: LocalizedStringKey {
        let days = calendar.range(of: .day, in: .month, for: month)!.count
        let isCurrent = calendar.isDate(month, equalTo: .now, toGranularity: .month)
        let total = isCurrent ? calendar.component(.day, from: .now) : days
        return isCurrent ? "Diesen Monat: \(wonInMonth) von \(total) Tagen" : "Im \(month.formatted(.dateTime.month(.wide).locale(AppLocale.current))): \(wonInMonth) von \(total) Tagen"
    }

    /// Drei Stufen für den gewählten Tag: Leicht · Gemischt · Schwer
    private var levelCard: some View {
        let key = DailyDate.string(selected)
        let future = selected > .now && !calendar.isDateInToday(selected)
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Tagesspiel am \(selected.formatted(.dateTime.day().month(.wide).locale(AppLocale.current)))")
            HStack(spacing: Design.Abstand.s) {
                levelButton("Leicht", level: 1, done: stats.dailyLevelWon(kind, level: 1).contains(key), disabled: future)
                levelButton("Gemischt", level: nil, done: stats.dailyWon(kind).contains(key), disabled: future)
                levelButton("Schwer", level: 3, done: stats.dailyLevelWon(kind, level: 3).contains(key), disabled: future)
            }
            Text("Gemischt hat das Tagesziel mit Krone und Pokal. Leicht und Schwer zählen nur als gewonnen.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .card()
    }

    private func levelButton(_ title: LocalizedStringKey, level: Int?, done: Bool, disabled: Bool) -> some View {
        Button {
            app.startDaily(selected, kind: kind, level: level)
            router.leaveToGame()
        } label: {
            HStack(spacing: Design.Abstand.xs) {
                if done { Image(systemName: "checkmark").font(.caption.weight(.bold)) }
                Text(title).font(.system(.subheadline, design: Design.zahlDesign).weight(.semibold)).lineLimit(1).minimumScaleFactor(0.8)
            }
            .foregroundStyle(level == nil ? Color.onAccent : .primary)
            .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
            .background(level == nil ? Color.appFarbe : Color(.tertiarySystemFill), in: .rect(cornerRadius: Design.Ecke.feld))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }

    private func bigStreak(_ value: Int, _ caption: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text("\(value)").font(.system(.largeTitle, design: Design.zahlDesign).weight(.black)).monospacedDigit()
                .foregroundStyle(Color.appFarbe)
            Text(caption).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

}
