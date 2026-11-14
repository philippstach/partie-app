// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import OwareKern

@MainActor
public struct OwareModul: SpielModul {
    public init() {}
    public let id = "oware"
    public let name = "Oware"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "circle.grid.2x2.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Samen säen und erobern", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Zwölf Mulden, je vier Samen. Jeder besitzt die sechs Mulden auf seiner Seite. Du nimmst alle Samen aus einer deiner Mulden und säst sie gegen den Uhrzeigersinn einzeln in die folgenden Mulden; bei zwölf oder mehr Samen wird die Ausgangsmulde übersprungen. Liegt dein letzter Samen in einer gegnerischen Mulde, die dadurch zwei oder drei Samen enthält, erobert du diese und davor liegende gegnerische Mulden mit zwei oder drei Samen. Würdest du dem Gegner damit alle Samen nehmen, passiert nichts. Hat der Gegner keine Samen, musst du ihm möglichst welche geben. Wer 25 Samen erobert hat, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            OwareSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Erobere als Erster 25 Samen aus den gegnerischen Mulden.").mitAnleitung([
            .figuren(symbol: "circle.grid.2x2", titel: "Samen säen", text: "Nimm alle Samen aus einer deiner Mulden und säe sie gegen den Uhrzeigersinn einzeln aus.", figuren: ["🟤", "🟤", "🟤", "🟤"], bewegt: 0),
            .figuren(symbol: "hand.raised", titel: "Erobern", text: "Landet dein letzter Samen in einer gegnerischen Mulde mit dann zwei oder drei Samen, gehören sie dir, ebenso davor liegende Mulden mit zwei oder drei.", figuren: ["🟤", "2️⃣", "3️⃣"], bewegt: nil),
            .figuren(symbol: "25.circle", titel: "25 Samen", text: "Wer 25 Samen erobert hat, gewinnt. Hat der Gegner keine Samen, musst du ihm möglichst welche geben.", figuren: ["2️⃣", "5️⃣"], bewegt: nil),
        ]))
    }
}

struct OwareSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var art = OwareArt.gespeichert
    @State private var spiel = Oware(regeln: OwareArt.gespeichert.regeln)
    @State private var stufe = ComputerStufe.gespeichert("oware")
    @State private var meldung: String?
    @State private var schritte = 0
    @State private var hinweis: Int?
    @State private var verlauf: [Oware] = []
    @State private var tippRechnet = false

    private var computerDran: Bool { teilnehmer[spiel.amZug].computer }
    private var tiefe: Int { switch stufe { case .leicht: 1; case .mittel: 3; case .schwer: 6 } }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.vorbei ? String(localized: "Spielende") : String(localized: "\(teilnehmer[spiel.amZug].name) ist dran"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    if teilnehmer.contains(where: { $0.computer }) { ComputerStufePicker(spiel: "oware", stufe: $stufe) }
                    Picker("Regeln", selection: $art) {
                        ForEach(OwareArt.allCases) { Text($0.titel).tag($0) }
                    }
                    .disabled(!verlauf.isEmpty)   // nur vor dem ersten Zug
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielerLeiste(eintraege: [0, 1].map { .init(id: "\($0)", name: teilnehmer[$0].name, farbe: $0 == 0 ? .red : .blue, wert: "\(spiel.vorrat[$0])") }, aktiv: "\(spiel.amZug)").padding(.horizontal, Theme.seitenRand)
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && !computerDran, tippMoeglich: !computerDran && !spiel.vorbei, rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            Text("Eroberte Samen (25 gewinnen)").font(.caption2).foregroundStyle(.tertiary)
            SpielfeldKarte {
                VStack(spacing: Design.Abstand.m) {
                    HStack(spacing: 6) { ForEach((6...11).reversed(), id: \.self) { mulde($0) } }
                    HStack(spacing: 6) { ForEach(0...5, id: \.self) { mulde($0) } }
                }
            }.padding(.horizontal, Theme.seitenRand)
            if let m = meldung { Text(m).font(.subheadline.weight(.semibold)) }
            Spacer(minLength: 0)
            if spiel.vorbei { Button("Ergebnis") { beenden() }.buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8) }
            else if computerDran { Text("\(teilnehmer[spiel.amZug].name) spielt …").foregroundStyle(.secondary).padding(.bottom, 8) }
            else { Text("Tippe eine deiner Mulden.").font(.subheadline).foregroundStyle(.secondary).padding(.bottom, 8) }
        }
        .background(Color.seitenGrund)
        .fortsetzbar("oware", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.vorbei))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .onChange(of: art) { _, neu in
            neu.sichern()
            if verlauf.isEmpty, spiel.regeln != neu.regeln { spiel = Oware(regeln: neu.regeln); hinweis = nil }
        }
        .task(id: "\(schritte)") {
            guard !spiel.vorbei, computerDran else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            let stand = spiel, t = tiefe
            let wahl = await Task.detached { OwareComputer.wahl(stand, tiefe: t) }.value
            guard !Task.isCancelled, spiel == stand, let m = wahl else { return }
            ziehe(m)
        }
    }

    private func mulde(_ i: Int) -> some View {
        let n = spiel.mulden[i], erlaubt = !computerDran && spiel.zuege.contains(i)
        return Button { if erlaubt { verlauf.append(spiel); ziehe(i) } } label: {
            ZStack {
                Circle().fill(Oware.besitzer(i) == 0 ? Color.red.opacity(0.18) : Color.blue.opacity(0.18))
                Circle().strokeBorder(hinweis == i ? Color.green : (erlaubt ? Color.primary : Color.secondary.opacity(0.4)), lineWidth: hinweis == i ? 5 : (erlaubt ? 3 : 1))   // design:spielinhalt (Markierung auf dem Spielmaterial)
                Text("\(n)").font(.title3.weight(.bold)).foregroundStyle(n == 0 ? .secondary : .primary)
            }.frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
        }.buttonStyle(.plain).accessibilityLabel("Mulde \(i + 1) von \(Oware.besitzer(i) == 0 ? teilnehmer[0].name : (teilnehmer.count > 1 ? teilnehmer[1].name : String(localized: "Computer"))), \(n) Samen")
            .accessibilityValue(erlaubt ? Text("spielbar") : Text(verbatim: ""))
    }

    private func zurueck() {
        hinweis = nil; meldung = nil
        while let l = verlauf.popLast() { spiel = l; schritte += 1; if !teilnehmer[l.amZug].computer { break } }
    }

    private func holeTipp() {
        tippRechnet = true
        let stand = spiel
        Task {
            let m = await Task.detached { OwareComputer.wahl(stand, tiefe: 6) }.value
            if spiel == stand { hinweis = m }
            tippRechnet = false
        }
    }

    private func ziehe(_ m: Int) {
        hinweis = nil
        let s = spiel.amZug
        if let b = spiel.spiele(m) { meldung = b > 0 ? String(localized: "\(teilnehmer[s].name) erobert \(b) Samen.") : nil }
        schritte += 1
    }

    private func beenden() {
        let s = spiel.sieger ?? 0
        ende(SpielEnde(reihenfolge: [teilnehmer[s].name, teilnehmer[1 - s].name], punkte: [spiel.vorrat[s], spiel.vorrat[1 - s]].map(String.init),
                       plaetze: spiel.sieger == nil ? [1, 1] : nil,
                       info: spiel.sieger == nil ? String(localized: "Unentschieden") : String(localized: "\(teilnehmer[s].name) gewinnt")))
    }
}

/// Wählbare Regelart im „Mehr“-Menü (gilt vor dem ersten Zug, wird gemerkt).
enum OwareArt: String, CaseIterable, Identifiable {
    case standard, kurz, lang, grand
    var id: String { rawValue }
    var titel: LocalizedStringKey {
        switch self {
        case .standard: "Standard (4 Samen, Ziel 25)"; case .kurz: "Kurz (3 Samen, Ziel 19)"
        case .lang: "Lang (5 Samen, Ziel 31)"; case .grand: "Grand Slam zählt"
        }
    }
    var regeln: OwareRegeln { switch self { case .standard: .standard; case .kurz: .kurz; case .lang: .lang; case .grand: .grand } }
    static var gespeichert: OwareArt { OwareArt(rawValue: UserDefaults.standard.string(forKey: "partie.regeln.oware") ?? "") ?? .standard }
    func sichern() { UserDefaults.standard.set(rawValue, forKey: "partie.regeln.oware") }
}
#endif
