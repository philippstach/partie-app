// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import UngleichungKern

@MainActor
public struct UngleichungModul: SpielModul {
    public init() {}
    public let id = "ungleichung"
    public let name = "Ungleichung"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.schiefer
    public let symbol = "lessthan.circle.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Kleiner oder größer?", farbe: farbe, spieler: 1...1,
                            regeln: "Fülle das Quadrat mit den Zahlen von 1 bis zur Kantenlänge, sodass in jeder Zeile und jeder Spalte jede Zahl genau einmal vorkommt. Zwischen manchen Feldern steht ein Zeichen: Die Spitze zeigt zur kleineren Zahl, also bedeutet „<“, dass die linke (obere) Zahl kleiner ist als die rechte (untere). Manche Zahlen sind vorgegeben. Jedes Rätsel hat genau eine Lösung, du musst also nie raten. Wähle ein Feld und tippe unten die Zahl. Rot markierte Felder verstoßen gegen eine Regel. Der Tipp-Knopf setzt eine Zahl für dich.",
                            einzelText: "Ein Spieler: Knobeln ohne Raten.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            UngleichungSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Fülle das Quadrat so, dass in jeder Zeile und Spalte jede Zahl einmal steht und alle Ungleichheitszeichen stimmen.").mitAnleitung(Self.anleitung))
    }
}

struct UngleichungSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var groesse = 5
    @State private var schwer = false
    @State private var rätsel: Ungleichung?
    @State private var erzeugt = false
    @State private var wahl: Int?
    @State private var tipps = 0
    @State private var start = Date()
    @State private var gemeldet = false
    @State private var tagesraetsel = false

    var body: some View { Group { if let p = rätsel { brett(p) } else { auswahl } }.background(Color.seitenGrund).weicheAnimation(bei: rätsel).spielHaptik(zug: rätsel, erfolg: (rätsel?.geloest ?? false), fehler: false).fortsetzbar("ungleichung", $rätsel, pruefen: { $0.istKonsistent }) }

    private var auswahl: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Ungleichung", linksAktion: abbrechen) { Color.clear.frame(width: 44, height: 44) }
            VStack(alignment: .leading, spacing: 14) {
                Text("Größe").font(.headline)
                Picker("Größe", selection: $groesse) { Text("4 × 4").tag(4); Text("5 × 5").tag(5); Text("6 × 6").tag(6) }.pickerStyle(.segmented)
                LeiterWahl(spiel: "ungleichung", namen: ["Mit Starthilfe", "Schwer"], stufe: Binding(get: { schwer ? 1 : 0 }, set: { schwer = $0 == 1 }))
                Toggle("Tagesrätsel (5 × 5, für alle gleich)", isOn: $tagesraetsel)
                if tagesraetsel, let b = Bestleistung.lesen(tagesSchluessel) { Label("Heute gelöst in \(b) Sekunden", systemImage: "checkmark.seal.fill").font(.footnote).foregroundStyle(.green) }
                else if !tagesraetsel, let b = Bestleistung.lesen(groessenSchluessel) { Label("Bestzeit: \(b) Sekunden", systemImage: "trophy").font(.footnote).foregroundStyle(.secondary) }
                if erzeugt { ProgressView("Rätsel wird gebaut …") }
            }.padding(Theme.seitenRand)
            Spacer()
            Button("Los geht’s") {
                erzeugt = true
                let tag = tagesraetsel
                let n = tag ? 5 : groesse, s = tag ? false : schwer
                if tag { Tagesraetsel.merkeStart(spiel: "ungleichung") }
                let seed = Tagesraetsel.seed(spiel: "ungleichung")
                Task {
                    let p = await Task.detached(priority: .userInitiated) { () -> Ungleichung in
                        if tag { var g = ZufallsQuelle(seed: seed); return Ungleichung(n: n, schwer: s, mit: &g) }
                        var g = SystemRandomNumberGenerator(); return Ungleichung(n: n, schwer: s, mit: &g)
                    }.value
                    rätsel = p; erzeugt = false; wahl = nil; tipps = 0; start = Date(); gemeldet = false
                }
            }.buttonStyle(HauptKnopfStil()).disabled(erzeugt).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private func brett(_ p: Ungleichung) -> some View {
        let fehler = p.fehler
        return VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: p.geloest ? String(localized: "Gelöst!") : String(localized: "\(p.n) × \(p.n)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { rätsel = nil }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            GeometryReader { g in
                let z = min(g.size.width, g.size.height) / CGFloat(p.n)
                ZStack(alignment: .topLeading) {
                    ForEach(0..<(p.n * p.n), id: \.self) { i in
                        let x = i % p.n, y = i / p.n
                        ZStack {
                            RoundedRectangle(cornerRadius: Design.Ecke.klein).fill(wahl == i ? Color.appFlaeche.opacity(0.3) : Color.kartenGrund)
                            RoundedRectangle(cornerRadius: Design.Ecke.klein).stroke(fehler.contains(i) ? Color.red : Color.secondary.opacity(0.4), lineWidth: fehler.contains(i) ? 3 : 1)
                            if p.werte[i] != 0 {
                                Text(verbatim: "\(p.werte[i])").font(.system(size: z * 0.45, weight: p.vorgaben.contains(i) ? .bold : .regular, design: Design.zahlDesign))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                                    .foregroundStyle(p.vorgaben.contains(i) ? Color.primary : Color.appFlaeche)
                            }
                        }
                        .frame(width: z * 0.78, height: z * 0.78)
                        .position(x: (CGFloat(x) + 0.5) * z, y: (CGFloat(y) + 0.5) * z)
                        .onTapGesture { if !p.vorgaben.contains(i) && !p.geloest { wahl = i } }
                        .accessibilityElement(children: .ignore)   // G1
                        .accessibilityLabel(Text("Zeile \(y + 1), Spalte \(x + 1)\(p.werte[i] == 0 ? String(localized: ", leer") : ", \(p.werte[i])")\(p.vorgaben.contains(i) ? String(localized: ", vorgegeben") : "")\(fehler.contains(i) ? String(localized: ", Fehler") : "")"))
                        .accessibilityAddTraits(p.vorgaben.contains(i) ? [] : .isButton)
                        .accessibilityAddTraits(wahl == i ? .isSelected : [])
                    }
                    ForEach(p.zeichen, id: \.self) { zz in
                        let ax = zz.a % p.n, ay = zz.a / p.n, bx = zz.b % p.n, by = zz.b / p.n
                        let waagrecht = ay == by
                        // Spitze zeigt zur kleineren Zahl (a < b)
                        let symbol: String = waagrecht ? (bx > ax ? "chevron.left" : "chevron.right") : (by > ay ? "chevron.up" : "chevron.down")
                        Image(systemName: symbol).font(.system(size: z * 0.2, weight: .bold)).foregroundStyle(.secondary)   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
                            .rotationEffect(.degrees(0))
                            .position(x: (CGFloat(ax + bx) / 2 + 0.5) * z, y: (CGFloat(ay + by) / 2 + 0.5) * z)
                    }
                }.frame(width: z * CGFloat(p.n), height: z * CGFloat(p.n)).frame(maxWidth: .infinity)
            }.aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth).padding(.horizontal, Theme.seitenRand)
            if p.geloest {
                VStack(spacing: Design.Abstand.s) {
                    Text("Gelöst in \(Int(Date().timeIntervalSince(start))) Sekunden!").font(.headline)
                    Button("Ergebnis") { beenden(p) }.buttonStyle(HauptKnopfStil())
                }.padding(.horizontal, Theme.seitenRand)
            } else {
                HStack(spacing: Design.Abstand.s) {
                    ForEach(1...p.n, id: \.self) { w in
                        Button { if let i = wahl { rätsel?.setze(i, w) } } label: { Text(verbatim: "\(w)").font(.title3.bold()).frame(minWidth: 44, minHeight: 46) }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    }
                    Button { if let i = wahl { rätsel?.setze(i, 0) } } label: { Image(systemName: "delete.left").frame(minWidth: 44, minHeight: 46) }.accessibilityLabel("Löschen").nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
                ZugKnoepfe(kannZurueck: p.kannZurueck, zurueck: { rätsel?.zurueck() },
                           tipp: { var g = SystemRandomNumberGenerator()
                                   if let i = rätsel?.tipp(mit: &g) { ansage(String(localized: "Tipp: Zeile \(i / p.n + 1), Spalte \(i % p.n + 1), Zahl \(p.loesung[i])")) }
                                   tipps += 1 })
            }
            Spacer(minLength: 0)
        }
    }

    private var tagesSchluessel: String { "ungleichung.tag.\(Tagesraetsel.tag())" }
    private var groessenSchluessel: String { "ungleichung.\(groesse).\(schwer)" }

    private func beenden(_ p: Ungleichung) {
        guard !gemeldet else { return }
        gemeldet = true
        let sek = Int(Date().timeIntervalSince(start))
        let punkte = max(10, p.n * 100 - sek - tipps * 40)
        var rekord = false
        if !tagesraetsel { Leiter.sieg("ungleichung", stufe: schwer ? 1 : 0, mitTipp: tipps > 0) }   // D4
        if tipps == 0 { rekord = Bestleistung.melden(tagesraetsel ? "ungleichung.tag.\(Tagesraetsel.startTag(spiel: "ungleichung"))" : "ungleichung.\(p.n).\(schwer)", wert: max(1, sek)) }
        ende(SpielEnde(reihenfolge: [name], punkte: ["\(punkte)"], info: String(localized: "\(sek) Sekunden, \(tipps) Tipps") + (rekord ? " · " + String(localized: "Neue Bestzeit!") : "")))
    }
}
#endif
