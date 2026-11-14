// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Zustand des Ziehens mit dem Finger. Eigene Klasse, damit nur die angehobenen Karten bei jedem Fingerpixel neu zeichnen,
/// nicht der ganze Tisch: `place`/`count` ändern sich nur bei Beginn und Ende, `translation`/`tilt` laufend.
@Observable
final class DragModel {
    var place: Pile?
    var count = 0
    /// Erlaubtes Ziel unter dem Finger (für das `selection`-Tick beim Überfahren)
    var hover: Pile?
    var translation: CGSize = .zero
    var tilt = 0.0

    func end() {
        OrientationLock.unlock()
        place = nil
        hover = nil
        count = 0
        translation = .zero
        tilt = 0
    }
}

struct TableView<R: SolitaireRulesMitLayout>: View {
    let store: GameStore<R>
    var showWaterfall = false
    var onWaterfallDone: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var drag = DragModel()
    /// Querformat: Spalte, deren dichter Block für 2 s aufgeklappt ist
    @State private var unfolded: Int?
    @State private var unfoldTask: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            let prefs = store.prefs
            // „Bewegung reduzieren“: kein Austeil-Flug – die Karten liegen sofort an ihrem Platz und blenden ein
            let shown = store.showsPreDeal && !reduceMotion ? R.preDealState(store.state) : store.state
            let layout = R.Layout(state: shown, size: geo.size, prefs: TablePrefs(leftHanded: prefs.leftHanded, largeCards: prefs.largeCards, unfolded: unfolded))
            let lifted = liftedCards(shown)
            let tint: Color = prefs.activeTable.tint
            let stockCards = Set(shown.stockCardIDs)

            ZStack(alignment: .topLeading) {
                slots(layout, shown, tint: tint)
                ForEach(layout.cardIDs) { card in
                    if let p = layout.placements[card] {
                        CardNodeView<R>(store: store, card: card, placement: p, layout: layout, source: layout.sources[card],
                                        pile: layout.pileOf[card],
                                        lifted: lifted.contains(card), inStock: stockCards.contains(card), drag: drag,
                                        selected: layout.pileOf[card].map { $0 == store.selected && layout.sources[card] != nil } ?? false)
                    }
                }
                .animation(.easeOut(duration: 0.25), value: layout.placements.count)
                .id(store.dealSkips)                // Austeilen übersprungen: Karten neu aufbauen, also ohne Flug am Platz
                highlights(layout, shown, targets: dragTargets(shown, layout))
                if let note = store.limitNote {
                    Text("max. \(note.max)")
                        .font(.system(.caption, design: Design.zahlDesign).weight(.bold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .glasFlaeche(Capsule())
                        .position(note.at)
                        .allowsHitTesting(false)
                        .zIndex(1500)
                        .transition(.opacity)
                }
                if let badge = layout.badge {
                    Text(badge.text)
                        .font(.system(.title3, design: Design.zahlDesign).weight(.black))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundStyle(Color.appFarbe)
                        // Ab Kette 5 leuchtet die Zahl
                        .shadow(color: Color.appFarbe.opacity(badge.glow && !reduceMotion ? 0.7 : 0), radius: badge.glow ? 8 : 0)
                        // Pulsiert kurz bei jeder neuen Karte der Kette (bei „Bewegung reduzieren“ nicht)
                        .keyframeAnimator(initialValue: 1.0, trigger: badge.text) { content, scale in
                            content.scaleEffect(reduceMotion ? 1 : scale)
                        } keyframes: { _ in
                            CubicKeyframe(1.3, duration: 0.09)
                            CubicKeyframe(1.0, duration: 0.16)
                        }
                        .position(badge.center)
                        .allowsHitTesting(false)
                        .zIndex(700)
                }
                // Gold-Schimmer über dem Ziel, wenn ein Ass darauf gelegt wird
                ForEach(0..<4, id: \.self) { f in
                    if let n = store.shimmers[f], n > 0, layout.dropPiles.contains(.foundation(f)) {
                        ShimmerFrame(trigger: n, cornerRadius: Theme.cardRadius(layout.cardSize.width), reduceMotion: reduceMotion)
                            .frame(width: layout.targetFrame(.foundation(f)).width, height: layout.targetFrame(.foundation(f)).height)
                            .position(x: layout.targetFrame(.foundation(f)).midX, y: layout.targetFrame(.foundation(f)).midY)
                            .allowsHitTesting(false)
                            .zIndex(850)
                    }
                }
                // Leer geräumte Spalte (Golf): kurzer Gold-Schimmer
                if let ps = store.placeShimmer {
                    let f = layout.targetFrame(ps.pile)
                    ShimmerFrame(trigger: ps.id, cornerRadius: Theme.cardRadius(layout.cardSize.width), reduceMotion: reduceMotion)
                        .frame(width: f.width, height: f.height)
                        .position(x: f.midX, y: f.midY)
                        .id(ps.id)
                        .allowsHitTesting(false)
                        .zIndex(850)
                }
                // Austeilen: Antippen springt zum Ende
                if store.dealing {
                    Color.clear.contentShape(Rectangle())
                        .onTapGesture { store.skipDeal() }
                        .zIndex(2500)
                }
                if let corner = layout.cornerSymbol {
                    Image(systemName: corner.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(tint.opacity(0.6))
                        .position(corner.center)
                        .accessibilityLabel(Text(verbatim: corner.label))
                        .zIndex(650)
                }
                if let toast = store.toast {
                    let at = layout.badge.map { CGPoint(x: $0.center.x, y: $0.center.y - 36) } ?? CGPoint(x: layout.size.width / 2, y: layout.size.height * 0.45)
                    Text(toast.text)
                        .font(.system(.caption, design: Design.zahlDesign).weight(.bold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .glasFlaeche(.capsule)
                        .position(at)
                        .id(toast.id)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                        .zIndex(1700)
                }
                if let popup = store.popup {
                    let frame = layout.targetFrame(popup.pile)
                    FloatingBonus(text: popup.text, reduceMotion: reduceMotion)
                        .id(popup.id)
                        .position(x: frame.midX, y: frame.minY)
                        .allowsHitTesting(false)
                        .zIndex(1600)
                }
                if store.blinkEmptyColumns {
                    ForEach(Array(layout.emptyColumnFrames.enumerated()), id: \.offset) { _, frame in
                        PulseFrame(cornerRadius: Theme.cardRadius(layout.cardSize.width), grow: 1.0)
                            .frame(width: frame.width, height: frame.height)
                            .position(x: frame.midX, y: frame.midY)
                            .allowsHitTesting(false)
                            .zIndex(800)
                    }
                }
                if showWaterfall {
                    WaterfallView(cards: layout.waterfallCards(), cardSize: layout.cardSize, size: layout.size,
                                  fourColor: prefs.fourColor, onFinish: onWaterfallDone)
                        .zIndex(2000).transition(.opacity)
                }
                // Querformat: dichter Block tieferer offener Karten – „+N“, Antippen klappt die Spalte 2 s lang auf
                ForEach(layout.collapsedBlocks, id: \.column) { block in
                    Text("+\(block.count)")
                        .font(.system(.caption2, design: Design.zahlDesign).weight(.bold))
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .glasFlaeche(Capsule())
                        .position(x: block.frame.midX, y: block.frame.minY - 10)       // über dem Block, deckt die erste volle Karte nicht zu
                        .allowsHitTesting(false)
                        .zIndex(900)
                    Color.clear
                        .frame(width: block.frame.width, height: max(block.frame.height + 12, Theme.tapSize))
                        .contentShape(Rectangle())
                        .position(x: block.frame.midX, y: block.frame.minY + max(block.frame.height + 12, Theme.tapSize) / 2 - 8)
                        .onTapGesture { unfold(block.column) }
                        .zIndex(901)
                        .accessibilityElement()
                        .accessibilityLabel(String(localized: "\(block.count) weitere offene Karten, antippen zum Aufklappen"))
                        .accessibilityAddTraits(.isButton)
                }
                // Stapel antippen: ziehen bzw. umdrehen
                if let tap = layout.stockTapFrame {
                    Color.clear
                        .frame(width: tap.width, height: tap.height)
                        .contentShape(Rectangle())
                        .position(x: tap.midX, y: tap.midY)
                        .onTapGesture { store.drawStock() }
                        .zIndex(500)
                        .accessibilityElement()
                        .accessibilityLabel(String(localized: "Stapel, \(shown.stockCount) Karten, ziehen"))
                        .accessibilityAddTraits(.isButton)
                }
            }
            .coordinateSpace(name: "table")
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            // Bricht das System ein Ziehen ab (Anruf, Kontrollzentrum, Hintergrund), kommt kein `onEnded`:
            // dann die angehobenen Karten absetzen und die Drehsperre lösen
            .onChange(of: scenePhase) { _, phase in if phase != .active, drag.place != nil { drag.end() } }
            .onChange(of: geo.size) { _, _ in if drag.place != nil { drag.end() } }       // Drehen oder Fenstergröße ändern bricht das Ziehen ab
            .onDisappear { if drag.place != nil { drag.end() } }
        }
    }

    private func unfold(_ column: Int) {
        unfoldTask?.cancel()
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { unfolded = column }
        unfoldTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { unfolded = nil } }
        }
    }

    // MARK: Ebenen

    private func slots(_ layout: R.Layout, _ state: R.State, tint: Color) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(layout.slots) { slot in
                SlotView(size: layout.cardSize, symbol: slot.symbol, label: slot.label, filled: slot.filled, tint: tint,
                         symbolColor: slot.suit.flatMap { suit in
                             // rote (bzw. blaue/grüne) Kartenfarben in ihrer Farbe, schwarze in der Tischfarbe
                             // B18 (F-AWS-K-025): Auf dunklen bzw. kräftig gefärbten Tischen (weiße Plätze, z. B. Salon rot) bleibt das Symbol weiß,
                             // sonst verschwindet Rot auf Rot.
                             tint == .white ? nil :
                             (suit.isRed || (store.prefs.fourColor && suit != .spades)) ? Theme.ink(for: suit, fourColor: store.prefs.fourColor) : nil
                         })
                    .opacity(slot.dimmed ? 0.5 : 1)
                    .scaleEffect(slot.scale)
                    .position(x: slot.frame.midX, y: slot.frame.midY)
            }
            if let center = layout.stockCountCenter, let caption = layout.stockCaption {
                Text(caption)
                    .font(.system(.caption2, design: Design.zahlDesign)).monospacedDigit()
                    .dynamicTypeSize(.large)                  // hängt an der Kartengröße, nicht an der Schrift
                    .foregroundStyle(tint.opacity(Design.ist(.salon) ? 0.95 : 0.6))   // F-AWS-K-026: in Salon auf dem Spielart-Rot sonst rosa auf rot
                    .position(center)
            }
        }
        .accessibilityHidden(true)
    }

    private func highlights(_ layout: R.Layout, _ state: R.State, targets: [Pile]) -> some View {
        ZStack(alignment: .topLeading) {
            ForEach(targets, id: \.self) { pile in
                frameHighlight(layout.targetFrame(pile), layout: layout)
            }
            if let sel = store.selected {
                // Gewählte Karte: Goldrand; mögliche Partner leuchten
                ForEach(R.partners(state, of: sel), id: \.self) { frameHighlight(layout.targetFrame($0), layout: layout) }
            }
            if let hint = store.hint {
                switch hint {
                case .draw:
                    if let tap = layout.stockTapFrame {
                        PulseFrame(cornerRadius: Theme.cardRadius(layout.cardSize.width))
                            .frame(width: tap.width, height: tap.height)
                            .position(x: tap.midX, y: tap.midY)
                            .id(store.hintShown)
                    }
                case let .move(from, to, count):
                    frameHighlight(layout.targetFrame(to), layout: layout)
                    if let moving = R.movingCards(state, from: from, count: count),
                       let firstFrame = layout.placements[moving[0]]?.frame {
                        frameHighlight(firstFrame, layout: layout)
                        let land = layout.landingOrigin(to)
                        HintGhostView(cards: moving.compactMap { c in layout.placements[c].map { (state.face(of: c), $0.frame) } },
                                      delta: CGSize(width: land.x - firstFrame.minX, height: land.y - firstFrame.minY),
                                      fourColor: store.prefs.fourColor)
                            .id(store.hintShown)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .zIndex(900)
        .animation(.easeOut(duration: 0.15), value: store.hint)
    }

    private func frameHighlight(_ r: CGRect, layout: R.Layout) -> some View {
        RoundedRectangle(cornerRadius: Theme.cardRadius(layout.cardSize.width))
            .strokeBorder(Color.appFarbe, lineWidth: 2.5)
            .background(RoundedRectangle(cornerRadius: Theme.cardRadius(layout.cardSize.width)).fill(Color.appFarbe.opacity(0.15)))
            .frame(width: r.width, height: r.height)
            .position(x: r.midX, y: r.midY)
            .transition(.opacity)
    }

    // MARK: Ziehen mit dem Finger (Zustand)

    private func liftedCards(_ state: R.State) -> Set<CardID> {
        guard let pile = drag.place else { return [] }
        return Set(R.movingCards(state, from: pile, count: drag.count) ?? [])
    }

    /// Erlaubte Ziele leuchten beim Ziehen gold auf.
    private func dragTargets(_ state: R.State, _ layout: R.Layout) -> [Pile] {
        guard let pile = drag.place else { return [] }
        return layout.dropPiles.filter { R.isLegal(state, .move(from: pile, to: $0, count: drag.count)) }
    }
}

/// Kurzer Gold-Schimmer (0,6 s) über einem Ziel; bei „Bewegung reduzieren“ nur ein Aufleuchten ohne Vergrößern
private struct ShimmerFrame: View {
    let trigger: Int
    let cornerRadius: CGFloat
    let reduceMotion: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.appFarbe.opacity(0.35))
            .overlay(RoundedRectangle(cornerRadius: cornerRadius).strokeBorder(Color.appFarbe, lineWidth: 2))
            .keyframeAnimator(initialValue: 0.0, trigger: trigger) { content, v in
                content.opacity(v).scaleEffect(reduceMotion ? 1 : 1 + 0.10 * v)
            } keyframes: { _ in
                CubicKeyframe(1.0, duration: 0.18)
                CubicKeyframe(0.0, duration: 0.42)
            }
    }
}

/// „+15“ in Gold: steigt 30 pt und blendet in 0,6 s aus (bei „Bewegung reduzieren“ nur ausblenden)
private struct FloatingBonus: View {
    let text: String
    let reduceMotion: Bool
    @State private var gone = false

    var body: some View {
        Text(text)
            .font(.system(.title3, design: Design.zahlDesign).weight(.black))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .foregroundStyle(Color.appFarbe)
            .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
            .offset(y: gone && !reduceMotion ? -30 : 0)
            .opacity(gone ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 0.6)) { gone = true } }
    }
}

/// Eine Karte auf dem Tisch. Liest den Fingerversatz nur, wenn sie selbst angehoben ist.
private struct CardNodeView<R: SolitaireRulesMitLayout>: View {
    let store: GameStore<R>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let card: CardID
    let placement: CardPlacement
    let layout: R.Layout
    let source: CardSource?
    var pile: Pile?
    let lifted: Bool
    var inStock = false
    let drag: DragModel
    var selected = false

    var body: some View {
        let p = placement
        let face = store.state.face(of: card)
        let size = layout.cardSize
        FlippingCardView(face: face, width: size.width, fourColor: store.prefs.fourColor, angle: p.faceUp ? 0 : 180, covered: p.covered)
            .animation(flipAnimation, value: p.faceUp)
            .overlay {
                if p.dimmed {
                    RoundedRectangle(cornerRadius: Theme.cardRadius(size.width)).fill(.black.opacity(0.12)).allowsHitTesting(false)
                }
                if selected {
                    RoundedRectangle(cornerRadius: Theme.cardRadius(size.width)).strokeBorder(Color.appFarbe, lineWidth: 2).allowsHitTesting(false)
                }
            }
            .shadow(color: .black.opacity(lifted ? 0.28 : 0.18), radius: lifted ? 8 : 2, x: 0, y: lifted ? 5 : 1)
            .scaleEffect(lifted ? 1.04 : 1)
            .animation(.easeOut(duration: 0.12), value: lifted)
            .frame(width: size.width, height: size.height)
            .scaleEffect(p.scale)
            .position(x: p.frame.midX, y: p.frame.midY - (selected ? 6 : 0))
            .animation(moveAnimation, value: p.frame)
            .animation(.easeOut(duration: 0.12), value: selected)
            .transition(.scale(scale: 0.6).combined(with: .opacity))
            .offset(lifted ? drag.translation : .zero)
            .rotationEffect(.degrees(lifted && !reduceMotion ? drag.tilt : 0))
            .keyframeAnimator(initialValue: 0.0, trigger: inStock ? store.stockWiggle : store.shakes[card.number, default: 0]) { content, dx in
                content.offset(x: dx)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(5, duration: 0.05)
                    CubicKeyframe(-5, duration: 0.08)
                    CubicKeyframe(5, duration: 0.08)
                    CubicKeyframe(0, duration: 0.05)
                }
            }
            .opacity(reduceMotion && store.showsPreDeal ? 0 : 1)
            .animation(.easeIn(duration: 0.25), value: store.showsPreDeal)
            .zIndex(lifted ? 1000 + p.z : p.z)
            .onTapGesture { store.tap(card: card, source: source) }
            .gesture(store.gaveUp || R.tapOnly ? nil : source.map { dragGesture($0) })      // nach dem Aufgeben bzw. beim Abspielen ist der Tisch gesperrt
            .accessibilityElement()
            .accessibilityLabel(accessibilityText(face: face, faceUp: p.faceUp))
            .accessibilityAddTraits(selected ? [.isButton, .isSelected] : source == nil ? [] : .isButton)
    }

    private var moveAnimation: Animation? {
        if reduceMotion { return .linear(duration: 0.15) }
        if store.dealing {
            // Austeilen: Karten fliegen einzeln, Zeile für Zeile, je 0,018 s versetzt
            let order = store.state.dealOrder(of: card) ?? 0
            return .spring(response: 0.3, dampingFraction: 0.86).delay(Double(order) * 0.018)
        }
        switch store.moveStyle {
        case .normal: return .spring(response: 0.28, dampingFraction: 0.86)
        case .drop: return .spring(response: 0.24, dampingFraction: 0.78)     // setzt mit leichtem Überschwingen auf
        case .undo: return .spring(response: 0.26, dampingFraction: 0.90)
        case .finish: return .spring(response: 0.22, dampingFraction: 0.90)
        case .recycle: return .easeInOut(duration: 0.25)
        case .draw:
            // Klondike 3 Karten: je 0,04 s versetzt, landen aufgefächert · Spider: 10 Karten nacheinander
            return .spring(response: 0.25, dampingFraction: 0.90).delay(store.state.stagger(of: card, style: .draw))
        case .complete:
            // Fertige Reihe: Karten fliegen nacheinander vom Ass bis zum König ab
            return .spring(response: 0.28, dampingFraction: 0.86).delay(store.state.stagger(of: card, style: .complete))
        }
    }

    private var flipAnimation: Animation? {
        if reduceMotion { return .linear(duration: 0.15) }
        if store.dealing { return .easeInOut(duration: 0.2).delay(0.9 + 0.03 * Double(store.state.dealColumn(of: card) ?? 0)) }
        return .easeInOut(duration: 0.2).delay(store.moveStyle == .undo ? 0 : 0.05)
    }

    private func dragGesture(_ source: CardSource) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("table"))
            .onChanged { value in
                if drag.place == nil {
                    store.flush()
                    SpielHaptik.select()
                    OrientationLock.lock()
                    drag.place = source.pile
                    drag.count = source.count
                }
                drag.translation = value.translation
                drag.tilt = max(-4, min(4, Double(value.velocity.width) / 300))
                // Ein Tick, sobald der Finger über ein erlaubtes Ziel kommt
                let state = store.state
                let over = layout.dropTarget(at: dropPoint(source, translation: value.translation, state: state))
                let legal = over.flatMap { R.isLegal(state, .move(from: source.pile, to: $0, count: source.count)) ? $0 : nil }
                if legal != drag.hover {
                    drag.hover = legal
                    if legal != nil { SpielHaptik.select() }
                }
            }
            .onEnded { value in
                let state = store.state
                let target = layout.dropTarget(at: dropPoint(source, translation: value.translation, state: state))
                let move = target.map { Move.move(from: source.pile, to: $0, count: source.count) }
                withAnimation(reduceMotion ? .linear(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.86)) {
                    drag.end()
                    if let move, R.isLegal(state, move) {
                        store.perform(move, style: .drop)
                    } else if source.count > 1, case let .column = target, let t = target,
                              let limit = R.maxMovable(state, to: t), source.count > limit,
                              let first = R.movingCards(state, from: source.pile, count: source.count)?.first,
                              let frame = layout.placements[first]?.frame {
                        // Zu lange Reihe (Supermove): zurückfedern und kurz „max. N“ zeigen
                        store.showLimit(limit, at: CGPoint(x: frame.midX, y: frame.minY - 12))
                    } else if value.translation != .zero {
                        SpielHaptik.soft()
                    }
                }
            }
    }

    /// VoiceOver: „Herz Zehn, Spalte 3“ bzw. „verdeckte Karte, Spalte 3“
    private func accessibilityText(face: CardFace, faceUp: Bool) -> String {
        let name = faceUp ? face.spokenName : String(localized: "Verdeckte Karte")
        guard let pile else { return name }
        let place: String
        switch pile {
        case let .column(i) where R.kind == .pyramid || R.kind == .tripeaks:
            // Pyramide bzw. Gipfel: Reihe von oben, und ob die Karte schon frei ist
            let row = R.kind == .pyramid ? PyramidState.row(of: i) : TriPeaksState.row(of: i)
            place = String(localized: "Reihe \(row + 1)") + ", " + (source == nil ? String(localized: "bedeckt") : String(localized: "frei"))
        case let .column(i): place = String(localized: "Spalte \(i + 1)")
        case let .cell(i): place = String(localized: "Zelle \(i + 1)")
        case .foundation: place = String(localized: "Ziel")
        case .waste: place = String(localized: "Ablage")
        case .stock: place = String(localized: "Stapel")
        }
        return "\(name), \(place)"
    }

    /// Mitte der untersten gezogenen Karte, mit dem Fingerversatz
    private func dropPoint(_ source: CardSource, translation: CGSize, state: R.State) -> CGPoint {
        let bottom = R.movingCards(state, from: source.pile, count: source.count)?.first
        let frame = bottom.flatMap { layout.placements[$0]?.frame } ?? .zero
        return CGPoint(x: frame.midX + translation.width, y: frame.midY + translation.height)
    }
}
