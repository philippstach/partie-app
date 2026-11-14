// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielbildschirm von „Solitär“: Spielkopf, Chip-Zeile, Tisch in der Resthöhe, Leiste fest unten (quer senkrecht am Rand).
/// Kein Scrollen. Der Tisch (`TableView`) und seine Layouts sind die der alten App; Kopf, Leiste, Einblendungen und Sieg sind neu und klein.
struct NeuTisch: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let zurSammlung: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var neuDialog = false
    @State private var siegPhase = SiegPhase.keine
    @State private var fenster = CGSize.zero
    @State private var gemeldet = false

    enum SiegPhase { case keine, wasserfall, konfetti }

    private var store: any GameSession { app.session }

    /// iPhone bleibt bei den Größenklassen; nur das iPad entscheidet nach Fensterbreite
    private var tisch: TischLayout {
        guard UIDevice.current.userInterfaceIdiom == .pad, fenster.width > 0 else { return .schmal }
        return TischLayout.entscheide(fenster)
    }
    private var quer: Bool { (verticalSizeClass == .compact || tisch == .breitQuer) && !store.replaying }
    private var breit: Bool { tisch != .schmal }
    private var barBreite: CGFloat { breit ? 520 : .infinity }
    private var aktionen: NeuAktionen { NeuAktionen(neu: { neuDialog = true }, menue: { router.path = []; router.showMenu = true }) }
    private var schema: ColorScheme? { app.prefs.activeTable.lightText ? .dark : nil }

    var body: some View {
        inhalt
            .environment(\.colorScheme, schema ?? colorSchemeStandard)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { fenster = $0 }
            .background { NeuTastatur(neu: { neuDialog = true }) }
            .background(TableBackground(style: app.prefs.activeTable).ignoresSafeArea())
            .onChange(of: store.isWon, initial: true) { _, gewonnen in
                if !gewonnen { siegPhase = .keine; return }
                if !store.justWon { app.newGame(); return }        // beendete Partie aus einem alten Stand: gleich neu austeilen
                if reduceMotion { siegAbschluss() } else { siegPhase = .wasserfall }
            }
            .sheet(isPresented: Bindable(router).showMenu) { MenuView().formSheet() }
            .onChange(of: router.showMenu || router.showStart) { _, offen in if offen { store.pauseClock() } else { store.resumeClock() } }
            .confirmationDialog("Neue Partie", isPresented: $neuDialog, titleVisibility: .hidden) {
                Button("Neues Spiel") { app.newGame() }
                Button("Gleiche Partie neu") { app.restartSameDeal() }
                Button("Abbrechen", role: .cancel) {}
            }
            .alert("Speichern fehlgeschlagen", isPresented: Binding(get: { store.saveError != nil }, set: { if !$0 { store.saveError = nil } })) {
                Button("OK") { store.saveError = nil }
            } message: { Text(store.saveError ?? "") }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { if !(router.showMenu || router.showStart) { store.resumeClock() } } else { store.pauseClock() }
                if phase == .background {
                    // Der Spielstand wird im Hintergrund geschrieben: das System hält die App erst an, wenn er auf der Platte ist
                    let task = UIApplication.shared.beginBackgroundTask(withName: "Spielstand speichern")
                    let sitzung = store
                    Task { @MainActor in await sitzung.settleSaves(); UIApplication.shared.endBackgroundTask(task) }
                }
            }
            .onAppear { if !router.showStart { store.resumeClock() }; store.scheduleStartHints() }
    }

    @Environment(\.colorScheme) private var colorSchemeStandard

    @ViewBuilder
    private var inhalt: some View {
        if quer {
            HStack(spacing: 0) {
                if app.prefs.leftHanded { seitenLeiste }
                VStack(spacing: 0) { NeuKopf(titel: NeuText.variante(store.mode), zurWahl: { router.showStart = true }, menue: aktionen.menue); tischFlaeche }
                if !app.prefs.leftHanded { seitenLeiste }
            }
        } else {
            VStack(spacing: 0) {
                NeuKopf(titel: NeuText.variante(store.mode), zurWahl: { router.showStart = true }, menue: aktionen.menue)
                tischFlaeche
                if store.replaying { NeuAbspieler() }
                else { NeuLeiste(aktionen: aktionen).frame(maxWidth: barBreite).frame(maxWidth: .infinity).padding(.bottom, 4) }
            }
        }
    }

    private var seitenLeiste: some View { NeuLeiste(aktionen: aktionen, quer: true) }

    private var tischFlaeche: some View {
        tischAnsicht
            .padding(.top, 6)
            .overlay(alignment: .bottom) {
                VStack(spacing: Design.Abstand.m) {
                    NeuHinweise(maxBreite: barBreite)
                    if store.canFinish, !store.isWon {
                        Button { store.autoFinish() } label: { Text("Fertig spielen") }.hauptKnopf()
                    }
                }
            }
            .overlay { if siegPhase == .konfetti { ConfettiView().allowsHitTesting(false).transition(.opacity) } }
    }

    /// Wasserfall zu Ende: 1,2 s Konfetti, dann geht der Sieg an den Rahmen
    private func wasserfallFertig() {
        guard siegPhase == .wasserfall else { return }
        siegPhase = .konfetti
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            if siegPhase == .konfetti { siegAbschluss() }
        }
    }

    /// Meldet den Sieg an den `SpielRahmen` (Ende-Bildschirm, Statistik der Sammlung) und teilt danach die nächste Partie aus.
    private func siegAbschluss() {
        guard !gemeldet, store.isWon else { return }
        gemeldet = true
        let s = store
        // Blatt 22 (EB-1): Satz nur noch die Variante, Zeit, Züge und Punkte stehen als Werte, dazu die vollen Ablagestapel als Bild.
        // Das Bild wird vor `app.newGame()` gebaut, danach ist der Stand weg.
        var e = SpielEnde(reihenfolge: [name], punkte: s.displayScore.map { [String($0)] } ?? [], plaetze: [1], info: NeuText.variante(s.mode))
        e.werte = NeuEndeInhalt.werte(s)
        e.bild = NeuEndeInhalt.bild(s.mode, vierFarben: app.prefs.fourColor)
        app.newGame()
        ende(e)
    }

    /// Der Tisch des aktiven Spiels (jede Variante hat ihren eigenen Typ)
    @ViewBuilder
    private var tischAnsicht: some View {
        let wasserfall = siegPhase == .wasserfall
        switch app.active {
        case let .klondike(s): TableView(store: s, showWaterfall: wasserfall, onWaterfallDone: wasserfallFertig).id(GameKind.klondike)
        case let .spider(s): TableView(store: s, showWaterfall: wasserfall, onWaterfallDone: wasserfallFertig).id(GameKind.spider)
        case let .freecell(s): TableView(store: s, showWaterfall: wasserfall, onWaterfallDone: wasserfallFertig).id(GameKind.freecell)
        case let .pyramid(s): TableView(store: s, showWaterfall: wasserfall, onWaterfallDone: wasserfallFertig).id(GameKind.pyramid)
        case let .tripeaks(s): TableView(store: s, showWaterfall: wasserfall, onWaterfallDone: wasserfallFertig).id(GameKind.tripeaks)
        case let .golf(s): TableView(store: s, showWaterfall: wasserfall, onWaterfallDone: wasserfallFertig).id(GameKind.golf)
        case let .yukon(s): TableView(store: s, showWaterfall: wasserfall, onWaterfallDone: wasserfallFertig).id(GameKind.yukon)
        }
    }
}

/// Tastaturkürzel (Hardware-Tastatur am iPad): ⌘Z Zurück · ⌘N Neu · ⌘T oder Leertaste Tipp · ⌘F Fertig · Esc Menü schließen
struct NeuTastatur: View {
    let neu: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(Router.self) private var router
    private var store: any GameSession { app.session }

    var body: some View {
        Group {
            Button("") { if store.canUndo { store.undo() } }.keyboardShortcut("z", modifiers: .command)
            Button("", action: neu).keyboardShortcut("n", modifiers: .command)
            Button("") { store.showHint() }.keyboardShortcut("t", modifiers: .command)
            Button("") { store.showHint() }.keyboardShortcut(.space, modifiers: [])
            Button("") { if store.canFinish { store.autoFinish() } }.keyboardShortcut("f", modifiers: .command)
            Button("") { router.showMenu = false }.keyboardShortcut(.escape, modifiers: [])
        }
        .opacity(0).frame(width: 0, height: 0).accessibilityHidden(true).allowsHitTesting(false)
    }
}
