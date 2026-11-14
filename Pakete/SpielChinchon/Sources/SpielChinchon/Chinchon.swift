// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import ChinchonKern

@MainActor
public struct ChinchonModul: SpielModul {
    public init() {}
    public let id = "chinchon"
    public let name = "Chinchón"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "rectangle.stack.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Reihen und Sätze legen, Karten loswerden", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Jeder hat sieben Karten aus einem 40er-Blatt. Du ziehst eine Karte vom Stapel oder die oberste Ablagekarte und legst dann eine Karte ab. Ziel sind Kombinationen: drei oder vier gleiche Zahlen oder Reihen von mindestens drei Karten einer Farbe (7 und 10 sind Nachbarn). Du darfst schließen, wenn nach dem Ablegen die übrigen sieben Karten höchstens 5 Punkte außerhalb von Kombinationen haben (Bilder zählen 10, sonst die Zahl). Der Schließer bekommt seine Restpunkte (bei 0 minus 10), der Gegner seine Restpunkte. Wer 100 Punkte erreicht, scheidet aus. Eine Reihe aus allen sieben Karten (Chinchón) gewinnt sofort.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            ChinchonSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Bilde Kombinationen und schließe mit möglichst wenig Restpunkten. Wer 100 Punkte erreicht, scheidet aus.").mitAnleitung([
            .figuren(symbol: "arrow.down.doc", titel: "Ziehen und ablegen", text: "Du ziehst vom Stapel oder nimmst die oberste Ablagekarte und legst dann eine Karte ab.", figuren: ["🂡", "🂱", "🂻"], bewegt: nil),
            .figuren(symbol: "rectangle.3.group", titel: "Kombinationen", text: "Sammle drei oder vier gleiche Zahlen oder Reihen von mindestens drei Karten einer Farbe.", figuren: ["🂡", "🂡", "🂡"], bewegt: nil),
            .figuren(symbol: "hand.raised", titel: "Schließen", text: "Hast du höchstens 5 Punkte außerhalb von Kombinationen, darfst du schließen. Wer 100 Punkte erreicht, scheidet aus.", figuren: ["🂡", "✋"], bewegt: nil),
        ]))
    }
}

struct ChinKarteView: View {
    let karte: ChinKarte?
    var verdeckt = false
    var gedimmt = false
    var body: some View {
        if verdeckt { KartenFlaeche(groesse: .klein, seite: .ruecken, gedimmt: gedimmt) { EmptyView() } }
        else if let k = karte { SpanischeKarteBild(rang: k.rang, farbe: k.farbe, groesse: .klein, gedimmt: gedimmt) }
        else { KartenPlatz(groesse: .klein) }
    }
}

struct ChinchonSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var partie: ChinchonPartie
    @State private var tipp: Int?   // F4
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var meldung: String?
    @State private var schritte = 0
    @State private var stufe = ComputerStufe.gespeichert("chinchon")

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _partie = State(initialValue: ChinchonPartie(mit: &g))
    }

    private var hand: ChinchonHand { partie.hand }
    private var unten: Int { teilnehmer.allSatisfy { !$0.computer } ? hand.amZug : (teilnehmer[0].computer ? 1 : 0) }
    private var computerDran: Bool { teilnehmer[hand.amZug].computer }
    private var meinZug: Bool { !hand.vorbei && !computerDran && hand.amZug == unten }
    private var offenIdx: Set<Int> { Set(Chinchon.rest(hand.haende[unten]).offen) }
    private var sortiert: [Int] { hand.haende[unten].indices.sorted { (hand.haende[unten][$0].farbe, hand.haende[unten][$0].folge) < (hand.haende[unten][$1].farbe, hand.haende[unten][$1].folge) } }
    private var schliessErlaubt: Set<Int> { hand.hatGezogen ? Set(Chinchon.schliessKarten(hand.haende[unten])) : [] }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: hand.vorbei ? String(localized: "Hand beendet") : String(localized: "\(teilnehmer[hand.amZug].name) ist dran"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "chinchon", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: $0 == 0 ? .red : .blue, wert: "\(partie.strafe[$0])") }, aktiv: "\(hand.amZug)").padding(.horizontal, Theme.seitenRand)
            Text("Strafpunkte (bei 100 ist Schluss)").font(.caption2).foregroundStyle(.tertiary)
            HStack(spacing: -22) { ForEach(0..<hand.haende[1 - unten].count, id: \.self) { _ in ChinKarteView(karte: nil, verdeckt: true) } }
            SpielfeldKarte {
                HStack(spacing: Design.Abstand.xl) {
                    Button { if meinZug, !hand.hatGezogen { partie.zug { $0.ziehe(vonAblage: false) }; schritte += 1 } } label: {
                        VStack { ChinKarteView(karte: nil, verdeckt: true); Text("Stapel \(hand.stapel.count)").font(.caption2) }
                    }.buttonStyle(.plain)
                    Button { if meinZug, !hand.hatGezogen { partie.zug { $0.ziehe(vonAblage: true) }; schritte += 1 } } label: {
                        VStack { ChinKarteView(karte: hand.ablage.last); Text("Ablage").font(.caption2) }
                    }.buttonStyle(.plain)
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, Theme.seitenRand)
            if !hand.vorbei, hand.haende[unten].count >= 7 { Text("Offene Punkte: \(Chinchon.rest(hand.haende[unten]).punkte) (Schließen ab höchstens 5)").font(.caption).foregroundStyle(.secondary) }
            if let m = meldung { Text(m).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center).padding(.horizontal) }
            Spacer(minLength: 0)
            HStack(spacing: Design.Abstand.m) {
                aktion
                if meinZug, !hand.vorbei {
                    Button { if hand.hatGezogen { tipp = ChinchonComputer.ablegen(partie.hand, stufe: 3).0; tippAnsage() } else { meldung = ChinchonComputer.ziehenVonAblage(hand, stufe: 3) ? String(localized: "Tipp: Nimm die Karte von der Ablage.") : String(localized: "Tipp: Zieh vom Stapel."); UIAccessibility.post(notification: .announcement, argument: meldung) } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                }
            }.padding(.horizontal, Theme.seitenRand)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(sortiert, id: \.self) { i in
                        VStack(spacing: Design.Abstand.xs) {
                            ChinKarteView(karte: hand.haende[unten][i], gedimmt: !offenIdx.contains(i) && hand.haende[unten].count == 7)
                                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == i ? 1 : 0))
                                .onTapGesture { if meinZug, hand.hatGezogen { tipp = nil; ablegen(i, schliessen: false) } }
                                .accessibilityAddTraits(.isButton)   // G1
                                .accessibilityHint(Text("Doppeltippen, um die Karte abzulegen"))
                                .accessibilityValue(tipp == i ? Text("Tipp") : Text(verbatim: ""))
                            if schliessErlaubt.contains(i), meinZug {
                                Button("Schließen") { ablegen(i, schliessen: true) }.font(.caption2.weight(.bold)).nebenKnopf().tint(Color.appFlaeche).controlSize(.mini)
                            }
                        }
                    }
                }.padding(.horizontal, Theme.seitenRand)
            }.padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("chinchon", $partie)
        .weicheAnimation(bei: [partie.hand.amZug, partie.hand.stapel.count, partie.hand.ablage.count, partie.strafe[0] + partie.strafe[1]])
        .spielHaptik(zug: [partie.hand.amZug, partie.hand.stapel.count, partie.hand.ablage.count, partie.strafe[0] + partie.strafe[1]], erfolg: partie.gewinner != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task(id: "\(schritte)") { await computerZug() }
    }

    @ViewBuilder private var aktion: some View {
        if partie.gewinner != nil { Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil()) }
        else if hand.vorbei {
            VStack(spacing: 6) {
                Text("\(teilnehmer[hand.schliesser!].name) schließt. Punkte: \(hand.strafe[0]) : \(hand.strafe[1])").font(.subheadline.weight(.semibold))
                Button("Nächste Hand") { partie.handAbschliessen(mit: &zufall); meldung = nil; schritte += 1 }.buttonStyle(HauptKnopfStil())
            }
        } else if computerDran { Text("\(teilnehmer[hand.amZug].name) spielt …").foregroundStyle(.secondary) }
        else { Text(hand.hatGezogen ? "Tippe eine Karte zum Ablegen." : "Ziehe vom Stapel oder von der Ablage.").font(.subheadline).foregroundStyle(.secondary) }
    }

    /// F4/G1: Tipp auch hörbar.
    private func tippAnsage() {
        guard let i = tipp else { return }
        let k = hand.haende[unten][i], pos = (sortiert.firstIndex(of: i) ?? i) + 1
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: Karte \(pos) von \(hand.haende[unten].count) ablegen, Rang \(k.rang), Farbe \(k.farbe + 1)."))
    }

    private func ablegen(_ i: Int, schliessen: Bool) {
        partie.zug { $0.lege(ab: i, schliessen: schliessen) }
        meldung = nil; schritte += 1
    }

    private func computerZug() async {
        guard partie.gewinner == nil, !hand.vorbei, computerDran else { return }
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        guard !Task.isCancelled else { return }
        let von = ChinchonComputer.ziehenVonAblage(hand, stufe: stufe.rawValue)
        partie.zug { $0.ziehe(vonAblage: von) }
        let (i, schl) = ChinchonComputer.ablegen(partie.hand, stufe: stufe.rawValue)
        partie.zug { $0.lege(ab: i, schliessen: schl) }
        meldung = schl ? String(localized: "\(teilnehmer[1 - unten].name) schließt!") : nil
        schritte += 1
    }

    private func beenden() {
        guard let w = partie.gewinner else { return }
        ende(SpielEnde(reihenfolge: [teilnehmer[w].name, teilnehmer[1 - w].name], punkte: [partie.strafe[w], partie.strafe[1 - w]].map(String.init), info: hand.chinchon ? String(localized: "Chinchón!") : String(localized: "\(teilnehmer[w].name) gewinnt")))
    }
}
#endif
