// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas
import SpieleKern

/// Statistik eines einzelnen Spiels (L17): Bilanz (Siege, Niederlagen, Remis), Serien, Rekord, Spielzeit und die letzten Partien.
struct SpielStatistikBlatt: View {
    let modul: any SpielModul
    @Environment(StatistikDienst.self) private var statistik
    @Environment(SpielerVerzeichnis.self) private var verzeichnis
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var schrift

    var body: some View {
        let s = statistik.spielStatistik(spiel: modul.id, ich: verzeichnis.ich?.id)
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    kopf(s)
                    if s.partien == 0 {
                        Text("Noch keine Partien in diesem Spiel.").font(.subheadline).foregroundStyle(.secondary).card()
                    } else {
                        bilanz(s)
                        if !s.istPunktespiel { serien(s) }
                        weitere(s)
                        stufen(s)
                        VStack(alignment: .leading, spacing: 10) {
                            KartenKopf("Letzte Partien", zusatz: String(localized: "\(s.letzte.count) von \(s.partien)"))
                            ForEach(s.letzte) { e in SpielverlaufZeile(ergebnis: e) }
                        }
                        .card()
                    }
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle(Text(verbatim: modul.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { BlattSchliessenKnopf { dismiss() } } }
        }
    }

    private func kopf(_ s: SpielStatistik) -> some View {
        HStack(spacing: 14) {
            ZStack { modul.gattung.farbe.color; MiniaturAnsicht(SpielMiniaturen.art(modul), farbe: modul.gattung.farbe.color, groesse: 0.8) }
                .frame(width: 56, height: 56).clipShape(.rect(cornerRadius: Theme.feldRadius)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: modul.name).font(.title2.bold())
                if let d = s.letzteDatum { Text("Zuletzt gespielt: \(d.formatted(.dateTime.day().month(.abbreviated).year()))").font(.subheadline).foregroundStyle(.secondary) }
            }
            Spacer()
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func raster(_ zeilen: [[(String, LocalizedStringKey)]]) -> some View {
        VStack(spacing: 14) {
            ForEach(zeilen.indices, id: \.self) { i in
                HStack(spacing: 0) { ForEach(zeilen[i].indices, id: \.self) { j in zahl(zeilen[i][j].0, zeilen[i][j].1) } }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func bilanz(_ s: SpielStatistik) -> some View {
        if s.istPunktespiel {
            return raster([[("\(s.partien)", "Partien"), (s.rekord.map(String.init) ?? "–", "Bestwert"), (s.durchschnittPunkte.map(String.init) ?? "–", "Durchschnitt")]])
        }
        let quote = "\(Int((s.siegquote * 100).rounded())) %"
        return raster([[("\(s.partien)", "Partien"), ("\(s.siege)", "Siege"), ("\(s.niederlagen)", "Niederlagen")],
                       [("\(s.remis)", "Remis"), (quote, "Siegquote"), (s.rekord.map(String.init) ?? "–", "Bestwert")]])
    }

    private func serien(_ s: SpielStatistik) -> some View {
        raster([[("\(s.serie)", "Serie"), ("\(s.besteSerie)", "Beste Serie")]])
    }

    private func weitere(_ s: SpielStatistik) -> some View {
        var z: [(String, LocalizedStringKey)] = [(Zeitformat.text(s.dauer), "Spielzeit")]
        if s.zeitPartien > 0 { z.append((Zeitformat.text(s.dauerSchnitt), "Ø Dauer")) }
        if let r = s.rallye { z.append(("\(r)", "Rallye")) }
        return raster([z])
    }

    /// Bilanz je Stufe (Rätsel mit Leicht/Mittel/Schwer) und gelöste Tagesrätsel. Nur für Spiele, die Stufennamen nennen
    /// (`SpielModul.stufenNamen`) und die Stufe am Ende melden.
    @ViewBuilder private func stufen(_ s: SpielStatistik) -> some View {
        let namen = modul.stufenNamen
        ForEach(s.stufen.filter { namen.indices.contains($0.stufe) }) { b in
            VStack(alignment: .leading, spacing: 10) {
                KartenKopf(LocalizedStringKey(namen[b.stufe]))
                HStack(spacing: 0) {
                    zahl("\(b.partien)", "Gespielt"); zahl("\(b.siege)", "Gewonnen")
                    zahl(b.besteZeit.map { Zeitformat.text($0) } ?? "–", "Bestzeit"); zahl("\(b.besteSerie)", "Beste Serie")
                }
            }
            .card()
            .accessibilityElement(children: .combine)
        }
        if s.tagesGeloest > 0 {
            VStack(alignment: .leading, spacing: 10) {
                KartenKopf("Tagesrätsel")
                HStack(spacing: 0) { zahl("\(s.tagesGeloest)", "Gelöst") }
            }
            .card()
            .accessibilityElement(children: .combine)
        }
    }

    private func zahl(_ wert: String, _ name: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: wert).font(.system(.title2, design: Design.zahlDesign).bold().monospacedDigit()).foregroundStyle(Color.accentText).lineLimit(1).minimumScaleFactor(0.6)
            Text(name).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
