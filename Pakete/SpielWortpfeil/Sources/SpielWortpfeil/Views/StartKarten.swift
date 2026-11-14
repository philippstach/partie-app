// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

extension Level {
    var sizeText: String {
        switch self {
        case .leicht: "7 × 9"
        case .mittel: "9 × 12"
        case .schwer: "11 × 15"
        }
    }
}

/// Die Kreuzworträtsel-eigenen Karten auf der Startseite des Rahmens (`mitStartInhalt`): Rätsel des Tages, Stufen mit Fortschritt,
/// Themen, alle Rätsel, Archiv und Einstellungen. Ein Tipp merkt das gewünschte Rätsel vor und startet es über den Rahmen;
/// der fragt nach, falls dabei ein laufendes Rätsel verworfen würde.
struct WortpfeilStartKarten: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dynamicTypeSize) private var schriftGroesse
    let aktionen: SpielStartAktionen
    @State private var completedLevel: Level?
    @State private var blatt: Blatt?
    /// Design-Runde 3 (Tinte): Die Karten sind eine Wahl. Der eine Knopf „Spielen“ der Spielseite startet das Gewählte (`aktionen.vormerken`).
    @State private var wahl: GameStore.Start?
    private var tinte: Bool { Design.ist(.tinte) }

    /// Blätter der Startseite. Wird darin ein Rätsel gewählt, startet es, sobald das Blatt zu ist.
    enum Blatt: Identifiable {
        case liste, thema(ThemeInfo), archiv, einstellungen
        var id: String {
            switch self {
            case .liste: "liste"
            case .thema(let t): "thema-" + t.id
            case .archiv: "archiv"
            case .einstellungen: "einstellungen"
            }
        }
    }

    var body: some View {
        let _ = store.dayRevision   // Tageswechsel: Datum und Tageskarte neu zeichnen
        VStack(spacing: Theme.kartenAbstand) {
            if store.packsLoading {
                ProgressView().frame(maxWidth: .infinity, minHeight: 200)
            } else if store.library.isEmpty {
                missingPacks
            } else {
                if isNewcomer { newcomerCard }
                dailyCard()
                levelCard
                if !store.library.themes.isEmpty { themesSection }
                VStack(spacing: 0) {
                    linkZeile("Alle Rätsel ansehen", symbol: "square.grid.3x3") { blatt = .liste }
                    Divider()
                    linkZeile("Archiv und Zeiten", symbol: "calendar") { blatt = .archiv }
                    Divider()
                    linkZeile("Einstellungen", symbol: "gearshape") { blatt = .einstellungen }
                }
                .padding(.horizontal, Theme.innen)
                .background(Color.karte, in: .rect(cornerRadius: Design.Ecke.karte))
            }
        }
        .tint(Color.kwAkzent)
        .onAppear { store.abgleichen(); if tinte { wahl = nil; aktionen.vormerken(nil) } }
        .sheet(item: $blatt, onDismiss: {
            guard let w = store.vorgemerkt else { return }
            if tinte { store.vorgemerkt = nil; wahl = nil; waehlen(w) } else { aktionen.neu() }   // Tinte: Wahl aus dem Blatt, gestartet wird mit „Spielen“
        }) { b in
            Group {
                if case .einstellungen = b {
                    SettingsView()   // bringt Titel und „Fertig“ selbst mit
                } else {
                    NavigationStack {
                        Group {
                            switch b {
                            case .liste: LevelListView(starten: { vormerken(.raetsel($0)) })
                            case .thema(let t): ThemeListView(theme: t, starten: { vormerken(.raetsel($0)) })
                            default: StatsView(starten: { vormerken($0 == store.today ? .tages : .archiv($0)) })
                            }
                        }
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { blatt = nil } } }
                    }
                }
            }
            .environment(store)
            .tint(Color.kwAkzent)
        }
        .confirmationDialog(completedTitle, isPresented: completedBinding, titleVisibility: .visible) {
            Button("Von vorn beginnen") {
                guard let l = completedLevel else { return }
                // erst wenn die Abfrage zu ist: der Rahmen fragt bei einem laufenden Rätsel selbst noch einmal nach
                Task { try? await Task.sleep(for: .milliseconds(400)); starten(.stufeVonVorn(l)) }
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text(aktionen.standVorhanden
                 ? "Alle Rätsel dieser Stufe sind gelöst. Du kannst sie noch einmal von vorn spielen. Dein laufendes Rätsel geht dabei verloren."
                 : "Alle Rätsel dieser Stufe sind gelöst. Du kannst sie noch einmal von vorn spielen.")
        }
    }

    /// Sofort starten (Karte der Startseite)
    private func starten(_ wunsch: GameStore.Start) {
        if tinte { waehlen(wunsch); return }   // Tinte: nur wählen, der eine Knopf „Spielen“ startet
        store.vorgemerkt = wunsch
        aktionen.neu()
    }

    /// Tinte: Karte an- oder abwählen und dem Rahmen melden, was „Spielen“ starten soll.
    private func waehlen(_ wunsch: GameStore.Start) {
        wahl = (wahl == wunsch) ? nil : wunsch
        let gewaehlt = wahl, spiel = store
        aktionen.vormerken(gewaehlt.map { s in { spiel.vorgemerkt = s } })
    }

    /// Wahlzeichen der Tinte-Karten: Kreis, bei der Wahl mit Haken.
    private func wahlZeichen(_ wunsch: GameStore.Start, farbe: Color) -> some View {
        Image(systemName: wahl == wunsch ? "checkmark.circle.fill" : "circle").font(.title3).foregroundStyle(farbe).accessibilityHidden(true)
    }

    /// Aus einem Blatt heraus: vormerken und das Blatt schließen; gestartet wird, wenn es zu ist (`onDismiss`)
    private func vormerken(_ wunsch: GameStore.Start) {
        store.vorgemerkt = wunsch
        blatt = nil
    }

    /// „Spielen“ auf der Tageskarte: Läuft das heutige Tagesrätsel schon, geht es dort weiter
    private func playDaily() {
        if aktionen.standVorhanden, store.game?.dailyKey == store.today.description, store.hasRunningGame { aktionen.fortsetzen() }
        else { starten(.tages) }
    }

    private func linkZeile(_ titel: LocalizedStringKey, symbol: String, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack {
                Label(titel, systemImage: symbol)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Color.kwAkzent)
            .frame(minHeight: 48)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var completedBinding: Binding<Bool> {
        Binding(get: { completedLevel != nil }, set: { if !$0 { completedLevel = nil } })
    }

    private var completedTitle: LocalizedStringKey {
        guard let l = completedLevel else { return "" }
        return "Alle \(store.totalCount(l)) \(levelAdjective(l)) Rätsel gelöst!"
    }

    /// Wer die Einführung noch nicht gesehen und noch nichts gespielt hat, bekommt oben die Karte „Neu hier?“
    private var isNewcomer: Bool {
        !store.preferences.introSeen && !store.hasRunningGame && store.stats.totalWon == 0
    }

    // MARK: Neu hier? (ersetzt die drei Einführungsseiten beim ersten Öffnen)

    private var newcomerCard: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            HStack(alignment: .firstTextBaseline) {
                Text("Neu hier?").font(.headline).foregroundStyle(Color.tinte).accessibilityAddTraits(.isHeader)
                Spacer()
                Button { withAnimation { store.preferences.introSeen = true } } label: {
                    Image(systemName: "xmark").font(.footnote.weight(.semibold)).foregroundStyle(.secondary)
                        .frame(width: 44, height: 44).contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Schließen")
                .padding(.top, -12).padding(.trailing, -12).padding(.bottom, -12)
            }
            ExampleWord().frame(maxWidth: .infinity)
            Text("Die Frage steht im Kästchen, der Pfeil zeigt die Richtung. Im ersten Rätsel ist jeder Anfangsbuchstabe schon eingetragen.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button { store.preferences.introSeen = true; starten(.einstieg) } label: {
                Label("Erstes Rätsel starten", systemImage: "play.circle")
                    .font(.subheadline.weight(.semibold)).frame(minHeight: 44)
            }
            .buttonStyle(.plain).foregroundStyle(Color.kwAkzent)
            .padding(.vertical, -8)
        }
        .card()
    }

    // MARK: Tageskarte (Held)

    /// Design-Runde 3: In Tinte ist das Rätsel des Tages eine Wahlzeile wie bei Sudoku (keine blaue Karte, kein eigener Knopf);
    /// der eine Knopf „Spielen“ der Seite startet es. Klar und Salon zeigen die Karte wie bisher.
    @ViewBuilder private func dailyCard() -> some View {
        if tinte { dailyZeile() } else { dailyHeld() }
    }

    private func dailyZeile() -> some View {
        let today = store.today
        let solved = store.isDailySolvedToday
        let streak = store.stats.streak(today: today)
        return Button { if !solved { playDaily() } } label: {
            HStack(spacing: Design.Abstand.m) {
                wahlZeichen(.tages, farbe: Color.schrift)
                VStack(alignment: .leading, spacing: 2) {
                    Label("Rätsel des Tages", systemImage: "calendar").font(.headline).foregroundStyle(Color.schrift)
                    Text(today.date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.footnote).foregroundStyle(Color.schriftZweit)
                }
                Spacer(minLength: 8)
                if solved {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).accessibilityLabel(Text("Gelöst"))
                } else if streak > 0 {
                    Label { Text(verbatim: "\(streak)") } icon: { Image(systemName: "flame.fill") }
                        .font(.footnote.weight(.semibold)).foregroundStyle(Color.orange)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(wahl == .tages ? [.isButton, .isSelected] : .isButton)
        .linieUnten()
    }

    private func dailyHeld() -> some View {
        let today = store.today
        let key = today.description
        let solved = store.isDailySolvedToday
        let streak = store.stats.streak(today: today)
        let puzzle = store.library.dailyPuzzle(for: today)
        let entries = store.game.flatMap { $0.dailyKey == key ? $0.entries : nil } ?? [:]
        return VStack(alignment: .leading, spacing: Design.Abstand.m) {
            HStack(alignment: .top, spacing: Design.Abstand.m) {
                VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                    Text("Rätsel des Tages").font(.title2.weight(.bold)).foregroundStyle(Color.kwAufHeld)
                        .accessibilityAddTraits(.isHeader)
                    Text(today.date().formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .font(.subheadline).foregroundStyle(Color.kwAufHeld.opacity(0.85))
                }
                Spacer(minLength: 0)
                // A-008: In den Bedienungshilfe-Größen fehlt neben dem Titel der Platz für das Mini-Raster (Titel brach Wort für Wort um)
                if let puzzle, !schriftGroesse.isAccessibilitySize {
                    MiniGrid(puzzle: puzzle, entries: entries).frame(width: 52, height: 52)
                        .padding(5).background(Color.feldLeer, in: .rect(cornerRadius: Design.Ecke.klein))
                }
            }
            lastDays
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Design.Abstand.m) { dailyStatus(solved: solved, key: key, streak: streak); Spacer(minLength: 0); if !solved { playChip } }
                VStack(alignment: .leading, spacing: Design.Abstand.s) { dailyStatus(solved: solved, key: key, streak: streak); if !solved { playChip } }
            }
        }
        .padding(Theme.innen)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.kwHeld, in: .rect(cornerRadius: Theme.cardRadius))
        .overlay { if tinte && wahl == .tages { RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).strokeBorder(Color.kwAufHeld, lineWidth: 3) } }
        .accessibilityAddTraits(tinte && wahl == .tages ? .isSelected : [])
        .kartenAktion { if !solved { playDaily() } }
    }

    @ViewBuilder
    private func dailyStatus(solved: Bool, key: String, streak: Int) -> some View {
        if solved {
            VStack(alignment: .leading, spacing: 2) {
                Label {
                    Text(store.stats.dailyTimes[key].map { "Gelöst in \(Zeitformat.text($0))" } ?? String(localized: "Gelöst"))
                } icon: {
                    Image(systemName: store.stats.dailyNoHelp.contains(key) ? "star.circle.fill" : "checkmark.circle.fill")
                }
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color.kwAufHeld)
                Text("Morgen gibt’s ein neues").font(.subheadline).foregroundStyle(Color.kwAufHeld.opacity(0.85))
            }
        } else if streak > 0 {
            Label("Serie: \(streak) Tage", systemImage: "flame.fill")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color.kwAufHeld)
        }
    }

    /// Sichtbarer Hinweis „Spielen“ auf der Tageskarte (die ganze Karte ist der Knopf)
    private var playChip: some View {
        HStack(spacing: Design.Abstand.xs) {
            if tinte {   // Design-Runde 3: kein zweiter „Spielen“-Knopf, die Karte ist eine Wahl
                Text("Heute")
                Image(systemName: wahl == .tages ? "checkmark.circle.fill" : "circle").font(.footnote.weight(.bold))
            } else {
                Text("Spielen")
                Image(systemName: "chevron.right").font(.footnote.weight(.bold))
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.kwHeld)
        .padding(.horizontal, 14).frame(minHeight: 34)
        .background(Color.kwAufHeld, in: .capsule)
    }

    private static func wochentagKurz(_ datum: Date) -> String {
        let kal = Calendar.current
        return kal.shortStandaloneWeekdaySymbols[kal.component(.weekday, from: datum) - 1]
    }

    /// Die laufende Woche Mo…So auf der Heldenkarte: Stern (ohne Hilfe), Haken, leerer Ring; heute mit kräftigem Ring
    private var lastDays: some View {
        let today = store.today
        var kal = Calendar(identifier: .gregorian); kal.firstWeekday = 2
        let heuteIndex = (kal.component(.weekday, from: today.date()) + 5) % 7   // Mo = 0 … So = 6 (Fund S2-021: wie die Wochenleiste der anderen Spiele)
        return HStack(spacing: 0) {
            ForEach(Array((0..<7).map { heuteIndex - $0 }), id: \.self) { back in
                let day = today.adding(days: -back)
                let key = day.description
                let solved = store.stats.dailySolved.contains(key)
                VStack(spacing: Design.Abstand.xs) {
                    ZStack {
                        if store.stats.dailyCatchUp.contains(key) {
                            Image(systemName: "checkmark.circle").font(.title3).foregroundStyle(Color.kwAufHeld)
                        } else if solved {
                            Image(systemName: store.stats.dailyNoHelp.contains(key) ? "star.circle.fill" : "checkmark.circle.fill")
                                .font(.title3).foregroundStyle(Color.kwAufHeld)
                        } else {
                            Circle().stroke(Color.kwAufHeld.opacity(back == 0 ? 1 : 0.55), lineWidth: back == 0 ? 2 : 1).frame(width: 18, height: 18)
                        }
                    }
                    .frame(height: 24)
                    // F-AWS-K-012/P-012/M-012: zweibuchstabig (Mo Di Mi …) wie die Wochenleiste der anderen Spiele, nicht „M D M D F S S“
                    Text(verbatim: Self.wochentagKurz(day.date())).lineLimit(1).minimumScaleFactor(0.7)
                        .font(.caption2.weight(back == 0 ? .bold : .regular)).foregroundStyle(Color.kwAufHeld.opacity(back == 0 ? 1 : 0.85))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement()
                .accessibilityLabel(Text(day.date().formatted(.dateTime.weekday(.wide).day().month(.wide))))
                .accessibilityValue(solved ? Text("gelöst") : Text(""))
            }
        }
    }

    // MARK: Neues Rätsel: drei Zeilen in einer Karte (lesbarer als drei schmale Kacheln, auch bei großer Schrift)

    private var levelCard: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            SectionLabel("Neues Rätsel").padding(.leading, 4)
            VStack(spacing: 0) {
                ForEach(Level.allCases) { level in
                    if level != Level.allCases.first { Divider().padding(.leading, tinte ? Theme.innen + 24 + Design.Abstand.m : 62) }   // Tinte: Trenner beginnt beim Titel (schmaleres Zeichen)
                    Button { choose(level) } label: {
                        HStack(spacing: Design.Abstand.m) {
                            if tinte {
                                // T-037 (Blatt 20): Wahlzeichen links wie bei „Rätsel des Tages“, kein Fortschrittsring in Tinte
                                wahlZeichen(.stufe(level), farbe: Color.schrift)
                            } else {
                            ZStack {
                                ProgressRing(done: store.solvedCount(level), total: store.totalCount(level))
                                if store.allSolved(level) {
                                    Image(systemName: "checkmark").font(.subheadline.weight(.bold)).foregroundStyle(Color.kwAkzent)
                                }
                            }
                            .frame(width: 34, height: 34)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(levelTitle(level)).font(.headline).foregroundStyle(Color.tinte)
                                Text("\(level.sizeText) · \(store.solvedCount(level)) von \(store.totalCount(level)) gelöst")
                                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            if tinte { if store.allSolved(level) { Image(systemName: "checkmark.seal.fill").foregroundStyle(.green).accessibilityLabel(Text("Gelöst")) } }
                            else { Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary) }
                        }
                        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                        .padding(.horizontal, Theme.innen)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(store.totalCount(level) == 0)
                    .accessibilityElement(children: .combine)
                    .accessibilityHint(tinte ? Text("Wählt die Stufe für das nächste Rätsel") : Text("Startet ein neues Rätsel"))
                    .accessibilityAddTraits(tinte && wahl == .stufe(level) ? .isSelected : [])
                }
            }
            .background(Color.karte, in: .rect(cornerRadius: Design.Ecke.karte))
        }
    }

    // MARK: Themen (waagerecht wischbare Karten)

    private var themesSection: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.s) {
            SectionLabel("Themen").padding(.leading, 4)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.library.themes) { t in
                        Button { blatt = .thema(t) } label: {
                            VStack(spacing: Design.Abstand.s) {
                                Image(systemName: t.symbol).font(.title3).foregroundStyle(Color.kwAkzent)
                                    .frame(width: 44, height: 44).background(Color.feldFrage, in: .circle)
                                Text(t.name).font(.subheadline.weight(.semibold)).foregroundStyle(Color.tinte)
                                    .lineLimit(2).multilineTextAlignment(.center).frame(height: 38)
                                Text("\(store.themeSolvedCount(t.id))/\(store.library.themePuzzles(t.id).count)")
                                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                            }
                            .frame(width: 112).padding(.vertical, 12)
                            .background(Color.karte, in: .rect(cornerRadius: Design.Ecke.karte))
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func choose(_ level: Level) {
        if store.allSolved(level) { completedLevel = level } else { starten(.stufe(level)) }
    }

    private var missingPacks: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel("Hinweis")
            Text("Die Rätsel konnten nicht geladen werden.").font(.headline)
            Text("Bitte starte die App neu. Hilft das nicht, installiere sie noch einmal.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .card()
    }
}

/// Fortschrittsring in der Akzentfarbe
struct ProgressRing: View {
    let done: Int
    let total: Int

    var body: some View {
        let value = total > 0 ? Double(done) / Double(total) : 0
        ZStack {
            Circle().stroke(Color.kwAkzent.opacity(0.22), lineWidth: 4)
            Circle().trim(from: 0, to: value)
                .stroke(Color.kwAkzent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}

/// Mini-Vorschau eines Gitters: Felder als Punkte, gefüllte in der Akzentfarbe
struct MiniGrid: View {
    let puzzle: Puzzle
    let entries: [Pos: Character]

    var body: some View {
        Canvas { ctx, size in
            let cell = min(size.width / CGFloat(puzzle.breite), size.height / CGFloat(puzzle.hoehe))
            let w = cell * CGFloat(puzzle.breite), h = cell * CGFloat(puzzle.hoehe)
            let origin = CGPoint(x: (size.width - w) / 2, y: (size.height - h) / 2)
            for r in 0..<puzzle.hoehe {
                for c in 0..<puzzle.breite {
                    let pos = Pos(r, c)
                    let rect = CGRect(x: origin.x + CGFloat(c) * cell, y: origin.y + CGFloat(r) * cell, width: cell, height: cell).insetBy(dx: 0.4, dy: 0.4)
                    let color: Color = puzzle.isLetter(pos) ? (entries[pos] != nil ? Color.kwAkzent : .feldLeer)
                        : puzzle.isClueCell(pos) ? .feldFrage : .feldSperre
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
        .overlay(Rectangle().stroke(Color.kwAkzent.opacity(0.5), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

/// „leichten“, „mittleren“, „schweren“ für „Alle 150 leichten Rätsel gelöst!“
func levelAdjective(_ l: Level) -> String {
    switch l {
    case .leicht: String(localized: "leichten")
    case .mittel: String(localized: "mittleren")
    case .schwer: String(localized: "schweren")
    }
}


func levelNameText(_ l: Level) -> String {
    switch l {
    case .leicht: String(localized: "Leicht")
    case .mittel: String(localized: "Mittel")
    case .schwer: String(localized: "Schwer")
    }
}
#endif
