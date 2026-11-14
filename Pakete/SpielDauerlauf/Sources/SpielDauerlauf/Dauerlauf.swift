// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import ArcadeKern
import DauerlaufKern

@MainActor
public struct DauerlaufModul: SpielModul {
    public init() {}
    public let id = "dauerlauf"
    public let name = "Dauerlauf"
    public let gattung = Gattung.arcade
    public let farbe = AkzentFarbeWert.orange
    public let symbol = "figure.run"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Immer weiter, immer schneller", farbe: farbe, spieler: 1...1,
                            regeln: "Dein Läufer rennt von allein und wird dabei immer schneller. Tippe aufs Feld, um zu springen: über Hürden und über Löcher im Boden. Tippst du kurz vor der Landung, springst du gleich wieder. Wische nach unten, um dich zu ducken, wenn ein Balken in der Luft hängt. Sammle die Perlen auf dem Weg, jede bringt zehn Punkte extra. Stößt du an oder fällst du in ein Loch, ist der Lauf zu Ende. Die gelaufenen Meter plus die Perlen sind deine Punktzahl.",
                            einzelText: "Ein Spieler: Wie weit kommst du?", zeigtRekord: true,
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            DauerlaufSpiel(name: teilnehmer[0].name, rekordFuer: { umgebung.statistik.rekord(spiel: "dauerlauf", stufe: $0) }, ende: ende, abbrechen: abbrechen)
        }.mitAnleitung(Self.anleitung))
    }
}

struct DauerlaufSpiel: View {
    let name: String
    let rekordFuer: (Int) -> Int?
    private var rekord: Int? { rekordFuer(spiel.schwierigkeit) }
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel = ArcadeStand.laden(Dauerlauf.self, spiel: "dauerlauf", phase: \.phase) ?? Dauerlauf(schwierigkeit: ComputerStufe.gespeichert("dauerlauf").rawValue)
    @State private var geduckt = false

    var body: some View {
        huelle.arcadeStand("dauerlauf", phase: spiel.phase) { spiel }
    }

    @ViewBuilder private var stufenWahl: some View {
        if spiel.phase == .bereit {
            ArcadeStufeWahl(spiel: "dauerlauf", stufe: spiel.schwierigkeit) { spiel = Dauerlauf(schwierigkeit: $0) }
        }
    }

    private var huelle: some View {
        ArcadeHuelle(punkte: spiel.punkte, status: "\(spiel.meter) m", rekord: rekord, ansage: String(localized: "\(spiel.punkte) Punkte, \(spiel.meter) Meter"), phase: spiel.phase,
                     bereitText: "Tippe, um loszulaufen", hinweis: "Tippen = springen · nach unten wischen = ducken",
                     schritt: { spiel.schritt($0) }, beginnen: { spiel.starte() }, neu: { SpielStand.loeschen("dauerlauf"); spiel = Dauerlauf(schwierigkeit: ComputerStufe.gespeichert("dauerlauf").rawValue) },
                     abbrechen: abbrechen,
                     beenden: { ende(SpielEnde(reihenfolge: [name], info: String(localized: "\(spiel.meter) Meter, \(spiel.gesammelt) Perlen"), arcade: ArcadeAusgang(punkte: spiel.punkte, grund: spiel.phase.grund, kennzahlen: ["stufe": Double(spiel.schwierigkeit)]))) }) {
            SpielfeldKarte {
                GeometryReader { g in
                    let w = g.size.width, h = w * Dauerlauf.sichtHoehe
                    Canvas { ctx, _ in zeichne(&ctx, w: w, h: h) }
                        .frame(width: w, height: h)
                        .background(LinearGradient(colors: [Color.appFlaeche.opacity(0.22), Color.appFlaeche.opacity(0.04)], startPoint: .top, endPoint: .bottom))
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                if !geduckt, v.translation.height > 24 { geduckt = true; spiel.ducke() }
                            }
                            .onEnded { v in
                                if !geduckt, abs(v.translation.height) < 24 { spiel.springe() }
                                geduckt = false
                            })
                }
                .aspectRatio(1 / Dauerlauf.sichtHoehe, contentMode: .fit)
            }
        } unten: { stufenWahl }
    }

    private func zeichne(_ ctx: inout GraphicsContext, w: CGFloat, h: CGFloat) {
        let boden = h * 0.82                 // Bildhöhe der Lauffläche
        func sx(_ welt: Double) -> CGFloat { CGFloat(welt - spiel.distanz) * w }
        func sy(_ hoch: Double) -> CGFloat { boden - CGFloat(hoch) * w }
        let akzent = Color.appFlaeche
        // Hintergrundhügel (wandern langsamer = Tiefe)
        for i in 0..<4 {
            let basis = CGFloat(i) * 0.37 - CGFloat(spiel.distanz * 0.3).truncatingRemainder(dividingBy: 0.37 * 4) 
            var x = basis * w
            if x < -0.3 * w { x += 0.37 * 4 * w }
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: boden - 0.1 * w, width: 0.3 * w, height: 0.2 * w)), with: .color(akzent.opacity(0.10)))
        }
        // Boden mit Löchern
        let loecher = spiel.hindernisse.filter { $0.art == .spalt }
        var streifen: [(CGFloat, CGFloat)] = []
        var links: CGFloat = 0
        for l in loecher.sorted(by: { $0.x < $1.x }) {
            let a = sx(l.x), b = sx(l.x + l.breite)
            if a > links { streifen.append((links, min(a, w))) }
            links = max(links, b)
        }
        if links < w { streifen.append((links, w)) }
        for (a, b) in streifen where b > a {
            ctx.fill(Path(CGRect(x: a, y: boden, width: b - a, height: h - boden)), with: .color(akzent.opacity(0.55)))
            ctx.fill(Path(CGRect(x: a, y: boden, width: b - a, height: 4)), with: .color(akzent))
        }
        // Hindernisse
        for o in spiel.hindernisse {
            let x = sx(o.x), b = CGFloat(o.breite) * w
            switch o.art {
            case .huerde:
                let hh = CGFloat(Dauerlauf.huerdeHoehe) * w
                ctx.fill(Path(roundedRect: CGRect(x: x, y: boden - hh, width: b, height: hh), cornerRadius: 4), with: .color(.primary.opacity(0.75)))
            case .balken:
                let unten = sy(Dauerlauf.balkenUnten), oben = sy(Dauerlauf.balkenOben)
                ctx.fill(Path(CGRect(x: x + b * 0.15, y: 0, width: 3, height: oben)), with: .color(.secondary.opacity(0.6)))
                ctx.fill(Path(CGRect(x: x + b * 0.85, y: 0, width: 3, height: oben)), with: .color(.secondary.opacity(0.6)))
                ctx.fill(Path(roundedRect: CGRect(x: x, y: oben, width: b, height: unten - oben), cornerRadius: 4), with: .color(.primary.opacity(0.75)))
            case .spalt: break
            }
        }
        // Perlen
        let pr = 0.014 * w
        for p in spiel.perlen where !p.weg {
            let px = sx(p.x), py = sy(p.y)
            ctx.fill(Path(ellipseIn: CGRect(x: px - pr, y: py - pr, width: pr * 2, height: pr * 2)), with: .color(.yellow))
            ctx.stroke(Path(ellipseIn: CGRect(x: px - pr, y: py - pr, width: pr * 2, height: pr * 2)), with: .color(.orange), lineWidth: 1)
        }
        // Läufer
        let lx = CGFloat(Dauerlauf.laeuferX) * w
        let lh = CGFloat(spiel.hoehe) * w
        let fuss = sy(spiel.y)
        let breite = 0.045 * w
        let phase = sin(spiel.distanz * 70)
        ctx.fill(Path(roundedRect: CGRect(x: lx - breite / 2, y: fuss - lh * 0.8, width: breite, height: lh * 0.6), cornerRadius: 6), with: .color(akzent))
        ctx.fill(Path(ellipseIn: CGRect(x: lx - breite * 0.42 + (spiel.geduckt ? breite * 0.2 : 0), y: fuss - lh, width: breite * 0.84, height: breite * 0.84)), with: .color(akzent))
        ctx.fill(Path(ellipseIn: CGRect(x: lx + 0.002 * w, y: fuss - lh * 0.93, width: 0.01 * w, height: 0.01 * w)), with: .color(.white))
        // Beine
        let beinHub = spiel.y > 0 ? 0 : CGFloat(phase) * breite * 0.35
        ctx.fill(Path(roundedRect: CGRect(x: lx - breite * 0.35 + beinHub, y: fuss - lh * 0.22, width: 4, height: lh * 0.22), cornerRadius: 2), with: .color(akzent))
        ctx.fill(Path(roundedRect: CGRect(x: lx + breite * 0.2 - beinHub, y: fuss - lh * 0.22, width: 4, height: lh * 0.22), cornerRadius: 2), with: .color(akzent))
    }
}
#endif
