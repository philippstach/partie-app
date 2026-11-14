// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import EscobaKern

@MainActor
public struct EscobaModul: SpielModul {
    public init() {}
    public let id = "escoba"
    public let name = "Escoba"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "sparkles"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Mach 15 und fege den Tisch", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Gespielt wird mit 40 Karten (Rang 1–10, Bube 8, Reiter 9, König 10). Jeder hat drei Handkarten, vier Karten liegen offen. Spiele eine Handkarte und sammle damit Tischkarten ein, sodass die Summe genau 15 ergibt. Geht das, musst du einsammeln; sonst legst du die Karte ab. Fegst du den Tisch leer, bekommst du eine Escoba (1 Punkt, nicht beim letzten Zug). Am Ende zählen: Escobas, Sieben der Münzen, meiste Karten, meiste Münzen und meiste Siebener (je 1 Punkt). Die Resttischkarten gehen an den, der zuletzt eingesammelt hat.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            EscobaSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Sammle Tischkarten mit der Summe 15 und hole die meisten Punkte. Es gewinnt, wer am Ende mehr Punkte hat.").mitAnleitung([
            .figuren(symbol: "plus", titel: "Summe 15", text: "Spiele eine Handkarte und sammle Tischkarten ein, sodass die Summe genau 15 ergibt.", figuren: ["7️⃣", "8️⃣"], bewegt: nil),
            .figuren(symbol: "sparkles", titel: "Escoba", text: "Fegst du den Tisch leer, bekommst du eine Escoba und einen Punkt. Geht das Einsammeln, musst du es tun.", figuren: ["🧹", "🂡"], bewegt: nil),
            .figuren(symbol: "list.number", titel: "Punkte am Ende", text: "Es zählen Escobas, die Sieben der Münzen, die meisten Karten, Münzen und Siebener.", figuren: ["🏆", "🂡"], bewegt: nil),
        ]))
    }
}

struct EscobaKarteView: View {
    let karte: EscobaKarte
    var gewaehlt = false
    var body: some View { SpanischeKarteBild(rang: karte.rang, farbe: karte.farbe, gewaehlt: gewaehlt) }
}

struct EscobaSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Escoba
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var hand: Int?
    @State private var wahl: Set<Int> = []
    @State private var meldung: String?
    @State private var schritte = 0
    @State private var stufe = ComputerStufe.gespeichert("escoba")

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Escoba(mit: &g))
    }

    private var computerDran: Bool { teilnehmer[spiel.amZug].computer }
    private var unten: Int { teilnehmer.allSatisfy({ !$0.computer }) ? spiel.amZug : (teilnehmer[0].computer ? 1 : 0) }
    private var summe: Int { wahl.reduce(0) { $0 + spiel.tisch[$1].wert } + (hand.map { spiel.haende[spiel.amZug][$0].wert } ?? 0) }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.vorbei ? String(localized: "Spielende") : String(localized: "\(teilnehmer[spiel.amZug].name) ist dran"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "escoba", stufe: $stufe) }
                    Button("Tipp", systemImage: "lightbulb") { tipp() }.disabled(computerDran || spiel.vorbei)
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: $0 == 0 ? .red : .blue, wert: "\(spiel.gewonnen[$0].count) · E\(spiel.escobas[$0])") }, aktiv: "\(spiel.amZug)").padding(.horizontal, Theme.seitenRand)
            Text("Gegner: \(spiel.haende[1 - unten].count) Karten · Stapel: \(spiel.stapel.count)").font(.footnote).foregroundStyle(.secondary)
            SpielfeldKarte {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 58))], spacing: Design.Abstand.s) {
                    ForEach(spiel.tisch.indices, id: \.self) { i in
                        EscobaKarteView(karte: spiel.tisch[i], gewaehlt: wahl.contains(i))
                            .onTapGesture { tippeTisch(i) }
                            .accessibilityAddTraits(.isButton)   // G1
                            .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
                    }
                }.frame(maxWidth: .infinity, minHeight: 100)
            }.padding(.horizontal, Theme.seitenRand)
            if let m = meldung { Text(m).font(.subheadline.weight(.semibold)) }
            if hand != nil { Text("Summe: \(summe) von 15").font(.headline) }
            Spacer(minLength: 0)
            aktion.padding(.horizontal, Theme.seitenRand)
            HStack(spacing: Design.Abstand.s) {
                ForEach(spiel.haende[unten].indices, id: \.self) { i in
                    EscobaKarteView(karte: spiel.haende[unten][i], gewaehlt: hand == i && unten == spiel.amZug)
                        .onTapGesture { tippeHand(i) }
                        .accessibilityAddTraits(.isButton)   // G1
                        .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
                }
            }.padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("escoba", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task(id: "\(spiel.amZug)-\(schritte)") {
            guard !spiel.vorbei, computerDran else { return }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            let (i, f) = EscobaComputer.wahl(spiel, stufe: stufe.rawValue)
            let karte = spiel.haende[spiel.amZug][i]
            meldung = f == nil ? String(localized: "\(teilnehmer[spiel.amZug].name) legt \(karte.rang) ab.") : String(localized: "\(teilnehmer[spiel.amZug].name) sammelt mit der \(karte.rang) ein.")
            spiel.spiele(hand: i, fang: f); schritte += 1
        }
    }

    @ViewBuilder private var aktion: some View {
        if spiel.vorbei {
            Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil())
        } else if computerDran {
            Text("\(teilnehmer[spiel.amZug].name) spielt …").foregroundStyle(.secondary)
        } else if let h = hand {
            let karte = spiel.haende[spiel.amZug][h]
            let moeglich = spiel.faenge(karte)
            if moeglich.isEmpty {
                Button("Ablegen") { spielen(nil) }.buttonStyle(HauptKnopfStil())
            } else {
                Button("Einsammeln") { spielen(Array(wahl)) }.buttonStyle(HauptKnopfStil()).disabled(summe != 15)
            }
        } else { Text("Wähle eine Handkarte.").font(.subheadline).foregroundStyle(.secondary) }
    }

    private func tipp() {
        guard !computerDran, !spiel.vorbei else { return }
        let (i, f) = EscobaComputer.wahl(spiel, stufe: 3)
        hand = i; wahl = Set(f ?? [])
        meldung = f == nil ? String(localized: "Tipp: Lege Handkarte \(i + 1) ab.") : String(localized: "Tipp: Nimm mit Handkarte \(i + 1) die \((f ?? []).count) markierten Tischkarten.")
        UIAccessibility.post(notification: .announcement, argument: meldung)
    }
    private func tippeHand(_ i: Int) {
        guard !computerDran, !spiel.vorbei, unten == spiel.amZug else { return }
        hand = hand == i ? nil : i; wahl = []; meldung = nil
    }
    private func tippeTisch(_ i: Int) {
        guard hand != nil, !computerDran else { return }
        if wahl.contains(i) { wahl.remove(i) } else { wahl.insert(i) }
    }
    private func spielen(_ fang: [Int]?) {
        guard let h = hand else { return }
        if spiel.spiele(hand: h, fang: fang) { hand = nil; wahl = []; meldung = nil; schritte += 1 }
    }
    private func beenden() {
        let w = [spiel.wertung(0), spiel.wertung(1)]
        let s = spiel.sieger
        let reihenfolge = s == 1 ? [teilnehmer[1].name, teilnehmer[0].name] : [teilnehmer[0].name, teilnehmer[1].name]
        let punkte = s == 1 ? [w[1].summe, w[0].summe] : [w[0].summe, w[1].summe]
        ende(SpielEnde(reihenfolge: reihenfolge, punkte: punkte.map(String.init), info: s == nil ? String(localized: "Unentschieden") : String(localized: "\(teilnehmer[s!].name) gewinnt")))
    }
}
#endif
