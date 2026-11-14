// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import TrucoKern

@MainActor
public struct TrucoModul: SpielModul {
    public init() {}
    public let id = "truco"
    public let name = "Truco"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "flame.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Stechen, bluffen, Einsatz steigern", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Jeder bekommt drei Karten aus einem 40er-Blatt ohne 8 und 9. Es gibt bis zu drei Stiche, wer zwei gewinnt, gewinnt die Hand. Die stärksten Karten sind Schwerter-Ass, Stäbe-Ass, Schwerter-Sieben und Münzen-Sieben, dann alle Dreien, Zweien, die restlichen Asse, Zwölfer, Elfer, Zehner, die übrigen Siebener, Sechser, Fünfer, Vierer. Bei Gleichstand im Stich (Parda) entscheidet der erste Stich. Vor dem ersten Stich kannst du Envido rufen: zwei Karten gleicher Farbe zählen 20 plus ihre Werte (Bilder 0), sonst zählt die höchste Karte; der höhere Wert bekommt 2 Punkte, bei Gleichstand der Startspieler. Mit Truco erhöhst du den Handwert auf 2, der Gegner kann mit Retruco (3) und Vale cuatro (4) antworten oder aufgeben. Wer 15 Punkte hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            TrucoSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Gewinne Stiche und Punkte mit Mut und Bluff. Wer zuerst 15 Punkte hat, gewinnt.").mitAnleitung([
            .figuren(symbol: "rectangle.on.rectangle", titel: "Drei Stiche", text: "Jeder hat drei Karten. Wer zwei Stiche gewinnt, gewinnt die Hand. Die stärksten Karten sind Schwerter-Ass, Stäbe-Ass und die beiden Siebener.", figuren: ["🂡", "🂱", "🂻"], bewegt: nil),
            .figuren(symbol: "megaphone", titel: "Envido", text: "Vor dem ersten Stich kannst du Envido rufen: zwei Karten gleicher Farbe zählen 20 plus ihre Werte.", figuren: ["📣", "🂡"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Truco", text: "Mit Truco erhöhst du den Handwert auf 2, der Gegner antwortet mit Retruco (3) oder Vale cuatro (4) oder gibt auf. Wer 15 Punkte hat, gewinnt.", figuren: ["🂡", "🏁"], bewegt: nil),
        ]))
    }
}

struct TrucoKarteView: View {
    let karte: TrucoKarte?
    var body: some View {
        if let k = karte { SpanischeKarteBild(rang: k.rang, farbe: k.farbe) } else { KartenPlatz() }
    }
}

struct TrucoSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var partie: TrucoPartie
    @State private var tipp: Int?   // F4
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var meldung: String?
    @State private var schritte = 0
    @State private var stufe = ComputerStufe.gespeichert("truco")

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _partie = State(initialValue: TrucoPartie(mit: &g))
    }

    private var hand: TrucoHand { partie.hand }
    /// Der Mensch unten (bei zwei Menschen: der, der gerade handeln muss).
    private var unten: Int {
        if teilnehmer.allSatisfy({ !$0.computer }) { return hand.offen.map { 1 - $0.von } ?? hand.amZug }
        return teilnehmer[0].computer ? 1 : 0
    }
    private var computerAmZug: Bool {
        if let o = hand.offen { return teilnehmer[1 - o.von].computer }
        return teilnehmer[hand.amZug].computer
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Hand: \(hand.einsatz) Punkte"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "truco", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: $0 == 0 ? .red : .blue, wert: "\(partie.punkte[$0])") }, aktiv: "\(hand.amZug)").padding(.horizontal, Theme.seitenRand)
            HStack(spacing: 6) { ForEach(0..<hand.haende[1 - unten].count, id: \.self) { _ in RoundedRectangle(cornerRadius: 6).fill(Color.appFlaeche.gradient).frame(width: 30, height: 42) } }
            SpielfeldKarte {
                VStack(spacing: 10) {
                    HStack(spacing: 20) { TrucoKarteView(karte: hand.ausgespielt[1 - unten]); TrucoKarteView(karte: hand.ausgespielt[unten]) }
                    HStack(spacing: Design.Abstand.s) {
                        ForEach(hand.stiche.indices, id: \.self) { i in
                            Image(systemName: hand.stiche[i].map { $0 == unten ? "checkmark.circle.fill" : "xmark.circle.fill" } ?? "equal.circle.fill")
                                .foregroundStyle(hand.stiche[i].map { $0 == unten ? Color.green : Color.red } ?? Color.gray)
                        }
                    }.frame(height: 22)
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, Theme.seitenRand)
            if !hand.vorbei { Text("Dein Envido: \(hand.envidoWert(unten))").font(.caption).foregroundStyle(.secondary) }
            if let m = meldung { Text(m).font(.subheadline.weight(.semibold)).multilineTextAlignment(.center).padding(.horizontal) }
            Spacer(minLength: 0)
            HStack(spacing: Design.Abstand.m) {
                aktionen
                if !hand.vorbei, hand.amZug == unten, hand.offen == nil, !computerAmZug {
                    Button { switch TrucoComputer.aktion(hand, spieler: unten, stufe: 3) {
                        case .spiele(let i): tipp = i; UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: Spiele Karte \(i + 1) von \(hand.haende[unten].count)."))
                        case .ruf(let a): meldung = String(localized: "Tipp: ") + anrufText(a, von: teilnehmer[unten].name); UIAccessibility.post(notification: .announcement, argument: meldung)
                        case .passen: meldung = String(localized: "Tipp: Passen."); UIAccessibility.post(notification: .announcement, argument: meldung)
                        } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                }
            }.padding(.horizontal, Theme.seitenRand)
            HStack(spacing: 10) {
                ForEach(hand.haende[unten].indices, id: \.self) { i in
                    TrucoKarteView(karte: hand.haende[unten][i]).overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == i ? 1 : 0)).onTapGesture { tipp = nil; spiele(i) }
                    .accessibilityAddTraits(.isButton)   // G1
                    .accessibilityValue(tipp == i ? Text("Tipp") : Text(verbatim: ""))
                    .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
                }
            }.padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("truco", $partie)
        .weicheAnimation(bei: [partie.punkte[0], partie.punkte[1], partie.hand.stiche.count, partie.hand.einsatz, partie.hand.amZug, partie.hand.haende.reduce(0) { $0 + $1.count }])
        .spielHaptik(zug: [partie.punkte[0], partie.punkte[1], partie.hand.stiche.count, partie.hand.einsatz, partie.hand.amZug, partie.hand.haende.reduce(0) { $0 + $1.count }], erfolg: partie.gewinner != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task(id: "\(schritte)") { await computerZug() }
    }

    @ViewBuilder private var aktionen: some View {
        if partie.gewinner != nil {
            Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil())
        } else if hand.vorbei {
            Button("Nächste Hand") { partie.handAbschliessen(mit: &zufall); meldung = nil; schritte += 1 }.buttonStyle(HauptKnopfStil())
        } else if let o = hand.offen, !computerAmZug {
            VStack(spacing: Design.Abstand.s) {
                Text(anrufText(o.anruf, von: teilnehmer[o.von].name)).font(.headline)
                HStack {
                    Button("Annehmen") { antworte(true) }.buttonStyle(HauptKnopfStil())
                    Button(o.anruf == .envido ? "Nein" : "Aufgeben", role: .destructive) { antworte(false) }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
            }
        } else if computerAmZug {
            Text("\(teilnehmer[hand.offen.map { 1 - $0.von } ?? hand.amZug].name) denkt …").foregroundStyle(.secondary)
        } else {
            HStack {
                if hand.kannRufen(unten, .envido) { Button("Envido") { ruf(.envido) }.lineLimit(1).minimumScaleFactor(0.7).nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge) }
                ForEach(2...4, id: \.self) { st in
                    if hand.kannRufen(unten, .truco(stufe: st)) { Button(st == 2 ? "Truco" : (st == 3 ? "Retruco" : "Vale cuatro")) { ruf(.truco(stufe: st)) }.lineLimit(1).minimumScaleFactor(0.7).nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge) }
                }
                Button("Passen") { partie.hand.passe(unten); schritte += 1 }.lineLimit(1).minimumScaleFactor(0.7).nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            }
        }
    }

    private func anrufText(_ a: TrucoAnruf, von: String) -> String {
        switch a {
        case .envido: return String(localized: "\(von): Envido!")
        case .truco(let st): return String(localized: "\(von): \(st == 2 ? String(localized: "Truco") : (st == 3 ? String(localized: "Retruco") : String(localized: "Vale cuatro")))!")
        }
    }

    private func spiele(_ i: Int) { if partie.hand.spiele(unten, karte: i) { meldung = nil; schritte += 1 } }
    private func ruf(_ a: TrucoAnruf) { if partie.hand.rufe(unten, a) { schritte += 1 } }
    private func antworte(_ ja: Bool) { if partie.hand.antworte(unten, annehmen: ja) { meldung = nil; schritte += 1 } }

    private func computerZug() async {
        guard partie.gewinner == nil, !hand.vorbei, computerAmZug else { return }
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        guard !Task.isCancelled else { return }
        if let o = hand.offen {
            let s = 1 - o.von, ja = TrucoComputer.antwort(hand, spieler: s, stufe: stufe.rawValue)
            partie.hand.antworte(s, annehmen: ja)
            meldung = ja ? String(localized: "\(teilnehmer[s].name) nimmt an.") : String(localized: "\(teilnehmer[s].name) lehnt ab.")
        } else {
            let s = hand.amZug
            switch TrucoComputer.aktion(hand, spieler: s, stufe: stufe.rawValue) {
            case .spiele(let i): partie.hand.spiele(s, karte: i)
            case .ruf(let a): partie.hand.rufe(s, a); meldung = anrufText(a, von: teilnehmer[s].name)
            case .passen: partie.hand.passe(s)
            }
        }
        schritte += 1
    }

    private func beenden() {
        guard let w = partie.gewinner else { return }
        ende(SpielEnde(reihenfolge: [teilnehmer[w].name, teilnehmer[1 - w].name], punkte: [partie.punkte[w], partie.punkte[1 - w]].map(String.init), info: String(localized: "\(teilnehmer[w].name) gewinnt")))
    }
}
#endif
