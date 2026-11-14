// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

extension GameKind {
    var title: String {
        switch self {
        case .klondike: String(localized: "Klondike")
        case .spider: String(localized: "Spider")
        case .freecell: String(localized: "FreeCell")
        case .pyramid: String(localized: "Pyramid")
        case .tripeaks: String(localized: "TriPeaks")
        case .golf: String(localized: "Golf")
        case .yukon: String(localized: "Yukon")
        }
    }

    /// Mini-Symbol für Kapseln (Statistik, Regeln)
    var symbol: String {
        switch self {
        case .klondike: "rectangle.stack.fill"
        case .spider: "circle.grid.3x3.fill"
        case .freecell: "square.grid.2x2.fill"
        case .pyramid: "triangle.fill"
        case .tripeaks: "mountain.2.fill"
        case .golf: "flag.fill"
        case .yukon: "snowflake"
        }
    }

    /// Spiele, die es in der App gibt (FreeCell kommt später)
    static var available: [GameKind] { [.klondike, .spider, .freecell, .pyramid, .tripeaks, .golf, .yukon] }

    /// Optionen des Modus: Klondike 1/3 Karten, Spider 1/2/4 Farben
    var options: [Int] {
        switch self {
        case .klondike: [1, 3]
        case .spider: [1, 2, 4]
        case .freecell, .pyramid, .tripeaks, .golf, .yukon: [0]
        }
    }
}

/// Spiele-Übersicht: Raster mit je einer Kachel pro Spiel, Modus wählen, Weiterspielen beim laufenden Spiel.
struct GamesView: View {
    @Environment(AppModel.self) private var app
    @Environment(StatsStore.self) private var stats
    @Environment(Router.self) private var router
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Modi mit angefangener Partie; wird außerhalb des Zeichnens geladen
    @State private var runningKeys: Set<String> = []
    /// Spiel mit Varianten, für das gerade die Variante gewählt wird (Klondike 1/3 Karten, Spider 1/2/4 Farben)
    @State private var waehleVariante: GameKind?
    /// Auf der Startseite eingebettet: nur das Raster, ohne eigenen Titel, Scroll und Hintergrund
    var embedded = false

    var body: some View {
        if embedded {
            grid
                .task { runningKeys = await app.runningKeys(for: GameKind.available.map(mode(of:))) }
        } else { sheetBody }
    }

    /// Eine Karte je Spiel, untereinander (Klar & Glas: Spielauswahl)
    private var grid: some View {
        VStack(spacing: Theme.kartenAbstand) { ForEach(GameKind.available, id: \.self) { tile($0) } }
    }

    private var sheetBody: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: Design.Abstand.l) {
                StartTitel("Spiele", gruss: Gruss.text(name: nil))
                // Bei sehr großer Schrift eine Spalte, sonst zwei (ab 700 pt Breite drei)
                grid
            }
            .padding(16)
            .padding(.bottom, 24)                                   // unter der letzten Kachel bleibt Rand (U5)
            .frame(maxWidth: Theme.wideColumnWidth)
            .frame(maxWidth: .infinity)
            .id("ende")
        }
        .onAppear { if router.scrollGamesToEnd { proxy.scrollTo("ende", anchor: .bottom) } }
        }
        .background(Color.seitenGrund)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .navigationBarTitleDisplayMode(.inline)
        .task { runningKeys = await app.runningKeys(for: GameKind.available.map(mode(of:))) }
    }

    // MARK: Kachel

    private func mode(of kind: GameKind) -> GameMode {
        switch kind {
        case .klondike: app.prefs.klondikeMode
        case .spider: app.prefs.spiderMode
        case .freecell: .freecell
        case .pyramid: .pyramid
        case .tripeaks: .tripeaks
        case .golf: .golf
        case .yukon: .yukon
        }
    }

    private func modeText(_ m: GameMode) -> String {
        switch m.kind {
        case .klondike: m.option == 3 ? String(localized: "3 Karten") : String(localized: "1 Karte")
        case .spider: m.option == 1 ? String(localized: "1 Farbe") : String(localized: "\(m.option) Farben")
        case .freecell: String(localized: "4 Zellen")
        case .pyramid: String(localized: "Summe 13")
        case .tripeaks: String(localized: "3 Gipfel")
        case .golf: String(localized: "Eins höher oder tiefer")
        case .yukon: String(localized: "Jede offene Karte zieht mit")
        }
    }

    private func subtitle(_ m: GameMode) -> String {
        if let rate = stats.stats(mode: m).winRate { return "\(modeText(m)) · \(rate) %" }
        return modeText(m)
    }

    private func tile(_ kind: GameKind) -> some View {
        let m = mode(of: kind)
        let current = app.session.mode.kind == kind
        let running = runningKeys.contains(m.key)
        let today = DailyDate.string(.now)
        let dailyWon = stats.data.daily[kind.rawValue]?.won.contains(today) == true
        let untertitel = subtitle(m) + (running ? " · " + String(localized: "Weiterspielen") : "")
        return AuswahlZeile(symbol: kind.symbol, titel: LocalizedStringKey(kind.title), untertitel: LocalizedStringKey(untertitel), laeuft: current) {
            // Läuft schon eine Partie dieser Variante, geht es direkt weiter; sonst erst die Variante wählen
            if kind.options.count > 1 && !running { waehleVariante = kind } else { open(m) }
        }
        .accessibilityLabel(Text(verbatim: [kind.title, untertitel,
                                            dailyWon ? String(localized: "Tagesspiel gewonnen") : nil].compactMap { $0 }.joined(separator: ", ")))
        .confirmationDialog(kind.title, isPresented: Binding(get: { waehleVariante == kind }, set: { if !$0 && waehleVariante == kind { waehleVariante = nil } }),
                            titleVisibility: .visible) {
            ForEach(kind.options, id: \.self) { option in
                Button(modeText(kind == .klondike ? .klondike(option) : .spider(option))) {
                    switch kind {
                    case .klondike: app.prefs.drawCount = option
                    case .spider: app.prefs.spiderColors = option
                    case .freecell, .pyramid, .tripeaks, .golf, .yukon: break
                    }
                    open(mode(of: kind))
                }
            }
            Button("Abbrechen", role: .cancel) {}
        }
    }

    private func open(_ mode: GameMode) {
        SpielHaptik.tap()
        withAnimation(.easeInOut(duration: 0.25)) { app.switchTo(mode) }
        router.leaveToGame()
    }
}

