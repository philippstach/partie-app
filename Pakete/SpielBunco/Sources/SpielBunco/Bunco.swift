// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import BuncoKern

@MainActor
public struct BuncoModul: SpielModul {
    public init() {}
    public let id = "bunco"
    public let name = "Bunco"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "dice.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Sechs Runden, drei Würfel", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            wuerfelWahl: true, regeln: "Es gibt sechs Runden. In Runde 1 zählt die Eins, in Runde 2 die Zwei und so weiter. Du würfelst drei Würfel: Jeder Würfel mit der Rundenzahl gibt 1 Punkt. Drei davon sind ein Bunco und bringen 21 Punkte, drei gleiche andere Würfel ein Mini-Bunco mit 5 Punkten. Hast du gepunktet, würfelst du weiter, sonst ist der andere dran. Wer zuerst 21 Punkte hat, gewinnt die Runde. Wer nach sechs Runden mehr Runden gewonnen hat, gewinnt das Spiel.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            BuncoSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitZiel("Erreiche in jeder Runde als Erster 21 Punkte. Wer nach sechs Runden die meisten Runden gewonnen hat, siegt.").mitAnleitung([
            .figuren(symbol: "1.circle", titel: "Rundenzahl würfeln", text: "Es gibt sechs Runden. In Runde 1 zählt die Eins, in Runde 2 die Zwei und so weiter. Du würfelst drei Würfel.", figuren: ["🎲", "🎲", "🎲"], bewegt: nil),
            .figuren(symbol: "plus.circle", titel: "Bunco", text: "Jeder Würfel mit der Rundenzahl gibt 1 Punkt. Drei davon sind ein Bunco mit 21 Punkten, drei andere Gleiche ein Mini-Bunco mit 5.", figuren: ["1️⃣", "1️⃣", "1️⃣"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Runden gewinnen", text: "Hast du gepunktet, würfelst du weiter. Wer zuerst 21 hat, gewinnt die Runde, wer nach sechs Runden die meisten gewonnen hat, das Spiel.", figuren: ["🎲", "🏆"], bewegt: nil),
        ]))
    }
}

struct BuncoSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    @State private var eingabe: Int?
    @State private var spiel = Bunco()
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var schritte = 0

    private var computerDran: Bool { teilnehmer[spiel.amZug].computer }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Runde \(spiel.runde) von 6 · Ziel: \(spiel.ziel)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: $0 == 0 ? .red : .blue, wert: "\(spiel.punkte[$0]) · \(spiel.rundenSiege[$0])") }, aktiv: "\(spiel.amZug)").padding(.horizontal, Theme.seitenRand)
            Text("Punkte in dieser Runde · gewonnene Runden").font(.caption2).foregroundStyle(.tertiary)
            HStack(spacing: Design.Abstand.s) {
                ForEach(0..<6, id: \.self) { r in
                    Circle().fill(r < spiel.rundenVerlauf.count ? (spiel.rundenVerlauf[r] == 0 ? Color.red : Color.blue) : Color.secondary.opacity(0.25))
                        .overlay(Circle().stroke(r + 1 == spiel.runde ? Color.primary : .clear, lineWidth: 2)).frame(width: 18, height: 18)
                        .overlay(Text("\(r + 1)").font(.caption2.weight(.bold)).foregroundStyle(.white))
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Runde \(r + 1)"))
                        .accessibilityValue(r < spiel.rundenVerlauf.count ? Text(verbatim: teilnehmer[spiel.rundenVerlauf[r]].name) : Text(r + 1 == spiel.runde ? "Läuft" : "Offen"))
                }
            }
            SpielfeldKarte {
                VStack(spacing: 14) {
                    HStack(spacing: 14) {
                        if spiel.letzterWurf.isEmpty { ForEach(0..<3, id: \.self) { _ in Image(systemName: "die.face.1").font(.system(size: 54)).foregroundStyle(.tertiary) } }   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                        else {
                            ForEach(0..<3, id: \.self) { i in
                                let w = spiel.letzterWurf[i]
                                WuerfelBild(w).font(.system(size: 54)).foregroundStyle(w == spiel.ziel ? Color.appFlaeche : Color.secondary)   // design:spielinhalt (feste Großdarstellung von Spielmaterial, kein Fließtext)
                            }
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(spiel.letzterWurf.count == 3 ? Text("Würfel: \(spiel.letzterWurf[0]), \(spiel.letzterWurf[1]), \(spiel.letzterWurf[2])") : Text("Noch nicht gewürfelt"))
                    Text(text).font(.headline).frame(minHeight: 24)
                }.frame(maxWidth: .infinity)
            }.padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
            aktion.padding(.horizontal, Theme.seitenRand).padding(.bottom, 12)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("bunco", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .echteWuerfelEingabe(anzahl: $eingabe) { schritt(augen: $0) }
        .computerZug(aktiv: computerDran && !spiel.vorbei && spiel.rundeBeendetVon == nil, id: "\(schritte)") { schritt() }
    }

    private var text: String {
        if let r = spiel.rundeBeendetVon { return String(localized: "\(teilnehmer[r].name) gewinnt die Runde!") }
        switch spiel.letzteWertung {
        case .bunco: return "Bunco! +21"
        case .miniBunco: return "Mini-Bunco! +5"
        case .punkte(let n): return "+\(n)"
        case .nichts: return String(localized: "Kein Treffer")
        case nil: return " "
        }
    }

    @ViewBuilder private var aktion: some View {
        if spiel.vorbei { Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil()) }
        else if spiel.rundeBeendetVon != nil { Button("Nächste Runde") { spiel.naechsteRunde(); schritte += 1 }.buttonStyle(HauptKnopfStil()) }
        else if computerDran { Text("\(teilnehmer[spiel.amZug].name) würfelt …").foregroundStyle(.secondary) }
        else { Button("Würfeln") { if quelle == .echt { eingabe = 3 } else { schritt() } }.buttonStyle(HauptKnopfStil()).beimSchuetteln(aktiv: quelle == .app) { schritt() } }
    }

    private func schritt(augen: [Int]) {
        _ = spiel.wuerfle(augen: augen)
        schritte += 1
    }

    private func schritt() {
        spiel.wuerfle(mit: &zufall)
        schritte += 1
    }

    private func beenden() {
        let s = spiel.sieger ?? 0
        ende(SpielEnde(reihenfolge: [teilnehmer[s].name, teilnehmer[1 - s].name], punkte: [spiel.rundenSiege[s], spiel.rundenSiege[1 - s]].map(String.init),
                       info: spiel.sieger == nil ? String(localized: "Unentschieden") : String(localized: "\(teilnehmer[s].name) gewinnt")))
    }
}
#endif
