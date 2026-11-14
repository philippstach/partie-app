// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Charts
import SwiftUI
import KlarGlas
import SpieleKern

/// Hälfte vorbei: Verlierer, Stand aller Spieler, Knopf zur nächsten Hälfte.
struct HalfOverView: View {
    @Environment(GameStore.self) private var store
    @Environment(AppPreferences.self) private var preferences
    let zustand: Spielzustand

    var body: some View {
        let z = zustand
        let v = z.haelftenVerlierer.last ?? 0
        let ablauf = partieAblauf(haelftenVerlierer: z.haelftenVerlierer, optionen: z.optionen)
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    VStack(spacing: 10) {
                        SectionLabel(verbatim: z.haelfte.art.titel)
                        AvatarAbzeichen(avatar: z.avatare[v], farbe: Theme.color(v), groesse: 88)
                        Text(z.verliertHaelfte(v)).font(.title2.weight(.bold)).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .card()
                    .accessibilityElement(children: .combine)

                    VStack(spacing: Design.Abstand.s) {
                        SectionLabel("Stand")
                        ForEach(Array(z.haelfte.spieler.enumerated()), id: \.offset) { i, s in
                            HStack(spacing: 10) {
                                AvatarAbzeichen(avatar: z.avatare[s], farbe: Theme.color(s), groesse: 32)
                                Text(z.namen[s]).font(.subheadline.weight(.semibold))
                                Spacer()
                                DeckelReihe(anzahl: z.haelfte.deckel[i])
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .card()

                    if let verlauf = z.verlaeufe.last, !verlauf.runden.isEmpty { geschichte(z, verlauf, verlierer: v) }

                    if ablauf.naechste == .finale {
                        Text("Im Finale spielen \(ablauf.finaleSpieler.map { z.namen[$0] }.joined(separator: " und ")).")
                            .font(.subheadline).card()
                    }
                }
                .padding()
                .frame(maxWidth: 560).frame(maxWidth: .infinity)
            }
            BottomBar {
                Button { store.haelfteWeiter() } label: {
                    Text(ablauf.naechste == .finale ? "Finale starten" : "Hälfte 2 starten").font(.headline).frame(maxWidth: .infinity)
                }
                .hauptKnopf()
                .keyboardShortcut(.space, modifiers: [])
                .accessibilityIdentifier("haelfteWeiter")
            }
        }
        .background(Color.seitenGrund)
        .onAppear { SpielHaptik.success() }
    }
}


extension HalfOverView {
    /// „SO LIEF DIE HÄLFTE“ (R4): Deckel nach jeder Runde je Spieler, dazu Runden, Schock aus und bester Wurf.
    @ViewBuilder
    func geschichte(_ z: Spielzustand, _ verlauf: HaelftenVerlauf, verlierer v: Int) -> some View {
        let namen = verlauf.spieler.map { z.namen[$0] }
        VStack(alignment: .leading, spacing: Design.Abstand.m) {
            SectionLabel("So lief die Hälfte")
            Chart {
                ForEach(verlauf.spieler, id: \.self) { s in
                    ForEach(Array(verlauf.kurve(s).enumerated()), id: \.offset) { r, d in
                        LineMark(x: .value("Runde", r), y: .value("Deckel", d), series: .value("Spieler", z.namen[s]))
                            .foregroundStyle(by: .value("Spieler", z.namen[s]))
                            .interpolationMethod(.monotone)
                    }
                }
            }
            .chartForegroundStyleScale(domain: namen, range: verlauf.spieler.map { Theme.color($0) })
            .chartXAxis { AxisMarks(values: .automatic(desiredCount: 5)) }
            .chartYScale(domain: 0...z.optionen.deckel)
            .frame(height: 120)
            .accessibilityLabel(ansage(z, verlauf, verlierer: v))

            HStack(alignment: .top, spacing: Design.Abstand.s) {
                zahl("\(verlauf.runden.count)", "Runden")
                zahl("\(verlauf.schockAus)", "Schock aus")
                if let b = verlauf.besterWurf {
                    zahl(b.wertung.name, String(localized: "Bester Wurf: \(z.namen[b.spieler])"))
                }
            }
        }
        .card()
    }

    private func zahl(_ wert: String, _ titel: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(wert).font(.system(.headline, design: Design.zahlDesign, weight: .bold)).foregroundStyle(Color.accentText)
            Text(titel).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// „Clara lag ab Runde 6 hinten und hatte am Ende alle 13 Deckel.“
    private func ansage(_ z: Spielzustand, _ verlauf: HaelftenVerlauf, verlierer v: Int) -> String {
        guard let ab = verlauf.liegtHintenAb(v) else { return "" }
        return String(localized: "\(z.namen[v]) lag ab Runde \(ab) hinten und hatte am Ende alle \(z.optionen.deckel) Deckel.")
    }
}
