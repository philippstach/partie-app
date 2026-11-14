// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

/// Würfel-Karte des Zugs: Punkte, Würfel bzw. Augen-Eingabe und Hinweis.
/// Die Knöpfe stehen in der festen Leiste unten (`DiceActionBar`).
struct DigitalDiceView: View {
    @Environment(GameStore.self) private var store
    @Environment(TurnInput.self) private var input
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.tischGross) private var tischGross
    @Environment(\.tischHoehe) private var tischHoehe
    /// Zähler je Würfel: startet seine Lande-Animation, wenn er gerade geworfen wurde
    @State private var landing = Array(repeating: 0, count: 6)
    /// Reihenfolge des Landens (Index im letzten Wurf) für den Versatz
    @State private var landingOrder: [Int: Int] = [:]
    /// „Alle Würfel punkten“ kurz einblenden
    @State private var hotDiceBanner = false

    /// iPad (regular): größere Würfel, Hover-Effekt und Tastatur
    private var wide: Bool { sizeClass == .regular }
    private var dieSpacing: CGFloat { wide ? 14 : 10 }

    /// Höchste Würfelgröße; die tatsächliche Größe rechnet `WuerfelReihe` aus der Breite (Build 10).
    /// iPhone 96 pt, iPad 128 pt, Spieltisch bis 200 pt – dort auch durch die freie Höhe begrenzt
    /// (Rest der Karte: Hinweis, Auswahl leeren, Abstände, ca. 200 pt).
    private var hoechsteWuerfel: CGFloat {
        guard tischGross else { return wide ? 128 : 96 }
        let hoehe = tischHoehe > 0 ? tischHoehe - 200 : 200
        return max(44, min(200, hoehe))
    }

    private var manual: Bool { input.manual(store) }
    private var showEntry: Bool { input.showEntry(store) }
    private var pending: [Int] { input.pending }
    private var shaking: Bool { input.shaking }

    var body: some View {
        let turn = store.turn
        let hint = (store.game?.settings.bestHint ?? false) ? store.bestSelection : []
        VStack(spacing: 10) {
            if let from = turn.inheritedFrom, let game = store.game {
                Label("+\(Theme.points(turn.inheritedPoints)) von \(game.players[from].name) übernommen", systemImage: "arrow.turn.down.right")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.tint)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.accentColor.opacity(0.1), in: .rect(cornerRadius: 10))
            }

            // Spieltisch: Die Zugpunkte stehen groß in der Kopfzeile „Am Zug“
            if !tischGross {
                let total = manual ? turn.banked + (input.pendingScore(store) ?? 0) : store.turnTotal
                Text(Theme.points(total))
                    .font(.system(.largeTitle, design: Design.zahlDesign).weight(.heavy))
                    .foregroundStyle(.tint)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: total)
                SectionLabel("Punkte dieses Zugs")
            }
            if manual {
                // Wurf-Nummer, offene Würfel, gesicherte Punkte – immer sichtbar
                if input.ansage.hoert {
                    Label("Ich höre zu. Sag die Würfel, die du rauslegst.", systemImage: "waveform")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .symbolEffect(.variableColor.iterative, isActive: true)
                } else {
                    Text("Wurf \(turn.keptThrows + 1) · \(turn.openCount) Würfel offen · gesichert \(Theme.points(turn.banked))")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    if let hinweis = input.ansage.hinweis {
                        Text(hinweis).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }
            }

            Group {
                if showEntry {
                    entryRow(turn)
                } else {
                    diceRow(turn, hint: hint)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .sensoryFeedback(.selection, trigger: turn.selected) { _, _ in store.game != nil && SpieleHaptik.erlaubt }

            if !showEntry, turn.hasRolled && turn.selected.contains(true) && !manual {
                Button(action: store.clearSelection) {
                    Label("Auswahl leeren", systemImage: "xmark.circle")
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
                .font(.footnote)
                .buttonStyle(.borderless)
            }

            hintText(for: turn, best: hint)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .frame(minHeight: 36)

        }
        // Spieltisch (Build 10): Karte umschließt den Inhalt mit großzügigem Innenabstand (seitlich ≥ 24 pt)
        // und steht senkrecht mittig im freien Bereich (GameView)
        .padding(.horizontal, tischGross ? 12 : 0)
        .padding(.vertical, tischGross ? 16 : 0)
        .card()
        .overlay(alignment: .top) {
            if hotDiceBanner {
                StatusChip(symbol: "flame.fill", text: Text("Alle Würfel punkten – weiter mit allen \(turn.count)!"))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                    .offset(y: -12)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .background {
            if wide && turn.hasRolled && !showEntry {
                dieShortcuts(turn)
            }
        }
        .onChange(of: store.rollCount) {
            diceLanded()
            // VoiceOver: Ergebnis des Wurfs ansagen (Build 11); Niete sagt die Einblendung an
            if UIAccessibility.isVoiceOverRunning, !manual, store.nieteNotice == nil, store.turn.hasRolled {
                let augen = store.lastThrown.map { store.turn.dice[$0] }
                let beste = Scoring.bestSelection(augen, fullThrow: store.turn.fullThrow, rules: store.scoringRules).points
                UIAccessibility.post(notification: .announcement, argument: VoiceOverText.wurf(augen, beste: beste))
            }
        }
        .onChange(of: store.hotDiceCount) { showHotDice() }
    }

    // MARK: - Würfel-Gefühl

    /// Frisch geworfene Würfel fallen versetzt herein, jeder mit einem weichen Stoß.
    private func diceLanded() {
        guard !manual, store.game != nil else { return }
        let thrown = store.lastThrown
        if reduceMotion {
            SpielHaptik.land(intensity: 0.8)
            return
        }
        landingOrder = Dictionary(uniqueKeysWithValues: thrown.enumerated().map { ($1, $0) })
        for i in thrown where landing.indices.contains(i) { landing[i] += 1 }
        for k in thrown.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14 + Double(k) * 0.05) {
                SpielHaptik.land(intensity: 0.5 + 0.1 * CGFloat(k % 3))
            }
        }
    }

    private func showHotDice() {
        withAnimation(.spring(duration: 0.35, bounce: 0.4)) { hotDiceBanner = true }
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Alle Würfel punkten, weiter mit allen \(store.turn.count)"))
        Task {
            try? await Task.sleep(for: .seconds(1.8))
            withAnimation(.easeIn(duration: 0.25)) { hotDiceBanner = false }
        }
    }

    /// iPad-Tastatur: 1–5 Würfel an/aus, Esc Auswahl leeren
    private func dieShortcuts(_ turn: DiceTurn) -> some View {
        KeyboardShortcutButtons {
            ForEach(turn.dice.indices, id: \.self) { i in
                Button("Würfel \(i + 1)") { store.toggleDie(i) }
                    .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
                    .disabled(turn.locked[i] || shaking)
            }
            Button("Auswahl leeren", action: store.clearSelection)
                .keyboardShortcut(.escape, modifiers: [])
        }
    }

    // MARK: - Würfelreihen

    private func diceRow(_ turn: DiceTurn, hint: Set<Int>) -> some View {
        WuerfelReihe(abstand: dieSpacing, hoechstens: hoechsteWuerfel) {
            ForEach(turn.dice.indices, id: \.self) { i in
                Button {
                    store.toggleDie(i)
                } label: {
                    WuerfelFeld { k in
                    DieView(value: turn.dice[i], state: state(of: i, in: turn), hinted: hint.contains(i) && !turn.selected[i], size: k)
                        .rotationEffect(.degrees(shaking && !turn.locked[i] ? 12 : 0))
                        .scaleEffect(shaking && !turn.locked[i] ? 0.9 : 1)
                        .modifier(LandingEffect(trigger: landing.indices.contains(i) ? landing[i] : 0,
                                                delay: Double(landingOrder[i] ?? 0) * 0.05,
                                                tilt: i % 2 == 0 ? 18 : -14))
                    }
                    .accessibilityHidden(true)   // F21-012: Der Knopf trägt Name, Wert und Zustand
                }
                .buttonStyle(.plain)
                // 1.1 (9), iPad quer: Würfel 1 blieb nach dem Drehen unsichtbar. Vermutlich hat der
                // Lift-Effekt (eigene Ebene, Original ausgeblendet) beim Drehen bzw. bei Tastaturfokus
                // auf dem ersten Knopf hängen. Deshalb nur Hervorhebung und kein Fokus-Effekt (vorläufig);
                // die Tasten 1–5/6 wählen weiter aus.
                .hoverEffect(.highlight, isEnabled: wide)
                .focusEffectDisabled()
                .disabled(!turn.hasRolled || turn.locked[i])
                // F21-011: Name, Wert (Augenzahl) und Zustand „ausgewählt“ für VoiceOver
                .accessibilityLabel(Text("Würfel \(i + 1) von \(turn.count)"))
                .accessibilityValue(Text(turn.hasRolled ? String(turn.dice[i]) : String(localized: "noch nicht geworfen")))
                .accessibilityAddTraits(turn.selected[i] ? .isSelected : [])
                .accessibilityRemoveTraits(turn.selected[i] ? [] : .isSelected)
            }
        }
    }

    /// Während der Augen-Eingabe: rausgelegte Würfel bleiben stehen, die freien Plätze
    /// füllen sich mit jedem Tap. Ein eingetippter Würfel lässt sich antippen und entfernen.
    private func entryRow(_ turn: DiceTurn) -> some View {
        let kept = turn.dice.indices.map { turn.locked[$0] || (turn.hasRolled && turn.selected[$0]) }
        let free = turn.dice.indices.filter { !kept[$0] }
        return WuerfelReihe(abstand: dieSpacing, hoechstens: hoechsteWuerfel) {
            ForEach(turn.dice.indices, id: \.self) { i in
                if kept[i] {
                    WuerfelFeld { k in DieView(value: turn.dice[i], state: .locked, size: k) }
                } else if let p = free.firstIndex(of: i), p < pending.count {
                    Button {
                        withAnimation(.snappy) { _ = input.pending.remove(at: p) }
                    } label: {
                        WuerfelFeld { k in DieView(value: pending[p], state: .free, size: k) }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Entfernt diesen Würfel")
                    .transition(.scale.combined(with: .opacity))
                } else {
                    let next = free.firstIndex(of: i) == pending.count
                    WuerfelFeld { k in
                        RoundedRectangle(cornerRadius: k * 0.22)
                            .strokeBorder(style: StrokeStyle(lineWidth: next ? 2.5 : 1.5, dash: [5, 4]))
                            .foregroundStyle(next ? Color.accentColor : .secondary.opacity(0.4))
                            .frame(width: k, height: k)
                    }
                    .accessibilityLabel(next ? String(localized: "Nächster Würfel") : String(localized: "Offener Würfel"))
                }
            }
        }
    }

    private func state(of i: Int, in turn: DiceTurn) -> DieView.State {
        if !turn.hasRolled { return turn.locked[i] ? .locked : .unknown }
        if turn.locked[i] { return .locked }
        return turn.selected[i] ? .selected : .free
    }

    @ViewBuilder
    private func hintText(for turn: DiceTurn, best: Set<Int>) -> some View {
        if showEntry {
            let open = turn.openCount
            if pending.isEmpty {
                Text(open == 1 ? String(localized: "Wirf den offenen Würfel und tippe die an, die du rauslegst.") : String(localized: "Wirf die \(open) offenen Würfel und tippe die an, die du rauslegst."))
                    .foregroundStyle(.secondary)
            } else if let score = input.pendingScore(store) {
                Text(String(localized: "+\(Theme.points(score)) Punkte") + (pending.count == open ? String(localized: " – alle raus, du darfst mit allen \(turn.count) weiter! 🔥") : ""))
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
            } else {
                Text(store.triples == .all
                     ? String(localized: "Zählt nicht – nur Einsen, Fünfen, Drillinge oder eine Straße (alle Würfel in einem Wurf).")
                     : String(localized: "Zählt nicht – nur Einsen, Fünfen, drei Einsen, drei Fünfen oder eine Straße (alle Würfel in einem Wurf)."))
                    .foregroundStyle(.red)
            }
        } else if !turn.hasRolled {
            Text(manual ? String(localized: "Tippe auf „Wurf eingeben“.") : String(localized: "Tippe auf „Würfeln“.")).foregroundStyle(.secondary)
        } else if turn.selectedValues.isEmpty {
            if best.isEmpty {
                Text("Tippe die Würfel an, die du rauslegen willst.").foregroundStyle(.secondary)
            } else {
                let points = Scoring.score(best.map { turn.dice[$0] }, fullThrow: turn.fullThrow, rules: store.scoringRules) ?? 0
                Label("Tipp: Die markierten Würfel bringen am meisten (\(Theme.points(points))).", systemImage: "lightbulb")
                    .foregroundStyle(.secondary)
            }
        } else if let score = store.selectionScore {
            let allOut = turn.nextRollCount == turn.count
            Text(String(localized: "+\(Theme.points(score)) Punkte") + (allOut ? String(localized: " – alle Würfel punkten, du darfst mit allen \(turn.count) weiter! 🔥") : ""))
                .foregroundStyle(.tint)
                .fontWeight(.semibold)
        } else {
            Text(store.triples == .all
                 ? String(localized: "Diese Auswahl zählt nicht – nur Einsen, Fünfen, Drillinge oder eine Straße (alle Würfel in einem Wurf).")
                 : String(localized: "Diese Auswahl zählt nicht – nur Einsen, Fünfen, drei Einsen, drei Fünfen oder eine Straße (alle Würfel in einem Wurf)."))
                .foregroundStyle(.red)
        }
    }
}

/// Feste Aktionsleiste unten: Würfeln/Weiter, Aufhören, Niete – bzw. die Augen-Tasten.
struct DiceActionBar: View {
    @Environment(GameStore.self) private var store
    @Environment(TurnInput.self) private var input
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.tischGross) private var tischGross
    /// iPad (regular): größere Augen-Tasten und Tastatur
    private var wide: Bool { sizeClass == .regular }

    private var manual: Bool { input.manual(store) }
    private var shaking: Bool { input.shaking }
    private var cooldown: Bool { input.cooldown }

    /// Höchste Größe der Augen-Tasten; 6 nebeneinander, die Größe rechnet `WuerfelReihe` aus der Breite
    private var keyHoechstens: CGFloat { tischGross ? 96 : (wide ? 80 : 64) }

    var body: some View {
        @Bindable var input = input
        let turn = store.turn
        Group {
            if input.showEntry(store) {
                keptEntry
                    .task {
                        // Die ersten drei Male erklärt ein Satz den langen Druck (Blatt 15b).
                        zeigeArtHinweis = artHinweisZaehler < 3
                        if verfuegbareArten.count > 1, geltendeArt == .ansage { artHinweisZaehler += 1 }
                    }
                    .task(id: "\(store.game?.current ?? 0)|\(store.turn.keptThrows)|\(store.game?.log.count ?? 0)") {
                        await gemerkteArtOeffnen(open: store.turn.openCount)
                    }
                    .fullScreenCover(isPresented: $input.kameraOffen) { haken(WuerfelEingabeHaken.kamera, open: store.turn.openCount) }
                    .fullScreenCover(isPresented: $input.scannerOffen) { haken(WuerfelEingabeHaken.scanner, open: store.turn.openCount) }
            } else {
                // F21-009: Knöpfe bei jeder Änderung von Würfeln, Auswahl und Zug neu aufbauen („Weiter (N)“ blieb mit alter Zahl stehen)
                buttons(turn).id(store.botSchluessel)
            }
        }
    }

    private func roll() { input.roll(store) }

    private var deleteButton: some View {
        Button(action: input.removeLastPip) {
            rundLabel("delete.left")
        }
        .buttonStyle(.plain)
        .disabled(input.pending.isEmpty)
        .opacity(input.pending.isEmpty ? 0.4 : 1)
        .accessibilityLabel("Letzten Würfel löschen")
    }

    // MARK: - Eingabeart: ein runder Knopf für Ansagen, Kamera und Scanner (Blatt 15b)

    /// Runder Knopf (52,5 pt) mit Zeichen; `gefuellt` beim Zuhören, `pfeil` = kleine Marke „hier gibt es mehr“.
    private func rundLabel(_ symbol: String, gefuellt: Bool = false, pfeil: Bool = false) -> some View {
        let tinte = Tisch.aktiv
        let linie: Color = tinte ? Tisch.elfenbein : Color.accentColor
        return Image(systemName: symbol)
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(gefuellt ? (tinte ? Tisch.dunkel : Color.onAccent) : linie)
            .frame(width: 52.5, height: 52.5)
            .background(Circle().fill(gefuellt ? linie : Color.clear))
            .overlay(Circle().strokeBorder(linie.opacity(0.9), lineWidth: 1.5))
            .overlay(alignment: .topTrailing) {
                if pfeil {
                    Image(systemName: "chevron.up").font(.system(size: 10, weight: .bold))
                        .foregroundStyle(tinte ? Tisch.dunkel : Color.onAccent)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(linie))
                        .offset(x: 2, y: -8)
                }
            }
            .contentShape(Circle())
    }

    /// Die Eingabearten, die es auf diesem Gerät gibt (Reihenfolge wie im Menü). Fehlt eine, fehlt sie im Menü.
    private var verfuegbareArten: [WuerfelEingabeArt] {
        WuerfelEingabeArt.allCases.filter { art in
            switch art {
            case .kamera: WuerfelEingabeHaken.kamera != nil
            case .scanner: WuerfelEingabeHaken.scanner != nil
            case .ansage: input.ansage.angeboten
            }
        }
    }

    /// Zuletzt genutzt (gemerkt), sonst Ansagen, sonst die erste vorhandene.
    private var geltendeArt: WuerfelEingabeArt? {
        let arten = verfuegbareArten
        if let g = WuerfelEingabeArt.gemerkt(), arten.contains(g) { return g }
        return arten.contains(.ansage) ? .ansage : arten.first
    }

    private static func symbol(_ art: WuerfelEingabeArt) -> String {
        switch art {
        case .kamera: "camera"
        case .scanner: "iphone.radiowaves.left.and.right"
        case .ansage: "mic"
        }
    }

    private static func wort(_ art: WuerfelEingabeArt) -> LocalizedStringKey {
        switch art {
        case .kamera: "Kamera"
        case .scanner: "Scanner"
        case .ansage: "Ansagen"
        }
    }

    /// Kurzer Tipp: die geltende Art starten (beim Zuhören: „Fertig“). Langer Druck: Menü mit allen Arten. Gibt es nur eine Art, ist es ein einfacher Knopf ohne Marke.
    @ViewBuilder private func eingabeKnopf(open: Int) -> some View {
        if let art = geltendeArt {
            let arten = verfuegbareArten
            let hoert = input.ansage.hoert
            let symbol = hoert ? "stop.fill" : Self.symbol(art)
            if arten.count > 1 {
                Menu {
                    Picker("Eingabe", selection: Binding(get: { art }, set: { waehle($0, open: open) })) {
                        ForEach(arten, id: \.self) { a in Label(Self.wort(a), systemImage: Self.symbol(a)).tag(a) }
                    }
                    .pickerStyle(.inline)
                } label: {
                    rundLabel(symbol, gefuellt: hoert, pfeil: true)
                } primaryAction: {
                    starte(art, open: open)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(Self.wort(art)))
                .accessibilityHint("Lange drücken für Kamera, Scanner oder Ansagen")
            } else {
                Button { starte(art, open: open) } label: { rundLabel(symbol, gefuellt: hoert) }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(Self.wort(art)))
            }
        }
    }

    /// Startet die Eingabeart und merkt sie sich für den nächsten Wurf. Beim Zuhören beendet der Tipp die Ansage.
    private func starte(_ art: WuerfelEingabeArt, open: Int) {
        if art == .ansage, input.ansage.hoert { input.ansage.stoppen(); return }
        WuerfelEingabeArt.merke(art)
        ausfuehren(art, open: open)
    }

    private func waehle(_ art: WuerfelEingabeArt, open: Int) { starte(art, open: open) }

    private func ausfuehren(_ art: WuerfelEingabeArt, open: Int) {
        switch art {
        case .ansage: input.ansage.starten(plaetze: input.pendingBindung(offen: open))
        case .kamera: input.kameraOffen = true
        case .scanner: input.scannerOffen = true
        }
    }

    /// Beim nächsten Wurf gleich mit der gemerkten Eingabeart beginnen (kurz warten, bis die Leiste steht). Fehlt sie auf dem Gerät, startet nichts.
    private func gemerkteArtOeffnen(open: Int) async {
        guard let art = WuerfelEingabeArt.gemerkt(), verfuegbareArten.contains(art) else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled, input.pending.isEmpty, open > 0, !input.ansage.hoert else { return }
        ausfuehren(art, open: open)
    }

    /// Kamera oder Scanner: die gelesenen Augen werden die rausgelegten Würfel (höchstens so viele wie offen); eingetragen wird erst mit „Weiterwürfeln“ oder „Aufhören“.
    @ViewBuilder private func haken(_ bauer: WuerfelEingabeHaken.Bauer?, open: Int) -> some View {
        if let bauer {
            bauer(open, { augen in
                input.kameraOffen = false; input.scannerOffen = false
                let gueltig = augen.filter { (1...6).contains($0) }.prefix(open)
                guard !gueltig.isEmpty else { return }
                input.hilfeGenutzt = true
                withAnimation(.snappy) { input.pending = Array(gueltig) }
            }, { input.kameraOffen = false; input.scannerOffen = false })
        }
    }

    private func bankButton(score: Int?, banked: Int) -> some View {
        Button {
            input.layOut(store, bank: true)
        } label: {
            Text(score.map { String(localized: "Aufhören +\(Theme.points(banked + $0))") } ?? String(localized: "Aufhören"))
                .lineLimit(1).minimumScaleFactor(0.7)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
        }
        .zweitKnopf()
        .disabled(score == nil || cooldown)
        .keyboardShortcut(wide ? KeyboardShortcut(.return, modifiers: []) : nil)
        .accessibilityHint("Die eingetippten Würfel rauslegen und die Punkte gutschreiben")
    }

    private var nieteButton: some View {
        Button(role: .destructive) {
            input.niete(store)
        } label: {
            // Blatt 15b: ohne Zeichen davor und mit fester Mindestbreite, damit das Wort nie an den Rand stößt
            Text("Niete")
                .lineLimit(1).minimumScaleFactor(0.7)
                .minimumScaleFactor(0.8)
                .frame(minWidth: typeSize.isAccessibilitySize ? 0 : 82, maxWidth: typeSize.isAccessibilitySize ? .infinity : nil)
        }
        .zweitKnopf()
        .tint(.red)
        .disabled(cooldown)
        .accessibilityHint("Zug ohne Punkte beenden, dann ist die nächste Person dran")
    }

    /// iPad-Tastatur: 1–6 Augen, ⌫ löschen (Leertaste = weiter, ⏎ = aufhören an den Knöpfen)
    private func keptShortcuts(open: Int) -> some View {
        KeyboardShortcutButtons {
            ForEach(1...6, id: \.self) { v in
                Button("\(v)") { input.addPip(v, store: store) }
                    .keyboardShortcut(KeyEquivalent(Character("\(v)")), modifiers: [])
                    .disabled(input.pending.count >= open)
            }
            Button("Löschen", action: input.removeLastPip)
                .keyboardShortcut(.delete, modifiers: [])
                .disabled(input.pending.isEmpty)
        }
    }

    // MARK: - Echte Würfel: rausgelegte Würfel eintippen

    /// Wie oft der Satz zum langen Druck schon gezeigt wurde (er erscheint die ersten drei Male).
    @AppStorage("partie.zehntausend.artHinweis") private var artHinweisZaehler = 0
    @State private var zeigeArtHinweis = false

    /// Augen-Tasten, dann „Weiterwürfeln (N)“, darunter ⌫, Eingabe-Knopf, „Aufhören +X“ und „Niete“.
    private var keptEntry: some View {
        let turn = store.turn
        let open = turn.openCount
        let score = input.pendingScore(store)
        let rest = open - input.pending.count
        return VStack(spacing: 10) {
            // Blatt 15b: die ersten drei Male ein Satz, der den langen Druck erklärt (nur wenn es ein Menü gibt und Ansagen gilt)
            if zeigeArtHinweis, verfuegbareArten.count > 1, geltendeArt == .ansage {
                Text("Lange auf das Mikrofon drücken: Kamera oder Scanner")
                    .font(.system(size: 13)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein.opacity(0.72) : Color.secondary)
                    .multilineTextAlignment(.center)
            }
            WuerfelReihe(abstand: 8, hoechstens: keyHoechstens) {
                ForEach(1...6, id: \.self) { v in
                    Button {
                        input.addPip(v, store: store)
                    } label: {
                        WuerfelFeld { k in DieView(value: v, state: .free, size: k) }
                            .contentShape(.rect)
                    }
                    .buttonStyle(PipKeyStyle())
                    .disabled(input.pending.count >= open)
                    .accessibilityLabel("\(v) rauslegen")
                }
            }
            .sensoryFeedback(.increase, trigger: input.pending.count) { _, _ in store.game != nil && SpieleHaptik.erlaubt }
            .background {
                if wide { keptShortcuts(open: open) }
            }

            Button {
                input.layOut(store, bank: false)
            } label: {
                ViewThatFits(in: .horizontal) {
                    Label(rest == 0 ? String(localized: "Mit allen \(turn.count) weiter") : String(localized: "Weiterwürfeln (\(rest))"), systemImage: "dice").lineLimit(1).minimumScaleFactor(0.7)
                    Text(rest == 0 ? String(localized: "Alle \(turn.count) weiter") : String(localized: "Weiter (\(rest))")).lineLimit(1).minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
            }
            .hauptKnopf()
            .controlSize(tischGross ? .extraLarge : .large)
            .disabled(score == nil)
            .keyboardShortcut(wide ? KeyboardShortcut(.space, modifiers: []) : nil)
            .accessibilityHint("Die eingetippten Würfel rauslegen und mit den übrigen weiterwürfeln")

            // Normale Schrift: eine Zeile, „Aufhören“ bekommt den meisten Platz.
            // Große Schrift: „Aufhören“ allein, darunter ⌫ und „Niete“.
            Group {
            if typeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    bankButton(score: score, banked: turn.banked)
                    HStack(spacing: 10) {
                        deleteButton
                        eingabeKnopf(open: open)
                        nieteButton.frame(maxWidth: .infinity)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    deleteButton
                    eingabeKnopf(open: open)
                    bankButton(score: score, banked: turn.banked)
                    nieteButton.fixedSize()
                }
            }
            }
            .controlSize(tischGross ? .extraLarge : .large)
        }
    }

    // MARK: - Knöpfe

    @ViewBuilder
    private func buttons(_ turn: DiceTurn) -> some View {
        do {
            VStack(spacing: 10) {
                AdaptiveStack {
                    Button(action: roll) {
                        Label(rollTitle(turn), systemImage: "dice")
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                    }
                    .hauptKnopf()
                    .disabled(!store.canRoll || shaking)
                    .keyboardShortcut(wide ? KeyboardShortcut(.space, modifiers: []) : nil)

                    if turn.hasRolled {
                        Button(action: store.endTurn) {
                            Text(store.canEndTurn ? String(localized: "Aufhören +\(Theme.points(store.turnTotal))") : String(localized: "Aufhören"))
                                .lineLimit(1).minimumScaleFactor(0.7)
                                .minimumScaleFactor(0.75)
                                .frame(maxWidth: .infinity)
                        }
                        .zweitKnopf()
                        .disabled(!store.canEndTurn || shaking)
                        .keyboardShortcut(wide ? KeyboardShortcut(.return, modifiers: []) : nil)
                        .accessibilityHint("Schreibt die Punkte dieses Zugs gut")
                    }
                }
                .controlSize(tischGross ? .extraLarge : .large)
            }
        }
    }

    private func rollTitle(_ turn: DiceTurn) -> String {
        guard turn.hasRolled else { return manual ? String(localized: "Wurf eingeben") : String(localized: "Würfeln") }
        let n = turn.nextRollCount
        let allOut = store.selectionScore != nil && n == turn.count
        if manual { return allOut ? String(localized: "Mit allen \(n) weiterwürfeln") : (n == 1 ? String(localized: "Weiterwürfeln mit \(n) Würfel") : String(localized: "Weiterwürfeln mit \(n) Würfeln")) }
        return allOut ? String(localized: "Alle \(n) nochmal") : String(localized: "Weiter (\(n))")
    }

}

/// Ein Würfel fällt herein: kurz angehoben und gedreht, dann federt er auf seinen Platz.
private struct LandingEffect: ViewModifier {
    struct Pose {
        var y: CGFloat = 0
        var rotation: Double = 0
        var scale: CGFloat = 1
    }

    let trigger: Int
    let delay: Double
    let tilt: Double

    func body(content: Content) -> some View {
        // Dauer 0 (erster Würfel, Verzögerung 0) ließ den Würfel nach dem Wurf unsichtbar: nie unter 1 ms
        let delay = max(delay, 0.001)
        return content.keyframeAnimator(initialValue: Pose(), trigger: trigger) { view, pose in
            view
                .offset(y: pose.y)
                .rotationEffect(.degrees(pose.rotation))
                .scaleEffect(pose.scale)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                LinearKeyframe(-28, duration: 0.001)
                LinearKeyframe(-28, duration: delay)
                SpringKeyframe(0, duration: 0.42, spring: .init(duration: 0.42, bounce: 0.45))
            }
            KeyframeTrack(\.rotation) {
                LinearKeyframe(tilt, duration: 0.001)
                LinearKeyframe(tilt, duration: delay)
                SpringKeyframe(0, duration: 0.42, spring: .init(duration: 0.42, bounce: 0.3))
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(0.82, duration: 0.001)
                LinearKeyframe(0.82, duration: delay)
                SpringKeyframe(1, duration: 0.42, spring: .init(duration: 0.42, bounce: 0.4))
            }
        }
    }
}

/// Augen-Taste: gibt beim Drücken sichtbar nach.
private struct PipKeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.snappy(duration: 0.12), value: configuration.isPressed)
    }
}
