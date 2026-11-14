// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import KalahaKern

@MainActor
public struct KalahaModul: SpielModul {
    public init() {}
    public let id = "kalaha"
    public let name = "Kalaha"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "circle.grid.3x3.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Steine säen, Haus füllen", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Jeder hat sechs Mulden mit je vier Steinen und ein Haus rechts von seiner Reihe. Du nimmst alle Steine einer Mulde und verteilst sie reihum, einen je Mulde, auch in dein Haus (nicht in das des Gegners). Endet der letzte Stein im eigenen Haus, bist du noch einmal dran. Endet er in einer leeren eigenen Mulde, bekommst du diesen Stein und alle gegenüber ins Haus. Ist eine Reihe leer, wandern die übrigen Steine in das Haus ihres Besitzers. Wer mehr Steine im Haus hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            KalahaSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Sammle am Ende mehr Steine in deinem Haus als dein Gegner.").mitAnleitung([
            .figuren(symbol: "hand.point.up", titel: "Mulde wählen", text: "Tippe eine deiner Mulden an. Die Steine daraus verteilst du reihum, jeweils einen pro Mulde.", figuren: ["🟤","🟤","🟤","🟤"], bewegt: 0),
            .figuren(symbol: "arrow.counterclockwise", titel: "Noch einmal dran", text: "Landet der letzte Stein in deinem Haus, bist du gleich noch einmal dran.", figuren: ["🟤","🟤","🏠"], bewegt: 0),
            .figuren(symbol: "sparkles", titel: "Fangen", text: "Landet der letzte Stein in einer leeren eigenen Mulde, gehören dir die Steine gegenüber. Wer am Ende mehr im Haus hat, gewinnt.", figuren: ["▫️","🟤","🏠"], bewegt: 1),
        ]))
    }
}

struct KalahaSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var art = KalahaArt.gespeichert
    @State private var spiel = Kalaha(regeln: KalahaArt.gespeichert.regeln)
    @State private var denkt = false
    @State private var verlauf: [Kalaha] = []
    @State private var tipp: Int?
    @State private var tippRechnet = false
    @State private var stufe = ComputerStufe.gespeichert("kalaha", standard: .schwer)
    private var suchtiefe: Int { switch stufe { case .leicht: 3; case .mittel: 5; case .schwer: 7 } }

    private func name(_ s: Int) -> String { teilnehmer[s].name }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: name(spiel.dran), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: \.computer) {
                        ComputerStufePicker(spiel: "kalaha", stufe: $stufe)
                    }
                    Picker("Regeln", selection: $art) {
                        ForEach(KalahaArt.allCases) { Text($0.titel).tag($0) }
                    }
                    .disabled(!verlauf.isEmpty || denkt)   // nur vor dem ersten Zug
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielfeldKarte {
                HStack(spacing: 6) {
                    haus(1)
                    VStack(spacing: 6) {
                        HStack(spacing: 6) { ForEach((7...12).reversed(), id: \.self) { mulde($0) } }
                        HStack(spacing: 6) { ForEach(0...5, id: \.self) { mulde($0) } }
                    }
                    haus(0)
                }
                .padding(6)
            }
            .padding(.horizontal, Theme.seitenRand)
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && !denkt, tippMoeglich: !teilnehmer[spiel.dran].computer && !spiel.beendet, rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            Text(denkt ? "\(name(spiel.dran)) denkt nach …" : "\(name(spiel.dran)) ist dran – tippe eine Mulde deiner Reihe.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, Theme.seitenRand)
            Text("Oben: \(name(1)) · Unten: \(name(0))").font(.footnote).foregroundStyle(.tertiary)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("kalaha", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.beendet))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: art) { _, neu in
            neu.sichern()
            if verlauf.isEmpty, spiel.regeln != neu.regeln { spiel = Kalaha(regeln: neu.regeln); tipp = nil; computer() }
        }
        .onAppear { computer() }
    }

    private func haus(_ s: Int) -> some View {
        Text("\(spiel.punkte(s))")
            .font(.system(.title, design: Design.zahlDesign).weight(.bold).monospacedDigit())
            .frame(width: 46).frame(minHeight: 124, maxHeight: .infinity)
            .background(s == 0 ? Color.appFlaeche.opacity(0.25) : Color.secondary.opacity(0.2), in: .rect(cornerRadius: 22))
            .accessibilityLabel("Haus von \(name(s)): \(spiel.punkte(s))")
    }

    private func mulde(_ i: Int) -> some View {
        let meine = Kalaha.mulden(spiel.dran).contains(i) && spiel.felder[i] > 0 && !denkt && !teilnehmer[spiel.dran].computer
        return Button { tippe(i) } label: {
            Text("\(spiel.felder[i])")
                .font(.system(.title3, design: Design.zahlDesign).weight(.bold).monospacedDigit())
                .frame(maxWidth: .infinity, minHeight: 56).aspectRatio(0.8, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
                .background(meine ? Color.appFlaeche.opacity(0.3) : Color(.tertiarySystemFill), in: Circle())
                .overlay(Circle().strokeBorder(meine ? Color.appFlaeche : .clear, lineWidth: 2))   // design:spielinhalt (Markierung auf dem Spielmaterial)
                .overlay(Circle().strokeBorder(Color.yellow, lineWidth: 4).opacity(tipp == i ? 1 : 0))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Mulde \(i % 7 + 1) von \(name(i < 7 ? 0 : 1)): \(spiel.felder[i]) Steine")
        .accessibilityValue(meine ? Text("spielbar") : Text(verbatim: ""))
        .accessibilityHint(meine ? Text("Doppeltippen, um die Steine zu säen.") : Text(verbatim: ""))
    }

    private func tippe(_ i: Int) {
        guard !denkt, !teilnehmer[spiel.dran].computer else { return }
        let vorher = spiel
        guard spiel.spiele(i) else { return }
        verlauf.append(vorher); tipp = nil
        nachZug()
    }

    private func nachZug() {
        if spiel.beendet {
            let s = spiel.sieger
            let ordnung = s.map { [$0, 1 - $0] } ?? [0, 1]
            ende(SpielEnde(reihenfolge: ordnung.map(name), punkte: ordnung.map { "\(spiel.punkte($0))" },
                           plaetze: s == nil ? [1, 1] : nil,
                           info: s.map { String(localized: "\(name($0)) gewinnt") } ?? String(localized: "Unentschieden")))
            return
        }
        computer()
    }

    private func zurueck() {
        tipp = nil
        while let l = verlauf.popLast() { spiel = l; if !teilnehmer[l.dran].computer { break } }
    }

    private func holeTipp() {
        tippRechnet = true
        let stand = spiel
        Task {
            let m = await Task.detached { KalahaComputer.wahl(stand, tiefe: 7) }.value
            if spiel == stand { tipp = m }
            tippRechnet = false
        }
    }

    private func computer() {
        guard !spiel.beendet, teilnehmer[spiel.dran].computer else { return }
        denkt = true
        let stand = spiel, tiefe = suchtiefe
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            let m = await Task.detached { KalahaComputer.wahl(stand, tiefe: tiefe) }.value
            denkt = false
            guard spiel == stand else { return }
            if let m, spiel.spiele(m) { nachZug() }
        }
    }
}

/// Wählbare Regelart im „Mehr“-Menü (gilt vor dem ersten Zug, wird gemerkt).
enum KalahaArt: String, CaseIterable, Identifiable {
    case standard, drei, sechs, schlicht
    var id: String { rawValue }
    var titel: LocalizedStringKey {
        switch self {
        case .standard: "Standard (4 Steine)"; case .drei: "Kurz (3 Steine)"
        case .sechs: "Lang (6 Steine)"; case .schlicht: "Schlicht (ohne Fangen und Extrazug)"
        }
    }
    var regeln: KalahaRegeln { switch self { case .standard: .standard; case .drei: .drei; case .sechs: .sechs; case .schlicht: .schlicht } }
    static var gespeichert: KalahaArt { KalahaArt(rawValue: UserDefaults.standard.string(forKey: "partie.regeln.kalaha") ?? "") ?? .standard }
    func sichern() { UserDefaults.standard.set(rawValue, forKey: "partie.regeln.kalaha") }
}
#endif
