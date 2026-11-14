// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import PatolliKern

@MainActor
public struct PatolliModul: SpielModul {
    public init() {}
    public let id = "patolli"
    public let name = "Patolli"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "circle.dotted"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Bohnen werfen, Steine um den Ring führen", farbe: farbe, spieler: 2...2, computerErlaubt: true, wuerfelWahl: true, wuerfelTexte: .bohnen,
                            regeln: "Patolli ist ein uraltes Brettspiel aus Mexiko. Jeder hat vier Steine und wirft fünf Bohnen, von denen jede eine markierte Seite hat. So viele Bohnen markiert zeigen, so viele Felder darfst du ziehen. Fünf markierte Bohnen sind zehn Felder und ein zusätzlicher Wurf, keine markierte Bohne bedeutet Aussetzen. Ein Stein kommt vom Haus auf das Startfeld deiner Farbe und läuft einmal um den Ring ins Ziel. Landest du auf einem gegnerischen Stein, muss er zurück ins Haus. Auf den sicheren Feldern (Startfelder und die Felder mit Raute) kann niemand geschlagen werden und der Gegner darf dort nicht landen. Ein Sonnenfeld gibt dir einen zusätzlichen Wurf. Wer zuerst alle vier Steine im Ziel hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            PatolliSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitZiel("Bringe als Erster alle vier Steine einmal um den Ring ins Ziel.").mitAnleitung([
            .figuren(symbol: "dice", titel: "Bohnen werfen", text: "Du wirfst fünf Bohnen. So viele markierte Seiten oben liegen, so viele Felder ziehst du.", figuren: ["🫘", "🫘", "🫘"], bewegt: nil),
            .figuren(symbol: "arrow.triangle.2.circlepath", titel: "Schlagen", text: "Dein Stein läuft einmal um den Ring. Landest du auf einem gegnerischen Stein, muss er zurück ins Haus.", figuren: ["🔴", "🔵", "💥"], bewegt: nil),
            .figuren(symbol: "shield", titel: "Sichere Felder", text: "Auf Startfeldern und Rautenfeldern kann niemand geschlagen werden. Wer zuerst alle vier Steine ins Ziel bringt, gewinnt.", figuren: ["🔴", "🛡️"], bewegt: nil),
        ]))
    }
}

struct PatolliSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    var quelle: WuerfelQuelle = .app
    @State private var bohnenEingabe = Array(repeating: false, count: 5)
    @State private var spiel = Patolli()
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var schritte = 0
    @State private var tipp: Int?
    @State private var stufe = ComputerStufe.gespeichert("patolli")

    private var computerDran: Bool { teilnehmer[spiel.amZug].computer }
    private let farben: [Color] = [.red, .blue]

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.gewinner != nil ? String(localized: "Spielende") : String(localized: "\(teilnehmer[spiel.amZug].name) ist dran"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "patolli", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: farben[$0], wert: "\(spiel.stand[$0].filter { $0 == Patolli.ring }.count)/4") }, aktiv: "\(spiel.amZug)").padding(.horizontal, Theme.seitenRand)
            Text("Steine im Ziel").font(.caption2).foregroundStyle(.tertiary)
            SpielfeldKarte { ring.aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth) }.padding(.horizontal, Theme.seitenRand)
            hausLeiste
            Spacer(minLength: 0)
            aktion.padding(.horizontal, Theme.seitenRand).padding(.bottom, 12)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("patolli", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.gewinner != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .computerZug(aktiv: computerDran && spiel.gewinner == nil, id: "\(schritte)") { computerSchritt() }
    }

    private var ring: some View {
        GeometryReader { geo in
            let r = min(geo.size.width, geo.size.height) / 2 - 18
            let mitte = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            ZStack {
                ForEach(0..<Patolli.ring, id: \.self) { f in
                    let w = Double(f) / Double(Patolli.ring) * 2 * .pi - .pi / 2
                    feldView(f).position(x: mitte.x + r * cos(w), y: mitte.y + r * sin(w))
                }
                VStack(spacing: 6) {
                    HStack(spacing: Design.Abstand.xs) {
                        ForEach(0..<5, id: \.self) { i in
                            Capsule().fill(spiel.bohnen.indices.contains(i) && spiel.bohnen[i] ? Color.appFlaeche : Color.secondary.opacity(0.35)).frame(width: 12, height: 22)
                        }
                    }
                    if let w = spiel.wurf { Text("\(w) Felder").font(.headline) } else { Text(" ").font(.headline) }
                }
            }
        }
    }

    private func feldView(_ f: Int) -> some View {
        let da = (0..<2).flatMap { p in spiel.stand[p].indices.filter { let s = spiel.stand[p][$0]; return s >= 0 && s < Patolli.ring && spiel.feld(p, s) == f }.map { (p, $0) } }
        return Button {
            guard !computerDran, spiel.wurf != nil, let (p, i) = da.first(where: { $0.0 == spiel.amZug && spiel.zuege.contains($0.1) }) else { return }
            _ = p; zieh(i)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6).fill(Patolli.sonne(f) ? Color.yellow.opacity(0.35) : (Patolli.sicher(f) ? Color.green.opacity(0.25) : Color(.tertiarySystemFill)))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Patolli.startFeld.contains(f) ? farben[f == 0 ? 0 : 1] : .clear, lineWidth: 2))
                if Patolli.sonne(f) { Image(systemName: "sun.max.fill").font(.caption2).foregroundStyle(.orange) }
                else if Patolli.sicher(f) { Image(systemName: "diamond.fill").font(.caption2).foregroundStyle(.green) }
                HStack(spacing: -4) { ForEach(da.indices, id: \.self) { k in Circle().fill(farben[da[k].0]).overlay(Circle().stroke(da[k].0 == spiel.amZug && tipp == da[k].1 ? Color.yellow : .white, lineWidth: da[k].0 == spiel.amZug && tipp == da[k].1 ? 3 : 1.5)).frame(width: 16, height: 16) } }
            }.frame(width: 28, height: 28)
        }.buttonStyle(.plain)
        .accessibilityLabel(Text("Feld \(f + 1)\(Patolli.sonne(f) ? String(localized: ", Sonne") : (Patolli.sicher(f) ? String(localized: ", sicher") : ""))\(da.isEmpty ? "" : ", " + da.map { teilnehmer[$0.0].name }.joined(separator: String(localized: " und ")))"))
        .accessibilityValue(da.contains(where: { $0.0 == spiel.amZug && spiel.zuege.contains($0.1) }) && !computerDran ? Text("spielbar") : Text(verbatim: ""))
    }

    private var hausLeiste: some View {
        HStack(spacing: Design.Abstand.xl) {
            ForEach(0..<2, id: \.self) { p in
                HStack(spacing: Design.Abstand.xs) {
                    Text("Haus").font(.caption2).foregroundStyle(.secondary)
                    ForEach(spiel.stand[p].indices.filter { spiel.stand[p][$0] == -1 }, id: \.self) { i in
                        Button { if p == spiel.amZug, !computerDran, spiel.zuege.contains(i) { zieh(i) } } label: {
                            Circle().fill(farben[p]).frame(width: 20, height: 20)
                                .accessibilityLabel(Text("Stein im Haus von \(teilnehmer[p].name)"))
                                .accessibilityValue(p == spiel.amZug && tipp == i ? Text("Tipp") : (p == spiel.amZug && spiel.zuege.contains(i) && !computerDran ? Text("spielbar") : Text(verbatim: "")))
                                .overlay(Circle().stroke(p == spiel.amZug && tipp == i ? Color.yellow : (p == spiel.amZug && spiel.zuege.contains(i) && !computerDran ? Color.primary : .clear), lineWidth: p == spiel.amZug && tipp == i ? 4 : 2))
                        }.buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder private var aktion: some View {
        if spiel.gewinner != nil { Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil()) }
        else if computerDran { Text("\(teilnehmer[spiel.amZug].name) spielt …").foregroundStyle(.secondary) }
        else if spiel.wurf == nil, quelle == .echt {
            VStack(spacing: 10) {
                Text("Wie liegen deine Bohnen? Tippe die markierten an.").font(.subheadline).foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { i in
                        Button { bohnenEingabe[i].toggle() } label: {
                            Capsule().fill(bohnenEingabe[i] ? Color.appFlaeche : Color.secondary.opacity(0.35)).frame(width: 28, height: 52)
                                .frame(minWidth: Theme.tapSize, minHeight: Theme.tapSize)
                        }.buttonStyle(.plain)
                        .accessibilityLabel(Text("Bohne \(i + 1) von 5")).accessibilityValue(bohnenEingabe[i] ? Text("markiert") : Text("nicht markiert"))
                    }
                }
                Button("Übernehmen") { if spiel.setzeWurf(bohnenEingabe) { schritte += 1 }; bohnenEingabe = Array(repeating: false, count: 5) }.buttonStyle(HauptKnopfStil())
            }
        }
        else if spiel.wurf == nil { Button("Bohnen werfen") { spiel.wuerfle(mit: &zufall); schritte += 1 }.buttonStyle(HauptKnopfStil()) }
        else {
            VStack(spacing: Design.Abstand.s) {
                Text("Tippe einen Stein, der ziehen soll.").font(.subheadline).foregroundStyle(.secondary)
                Button { tipp = PatolliComputer.wahl(spiel, stufe: 3); if let t = tipp { let s = spiel.stand[spiel.amZug][t]; UIAccessibility.post(notification: .announcement, argument: s < 0 ? String(localized: "Tipp: Stein \(t + 1) aus dem Haus setzen.") : String(localized: "Tipp: Stein \(t + 1) auf Feld \(spiel.feld(spiel.amZug, s) + 1) ziehen.")) } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(spiel.zuege.isEmpty)
            }
        }
    }

    private func zieh(_ i: Int) { tipp = nil; if spiel.ziehe(i) { schritte += 1 } }

    private func computerSchritt() {
        if spiel.wurf == nil { spiel.wuerfle(mit: &zufall) }
        else if let i = PatolliComputer.wahl(spiel, stufe: stufe.rawValue) { spiel.ziehe(i) }
        schritte += 1
    }

    private func beenden() {
        guard let w = spiel.gewinner else { return }
        ende(SpielEnde(reihenfolge: [teilnehmer[w].name, teilnehmer[1 - w].name], punkte: [4, spiel.stand[1 - w].filter { $0 == Patolli.ring }.count].map(String.init), info: String(localized: "\(teilnehmer[w].name) gewinnt")))
    }
}
#endif
