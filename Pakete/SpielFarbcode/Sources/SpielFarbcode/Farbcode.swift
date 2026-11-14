// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import FarbcodeKern

@MainActor
public struct FarbcodeModul: SpielModul {
    public init() {}
    public let id = "farbcode"
    public let name = "Farbcode"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.violett
    public let symbol = "circle.grid.2x2.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Knacke den geheimen Code", farbe: farbe, spieler: 1...1,
                            regeln: "Der Computer denkt sich einen Code aus Farbpunkten aus. Du hast zehn Versuche. Lege mit den Farben unten einen Tipp und tippe auf „Prüfen“. Rechts neben dem Tipp zeigen kleine Punkte: ein dunkler Punkt heißt „richtige Farbe an der richtigen Stelle“, ein heller Punkt heißt „richtige Farbe, aber an der falschen Stelle“. Die Punkte sind nicht den Stellen zugeordnet. Im Modus „Leicht“ kommt jede Farbe höchstens einmal vor, sonst sind Farben mehrfach möglich. Der Tipp-Knopf schlägt dir einen Code vor, der zu allem passt, was du bisher erfahren hast, und kostet einen Punkt.",
                            einzelText: "Ein Spieler: Wie schnell knackst du den Code?",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            FarbcodeSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Knacke den geheimen Farbcode des Computers in höchstens zehn Versuchen.").mitAnleitung(Self.anleitung))
    }
}

private let codeFarben: [Color] = [Familienfarbe.rot.color, Familienfarbe.blau.color, Familienfarbe.gruen.color, Familienfarbe.orange.color, Familienfarbe.violett.color, Familienfarbe.tuerkis.color, Familienfarbe.pink.color]   // Farben der Spielefamilie aus KlarGlas, Formzeichen unterscheiden sie zusätzlich
private func codeName(_ i: Int?) -> String {
    guard let i else { return String(localized: "leer") }
    let farben = [String(localized: "Rot"), String(localized: "Blau"), String(localized: "Grün"), String(localized: "Orange"), String(localized: "Violett"), String(localized: "Türkis"), String(localized: "Pink")]
    let formen = [String(localized: "Kreis"), String(localized: "Quadrat"), String(localized: "Dreieck"), String(localized: "Raute"), String(localized: "Stern"), String(localized: "Sechseck"), String(localized: "Herz")]
    return "\(farben[i % farben.count]), \(formen[i % formen.count])"
}
private let codeFormen = ["circle.fill", "square.fill", "triangle.fill", "diamond.fill", "star.fill", "hexagon.fill", "heart.fill"]

struct FarbcodeSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var modus = Farbcode.Modus.normal
    @State private var spiel: Farbcode?
    @State private var tipp: [Int?] = []
    @State private var hinweise = 0
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var gemeldet = false
    @State private var tag = false

    var body: some View { Group { if let s = spiel { brett(s) } else { auswahl } }.background(Color.seitenGrund).weicheAnimation(bei: spiel).spielHaptik(zug: spiel, erfolg: (spiel?.geloest ?? false), fehler: ((spiel?.vorbei ?? false) && !(spiel?.geloest ?? false))).fortsetzbar("farbcode", $spiel, pruefen: { $0.istKonsistent }) }

    private var auswahl: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Farbcode", linksAktion: abbrechen) { Color.clear.frame(width: 44, height: 44) }
            VStack(alignment: .leading, spacing: 14) {
                Text("Schwierigkeit").font(.headline)
                LeiterWahl(spiel: "farbcode", namen: ["Leicht", "Normal", "Schwer"], stufe: Binding(
                    get: { Farbcode.Modus.allCases.firstIndex(of: modus) ?? 1 },
                    set: { modus = Farbcode.Modus.allCases[min(max($0, 0), 2)] }))
                Toggle("Tagesrätsel (Normal, für alle gleich)", isOn: $tag)
                if tag, let b = Bestleistung.lesen(Bestleistung.schluessel("farbcode", tages: true)) { Label("Heute geknackt in \(b) Versuchen", systemImage: "checkmark.seal.fill").font(.footnote).foregroundStyle(.green) }
                else if !tag, let b = Bestleistung.lesen(Bestleistung.schluessel("farbcode", variante: modus.rawValue, tages: false)) { Label("Bestleistung: \(b) Versuche", systemImage: "trophy").font(.footnote).foregroundStyle(.secondary) }
                Text("\(modus.laenge) Stellen, \(modus.farben) Farben, \(modus.doppelt ? String(localized: "Farben mehrfach möglich") : String(localized: "jede Farbe nur einmal"))").font(.footnote).foregroundStyle(.secondary)
            }.padding(Theme.seitenRand)
            Spacer()
            Button("Los geht’s") {
                if tag { var g = Tagesraetsel.generator(spiel: "farbcode"); spiel = Farbcode(modus: .normal, mit: &g) }
                else { var g = SystemRandomNumberGenerator(); spiel = Farbcode(modus: modus, mit: &g) }
                tipp = Array(repeating: nil, count: spiel?.modus.laenge ?? modus.laenge); hinweise = 0; gemeldet = false }
                .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private func punkt(_ i: Int?, gross: Bool = true) -> some View {
        ZStack {
            Circle().fill(i.map { codeFarben[$0] } ?? Color.feldGrund)
            if let i { Image(systemName: codeFormen[i]).font(.system(gross ? Font.TextStyle.subheadline : .caption).weight(.bold)).foregroundStyle(.white.opacity(0.85)) }   // Formen zusätzlich zur Farbe
        }.frame(width: gross ? 34 : 24, height: gross ? 34 : 24)
        .accessibilityElement().accessibilityLabel(Text(verbatim: codeName(i)))
    }

    private func brett(_ s: Farbcode) -> some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: s.geloest ? String(localized: "Geknackt!") : String(localized: "Versuch \(min(s.versuche.count + 1, s.modus.versuche)) von \(s.modus.versuche)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { spiel = nil }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            ScrollView {
                VStack(spacing: Design.Abstand.s) {
                    ForEach(s.versuche.indices, id: \.self) { i in
                        HStack(spacing: Design.Abstand.s) {
                            Text(verbatim: "\(i + 1)").font(.caption).foregroundStyle(.secondary).frame(width: 18)
                            ForEach(s.versuche[i].tipp.indices, id: \.self) { punkt(s.versuche[i].tipp[$0]) }
                            Spacer(minLength: 8)
                            bewertung(s.versuche[i].antwort, s.modus.laenge)
                        }
                    }
                    if !s.vorbei {
                        HStack(spacing: Design.Abstand.s) {
                            Text(verbatim: "\(s.versuche.count + 1)").font(.caption.bold()).frame(width: 18)
                            ForEach(tipp.indices, id: \.self) { i in punkt(tipp[i]).overlay(Circle().stroke(Color.appFlaeche, lineWidth: tipp[i] == nil && i == tipp.firstIndex(of: nil) ? 3 : 0)).onTapGesture { tipp[i] = nil }.accessibilityAddTraits(.isButton) }
                            Spacer()
                        }
                    }
                    if s.vorbei {
                        HStack(spacing: Design.Abstand.s) {
                            Text("Code").font(.caption.bold()).frame(width: 40)
                            ForEach(s.code.indices, id: \.self) { punkt(s.code[$0]) }
                            Spacer()
                        }.padding(.top, 6)
                    }
                }.padding(.horizontal, Theme.seitenRand).padding(.vertical, 6)
            }
            if s.vorbei {
                VStack(spacing: Design.Abstand.s) {
                    Text(s.geloest ? "In \(s.versuche.count) Versuchen geknackt" : "Leider nicht geschafft").font(.headline)
                    Button("Ergebnis") { beenden(s) }.buttonStyle(HauptKnopfStil())
                }.padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            } else {
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        ForEach(0..<s.modus.farben, id: \.self) { f in
                            punkt(f).opacity(!s.modus.doppelt && tipp.contains(f) ? 0.3 : 1)
                                .frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
                                .onTapGesture { setze(f, s) }
                                .accessibilityElement(children: .ignore).accessibilityLabel("Farbe \(f + 1)").accessibilityAddTraits(.isButton)
                                .accessibilityAction { setze(f, s) }
                        }
                    }
                    HStack(spacing: Design.Abstand.m) {
                        Button { var g = SystemRandomNumberGenerator(); if let h = spiel?.hinweis(mit: &g) { tipp = h.map { Optional($0) }; hinweise += 1 } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        Button("Prüfen") { pruefe() }.hauptKnopf().disabled(tipp.contains(nil))
                    }.padding(.horizontal, Theme.seitenRand)
                }.padding(.bottom, 8)
            }
        }
    }

    private func bewertung(_ r: Farbcode.Rueckmeldung, _ n: Int) -> some View {
        let spalten = (n + 1) / 2
        let eintraege = Array(repeating: 2, count: r.genau) + Array(repeating: 1, count: r.farbe) + Array(repeating: 0, count: max(0, n - r.genau - r.farbe))
        return LazyVGrid(columns: Array(repeating: GridItem(.fixed(14), spacing: 3), count: spalten), spacing: 3) {
            ForEach(eintraege.indices, id: \.self) { i in
                Circle().fill(eintraege[i] == 2 ? Color.primary : (eintraege[i] == 1 ? Color.gray.opacity(0.45) : Color.clear))
                    .overlay(Circle().stroke(.secondary.opacity(0.5), lineWidth: eintraege[i] == 0 ? 1 : (eintraege[i] == 1 ? 1.5 : 0)))
                    .frame(width: 14, height: 14)
            }
        }.frame(width: CGFloat(spalten) * 17)
        .accessibilityLabel(Text("\(r.genau) richtig, \(r.farbe) falsche Stelle"))
    }

    private func setze(_ f: Int, _ s: Farbcode) {
        guard let i = tipp.firstIndex(of: nil) else { return }
        if !s.modus.doppelt && tipp.contains(f) { return }
        tipp[i] = f
    }

    private func pruefe() {
        guard var s = spiel, !tipp.contains(nil) else { return }
        if s.rate(tipp.compactMap { $0 }) { spiel = s; tipp = Array(repeating: nil, count: s.modus.laenge) }
    }

    private func beenden(_ s: Farbcode) {
        guard !gemeldet else { return }
        gemeldet = true
        if s.geloest, let i = Farbcode.Modus.allCases.firstIndex(of: s.modus) { Leiter.sieg("farbcode", stufe: i, mitTipp: hinweise > 0, tages: tag) }   // D4
        let punkte = s.geloest ? max(10, (s.modus.versuche + 1 - s.versuche.count) * 10 - hinweise) : 0
        ende(SpielEnde(reihenfolge: [name], punkte: ["\(punkte)"], info: s.geloest ? String(localized: "Code in \(s.versuche.count) Versuchen geknackt") + (hinweise == 0 ? Bestleistung.zusatz("farbcode", variante: s.modus.rawValue, tages: tag, wert: s.versuche.count) : "") : String(localized: "Code nicht geknackt")))
    }
}
#endif
