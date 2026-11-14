// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Alle Rätsel eines Themas als Raster (wie die Stufen-Liste).
struct ThemeListView: View {
    @Environment(GameStore.self) private var store
    let theme: ThemeInfo
    /// Startet das gewählte Rätsel im Rahmen (der fragt nach, falls dabei ein laufendes Rätsel verworfen würde)
    var starten: (Puzzle) -> Void = { _ in }

    private let columns = [GridItem(.adaptive(minimum: 62, maximum: 90), spacing: Design.Abstand.s)]

    var body: some View {
        let puzzles = store.library.themePuzzles(theme.id)
        ScrollView {
            VStack(spacing: 14) {
                Image(systemName: theme.symbol).font(.title).imageScale(.large).foregroundStyle(Color.kwAkzent)
                Text("\(store.themeSolvedCount(theme.id)) von \(puzzles.count) gelöst")
                    .font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: columns, spacing: Design.Abstand.s) {
                    ForEach(Array(puzzles.enumerated()), id: \.element.id) { i, p in cell(i + 1, p) }
                }
            }
            .padding(16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color.papier)
        .navigationTitle(theme.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func cell(_ number: Int, _ p: Puzzle) -> some View {
        let solved = store.isSolved(p)
        let time = store.times[p.id]
        return Button {
            starten(p)
        } label: {
            VStack(spacing: 2) {
                Text("\(number)").font(.system(.headline, design: Design.zahlDesign, weight: .bold))
                Text(solved ? (time.map { Zeitformat.text($0) } ?? "✓") : " ").font(.caption2.monospacedDigit())
            }
            .foregroundStyle(solved ? Color.kwAufAkzent : Color.tinte)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(solved ? Color.kwAkzent : Color.karte, in: .rect(cornerRadius: Design.Ecke.feld))
            .overlay(RoundedRectangle(cornerRadius: Design.Ecke.feld).stroke(Color.kwAkzent.opacity(0.25), lineWidth: 1))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement()
        .accessibilityLabel("Rätsel \(number)")
        .accessibilityValue(solved ? String(localized: "gelöst") : String(localized: "offen"))
    }
}
#endif
