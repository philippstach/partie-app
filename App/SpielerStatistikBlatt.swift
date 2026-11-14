// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import Charts
import KlarGlas
import SpieleKern

/// Statistik einer Person (W10): Partien, Siege, Siegquote, Lieblingsspiele, Bilanz gegen die anderen – aus dem Ereignisspeicher.
struct SpielerStatistikBlatt: View {
    let spieler: Spieler
    @Environment(StatistikDienst.self) private var statistik
    @Environment(SpielerVerzeichnis.self) private var verzeichnis
    @Environment(\.dismiss) private var dismiss

    private struct SpielZahl: Identifiable { let id: String; let modul: any SpielModul; let partien: Int; let siege: Int }
    private struct Bilanz: Identifiable { let id: UUID; let name: String; let partien: Int; let siege: Int; let niederlagen: Int; let unentschieden: Int }

    private var spiele: [SpielZahl] {
        SpielKatalog.alleModule.compactMap { m in
            let s = statistik.summe(spiel: m.id, spieler: spieler.id)
            return s.partien > 0 ? SpielZahl(id: m.id, modul: m, partien: s.partien, siege: s.siege) : nil
        }.sorted { $0.partien > $1.partien }
    }

    /// Gegen wen wie oft gespielt und gewonnen (nur Partien mit genau diesen beiden unter den Teilnehmern).
    private var bilanzen: [Bilanz] {
        verzeichnis.menschen.filter { $0.id != spieler.id }.compactMap { g in
            let d = statistik.duell(spieler.id, gegen: g.id)
            guard d.partien > 0 else { return nil }
            return Bilanz(id: g.id, name: g.name, partien: d.partien, siege: d.siege, niederlagen: d.niederlagen, unentschieden: d.unentschieden)
        }.sorted { $0.partien > $1.partien }
    }

    var body: some View {
        let s = statistik.summe(spieler: spieler.id)
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    HStack(spacing: 14) {
                        SpielerBildKreis(spieler, groesse: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: spieler.name).font(.title2.bold())
                            Text("\(s.partien) Partien · \(s.siege) Siege · \(s.partien > 0 ? Int((Double(s.siege) / Double(s.partien) * 100).rounded()) : 0) %")
                                .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .card()
                    .accessibilityElement(children: .combine)
                    if s.partien == 0 {
                        Text("Noch keine Partien mit \(spieler.name). Wähle die Person beim nächsten Spiel aus, dann zählt alles hier mit.").font(.subheadline).foregroundStyle(.secondary).card()
                    }
                    if spiele.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            KartenKopf("Lieblingsspiele", zusatz: String(localized: "nach Partien"))
                            Chart(spiele.prefix(6)) { z in
                                BarMark(x: .value("Partien", z.partien), y: .value("Spiel", z.modul.name))
                                    .foregroundStyle(z.modul.gattung.farbe.color).cornerRadius(4)
                                    .annotation(position: .trailing) { Text("\(z.partien)").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
                            }
                            .chartXAxis(.hidden).frame(height: CGFloat(min(spiele.count, 6)) * 30 + 10)
                            .accessibilityLabel(Text("Lieblingsspiele")).accessibilityValue(Text(spiele.prefix(6).map { "\($0.modul.name) \($0.partien)" }.joined(separator: ", ")))
                        }
                        .card()
                    }
                    if !bilanzen.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            KartenKopf("Bilanz", zusatz: String(localized: "gegen"))
                            ForEach(bilanzen) { b in
                                NavigationLink {
                                    RivalenBlatt(spieler: spieler, gegner: verzeichnis.menschen.first { $0.id == b.id } ?? spieler)
                                } label: {
                                ViewThatFits(in: .horizontal) {
                                    HStack {
                                        Text(verbatim: b.name).font(.headline).lineLimit(1)
                                        Spacer()
                                        Text("\(b.siege) : \(b.niederlagen)").font(.system(.title3, design: Design.zahlDesign).bold().monospacedDigit())
                                        Text("in \(b.partien)").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verbatim: b.name).font(.headline)
                                        HStack { Text("\(b.siege) : \(b.niederlagen)").font(.system(.title3, design: Design.zahlDesign).bold().monospacedDigit()); Text("in \(b.partien)").font(.subheadline).foregroundStyle(.secondary) }
                                    }
                                }
                                }
                                .buttonStyle(.plain).frame(minHeight: 44)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(Text("Gegen \(b.name): \(b.siege) Siege, \(b.niederlagen) Niederlagen, \(b.unentschieden) unentschieden in \(b.partien) Partien"))
                            }
                        }
                        .card()
                    }
                    ForEach(spiele) { z in
                        HStack(spacing: Design.Abstand.m) {
                            ZStack { z.modul.gattung.farbe.color; MiniaturAnsicht(SpielMiniaturen.art(z.modul), farbe: z.modul.gattung.farbe.color, groesse: 0.6) }
                                .frame(width: 44, height: 44).clipShape(.rect(cornerRadius: Theme.feldRadius)).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                                ViewThatFits(in: .horizontal) {
                                    HStack { Text(verbatim: z.modul.name).font(.headline).lineLimit(1); Spacer(); Text("\(z.partien) Partien · \(z.siege) Siege").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary).lineLimit(1) }
                                    VStack(alignment: .leading, spacing: 2) { Text(verbatim: z.modul.name).font(.headline); Text("\(z.partien) Partien · \(z.siege) Siege").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary) }
                                }
                                Fortschrittsbalken(wert: Double(z.siege) / Double(z.partien))
                            }
                        }
                        .card()
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("\(z.modul.name): \(z.partien) Partien, \(z.siege) Siege"))
                    }
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle(spieler.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { SchliessenKnopf() } }
        }
    }
}

/// Rivalität zweier Personen (B5): Gesamtbilanz, aktuelle Siegesserie und Bilanz je Spiel.
struct RivalenBlatt: View {
    let spieler: Spieler
    let gegner: Spieler
    @Environment(StatistikDienst.self) private var statistik

    var body: some View {
        let r = statistik.rivalitaet(spieler.id, gegen: gegner.id)
        ScrollView {
            VStack(spacing: Theme.kartenAbstand) {
                VStack(spacing: 6) {
                    Text("\(r.gesamt.siege) : \(r.gesamt.niederlagen)").font(.system(.largeTitle, design: Design.zahlDesign).bold().monospacedDigit())
                    Text(verbatim: "\(spieler.name) – \(gegner.name)").font(.headline)
                    Text("\(r.gesamt.partien) Partien, \(r.gesamt.unentschieden) unentschieden").font(.subheadline).foregroundStyle(.secondary)
                    if let w = r.serieWer, r.serieLaenge >= 2 {
                        let n = w == spieler.id ? spieler.name : gegner.name
                        Label("\(n) gewinnt \(r.serieLaenge) Mal in Folge", systemImage: "flame.fill").font(.subheadline.weight(.semibold)).padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity).card()
                .accessibilityElement(children: .combine)
                VStack(alignment: .leading, spacing: 10) {
                    KartenKopf("Je Spiel", zusatz: String(localized: "Siege : Niederlagen"))
                    ForEach(r.spiele) { j in
                        HStack {
                            Text(verbatim: SpielKatalog.modul(j.spiel)?.name ?? j.spiel).font(.body).lineLimit(2)
                            Spacer()
                            Text("\(j.duell.siege) : \(j.duell.niederlagen)").font(.system(.body, design: Design.zahlDesign).bold().monospacedDigit())
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("\(SpielKatalog.modul(j.spiel)?.name ?? j.spiel): \(j.duell.siege) Siege, \(j.duell.niederlagen) Niederlagen"))
                    }
                }.card()
            }
            .padding(Theme.seitenRand)
        }
        .background(Color.seitenGrund)
        .navigationTitle(gegner.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
