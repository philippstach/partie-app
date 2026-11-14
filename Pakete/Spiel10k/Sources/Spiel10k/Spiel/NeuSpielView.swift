// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielbildschirm von „10k“: kein Scrollen, das Würfelfeld nimmt die Resthöhe.
/// iPhone von oben: Kopf · Spielerleiste mit Zählwerk · Zug-Karte · Würfelfeld (mit „Frühere Runden“) · Knöpfe.
/// iPad: quer Tafel links und Tisch rechts, hoch Tafel als Raster oben (wie bisher), der Tisch mit dem neuen Würfelfeld.
struct NeuSpielView: View {
    @Environment(GameStore.self) private var store
    @Environment(AppPreferences.self) private var preferences
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    let abbrechen: () -> Void
    @State private var input = TurnInput()
    @State private var stufe = ComputerStufe.gespeichert(NeuAblage.id)
    @State private var size: CGSize = .zero
    @State private var showRules = false
    @State private var showHistory = false
    @State private var showTafel = false
    @State private var showRegeln = false
    @State private var detailPlayer: PlayerRef?
    @State private var regelnEntwurf = GameRules()

    private var wide: Bool { sizeClass == .regular }

    private var layout: TischLayout {
        guard size.width > 0 else { return sizeClass == .regular ? .breitHoch : .kompakt }
        return TischLayout.layout(breite: size.width, hoehe: size.height, sizeClass: sizeClass, grosseSchrift: typeSize.isAccessibilitySize)
    }

    var body: some View {
        if let game = store.game {
            ZStack {
                switch layout {
                case .kompakt: kompakt(game)
                case .breitQuer: tischQuer(game)
                case .breitHoch: tischHoch(game)
                }
            }
            .environment(\.tischGross, layout.breit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Der Kopf muss VOR `aufTisch()` stehen: sonst liegt er außerhalb des dunklen Farbschemas des Filzes und „Runde 1“ steht dunkel auf dunklem Filz.
            .safeAreaInset(edge: .top, spacing: 0) { kopf(game) }
            .aufTisch()   // Design-Runde 3: in Tinte Filz bis in die Ecken, sonst Seitengrund wie bisher
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .sheet(isPresented: $showRules) { RulesDetailView(active: game.settings.rules).formBlatt() }
            .sheet(isPresented: $showHistory) { HistorySheet(game: game).formBlatt() }
            .sheet(isPresented: $showTafel) { NeuTafelBlatt().formBlatt() }
            .sheet(isPresented: $showRegeln) {
                NeuRegelnBlatt(rules: $regelnEntwurf) {
                    store.regelnVorStart(regelnEntwurf)
                    NeuAblage.sichern(regeln: regelnEntwurf)
                    showRegeln = false
                }
                .formBlatt(gross: true)
            }
            .sheet(item: $detailPlayer) { ref in
                if let game = store.game, game.players.indices.contains(ref.id) { PlayerDetailSheet(game: game, player: ref.id).formBlatt() }
            }
            .sheet(isPresented: offerPresented) {
                if let offer = store.game?.offer, let game = store.game {
                    OfferSheet(offer: offer, game: game, onAccept: store.acceptOffer, onDecline: store.declineOffer, wide: wide)
                }
            }
            .environment(input)
            .environment(\.showPlayerDetail, store.game?.offer == nil ? { detailPlayer = PlayerRef(id: $0) } : nil)
            .onChange(of: game.current) {
                input.reset()
                if UIAccessibility.isVoiceOverRunning, store.nieteNotice == nil, let g = store.game, !g.finished {
                    let p = g.players[g.current]
                    UIAccessibility.post(notification: .announcement, argument: VoiceOverText.amZug(p.name, punkte: p.score))
                }
            }
            .onChange(of: game.log.count) { input.reset() }
            // Computergegner: ein Schritt nach kurzer Denkpause
            .task(id: store.botSchluessel) {
                guard store.botAmZug else { return }
                await ComputerTempo.warte(.milliseconds(store.game?.turn.hasRolled == true ? 650 : 450))
                guard !Task.isCancelled else { return }
                store.computerSchritt()
            }
            .overlay { if layout == .kompakt { TischEinblendungen(game: game) } }
            .overlay(alignment: .top) {
                if store.nieteNotice == nil, store.tiebreakNotice == nil, let next = store.nextPlayerNotice, game.players.count > 1, game.players.indices.contains(next) {
                    NextPlayerBanner(player: game.players[next])
                        .padding(.top, 52)   // unter den Kopf mit „Runde N“, sonst überdeckt das Banner den Titel
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: next) {
                            try? await Task.sleep(for: .seconds(1.5))
                            if store.nextPlayerNotice == next { store.nextPlayerNotice = nil }
                        }
                }
            }
            .overlay(alignment: .bottom) {
                if store.nieteNotice == nil, let r = store.recordNotice, game.players.indices.contains(r.player) {
                    RecordBanner(player: game.players[r.player], notice: r)
                        .padding(.bottom, 150)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .task(id: r) {
                            try? await Task.sleep(for: .seconds(2.6))
                            if store.recordNotice == r { store.recordNotice = nil }
                        }
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.35), value: store.recordNotice)
            .animation(.easeInOut(duration: 0.2), value: store.nieteNotice)
            .animation(.easeInOut(duration: 0.2), value: store.nextPlayerNotice)
            .animation(.easeInOut(duration: 0.2), value: store.tiebreakNotice)
            .animation(.snappy, value: store.vorErstemZug)
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true; regelnEntwurf = game.settings.rules }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
        }
    }

    // MARK: - Kopf

    private func kopf(_ game: GameState) -> some View {
        SpielKopf(mitte: game.inTiebreak ? String(localized: "Stechen") : String(localized: "Runde \(game.roundNumber)"), linksAktion: abbrechen) {
            RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
                Button("Rückgängig", systemImage: "arrow.uturn.backward", action: store.undo)
                    .disabled(!store.canUndo)
                    .kuerzel(Kuerzel.rueckgaengig)
                Section("Für alle Spiele") {
                    if game.settings.usesDice {
                        Toggle("Punkte-Würfel vorauswählen", systemImage: "checkmark.circle", isOn: einstellung(\.preselect))
                        Toggle("Tipp: beste Auswahl", systemImage: "lightbulb", isOn: einstellung(\.bestHint))
                    }
                }
                if game.settings.diceMode == .real {
                    Section("Eingabe") {
                        Picker("Eingabe", selection: realEntry) {
                            Label("Punkte eintippen", systemImage: "number").tag(RealEntry.points)
                            Label("Würfel eintippen", systemImage: "dice").tag(RealEntry.pips)
                        }
                        .disabled(!store.canSwitchEntry)
                    }
                }
                if game.players.contains(where: { $0.isComputer }) {
                    ComputerStufePicker(spiel: NeuAblage.id, stufe: $stufe)   // C-038 (2): gilt ab der nächsten Partie
                }
                Button("Punktestand und Verlauf", systemImage: "chart.xyaxis.line") { showHistory = true }
                Button("Regeln dieser Partie", systemImage: "book") { showRules = true }
                    .kuerzel(Kuerzel.regeln)
                NeuePartieMenuePunkt()   // G-019
                Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
            }
        }
    }

    // MARK: - Layouts

    /// iPhone und schmale iPad-Fenster: eine Spalte ohne Scrollen
    private func kompakt(_ game: GameState) -> some View {
        let klein = size.height < NeuLogik.hoeheMittel || typeSize.isAccessibilitySize
        let frueher = NeuLogik.fruehereRundenAnzahl(hoehe: size.height, grosseSchrift: typeSize.isAccessibilitySize)
        return VStack(spacing: Design.Abstand.s) {
            NeuSpielerLeiste(game: game) { showTafel = true }.dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // B18 N-016: Namen/Status sonst auf „T…“ gekürzt
            NeuZugKarte(game: game, zugPunkte: zugPunkte(game), kompakt: klein).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            feld(game, hoechstens: NeuLogik.wuerfelHoechstens(hoehe: size.height, grosseSchrift: typeSize.isAccessibilitySize), frueher: frueher)
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .frame(maxWidth: wide ? Theme.wideColumnWidth : 520)
        .frame(maxWidth: .infinity)
        .safeAreaInset(edge: .bottom) { actionBar(game).id(store.botSchluessel) }   // F21-014: Leiste im Inset wurde beim Zugwechsel nicht neu gezeichnet; Kennung aus dem Spielstand erzwingt den Neuaufbau
    }

    /// iPad quer: links die Tafel (ca. 38 %), rechts der Tisch
    private func tischQuer(_ game: GameState) -> some View {
        HStack(alignment: .top, spacing: 20) {
            ScrollView {
                VStack(spacing: Design.Abstand.m) {
                    Scoreboard(game: game)
                    if !game.log.isEmpty { HistoryCard(game: game, limit: 10) }
                }
                .padding(.bottom, 24)
            }
            .frame(width: max(340, size.width * 0.38))
            tischBereich(game)
        }
        .padding(.horizontal)
    }

    /// iPad hoch: oben Zug-Karte und Tafel als Raster, darunter der Tisch
    private func tischHoch(_ game: GameState) -> some View {
        VStack(spacing: Design.Abstand.m) {
            NeuZugKarte(game: game, zugPunkte: zugPunkte(game)).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            ScrollView { Scoreboard(game: game, raster: true) }
                .scrollBounceBehavior(.basedOnSize)
                .frame(maxHeight: max(size.height * 0.35, 200))
                .fixedSize(horizontal: false, vertical: true)
            tischBereich(game, mitKopf: false)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private func tischBereich(_ game: GameState, mitKopf: Bool = true) -> some View {
        VStack(spacing: Design.Abstand.m) {
            if mitKopf { NeuZugKarte(game: game, zugPunkte: zugPunkte(game)).dynamicTypeSize(...DynamicTypeSize.xxxLarge).frame(maxWidth: 1000) }
            feld(game, hoechstens: 150, frueher: 0).frame(maxWidth: 1000)
        }
        .frame(maxWidth: .infinity)
        .safeAreaInset(edge: .bottom) { actionBar(game).id(store.botSchluessel) }   // F21-014: Leiste im Inset wurde beim Zugwechsel nicht neu gezeichnet; Kennung aus dem Spielstand erzwingt den Neuaufbau
        .overlay { TischEinblendungen(game: game) }
    }

    // MARK: - Würfelfeld

    /// Resthöhe: App-Würfel im neuen Feld; echte Würfel mit der bekannten Eingabe (dort darf es scrollen, wenn es nicht passt).
    @ViewBuilder
    private func feld(_ game: GameState, hoechstens: CGFloat, frueher: Int) -> some View {
        VStack(spacing: Design.Abstand.s) {
            if let tb = game.tiebreak, !game.finished { TiebreakCard(game: game, tiebreak: tb) }
            Group {
                if game.settings.diceMode == .digital {
                    NeuWuerfelFeld(hoechstens: hoechstens)
                } else {
                    ScrollView {
                        Group { if game.settings.usesDice { DigitalDiceView() } else { RealInputView() } }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .allowsHitTesting(!store.botAmZug)
            if frueher > 0, game.tiebreak == nil { NeuFruehereRunden(game: game, anzahl: frueher) }
        }
    }

    private func zugPunkte(_ game: GameState) -> Int {
        let t = game.turn
        switch (game.settings.diceMode, game.settings.realEntry) {
        case (.digital, _): return store.turnTotal
        case (.real, .pips): return t.banked + (input.pendingScore(store) ?? 0)
        case (.real, .points): return (t.inheritedFrom == nil ? 0 : t.inheritedPoints) + input.points
        }
    }

    /// K-033: Tinte und Salon: Leiste hinter dem Knopf in der Papierfarbe des Designs statt weißem Streifen.
    @ViewBuilder private var aktionsGrund: some View {
        if !Design.ist(.klar) && !Tisch.aktiv { Color.seitenGrund.ignoresSafeArea(edges: .bottom) }
    }

    @ViewBuilder
    private func actionBar(_ game: GameState) -> some View {
        if !game.finished, store.botAmZug {
            BottomBar {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("\(game.players[game.current].name) überlegt …").font(.headline)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityElement(children: .combine)
            }
            .background { aktionsGrund }
        } else if !game.finished {
            BottomBar {
                if game.settings.usesDice { DiceActionBar() } else { RealActionBar() }
            }
            .background { aktionsGrund }
        }
    }

    // MARK: - Bindungen

    private var realEntry: Binding<RealEntry> {
        Binding(get: { store.game?.settings.realEntry ?? .points }, set: { v in store.updateSettings { $0.realEntry = v } })
    }

    private func einstellung(_ key: ReferenceWritableKeyPath<AppPreferences, Bool>) -> Binding<Bool> {
        Binding(get: { preferences[keyPath: key] }, set: { preferences[keyPath: key] = $0 })
    }

    private var offerPresented: Binding<Bool> {
        Binding(
            get: { store.game?.offer != nil && store.nieteNotice == nil && store.tiebreakNotice == nil
                && store.game?.settings.usesDice == true && !store.botAmZug },
            set: { _ in }
        )
    }
}

/// Blatt mit Punktestand (Tafel) und vollständigem Verlauf – Tipp auf die Spielerleiste.
struct NeuTafelBlatt: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if let game = store.game {
                    VStack(spacing: Design.Abstand.m) {
                        Scoreboard(game: game)
                        if !game.log.isEmpty { HistoryCard(game: game, limit: nil) }
                    }
                    .padding()
                }
            }
            .background(Color.seitenGrund)
            .navigationTitle("Punktestand")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
    }
}
