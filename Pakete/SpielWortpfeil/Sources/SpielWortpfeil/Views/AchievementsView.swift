// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern

/// Raster runder Medaillen: erreicht = Gold-Kreis mit Symbol, offen = gedimmt mit der Bedingung darunter.
struct AchievementsView: View {
    @Environment(GameStore.self) private var store
    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 14, alignment: .top)]

    var body: some View {
        let got = Set(store.achieved)
        ScrollView {
            VStack(spacing: Design.Abstand.l) {
                Text("\(got.count) von \(Achievements.all.count) erreicht")
                    .font(.subheadline).foregroundStyle(.secondary)
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(Achievements.all) { a in medal(a, reached: got.contains(a.id)) }
                }
            }
            .padding(16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .background(Color.papier)
        .navigationTitle("Erfolge")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private func medal(_ a: Achievement, reached: Bool) -> some View {
        VStack(spacing: 6) {
            MedalView(symbol: a.symbol, reached: reached, size: 64)
            Text(a.name).font(.subheadline.weight(.semibold)).foregroundStyle(reached ? Color.tinte : Color.secondary)
                .multilineTextAlignment(.center)
            Text(a.condition).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(a.name)
        .accessibilityValue(reached ? String(localized: "erreicht") : a.condition)
    }
}

/// Medaille: erreicht = Gold-Kreis mit Symbol, offen = `feldSperre`-Kreis, Symbol gedimmt
struct MedalView: View {
    let symbol: String
    let reached: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(reached ? Color.kwAkzent : Color.feldSperre)
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                .foregroundStyle(reached ? Color.kwAufAkzent : Color.secondary)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.kwAkzent.opacity(reached ? 0 : 0.25), lineWidth: 1))
    }
}
#endif
