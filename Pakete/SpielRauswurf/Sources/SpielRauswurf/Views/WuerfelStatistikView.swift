// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas

/// Sechs kleine Balken: wie oft jede Zahl fiel.
struct AugenBalken: View {
    let augen: [Int]
    var farbe: Color = Color.appFlaeche
    var hoehe: CGFloat = 44

    var body: some View {
        let maximum = max(1, augen.max() ?? 1)
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(0 ..< 6, id: \.self) { k in
                VStack(spacing: 3) {
                    Text("\(augen[k])").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(farbe.opacity(k == 5 ? 1 : 0.65))
                        .frame(height: max(3, hoehe * CGFloat(augen[k]) / CGFloat(maximum)))
                    Text("\(k + 1)").font(.caption2.weight(.semibold))
                }
                .frame(maxWidth: .infinity, maxHeight: hoehe + 36, alignment: .bottom)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel((0 ..< 6).map { "\($0 + 1): \(augen[$0])" }.joined(separator: ", "))
    }
}

/// Menü → Würfelstatistik: offen zeigen, was gewürfelt wurde (SPEZIFIKATION 11.1).
struct WuerfelStatistikView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Design.Abstand.m) {
                    if let z = store.zustand {
                        let zahlen = Wuerfelstatistik.zaehle(z.partie)
                        ForEach(Array(z.spieler.enumerated()), id: \.offset) { i, s in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: Design.Abstand.s) {
                                    AvatarBadge(avatar: s.avatar, sitz: s.sitz, size: 30)
                                    Text(s.name).font(.headline).foregroundStyle(BrettTheme.standard.textfarbe(s.sitz))
                                    Spacer()
                                    Text(L("wuerfel.wuerfe", zahlen[i].wuerfe)).font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                                }
                                AugenBalken(augen: zahlen[i].augen, farbe: BrettTheme.standard.farbe(s.sitz))
                                Text(L("wuerfel.ohneSechs", zahlen[i].ohneSechs)).font(.footnote).foregroundStyle(.secondary)
                                if zahlen[i].eingetippt > 0 {
                                    Text(L("wuerfel.eingetippt", zahlen[i].eingetippt)).font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                            .card()
                            .accessibilityElement(children: .contain)
                        }
                    }
                    Text(L("wuerfel.fair")).font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal)
                }
                .padding()
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .background(Color.seitenGrund)
            .navigationTitle(L("wuerfel.titel"))
            .navigationBarTitleDisplayMode(.inline)
            .einstellungsSchliessen()
        }
    }
}
