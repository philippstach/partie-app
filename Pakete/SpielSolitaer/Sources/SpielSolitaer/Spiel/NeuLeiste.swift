// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Untere Leiste (Zurück · Tipp · Neu · Menü bzw. Fertig) und im Querformat die senkrechte Rundknopf-Leiste.
/// „Zurück“ gedrückt halten spult schnell zurück (0,15 s je Zug).
struct NeuLeiste: View {
    let aktionen: NeuAktionen
    var quer = false
    @Environment(AppModel.self) private var app
    @State private var halten: Task<Void, Never>?
    @State private var gehaltenAm: Date?
    @State private var breite: CGFloat = 0

    private var store: any GameSession { app.session }

    @Environment(\.designArt) private var art   // zeichnet beim Designwechsel neu

    @ViewBuilder var body: some View {
        if quer { seite } else if art == .tinte { untenTinte } else { unten }
    }

    /// Große Tinte-Runde, Punkt 10: Aktionen unten als runde Knöpfe auf dem Filz statt kleiner unterstrichener Wörter.
    /// Brechen nie um; reicht die Breite nicht (große Schrift), stehen sie in zwei Reihen. „Zurück“ gedrückt halten spult wie bisher.
    private var untenTinte: some View {
        let zurueck = Button { if store.canUndo, Date.now.timeIntervalSince(gehaltenAm ?? .distantPast) > 0.35 { store.undo() } } label: { Label("Zurück", systemImage: "arrow.uturn.backward") }
            .tischNebenKnopf().disabled(!store.canUndo)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in if halten == nil, store.canUndo { starteHalten() } }
                    .onEnded { _ in stoppeHalten() }
            )
        let tipp = Button { store.showHint() } label: { Label("Tipp", systemImage: "lightbulb") }.tischNebenKnopf()
        let neu = Button(action: aktionen.neu) { Label("Neu", systemImage: "plus.square.on.square") }.tischNebenKnopf()
        let letzter: AnyView = store.canFinish
            ? AnyView(Button { store.autoFinish() } label: { Label("Fertig", systemImage: "checkmark.circle") }.tischNebenKnopf())
            : AnyView(Button(action: aktionen.menue) { Label("Menü", systemImage: "line.3.horizontal") }.tischNebenKnopf())
        return ViewThatFits(in: .horizontal) {
            HStack(spacing: Design.Abstand.s) { zurueck; tipp; neu; letzter }
            VStack(spacing: Design.Abstand.s) {
                HStack(spacing: Design.Abstand.s) { zurueck; tipp }
                HStack(spacing: Design.Abstand.s) { neu; letzter }
            }
        }
        .padding(.horizontal, Theme.seitenRand).padding(.vertical, 4)
    }

    private var unten: some View {
        AktionsLeiste(eintraege: [
            AktionsEintrag(symbol: "arrow.uturn.backward", titel: "Zurück", gesperrt: !store.canUndo) {
                if store.canUndo, Date.now.timeIntervalSince(gehaltenAm ?? .distantPast) > 0.35 { store.undo() }
            },
            AktionsEintrag(symbol: "lightbulb", titel: "Tipp") { store.showHint() },
            AktionsEintrag(symbol: "plus.square.on.square", titel: "Neu", aktion: aktionen.neu),
            store.canFinish
                ? AktionsEintrag(symbol: "checkmark.circle", titel: "Fertig", aktiv: true) { store.autoFinish() }
                : AktionsEintrag(symbol: "line.3.horizontal", titel: "Menü", aktion: aktionen.menue),
        ])
        .padding(.vertical, 4)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { breite = $0 }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { v in
                    // Erste Spalte von vier = „Zurück“: nach 0,45 s Halten beginnt das schnelle Zurück
                    if halten == nil, store.canUndo, v.startLocation.x < breite / 4 { starteHalten() }
                }
                .onEnded { _ in stoppeHalten() }
        )
    }

    /// Querformat: dieselben vier Knöpfe senkrecht
    private var seite: some View {
        VStack(spacing: Design.Abstand.m) {
            RundKnopf(symbol: "arrow.uturn.backward", beschriftung: "Zurück") { if store.canUndo { store.undo() } }
                .disabled(!store.canUndo).opacity(store.canUndo ? 1 : 0.4)
            RundKnopf(symbol: "lightbulb", beschriftung: "Tipp") { store.showHint() }
            RundKnopf(symbol: "plus.square.on.square", beschriftung: "Neu", aktion: aktionen.neu)
            if store.canFinish { RundKnopf(symbol: "checkmark.circle", beschriftung: "Fertig") { store.autoFinish() } }
            else { RundKnopf(symbol: "line.3.horizontal", beschriftung: "Menü", aktion: aktionen.menue) }
        }
        .frame(width: 72).frame(maxHeight: .infinity).padding(.vertical, 8)
    }

    private func starteHalten() {
        halten?.cancel()
        halten = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(450))
            while !Task.isCancelled, store.canUndo {
                store.undo(); gehaltenAm = .now
                SpielHaptik.select()
                try? await Task.sleep(for: .milliseconds(150))
            }
        }
    }

    private func stoppeHalten() {
        if gehaltenAm != nil { gehaltenAm = .now }
        halten?.cancel(); halten = nil
    }
}

/// Was die Leiste auslöst
struct NeuAktionen {
    var neu: () -> Void
    var menue: () -> Void
}
