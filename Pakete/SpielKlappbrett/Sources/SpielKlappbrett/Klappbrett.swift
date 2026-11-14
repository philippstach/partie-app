// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import KlappbrettKern

@MainActor
public struct KlappbrettModul: SpielModul {
    public init() {}
    public let id = "klappbrett"
    public let name = "Klappbrett"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "square.split.2x1.fill"
    public let spielerzahl = 1...6
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Würfeln und Zahlen abklappen", farbe: farbe, spieler: 1...6, computerErlaubt: true,
                            wuerfelWahl: true, regeln: "Die Zahlen 1 bis 9 stehen offen. Würfle und klappe offene Zahlen zu, deren Summe genau der Würfelsumme entspricht. Sind 7, 8 und 9 zu, würfelst du nur noch mit einem Würfel. Geht kein Zug mehr, endet deine Runde; die offenen Zahlen zählen als Punkte. Wer die wenigsten Punkte hat, gewinnt. Alle Zahlen zu: „Klappbrett geschafft“ mit null Punkten.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            KlappbrettSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, wuerfelQuelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitZiel("Klappe die Zahlen 1 bis 9 zu. Wer am Ende die wenigsten Punkte aus offenen Zahlen hat, gewinnt.").mitAnleitung(Self.anleitung))
    }
}

struct KlappbrettSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let wuerfelQuelle: WuerfelQuelle

    @State private var dran = 0
    @State private var brett = Klappbrett()
    @State private var gewaehlt: Set<Int> = []
    @State private var punkte: [Int?]
    @State private var hatGewuerfelt = false
    @State private var kein = false
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var echtEingabe = false
    @State private var stufe = ComputerStufe.gespeichert("klappbrett")
    @State private var schritte = 0

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, wuerfelQuelle: WuerfelQuelle) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.wuerfelQuelle = wuerfelQuelle
        _punkte = State(initialValue: Array(repeating: nil, count: teilnehmer.count))
    }

    private var computerDran: Bool { teilnehmer[dran].computer }
    private var summeGewaehlt: Int { gewaehlt.reduce(0, +) }
    private var passt: Bool { hatGewuerfelt && !kein && summeGewaehlt == brett.summe && !gewaehlt.isEmpty }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: teilnehmer[dran].name, linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "klappbrett", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            if teilnehmer.count > 1 {
                SpielerLeiste(eintraege: teilnehmer.enumerated().map { i, t in
                    .init(id: "\(i)", name: t.name, farbe: nil, wert: punkte[i].map(String.init))
                }, aktiv: "\(dran)")
                .padding(.horizontal, Theme.seitenRand)
            }
            SpielfeldKarte {
                VStack(spacing: 14) {
                    HStack(spacing: 6) {
                        ForEach(Klappbrett.zahlen, id: \.self) { z in klappe(z) }
                    }
                    würfelAnzeige
                    Text(hinweis).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(minHeight: 40)
                }
                .padding(.vertical, 14)
            }
            .padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
            hauptknopf
                .padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
                .frame(maxWidth: Theme.wideColumnWidth)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("klappbrett", $brett)
        .weicheAnimation(bei: brett)
        .spielHaptik(zug: brett, erfolg: (brett.geschafft))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .computerZug(aktiv: computerDran, id: schritte, verzoegerung: 1.0) { computerSchritt() }
    }

    private func computerSchritt() {
        if kein { rundeEnde() }
        else if !hatGewuerfelt { wuerfeln() }
        else if let z = KlappbrettComputer.zug(brett, stufe: stufe.rawValue) { gewaehlt = Set(z); zuklappen() }
        schritte += 1
    }

    private var hinweis: LocalizedStringKey {
        if kein { return "Kein Zug möglich. Deine Runde endet." }
        if !hatGewuerfelt { return "Würfle!" }
        return "Wähle Zahlen mit Summe \(brett.summe)."
    }

    private func klappe(_ z: Int) -> some View {
        let offen = brett.offen.contains(z)
        let an = gewaehlt.contains(z)
        return Button {
            guard hatGewuerfelt, offen, !kein, !computerDran else { return }
            if an { gewaehlt.remove(z) } else { gewaehlt.insert(z) }
        } label: {
            Text("\(z)")
                .font(.system(.title3, design: Design.zahlDesign).weight(.bold).monospacedDigit())
                .frame(maxWidth: .infinity, minHeight: 64)
                .foregroundStyle(offen ? (an ? Color.white : Color.primary) : Color.secondary.opacity(0.4))
                .background(offen ? (an ? Color.appFlaeche : Color.appFlaeche.opacity(0.12)) : Color(.tertiarySystemFill),
                            in: .rect(cornerRadius: Theme.feldRadius))
                .offset(y: offen ? 0 : 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(offen ? Text("\(z)") : Text("\(z), zugeklappt"))
        .accessibilityAddTraits(an ? .isSelected : [])
    }

    private var würfelAnzeige: some View {
        HStack(spacing: Design.Abstand.m) {
            ForEach(Array(brett.wurf.enumerated()), id: \.offset) { _, a in
                WuerfelBild(a).font(.system(size: 52)).foregroundStyle(Color.appFlaeche)  // design:spielinhalt
            }
            if brett.wurf.isEmpty { Image(systemName: "dice").font(.system(size: 52)).foregroundStyle(.tertiary) }  // design:spielinhalt
        }
        .frame(minHeight: 60)
        .accessibilityLabel(brett.wurf.isEmpty ? Text("Noch nicht gewürfelt") : Text("Gewürfelt: \(brett.wurf.map(String.init).joined(separator: " + ")), Summe \(brett.summe)"))
    }

    @ViewBuilder private var hauptknopf: some View {
        if computerDran {
            Text("\(teilnehmer[dran].name) spielt …").foregroundStyle(.secondary).frame(minHeight: 50)
        } else if kein {
            Button("Weiter") { rundeEnde() }.buttonStyle(HauptKnopfStil())
        } else if hatGewuerfelt {
            Button("Zuklappen") { zuklappen() }.buttonStyle(HauptKnopfStil()).disabled(!passt)
        } else {
            Button("Würfeln") { wuerfeln() }.buttonStyle(HauptKnopfStil()).beimSchuetteln { wuerfeln() }
        }
    }

    private func wuerfeln() {
        let moeglich = brett.wuerfeln(mit: &zufall)
        hatGewuerfelt = true
        gewaehlt = []
        if !moeglich { kein = true }
    }

    private func zuklappen() {
        guard brett.klappen(Array(gewaehlt)) else { return }
        gewaehlt = []; hatGewuerfelt = false
        if brett.geschafft { rundeEnde() }
    }

    private func rundeEnde() {
        punkte[dran] = brett.punkte
        kein = false; hatGewuerfelt = false; gewaehlt = []
        brett = Klappbrett()
        if dran + 1 < teilnehmer.count { dran += 1; return }
        let p = punkte.map { $0 ?? 0 }
        let rang = klappbrettRangfolge(punkte: p)
        let ordnung = teilnehmer.indices.sorted { (rang[$0], $0) < (rang[$1], $1) }
        ende(SpielEnde(reihenfolge: ordnung.map { teilnehmer[$0].name }, punkte: ordnung.map { "\(p[$0])" },
                       plaetze: ordnung.map { rang[$0] },
                       info: p.contains(0) ? String(localized: "Klappbrett geschafft!") : nil))
    }
}
#endif
