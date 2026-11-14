// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Rundenverlauf (F7): alle beendeten Runden, Abschnitt je Hälfte, die aktuelle oben, neueste Runde zuerst.
struct VerlaufView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    let zustand: Spielzustand

    private var abschnitte: [(index: Int, verlauf: HaelftenVerlauf)] {
        Array(zustand.verlaeufe.enumerated()).reversed().map { ($0.offset, $0.element) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if zustand.verlaeufe.allSatisfy({ $0.runden.isEmpty }) {
                        Text("Noch keine Runde gespielt.").font(.subheadline).foregroundStyle(.secondary).card()
                    }
                    ForEach(abschnitte, id: \.index) { a in
                        if !a.verlauf.runden.isEmpty {
                            SectionLabel(verbatim: a.verlauf.art.titel).padding(.leading, 4)
                            ForEach(Array(a.verlauf.runden.enumerated()).reversed(), id: \.offset) { i, r in
                                runde(i + 1, r)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            .background(Color.seitenGrund)
            .navigationTitle("Verlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { dismiss() } } }
        }
    }

    private func runde(_ nr: Int, _ r: RundenEintrag) -> some View {
        let z = zustand
        return VStack(alignment: .leading, spacing: Design.Abstand.s) {
            Text("Runde \(nr) · Vorleger \(z.namen[r.beginner])").font(.subheadline.weight(.bold))
            ForEach(Array(r.zuege.enumerated()), id: \.offset) { _, zug in
                let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6)) : AnyLayout(HStackLayout(spacing: Design.Abstand.s))
                layout {
                    HStack(spacing: Design.Abstand.s) {
                        AvatarAbzeichen(avatar: z.avatare[zug.spieler], farbe: Theme.color(zug.spieler), groesse: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(z.namen[zug.spieler]).font(.footnote.weight(.semibold)).lineLimit(typeSize.isAccessibilitySize ? nil : 1)
                            if zug.spieler == r.verlierer {
                                StatusChip(text: Text("verliert"), ton: .warnung).fixedSize()
                            }
                        }
                    }
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 4) }
                    HStack(spacing: 3) {
                        ForEach(Array(zug.wuerfel.enumerated()), id: \.offset) { _, w in
                            DieView(wert: w, size: typeSize.isAccessibilitySize ? 28 : 20)
                        }
                    }
                    VStack(alignment: typeSize.isAccessibilitySize ? .leading : .trailing, spacing: 0) {
                        Text(zug.ergebnis.wertung.name).font(.caption.weight(.semibold).monospacedDigit())
                        Text(wuerfeText(zug.ergebnis.wuerfe)).font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(minWidth: typeSize.isAccessibilitySize ? 0 : 84, alignment: typeSize.isAccessibilitySize ? .leading : .trailing)
                }
            }
            Divider()
            HStack {
                Text(fuss(r, z)).font(.footnote.weight(.semibold))
                Spacer()
                Text("Stock \(r.stock) · \(r.stand.map(String.init).joined(separator: "/"))")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(ansage(nr, r, z))
    }

    private func fuss(_ r: RundenEintrag, _ z: Spielzustand) -> String {
        r.ausStock
            ? String(localized: "\(r.deckel) Deckel aus dem Stock → \(z.namen[r.verlierer])")
            : z.gibtDeckel(von: r.gewinner, an: r.verlierer, r.deckel)
    }

    private func ansage(_ nr: Int, _ r: RundenEintrag, _ z: Spielzustand) -> String {
        let zeilen = r.zuege.map { "\(z.namen[$0.spieler]): \($0.ergebnis.wertung.name), \(wuerfeText($0.ergebnis.wuerfe))" }
        return String(localized: "Runde \(nr), Vorleger \(z.namen[r.beginner]).") + " " + zeilen.joined(separator: ". ") + ". " + fuss(r, z)
    }
}
