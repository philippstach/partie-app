// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import ArcadeKern
import MauerbrecherKern

@MainActor
public struct MauerbrecherModul: SpielModul {
    public init() {}
    public let id = "mauerbrecher"
    public let name = "Mauerbrecher"
    public let gattung = Gattung.arcade
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "rectangle.split.3x3.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Mauer knacken, Serie halten", farbe: farbe, spieler: 1...1,
                            regeln: "Lenke den Schläger mit dem Finger und lass den Ball nicht fallen. Tippe, um den Ball abzuschießen. Jeder Treffer bricht einen Stein, harte Steine brauchen mehrere. Gelingen mehrere Treffer hintereinander, ohne dass der Ball den Schläger berührt, steigt dein Faktor bis ×4. Aus Steinen fallen manchmal Gaben: breiter Schläger, drei Bälle oder ein Extraleben – fange sie mit dem Schläger. Die Mauer rückt langsam nach unten; erreicht sie den Schläger, ist das Spiel aus. Du hast drei Leben. Ist die Mauer weg, kommt eine neue, und der Ball wird schneller.",
                            einzelText: "Ein Spieler: Wie viele Punkte schaffst du?", zeigtRekord: true,
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            MauerbrecherSpiel(name: teilnehmer[0].name, rekordFuer: { umgebung.statistik.rekord(spiel: "mauerbrecher", stufe: $0) }, ende: ende, abbrechen: abbrechen)
        }.mitAnleitung(Self.anleitung))
    }
}

struct MauerbrecherSpiel: View {
    let name: String
    let rekordFuer: (Int) -> Int?
    private var rekord: Int? { rekordFuer(spiel.schwierigkeit) }
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel = ArcadeStand.laden(Mauerbrecher.self, spiel: "mauerbrecher", phase: \.phase) ?? Mauerbrecher(schwierigkeit: ComputerStufe.gespeichert("mauerbrecher").rawValue)

    private static let steinFarben: [Color] = [AkzentFarbeWert.rot.color, AkzentFarbeWert.orange.color, AkzentFarbeWert.violett.color]

    var body: some View {
        huelle.arcadeStand("mauerbrecher", phase: spiel.phase) { spiel }
    }

    @ViewBuilder private var stufenWahl: some View {
        if spiel.phase == .bereit {
            ArcadeStufeWahl(spiel: "mauerbrecher", stufe: spiel.schwierigkeit) { spiel = Mauerbrecher(schwierigkeit: $0) }
        }
    }

    private var huelle: some View {
        ArcadeHuelle(punkte: spiel.punkte, status: "\(String(repeating: "♥", count: max(0, spiel.leben))) · ×\(spiel.faktor)", rekord: rekord,
                     ansage: String(localized: "\(spiel.punkte) Punkte, \(spiel.leben) Leben, Faktor \(spiel.faktor)"), verloren: spiel.verloreneLeben, phase: spiel.phase,
                     bereitText: "Tippe zum Starten",
                     hinweis: spiel.haftet && spiel.phase.laeuft ? "Tippe, um den Ball abzuschießen" : "Finger ziehen lenkt den Schläger",
                     schritt: { spiel.schritt($0) }, beginnen: { spiel.starte() }, neu: { SpielStand.loeschen("mauerbrecher"); spiel = Mauerbrecher(schwierigkeit: ComputerStufe.gespeichert("mauerbrecher").rawValue) },
                     abbrechen: abbrechen,
                     beenden: { ende(SpielEnde(reihenfolge: [name], info: String(localized: "Stufe \(spiel.stufe)"), arcade: ArcadeAusgang(punkte: spiel.punkte, grund: spiel.phase.grund, kennzahlen: ["stufe": Double(spiel.schwierigkeit)]))) }) {
            SpielfeldKarte {
                GeometryReader { g in
                    let w = g.size.width, h = w * Mauerbrecher.hoehe
                    Canvas { ctx, _ in zeichne(&ctx, w: w) }
                        .frame(width: w, height: h)
                        .background(Color.secondary.opacity(0.06))
                        .contentShape(Rectangle())
                        .gesture(DragGesture(minimumDistance: 0)
                            .onChanged { v in spiel.zielen(Double(v.location.x / w)) }
                            .onEnded { v in
                                if abs(v.translation.width) < 8, abs(v.translation.height) < 8 { spiel.abschuss() }
                            })
                }
                .aspectRatio(1 / Mauerbrecher.hoehe, contentMode: .fit)
            }
        } unten: { stufenWahl }
    }

    private func zeichne(_ ctx: inout GraphicsContext, w: CGFloat) {
        for s in spiel.steine {
            let k = spiel.steinKasten(s)
            let r = CGRect(x: k.x * w + 1, y: k.y * w + 1, width: k.b * w - 2, height: k.h * w - 2)
            let c = Self.steinFarben[min(max(s.leben, 1), 3) - 1]
            ctx.fill(Path(roundedRect: r, cornerRadius: 4), with: .color(c.opacity(s.leben < s.start ? 0.6 : 0.95)))
        }
        for gabe in spiel.gaben {
            let r = CGRect(x: gabe.x * w - 14, y: gabe.y * w - 10, width: 28, height: 20)
            let (farbe, text): (Color, String) = switch gabe.art { case .breit: (.green, "↔"); case .dreifach: (.blue, "●●●"); case .leben: (.pink, "♥") }
            ctx.fill(Path(roundedRect: r, cornerRadius: 10), with: .color(farbe))
            ctx.draw(Text(text).font(.caption.weight(.bold)).foregroundColor(.white), at: CGPoint(x: r.midX, y: r.midY))
        }
        let sk = spiel.schlaeger
        ctx.fill(Path(roundedRect: CGRect(x: sk.x * w, y: sk.y * w, width: sk.b * w, height: sk.h * w), cornerRadius: sk.h * w / 2), with: .color(Color.appFlaeche))
        let r = Mauerbrecher.radius * w
        for b in spiel.baelle {
            ctx.fill(Path(ellipseIn: CGRect(x: b.x * w - r, y: b.y * w - r, width: r * 2, height: r * 2)), with: .color(.primary))
        }
    }
}
#endif
