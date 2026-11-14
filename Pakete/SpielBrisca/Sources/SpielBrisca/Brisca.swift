// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import BriscaKern

@MainActor
public struct BriscaModul: SpielModul {
    public init() {}
    public let id = "brisca"
    public let name = "Brisca"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "suit.spade.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Trumpf stechen, Augen sammeln", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Jeder hat drei Karten, die unterste Karte des Stapels zeigt das Trumpf-Atout. Der Startspieler legt eine Karte, der andere antwortet mit beliebiger Karte. Der Stich geht an die höhere Karte derselben Farbe oder an einen Trumpf. Danach ziehen beide nach, der Stichgewinner zuerst, und er beginnt den nächsten Stich. Die Karten haben Augen: As 11, Drei 10, König 4, Reiter 3, Bube 2, alle anderen 0 (zusammen 120). Reihenfolge: As, Drei, König, Reiter, Bube, Sieben, Sechs, Fünf, Vier, Zwei. Wer am Ende mehr als 60 Augen hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            BriscaSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Hole mit deinen Stichen mehr als 60 der 120 Augen. Wer das schafft, gewinnt.").mitAnleitung([
            .figuren(symbol: "rectangle.stack", titel: "Stich spielen", text: "Du legst eine Karte, der andere antwortet. Die höhere Karte derselben Farbe oder ein Trumpf gewinnt den Stich.", figuren: ["🂡", "🂱"], bewegt: 0),
            .figuren(symbol: "star", titel: "Trumpf und Augen", text: "Die Trumpffarbe zeigt die unterste Karte des Stapels. As zählt 11, Drei 10, König 4, Reiter 3, Bube 2.", figuren: ["🂡", "⭐️"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Über 60 gewinnt", text: "Nach jedem Stich ziehen beide nach. Wer am Ende mehr als 60 Augen hat, gewinnt.", figuren: ["🂡", "🏁"], bewegt: nil),
        ]))
    }
}

struct BriscaKarteView: View {
    let karte: BriscaKarte?
    var atout = false
    var body: some View {
        if let k = karte { SpanischeKarteBild(rang: k.rang, farbe: k.farbe, markiert: atout) } else { KartenPlatz() }
    }
}

struct BriscaSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Brisca
    @State private var schritte = 0
    @State private var meldung: String?
    @State private var stufe = ComputerStufe.gespeichert("brisca")

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Brisca(mit: &g))
    }

    private var unten: Int { teilnehmer.allSatisfy { !$0.computer } ? spiel.amZug : (teilnehmer[0].computer ? 1 : 0) }
    private var computerDran: Bool { teilnehmer[spiel.amZug].computer }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.vorbei ? String(localized: "Spielende") : String(localized: "\(teilnehmer[spiel.amZug].name) ist dran"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "brisca", stufe: $stufe) }
                    Button("Tipp", systemImage: "lightbulb") { tipp() }.disabled(computerDran || spiel.vorbei || spiel.amZug != unten)
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: $0 == 0 ? .red : .blue, wert: "\(spiel.augen[$0])") }, aktiv: "\(spiel.amZug)").padding(.horizontal, Theme.seitenRand)
            HStack(spacing: 6) { ForEach(0..<spiel.haende[1 - unten].count, id: \.self) { _ in RoundedRectangle(cornerRadius: 6).fill(Color.appFlaeche.gradient).frame(width: 30, height: 42) } }
            SpielfeldKarte {
                HStack(spacing: 20) {
                    VStack(spacing: Design.Abstand.xs) {
                        BriscaKarteView(karte: spiel.stapel.isEmpty ? nil : spiel.atoutKarte, atout: true)
                        Text("Atout · \(spiel.stapel.count) im Stapel").font(.caption2).foregroundStyle(.secondary)
                    }
                    BriscaKarteView(karte: spiel.ausgespielt[1 - unten])
                    BriscaKarteView(karte: spiel.ausgespielt[unten])
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, Theme.seitenRand)
            if let m = meldung { Text(m).font(.subheadline.weight(.semibold)) }
            if let l = spiel.letzterStich { Text("Letzter Stich: \(teilnehmer[l.gewinner].name) (\(l.karten.reduce(0) { $0 + $1.augen }) Augen)").font(.footnote).foregroundStyle(.secondary) }
            Spacer(minLength: 0)
            if spiel.vorbei { Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand) }
            else if computerDran { Text("\(teilnehmer[spiel.amZug].name) spielt …").foregroundStyle(.secondary) }
            else { Text("Wähle eine Karte.").font(.subheadline).foregroundStyle(.secondary) }
            HStack(spacing: 10) {
                ForEach(spiel.haende[unten].indices, id: \.self) { i in
                    BriscaKarteView(karte: spiel.haende[unten][i]).onTapGesture { if spiel.amZug == unten, !computerDran, spiel.spiele(unten, karte: i) { meldung = nil; schritte += 1 } }
                    .accessibilityAddTraits(.isButton)   // G1
                    .accessibilityHint(Text("Doppeltippen, um die Karte zu spielen"))
                }
            }.padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("brisca", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task(id: "\(schritte)") {
            guard !spiel.vorbei, computerDran else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            let s = spiel.amZug
            spiel.spiele(s, karte: BriscaComputer.wahl(spiel, spieler: s, stufe: stufe.rawValue)); schritte += 1
        }
    }

    private func tipp() {
        guard !spiel.vorbei, !computerDran else { return }
        let i = BriscaComputer.wahl(spiel, spieler: spiel.amZug, stufe: 3)
        let k = spiel.haende[spiel.amZug][i]
        meldung = String(localized: "Tipp: Spiele Karte \(i + 1), Rang \(k.rang), Farbe \(k.farbe + 1).")
        UIAccessibility.post(notification: .announcement, argument: meldung)
    }
    private func beenden() {
        let s = spiel.sieger ?? 0
        ende(SpielEnde(reihenfolge: [teilnehmer[s].name, teilnehmer[1 - s].name], punkte: [spiel.augen[s], spiel.augen[1 - s]].map(String.init),
                       info: spiel.sieger == nil ? String(localized: "Unentschieden") : String(localized: "\(teilnehmer[s].name) gewinnt")))
    }
}
#endif
