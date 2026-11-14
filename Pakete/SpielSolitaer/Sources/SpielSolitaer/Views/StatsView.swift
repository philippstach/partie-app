// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

struct StatsView: View {
    @Environment(AppModel.self) private var app
    @Environment(StatsStore.self) private var stats
    @Environment(Router.self) private var router
    @State private var kindChoice: GameKind?
    @State private var optionChoice: Int?
    @State private var confirmReset = false
    @State private var confirmAccountReset = false

    /// Ausgewähltes Spiel (zuerst das, das gerade offen ist) und Modus (zuerst der aus den Einstellungen)
    private var kind: GameKind { kindChoice ?? app.session.mode.kind }
    private var option: Int {
        let o = optionChoice ?? (kind == .spider ? app.prefs.spiderColors : app.prefs.drawCount)
        return kind.options.contains(o) ? o : kind.options[0]
    }
    private var mode: GameMode {
        switch kind {
        case .klondike: .klondike(option)
        case .spider: .spider(option)
        case .freecell: .freecell
        case .pyramid: .pyramid
        case .tripeaks: .tripeaks
        case .golf: .golf
        case .yukon: .yukon
        }
    }

    var body: some View {
        let s = stats.stats(mode: mode)
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: Design.Abstand.l) {
                GameKindCapsules(selection: Binding(get: { kind }, set: { kindChoice = $0 }), onSelect: { _ in optionChoice = nil })
                if kind == .klondike {
                    Picker("Karten ziehen", selection: Binding(get: { option }, set: { optionChoice = $0 })) {
                        Text("1 Karte").tag(1)
                        Text("3 Karten").tag(3)
                    }
                    .pickerStyle(.segmented)
                } else if kind == .spider {
                    Picker("Farben", selection: Binding(get: { option }, set: { optionChoice = $0 })) {
                        Text("1 Farbe").tag(1)
                        Text("2 Farben").tag(2)
                        Text("4 Farben").tag(4)
                    }
                    .pickerStyle(.segmented)
                }

                if s.played > 0 {
                    // Kopf: Ring für die Quote, daneben Gewonnen und Beste Serie
                    HStack(spacing: 18) {
                        QuoteRing(percent: s.winRate ?? 0)
                            .frame(width: 96, height: 96)
                        VStack(spacing: 10) {
                            bigNumber("\(s.won)", "Gewonnen", gold: false)
                            bigNumber("\(s.bestStreak)", "Beste Serie", gold: false)
                        }
                    }
                    .card()
                    .accessibilityElement(children: .combine)
                    AchievementsCard().id("erfolge")
                    HistoryCard(mode: mode).id("verlauf")
                    TopTenCard(mode: mode)
                } else {
                    emptyState
                    AchievementsCard().id("erfolge")
                }

                if s.played > 0 {
                block("Spiele") {
                    row("Gespielt", "\(s.played)")
                    row("Gewonnen", "\(s.won)")
                    row("Quote", s.winRate.map { "\($0) %" } ?? "–")
                    // je Stufe: gewonnen von gespielt (nur Modi mit Stufen und nur, wenn gespielt)
                    ForEach([1, 2, 3], id: \.self) { level in
                        if let c = s.levels[String(level)], c.played > 0 {
                            row(LocalizedStringKey(Self.levelNames[level]!), "\(c.won)/\(c.played) · \(Int((Double(c.won) / Double(c.played) * 100).rounded())) %")
                        }
                    }
                }
                block("Serie") {
                    row("Aktuell", "\(s.streak)")
                    row("Beste", "\(s.bestStreak)")
                }
                block("Rekorde") {
                    row("Bestzeit", s.bestTime.map { Zeitformat.text($0) } ?? "–")
                    row("Wenigste Züge", s.fewestMoves.map(String.init) ?? "–")
                    if kind != .freecell, kind != .pyramid { row("Höchste Punkte", s.highScore.map(String.init) ?? "–") }
                }
                }
                if kind == .klondike, stats.vegasAccount(mode) != 0 || app.prefs.klondikeScoring == 2 {
                    block("Gesamtwertung") {
                        let v = stats.vegasAccount(mode)
                        row("Punkte insgesamt", v < 0 ? "−\(-v)" : "\(v)")
                        Button("Gesamtwertung zurücksetzen", role: .destructive) { confirmAccountReset = true }
                            .font(.subheadline)
                            .frame(minHeight: Theme.tapSize, alignment: .leading)
                    }
                }
                if stats.data.weeksDone > 0 {
                    block("Wochenziele") { row("Wochen geschafft", "\(stats.data.weeksDone)") }
                }
                block("Tagesspiel") {
                    row("Gewonnene Tage", "\(stats.dailyWon(kind).count)")
                    row("Tages-Serie", "\(stats.dailyStreak(kind: kind))")
                    row("Kronen", "\(stats.crownCount(kind))")
                    if DealCatalog.hasDailyLevels(kind) {
                        row("Leicht gewonnen", "\(stats.dailyLevelWon(kind, level: 1).count)")
                        row("Schwer gewonnen", "\(stats.dailyLevelWon(kind, level: 3).count)")
                    }
                    cupRow
                }
                Button("Statistik zurücksetzen", role: .destructive) { confirmReset = true }
                    .frame(maxWidth: .infinity, minHeight: Theme.tapSize)
                    .card()
            }
            .padding(16)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            if router.scrollToAchievements { proxy.scrollTo("erfolge", anchor: .top) }
            if router.scrollToHistory { proxy.scrollTo("verlauf", anchor: .top) }
        }
        }
        .background(Color.seitenGrund)
        .navigationTitle("Statistik")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(kind == .spider
                            ? "Alle Zahlen für \(option) Farben löschen? Das lässt sich nicht rückgängig machen."
                            : kind == .freecell
                            ? "Alle Zahlen für FreeCell löschen? Das lässt sich nicht rückgängig machen."
                            : kind == .yukon
                            ? "Alle Zahlen für Yukon löschen? Das lässt sich nicht rückgängig machen."
                            : kind == .golf
                            ? "Alle Zahlen für Golf löschen? Das lässt sich nicht rückgängig machen."
                            : kind == .tripeaks
                            ? "Alle Zahlen für TriPeaks löschen? Das lässt sich nicht rückgängig machen."
                            : kind == .pyramid
                            ? "Alle Zahlen für Pyramid löschen? Das lässt sich nicht rückgängig machen."
                            : "Alle Zahlen für \(option) Karten löschen? Das lässt sich nicht rückgängig machen.",
                            isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Statistik zurücksetzen", role: .destructive) { stats.reset(mode: mode) }
            Button("Abbrechen", role: .cancel) {}
        }
        .confirmationDialog("Die Gesamtwertung dieser Zieh-Art auf 0 zurücksetzen?", isPresented: $confirmAccountReset, titleVisibility: .visible) {
            Button("Gesamtwertung zurücksetzen", role: .destructive) { stats.resetVegasAccount(mode) }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    /// Leerer Zustand: gezeichnete Karte, Satz und Knopf
    private var emptyState: some View {
        VStack(spacing: 14) {
            ZStack {
                CardBackView(width: 54).rotationEffect(.degrees(-9)).offset(x: -22)
                CardFaceView(face: CardFace(rank: 1, suit: .spades), width: 54).rotationEffect(.degrees(7)).offset(x: 20)
            }
            .frame(height: 96)
            .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
            Text("Noch keine Partie – los geht’s!")
                .font(.system(.headline, design: Design.zahlDesign))
                .multilineTextAlignment(.center)
            Button {
                app.switchTo(mode)
                router.leaveToGame()
            } label: { Text("Spielen").frame(maxWidth: .infinity) }
            .hauptKnopf().controlSize(.large)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    /// Pokale: Anzahl je Stufe (Bronze, Silber, Gold)
    private var cupRow: some View {
        let totals = stats.cupTotals(kind: kind)
        return HStack {
            Text("Pokale").foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 10) {
                ForEach(Cup.allCases, id: \.self) { cup in
                    HStack(spacing: 3) {
                        Image(systemName: "trophy.fill").foregroundStyle(cup.color)
                        Text("\(totals[cup] ?? 0)").font(.system(.body, design: Design.zahlDesign).monospacedDigit())
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(Text("\(cup.title): \(totals[cup] ?? 0)"))
                }
            }
        }
        .font(.subheadline)
    }

    static let levelNames = [1: "Leicht", 2: "Mittel", 3: "Schwer"]

    private func bigNumber(_ value: String, _ caption: LocalizedStringKey, gold: Bool) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.largeTitle, design: Design.zahlDesign).weight(.black)).monospacedDigit()
                .foregroundStyle(gold ? Color.appFarbe : .primary)
                .minimumScaleFactor(0.6).lineLimit(1)
            Text(caption).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func block(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title)
            content()
        }
        .card()
        .accessibilityElement(children: .combine)
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


/// Ring für die Siegquote: Gold auf Grau, die Zahl steht in der Mitte
private struct QuoteRing: View {
    let percent: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = 0.0

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 11)
            Circle().trim(from: 0, to: shown)
                .stroke(Color.appFarbe, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text("\(percent) %").font(.system(.title2, design: Design.zahlDesign).weight(.black)).monospacedDigit().minimumScaleFactor(0.6)
                Text("Quote").font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.6)
            }
            .dynamicTypeSize(...DynamicTypeSize.xLarge)         // der Ring hat feste Größe
            .padding(14)
        }
        .onAppear {
            if reduceMotion { shown = Double(percent) / 100 }
            else { withAnimation(.easeOut(duration: 0.7)) { shown = Double(percent) / 100 } }
        }
        .onChange(of: percent) { _, p in withAnimation(.easeOut(duration: 0.4)) { shown = Double(p) / 100 } }
    }
}
