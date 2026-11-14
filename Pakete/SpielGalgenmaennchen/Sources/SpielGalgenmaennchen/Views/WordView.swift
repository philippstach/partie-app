// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
// design:spielinhalt-datei
import SwiftUI
import KlarGlas
import SpieleKern

/// Legt Teile zeilenweise nebeneinander und bricht um (Wörter mit Leerzeichen brechen am Leerzeichen).
struct WrapLayout: Layout {
    var spacing: CGFloat = 12
    var lineSpacing: CGFloat = 10

    private func rows(_ subviews: Subviews, maxWidth: CGFloat) -> (rows: [[Int]], sizes: [CGSize], height: CGFloat, width: CGFloat) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var rows: [[Int]] = [[]]
        var x: CGFloat = 0, height: CGFloat = 0, rowH: CGFloat = 0, widest: CGFloat = 0
        for (i, s) in sizes.enumerated() {
            if x > 0, x + spacing + s.width > maxWidth {
                height += rowH + lineSpacing; rowH = 0; x = 0; rows.append([])
            }
            x += (x > 0 ? spacing : 0) + s.width
            rowH = max(rowH, s.height)
            rows[rows.count - 1].append(i)
            widest = max(widest, x)
        }
        return (rows, sizes, height + rowH, widest)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let r = rows(subviews, maxWidth: proposal.width ?? .infinity)
        return CGSize(width: r.width, height: r.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let r = rows(subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in r.rows {
            let rowWidth = row.reduce(CGFloat(0)) { $0 + r.sizes[$1].width } + CGFloat(max(0, row.count - 1)) * spacing
            var x = bounds.midX - rowWidth / 2
            let rowH = row.map { r.sizes[$0].height }.max() ?? 0
            for i in row {
                subviews[i].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(r.sizes[i]))
                x += r.sizes[i].width + spacing
            }
            y += rowH + lineSpacing
        }
    }
}

/// Eine Kachel pro Zeichen. Treffer decken sich von links nach rechts auf (je 0,07 s), jede Kachel springt
/// auf 1,25 und ist 0,6 s in der App-Farbe. Beim Sieg hüpft eine Welle über alle Kacheln, bei der Niederlage blenden die
/// fehlenden Buchstaben nacheinander grau ein (Werte: Doku/DESIGN.md „Spielgefühl“).
struct WordView: View {
    let game: Game

    @Environment(GameStore.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Stellen, die noch verdeckt gezeigt werden, bis die Welle sie erreicht
    @State private var pending: Set<Int> = []
    @State private var popped: Set<Int> = []
    @State private var highlighted: Set<Int> = []
    @State private var sparkling: Set<Int> = []
    @State private var hopping: Set<Int> = []
    /// Niederlage: so viele fehlende Buchstaben sind schon grau eingeblendet
    @State private var missingShown: Int
    @State private var lastDisplay: String

    init(game: Game) {
        self.game = game
        _lastDisplay = State(initialValue: game.display)
        _missingShown = State(initialValue: game.status == .lost ? .max : 0)   // beendetes Spiel: sofort alles
    }

    private var chars: [Character] { Array(game.display) }
    /// Teile am Leerzeichen: je Teil Zeichen mit ihrem Index im ganzen Wort
    private var parts: [[(index: Int, char: Character)]] {
        var result: [[(Int, Character)]] = [[]]
        for (i, c) in chars.enumerated() {
            if c == " " { result.append([]) } else { result[result.count - 1].append((i, c)) }
        }
        return result.filter { !$0.isEmpty }.map { $0.map { (index: $0.0, char: $0.1) } }
    }

    /// Fehlende Buchstaben (Niederlage) von links nach rechts
    private var missingIndices: [Int] {
        chars.indices.filter { Letters.isLetter(chars[$0], in: game.language) && !game.guessed.contains(chars[$0]) }
    }

    var body: some View {
        let longest = max(1, parts.map(\.count).max() ?? 1)
        let missing = missingIndices
        WrapLayout(spacing: 18, lineSpacing: 10) {
            ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                HStack(spacing: 4) {
                    ForEach(part, id: \.index) { item in
                        TileView(char: item.char,
                                 state: state(item.index, item.char, missingRank: missing.firstIndex(of: item.index)),
                                 popped: popped.contains(item.index), highlighted: highlighted.contains(item.index),
                                 hop: hopping.contains(item.index), sparkle: sparkling.contains(item.index))
                    }
                }
            }
        }
        .modifier(TileWidthModifier(longest: longest))
        .onChange(of: game.guessed.count + game.wrongSolves.count) { _, _ in advance() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private func state(_ index: Int, _ c: Character, missingRank: Int?) -> TileState {
        if Letters.open.contains(c) { return .fixed }
        if pending.contains(index) { return .hidden }
        if let rank = missingRank { return rank < missingShown ? .missing : .hidden }
        return c == "_" ? .hidden : .open
    }

    // MARK: Abläufe

    private func advance() {
        let old = Array(lastDisplay), new = Array(game.display)
        lastDisplay = game.display
        if game.status == .lost { revealMissing(); return }
        guard old.count == new.count, !reduceMotion else { return }
        let fresh = old.indices.filter { old[$0] == "_" && new[$0] != "_" }   // von links nach rechts
        guard !fresh.isEmpty else { return }
        let byHint = store.lastRevealWasHint
        pending.formUnion(fresh)
        for (k, index) in fresh.enumerated() {
            Task {
                try? await Task.sleep(for: .seconds(Double(k) * GameStore.revealStep))
                pending.remove(index)
                popped.insert(index); highlighted.insert(index)
                if byHint { sparkling.insert(index) }
                try? await Task.sleep(for: .seconds(0.3))
                popped.remove(index)
                try? await Task.sleep(for: .seconds(0.3))
                highlighted.remove(index)
                sparkling.remove(index)
            }
        }
        if game.status == .won { hopWave(after: Double(fresh.count) * GameStore.revealStep + 0.2) }
    }

    /// Sieg: Hüpf-Welle über alle Kacheln (je 6 pt hoch, Abstand 0,05 s)
    private func hopWave(after delay: Double) {
        let indices = chars.indices.filter { !Letters.open.contains(chars[$0]) }
        for (j, index) in indices.enumerated() {
            Task {
                try? await Task.sleep(for: .seconds(delay + Double(j) * 0.05))
                hopping.insert(index)
                try? await Task.sleep(for: .seconds(0.18))
                hopping.remove(index)
            }
        }
    }

    /// Niederlage: die fehlenden Buchstaben blenden nacheinander grau ein (0,08 s Abstand)
    private func revealMissing() {
        let total = missingIndices.count
        guard !reduceMotion else { missingShown = .max; return }
        missingShown = 0
        Task {
            for k in 1...max(1, total) {
                try? await Task.sleep(for: .seconds(k == 1 ? 0.3 : 0.08))
                missingShown = k
            }
        }
    }

    private var accessibilityText: Text {
        let list = chars.map { c -> String in
            c == "_" ? String(localized: "leer") : (c == " " ? String(localized: "Leerzeichen") : String(c))
        }.joined(separator: ", ")
        let count = chars.filter { $0 != " " && $0 != "-" }.count
        return Text("Wort mit \(count) Buchstaben: \(list)")
    }
}

enum TileState { case hidden, open, missing, fixed }

private struct TileWidthKey: EnvironmentKey { static let defaultValue: CGFloat = 40 }
extension EnvironmentValues {
    var tileWidth: CGFloat {
        get { self[TileWidthKey.self] }
        set { self[TileWidthKey.self] = newValue }
    }
}

/// Kachelbreite = min(40, verfügbare Breite / Länge des längsten Teils)
private struct TileWidthModifier: ViewModifier {
    let longest: Int
    @State private var width: CGFloat = 40
    @State private var verfuegbar: CGFloat = 0

    private func berechne() {
        guard verfuegbar > 0 else { return }
        width = max(10, min(40, (verfuegbar - 24 - CGFloat(longest - 1) * 4) / CGFloat(longest)))
    }

    /// B18 K-016: Die Breite wird an einer Messzeile gelesen, die nicht vom Inhalt aufgeweitet wird. Sonst misst
    /// ein überlanges Wort seine eigene Breite und die Kacheln schrumpfen nie.
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: 0).frame(maxWidth: .infinity)
                .background(GeometryReader { geo in
                    Color.clear.preference(key: WidthKey.self, value: geo.size.width)
                })
            content.environment(\.tileWidth, width).frame(maxWidth: .infinity)
        }
        .onPreferenceChange(WidthKey.self) { verfuegbar = $0; berechne() }
        .onChange(of: longest) { _, _ in berechne() }
    }

    private struct WidthKey: PreferenceKey {
        static let defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
    }
}

private struct TileView: View {
    let char: Character
    let state: TileState
    let popped: Bool
    let highlighted: Bool
    let hop: Bool
    let sparkle: Bool
    @Environment(\.tileWidth) private var w
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            Text(state == .hidden ? "" : String(char))
                .font(.system(size: w * 0.62, weight: .bold, design: Design.zahlDesign))  // design:spielinhalt
                .foregroundStyle(textStyle)
                .frame(width: w, height: w * 1.3 - 6, alignment: .center)
                .frame(maxHeight: .infinity, alignment: .center)
                .scaleEffect(popped ? 1.25 : 1)
                .animation(reduceMotion ? nil : .spring(duration: 0.3, bounce: 0.5), value: popped)
            if state != .fixed {
                Rectangle().fill(underline).frame(height: 3)
            }
        }
        .frame(width: w, height: w * 1.3)
        .offset(y: hop ? -6 : 0)
        .animation(reduceMotion ? nil : .spring(duration: 0.2, bounce: 0.4), value: hop)
        .overlay { if sparkle { SparkleView().frame(width: w, height: w * 1.3) } }
        .animation(.easeOut(duration: reduceMotion ? 0.2 : 0.25), value: state)
    }

    private var textStyle: AnyShapeStyle {
        if highlighted { return AnyShapeStyle(Color.appFlaeche) }
        return state == .missing ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary)
    }

    private var underline: AnyShapeStyle {
        switch state {
        case .open: AnyShapeStyle(Color.appFlaeche)
        default: AnyShapeStyle(.secondary)
        }
    }
}

/// Hinweis: 3 kleine Sterne glitzern 0,5 s an der Kachel.
private struct SparkleView: View {
    @State private var on = false

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: [9, 7, 8][i], weight: .bold))  // design:spielinhalt
                    .foregroundStyle(Color.appFlaeche)
                    .offset(x: [-14, 15, 2][i], y: [-14, -8, -22][i])
                    .scaleEffect(on ? 1 : 0.2)
                    .opacity(on ? 0 : 1)
                    .animation(.easeOut(duration: 0.5).delay(Double(i) * 0.08), value: on)
            }
        }
        .onAppear { on = true }
        .allowsHitTesting(false)
    }
}
#endif
