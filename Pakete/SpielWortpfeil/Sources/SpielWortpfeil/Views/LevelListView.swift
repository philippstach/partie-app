// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Alle Rätsel einer Stufe als Raster: gelöste in der Akzentfarbe mit Zeit, jedes antippbar (gelöste lassen sich wiederholen).
struct LevelListView: View {
    @Environment(GameStore.self) private var store
    @State var level: Level = .leicht
    /// Startet das gewählte Rätsel im Rahmen (der fragt nach, falls dabei ein laufendes Rätsel verworfen würde)
    var starten: (Puzzle) -> Void = { _ in }

    private let columns = [GridItem(.adaptive(minimum: 62, maximum: 90), spacing: Design.Abstand.s)]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Picker("Stufe", selection: $level) {
                    ForEach(Level.allCases) { Text(levelTitle($0)).tag($0) }
                }
                .pickerStyle(.segmented)
                let puzzles = store.library.puzzles(level)
                Text("\(store.solvedCount(level)) von \(puzzles.count) gelöst")
                    .font(.subheadline).foregroundStyle(.secondary)
                let next = store.nextPuzzle(level)?.id
                LazyVGrid(columns: columns, spacing: Design.Abstand.s) {
                    ForEach(Array(puzzles.enumerated()), id: \.element.id) { i, p in
                        cell(number: i + 1, puzzle: p, isNext: p.id == next)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color.papier)
        .navigationTitle("Alle Rätsel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func cell(number: Int, puzzle p: Puzzle, isNext: Bool) -> some View {
        let solved = store.isSolved(p)
        let time = store.times[p.id]
        return Button {
            starten(p)
        } label: {
            VStack(spacing: 2) {
                Text("\(number)").font(.system(.headline, design: Design.zahlDesign, weight: .bold))
                Text(solved ? (time.map { Zeitformat.text($0) } ?? "✓") : " ")
                    .font(.caption2.monospacedDigit())
            }
            .foregroundStyle(solved ? Color.kwAufAkzent : Color.tinte)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(solved ? Color.kwAkzent : Color.karte, in: .rect(cornerRadius: Design.Ecke.feld))
            .overlay(RoundedRectangle(cornerRadius: Design.Ecke.feld).stroke(Color.kwAkzent.opacity(isNext ? 0.9 : 0.25), lineWidth: isNext ? 2 : 1))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel("Rätsel \(number)")
        .accessibilityValue(solved ? (time.map { String(localized: "gelöst in \(Zeitformat.text($0))") } ?? String(localized: "gelöst")) : String(localized: "offen"))
    }
}
#endif
