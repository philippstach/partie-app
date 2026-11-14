// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

/// Würfelfeld mit App-Würfeln: nimmt die ganze Resthöhe. Gesperrte Würfel klein oben links („Gesperrt (300)“),
/// freie Würfel groß in der Mitte (eine oder zwei Reihen, je nachdem was größer wird), darunter die Auswahlzeile.
struct NeuWuerfelFeld: View {
    @Environment(GameStore.self) private var store
    @Environment(TurnInput.self) private var input
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Größte Würfelkante (SE 56, 390 pt breit bis 90, Pro Max bis 112, iPad mehr)
    let hoechstens: CGFloat
    @State private var landing = Array(repeating: 0, count: 6)
    @State private var landingOrder: [Int: Int] = [:]
    @State private var hotDiceBanner = false

    private var wide: Bool { sizeClass == .regular }

    var body: some View {
        let turn = store.turn
        let hint = (store.game?.settings.bestHint ?? false) ? store.bestSelection : []
        VStack(spacing: 6) {
            gesperrt(turn)
            GeometryReader { geo in
                wuerfel(turn, hint: hint, in: geo.size)
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            auswahl(turn, best: hint)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .designFlaeche(16)
        .overlay(alignment: .top) {
            if hotDiceBanner {
                StatusChip(symbol: "flame.fill", text: Text("Alle Würfel punkten – weiter mit allen \(turn.count)!"))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                    .offset(y: -10)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .background { if wide && turn.hasRolled { kuerzel(turn) } }
        .sensoryFeedback(.selection, trigger: turn.selected) { _, _ in store.game != nil && SpieleHaptik.erlaubt }
        .onChange(of: store.rollCount) { diceLanded() }
        .onChange(of: store.hotDiceCount) { showHotDice() }
    }

    // MARK: - Gesperrt

    @ViewBuilder
    private func gesperrt(_ turn: DiceTurn) -> some View {
        let sperren = turn.dice.indices.filter { turn.locked[$0] }
        HStack(spacing: Design.Abstand.xs) {
            if let from = turn.inheritedFrom, let game = store.game, sperren.isEmpty || turn.banked == turn.inheritedPoints {
                Label("+\(Theme.points(turn.inheritedPoints)) von \(game.players[from].name)", systemImage: "arrow.turn.down.right")
                    .font(.caption.weight(.semibold)).foregroundStyle(.spielAkzent)
            }
            if !sperren.isEmpty {
                ForEach(sperren, id: \.self) { i in DieView(value: turn.dice[i], state: .locked, size: 22) }
                Text("Gesperrt (\(Theme.points(turn.banked)))").font(.caption.weight(.semibold)).tischHinweis(zeilen: 1)
                    .padding(.leading, 2)
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: 24)
        .lineLimit(1)
    }

    // MARK: - Würfel

    private func wuerfel(_ turn: DiceTurn, hint: Set<Int>, in size: CGSize) -> some View {
        let frei = turn.dice.indices.filter { !turn.locked[$0] }
        let abstand: CGFloat = wide ? 14 : 10
        let r = NeuLogik.wuerfelRaster(n: frei.count, breite: size.width, hoehe: size.height, abstand: abstand, hoechstens: hoechstens)
        let reihen = stride(from: 0, to: frei.count, by: r.spalten).map { Array(frei[$0..<min($0 + r.spalten, frei.count)]) }
        return VStack(spacing: abstand) {
            ForEach(Array(reihen.enumerated()), id: \.offset) { _, reihe in
                HStack(spacing: abstand) {
                    ForEach(reihe, id: \.self) { i in
                        Button { store.toggleDie(i) } label: {
                            DieView(value: turn.dice[i], state: zustand(i, turn), hinted: hint.contains(i) && !turn.selected[i], size: r.kante)
                                .frame(width: r.kante, height: r.kante)
                                .rotationEffect(.degrees(input.shaking ? 12 : 0))
                                .scaleEffect(input.shaking ? 0.9 : 1)
                                .modifier(NeuLanding(trigger: landing.indices.contains(i) ? landing[i] : 0,
                                                     delay: Double(landingOrder[i] ?? 0) * 0.05, tilt: i % 2 == 0 ? 18 : -14))
                                .accessibilityHidden(true)   // F21-012: Der Knopf trägt Name, Wert und Zustand; die Würfelfigur darin war ein zweites Element
                        }
                        .buttonStyle(.plain)
                        .focusEffectDisabled()
                        .disabled(!turn.hasRolled && !Tisch.aktiv)   // Tinte (Punkt 14c): ein gesperrter Knopf dimmt den Würfel grau; der Tipp ist ohne Wurf ohnehin wirkungslos
                        .allowsHitTesting(turn.hasRolled)
                        .accessibilityElement(children: .ignore)   // F21-012: Würfelfigur („Noch nicht gewürfelt“, „Fragezeichen“) nicht als Kinder im Baum
                        // F21-011: Name „Würfel 2 von 5“, Wert = Augenzahl, Zustand „ausgewählt“ als Merkmal
                        .accessibilityLabel(Text("Würfel \(i + 1) von \(turn.count)"))
                        .accessibilityValue(Text(turn.hasRolled ? String(turn.dice[i]) : String(localized: "noch nicht geworfen")))
                        .accessibilityAddTraits(turn.selected[i] ? .isSelected : [])
                        .accessibilityRemoveTraits(turn.selected[i] ? [] : .isSelected)
                    }
                }
            }
        }
        .animation(.snappy, value: r.spalten)
    }

    private func zustand(_ i: Int, _ turn: DiceTurn) -> DieView.State {
        if !turn.hasRolled { return .unknown }
        return turn.selected[i] ? .selected : .free
    }

    // MARK: - Auswahlzeile

    @ViewBuilder
    private func auswahl(_ turn: DiceTurn, best: Set<Int>) -> some View {
        Group {
            if !turn.hasRolled {
                Text("Tippe auf „Würfeln“.").tischHinweis()
            } else if turn.selectedValues.isEmpty {
                if best.isEmpty {
                    Text("Tippe die Würfel an, die du rauslegen willst.").tischHinweis()
                } else {
                    let pts = Scoring.score(best.map { turn.dice[$0] }, fullThrow: turn.fullThrow, rules: store.scoringRules) ?? 0
                    Label("Tipp: Die markierten Würfel bringen am meisten (\(Theme.points(pts))).", systemImage: "lightbulb").tischHinweis()
                }
            } else if let score = store.selectionScore {
                let allOut = turn.nextRollCount == turn.count
                VStack(spacing: 1) {
                    Text("Ausgewählt: \(turn.selectedValues.sorted().map(String.init).joined(separator: " ")) = \(Theme.points(score)) · Zug \(Theme.points(store.turnTotal))")
                        .fontWeight(.semibold).foregroundStyle(.spielAkzent)
                    if allOut { Text("Alle Würfel punkten – weiter mit allen \(turn.count)! 🔥").font(.caption).foregroundStyle(.spielAkzent) }
                }
            } else {
                Text(store.triples == .all
                     ? String(localized: "Diese Auswahl zählt nicht – nur Einsen, Fünfen, Drillinge oder eine Straße.")
                     : String(localized: "Diese Auswahl zählt nicht – nur Einsen, Fünfen, drei Einsen, drei Fünfen oder eine Straße."))
                    .foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.meldungRot)
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
        .lineLimit(typeSize.isAccessibilitySize ? 4 : 2).minimumScaleFactor(0.8)
        .frame(maxWidth: .infinity, minHeight: 34)
    }

    // MARK: - Gefühl

    private func diceLanded() {
        guard store.game != nil else { return }
        let thrown = store.lastThrown
        if reduceMotion { SpielHaptik.land(intensity: 0.8); return }
        landingOrder = Dictionary(uniqueKeysWithValues: thrown.enumerated().map { ($1, $0) })
        for i in thrown where landing.indices.contains(i) { landing[i] += 1 }
        for k in thrown.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14 + Double(k) * 0.05) {
                SpielHaptik.land(intensity: 0.5 + 0.1 * CGFloat(k % 3))
            }
        }
        if UIAccessibility.isVoiceOverRunning, store.nieteNotice == nil, store.turn.hasRolled {
            let augen = thrown.map { store.turn.dice[$0] }
            let beste = Scoring.bestSelection(augen, fullThrow: store.turn.fullThrow, rules: store.scoringRules).points
            UIAccessibility.post(notification: .announcement, argument: VoiceOverText.wurf(augen, beste: beste))
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

    /// iPad-Tastatur: 1–6 wählt Würfel, Esc leert die Auswahl
    private func kuerzel(_ turn: DiceTurn) -> some View {
        KeyboardShortcutButtons {
            ForEach(turn.dice.indices, id: \.self) { i in
                Button("Würfel \(i + 1)") { store.toggleDie(i) }
                    .keyboardShortcut(KeyEquivalent(Character("\(i + 1)")), modifiers: [])
                    .disabled(turn.locked[i] || input.shaking)
            }
            Button("Auswahl leeren", action: store.clearSelection).keyboardShortcut(.escape, modifiers: [])
        }
    }
}

/// Würfel fällt herein: kurz angehoben und gedreht, dann federt er auf seinen Platz.
private struct NeuLanding: ViewModifier {
    struct Pose { var y: CGFloat = 0; var rotation: Double = 0; var scale: CGFloat = 1 }
    let trigger: Int
    let delay: Double
    let tilt: Double

    func body(content: Content) -> some View {
        let delay = max(delay, 0.001)
        return content.keyframeAnimator(initialValue: Pose(), trigger: trigger) { view, pose in
            view.offset(y: pose.y).rotationEffect(.degrees(pose.rotation)).scaleEffect(pose.scale)
        } keyframes: { _ in
            KeyframeTrack(\.y) {
                LinearKeyframe(-28, duration: 0.001); LinearKeyframe(-28, duration: delay)
                SpringKeyframe(0, duration: 0.42, spring: .init(duration: 0.42, bounce: 0.45))
            }
            KeyframeTrack(\.rotation) {
                LinearKeyframe(tilt, duration: 0.001); LinearKeyframe(tilt, duration: delay)
                SpringKeyframe(0, duration: 0.42, spring: .init(duration: 0.42, bounce: 0.3))
            }
            KeyframeTrack(\.scale) {
                LinearKeyframe(0.82, duration: 0.001); LinearKeyframe(0.82, duration: delay)
                SpringKeyframe(1, duration: 0.42, spring: .init(duration: 0.42, bounce: 0.4))
            }
        }
    }
}
