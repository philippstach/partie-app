// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import KartenduellKern

@MainActor
public struct KartenduellModul: SpielModul {
    public init() {}
    public let id = "kartenduell"
    public let name = "Kartenduell"
    public let gattung = Gattung.karten
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "rectangle.on.rectangle.angled"
    public let spielerzahl = 2...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Die höhere Karte gewinnt", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Die Karten werden gleichmäßig verteilt. Beide Spieler decken gleichzeitig ihre oberste Karte auf. Wer die höhere Karte hat (Ass ist am höchsten), bekommt beide Karten unter seinen Stapel. Bei zwei gleichen Karten gibt es einen Streit: Jeder legt noch drei Karten verdeckt dazu und deckt dann eine weitere auf; die höhere Karte nimmt den ganzen Haufen. Wer alle Karten hat, gewinnt. Dauert es zu lange, gewinnt nach 400 Runden, wer mehr Karten hat. Tippe auf die Karten, um aufzudecken, oder schalte „Automatisch“ ein.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            KartenduellSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Gewinne durch die höhere Karte alle Karten des Gegners. Wer am Ende alle hat, gewinnt.").mitAnleitung([
            .figuren(symbol: "rectangle.on.rectangle", titel: "Aufdecken", text: "Beide decken gleichzeitig die oberste Karte auf. Die höhere (Ass am höchsten) gewinnt beide.", figuren: ["🂡", "🂱"], bewegt: nil),
            .figuren(symbol: "equal.circle", titel: "Streit", text: "Bei zwei gleichen Karten legt jeder drei verdeckt dazu und deckt noch eine auf. Die höhere nimmt alles.", figuren: ["🂡", "🂡", "⚔️"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Alle Karten", text: "Wer alle Karten hat, gewinnt. Tippe auf die Karten oder schalte „Automatisch“ ein.", figuren: ["🂡", "🏆"], bewegt: nil),
        ]))
    }
}

private func kartenName(_ w: Int) -> String { w <= 10 ? "\(w)" : ["B", "D", "K", "A"][w - 11] }

struct DuellKarte: View {
    let wert: Int?
    let farbeIndex: Int
    var body: some View {
        KartenFlaeche(groesse: .riesig, seite: wert == nil ? .ruecken : .vorn,
                      beschriftung: wert.map { Text(verbatim: Kartensprache.name(rang: kartenName($0), symbol: ["♣", "♦", "♠", "♥"][farbeIndex % 4])) } ?? Text(verbatim: "")) {
            if let w = wert, KartenSatz.istGewaehlt {   // gewählter Kartensatz (Blatt 17/19): Kartenbild und Figuren vom Satz
                KartenIndex(rang: kartenName(w), zeichen: ["♣", "♦", "♠", "♥"][farbeIndex % 4],
                            farbe: KartenStil.aktuell.farbe(rot: farbeIndex % 4 == 1 || farbeIndex % 4 == 3),
                            breite: KartenGroesse.riesig.masse.width, hoehe: KartenGroesse.riesig.masse.height)
            } else if let w = wert {
                VStack(spacing: 0) {
                    Text(verbatim: kartenName(w)).font(.system(.largeTitle, design: Design.zahlDesign).weight(.bold))
                    Text(verbatim: ["♣", "♦", "♠", "♥"][farbeIndex % 4]).font(.largeTitle)
                }.foregroundStyle(farbeIndex % 4 == 1 || farbeIndex % 4 == 3 ? Color.red : Color.primary)
            }
        }
    }
}

struct KartenduellSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Kartenduell
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var automatisch = false
    @State private var gemeldet = false
    @State private var farben = [0, 1]

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _spiel = State(initialValue: Kartenduell(mit: &g))
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Runde \(spiel.runden)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            Spacer(minLength: 0)
            ForEach([1, 0], id: \.self) { s in
                VStack(spacing: 6) {
                    HStack { Text(verbatim: teilnehmer[s].name).font(.headline); Spacer(); Label("\(spiel.stapel[s].count)", systemImage: "rectangle.stack").font(.headline) }
                        .padding(.horizontal, 40)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(verbatim: teilnehmer[s].name))
                        .accessibilityValue(Text("\(spiel.stapel[s].count) Karten übrig"))
                    DuellKarte(wert: spiel.offen[s], farbeIndex: farben[s])
                }
                if s == 1 {
                    Text(spiel.streit > 0 ? "Streit! Gleichstand – nächste Karte entscheidet." : (spiel.letzterGewinner.map { String(localized: "\(teilnehmer[$0].name) nimmt die Karten") } ?? " "))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(spiel.streit > 0 ? Color.red : Color.appFlaeche).frame(minHeight: 22)
                }
            }
            Spacer(minLength: 0)
            Toggle("Automatisch", isOn: $automatisch).padding(.horizontal, 40)
            Button("Aufdecken") { zug() }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("kartenduell", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.sieger != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .task(id: "\(automatisch)-\(spiel.runden)") {
            guard automatisch, spiel.sieger == nil else { return }
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            zug()
        }
    }

    private func zug() {
        guard spiel.sieger == nil else { return }
        farben = [Int.random(in: 0..<4), Int.random(in: 0..<4)]
        spiel.aufdecken(mit: &zufall)
        if let w = spiel.sieger, !gemeldet {
            gemeldet = true; automatisch = false
            Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                ende(SpielEnde(reihenfolge: [teilnehmer[w].name, teilnehmer[1 - w].name], punkte: ["\(spiel.stapel[w].count)", "\(spiel.stapel[1 - w].count)"]))
            }
        }
    }
}
#endif
