// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import LagerplatzKern

@MainActor
public struct LagerplatzModul: SpielModul {
    public init() {}
    public let id = "lagerplatz"
    public let name = "Lagerplatz"
    public let gattung = Gattung.raetsel
    public let farbe = AkzentFarbeWert.braun
    public let symbol = "shippingbox.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Kisten an ihren Platz schieben", farbe: farbe, spieler: 1...1,
                            regeln: "Du bist der Lagerarbeiter und musst alle Kisten auf die markierten Plätze schieben. Ziehe den Finger über das Feld, um dich zu bewegen: Pro Feldbreite machst du einen Schritt. Läufst du gegen eine Kiste, schiebst du sie ein Feld weiter, aber nur, wenn dahinter Platz ist. Kisten kannst du nicht ziehen und nur einzeln schieben; Wände sind im Weg. Steckt eine Kiste fest, hilft der Zurück-Knopf (beliebig oft). Jede Stufe ist neu gemischt und garantiert lösbar. Mit jeder Stufe kommen mehr Kisten und Wände dazu. Beende den Lauf, wann du willst; jede gelöste Stufe zählt.",
                            einzelText: "Ein Spieler: Wie viele Stufen schaffst du?",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            LagerplatzSpiel(name: teilnehmer[0].name, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Schiebe alle Kisten auf die markierten Plätze, um die Stufe zu lösen, und löse so viele Stufen wie möglich.").mitAnleitung(Self.anleitung))
    }
}

/// Gespeicherter Lauf: aktuelle Stufe mit Zugverlauf, gelöste Stufen, Tageslauf.
struct LagerplatzStand: Codable {
    var lager: Lagerplatz
    var geloest: Int
    var tag: Bool
}

struct LagerplatzSpiel: View {
    let name: String
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var lager: Lagerplatz
    @State private var geloest = 0
    @State private var anker: CGPoint?
    @State private var zufall = SystemRandomNumberGenerator()
    @State private var tag = false
    @State private var tippText: String?
    @State private var tippRechnet = false

    init(name: String, ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.name = name; self.ende = ende; self.abbrechen = abbrechen
        var g = SystemRandomNumberGenerator()
        _lager = State(initialValue: Lagerplatz(stufe: 1, mit: &g))
    }

    /// Neue Stufe; im Tageslauf für alle am selben Tag gleich.
    private func stufe(_ nummer: Int) -> Lagerplatz {
        if tag { var g = Tagesraetsel.generator(spiel: "lagerplatz", variante: "\(nummer)"); return Lagerplatz(stufe: nummer, mit: &g) }
        var g = SystemRandomNumberGenerator(); return Lagerplatz(stufe: nummer, mit: &g)
    }

    private func neuerLauf(tages: Bool, start: Int) { tag = tages; geloest = 0; tippText = nil; lager = stufe(start) }

    private func holeTipp() {
        tippRechnet = true
        let stand = lager
        Task {
            let r = await Task.detached { stand.hinweis() }.value
            if lager == stand {
                switch r {
                case .hoch?: tippText = String(localized: "Tipp: nach oben ↑")
                case .runter?: tippText = String(localized: "Tipp: nach unten ↓")
                case .links?: tippText = String(localized: "Tipp: nach links ←")
                case .rechts?: tippText = String(localized: "Tipp: nach rechts →")
                case nil: tippText = String(localized: "Kein Tipp gefunden – versuche „Zurück“.")
                }
            }
            tippRechnet = false
        }
    }

    private func beenden() {
        ende(SpielEnde(reihenfolge: [name], punkte: ["\(geloest)"], info: String(localized: "\(geloest) Stufen gelöst") + Bestleistung.zusatz("lagerplatz", tages: tag, wert: geloest, hoeherIstBesser: true)))
    }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: String(localized: "Stufe \(lager.stufe)"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Stufe neu starten", systemImage: "arrow.counterclockwise") { while lager.kannZurueck { lager.zurueck() } }
                    Button("Neuer Lauf: Anfänger", systemImage: "shuffle") { neuerLauf(tages: false, start: 1) }
                    Button("Neuer Lauf: Fortgeschritten", systemImage: "shuffle") { neuerLauf(tages: false, start: 4) }
                    Button("Neuer Lauf: Experte", systemImage: "shuffle") { neuerLauf(tages: false, start: 8) }
                    Button("Tageslauf", systemImage: "calendar") { neuerLauf(tages: true, start: 1) }
                    if let b = Bestleistung.lesen(Bestleistung.schluessel("lagerplatz", tages: tag)) { Text("Beste Stufenzahl: \(b)") }
                    Button("Lauf beenden", systemImage: "flag.checkered", action: beenden)
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            HStack {
                Label("\(lager.kistenAufZiel)/\(lager.kisten.count)", systemImage: "shippingbox").font(.footnote.weight(.semibold))
                Spacer()
                Text("Schritte: \(lager.schritte)").font(.footnote).foregroundStyle(.secondary)
            }.padding(.horizontal, Theme.seitenRand)
            SpielfeldKarte {
                GeometryReader { g in
                    let z = min(g.size.width / CGFloat(lager.breite), g.size.height / CGFloat(lager.hoehe))
                    Canvas { ctx, _ in zeichne(&ctx, z) }
                        .frame(width: z * CGFloat(lager.breite), height: z * CGFloat(lager.hoehe)).frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .accessibilityElement(children: .ignore)   // G1
                        .accessibilityLabel(Text("Lagerplatz, \(lager.breite) mal \(lager.hoehe)"))
                        .accessibilityValue(Text("\(lager.kistenAufZiel) von \(lager.kisten.count) Kisten am Ziel, \(lager.schritte) Schritte"))
                        .accessibilityHint(Text("In eine Richtung wischen, um den Arbeiter zu bewegen."))
                        .accessibilityAction(named: Text("Nach links")) { if !lager.geloest { lager.bewege(.links); tippText = nil } }
                        .accessibilityAction(named: Text("Nach rechts")) { if !lager.geloest { lager.bewege(.rechts); tippText = nil } }
                        .accessibilityAction(named: Text("Nach oben")) { if !lager.geloest { lager.bewege(.hoch); tippText = nil } }
                        .accessibilityAction(named: Text("Nach unten")) { if !lager.geloest { lager.bewege(.runter); tippText = nil } }
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                guard !lager.geloest else { return }
                                let a = anker ?? v.startLocation
                                let dx = v.location.x - a.x, dy = v.location.y - a.y
                                guard max(abs(dx), abs(dy)) >= z * 0.7 else { anker = a; return }
                                lager.bewege(abs(dx) > abs(dy) ? (dx > 0 ? .rechts : .links) : (dy > 0 ? .runter : .hoch)); tippText = nil
                                anker = v.location
                            }
                            .onEnded { _ in anker = nil })
                }
                .aspectRatio(CGFloat(lager.breite) / CGFloat(lager.hoehe), contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth)
            }.padding(.horizontal, Theme.seitenRand)
            if lager.geloest {
                VStack(spacing: Design.Abstand.s) {
                    Text("Geschafft! \(lager.schritte) Schritte, \(lager.schiebungen) Schübe").font(.headline)
                    Button("Weiter zu Stufe \(lager.stufe + 1)") {
                        geloest += 1
                        lager = stufe(lager.stufe + 1)
                    }.buttonStyle(HauptKnopfStil())
                }.padding(.horizontal, Theme.seitenRand)
            } else {
                if !lager.festeKisten.isEmpty {
                    Label("Eine Kiste steckt in einer Ecke fest – mit „Zurück“ geht es weiter.", systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote).foregroundStyle(.orange).multilineTextAlignment(.center).padding(.horizontal, Theme.seitenRand)
                }
                if let t = tippText { Text(t).font(.headline).foregroundStyle(.orange) }
                HStack(spacing: Design.Abstand.m) {
                    Button { holeTipp() } label: { if tippRechnet { ProgressView() } else { Label("Tipp", systemImage: "lightbulb") } }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(tippRechnet)
                    Button { lager.zurueck(); tippText = nil } label: { Label("Zurück", systemImage: "arrow.uturn.backward") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(!lager.kannZurueck)
                }
            }
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .weicheAnimation(bei: lager)
        .spielHaptik(zug: lager, erfolg: lager.geloest, fehler: false).fortsetzbar("lagerplatz", Binding(
            get: { LagerplatzStand(lager: lager, geloest: geloest, tag: tag) },
            set: { lager = $0.lager; geloest = $0.geloest; tag = $0.tag }),
            pruefen: { $0.lager.istKonsistent })
    }

    private func zeichne(_ ctx: inout GraphicsContext, _ z: CGFloat) {
        let akzent = Color.appFlaeche
        for y in 0..<lager.hoehe { for x in 0..<lager.breite {
            let p = LPos(x, y)
            let r = CGRect(x: CGFloat(x) * z, y: CGFloat(y) * z, width: z, height: z)
            if lager.waende.contains(p) {
                ctx.fill(Path(roundedRect: r.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 4), with: .color(.gray.opacity(0.55)))
            } else {
                ctx.fill(Path(r), with: .color(akzent.opacity((x + y) % 2 == 0 ? 0.10 : 0.05)))
                if lager.ziele.contains(p) {
                    ctx.stroke(Path(ellipseIn: r.insetBy(dx: z * 0.3, dy: z * 0.3)), with: .color(akzent), lineWidth: 3)
                }
            }
        } }
        for k in lager.kisten {
            let r = CGRect(x: CGFloat(k.x) * z + z * 0.1, y: CGFloat(k.y) * z + z * 0.1, width: z * 0.8, height: z * 0.8)
            let drauf = lager.ziele.contains(k)
            let fest = lager.festeKisten.contains(k)
            ctx.fill(Path(roundedRect: r, cornerRadius: 5), with: .color(drauf ? Color.green : (fest ? Color.red.opacity(0.8) : Color.brown)))
            ctx.stroke(Path(roundedRect: r, cornerRadius: 5), with: .color(.white.opacity(0.7)), lineWidth: 2)
            var kreuz = Path(); kreuz.move(to: CGPoint(x: r.minX + 4, y: r.minY + 4)); kreuz.addLine(to: CGPoint(x: r.maxX - 4, y: r.maxY - 4))
            kreuz.move(to: CGPoint(x: r.maxX - 4, y: r.minY + 4)); kreuz.addLine(to: CGPoint(x: r.minX + 4, y: r.maxY - 4))
            ctx.stroke(kreuz, with: .color(.white.opacity(0.35)), lineWidth: 2)
        }
        let c = CGPoint(x: (CGFloat(lager.spieler.x) + 0.5) * z, y: (CGFloat(lager.spieler.y) + 0.5) * z)
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - z * 0.32, y: c.y - z * 0.32, width: z * 0.64, height: z * 0.64)), with: .color(akzent))
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - z * 0.32, y: c.y - z * 0.32, width: z * 0.64, height: z * 0.64)), with: .color(.white), lineWidth: 2)
    }
}
#endif
