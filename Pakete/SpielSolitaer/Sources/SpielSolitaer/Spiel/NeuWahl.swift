// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Variantenwahl von „Solitär“: Kopf, Karte „Tagesspiel“ (mit Kalender), die sieben Spiele mit Weiterspielen und Siegquote,
/// unten „Zum Tisch“, wenn eine Partie läuft. Die Kacheln selbst sind dieselben wie in der alten App (`GamesView`).
struct NeuWahl: View {
    let zurSammlung: () -> Void
    @Environment(AppModel.self) private var app
    @Environment(StatsStore.self) private var stats
    @Environment(Router.self) private var router
    @State private var tagesArt = GameKind.klondike
    @State private var kalender = false
    @State private var statistik = false

    private var heute: String { DailyDate.string(.now) }
    private var tagesGewonnen: Bool { stats.data.daily[tagesArt.rawValue]?.won.contains(heute) == true }
    private var tagesArten: [GameKind] { GameKind.available.filter { DealCatalog.shared.dailySeed(for: .now, kind: $0, level: nil) != nil } }
    private var laeuft: Bool { app.session.moves > 0 && !app.session.isWon && !app.session.gaveUp }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(linksSymbol: "chevron.left", linksBeschriftung: "Sammlung", mitte: String(localized: "Solitär"), linksAktion: zurSammlung) {
                RundKnopf(symbol: "chart.bar", beschriftung: "Statistik") { statistik = true }
            }
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    tagesKarte
                    GamesView(embedded: true)
                }
                .padding(.horizontal, Theme.seitenRand)
                .padding(.bottom, Theme.kartenAbstand)
                .frame(maxWidth: Theme.wideColumnWidth)
                .frame(maxWidth: .infinity)
            }
            if laeuft {
                Button("Zum Tisch") { router.leaveToGame() }
                    .hauptKnopf().padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            }
        }
        .background(Color.seitenGrund)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .sheet(isPresented: $kalender) {
            NavigationStack { DailyView(month: nil, kind: tagesArt) }.seitenBlatt()
        }
        .sheet(isPresented: $statistik) {
            NavigationStack { StatsView() }.seitenBlatt()
        }
        .onChange(of: router.showStart) { _, offen in if !offen { kalender = false; statistik = false } }
    }

    private var heuteKnopf: some View {
        Button("Heute spielen") { app.startDaily(.now, kind: tagesArt); router.leaveToGame() }
            .hauptKnopf()
    }

    private var kalenderKnopf: some View {
        Button { kalender = true } label: { Label("Kalender", systemImage: "calendar").lineLimit(1) }
            .nebenKnopf().buttonBorderShape(.capsule)
    }

    /// Das Tagesspiel: Spiel wählen, heute spielen, Kalender öffnen
    private var tagesKarte: some View {
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tagesspiel").font(.headline)
                    Text(tagesGewonnen ? "Heute gewonnen" : "Heute noch offen").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Picker("Spiel", selection: $tagesArt) { ForEach(tagesArten, id: \.self) { Text(verbatim: $0.title).tag($0) } }
                    .pickerStyle(.menu).labelsHidden()
            }
            // F-AWS-R-001: „Kalender“ bricht nicht mehr mitten im Wort um; reicht die Breite nicht, stehen die Knöpfe untereinander
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { heuteKnopf; kalenderKnopf.fixedSize() }
                VStack(spacing: 10) { heuteKnopf; kalenderKnopf.frame(maxWidth: .infinity) }
            }
        }
        .padding(Theme.innen).card()
        .accessibilityElement(children: .contain)
    }
}
