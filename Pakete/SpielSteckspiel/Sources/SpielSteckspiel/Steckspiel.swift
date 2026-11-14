// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import SteckspielKern

@MainActor
public struct SteckspielModul: SpielModul {
    public init() {}
    public let id = "steckspiel"
    public let name = "Steckspiel"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.indigo
    public let symbol = "circle.grid.cross.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Spring und lass nur einen übrig", farbe: farbe, spieler: 1...1,
                            regeln: "Auf dem Brett stecken Stecker in allen Löchern bis auf das mittlere. Du springst mit einem Stecker waagrecht oder senkrecht über einen direkten Nachbarn in ein leeres Loch dahinter. Der übersprungene Stecker wird entfernt. Ziel: Am Ende soll nur ein einziger Stecker übrig sein. Gehen keine Sprünge mehr, ist das Spiel zu Ende; je weniger Stecker übrig sind, desto besser bist du. Tippe einen Stecker an, dann das leere Loch, in das er springen soll. Mit „Zurück“ nimmst du Züge zurück. Es gibt zwei Bretter: das klassische Kreuz und das größere europäische Brett.",
                            einzelText: "Ein Spieler: Wie wenige Stecker bleiben übrig?",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SteckspielSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Springe über Stecker und entferne sie, bis nur noch einer übrig ist. Je weniger, desto besser.").mitAnleitung(Self.anleitung))
    }
}

struct SteckspielSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var brett = Steckspiel.Brett.kreuz
    @State private var spiel: Steckspiel?
    @State private var gewaehlt: SPos?
    @State private var gemeldet = false
    @State private var tipp: SZug?
    @State private var tipps = 0

    var body: some View { Group { if let s = spiel { feld(s) } else { auswahl } }.background(Color.seitenGrund).weicheAnimation(bei: spiel).spielHaptik(zug: spiel, erfolg: (spiel?.uebrig == 1), fehler: (spiel?.festgefahren ?? false)).fortsetzbar("steckspiel", $spiel, pruefen: { $0.istKonsistent }) }

    private var auswahl: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Steckspiel", linksAktion: abbrechen) { Color.clear.frame(width: 44, height: 44) }
            VStack(alignment: .leading, spacing: 14) {
                Text("Brett").font(.headline)
                Picker("Brett", selection: $brett) { Text("Kreuz (33)").tag(Steckspiel.Brett.kreuz); Text("Europa (37)").tag(Steckspiel.Brett.europa) }.pickerStyle(.segmented)
                if let b = Bestleistung.lesen(Bestleistung.schluessel("steckspiel", variante: brett.rawValue, tages: false)) { Label("Bisher am wenigsten: \(b) Stecker", systemImage: "trophy").font(.footnote).foregroundStyle(.secondary) }
            }.padding(Theme.seitenRand)
            Spacer()
            Button("Los geht’s") { spiel = Steckspiel(brett: brett); gewaehlt = nil; gemeldet = false; tipp = nil; tipps = 0 }
                .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private func feld(_ s: Steckspiel) -> some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "\(s.uebrig) Stecker"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { spiel = nil }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            SpielfeldKarte {
                GeometryReader { g in
                    let n = s.brett.muster.count
                    let z = min(g.size.width, g.size.height) / CGFloat(n)
                    Canvas { ctx, _ in zeichne(&ctx, s, z) }
                        .frame(width: z * CGFloat(n), height: z * CGFloat(n)).frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .accessibilityElement(children: .ignore)   // G1
                        .accessibilityLabel(Text("Steckbrett"))
                        .accessibilityValue(Text("\(s.uebrig) Stecker übrig\(s.festgefahren ? String(localized: ", keine Sprünge mehr") : "")"))
                        .accessibilityHint(Text("Erst einen Stecker antippen, dann das Zielloch zwei Felder weiter."))
                        .accessibilityChildren {
                            // VoiceOver: jeder mögliche Sprung ist ein eigener Knopf (die Fläche selbst ist nur tippbar)
                            VStack {
                                Text("Steckbrett: \(s.uebrig) Stecker übrig")
                                ForEach(Array(s.zuege().enumerated()), id: \.offset) { _, z in
                                    Button(Self.beschreibung(z)) { springe(z) }
                                }
                            }
                        }
                        .gesture(SpatialTapGesture().onEnded { v in
                            let ox = (g.size.width - z * CGFloat(n)) / 2
                            tippe(SPos(Int((v.location.x - ox) / z), Int(v.location.y / z)))
                        })
                }.aspectRatio(1, contentMode: .fit)
            }.padding(.horizontal, Theme.seitenRand)
            if s.festgefahren {
                VStack(spacing: Design.Abstand.s) {
                    Text(Steckspiel.rangNamen[s.rang]).font(.title3.bold()).foregroundStyle(Color.accentText)
                    Text(s.uebrig == 1 ? "Perfekt – nur ein Stecker übrig!" : "Keine Sprünge mehr – \(s.uebrig) Stecker übrig.").font(.subheadline)
                    HStack { Button("Zurück") { spiel?.zurueck() }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge); Button("Ergebnis") { beenden(s) }.buttonStyle(HauptKnopfStil()) }
                }.padding(.horizontal, Theme.seitenRand)
            } else {
                HStack(spacing: Design.Abstand.m) {
                    Button { spiel?.zurueck(); gewaehlt = nil; tipp = nil } label: { Label("Zurück", systemImage: "arrow.uturn.backward") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(!s.kannZurueck)
                    Button { tipp = s.hinweis(); tipps += 1; if let t = tipp { ansage(String(localized: "Tipp: ") + Self.beschreibung(t)) } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                Text("Mögliche Sprünge: \(s.zuege().count)").font(.footnote).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func zeichne(_ ctx: inout GraphicsContext, _ s: Steckspiel, _ z: CGFloat) {
        let ziele = gewaehlt.map { s.zuege(von: $0).map(\.nach) } ?? []
        if let t = tipp, s.zuege().contains(t) {
            for p in [t.von, t.nach] {
                let c = CGPoint(x: (CGFloat(p.x) + 0.5) * z, y: (CGFloat(p.y) + 0.5) * z)
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - z * 0.44, y: c.y - z * 0.44, width: z * 0.88, height: z * 0.88)), with: .color(.yellow), lineWidth: 4)
            }
        }
        for l in s.loecher {
            let c = CGPoint(x: (CGFloat(l.x) + 0.5) * z, y: (CGFloat(l.y) + 0.5) * z)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - z * 0.4, y: c.y - z * 0.4, width: z * 0.8, height: z * 0.8)), with: .color(Color.appFlaeche.opacity(0.10)))
            if ziele.contains(l) { ctx.stroke(Path(ellipseIn: CGRect(x: c.x - z * 0.33, y: c.y - z * 0.33, width: z * 0.66, height: z * 0.66)), with: .color(Color.appFlaeche), style: StrokeStyle(lineWidth: 3, dash: [4, 3])) }
            if s.stecker.contains(l) {
                let r = z * 0.3
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(Color.appFlaeche))
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(gewaehlt == l ? Color.primary : .white), lineWidth: gewaehlt == l ? 4 : 1.5)
            }
        }
    }

    /// Sprechtext für einen Sprung: „Von Zeile 2, Spalte 4 über Zeile 3, Spalte 4 nach Zeile 4, Spalte 4“.
    static func beschreibung(_ z: SZug) -> String {
        String(localized: "Springe von Zeile \(z.von.y + 1), Spalte \(z.von.x + 1) nach Zeile \(z.nach.y + 1), Spalte \(z.nach.x + 1)")
    }

    private func springe(_ z: SZug) {
        guard var s = spiel, s.ziehe(z) else { return }
        spiel = s; gewaehlt = nil; tipp = nil
        ansage(String(localized: "\(s.uebrig) Stecker übrig") + (s.festgefahren ? String(localized: ", keine Sprünge mehr") : ""))
    }

    private func tippe(_ p: SPos) {
        guard var s = spiel, s.loecher.contains(p) else { return }
        if let g = gewaehlt, let z = s.zuege(von: g).first(where: { $0.nach == p }) { s.ziehe(z); spiel = s; gewaehlt = nil; tipp = nil; ansage(String(localized: "\(s.uebrig) Stecker übrig")); return }
        gewaehlt = s.stecker.contains(p) && !s.zuege(von: p).isEmpty ? p : nil
    }

    private func beenden(_ s: Steckspiel) {
        guard !gemeldet else { return }
        gemeldet = true
        ende(SpielEnde(reihenfolge: [name], punkte: ["\(s.punkte)"], info: String(localized: "\(s.uebrig) Stecker übrig (\(Steckspiel.rangNamen[s.rang]))") + (tipps == 0 ? Bestleistung.zusatz("steckspiel", variante: s.brett.rawValue, tages: false, wert: s.uebrig) : "")))
    }
}
#endif
