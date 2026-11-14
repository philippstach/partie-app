// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern
import SudokuKern

/// Lernweg: die Techniken nach Stufe, je mit sechs Übungen. Jede Übung ist ein Feld mit Notizen und einem Ziel („Finde: Nacktes Paar“).
struct NeuLernweg: View {
    let zurueck: () -> Void
    let abbrechen: () -> Void
    let uebung: (SudokuUebungRef) -> Void
    @State private var geuebt = NeuAblage.geuebt()

    var body: some View {
        VStack(spacing: 0) {
            SpielKopf(linksSymbol: "chevron.left", linksBeschriftung: "Zurück", mitte: String(localized: "Lernweg"), linksAktion: zurueck) {
                RundKnopf(symbol: "xmark", beschriftung: "Spiel beenden", aktion: abbrechen)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                    if Exercises.all.isEmpty {
                        HinweisKarte(symbol: "exclamationmark.triangle", titel: "Keine Übungen gefunden", text: "Die Übungen konnten nicht geladen werden.")
                    }
                    ForEach(1...4, id: \.self) { stufe in
                        let technikenDerStufe = Technique.allCases.filter { $0.level == stufe && !Exercises.series(for: $0).isEmpty }
                        if !technikenDerStufe.isEmpty {
                            Text(verbatim: NeuBruecke.difficulty(NeuBruecke.stufe(Difficulty.allCases[stufe - 1])).title)
                                .font(.footnote.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase).padding(.horizontal, 4)
                            ForEach(technikenDerStufe, id: \.self) { karte($0) }
                        }
                    }
                }
                .padding(.horizontal, Theme.seitenRand).padding(.bottom, 24)
                .frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)
            }
        }
        .background(Color.seitenGrund)
        .onAppear { geuebt = NeuAblage.geuebt() }
    }

    private func karte(_ t: Technique) -> some View {
        let reihe = Exercises.series(for: t)
        let fertig = reihe.filter { NeuAblage.istGeuebt(t, $0.nr, in: geuebt) }.count
        let naechste = reihe.first { !NeuAblage.istGeuebt(t, $0.nr, in: geuebt) }?.nr ?? 1
        return HStack(spacing: Design.Abstand.m) {
            VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                Text(verbatim: t.title).font(.headline)
                Text("\(fertig) von \(reihe.count) geübt").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button { uebung(SudokuUebungRef(technik: t.rawValue, nummer: naechste)) } label: {
                Text(fertig == 0 ? "Starten" : (fertig == reihe.count ? "Nochmal" : "Weiter")).padding(.horizontal, Design.Abstand.l)
            }
            .buttonStyle(AkzentPilleStil(gefuellt: fertig < reihe.count))
            .fixedSize()
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}
