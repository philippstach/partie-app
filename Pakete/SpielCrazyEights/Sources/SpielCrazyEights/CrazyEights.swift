// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import CrazyEightsKern
import SpielHilfen

@MainActor
public struct CrazyEightsModul: SpielModul {
    public init() {}
    public let id = "crazyeights"
    public let name = "Crazy Eights"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "8.circle.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Farbe oder Zahl bedienen, Achter sind Joker", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Jeder bekommt sieben Karten. Du legst eine Karte auf den Ablagestapel, die in Farbe oder Zahl zur obersten Karte passt. Achter passen immer: Damit wünschst du dir eine Farbe. Hast du nichts Passendes, ziehst du bis zu drei Karten und musst dann aussetzen, wenn immer noch nichts passt. Wer zuerst keine Karten mehr hat, gewinnt und bekommt die Punkte der Karten des Gegners (Achter 50, Bild 10, Ass 1, sonst die Zahl).",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            CrazyEightsSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Werde deine Karten als Erster los. Dafür bekommst du die Punkte der Karten des Gegners.").mitAnleitung([
            .figuren(symbol: "rectangle.on.rectangle", titel: "Farbe oder Zahl", text: "Lege eine Karte, die in Farbe oder Zahl zur obersten Karte passt.", figuren: ["🂡", "🂱"], bewegt: 0),
            .figuren(symbol: "8.circle", titel: "Achter sind Joker", text: "Achter passen immer, und du wünschst dir eine Farbe.", figuren: ["8️⃣", "🌈"], bewegt: nil),
            .figuren(symbol: "tray.and.arrow.down", titel: "Ziehen", text: "Passt nichts, ziehst du bis zu drei Karten. Wer zuerst keine Karten mehr hat, gewinnt.", figuren: ["🂡", "📥"], bewegt: nil),
        ]))
    }
}

struct CrazyEightsSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: CrazyEights
    @State private var tipp: Int?   // F4: vorgeschlagene Handkarte
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var stufe = ComputerStufe.gespeichert("crazyeights")
    @State private var wunschFuer: Int?
    @State private var meldung: String?
    @State private var schritte = 0

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: CrazyEights(mit: &g))
    }

    private var unten: Int { teilnehmer.allSatisfy { !$0.computer } ? spiel.amZug : (teilnehmer[0].computer ? 1 : 0) }
    private var computerDran: Bool { teilnehmer[spiel.amZug].computer }
    private var meinZug: Bool { spiel.gewinner == nil && !computerDran && spiel.amZug == unten }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.gewinner != nil ? String(localized: "Spielende") : String(localized: "\(teilnehmer[spiel.amZug].name) ist dran"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "crazyeights", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: $0 == 0 ? .red : .blue, wert: "\(spiel.haende[$0].count)") }, aktiv: "\(spiel.amZug)").padding(.horizontal, Theme.seitenRand)
            Text("Zahl: Karten in der Hand").font(.caption2).foregroundStyle(.tertiary)
            HStack(spacing: -28) { ForEach(0..<min(spiel.haende[1 - unten].count, 12), id: \.self) { _ in SkatKartenBild(nil, groesse: .klein) } }
            SpielfeldKarte {
                HStack(spacing: Design.Abstand.xl) {
                    Button { if meinZug, spiel.darfZiehen { spiel.ziehe(mit: &zufall); schritte += 1 } } label: {
                        VStack(spacing: Design.Abstand.xs) { SkatKartenBild(nil); Text("Stapel \(spiel.stapel.anzahl)").font(.caption2).foregroundStyle(.secondary) }
                    }.buttonStyle(.plain)
                    VStack(spacing: Design.Abstand.xs) {
                        SkatKartenBild(spiel.oben)
                        HStack(spacing: Design.Abstand.xs) {
                            Text("Farbe:").font(.caption2).foregroundStyle(.secondary)
                            Text(verbatim: spiel.gewuenschteFarbe.symbol).font(.headline).foregroundStyle(spiel.gewuenschteFarbe.rot ? .red : .primary)
                        }
                    }
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, Theme.seitenRand)
            if let m = meldung { Text(m).font(.subheadline.weight(.semibold)) }
            Spacer(minLength: 0)
            HStack(spacing: Design.Abstand.m) {
                aktion
                if meinZug, spiel.gewinner == nil, !spiel.spielbar.isEmpty {
                    Button { tipp = spiel.spielbar.first; tippAnsage() } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)   // F4
                }
            }.padding(.horizontal, Theme.seitenRand)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -10) {
                    ForEach(spiel.haende[unten].indices, id: \.self) { i in
                        SkatKartenBild(spiel.haende[unten][i], gedimmt: meinZug && !spiel.spielbar.contains(i))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == i ? 1 : 0))
                            .onTapGesture { tipp = nil; tippe(i) }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
                            .accessibilityValue(tipp == i ? Text("Tipp") : Text(verbatim: ""))
                    }
                }.padding(.horizontal, Theme.seitenRand).padding(.top, 12).padding(.bottom, 8)
            }
        }
        .background(Color.seitenGrund)
        .fortsetzbar("crazyeights", $spiel)
        .uebergabeSeite(teilnehmer: teilnehmer, amZug: spiel.amZug, aktiv: spiel.gewinner == nil)   // S1-025: Weitergabe-Bildschirm bei mehreren Menschen
        .weicheAnimation(bei: [spiel.amZug, spiel.gezogen, spiel.haende.reduce(0) { $0 + $1.count }, spiel.stapel.anzahl])
        .spielHaptik(zug: [spiel.amZug, spiel.gezogen, spiel.haende.reduce(0) { $0 + $1.count }, spiel.stapel.anzahl], erfolg: spiel.gewinner != nil)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .confirmationDialog("Welche Farbe wünschst du dir?", isPresented: Binding(get: { wunschFuer != nil }, set: { if !$0 { wunschFuer = nil } }), titleVisibility: .visible) {
            ForEach(SkatKarte.Farbe.allCases, id: \.self) { f in
                Button(f.symbol) { if let i = wunschFuer { lege(i, wunsch: f) }; wunschFuer = nil }
            }
        }
        .computerZug(aktiv: computerDran && spiel.gewinner == nil, id: "\(schritte)") { computerSchritt() }
    }

    @ViewBuilder private var aktion: some View {
        if spiel.gewinner != nil { Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil()) }
        else if computerDran { Text("\(teilnehmer[spiel.amZug].name) spielt …").foregroundStyle(.secondary) }
        else if spiel.mussPassen { Button("Aussetzen") { spiel.passe(); schritte += 1 }.buttonStyle(HauptKnopfStil()) }
        else if spiel.darfZiehen { Button("Karte ziehen (\(CrazyEights.maxZiehen - spiel.gezogen) übrig)") { spiel.ziehe(mit: &zufall); schritte += 1 }.buttonStyle(HauptKnopfStil()) }
        else { Text("Tippe eine passende Karte.").font(.subheadline).foregroundStyle(.secondary) }
    }

    /// F4/G1: Tipp auch hörbar.
    private func tippAnsage() {
        guard let i = tipp else { return }
        let h = spiel.haende[unten]
        UIAccessibility.post(notification: .announcement, argument: String(localized: "Tipp: Karte \(i + 1) von \(h.count), \(h[i].sprechname)."))
    }

    private func tippe(_ i: Int) {
        guard meinZug, spiel.spielbar.contains(i) else { return }
        if spiel.haende[unten][i].wert == 8 { wunschFuer = i } else { lege(i, wunsch: nil) }
    }
    private func lege(_ i: Int, wunsch: SkatKarte.Farbe?) { if spiel.lege(i, wunsch: wunsch) { meldung = nil; schritte += 1 } }

    private func computerSchritt() {
        let name = teilnehmer[spiel.amZug].name
        if let m = CrazyEightsComputer.wahl(spiel, stufe: stufe.rawValue) {
            spiel.lege(m.index, wunsch: m.wunsch)
            meldung = m.wunsch.map { String(localized: "\(name) wünscht sich \($0.symbol)") }
        } else if spiel.darfZiehen { spiel.ziehe(mit: &zufall) }
        else { spiel.passe(); meldung = String(localized: "\(name) setzt aus.") }
        schritte += 1
    }

    private func beenden() {
        guard let w = spiel.gewinner else { return }
        ende(SpielEnde(reihenfolge: [teilnehmer[w].name, teilnehmer[1 - w].name], punkte: [spiel.punkte, 0].map(String.init), info: String(localized: "\(teilnehmer[w].name) gewinnt")))
    }
}
#endif
