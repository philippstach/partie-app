// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import Charts
import KlarGlas
import SpieleKern

/// Statistik der Sammlung (C2 Fortschritts-Diagramme, H1 Spielverlauf): Kennzahlen, Partien je Woche, Partien je Spielart,
/// Siegquote je Spiel und der Verlauf der letzten Partien. Alles aus dem Ereignisspeicher `StatistikDienst`.
struct StatistikSeite: View {
    @Environment(StatistikDienst.self) private var statistik
    @Environment(SpielerVerzeichnis.self) private var verzeichnis
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var ruhig
    @Environment(\.dynamicTypeSize) private var schrift
    @ScaledMetric(relativeTo: .body) private var balkenHoehe: CGFloat = 30
    @State private var verlaufOffen = false
    @State private var spielDetail: SpielZahl?

    private struct Woche: Identifiable { let id: Date; let partien: Int }
    private struct ArtZahl: Identifiable { let id: Gattung; let partien: Int }
    fileprivate struct SpielZahl: Identifiable { let id: String; let modul: any SpielModul; let partien: Int; let siege: Int }

    /// Die letzten zwölf Wochen, auch leere (für eine gleichmäßige Achse).
    private var wochen: [Woche] {
        let kal = Calendar.current
        let heute = kal.startOfDay(for: .now)
        guard let start = kal.dateInterval(of: .weekOfYear, for: heute)?.start else { return [] }
        return (0..<12).reversed().compactMap { i in
            guard let a = kal.date(byAdding: .weekOfYear, value: -i, to: start), let b = kal.date(byAdding: .weekOfYear, value: 1, to: a) else { return nil }
            return Woche(id: a, partien: statistik.ereignisse.filter { $0.datum >= a && $0.datum < b }.count)
        }
    }

    private var spielarten: [ArtZahl] {
        SpielZeilen.spielarten.map { g in
            ArtZahl(id: g, partien: statistik.ereignisse.filter { e in SpielKatalog.modul(e.spiel)?.gattung == g }.count)
        }.filter { $0.partien > 0 }
    }

    private var spiele: [SpielZahl] {
        SpielKatalog.alleModule.compactMap { m in
            let s = statistik.summe(spiel: m.id, ich: verzeichnis.ich?.id)
            return s.partien > 0 ? SpielZahl(id: m.id, modul: m, partien: s.partien, siege: s.siege) : nil
        }.sorted { $0.partien > $1.partien }
    }

    var body: some View {
        let gesamt = statistik.summe(ich: verzeichnis.ich?.id)
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.kartenAbstand) {
                    if statistik.ereignisse.isEmpty {
                        Text("Noch keine Partien gespielt. Sobald du spielst, siehst du hier Diagramme und den Verlauf.").font(.subheadline).foregroundStyle(.secondary).card()
                    } else {
                        kennzahlen(gesamt)
                        wochenKarte
                        if spielarten.count > 1 { spielartenKarte }
                        verlaufKarte
                        NavigationLink { LeiterUebersicht() } label: {
                            Label("Schwierigkeitsleiter", systemImage: "chart.bar.fill").frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(ZweitKnopfStil())
                        SectionLabel("Je Spiel").frame(maxWidth: .infinity, alignment: .leading).padding(.top, 4)
                        ForEach(spiele) { z in Button { spielDetail = z } label: { spielZeile(z) }.buttonStyle(.plain) }
                    }
                    ShareLink(item: statistik.csv()) { Label("Statistik exportieren", systemImage: "square.and.arrow.up") }
                        .buttonStyle(ZweitKnopfStil())
                }
                .padding(Theme.seitenRand)
            }
            .scrollBounceBehavior(.basedOnSize)   // T-001: kein Wippen, wenn der Inhalt in die Höhe passt
            .background(Color.seitenGrund)
            .navigationTitle("Statistik")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { SchliessenKnopf() } }
            .sheet(isPresented: $verlaufOffen) { SpielverlaufBlatt().formSheet() }
            .sheet(item: $spielDetail) { z in SpielStatistikBlatt(modul: z.modul).formSheet() }
        }
    }

    // MARK: Karten

    /// Vier Kennzahlen nebeneinander; bei Bedienungshilfen-Schriftgrößen als Zweierraster (G3).
    private func kennzahlen(_ s: StatistikSumme) -> some View {
        let quote = s.partien > 0 ? "\(Int((Double(s.siege) / Double(s.partien) * 100).rounded())) %" : "–"
        return Group {
            if schrift.isAccessibilitySize {
                VStack(spacing: 14) {
                    HStack(spacing: 0) { zahl("\(s.partien)", "Partien"); zahl("\(s.siege)", "Siege") }
                    HStack(spacing: 0) { zahl(quote, "Siegquote"); zahl(Zeitformat.text(s.dauer), "Spielzeit") }
                }
            } else {
                HStack(spacing: 0) {
                    zahl("\(s.partien)", "Partien"); zahl("\(s.siege)", "Siege"); zahl(quote, "Siegquote"); zahl(Zeitformat.text(s.dauer), "Spielzeit")
                }
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }

    private func zahl(_ wert: String, _ name: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: wert).font(.system(.title2, design: Design.zahlDesign).bold().monospacedDigit()).foregroundStyle(Color.accentText).lineLimit(1).minimumScaleFactor(0.6)
            Text(name).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var wochenKarte: some View {
        let w = wochen
        let summe = w.reduce(0) { $0 + $1.partien }
        return VStack(alignment: .leading, spacing: 10) {
            KartenKopf("Partien je Woche", zusatz: String(localized: "letzte 12 Wochen"))
            Chart(w) { x in
                BarMark(x: .value("Woche", x.id, unit: .weekOfYear), y: .value("Partien", x.partien))
                    .foregroundStyle(Color.appFlaeche)
                    .cornerRadius(4)
            }
            .chartXAxis { AxisMarks(values: .stride(by: .month)) { _ in AxisGridLine(); AxisValueLabel(format: .dateTime.month(.abbreviated)) } }
            .chartYAxis { AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) }
            .frame(height: 140)
            .animation(ruhig ? nil : .default, value: summe)
            .accessibilityLabel(Text("Partien je Woche"))
            .accessibilityValue(Text("\(summe) Partien in den letzten zwölf Wochen"))
        }
        .card()
    }

    private var spielartenKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            KartenKopf("Was ihr spielt", zusatz: String(localized: "nach Spielart"))
            Chart(spielarten) { a in
                BarMark(x: .value("Partien", a.partien), y: .value("Spielart", a.id.anzeigeName))
                    .foregroundStyle(a.id.farbe.color)
                    .cornerRadius(4)
                    .annotation(position: .trailing) { Text("\(a.partien)").font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
            }
            .chartXAxis(.hidden)
            .chartYAxis { AxisMarks { AxisValueLabel() } }
            .frame(height: CGFloat(spielarten.count) * balkenHoehe + 10)
            .accessibilityLabel(Text("Partien nach Spielart"))
            .accessibilityValue(Text(spielarten.map { "\($0.id.anzeigeName) \($0.partien)" }.joined(separator: ", ")))
        }
        .card()
    }

    private var verlaufKarte: some View {
        VStack(alignment: .leading, spacing: 10) {
            KartenKopf("Verlauf", zusatz: String(localized: "\(statistik.ereignisse.count) Partien"))
            ForEach(statistik.ereignisse.suffix(3).reversed()) { e in SpielverlaufZeile(ergebnis: e) }
            Button { verlaufOffen = true } label: { Label("Alle Partien", systemImage: "list.bullet").frame(maxWidth: .infinity) }.buttonStyle(ZweitKnopfStil())
        }
        .card()
    }

    private func spielZeile(_ z: SpielZahl) -> some View {
        let quote = Double(z.siege) / Double(z.partien)
        return HStack(spacing: Design.Abstand.m) {
            ZStack { z.modul.gattung.farbe.color; MiniaturAnsicht(SpielMiniaturen.art(z.modul), farbe: z.modul.gattung.farbe.color, groesse: 0.6) }
                .frame(width: 44, height: 44).clipShape(.rect(cornerRadius: Theme.feldRadius)).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Design.Abstand.xs) {
                ViewThatFits(in: .horizontal) {
                    HStack { Text(verbatim: z.modul.name).font(.headline).lineLimit(1); Spacer(); Text("\(z.partien) Partien · \(z.siege) Siege").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary).lineLimit(1) }
                    VStack(alignment: .leading, spacing: 2) { Text(verbatim: z.modul.name).font(.headline); Text("\(z.partien) Partien · \(z.siege) Siege").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary) }
                }
                Fortschrittsbalken(wert: quote)
            }
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(Text("\(z.modul.name): \(z.partien) Partien, \(z.siege) Siege, Siegquote \(Int((quote * 100).rounded())) Prozent"))
    }
}

/// Eine Partie im Verlauf: Spiel, Datum, Teilnehmer mit Platz, Dauer.
struct SpielverlaufZeile: View {
    let ergebnis: PartieErgebnis
    @Environment(SpielerVerzeichnis.self) private var verzeichnis

    private var modul: (any SpielModul)? { SpielKatalog.modul(ergebnis.spiel) }

    private var teilnehmerText: String { ergebnis.ergebnisText(ichName: verzeichnis.ich?.name ?? String(localized: "Ich")) }
    private var gesprochen: String { ergebnis.ergebnisText(ichName: verzeichnis.ich?.name ?? String(localized: "Ich"), sprechend: true) }

    var body: some View {
        HStack(alignment: .top, spacing: Design.Abstand.m) {
            if let m = modul {
                ZStack { m.gattung.farbe.color; MiniaturAnsicht(SpielMiniaturen.art(m), farbe: m.gattung.farbe.color, groesse: 0.5) }
                    .frame(width: 36, height: 36).clipShape(.rect(cornerRadius: 10)).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(verbatim: modul?.name ?? ergebnis.spiel).font(.subheadline.weight(.semibold)).lineLimit(1)
                        Spacer()
                        Text(ergebnis.datum, format: .dateTime.day().month(.abbreviated)).font(.caption).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: modul?.name ?? ergebnis.spiel).font(.subheadline.weight(.semibold))
                        Text(ergebnis.datum, format: .dateTime.day().month(.abbreviated)).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(verbatim: teilnehmerText).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                if ergebnis.dauer >= 60 { Text(verbatim: Zeitformat.text(ergebnis.dauer)).font(.caption.monospacedDigit()).foregroundStyle(.secondary) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: [modul?.name ?? ergebnis.spiel, ergebnis.datum.formatted(.dateTime.day().month(.wide)), gesprochen,
                                            ergebnis.dauer >= 60 ? Zeitformat.text(ergebnis.dauer) : ""].filter { !$0.isEmpty }.joined(separator: ", ")))
    }
}

/// Alle Partien, neueste zuerst, nach Tagen gruppiert (H1 Spielverlauf).
struct SpielverlaufBlatt: View {
    @Environment(StatistikDienst.self) private var statistik
    @Environment(\.dismiss) private var dismiss

    private var tage: [(Date, [PartieErgebnis])] {
        let kal = Calendar.current
        let gruppen = Dictionary(grouping: statistik.ereignisse) { kal.startOfDay(for: $0.datum) }
        return gruppen.keys.sorted(by: >).map { ($0, gruppen[$0]!.sorted { $0.datum > $1.datum }) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.kartenAbstand) {
                    ForEach(tage, id: \.0) { tag, liste in
                        SectionLabel(text: Text(tag, format: .dateTime.weekday(.wide).day().month(.wide).year()))
                        VStack(spacing: Design.Abstand.m) { ForEach(liste) { e in SpielverlaufZeile(ergebnis: e) } }.card()
                    }
                }
                .padding(Theme.seitenRand)
            }
            .background(Color.seitenGrund)
            .navigationTitle("Spielverlauf")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { SchliessenKnopf() } }
        }
    }
}
