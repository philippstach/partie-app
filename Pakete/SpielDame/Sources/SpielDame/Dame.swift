// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import DameKern

@MainActor
public struct DameModul: SpielModul {
    public init() {}
    public let id = "dame"
    public let name = "Dame"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "checkerboard.rectangle"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Diagonal ziehen, springen, krönen", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Gezogen wird diagonal auf dunklen Feldern. Steine ziehen ein Feld vorwärts. Gegnerische Steine werden übersprungen und geschlagen – Schlagen ist Pflicht, auch rückwärts und mehrfach hintereinander. Erreicht ein Stein die letzte Reihe, wird er Dame und darf beliebig weit diagonal ziehen und schlagen. Wer keinen Stein mehr hat oder nicht ziehen kann, verliert.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            DameSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Schlage alle gegnerischen Steine oder sperre sie so ein, dass dein Gegner nicht mehr ziehen kann.").mitAnleitung([
            .figuren(symbol: "arrow.up.right", titel: "Diagonal ziehen", text: "Deine Steine ziehen ein Feld schräg vorwärts, nur auf den dunklen Feldern.", figuren: ["⚫️","▫️"], bewegt: 0),
            .figuren(symbol: "arrow.triangle.swap", titel: "Schlagen", text: "Springe über einen gegnerischen Stein und nimm ihn vom Brett. Je nach Regelart ist Schlagen Pflicht.", figuren: ["⚫️","⚪️","▫️"], bewegt: 0),
            .figuren(symbol: "crown", titel: "Dame werden", text: "Erreicht ein Stein die letzte Reihe, wird er Dame und darf weiter ziehen. Die Regelart wählst du im Mehr-Menü.", figuren: ["⚫️","👑"], bewegt: 0),
        ]))
    }
}

struct DameSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var art = DameArt.gespeichert
    @State private var spiel = Dame(regeln: DameArt.gespeichert.regeln)
    @State private var verlauf: [Dame] = []
    @State private var tipp: DamenZug?
    @State private var tippRechnet = false
    @State private var gewaehlt: Int?
    @State private var denkt = false
    @State private var stufe = ComputerStufe.gespeichert("dame", standard: .schwer)
    private var staerke: DameStaerke { switch stufe { case .leicht: .leicht; case .mittel: .mittel; case .schwer: .schwer } }

    private func name(_ s: Int) -> String { teilnehmer[s - 1].name }
    private var computerDran: Bool { teilnehmer[spiel.dran - 1].computer }
    private var ziele: Set<Int> {
        guard let g = gewaehlt else { return [] }
        return Set(spiel.zuege.filter { $0.start == g }.map(\.ziel))
    }
    private var bewegliche: Set<Int> { Set(spiel.zuege.map(\.start)) }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: name(spiel.dran), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: \.computer) {
                        ComputerStufePicker(spiel: "dame", stufe: $stufe)
                    }
                    Picker("Regeln", selection: $art) {
                        ForEach(DameArt.allCases) { Text($0.titel).tag($0) }
                    }
                    .disabled(!verlauf.isEmpty || denkt)   // nur vor dem ersten Zug
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [1, 2].map { s in .init(id: "\(s)", name: name(s), farbe: s == 1 ? .white : .black, wert: "\(spiel.steine(s))") },
                          aktiv: "\(spiel.dran)").padding(.horizontal, Theme.seitenRand)
            SpielfeldKarte {
                Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                    ForEach(0..<8, id: \.self) { z in GridRow { ForEach(0..<8, id: \.self) { s in feld(z * 8 + s) } } }
                }
                .clipShape(RoundedRectangle(cornerRadius: Design.Ecke.klein))
            }
            .padding(.horizontal, Theme.seitenRand)
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && !denkt, tippMoeglich: !computerDran && !spiel.vorbei, rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            Text(denkt ? "\(name(spiel.dran)) denkt nach …" : (spiel.schlagPflicht ? "\(name(spiel.dran)): Du musst schlagen." : "\(name(spiel.dran)) ist dran"))
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("dame", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: art) { _, neu in
            neu.sichern()
            if verlauf.isEmpty, spiel.regeln != neu.regeln { spiel = Dame(regeln: neu.regeln); gewaehlt = nil; tipp = nil; computer() }
        }
        .onAppear { computer() }
    }

    private func feld(_ i: Int) -> some View {
        let r = i / 8, c = i % 8, dunkel = (r + c) % 2 == 1
        let stein = spiel.brett[i]
        return Button { tippe(i) } label: {
            ZStack {
                Rectangle().fill(dunkel ? Color.appFlaeche.opacity(0.55) : Color.appFlaeche.opacity(0.1))
                if stein != 0 {
                    Circle().fill(Dame.gehoertZuOeffentlich(stein) == 1 ? Color.white : Color(white: 0.12)).padding(5)
                        .overlay(Circle().strokeBorder(Color.secondary.opacity(0.6), lineWidth: 1.5).padding(5))
                    if stein >= 3 { Image(systemName: "crown.fill").font(.caption).foregroundStyle(Dame.gehoertZuOeffentlich(stein) == 1 ? .orange : .yellow) }
                }
                if gewaehlt == i { Rectangle().strokeBorder(Color.white, lineWidth: 3) }
                if let t = tipp, t.start == i || t.ziel == i { Rectangle().strokeBorder(Color.yellow, lineWidth: 4) }
                if ziele.contains(i) { Circle().fill(Color.white.opacity(0.8)).padding(14) }
                else if gewaehlt == nil, !denkt, !computerDran, bewegliche.contains(i) { Circle().strokeBorder(Color.white.opacity(0.7), lineWidth: 2).padding(3) }
            }
            .aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
        }
        .buttonStyle(.plain)
        .disabled(!dunkel)
        .accessibilityLabel(stein == 0 ? Text("Zeile \(r + 1), Spalte \(c + 1), frei")
                            : (stein >= 3 ? Text("Zeile \(r + 1), Spalte \(c + 1), Dame von \(name(Dame.gehoertZuOeffentlich(stein)))")
                                          : Text("Zeile \(r + 1), Spalte \(c + 1), Stein von \(name(Dame.gehoertZuOeffentlich(stein)))")))
        .accessibilityValue(ziele.contains(i) ? Text("mögliches Ziel") : Text(verbatim: ""))
        .accessibilityAddTraits(gewaehlt == i ? .isSelected : [])
    }

    private func tippe(_ i: Int) {
        guard !denkt, !computerDran, !spiel.vorbei else { return }
        if let g = gewaehlt, let z = spiel.zuege.first(where: { $0.start == g && $0.ziel == i }) {
            verlauf.append(spiel); tipp = nil
            spiel.spiele(z); SpielZug.gemacht("dame"); gewaehlt = nil; nachZug(); return
        }
        gewaehlt = bewegliche.contains(i) ? i : nil
    }

    private func nachZug() {
        if spiel.remis {
            ende(SpielEnde(reihenfolge: [name(1), name(2)], punkte: [1, 2].map { "\(spiel.steine($0))" }, plaetze: [1, 1], info: String(localized: "Remis – 40 Züge ohne Schlag oder Männerzug")))
            return
        }
        if let s = spiel.sieger {
            ende(SpielEnde(reihenfolge: [name(s), name(3 - s)], punkte: [s, 3 - s].map { "\(spiel.steine($0))" },
                           info: String(localized: "\(name(s)) gewinnt")))
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
            let z = await Task.detached { DameComputer.wahl(stand, tiefe: 5) }.value
            if spiel == stand { tipp = z; gewaehlt = nil }
            tippRechnet = false
        }
    }

    private func computer() {
        guard !spiel.vorbei, computerDran else { return }
        denkt = true
        let stand = spiel, st = staerke
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            let z = await Task.detached { DameComputer.wahl(stand, staerke: st) }.value
            denkt = false
            if let z, spiel.spiele(z) { nachZug() }
        }
    }
}

extension Dame {
    /// Besitzer eines Steins (1 oder 2), 0 bei leerem Feld.
    static func gehoertZuOeffentlich(_ stein: Int) -> Int { stein == 0 ? 0 : (stein % 2 == 1 ? 1 : 2) }
}

/// Wählbare Regelart im „Mehr“-Menü (gilt vor dem ersten Zug, wird gemerkt).
enum DameArt: String, CaseIterable, Identifiable {
    case deutsch, englisch, locker
    var id: String { rawValue }
    var titel: LocalizedStringKey {
        switch self { case .deutsch: "Deutsch (fliegende Dame)"; case .englisch: "Englisch (Dame zieht ein Feld)"; case .locker: "Ohne Schlagzwang" }
    }
    var regeln: DameRegeln { switch self { case .deutsch: .deutsch; case .englisch: .englisch; case .locker: .locker } }
    static var gespeichert: DameArt { DameArt(rawValue: UserDefaults.standard.string(forKey: "partie.regeln.dame") ?? "") ?? .deutsch }
    func sichern() { UserDefaults.standard.set(rawValue, forKey: "partie.regeln.dame") }
}
#endif
