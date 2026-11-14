// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import HalmaKern

@MainActor
public struct HalmaModul: SpielModul {
    public init() {}
    public let id = "halma"
    public let name = "Halma"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "star.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Hüpfen ins Zielfeld", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Jeder hat zehn Steine in seiner Ecke. Ziel: alle Steine in die gegenüberliegende Ecke bringen. Du ziehst einen Stein ein Feld in beliebiger Richtung oder springst über einen angrenzenden Stein (auch mehrfach hintereinander in einer Kette) auf das freie Feld dahinter. Wer zuerst das gegnerische Lager besetzt, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            HalmaSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Bringe als Erster alle deine zehn Steine in die gegenüberliegende Ecke.").mitAnleitung([
            .figuren(symbol: "arrow.up.right", titel: "Ein Feld ziehen", text: "Du ziehst einen Stein ein Feld in beliebiger Richtung.", figuren: ["🔴", "▫️"], bewegt: 0),
            .figuren(symbol: "arrow.up.forward", titel: "Springen", text: "Oder springe über einen angrenzenden Stein auf das freie Feld dahinter, auch mehrfach in einer Kette.", figuren: ["🔴", "🔵", "▫️"], bewegt: 0),
            .figuren(symbol: "flag.checkered", titel: "Ziel", text: "Bringe alle zehn Steine in die gegenüberliegende Ecke. Wer zuerst dort ist, gewinnt.", figuren: ["🔴", "🏁"], bewegt: nil),
        ]))
    }
}

struct HalmaSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel = Halma()
    @State private var gewaehlt: Int?
    @State private var denkt = false
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var verlauf: [Halma] = []
    @State private var tipp: (Int, Int)?
    @State private var tippRechnet = false
    @State private var stufe = ComputerStufe.gespeichert("halma")
    private var suchtiefe: Int { switch stufe { case .leicht: 1; case .mittel: 2; case .schwer: 3 } }
    private var suchbreite: Int { switch stufe { case .leicht: 12; case .mittel: 10; case .schwer: 8 } }

    private func name(_ s: Int) -> String { teilnehmer[s - 1].name }
    @Environment(\.farbenUnterscheidbar) private var farbenUnterscheidbar   // G2: Orange = Kreis, Blau = Quadrat
    private var computerDran: Bool { teilnehmer[spiel.dran - 1].computer }
    private var ziele: Set<Int> { gewaehlt.map { spiel.ziele(von: $0) } ?? [] }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: name(spiel.dran), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "halma", stufe: $stufe) }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [1, 2].map { .init(id: "\($0)", name: name($0), farbe: $0 == 1 ? .orange : .blue) }, aktiv: "\(spiel.dran)").padding(.horizontal, Theme.seitenRand)
            SpielfeldKarte {
                Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                    ForEach(0..<8, id: \.self) { z in GridRow { ForEach(0..<8, id: \.self) { s in feld(z * 8 + s) } } }
                }
            }.padding(.horizontal, Theme.seitenRand)
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && !denkt, tippMoeglich: !computerDran && !spiel.vorbei, rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            Text("Zug \(spiel.zuege / 2 + 1) von \(Halma.zeitlimit / 2) – dann zählt der Fortschritt").font(.caption).foregroundStyle(.tertiary)
            Text(denkt ? "\(name(spiel.dran)) denkt nach …" : "\(name(spiel.dran)) ist dran – bringe alle Steine in die gegenüberliegende Ecke.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("halma", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onAppear { computer() }
    }

    private func feld(_ i: Int) -> some View {
        let s = spiel.brett[i]
        let lagerFarbe: Color? = Halma.lager(1).contains(i) ? .orange : (Halma.lager(2).contains(i) ? .blue : nil)
        return Button { tippe(i) } label: {
            ZStack {
                Rectangle().fill((lagerFarbe ?? Color.appFlaeche).opacity(lagerFarbe == nil ? ((i / 8 + i % 8) % 2 == 0 ? 0.08 : 0.16) : 0.2))
                if s != 0 {
                    Circle().fill(s == 1 ? Color.orange : Color.blue).padding(4)
                        .overlay(Circle().strokeBorder(.white.opacity(0.7), lineWidth: 1.5).padding(4))
                    if farbenUnterscheidbar {
                        Image(systemName: s == 1 ? "circle.fill" : "square.fill").font(.caption2).foregroundStyle(.white.opacity(0.9))
                    }
                }
                if gewaehlt == i { Rectangle().strokeBorder(Color.primary, lineWidth: 3) }
                if let t = tipp, t.0 == i || t.1 == i { Rectangle().strokeBorder(Color.yellow, lineWidth: 4) }
                if ziele.contains(i) { Circle().fill(Color.primary.opacity(0.45)).padding(12) }
            }.aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(s == 0 ? Text("Zeile \(i / 8 + 1), Spalte \(i % 8 + 1), frei") : Text("Zeile \(i / 8 + 1), Spalte \(i % 8 + 1), Stein von \(name(s))"))
        .accessibilityValue(ziele.contains(i) ? Text("mögliches Ziel") : Text(verbatim: ""))
        .accessibilityAddTraits(gewaehlt == i ? .isSelected : [])
    }

    private func tippe(_ i: Int) {
        guard !denkt, !computerDran, !spiel.vorbei else { return }
        if let g = gewaehlt, ziele.contains(i) { verlauf.append(spiel); tipp = nil; spiel.ziehe(von: g, nach: i); gewaehlt = nil; nachZug(); return }
        gewaehlt = spiel.brett[i] == spiel.dran ? i : nil
    }

    private func nachZug() {
        if case .spieler(let s)? = spiel.sieger {
            ende(SpielEnde(reihenfolge: [name(s), name(3 - s)], info: String(localized: "\(name(s)) gewinnt")))
            return
        }
        if spiel.zeitUm {
            if let s = spiel.siegerNachZeit {
                ende(SpielEnde(reihenfolge: [name(s), name(3 - s)], punkte: [s, 3 - s].map { "\(spiel.fortschritt($0))" }, info: String(localized: "Zeit um – \(name(s)) ist weiter")))
            } else {
                ende(SpielEnde(reihenfolge: [name(1), name(2)], plaetze: [1, 1], info: String(localized: "Zeit um – Gleichstand")))
            }
            return
        }
        computer()
    }

    private func zurueck() {
        tipp = nil; gewaehlt = nil
        while let l = verlauf.popLast() { spiel = l; if !teilnehmer[l.dran - 1].computer { break } }
    }

    private func holeTipp() {
        tippRechnet = true
        let stand = spiel
        Task {
            let z = await Task.detached { () -> (Int, Int)? in var g = SystemRandomNumberGenerator(); return HalmaComputer.wahl(stand, tiefe: 2, breite: 10, mit: &g) }.value
            if spiel == stand { tipp = z; gewaehlt = nil }
            tippRechnet = false
        }
    }

    private func computer() {
        guard !spiel.vorbei, computerDran else { return }
        denkt = true
        let stand = spiel, tiefe = suchtiefe, breite = suchbreite
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            let z = await Task.detached { () -> (Int, Int)? in var g = SystemRandomNumberGenerator(); return HalmaComputer.wahl(stand, tiefe: tiefe, breite: breite, mit: &g) }.value
            denkt = false
            guard computerDran, spiel == stand else { return }
            if let (v, ziel) = z, spiel.ziehe(von: v, nach: ziel) { nachZug() }
        }
    }
}
#endif
