// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Mindestgröße eines Feldes; darunter wird das Gitter zoom- und schiebbar.
enum GridMetrics {
    static let minCell: CGFloat = 34
    static let maxZoom: CGFloat = 2
}

/// Das Gitter mit allen Feldern. Antippen meldet die Position.
struct GridView: View {
    let data: GridData
    let cell: CGFloat
    var wave: GameStore.Wave?
    var onTap: ((Pos) -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale

    /// Feldgröße auf ganze Pixel gerundet, damit die Linien auch bei Zoom (1,5× / 2× / Pinch) scharf bleiben
    private var pixelCell: CGFloat { (cell * displayScale).rounded(.down) / displayScale }

    var body: some View {
        let p = data.puzzle
        VStack(spacing: 0) {
            ForEach(0..<p.hoehe, id: \.self) { r in
                HStack(spacing: 0) {
                    ForEach(0..<p.breite, id: \.self) { c in
                        let pos = Pos(r, c)
                        CellView(data: data, pos: pos, size: pixelCell, wave: wave)
                            .equatable()   // Feld zeichnet nur neu, wenn sich sein eigener Zustand ändert (flüssig auf Schwer)
                            .id(pos)
                            .onTapGesture { onTap?(pos) }
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            // Der Cursor-Rahmen gleitet weich von Feld zu Feld (bei „Bewegung reduzieren“ springt er)
            if let cur = data.cursor {
                Rectangle().stroke(Color.gAkzent, lineWidth: 2)
                    .frame(width: pixelCell, height: pixelCell)
                    .offset(x: CGFloat(cur.c) * pixelCell, y: CGFloat(cur.r) * pixelCell)
                    .animation(reduceMotion ? nil : .snappy(duration: 0.12), value: cur)
                    .allowsHitTesting(false)
            }
        }
        .overlay(Rectangle().stroke(Design.art == .klar ? Color.kwAkzent : Color.gLinie, lineWidth: 1.5))
        .accessibilityElement(children: .contain)
    }
}

/// Alles, was ein einzelnes Feld zum Zeichnen braucht – nur wenn sich das ändert, wird das Feld neu gezeichnet.
struct CellKey: Equatable {
    var entry: Character?
    var isCursor = false
    var isActive = false
    var isWrong = false
    var isRevealed = false
    var isPencil = false
    var solutionNumber: Int?
    /// Fragefeld: ob die (bis zu zwei) Fragen aktiv sind
    var clueActive: [Bool] = []
    var waveID: UUID?
    var shakeID: UUID?

    init(data: GridData, pos: Pos, wave: GameStore.Wave?) {
        let p = data.puzzle
        if p.isLetter(pos) {
            entry = data.entries[pos]
            isCursor = data.cursor == pos
            isActive = data.activeCells.contains(pos)
            isWrong = data.marked.contains(pos) || data.shownWrong.contains(pos)
            isRevealed = data.revealed.contains(pos)
            isPencil = data.uncertain.contains(pos)
            solutionNumber = data.solutionIndex[pos]
            if let wave, wave.cells.contains(pos) { waveID = wave.id }
            if let shake = data.shake, shake.cells.contains(pos) { shakeID = shake.id }
        } else if p.isClueCell(pos) {
            clueActive = p.clues(inCell: pos).map { data.activeClue == $0 }
        }
    }
}

struct CellView: View, Equatable {
    let data: GridData
    let pos: Pos
    let size: CGFloat
    var wave: GameStore.Wave?
    let key: CellKey

    init(data: GridData, pos: Pos, size: CGFloat, wave: GameStore.Wave?) {
        self.data = data; self.pos = pos; self.size = size; self.wave = wave
        key = CellKey(data: data, pos: pos, wave: wave)
    }

    nonisolated static func == (a: CellView, b: CellView) -> Bool { a.key == b.key && a.size == b.size && a.pos == b.pos }

    @State private var flash = false
    @State private var pop = false
    @State private var shakeX: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @Environment(\.displayScale) private var displayScale
    @State private var clueGlow = false

    var body: some View {
        let p = data.puzzle
        Group {
            if p.isLetter(pos) { letter } else if p.isClueCell(pos) { clue } else {
                Color.feldSperre
            }
        }
        .frame(width: size, height: size)
        .overlay(Rectangle().stroke(Color.gLinie, lineWidth: 1 / displayScale))
        .onChange(of: key.waveID) { _, id in
            guard id != nil, let w = wave, let i = w.cells.firstIndex(of: pos) else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : w.step * i))   // bei „Bewegung reduzieren“: alle zugleich überblenden
                withAnimation(.easeOut(duration: 0.15)) { flash = true }
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.easeOut(duration: 0.3)) { flash = false }
            }
        }
        .onChange(of: key.shakeID) { _, id in
            // sanftes Schütteln (2 × 3 pt, 250 ms) bei Fehlern nach „prüfen“
            guard id != nil, !reduceMotion else { return }
            Task {
                for dx: CGFloat in [3, -3, 3, -3, 0] {
                    withAnimation(.linear(duration: 0.05)) { shakeX = dx }
                    try? await Task.sleep(for: .milliseconds(50))
                }
            }
        }
        .onChange(of: key.entry) { old, new in
            // kurzer Pop beim Eintippen (nicht bei „Bewegung reduzieren“)
            guard new != nil, new != old, !reduceMotion else { return }
            pop = true
            Task {
                try? await Task.sleep(for: .milliseconds(16))
                withAnimation(.snappy(duration: 0.12)) { pop = false }
            }
        }
    }

    // MARK: Buchstabenfeld

    private var letter: some View {
        let isCursor = data.cursor == pos
        let isActive = data.activeCells.contains(pos)
        let isWrong = data.marked.contains(pos) || data.shownWrong.contains(pos)
        let isRevealed = data.revealed.contains(pos)
        let isPencil = data.uncertain.contains(pos)
        let dark = scheme == .dark
        return ZStack {
            Color.gFeldLeer
            if isWrong { Color.fehler.opacity(0.14) }
            if isActive { Color.gWort(dunkel: dark) }
            if isCursor { Design.art == .klar ? Color.kwAkzent.opacity(dark ? KwFarbe.cursorMarkierung.dunkel : KwFarbe.cursorMarkierung.hell) : Color.gAkzent }
            if flash { Color.kwAkzent.opacity(0.55) }
            if let ch = data.entries[pos] {
                Text(String(ch))
                    .font(.system(size: size * (data.solutionIndex[pos] != nil ? 0.52 : 0.58), weight: isPencil ? .regular : .semibold, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .offset(y: data.solutionIndex[pos] != nil ? size * 0.05 : 0)
                    .foregroundStyle(isCursor && Design.art != .klar ? Color.gAufAkzent : isWrong ? Color.fehler : isRevealed ? Color.kwAkzent
                                     : isPencil ? Color.tinte.opacity(KwFarbe.bleistift) : Color.tinte)
                    .scaleEffect(pop ? 1.15 : 1)
                    .offset(x: shakeX)
            }
            if isRevealed {
                Circle().fill(Color.kwAkzent).frame(width: max(3, size * 0.1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(size * 0.08)
            }
            if let n = data.solutionIndex[pos] {
                // Lösungswort: kleiner Kreis mit Nummer oben links (der Buchstabe sitzt etwas tiefer und kleiner)
                let d = max(9, size * 0.24)
                Text("\(n)")
                    .font(.system(size: d * 0.62, weight: .semibold, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                    .foregroundStyle(Color.gAkzent)
                    .frame(width: d, height: d)
                    .overlay(Circle().stroke(Color.gAkzent.opacity(0.8), lineWidth: 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(size * 0.04)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(letterLabel)
        .accessibilityHint(hint)
        .accessibilityAddTraits(.isButton)
    }

    private var letterLabel: String {
        var s = String(localized: "Zeile \(pos.r + 1), Spalte \(pos.c + 1)") + ", "
        s += data.entries[pos].map(String.init) ?? String(localized: "leer")
        if let n = data.solutionIndex[pos] { s += ", " + String(localized: "Lösungswort, Buchstabe \(n)") }
        if data.revealed.contains(pos) { s += ", " + String(localized: "aufgedeckt") }
        if data.marked.contains(pos) || data.shownWrong.contains(pos) { s += ", " + String(localized: "falsch") }
        return s
    }

    private var hint: String {
        let dir = data.activeClue?.direction ?? .rechts
        guard let c = data.puzzle.clue(at: pos, direction: dir) else { return "" }
        let n = data.puzzle.wordCells(c).count
        let name = dir == .rechts ? String(localized: "Waagerecht") : String(localized: "Senkrecht")
        return "\(name): \(c.text), " + String(localized: "\(n) Buchstaben")
    }

    // MARK: Fragefeld

    private var clue: some View {
        let clues = data.puzzle.clues(inCell: pos)
        return ZStack {
            Color.gFrageFeld
            if clues.count == 2 {
                VStack(spacing: 0) {
                    clueText(clues[0], arrowAt: .trailing, split: true)
                    Rectangle().fill(Color.gLinie).frame(height: 0.5)
                    clueText(clues[1], arrowAt: .bottom, split: true)
                }
            } else if let c = clues.first {
                clueText(c, arrowAt: c.direction == .rechts ? .trailing : .bottom, split: false)
            }
        }
        .overlay(Color.gAkzent.opacity(clueGlow ? 0.55 : 0).allowsHitTesting(false))
        .onChange(of: key.clueActive) { old, new in
            // Beim Sprung ins nächste Wort leuchtet dessen Fragefeld 200 ms in der Akzentfarbe auf
            guard !reduceMotion, new.contains(true), !old.contains(true) else { return }
            clueGlow = true
            Task {
                try? await Task.sleep(for: .milliseconds(30))
                withAnimation(.easeOut(duration: 0.2)) { clueGlow = false }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(clueLabel(clues))
        .accessibilityAddTraits(.isButton)
    }

    /// Fragetext mit Pfeil. Die aktive Frage ist invertiert (volle Akzentfarbe), bei zwei Fragen nur ihre Hälfte.
    private func clueText(_ c: Clue, arrowAt edge: Alignment, split: Bool) -> some View {
        let active = data.activeClue == c
        let box = ClueFit.box(cell: size, bottom: edge == .bottom, split: split)
        return ZStack(alignment: edge) {
            if active { Color.gAkzent }
            ClueText(text: c.boxText, width: box.width, height: box.height, base: ClueFit.baseSize(cell: size),
                     minSize: ClueFit.minimum(split: split), color: active ? Color.gAufAkzent : Color.gFrageText)
                // Text mittig in dem Bereich, den der Pfeil nicht belegt
                .padding(.horizontal, ClueFit.margin)
                .padding(.trailing, edge == .trailing ? ClueFit.arrowZone : 0)
                .padding(.bottom, edge == .bottom ? ClueFit.arrowZone : 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Image(systemName: edge == .trailing ? "arrowtriangle.right.fill" : "arrowtriangle.down.fill")
                .font(.system(size: 4.5)) // design:spielinhalt
                .foregroundStyle(active ? Color.gAufAkzent : Color.gPfeil)
        }
    }

    private func clueLabel(_ clues: [Clue]) -> String {
        clues.map { c in
            let name = c.direction == .rechts ? String(localized: "Frage nach rechts") : String(localized: "Frage nach unten")
            return "\(name): \(c.text), " + String(localized: "\(data.puzzle.wordCells(c).count) Buchstaben")
        }.joined(separator: ". ")
    }
}
#endif
