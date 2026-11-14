// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpitSpeedKern

@MainActor
public struct SpitSpeedModul: SpielModul {
    public init() {}
    public let id = "spitspeed"
    public let name = "Spit"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "bolt.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Schnell Karten loswerden, ohne Reihenfolge", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Beide spielen gleichzeitig, es gibt keine Reihenfolge. Jeder hat fünf Karten in der Hand und einen Nachziehstapel. In der Mitte liegen zwei Stapel. Du darfst eine Karte aus der Hand auf einen Mittelstapel legen, wenn sie genau einen Wert höher oder niedriger ist (As liegt zwischen König und Zwei, es geht rundum). Nach jeder gelegten Karte füllt sich deine Hand wieder auf fünf auf. Wer zuerst keine Karten mehr hat, gewinnt. Kann keiner mehr legen, werden in der Mitte automatisch zwei neue Karten aufgedeckt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SpitSpeedSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Werde so schnell wie möglich alle Karten los, indem du eins höher oder niedriger anlegst. Wer zuerst keine hat, gewinnt.").mitAnleitung([
            .figuren(symbol: "bolt.fill", titel: "Gleichzeitig", text: "Beide spielen gleichzeitig, es gibt keine Reihenfolge.", figuren: ["🂡", "🂱"], bewegt: nil),
            .figuren(symbol: "plusminus", titel: "Eins höher oder tiefer", text: "Lege eine Handkarte auf einen Mittelstapel, wenn sie genau einen Wert höher oder niedriger ist. Das Ass liegt zwischen König und Zwei.", figuren: ["6️⃣", "7️⃣"], bewegt: 0),
            .figuren(symbol: "flag.checkered", titel: "Zuerst leer", text: "Die Hand füllt sich auf fünf auf. Wer zuerst keine Karten mehr hat, gewinnt.", figuren: ["🂡", "🏁"], bewegt: nil),
        ]))
    }
}

struct SpitSpeedSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: SpitSpeed
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var stufe = ComputerStufe.gespeichert("spitspeed")
    @State private var gewaehlt: Int?
    @State private var schritte = 0

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: SpitSpeed(mit: &g))
    }

    /// Wer den Computer spielt: bei Mensch gegen Computer der Computer, sonst niemand (zwei Menschen am selben Gerät).
    private var computerSpieler: Int? { teilnehmer[1].computer ? 1 : (teilnehmer[0].computer ? 0 : nil) }
    private var unten: Int { computerSpieler == 0 ? 1 : 0 }
    private var verzoegerung: Double { switch stufe { case .leicht: 3.0; case .mittel: 1.8; case .schwer: 1.0 } }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.gewinner != nil ? String(localized: "Spielende") : String(localized: "Schnell legen!"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if computerSpieler != nil { ComputerStufePicker(spiel: "spitspeed", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: $0 == 0 ? .red : .blue, wert: "\(spiel.restkarten($0))") }, aktiv: "").padding(.horizontal, Theme.seitenRand)
            Text("Zahl: Karten übrig").font(.caption2).foregroundStyle(.tertiary)
            reihe(oben: true)
            SpielfeldKarte {
                HStack(spacing: 28) {
                    ForEach(0..<2, id: \.self) { m in
                        Button { mitteTippen(m) } label: {
                            SkatKartenBild(spiel.mitte[m].last, groesse: .gross, gewaehlt: false)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(gewaehlt != nil && spiel.kannLegen(unten, hand: gewaehlt!, auf: m) ? Color.appFlaeche : .clear, lineWidth: 4))
                        }.buttonStyle(.plain)
                    }
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
            if spiel.gewinner != nil { Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand) }
            else if spiel.festgefahren { Text("Beide sitzen fest – neue Karten kommen …").font(.subheadline).foregroundStyle(.secondary) }
            reihe(oben: false).padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("spitspeed", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: spiel.gewinner != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .computerZug(aktiv: spiel.gewinner == nil && (computerSpieler != nil || spiel.festgefahren), id: "\(schritte)", verzoegerung: spiel.festgefahren ? 1.4 : verzoegerung, tempoFolgen: false) { tick() }
    }

    private func reihe(oben: Bool) -> some View {
        let p = oben ? 1 - unten : unten
        let sichtbar = !oben || computerSpieler == nil
        return HStack(spacing: -14) {
            ForEach(spiel.haende[p].indices, id: \.self) { i in
                SkatKartenBild(sichtbar ? spiel.haende[p][i] : nil, groesse: oben ? .klein : .normal, gewaehlt: !oben && gewaehlt == i,
                               gedimmt: sichtbar && !(0..<2).contains { spiel.kannLegen(p, hand: i, auf: $0) })
                    .rotationEffect(.degrees(oben ? 180 : 0))
                    .onTapGesture { handTippen(p, i) }
                    .accessibilityAddTraits(.isButton)   // G1
                    .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
            }
        }.padding(.top, 8)
    }

    private func handTippen(_ p: Int, _ i: Int) {
        guard spiel.gewinner == nil, computerSpieler != p else { return }
        let passt = (0..<2).filter { spiel.kannLegen(p, hand: i, auf: $0) }
        if passt.count == 1 { if spiel.lege(p, hand: i, auf: passt[0]) { gewaehlt = nil; schritte += 1 } }
        else if passt.count == 2 { gewaehlt = i }
        else { gewaehlt = nil }
    }

    private func mitteTippen(_ m: Int) {
        guard let i = gewaehlt else { return }
        if spiel.lege(unten, hand: i, auf: m) { gewaehlt = nil; schritte += 1 }
    }

    private func tick() {
        if spiel.festgefahren { spiel.neuAufdecken(mit: &zufall) }
        else if let c = computerSpieler, let z = SpitSpeedComputer.zug(spiel, spieler: c, stufe: stufe.rawValue) { spiel.lege(c, hand: z.hand, auf: z.mitte) }
        schritte += 1
    }

    private func beenden() {
        guard let w = spiel.gewinner else { return }
        ende(SpielEnde(reihenfolge: [teilnehmer[w].name, teilnehmer[1 - w].name], punkte: [0, spiel.restkarten(1 - w)].map(String.init), info: String(localized: "\(teilnehmer[w].name) gewinnt")))
    }
}
#endif
