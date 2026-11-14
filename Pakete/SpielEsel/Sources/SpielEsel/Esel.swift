// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import EselKern

@MainActor
public struct EselModul: SpielModul {
    public init() {}
    public let id = "esel"
    public let name = "Esel"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.limette
    public let symbol = "hand.raised.fill"
    public let spielerzahl = 3...5
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Wer als Letzter die Hand auflegt, ist der Esel", farbe: farbe, spieler: 3...5, computerErlaubt: true,
                            regeln: "Jeder hat vier Karten. Im Spiel sind so viele Ränge wie Spieler (zum Beispiel Asse, Könige und Damen), jeder in allen vier Farben. Alle reichen gleichzeitig eine Karte an den Nachbarn weiter und bekommen eine vom anderen Nachbarn. Ziel: vier gleiche Karten sammeln. Wer sie hat, legt sofort die Hand auf den Tisch. Sobald jemand seine Hand aufgelegt hat, müssen alle anderen so schnell wie möglich folgen, indem sie den Knopf „Hand drauf!“ drücken. Der Letzte, der noch nicht aufgelegt hat, ist der Esel. Hier spielt immer nur ein Mensch, alle anderen Plätze übernimmt der Computer.",
                            einzelText: "Du gegen die Computer.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            EselSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Sammle vier gleiche Karten und lege die Hand auf. Wer als Letzter aufliegt, ist der Esel.").mitAnleitung([
            .figuren(symbol: "arrow.left.arrow.right", titel: "Karten weiterreichen", text: "Alle reichen gleichzeitig eine Karte an den Nachbarn weiter und bekommen eine vom anderen.", figuren: ["🂡", "🂱", "🂻"], bewegt: 0),
            .figuren(symbol: "square.stack.3d.up", titel: "Vier Gleiche", text: "Sammle vier gleiche Karten. Wer sie hat, legt sofort die Hand auf den Tisch.", figuren: ["🂡", "🂡", "🂡", "🂡"], bewegt: nil),
            .figuren(symbol: "hand.tap", titel: "Hand drauf!", text: "Sobald jemand aufgelegt hat, drücken alle schnell „Hand drauf!“. Der Letzte ist der Esel.", figuren: ["✋", "🫏"], bewegt: nil),
        ]))
    }
}

struct EselSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Esel
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var gemeldet = false
    @State private var gewaehlt: Int?
    @State private var griffGeplant = false
    @State private var stufe = ComputerStufe.gespeichert("esel")
    private var reaktionszeit: ClosedRange<Double> { switch stufe { case .leicht: 1.6...3.0; case .mittel: 1.1...2.2; case .schwer: 0.7...1.4 } }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Esel(spieler: teilnehmer.count, mit: &g))
    }

    private var n: Int { teilnehmer.count }
    private let ich = 0

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Runde \(spiel.runde + 1)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    ComputerStufePicker(spiel: "esel", stufe: $stufe)
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(1..<n, id: \.self) { i in
                        VStack(spacing: Design.Abstand.xs) {
                            Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                            HStack(spacing: -22) { ForEach(0..<4, id: \.self) { _ in KartenFlaeche(groesse: .klein, seite: .ruecken) { EmptyView() } } }
                            if let p = spiel.griffe.firstIndex(of: i) { Label("\(p + 1).", systemImage: "hand.raised.fill").font(.caption.bold()).foregroundStyle(.green) }
                            else if spiel.vorbei { Label("Esel", systemImage: "exclamationmark.triangle.fill").font(.caption.bold()).foregroundStyle(.red) }
                            else { Text(" ").font(.caption) }
                        }
                        .padding(8).background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(Color.kartenGrund))
                    }
                }.padding(.horizontal, Theme.seitenRand)
            }
            Spacer(minLength: 0)
            Text(status).font(.headline).foregroundStyle(spiel.jemandHatVierling ? Color.red : Color.primary).multilineTextAlignment(.center).padding(.horizontal)
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                ForEach(spiel.haende[ich].indices, id: \.self) { i in
                    SkatKartenBild(spiel.haende[ich][i], groesse: .normal, gewaehlt: gewaehlt == i)
                        .onTapGesture { if !spiel.jemandHatVierling { gewaehlt = i } }
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
                }
            }
            Group {
                if spiel.jemandHatVierling && !spiel.vorbei {
                    Button { greife(ich) } label: { Text("Hand drauf!").font(.title2.bold()).frame(maxWidth: .infinity, minHeight: 56) }
                        .buttonStyle(HauptKnopfStil()).disabled(spiel.griffe.contains(ich))
                } else if !spiel.vorbei {
                    Button("Karte weitergeben") { reiche() }.buttonStyle(HauptKnopfStil()).disabled(gewaehlt == nil)
                }
            }.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("esel", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: spiel.jemandHatVierling) { _, v in if v { starteComputerGriffe() } }
        .onChange(of: spiel.vorbei) { _, v in if v { meldeEnde() } }
    }

    private var status: String {
        if spiel.vorbei { return spiel.esel == ich ? String(localized: "Du bist der Esel! 🫏") : String(localized: "\(teilnehmer[spiel.esel ?? 0].name) ist der Esel!") }
        if spiel.jemandHatVierling { return spiel.griffe.isEmpty ? String(localized: "Vier Gleiche! Schnell: Hand drauf!") : String(localized: "Schnell, die anderen sind schon dran!") }
        return String(localized: "Wähle eine Karte, die du nach links weitergibst. Sammle vier gleiche.")
    }

    private func reiche() {
        guard let g = gewaehlt, !spiel.jemandHatVierling else { return }
        var auswahl = [g]
        for i in 1..<n { auswahl.append(spiel.computerAbgabe(i, mit: &zufall)) }
        spiel.reiche(auswahl); gewaehlt = nil
        if spiel.hatVierling(ich) { /* der Mensch darf sofort greifen */ }
    }

    private func greife(_ s: Int) { spiel.greife(s) }

    /// Die Computer reagieren nacheinander mit zufälligen Reaktionszeiten.
    private func starteComputerGriffe() {
        guard !griffGeplant else { return }
        griffGeplant = true
        var zeiten: [(Int, Double)] = []
        for i in 1..<n { zeiten.append((i, spiel.hatVierling(i) ? 0.6 : Double.random(in: reaktionszeit, using: &zufall))) }
        zeiten.sort { $0.1 < $1.1 }
        Task {
            var vergangen = 0.0
            for (i, t) in zeiten {
                try? await Task.sleep(nanoseconds: UInt64(max(0, t - vergangen) * 1e9)); vergangen = t
                if spiel.vorbei { return }
                if spiel.griffe.isEmpty && !spiel.hatVierling(i) { continue }
                spiel.greife(i)
            }
            // Wer den Computern nicht folgt, hat nach einer Gnadenfrist verloren
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if !spiel.vorbei, !spiel.griffe.contains(ich) { /* Mensch ist zu langsam: er bleibt als Letzter übrig */ }
        }
    }

    private func meldeEnde() {
        guard !gemeldet, let e = spiel.esel else { return }
        gemeldet = true
        let reihenfolge = spiel.griffe + [e]
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            ende(SpielEnde(reihenfolge: reihenfolge.map { teilnehmer[$0].name }, plaetze: reihenfolge.indices.map { $0 + 1 },
                           info: String(localized: "\(teilnehmer[e].name) ist der Esel")))
        }
    }
}
#endif
