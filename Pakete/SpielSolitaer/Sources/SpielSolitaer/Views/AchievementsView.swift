// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Datum „2026-10-06“ → „6. Oktober“ bzw. „October 6“
private func dayText(_ day: String) -> String {
    DailyDate.date(day).map { $0.formatted(.dateTime.day().month(.wide).locale(AppLocale.current)) } ?? day
}

extension Achievement {
    /// VoiceOver: „Erfolg Ohne Netz, erreicht am 6. Oktober“ bzw. „noch nicht erreicht: gewinnen ohne Rückgängig“
    func spokenText(earnedOn day: String?) -> String {
        if let day { return String(localized: "Erfolg \(title), erreicht am \(dayText(day))") }
        return String(localized: "\(title), noch nicht erreicht: \(condition)")
    }
}

/// Statistik → „ERFOLGE · 4/15“: Raster runder Abzeichen (Gold gefüllt = erreicht, grauer Umriss = offen); Antippen zeigt Name, Bedingung, Datum
struct AchievementsCard: View {
    @Environment(StatsStore.self) private var stats
    @State private var selected: Achievement?

    var body: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            SectionLabel("Erfolge · \(stats.earnedCount)/\(Achievement.allCases.count)")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 10)], spacing: 10) {
                ForEach(Achievement.allCases) { a in badge(a) }
            }
            if let a = selected {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: a.title).font(.system(.subheadline, design: Design.zahlDesign).weight(.bold))
                    Text(verbatim: a.condition).font(.caption).foregroundStyle(.secondary)
                    if let day = stats.earned(a) {
                        Text("Erreicht am \(dayText(day))").font(.caption).foregroundStyle(Color.appFarbe)
                    } else {
                        Text("Noch nicht erreicht").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            }
        }
        .card()
        .animation(.easeOut(duration: 0.15), value: selected)
    }

    private func badge(_ a: Achievement) -> some View {
        let day = stats.earned(a)
        let on = day != nil
        return Button { selected = selected == a ? nil : a } label: {
            ZStack {
                Circle().fill(on ? Color.appFarbe : .clear)
                Circle().strokeBorder(on ? .clear : Color.secondary.opacity(0.45), lineWidth: 1.5)
                Image(systemName: a.symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(on ? Color.onAccent : Color.secondary.opacity(0.6))
            }
            .frame(width: 52, height: 52)
            .overlay { if selected == a { Circle().strokeBorder(Color.appFarbe, lineWidth: 2.5).padding(-4) } }
            .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: a.spokenText(earnedOn: day)))
    }
}
