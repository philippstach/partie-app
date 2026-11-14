// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import ArcadeKern
import WolkenhuepferKern

@MainActor
public struct WolkenhuepferModul: SpielModul {
    public init() {}
    public let id = "wolkenhuepfer"
    public let name = "Wolkenhüpfer"
    public let gattung = Gattung.arcade
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "cloud.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Immer höher hüpfen", farbe: farbe, spieler: 1...1,
                            regeln: "Dein Hüpfer springt von allein. Ziehe den Finger nach links und rechts, um ihn zu lenken – am Rand kommst du auf der anderen Seite wieder heraus. Gelandet wird nur beim Fallen. Weiße Wolken tragen immer, blaue wandern hin und her, graue Wolken brechen nach dem Sprung weg, und die gelbe Feder schleudert dich besonders hoch. Je höher du kommst, desto kleiner werden die Wolken und desto weiter liegen sie auseinander. Fällst du unten aus dem Bild, ist das Spiel aus. Die erreichte Höhe ist deine Punktzahl.",
                            einzelText: "Ein Spieler: Wie hoch kommst du?", zeigtRekord: true,
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            WolkenhuepferSpiel(name: teilnehmer[0].name, rekordFuer: { umgebung.statistik.rekord(spiel: "wolkenhuepfer", stufe: $0) }, ende: ende, abbrechen: abbrechen)
        }.mitAnleitung(Self.anleitung))
    }
}

struct WolkenhuepferSpiel: View {
    let name: String
    let rekordFuer: (Int) -> Int?
    private var rekord: Int? { rekordFuer(spiel.schwierigkeit) }
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel = ArcadeStand.laden(Wolkenhuepfer.self, spiel: "wolkenhuepfer", phase: \.phase) ?? Wolkenhuepfer(schwierigkeit: ComputerStufe.gespeichert("wolkenhuepfer").rawValue)
    @State private var letzteX: CGFloat?

    var body: some View {
        huelle.arcadeStand("wolkenhuepfer", phase: spiel.phase) { spiel }
    }

    @ViewBuilder private var stufenWahl: some View {
        if spiel.phase == .bereit {
            ArcadeStufeWahl(spiel: "wolkenhuepfer", stufe: spiel.schwierigkeit) { spiel = Wolkenhuepfer(schwierigkeit: $0) }
        }
    }

    private var huelle: some View {
        ArcadeHuelle(punkte: spiel.punkte, rekord: rekord, ansage: String(localized: "\(spiel.punkte) Punkte"), phase: spiel.phase,
                     bereitText: "Tippe zum Hüpfen", hinweis: "Mit dem Finger nach links und rechts lenken",
                     schritt: { spiel.schritt($0) }, beginnen: { spiel.starte() }, neu: { SpielStand.loeschen("wolkenhuepfer"); spiel = Wolkenhuepfer(schwierigkeit: ComputerStufe.gespeichert("wolkenhuepfer").rawValue) },
                     abbrechen: abbrechen,
                     beenden: { ende(SpielEnde(reihenfolge: [name], info: String(localized: "\(spiel.spruenge) Sprünge"), arcade: ArcadeAusgang(punkte: spiel.punkte, grund: spiel.phase.grund, kennzahlen: ["stufe": Double(spiel.schwierigkeit)]))) }) {
            SpielfeldKarte {
                GeometryReader { g in
                    let w = g.size.width, h = w * Wolkenhuepfer.sichtHoehe
                    Canvas { ctx, _ in zeichne(&ctx, w: w, h: h) }
                        .frame(width: w, height: h)
                        .background(LinearGradient(colors: [AkzentFarbeWert.tuerkis.color.opacity(0.28), AkzentFarbeWert.tuerkis.color.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                        .clipShape(RoundedRectangle(cornerRadius: Design.Ecke.feld))
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in
                                let x = v.translation.width
                                if let l = letzteX { spiel.lenke(um: Double((x - l) / w) * 1.3) }
                                letzteX = x
                            }
                            .onEnded { _ in letzteX = nil })
                }
                .aspectRatio(1 / Wolkenhuepfer.sichtHoehe, contentMode: .fit)
            }
        } unten: { stufenWahl }
    }

    private func zeichne(_ ctx: inout GraphicsContext, w: CGFloat, h: CGFloat) {
        func sy(_ welt: Double) -> CGFloat { CGFloat((spiel.kamera + Wolkenhuepfer.sichtHoehe - welt) / Wolkenhuepfer.sichtHoehe) * h }
        func sx(_ welt: Double) -> CGFloat { CGFloat(welt) * w }
        for wk in spiel.wolken where !wk.weg {
            let bw = sx(wk.breite), bh = CGFloat(Wolkenhuepfer.wolkenDicke) * h / CGFloat(Wolkenhuepfer.sichtHoehe) * 1.6
            let r = CGRect(x: sx(spiel.wolkenX(wk)) - bw / 2, y: sy(wk.y + Wolkenhuepfer.wolkenDicke), width: bw, height: bh)
            let farbe: Color
            switch wk.art {
            case .fest: farbe = .white
            case .wandernd: farbe = Color(red: 0.55, green: 0.75, blue: 1)
            case .bruechig: farbe = Color.gray.opacity(0.7)
            case .feder: farbe = Color.yellow
            }
            ctx.fill(Path(roundedRect: r, cornerRadius: bh / 2), with: .color(farbe))
            ctx.stroke(Path(roundedRect: r, cornerRadius: bh / 2), with: .color(.black.opacity(0.15)), lineWidth: 1)
            if wk.art == .feder { ctx.fill(Path(roundedRect: CGRect(x: r.midX - 8, y: r.minY - 7, width: 16, height: 7), cornerRadius: 3), with: .color(.orange)) }
        }
        // Hüpfer (am Rand zweimal zeichnen, damit der Umbruch fließend aussieht)
        let rad = CGFloat(Wolkenhuepfer.halbBreite) * w * 1.15
        let streckt = min(1.25, 1 + abs(CGFloat(spiel.vy)) * 0.08)
        for ox in [0.0, -1.0, 1.0] {
            let cx = sx(spiel.x + ox)
            guard cx > -rad * 2, cx < w + rad * 2 else { continue }
            let cy = sy(spiel.y) - rad * streckt
            let body = CGRect(x: cx - rad, y: cy - rad * streckt, width: rad * 2, height: rad * 2 * streckt)
            ctx.fill(Path(ellipseIn: body), with: .color(AkzentFarbeWert.tuerkis.color))
            ctx.fill(Path(ellipseIn: CGRect(x: cx - rad * 0.55, y: cy - rad * streckt * 0.5, width: rad * 0.45, height: rad * 0.45)), with: .color(.white))
            ctx.fill(Path(ellipseIn: CGRect(x: cx + rad * 0.1, y: cy - rad * streckt * 0.5, width: rad * 0.45, height: rad * 0.45)), with: .color(.white))
        }
    }
}
#endif
