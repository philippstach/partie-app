// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

struct MenuView: View {
    @Environment(AppModel.self) private var app
    @Environment(StatsStore.self) private var stats
    @Environment(Router.self) private var router
    @State private var confirmGiveUp = false
    @State private var choosePlacing = false
    @Environment(\.zurSammlung) private var zurSammlung
    /// KI-3 (Blatt 12): nur mit Apple Intelligence gesetzt; sonst keine Zeile.
    @Environment(\.regelFrage) private var regelFrage

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    HStack {
                        Spacer()
                        RundKnopf(symbol: "xmark", beschriftung: "Weiterspielen") { router.showMenu = false }
                    }
                    VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                        Text("Menü")
                            .font(.largeTitle.weight(.bold))
                            .tracking(-0.02 * 42)
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                        Text(verbatim: StartText.modus(app.session.mode, difficulty: nil, solvable: false))
                            .font(.title3).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 6)
                    if DealCatalog.shared.maxNumber(mode: app.newGameMode) != nil { pickDealRow }
                    if [GameKind.klondike, .freecell, .yukon].contains(app.session.mode.kind) { placingRow }
                    replayCard
                    if canGiveUp { giveUpCard }
                    linkZeile("Statistik") { router.path.append(.stats) }
                    linkZeile("Einstellungen") { router.path.append(.settings) }
                    if let regelFrage {
                        // Das Menü ist ein Blatt: erst schließen, dann das Chat-Blatt des Rahmens öffnen
                        linkZeile("Frag nach den Regeln") { router.showMenu = false; DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { regelFrage() } }
                    }
                    linkZeile("Regeln") { router.path.append(.rules) }
                    // N-S1-007: Rückweg zur Übersicht auch aus dem Menü, nicht nur per Randwischen
                    if let zurSammlung { linkZeile("Zur Übersicht") { router.showMenu = false; zurSammlung() } }
                }
                .padding(.horizontal, Theme.seitenRand)
                .padding(.bottom, Theme.kartenAbstand)
                .frame(maxWidth: Theme.wideColumnWidth)
                .frame(maxWidth: .infinity)
            }
            .background(Color.seitenGrund)
            .safeAreaInset(edge: .bottom) { newGameCard }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: MenuRoute.self) { route in
                switch route {
                case .daily: DailyView(month: router.dailyMonth, kind: app.session.mode.kind)
                case .stats: StatsView()
                case .settings: SettingsView()
                case .rules: RulesView()
                case .games: GamesView()
                case .pickDeal: PickDealView()
                }
            }
        }
    }

    /// „Lösbare Partie · Mittel“ – bei Spielen ohne Stufen nur „Lösbare Partie“, bei Zufall „Zufällige Partie“
    private var newGameSubtitle: String {
        let mode = app.newGameMode
        if !app.prefs.solvableDeals || (mode.kind != .freecell && DealCatalog.shared.listName(for: mode) == nil) {
            return String(localized: "Zufällige Partie")
        }
        guard DealCatalog.shared.hasLevels(mode) else { return String(localized: "Lösbare Partie") }
        let names = [String(localized: "Gemischt"), String(localized: "Leicht"), String(localized: "Mittel"), String(localized: "Schwer")]
        return String(localized: "Lösbare Partie") + " · " + names[app.prefs.difficulty]
    }

    private var newGameCard: some View {
        VStack(spacing: 6) {
            Button("Neues Spiel") {
                app.newGame()
                router.showMenu = false
            }
            .hauptKnopf()
            Text(verbatim: newGameSubtitle)
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.horizontal, Theme.seitenRand).padding(.vertical, 8)
        .frame(maxWidth: Theme.wideColumnWidth)
        .frame(maxWidth: .infinity)
        .background(Color.seitenGrund)
    }

    /// „Partie wählen…“: öffnet die Eingabe der Partienummer
    private var pickDealRow: some View {
        NavigationLink(value: MenuRoute.pickDeal) {
            zeile("Partie wählen…", "Spiele eine bestimmte Nummer – auch von Freunden") {
                Image(systemName: "chevron.right").font(.body.weight(.semibold)).foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .buttonStyle(.plain)
    }

    /// „Karten ablegen: Automatisch ›“ – öffnet dieselbe Auswahl wie die Einstellungen (einzige Ausnahme von der Ruhe-Regel, auf Philipps Wunsch)
    private var placingRow: some View {
        Button { choosePlacing = true } label: {
            zeile("Karten ablegen", app.prefs.autoFoundation ? "Automatisch" : "Selbst") {
                Image(systemName: "chevron.right").font(.body.weight(.semibold)).foregroundStyle(Color(.tertiaryLabel))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: String(localized: "Karten ablegen") + ": " + String(localized: app.prefs.autoFoundation ? "Automatisch" : "Selbst")))
        .confirmationDialog("Karten ablegen", isPresented: $choosePlacing, titleVisibility: .visible) {
            Button("Automatisch") { app.prefs.choosePlacing(automatic: true) }
            Button("Selbst") { app.prefs.choosePlacing(automatic: false) }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Selbst: Du legst jede Karte ab. Automatisch: sichere Karten wandern von selbst nach oben.")
        }
    }

    /// Aufgeben: nur bei angefangener, nicht zu Ende gespielter Partie
    private var canGiveUp: Bool {
        let s = app.session
        return s.moves > 0 && !s.isWon && !s.gaveUp
    }

    private var giveUpCard: some View {
        Button(role: .destructive) { confirmGiveUp = true } label: {
            HStack {
                Text("Aufgeben").font(.headline)
                Spacer()
                Image(systemName: "flag.fill")
            }
            .foregroundStyle(.red)
            .card()
        }
        .buttonStyle(.plain)
        .confirmationDialog("Aufgeben?", isPresented: $confirmGiveUp, titleVisibility: .visible) {
            Button("Aufgeben", role: .destructive) {
                app.session.giveUp()
                router.showMenu = false
            }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Die Partie zählt als verloren. Bei lösbaren Partien kannst du danach die Lösung ansehen.")
        }
    }

    private var replayCard: some View {
        Button {
            app.restartSameDeal()
            router.showMenu = false
        } label: {
            zeile("Gleiche Partie neu", "Partie #\(app.session.deal.number)") {
                Image(systemName: "arrow.counterclockwise").font(.body.weight(.semibold)).foregroundStyle(Color.accentText)
            }
        }
        .buttonStyle(.plain)
    }

    /// Sprungzeile in einer Karte: wie die Zeilen darüber (Titel fett, serifenlos), Pfeil rechts, kein Untertitel.
    private func linkZeile(_ titel: LocalizedStringKey, aktion: @escaping () -> Void) -> some View {
        Button(action: aktion) {
            HStack {
                Text(titel).font(.headline).foregroundStyle(.primary).frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold)).foregroundStyle(.tertiary).accessibilityHidden(true)
            }
            .frame(minHeight: Theme.tapSize).contentShape(.rect)
            .card()
        }
        .buttonStyle(.plain)
    }

    /// Zeile in einer Karte: Titel fett, Untertitel grau, rechts ein Symbol (gleiche Optik wie `StatistikZeile`)
    private func zeile<Rechts: View>(_ titel: LocalizedStringKey, _ untertitel: LocalizedStringKey, @ViewBuilder rechts: () -> Rechts) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(titel).font(.headline).foregroundStyle(.primary)
                Text(untertitel).font(.subheadline).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            rechts()
        }
        .card()
    }
}
