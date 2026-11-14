// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import HoelzchenKern

@MainActor
public struct HoelzchenModul: SpielModul {
    public init() {}
    public let id = "hoelzchen"
    public let name = "Hölzchen"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.braun
    public let symbol = "line.3.horizontal"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Nimm clever – das letzte Hölzchen entscheidet", farbe: farbe, spieler: 1...2, computerErlaubt: true,
                            regeln: "Mehrere Reihen liegen vor euch, in jeder einige Hölzchen. Wer dran ist, nimmt aus genau einer Reihe beliebig viele Hölzchen, mindestens eines. Im Modus „Klassisch“ gewinnt, wer das letzte Hölzchen nimmt. Im Modus „Pechvogel“ verliert, wer das letzte nehmen muss. Tippe auf ein Hölzchen: Es wird zusammen mit allen Hölzchen rechts davon in derselben Reihe markiert und dann genommen. Gegen den Computer wählst du die Stärke: Auf „Schwer“ macht er keine Fehler – dann gewinnt nur, wer die Stellung kennt.",
                            einzelText: "Du gegen den Computer.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            HoelzchenSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Klassisch gewinnst du, wenn du das letzte Hölzchen nimmst. Im Modus Pechvogel verliert, wer es nehmen muss.").mitAnleitung(Self.anleitung))
    }
}

struct HoelzchenSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var modus = Hoelzchen.Modus.normal
    @State private var aufbau = 0
    @State private var stufe = ComputerStufe.gespeichert("hoelzchen")
    @State private var spiel: Hoelzchen?
    @State private var markiert: (reihe: Int, ab: Int)?
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var gemeldet = false
    @State private var tick = 0
    @State private var tippGenutzt = false

    private var gegnerComputer: Bool { teilnehmer.count < 2 || teilnehmer[1].computer }
    private func name(_ i: Int) -> String { i < teilnehmer.count ? teilnehmer[i].name : String(localized: "Computer") }
    private var fehler: Double { switch stufe { case .leicht: 0.4; case .mittel: 0.15; case .schwer: 0 } }

    var body: some View {
        Group { if let s = spiel { brett(s) } else { auswahl } }.background(Color.seitenGrund).weicheAnimation(bei: spiel).dynamicTypeSize(...DynamicTypeSize.xxxLarge).spielHaptik(zug: spiel, erfolg: (spiel?.sieger != nil), fehler: false).fortsetzbar("hoelzchen", $spiel, pruefen: { $0.istKonsistent })
    }

    private var auswahl: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Hölzchen", linksAktion: abbrechen) { Color.clear.frame(width: 44, height: 44) }
            VStack(alignment: .leading, spacing: 14) {
                Text("Modus").font(.headline)
                Picker("Modus", selection: $modus) { Text("Klassisch").tag(Hoelzchen.Modus.normal); Text("Pechvogel").tag(Hoelzchen.Modus.misere) }.pickerStyle(.segmented)
                Text("Aufbau").font(.headline)
                Picker("Aufbau", selection: $aufbau) {
                    ForEach(Hoelzchen.aufbauten.indices, id: \.self) { Text(verbatim: Hoelzchen.aufbauten[$0].map(String.init).joined(separator: "-")).tag($0) }
                }.pickerStyle(.segmented)
                if gegnerComputer {
                    ComputerStufePicker(spiel: "hoelzchen", stufe: $stufe).pickerStyle(.segmented)
                }
            }.padding(Theme.seitenRand)
            Spacer()
            Button("Los geht’s") { spiel = Hoelzchen(reihen: Hoelzchen.aufbauten[aufbau], modus: modus); gemeldet = false; tippGenutzt = false }
                .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private func brett(_ s: Hoelzchen) -> some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: s.sieger == nil ? String(localized: "\(name(s.amZug)) ist dran") : String(localized: "Spielende"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { spiel = nil; markiert = nil }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            Text(s.modus == .normal ? "Wer das letzte nimmt, gewinnt." : "Wer das letzte nimmt, verliert.").font(.footnote).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            VStack(spacing: 18) {
                ForEach(s.reihen.indices, id: \.self) { r in
                    HStack(spacing: 10) {
                        ForEach(0..<s.reihen[r], id: \.self) { k in
                            let sel = markiert.map { $0.reihe == r && k >= $0.ab } ?? false
                            Capsule().fill(sel ? Color.red : Color.appFlaeche).frame(width: 14, height: 60)
                                .overlay(alignment: .top) { Circle().fill(.orange).frame(width: 14, height: 14) }
                                .padding(.horizontal, 3).contentShape(Rectangle())
                                .onTapGesture { if kannHandeln(s) { markiert = (r, k) } }
                                .accessibilityElement(children: .ignore)   // G1
                                .accessibilityLabel(Text("Reihe \(r + 1), Hölzchen \(k + 1) von \(s.reihen[r])"))
                                .accessibilityValue(sel ? Text("zum Nehmen markiert") : Text(verbatim: ""))
                                .accessibilityHint(Text("Markiert dieses und alle rechts davon."))
                                .accessibilityAddTraits(.isButton)
                        }
                        if s.reihen[r] == 0 { Color.clear.frame(width: 14, height: 60) }
                    }.frame(maxWidth: .infinity).frame(minHeight: 60)
                }
            }
            Spacer(minLength: 0)
            ZugKnoepfe(kannZurueck: s.sieger == nil && s.kannZurueck(zumSpieler: zurueckSpieler(s)),
                       tippMoeglich: kannHandeln(s),
                       zurueck: { if var s2 = spiel, s2.zurueck(zumSpieler: zurueckSpieler(s2)) { spiel = s2; markiert = nil; tick += 1 } },
                       tipp: { var g = SystemRandomNumberGenerator(); if let z = s.computerZug(fehler: 0, mit: &g) { markiert = (z.reihe, s.reihen[z.reihe] - z.anzahl); tippGenutzt = true; ansage(String(localized: "Tipp: aus Reihe \(z.reihe + 1) \(z.anzahl) nehmen")) } })
            Button(markiert.map { "\(s.reihen[$0.reihe] - $0.ab) nehmen" } ?? String(localized: "Hölzchen wählen")) { nehmen() }
                .buttonStyle(HauptKnopfStil()).disabled(markiert == nil || !kannHandeln(s))
                .padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
        .computerZug(aktiv: s.sieger == nil && s.amZug == 1 && gegnerComputer, id: "\(s.summe)-\(tick)", verzoegerung: 1.0) {
            guard var s2 = spiel, let z = s2.computerZug(fehler: fehler, mit: &zufall) else { return }
            s2.nimm(reihe: z.reihe, anzahl: z.anzahl); spiel = s2; tick += 1; ansage(String(localized: "Computer nimmt \(z.anzahl) aus Reihe \(z.reihe + 1)")); pruefe()
        }
    }

    /// Gegen den Computer nimmt „Zug zurück“ den letzten eigenen Zug samt Antwort zurück; zu zweit den Zug des Vorgängers.
    private func zurueckSpieler(_ s: Hoelzchen) -> Int { gegnerComputer ? 0 : 1 - s.amZug }

    private func kannHandeln(_ s: Hoelzchen) -> Bool { s.sieger == nil && !(s.amZug == 1 && gegnerComputer) }

    private func nehmen() {
        guard var s = spiel, let m = markiert, kannHandeln(s) else { return }
        s.nimm(reihe: m.reihe, anzahl: s.reihen[m.reihe] - m.ab); spiel = s; markiert = nil; tick += 1; pruefe()
    }

    private func pruefe() {
        guard let s = spiel, let w = s.sieger, !gemeldet else { return }
        gemeldet = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            ende(SpielEnde(reihenfolge: [name(w), name(1 - w)], info: String(localized: "\(name(w)) gewinnt") + (tippGenutzt ? " · " + String(localized: "mit Tipp") : "")))
        }
    }
}
#endif
