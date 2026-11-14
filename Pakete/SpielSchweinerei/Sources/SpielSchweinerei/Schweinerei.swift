// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SchweinereiKern

@MainActor
public struct SchweinereiModul: SpielModul {
    public init() {}
    public let id = "schweinerei"
    public let name = "Schweinerei"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "die.face.4.fill"
    public let spielerzahl = 2...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Riskieren oder sichern", farbe: farbe, spieler: 2...6, computerErlaubt: true,
                            wuerfelWahl: true, regeln: "Du würfelst mit einem Würfel so oft du willst und zählst die Augen zusammen. Wirfst du eine 1, verfallen alle Punkte dieser Runde und der Nächste ist dran. Mit „Sichern“ schreibst du die Runde gut und gibst weiter. Wer zuerst 100 Punkte hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SchweinereiSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitZiel("Sei der Erste mit 100 Punkten. Würfle mutig, aber sichere rechtzeitig, bevor eine 1 alles löscht.").mitAnleitung([
            .figuren(symbol: "die.face.3", titel: "Würfeln und zählen", text: "Du würfelst so oft du willst und zählst die Augen zusammen.", figuren: ["🎲", "➕"], bewegt: nil),
            .figuren(symbol: "1.circle", titel: "Die Eins", text: "Wirfst du eine 1, verfallen alle Punkte dieser Runde und der Nächste ist dran.", figuren: ["1️⃣", "💥"], bewegt: nil),
            .figuren(symbol: "lock", titel: "Sichern", text: "Mit „Sichern“ schreibst du die Runde gut. Wer zuerst das Ziel erreicht (im Mehr-Menü: 50, 100 oder 150 Punkte), gewinnt.", figuren: ["🔒", "💯"], bewegt: nil),
        ]))
    }
}

struct SchweinereiSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    @AppStorage("partie.regeln.schweinerei.ziel") private var ziel = 100
    @State private var spiel: Schweinerei
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var denkt = false
    @State private var tipp: String?

    /// Tipp (wie der mittlere Computer): Wann lohnt sich das Sichern?
    private func tippText() -> String {
        if spiel.runde == 0 { return String(localized: "Tipp: Würfle – es steht noch nichts auf dem Spiel.") }
        return SchweinereiComputer.sichert(spiel, stufe: 3)
            ? String(localized: "Tipp: Sichere jetzt – \(spiel.runde) Punkte sind genug.")
            : String(localized: "Tipp: Würfle weiter – \(spiel.runde) Punkte sind noch zu wenig.")
    }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle
        _spiel = State(initialValue: Schweinerei(spieler: teilnehmer.count, ziel: UserDefaults.standard.integer(forKey: "partie.regeln.schweinerei.ziel") == 0 ? 100 : UserDefaults.standard.integer(forKey: "partie.regeln.schweinerei.ziel")))
    }

    @State private var stufe = ComputerStufe.gespeichert("schweinerei")
    private var unberuehrt: Bool { spiel.letzterWurf == nil && spiel.punkte.allSatisfy { $0 == 0 } && spiel.dran == 0 }
    private var computerDran: Bool { teilnehmer[spiel.dran].computer }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: teilnehmer[spiel.dran].name, linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "schweinerei", stufe: $stufe) }
                    Picker("Ziel", selection: $ziel) {
                        Text("Kurz: 50 Punkte").tag(50); Text("Standard: 100 Punkte").tag(100); Text("Lang: 150 Punkte").tag(150)
                    }
                    .disabled(unberuehrt == false)   // nur vor dem ersten Wurf
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: teilnehmer.indices.map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: Spieler.farbe($0), wert: "\(spiel.punkte[$0])") }, aktiv: "\(spiel.dran)")
                .padding(.horizontal, Theme.seitenRand)
            VStack(spacing: 10) {
                Group { if let w = spiel.letzterWurf { WuerfelBild(w) } else { Image(systemName: "dice").accessibilityLabel(Text("Noch nicht gewürfelt")) } }
                    .font(.system(size: 84)).foregroundStyle(spiel.verfallen ? Color.red : Color.appFlaeche)   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                Text(spiel.verfallen ? "Eine 1! Runde verfallen." : "Runde: \(spiel.runde)").font(.title3.weight(.semibold))
                Text("Ziel: \(spiel.ziel) Punkte").font(.footnote).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 24).card()
            .accessibilityElement(children: .combine)
            .padding(.horizontal, Theme.seitenRand)
            if quelle == .echt, !computerDran, spiel.sieger == nil {
                HStack { ForEach(1...6, id: \.self) { w in Button("\(w)") { setze(w) }.buttonStyle(ZweitKnopfStil()) } }.padding(.horizontal, Theme.seitenRand)
            }
            Spacer(minLength: 0)
            if let s = spiel.sieger {
                Button("Ergebnis") { fertig(s) }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            } else if computerDran {
                Text("\(teilnehmer[spiel.dran].name) denkt nach …").foregroundStyle(.secondary).padding(.bottom, 12)
            } else {
                if let t = tipp { Text(t).font(.footnote).foregroundStyle(.secondary).padding(.horizontal, Theme.seitenRand) }
                HStack(spacing: Design.Abstand.s) {
                    Button { tipp = tippText(); UIAccessibility.post(notification: .announcement, argument: tipp) } label: { Label("Tipp", systemImage: "lightbulb") }
                        .nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    Button("Sichern (\(spiel.runde))") { tipp = nil; spiel.sichern(); pruefe() }.buttonStyle(ZweitKnopfStil()).disabled(spiel.runde == 0)
                    if quelle == .app { Button("Würfeln") { tipp = nil; spiel.wuerfeln(mit: &zufall); pruefe() }.buttonStyle(HauptKnopfStil()).beimSchuetteln { spiel.wuerfeln(mit: &zufall); pruefe() } }
                }.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            }
        }
        .background(Color.seitenGrund)
        .fortsetzbar("schweinerei", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.sieger != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: ziel) { _, neu in
            if unberuehrt, spiel.ziel != neu { spiel = Schweinerei(spieler: teilnehmer.count, ziel: neu) }
        }
        .onAppear { pruefe() }
    }

    private func setze(_ w: Int) { tipp = nil; spiel.setzeWurf(w); pruefe() }

    private func pruefe() {
        guard spiel.sieger == nil, computerDran, !denkt else { return }
        denkt = true
        Task {
            try? await Task.sleep(for: .milliseconds(700))
            denkt = false
            guard spiel.sieger == nil, computerDran else { return }
            if spiel.runde > 0, SchweinereiComputer.sichert(spiel, stufe: stufe.rawValue) { spiel.sichern() } else { spiel.wuerfeln(mit: &zufall) }
            pruefe()
        }
    }

    private func fertig(_ s: Int) {
        let o = teilnehmer.indices.sorted { spiel.punkte[$0] > spiel.punkte[$1] }
        ende(SpielEnde(reihenfolge: o.map { teilnehmer[$0].name }, punkte: o.map { "\(spiel.punkte[$0])" }, info: String(localized: "\(teilnehmer[s].name) gewinnt")))
    }
}
#endif
