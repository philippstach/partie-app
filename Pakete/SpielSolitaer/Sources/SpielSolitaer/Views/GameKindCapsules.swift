// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielauswahl als waagerecht scrollende Kapseln mit Mini-Symbol (Statistik, Regeln, Tagesspiel)
struct GameKindCapsules: View {
    @Binding var selection: GameKind
    var onSelect: (GameKind) -> Void = { _ in }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Design.Abstand.s) {
                    ForEach(GameKind.available, id: \.self) { k in
                        Button { selection = k; onSelect(k) } label: {
                            Label { Text(verbatim: k.title) } icon: { Image(systemName: k.symbol) }
                                .font(.system(.subheadline, design: Design.zahlDesign).weight(.semibold))
                                .foregroundStyle(k == selection ? Color.onAccent : .primary)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(k == selection ? Color.appFarbe : Color(.tertiarySystemFill), in: Capsule())
                                .frame(minHeight: Theme.tapSize)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .id(k)
                        .accessibilityAddTraits(k == selection ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.horizontal, -16)
            .onAppear { proxy.scrollTo(selection, anchor: .center) }
        }
    }
}
