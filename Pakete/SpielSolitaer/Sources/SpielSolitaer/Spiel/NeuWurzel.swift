// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import Baukasten
import SpieleKern

/// Wurzel von „Solitär“: der Tisch liegt immer darunter, die Variantenwahl darüber (ohne eigene Hülle).
/// Eigene Spielstände und eigene Statistik liegen im Ordner `solitaer-neu`, die Einstellungen (Tisch, Rücken, Anzeige) bleiben dieselben.
struct NeuWurzel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let zurSammlung: () -> Void
    @State private var app: AppModel
    @State private var router = Router()
    /// Design-Runde 3 (Tinte): Die Wahl der Spielseite wird nur beim frischen Start angewandt, nicht beim Fortsetzen.
    private let fortsetzt: Bool
    @State private var angewandt = false
    @Environment(\.scenePhase) private var szene

    /// Ordner mit Spielständen und Statistik von „Solitär“
    nonisolated static var ordner: URL {
        let url = AppModel.standardFolder.appending(path: NeuText.kennung, directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    #if DEBUG
    @MainActor private static var testZustandGesetzt = false
    #endif

    init(name: String, ende: @escaping (SpielEnde) -> Void, zurSammlung: @escaping () -> Void) {
        self.name = name; self.ende = ende; self.zurSammlung = zurSammlung
        let ordner = Self.ordner
        let stats = StatsStore(url: ordner.appending(path: "statistik.json"))
        stats.meldeKennung = NeuText.kennung; stats.meldeName = name
        let model = AppModel(prefs: AppPreferences(), stats: stats, folder: ordner)
        #if DEBUG
        var testAktiv = false
        // T-2: Der Testzustand „ende“ gewinnt die Partie schon im `init`. Meldet das `ende` an den Rahmen, baut der die Wurzel neu, deren `init`
        // setzt den Testzustand wieder und gewinnt wieder: Endlosschleife (App hängt). Darum nur einmal je Start.
        if !Self.testZustandGesetzt, let art = Testzustand.art, ["solitaer", NeuText.kennung].contains(UserDefaults.standard.string(forKey: "startetMit") ?? "") {
            Self.testZustandGesetzt = true
            model.switchTo(.klondike(1))
            model.session.testZustand(ende: art == .ende); testAktiv = true
        }
        #endif
        _app = State(initialValue: model)
        let router = Router()
        // B21: „Partie fortsetzen“ im Rahmen öffnet gleich den Tisch, wenn im zuletzt gespielten Modus eine Partie läuft (sonst die Wahl).
        let fortsetzen = SpielStand.vorhanden(NeuText.kennung) && model.session.moves > 0 && !model.session.isWon && !model.session.gaveUp
        #if DEBUG
        router.showStart = !fortsetzen && !testAktiv && !Design.ist(.tinte)
        fortsetzt = fortsetzen || testAktiv
        #else
        router.showStart = !fortsetzen && !Design.ist(.tinte)   // Tinte: die Wahl steht auf der Spielseite des Rahmens
        fortsetzt = fortsetzen
        #endif
        _router = State(initialValue: router)
    }

    /// Design-Runde 3 (Tinte): Startet, was auf der Spielseite gewählt wurde (siehe `NeuStartWahl`).
    private func wahlAnwenden() {
        guard Design.ist(.tinte), !fortsetzt, !angewandt else { return }
        angewandt = true
        let d = UserDefaults.standard
        let wahl = d.string(forKey: NeuStartWahl.schluessel) ?? ""
        d.removeObject(forKey: NeuStartWahl.schluessel)
        if wahl.hasPrefix("daily:"), let art = GameKind(rawValue: String(wahl.dropFirst(6))) { app.startDaily(.now, kind: art); return }
        guard !wahl.isEmpty else { return }
        let modus = AppModel.mode(forKey: wahl)
        if modus.kind == .klondike { app.prefs.drawCount = modus.option } else if modus.kind == .spider { app.prefs.spiderColors = modus.option }
        app.switchTo(modus)
    }

    private var laeuft: Bool { app.session.moves > 0 && !app.session.isWon && !app.session.gaveUp }

    var body: some View {
        ZStack {
            NeuTisch(name: name, ende: ende, zurSammlung: zurSammlung)
                .accessibilityHidden(router.showStart)
                .allowsHitTesting(!router.showStart)
            if router.showStart {
                NeuWahl(zurSammlung: zurSammlung)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: router.showStart)
        .environment(app)
        .environment(app.stats)
        .environment(router)
        .environment(\.cardBackStyle, app.prefs.cardBack)
        .environment(\.tableStyle, app.prefs.activeTable)
        .environment(\.tablePhoto, app.prefs.tablePhoto)
        .environment(\.largeCardIndex, app.prefs.largeCards)
        .environment(\.zurSammlung, zurSammlung)
        // B21/F21-002: Marke für „Partie fortsetzen“ im Rahmen. Nicht nur beim Wechsel von „läuft“, sondern bei jedem Zug, beim Erscheinen
        // (die Partie kann schon laufen, wenn die Ansicht entsteht) und beim Verlassen der App (kein Warten auf onDisappear).
        .onChange(of: laeuft) { _, an in if an { NeuMarke.sichern() } }
        .onChange(of: app.session.moves) { _, _ in if laeuft { NeuMarke.sichern() } }
        .onChange(of: szene) { _, neu in if neu != .active, laeuft { NeuMarke.sichernBeimVerlassen() } }
        .onAppear { if laeuft { NeuMarke.sichern() } }
        .onDisappear {
            OffenesSpiel.setze(NeuText.kennung, offen: laeuft)
            if laeuft { NeuMarke.sichernBeimVerlassen() }
            app.session.pauseClock()
        }
        .onAppear { SpielAusrichtung.maske = { OrientationLock.mask }; wahlAnwenden() }
        .onDisappear { SpielAusrichtung.zuruecksetzen() }
    }
}

/// Texte der Varianten für Kopfzeile, Wahl und Ende
enum NeuText {
    static let kennung = "solitaer-neu"
    static func variante(_ m: GameMode) -> String {
        switch m.kind {
        case .klondike: m.option == 3 ? String(localized: "Klondike · 3 Karten") : String(localized: "Klondike · 1 Karte")
        case .spider: m.option == 1 ? String(localized: "Spider · 1 Farbe") : String(localized: "Spider · \(m.option) Farben")
        default: m.kind.title
        }
    }
}

/// B21: Solitär speichert seine Partien selbst (Ordner `solitaer-neu`). Damit der Rahmen „Partie fortsetzen“ anbietet, liegt
/// zusätzlich eine kleine Marke im Rahmen-Stand. Sie wird vom Rahmen beim Ende, Abbrechen und bei einer neuen Partie gelöscht.
struct NeuMarke: Codable {
    var offen = true
    @MainActor static func sichern() { SpielStand.sichern(NeuMarke(), spiel: NeuText.kennung) }
    @MainActor static func sichernBeimVerlassen() { SpielStand.sichernBeimVerlassen(NeuMarke(), spiel: NeuText.kennung, laeuft: true) }
}
