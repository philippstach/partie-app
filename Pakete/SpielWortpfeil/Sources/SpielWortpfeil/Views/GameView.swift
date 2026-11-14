// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

struct GameView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.designArt) private var art
    @Environment(\.geraeteSchema) private var geraet
    /// Gerätefarbschema von außen: `geraet` setzt erst das `aufTisch()` dieser Ansicht (für die Kinder) und ist hier selbst nil.
    @Environment(\.colorScheme) private var geraeteFarbschema
    @State private var toast: String?
    @State private var hatGescrollt = false
    @FocusState private var focused: Bool
    /// Vom Rahmen: fragt „Spiel wirklich beenden?“ (mit „Pausieren“) und führt zurück zum Start
    var abbrechen: () -> Void = {}

    var body: some View {
        GeometryReader { geo in
            let landscape = sizeClass == .regular && geo.size.width > geo.size.height * 1.15
            Group {
                if landscape { landscapeLayout(geo.size) } else { portraitLayout(geo.size) }
            }
        }
        .aufTisch()   // Design-Runde 3: Tinte = Filz, sonst Papier
        .focusable()
        .focused($focused)
        .focusEffectDisabled()
        .onAppear { focused = true }
        .onKeyPress(phases: [.down, .repeat]) { press in handle(press) }
        .onChange(of: store.activeClue) { _, clue in
            // VoiceOver: aktive Frage ansagen
            guard UIAccessibility.isVoiceOverRunning, let clue, let g = store.game else { return }
            let dir = clue.direction == .rechts ? String(localized: "Waagerecht") : String(localized: "Senkrecht")
            UIAccessibility.post(notification: .announcement,
                                 argument: "\(dir): \(clue.text), " + String(localized: "\(g.puzzle.wordCells(clue).count) Buchstaben"))
        }
        .onChange(of: store.status) { _, status in
            if status == .voll_mit_fehlern {
                SpielHaptik.warning()
                UIAccessibility.post(notification: .announcement, argument: String(localized: "Alle Felder sind gefüllt, aber noch nicht alles stimmt."))
            }
        }
    }

    // MARK: Kopf (schlank, nur Symbole)

    @ViewBuilder private var header: some View {
        // Große Tinte-Runde, Punkt 14b: in Tinte die übliche Kopfzeile (Start, Buch, drei Punkte); Pause steckt im Menü
        if art == .tinte { tinteKopf } else { altKopf }
    }

    /// Titel der Kopfzeile in Tinte: Thema, „Rätsel des Tages“ oder die Stufe
    private var kopfTitel: String {
        guard let g = store.game else { return "" }
        if let t = g.puzzle.thema, let theme = store.library.themes.first(where: { $0.id == t }) { return theme.name }
        if g.dailyKey != nil { return String(localized: "Rätsel des Tages") }
        switch g.level { case .leicht: return String(localized: "Leicht"); case .mittel: return String(localized: "Mittel"); case .schwer: return String(localized: "Schwer") }
    }

    private var tinteKopf: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let zeit = store.preferences.showTimer ? Zeitformat.text(store.elapsed(at: ctx.date)) : nil
            // RT-007: Der Hilfen-Zähler (nur wenn > 0) gehört auch in Tinte in die Kopfzeile, wie in Klar und Salon
            let hilfen = (store.game?.hints ?? 0) > 0 ? String(localized: "\(store.game?.hints ?? 0) Hilfen") : nil
            let mitte = ([kopfTitel] + [zeit, hilfen].compactMap { $0 }).joined(separator: " · ")
            SpielKopf(mitte: mitte, mitteKurz: zeit ?? kopfTitel, mitteMinimal: zeit ?? kopfTitel, linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button(LocalizedStringKey(store.isPaused ? "Fortsetzen" : "Pause"), systemImage: store.isPaused ? "play.fill" : "pause.fill") { store.togglePause() }
                    menuInhalt
                }
            }
        }
    }

    private var altKopf: some View {
        HStack(spacing: Design.Abstand.s) {
            RundKnopf(symbol: "house", beschriftung: "Zum Start") { abbrechen() }
            Spacer(minLength: 0)
            if typeSize < .xxLarge {
                if Design.art == .klar { info.padding(.horizontal, 14).padding(.vertical, 8).glasFlaeche(.capsule) }
                else { info.padding(.vertical, 8) }   // Tinte und Salon: Text ohne Fläche (wie die Status-Pille des Designs)
            }
            Spacer(minLength: 0)
            if Design.art != .klar {
                RundKnopfMenue(beschriftung: "Mehr") { menuInhalt }
            } else {
            Menu {
                menuInhalt
            } label: {
                Image(systemName: "ellipsis").font(.body.weight(.semibold)).foregroundStyle(.primary)
                    .frame(width: Theme.rundKnopf, height: Theme.rundKnopf).glasFlaeche(.circle)
            }
            .accessibilityLabel("Mehr")
            }
            RundKnopf(symbol: store.isPaused ? "play.fill" : "pause.fill", beschriftung: store.isPaused ? "Fortsetzen" : "Pause") {
                store.togglePause()
            }
        }
        .frame(minHeight: 44)
    }

    @ViewBuilder private var menuInhalt: some View {
        Group {
            FragNachDenRegelnMenuePunkt()   // KI-3 (Blatt 12): nur mit Apple Intelligence sichtbar
            Group {
                Section("Im Spiel") {
                    Toggle("Fehler sofort zeigen", systemImage: "exclamationmark.circle", isOn: Binding(
                        get: { store.preferences.showErrors }, set: { store.preferences.showErrors = $0 }))
                    Toggle("Richtige Wörter zeigen", systemImage: "sparkles", isOn: Binding(
                        get: { store.preferences.showCorrectWords }, set: { store.preferences.showCorrectWords = $0 }))
                }
                Button("Wort aufdecken", systemImage: "lightbulb.max") {
                    store.revealWord()
                    SpielHaptik.success()
                }
                .disabled(store.isPaused)
                Button("Frage merken", systemImage: "flag") {
                    store.flagActiveClue()
                    toast = String(localized: "Frage gemerkt")
                    Task { try? await Task.sleep(for: .seconds(2)); withAnimation { toast = nil } }
                }
            }
        }
    }

    // MARK: Layouts

    private func portraitLayout(_ size: CGSize) -> some View {
        let width = min(size.width - 16, sizeClass == .regular ? 700 : 560)
        let accessibility = typeSize >= .xxLarge
        // Kopf 44 + Frageleiste 56 + Werkzeuge 44 + Tastatur 144 + Abstände
        let hasSolution = !(store.game?.puzzle.solutionCells.isEmpty ?? true)
        let reserved: CGFloat = 44 + 56 + 58 + 3 * 48 + 5 * 6 + (accessibility ? 40 : 0) + (hasSolution ? 36 : 0) - 8
        let height = max(120, size.height - reserved)
        return VStack(spacing: 6) {
            header.padding(.horizontal, Theme.seitenRand)
            if typeSize >= .xxLarge { info.glasFlaeche(.capsule) }
            gridCard(width: width, height: height)
            SolutionRow().padding(.horizontal, 8)
            Spacer(minLength: 0)
            ClueBar().padding(.horizontal, 8)
            ToolRow(onCheck: showCheckResult).padding(.horizontal, 8)
            KeyboardView().padding(.horizontal, 4)
        }
        .padding(.bottom, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func landscapeLayout(_ size: CGSize) -> some View {
        VStack(spacing: Design.Abstand.s) {
            header
            HStack(alignment: .top, spacing: Design.Abstand.l) {
                gridCard(width: size.width * 0.58, height: size.height - 70)
                VStack(spacing: Design.Abstand.m) {
                    ClueBar()
                    ClueList()
                    ToolRow(onCheck: showCheckResult)
                    KeyboardView()
                }
                .frame(maxWidth: 520)
            }
        }
        .padding(.horizontal, 16)
    }

    /// Schrift des Kopftexts: klar wie bisher, Tinte Serif, Salon Kapitälchen-Label.
    private func infoSchrift(_ fett: Bool) -> Font {
        switch Design.art {
        case .klar: fett ? .subheadline.weight(.semibold) : .subheadline
        case .tinte: Design.Schrift.serif(17, gewicht: fett ? .semibold : .regular, relativ: .headline, hoechstens: 1.2)
        case .salon: Design.Schrift.label
        }
    }
    private var infoLaufweite: CGFloat { Design.art == .salon ? Design.Schrift.labelSperrung : 0 }

    private var info: some View {
        HStack(spacing: 10) {
            if let g = store.game {
                if let t = g.puzzle.thema, let theme = store.library.themes.first(where: { $0.id == t }) {
                    Text(theme.name).font(infoSchrift(true)).tracking(infoLaufweite).textCase(Design.art == .salon ? .uppercase : nil).foregroundStyle(Design.art == .klar ? Color.tinte : Color.schrift)
                } else {
                    Text(g.dailyKey != nil ? LocalizedStringKey("Rätsel des Tages") : levelTitle(g.level)).font(infoSchrift(true)).tracking(infoLaufweite).textCase(Design.art == .salon ? .uppercase : nil).foregroundStyle(Design.art == .klar ? Color.tinte : Color.schrift)
                }
            }
            if store.preferences.showTimer {
                TimelineView(.periodic(from: .now, by: 1)) { ctx in
                    Text(Zeitformat.text(store.elapsed(at: ctx.date)))
                        .font(infoSchrift(false).monospacedDigit()).tracking(infoLaufweite).foregroundStyle(Design.art == .klar ? Color.secondary : Color.schriftZweit)
                }
            }
            // Hilfen sichtbar (nur wenn > 0): kompakt, damit es auch auf schmalen iPhones passt
            if let n = store.game?.hints, n > 0 {
                Label("\(n)", systemImage: "lightbulb")
                    .labelStyle(.titleAndIcon)
                    .font(infoSchrift(false).monospacedDigit()).foregroundStyle(Color.gAkzent)
                    .accessibilityLabel("\(n) Hilfen")
            }
        }
    }

    // MARK: Gitter ohne Innenabstand, nur Akzentrahmen; groß oder zoombar

    private func gridCard(width breite: CGFloat, height hoehe: CGFloat) -> some View {
        // Punkt 9: Tinte bei hellem Gerät legt das Gitter als helles Blatt auf den Filz (Rand 4 pt rundum)
        let blatt = art == .tinte && (geraet ?? geraeteFarbschema) == .light
        let width = breite - (blatt ? 8 : 0), height = hoehe - (blatt ? 8 : 0)
        let p = store.game!.puzzle
        let fit = min((width - 3) / CGFloat(p.breite), (height - 3) / CGFloat(p.hoehe))
        let zoomable = fit < GridMetrics.minCell
        // S2-020: Ist das Gitter durch die Höhe klein, obwohl Breite frei ist, wird es nach Breite gezeichnet (höchstens 52 pt je Feld)
        // und senkrecht scrollbar; so bleiben Zahlen und Hinweise lesbar.
        let breitFit = floor(min((width - 3) / CGFloat(p.breite), 52))
        let scrollend = !zoomable && breitFit > floor(fit) + 4 && breitFit * CGFloat(p.hoehe) + 3 > height
        return ZStack {
            if zoomable {
                ZoomableGrid(width: width, height: height)
            } else if scrollend {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) { gridView(cell: breitFit).frame(maxWidth: .infinity) }
                        .scrollIndicatorsFlash(onAppear: true)   // TestFlight 12.11.: sichtbar machen, dass das Gitter nach unten weitergeht
                        .simultaneousGesture(DragGesture(minimumDistance: 4).onChanged { _ in if !hatGescrollt { hatGescrollt = true } })
                        .overlay(alignment: .bottom) { if !hatGescrollt { scrollHinweis } }
                        .onChange(of: store.game?.cursor) { _, c in if let c { withAnimation(.snappy) { proxy.scrollTo(c) } } }   // aktives Feld bleibt sichtbar
                }
                .frame(width: width, height: height)
            } else {
                gridView(cell: floor(fit))
            }
            if store.isPaused { pauseCover }
        }
        .frame(width: (zoomable || scrollend) ? width : nil, height: (zoomable || scrollend) ? height : nil)
        .clipShape(.rect(cornerRadius: Design.Ecke.feld))
        .raetselBlatt(Design.Ecke.feld, innen: 4)
        .overlay(alignment: .top) { banner }
    }

    /// Verlauf mit Pfeil am unteren Rand, bis man das erste Mal gescrollt hat.
    private var scrollHinweis: some View {
        Image(systemName: "chevron.compact.down").font(.title2.weight(.semibold)).foregroundStyle(Color.tinte)
            .frame(maxWidth: .infinity).padding(.top, 18).padding(.bottom, 2)
            .background(LinearGradient(colors: [.clear, Tisch.aktiv ? Color.clear : Color.seitenGrund.opacity(0.9)], startPoint: .top, endPoint: .bottom))
            .allowsHitTesting(false).accessibilityHidden(true)
    }

    private func gridView(cell: CGFloat) -> some View {
        GridView(data: store.gridData,
                 cell: cell, wave: store.wave) { pos in store.tap(row: pos.r, col: pos.c) }
            .blur(radius: store.isPaused ? 14 : 0)
            .allowsHitTesting(!store.isPaused)
    }

    private var pauseCover: some View {
        VStack(spacing: 14) {
            Image(systemName: "pause.circle.fill").font(.largeTitle).imageScale(.large).foregroundStyle(Color.kwAkzent)
            Text("Pausiert").font(.system(.title2, design: Design.zahlDesign, weight: .bold)).foregroundStyle(Color.tinte)
            Text("Das Gitter ist verdeckt, die Zeit steht.").font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button { store.togglePause() } label: {
                Text("Weiter").font(.title3.weight(.semibold)).frame(minWidth: 160, minHeight: 36)
            }
            .hauptKnopf()
        }
        .padding(24)
        .background(Color.karte, in: .rect(cornerRadius: 24))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder private var banner: some View {
        let text: LocalizedStringKey? = store.status == .voll_mit_fehlern
            ? "Noch nicht ganz richtig" : toast.map { LocalizedStringKey($0) }
        if let text {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14).padding(.vertical, 8)
                .foregroundStyle(Color.white)   // Fund 136/171: im Dunkelmodus war die Einblendung fast durchsichtig; wie im Hellmodus ein dunkles Banner
                .background(Capsule().fill(Color.black.opacity(0.85)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                .padding(.top, 10)
                .transition(.opacity)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    private func showCheckResult(_ wrong: Int) {
        toast = wrong == 0 ? String(localized: "Alles richtig bisher")
            : wrong == 1 ? String(localized: "1 falsches Feld") : String(localized: "\(wrong) falsche Felder")
        UIAccessibility.post(notification: .announcement, argument: toast)
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation { toast = nil }
        }
    }

    // MARK: Hardware-Tastatur

    private func handle(_ press: KeyPress) -> KeyPress.Result {
        guard !store.isPaused else { return .ignored }
        switch press.key {
        case .delete, .deleteForward: store.delete(); return .handled
        case .tab:
            if press.modifiers.contains(.shift) { store.previousClue() } else { store.nextClue() }
            return .handled
        case .rightArrow: store.moveCursor(.rechts, forward: true); return .handled
        case .leftArrow: store.moveCursor(.rechts, forward: false); return .handled
        case .downArrow: store.moveCursor(.unten, forward: true); return .handled
        case .upArrow: store.moveCursor(.unten, forward: false); return .handled
        default:
            guard !press.modifiers.contains(.command), !press.modifiers.contains(.control),
                  !Normalizer.normalize(press.characters).isEmpty else { return .ignored }
            store.type(press.characters)
            Sound.key.play()
            return .handled
        }
    }
}

func levelTitle(_ l: Level) -> LocalizedStringKey {
    switch l {
    case .leicht: "Leicht"
    case .mittel: "Mittel"
    case .schwer: "Schwer"
    }
}

/// Gitter bei kleinen Feldern: schiebbar, mit zwei Fingern zoombar; der Cursor bleibt sichtbar.
struct ZoomableGrid: View {
    @Environment(GameStore.self) private var store
    let width: CGFloat
    let height: CGFloat
    @State private var zoom: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1
    /// T-016: Hinweis „es geht weiter“, bis zum ersten Mal gescrollt wurde (wie im senkrecht scrollenden Gitter).
    @State private var hatGescrollt = false

    var body: some View {
        // F-AWS-K-027: Grundgröße so, dass das Gitter die Breite füllt (statt fest 34 pt); Zoom wirkt darauf.
        let spalten = CGFloat(max(1, store.game?.puzzle.breite ?? 1))
        let basis = max(GridMetrics.minCell, floor(min((width - 4) / spalten, 52)))
        let cell = basis * min(GridMetrics.maxZoom, max(1, zoom * pinch))
        ScrollViewReader { proxy in
            // T-016 (TestFlight B15: „nicht sofort klar, dass man scrollen kann“): Den Hinweis aus 7f713da0 hatte nur das senkrecht
            // scrollende Gitter. Große Gitter (Rätsel des Tages) landen hier im Zoom-Gitter: jetzt mit Laufleisten, die beim Öffnen
            // kurz aufblinken, und demselben Pfeil unten, solange das Gitter höher ist als der Platz und noch nicht gescrollt wurde.
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                GridView(data: store.gridData,
                         cell: cell, wave: store.wave) { pos in store.tap(row: pos.r, col: pos.c) }
                    .padding(2)
            }
            .scrollIndicatorsFlash(onAppear: true)
            .simultaneousGesture(DragGesture(minimumDistance: 4).onChanged { _ in if !hatGescrollt { hatGescrollt = true } })
            .overlay(alignment: .bottom) {
                let reihen = CGFloat(store.game?.puzzle.hoehe ?? 0)
                if !hatGescrollt, reihen * cell + 4 > height {
                    Image(systemName: "chevron.compact.down").font(.title2.weight(.semibold)).foregroundStyle(Color.tinte)
                        .frame(maxWidth: .infinity).padding(.top, 18).padding(.bottom, 2)
                        .background(LinearGradient(colors: [.clear, Tisch.aktiv ? Color.clear : Color.seitenGrund.opacity(0.9)], startPoint: .top, endPoint: .bottom))
                        .allowsHitTesting(false).accessibilityHidden(true)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .simultaneousGesture(
                MagnifyGesture()
                    .updating($pinch) { value, state, _ in state = value.magnification }
                    .onEnded { value in zoom = min(GridMetrics.maxZoom, max(1, zoom * value.magnification)) }
            )
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                // Doppeltipp: Zoom-Stufen 1× → 1,5× → 2×, Cursor in der Mitte
                zoom = zoom < 1.25 ? 1.5 : zoom < 1.75 ? GridMetrics.maxZoom : 1   // Stufen 1× → 1,5× → 2× → 1×
            })
            .blur(radius: store.isPaused ? 14 : 0)
            .allowsHitTesting(!store.isPaused)
            .onChange(of: store.game?.cursor) { _, pos in
                guard let pos else { return }
                withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(pos) }
            }
            .onAppear {
                // zuletzt gewählte Zoomstufe dieser Schwierigkeitsstufe
                if let level = store.game?.level { zoom = CGFloat(store.preferences.zoom(for: level)) }
            }
            .onChange(of: zoom) { _, new in
                if let level = store.game?.level { store.preferences.setZoom(Double(new), for: level) }
                // nach dem Zoomen den Cursor wieder in die Mitte holen
                if let pos = store.game?.cursor { proxy.scrollTo(pos, anchor: .center) }
            }
            .task { if let pos = store.game?.cursor { proxy.scrollTo(pos, anchor: .center) } }
        }
        .frame(width: width, height: height)
    }
}

/// iPad quer: alle Fragen in zwei Abschnitten, die aktive hinterlegt, gelöste durchgestrichen.
struct ClueList: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        if let g = store.game {
            ScrollViewReader { proxy in
                List {
                    section("Waagerecht", "arrow.right", .rechts, g)
                    section("Senkrecht", "arrow.down", .unten, g)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .clipShape(.rect(cornerRadius: Design.Ecke.karte))
                .onChange(of: g.activeClue) { _, c in
                    if let c { withAnimation { proxy.scrollTo(c, anchor: .center) } }
                }
            }
        }
    }

    private func section(_ title: LocalizedStringKey, _ icon: String, _ d: Direction, _ g: Game) -> some View {
        Section {
            ForEach(g.puzzle.sortedClues.filter { $0.direction == d }, id: \.self) { c in
                let done = g.puzzle.wordCells(c).allSatisfy { g.entries[$0] == g.puzzle.solution($0) }
                Button {
                    store.tap(row: c.zeile, col: c.spalte)
                    if store.activeClue != c { store.tap(row: c.zeile, col: c.spalte) }
                } label: {
                    Text(c.text)
                        .font(.subheadline)
                        .strikethrough(done)
                        .foregroundStyle(done ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(minHeight: 36)
                }
                .listRowBackground(g.activeClue == c ? Color.kwAkzent.opacity(0.25) : Color.karte)
                .id(c)
            }
        } header: {
            Label(title, systemImage: icon)
        }
    }
}

/// Name einer Stufe als lokalisierter Text (für Sätze)
func levelName(_ l: Level) -> LocalizedStringResource {
    switch l {
    case .leicht: "Leicht"
    case .mittel: "Mittel"
    case .schwer: "Schwer"
    }
}
#endif
