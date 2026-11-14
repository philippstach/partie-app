// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Spielkopf (Spielart, Wahl, Menü) mit Chip-Zeile darunter: Zeit, Züge, Punkte, je nach Einstellung.
struct NeuKopf: View {
    let titel: String
    let zurWahl: () -> Void
    let menue: () -> Void
    @Environment(AppModel.self) private var app
    private var store: any GameSession { app.session }

    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    /// Große Tinte-Runde, Punkt 14a: In Tinte steht links wie in allen anderen Spielen „Start“ (Standard-Kopf) und rechts „…“ (Menü).
    /// Klar und Salon bleiben, wie sie waren („Spiele“, Menü nur bei „Fertig“).
    @ViewBuilder private var kopf: some View {
        let mitte = store.replaying ? String(localized: "Lösung") : titel
        if art == .tinte {
            SpielKopf(mitte: mitte, linksAktion: zurWahl) {
                RundKnopf(symbol: "ellipsis", beschriftung: "Menü", aktion: menue)
            }
        } else {
            SpielKopf(linksSymbol: "square.grid.2x2", linksBeschriftung: "Spiele", mitte: mitte,
                      linksAktion: zurWahl) {
                // B12-S2-008: Das Menü sitzt unten in der Leiste; oben nur, solange dort „Fertig“ statt „Menü“ steht (nie doppelt)
                if store.canFinish { RundKnopf(symbol: "line.3.horizontal", beschriftung: "Menü", aktion: menue) }
            }
        }
    }

    var body: some View {
        VStack(spacing: Design.Abstand.s) {
            kopf
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let chips = self.chips(ctx.date)
                if !chips.isEmpty {
                    HStack(spacing: Design.Abstand.s) { ForEach(chips, id: \.symbol) { StatusChip(symbol: $0.symbol, text: $0.text) } }
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private struct Chip { var symbol: String; var text: String }

    private func chips(_ date: Date) -> [Chip] {
        if store.replaying { return [] }
        var c: [Chip] = []
        if store.deal.kind == .daily { c.append(Chip(symbol: "calendar", text: String(localized: "Tagesspiel"))) }
        if store.mode.kind == .freecell { c.append(Chip(symbol: "number", text: "\(store.deal.number)")) }
        if app.prefs.showTime { c.append(Chip(symbol: "clock", text: Zeitformat.text(store.elapsed(at: date)))) }
        if app.prefs.showMoves { c.append(Chip(symbol: "hand.tap", text: String(localized: "\(store.moves) Züge"))) }
        if app.prefs.showScore, let t = store.scoreText { c.append(Chip(symbol: "star", text: t)) }
        return c
    }
}
