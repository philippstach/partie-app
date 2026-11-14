// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import WendespielKern

@MainActor
public struct WendespielModul: SpielModul {
    public init() {}
    public let id = "wendespiel"
    public let name = "Wendespiel"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "circle.lefthalf.filled"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Steine einkreisen und wenden", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Setze einen Stein so, dass du mindestens eine Reihe gegnerischer Steine zwischen deinem neuen und einem deiner alten Steine einschließt – die Eingeschlossenen werden gewendet. Kannst du nicht setzen, passt du. Das Spiel endet, wenn keiner mehr setzen kann. Wer mehr Steine hat, gewinnt. Ecken sind besonders wertvoll.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            WendespielSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Habe am Ende mehr Steine deiner Farbe auf dem Brett als dein Gegner.").mitAnleitung([
            .figuren(symbol: "circle.lefthalf.filled", titel: "Steine einklemmen", text: "Setze einen Stein so, dass gegnerische Steine zwischen deinem neuen und einem deiner Steine liegen.", figuren: ["⚫️","⚪️","⚫️"], bewegt: nil),
            .figuren(symbol: "arrow.2.circlepath", titel: "Wenden", text: "Alle eingeklemmten Steine wechseln zu deiner Farbe. Kannst du nicht setzen, passt du.", figuren: ["⚫️","⚪️","⚫️"], bewegt: 1),
            .figuren(symbol: "square.grid.2x2", titel: "Ecken sichern", text: "Wer am Ende die meisten Steine hat, gewinnt. Ecken kann niemand zurückdrehen. Mit „Verkehrt“ im Mehr-Menü gewinnt, wer die wenigsten hat.", figuren: ["◼️","⚫️"], bewegt: nil),
        ]))
    }
}

struct WendespielSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var verkehrt = UserDefaults.standard.bool(forKey: "partie.regeln.wendespiel.verkehrt")
    @State private var spiel = Wendespiel(verkehrt: UserDefaults.standard.bool(forKey: "partie.regeln.wendespiel.verkehrt"))
    @State private var denkt = false
    @State private var stufe = ComputerStufe.gespeichert("wendespiel", standard: .schwer)
    private var suchtiefe: Int { switch stufe { case .leicht: 1; case .mittel: 3; case .schwer: 4 } }
    private var fehler: Double { switch stufe { case .leicht: 0.5; case .mittel: 0.1; case .schwer: 0 } }
    @State private var verlauf: [Wendespiel] = []
    @State private var tipp: Int?
    @State private var tippRechnet = false

    private func name(_ s: Int) -> String { teilnehmer[s - 1].name }
    private func computerDran() -> Bool { teilnehmer[spiel.dran - 1].computer }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: name(spiel.dran), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: \.computer) {
                        ComputerStufePicker(spiel: "wendespiel", stufe: $stufe)
                    }
                    Toggle("Verkehrt: wenige Steine gewinnen", isOn: $verkehrt)
                        .disabled(!verlauf.isEmpty || denkt)   // nur vor dem ersten Zug
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [1, 2].map { s in .init(id: "\(s)", name: name(s), farbe: s == 1 ? .black : .gray, wert: "\(spiel.steine(s))") },
                          aktiv: "\(spiel.dran)").padding(.horizontal, Theme.seitenRand)
            SpielfeldKarte {
                Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                    ForEach(0..<8, id: \.self) { z in
                        GridRow { ForEach(0..<8, id: \.self) { s in feld(z * 8 + s) } }
                    }
                }
            }
            .padding(.horizontal, Theme.seitenRand)
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && !denkt, tippMoeglich: !computerDran() && !spiel.beendet, rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            Text(denkt ? "\(name(spiel.dran)) denkt nach …" : "\(name(spiel.dran)) ist dran").font(.subheadline).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("wendespiel", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.beendet))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: verkehrt) { _, neu in
            UserDefaults.standard.set(neu, forKey: "partie.regeln.wendespiel.verkehrt")
            if verlauf.isEmpty, spiel.verkehrt != neu { spiel = Wendespiel(verkehrt: neu); tipp = nil; computer() }
        }
        .onAppear { computer() }
    }

    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert

    private func feld(_ i: Int) -> some View {
        let s = spiel.brett[i]
        let moeglich = !denkt && !computerDran() && spiel.zuege.contains(i)
        return Button { tippe(i) } label: {
            ZStack {
                Rectangle().fill(Color.appFlaeche.opacity(0.14))
                if s != 0 {
                    Circle().fill(s == 1 ? Color.black : Color.white).padding(3)
                        .overlay(Circle().strokeBorder(Color.secondary.opacity(0.5)).padding(3))
                } else if moeglich {
                    Circle().fill(Color.appFlaeche.opacity(0.45)).padding(12)
                }
                if tipp == i { Rectangle().strokeBorder(Color.yellow, lineWidth: 4) }
            }
            .aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
        }
        .buttonStyle(.plain)
        .animation(bewegungReduziert ? nil : .snappy(duration: 0.2), value: s)   // G3
        .accessibilityLabel(s == 0 ? Text("Zeile \(i / 8 + 1), Spalte \(i % 8 + 1), frei") : Text("Zeile \(i / 8 + 1), Spalte \(i % 8 + 1), Stein von \(name(s))"))
    }

    private func tippe(_ i: Int) {
        guard !denkt, !computerDran() else { return }
        let vorher = spiel
        guard spiel.setze(i) else { return }
        verlauf.append(vorher); tipp = nil
        nachZug()
    }

    private func nachZug() {
        if spiel.beendet {
            let s = spiel.sieger
            let o = s.map { [$0, 3 - $0] } ?? [1, 2]
            ende(SpielEnde(reihenfolge: o.map(name), punkte: o.map { "\(spiel.steine($0))" }, plaetze: s == nil ? [1, 1] : nil,
                           info: s.map { String(localized: "\(name($0)) gewinnt") } ?? String(localized: "Unentschieden")))
            return
        }
        computer()
    }

    private func zurueck() {
        tipp = nil
        while let l = verlauf.popLast() { spiel = l; if !teilnehmer[l.dran - 1].computer { break } }
    }

    private func holeTipp() {
        tippRechnet = true
        let stand = spiel
        Task {
            let p = await Task.detached { WendespielComputer.wahl(stand, tiefe: 4) }.value
            if spiel == stand { tipp = p }
            tippRechnet = false
        }
    }

    private func computer() {
        guard !spiel.beendet, computerDran() else { return }
        denkt = true
        let stand = spiel, tiefe = suchtiefe, f = fehler
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            let p = await Task.detached { WendespielComputer.wahl(stand, tiefe: tiefe, fehler: f) }.value
            denkt = false
            guard spiel == stand else { return }
            if let p, spiel.setze(p) { nachZug() }
        }
    }
}
#endif
