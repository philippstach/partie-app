// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Die aktive Frage voll lesbar, mit Pfeilen zur vorigen/nächsten Frage; rechts „gefüllt/Länge“ des Wortes.
struct ClueBar: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        let clue = store.activeClue
        HStack(spacing: 0) {
            stepButton("chevron.left", label: "Vorige Frage") { store.previousClue() }
            Button { store.toggleDirection() } label: {
                HStack(spacing: 10) {
                    Image(systemName: clue?.direction == .unten ? "arrow.down" : "arrow.right")
                        .font(.headline).foregroundStyle(Color.gAkzent)
                    Text(clue?.text ?? "")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.tinte)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(progressText)
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .frame(minHeight: 52)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .gesture(DragGesture(minimumDistance: 24).onEnded { v in
                // Wischen nach links = nächste Frage, nach rechts = vorige
                guard abs(v.translation.width) > abs(v.translation.height) else { return }
                if v.translation.width < 0 { store.nextClue() } else { store.previousClue() }
                SpielHaptik.tap()
            })
            .accessibilityLabel(accessibilityText)
            .accessibilityHint("Wechselt die Richtung")
            stepButton("chevron.right", label: "Nächste Frage") { store.nextClue() }
        }
        .padding(.horizontal, 4)
        .background(Color.karte, in: .rect(cornerRadius: 16))
    }

    /// „3/7“: gefüllte Felder / Länge des Wortes
    private var progressText: String {
        guard let g = store.game else { return "" }
        let cells = g.activeCells
        return "\(cells.filter { g.entries[$0] != nil }.count)/\(cells.count)"
    }

    private var accessibilityText: String {
        guard let c = store.activeClue, let g = store.game else { return "" }
        let dir = c.direction == .rechts ? String(localized: "Waagerecht") : String(localized: "Senkrecht")
        return "\(dir): \(c.text), " + String(localized: "\(g.puzzle.wordCells(c).count) Buchstaben")
    }

    private func stepButton(_ icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.headline).frame(width: 44, height: 44).contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.gAkzent)
        .accessibilityLabel(label)
    }
}

/// Flache Werkzeugzeile: vier Textknöpfe ohne Hintergrund (Bleistift aktiv = goldene Kapsel).
struct ToolRow: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Wird nach dem Prüfen mit der Zahl falscher Felder aufgerufen
    var onCheck: (Int) -> Void = { _ in }

    var body: some View {
        // Bei sehr großer Schrift 2 × 2 statt vier in einer Reihe
        let layout = typeSize.isAccessibilitySize ? AnyLayout(TwoByTwo()) : AnyLayout(HStackLayout(spacing: Design.Abstand.xs))
        layout {
            tool("pencil", "Bleistift", on: store.game?.pencil == true) {
                store.togglePencil()
                SpielHaptik.tap()
            }
            revealTool
            tool("checkmark", "Wort prüfen") { finish(store.checkWord()) }
            tool("checkmark.seal", "Alles prüfen") { finish(store.checkPuzzle()) }
        }
    }

    /// „Aufdecken“: Tippen deckt den Buchstaben auf, langes Drücken das ganze Wort
    private var revealTool: some View {
        toolFace("lightbulb", "Aufdecken", on: false)
        .contentShape(.rect)
        .onTapGesture {
            guard !store.isPaused else { return }
            store.revealLetter()
            SpielHaptik.tap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            guard !store.isPaused else { return }
            store.revealWord()
            SpielHaptik.success()
        }
        .accessibilityElement()
        .accessibilityLabel("Aufdecken")
        .accessibilityHint("Doppeltippen deckt den Buchstaben auf, gedrückt halten das ganze Wort")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Wort aufdecken") { guard !store.isPaused else { return }; store.revealWord() }
    }

    private func finish(_ wrong: Int) {
        if wrong > 0 { SpielHaptik.warning() }
        else { SpielHaptik.success() }
        onCheck(wrong)
    }

    /// Runder Glas-Knopf mit Beschriftung darunter; aktiv = App-Farbe gefüllt (Baustein-Maße, kompakt 36 pt).
    private func toolFace(_ icon: String, _ title: LocalizedStringKey, on: Bool) -> some View {
        VStack(spacing: 2) {
            ZStack {
                if on { Circle().fill(Color.kwAkzent) } else { Color.clear.glasFlaeche(.circle) }
                Image(systemName: icon).font(.subheadline.weight(.semibold))
                    .foregroundStyle(on ? Color.kwAufAkzent : Color.primary)
            }
            .frame(width: Theme.rundKnopfKlein, height: Theme.rundKnopfKlein)
            Text(title).font(.caption2).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 44)
        .contentShape(.rect)
    }

    private func tool(_ icon: String, _ title: LocalizedStringKey, on: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) { toolFace(icon, title, on: on) }
            .buttonStyle(.plain)
            .disabled(store.isPaused)
    }
}

/// Vier Knöpfe in zwei Zeilen
private struct TwoByTwo: SwiftUI.Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let w = proposal.width ?? 300
        let rows = subviews.chunked(2).map { $0.map { $0.sizeThatFits(.init(width: w / 2, height: nil)).height }.max() ?? 0 }
        return CGSize(width: w, height: rows.reduce(0, +))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in subviews.chunked(2) {
            let h = row.map { $0.sizeThatFits(.init(width: bounds.width / 2, height: nil)).height }.max() ?? 0
            for (i, v) in row.enumerated() {
                v.place(at: CGPoint(x: bounds.minX + CGFloat(i) * bounds.width / 2, y: y), proposal: .init(width: bounds.width / 2, height: h))
            }
            y += h
        }
    }
}

private extension Collection {
    func chunked(_ n: Int) -> [[Element]] {
        var out: [[Element]] = []
        var cur: [Element] = []
        for e in self { cur.append(e); if cur.count == n { out.append(cur); cur = [] } }
        if !cur.isEmpty { out.append(cur) }
        return out
    }
}

/// Eigene QWERTZ-Tastatur mit Ä Ö Ü (je zwei Felder: AE, OE, UE). ß per langem Druck auf S.
struct KeyboardView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.colorScheme) private var scheme
    var keyHeight: CGFloat = 48

    private let rows = ["QWERTZUIOPÜ", "ASDFGHJKLÖÄ", "YXCVBNM"]

    var body: some View {
        GeometryReader { geo in
            let unit = geo.size.width / 11
            VStack(spacing: 0) {
                row(rows[0], unit: unit, leading: 0)
                row(rows[1], unit: unit, leading: 0)
                HStack(spacing: 0) {
                    row(rows[2], unit: unit, leading: 0.5, fill: false)
                    key(width: unit * 3, label: Image(systemName: "delete.left"), a11y: "Löschen", rigid: true) {
                        store.delete()
                    }
                }
            }
        }
        .frame(height: keyHeight * 3)
    }

    private func row(_ letters: String, unit: CGFloat, leading: CGFloat, fill: Bool = true) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: unit * leading)
            ForEach(Array(letters), id: \.self) { ch in
                key(width: unit, label: Text(String(ch)), a11y: LocalizedStringKey(String(ch)),
                    longPress: ch == "S" ? "ß" : nil) {
                    store.type(String(ch))
                }
            }
            if fill { Spacer(minLength: 0) }
        }
    }

    private func key<L: View>(width: CGFloat, label: L, a11y: LocalizedStringKey, longPress: String? = nil,
                              rigid: Bool = false, action: @escaping () -> Void) -> some View {
        KeyCap(label: label, width: width, height: keyHeight, dark: scheme == .dark, longPress: longPress,
               onTap: {
                   guard !store.isPaused else { return }
                   action()
                   Sound.key.play()
                   if rigid { SpielHaptik.rigid() } else { SpielHaptik.stoss(.soft) }
               },
               onLong: { extra in
                   guard !store.isPaused else { return }
                   store.type(extra)
                   SpielHaptik.tap()
               })
            .accessibilityElement()
            .accessibilityLabel(a11y)
            .accessibilityAddTraits(.isKeyboardKey)
            .accessibilityAction { guard !store.isPaused else { return }; action() }
    }
}

/// Eine Taste: `karte`, Radius 8, Schatten (hell) bzw. Kontur (dunkel); gedrückt kurz Gold 25 %.
private struct KeyCap<L: View>: View {
    let label: L
    let width: CGFloat
    let height: CGFloat
    let dark: Bool
    let longPress: String?
    let onTap: () -> Void
    let onLong: (String) -> Void
    @State private var pressed = false
    @State private var longFired = false

    var body: some View {
        label
            .font(.system(.title3, design: Design.zahlDesign, weight: .semibold))
            .foregroundStyle(Color.tinte)
            .frame(width: width - 4, height: height - 7)
            .background {
                RoundedRectangle(cornerRadius: Design.Ecke.klein)
                    .fill(Color.karte)
                    .overlay(RoundedRectangle(cornerRadius: Design.Ecke.klein).fill(Color.kwAkzent.opacity(pressed ? 0.25 : 0)))
                    .overlay { if dark { RoundedRectangle(cornerRadius: Design.Ecke.klein).stroke(Color.kwAkzent.opacity(0.18), lineWidth: 1) } }
                    .shadow(color: dark ? .clear : Color.kwAkzent.opacity(0.25), radius: 0, x: 0, y: 1)
            }
            .frame(width: width, height: height) // Zwischenraum gehört zur Tippfläche
            .contentShape(.rect)
            .onLongPressGesture(minimumDuration: 0.4, maximumDistance: 20, perform: {
                if let longPress { longFired = true; onLong(longPress) }
            }, onPressingChanged: { pressing in
                if pressing { withAnimation(.easeOut(duration: 0.05)) { pressed = true } }
                else { withAnimation(.easeOut(duration: 0.15)) { pressed = false } }
            })
            .simultaneousGesture(TapGesture().onEnded {
                // Falls das Loslassen nicht gemeldet wurde, die Hervorhebung sicher zurücknehmen
                Task {
                    try? await Task.sleep(for: .milliseconds(120))
                    withAnimation(.easeOut(duration: 0.15)) { pressed = false }
                }
                if longFired { longFired = false; return }
                onTap()
            })
    }
}

/// Lösungszeile: n Kästchen mit Nummer, füllen sich aus dem Gitter; komplett und richtig = Gold.
struct SolutionRow: View {
    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glow = false

    var body: some View {
        if let g = store.game, !g.puzzle.solutionCells.isEmpty {
            let cells = g.puzzle.solutionCells
            let done = g.solutionComplete
            HStack(spacing: Design.Abstand.xs) {
                ForEach(Array(cells.enumerated()), id: \.offset) { i, pos in
                    Button { store.jumpToSolutionCell(i); SpielHaptik.tap() } label: {
                        ZStack(alignment: .topLeading) {
                            Text(store.isPaused ? "" : (g.entries[pos].map(String.init) ?? ""))   // in der Pause nichts verraten
                                .font(.system(.body, design: Design.zahlDesign, weight: .semibold))
                                .foregroundStyle(done ? Color.kwAufAkzent : Color.tinte)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Text("\(i + 1)")
                                .font(.system(size: 8, weight: .semibold, design: Design.zahlDesign)) // design:spielinhalt
                                .foregroundStyle(done ? Color.kwAufAkzent.opacity(0.8) : Color.kwAkzent)
                                .padding(.leading, 3).padding(.top, 1)
                        }
                        .frame(maxWidth: 40, minHeight: 34, maxHeight: 34)
                        .background(done ? Color.kwAkzent : Color.karte, in: .rect(cornerRadius: 6))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.kwAkzent.opacity(0.35), lineWidth: 1))
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Lösungswort, Buchstabe \(i + 1)")
                    .accessibilityValue(g.entries[pos].map(String.init) ?? String(localized: "leer"))
                }
            }
            .frame(maxWidth: .infinity)
            .scaleEffect(glow && !reduceMotion ? 1.04 : 1)
            .shadow(color: Color.kwAkzent.opacity(glow ? 0.7 : 0), radius: glow ? 12 : 0)
            .animation(.easeOut(duration: 0.3), value: done)
            .onChange(of: store.solutionPulse) { _, _ in
                // Lösungswort komplett und richtig: kurzes Aufleuchten
                withAnimation(.easeOut(duration: 0.25)) { glow = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(700))
                    withAnimation(.easeOut(duration: 0.5)) { glow = false }
                }
            }
        }
    }
}
#endif
