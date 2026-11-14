// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import ArcadeKern
import SteinfallKern

@MainActor
public struct SteinfallModul: SpielModul {
    public init() {}
    public let id = "steinfall"
    public let name = "Steinfall"
    public let gattung = Gattung.arcade
    public let farbe = AkzentFarbeWert.violett
    public let symbol = "square.grid.3x2.fill"
    public let spielerzahl = 1...1
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Steine stapeln, Reihen auflösen", farbe: farbe, spieler: 1...1,
                            regeln: "Fünferteile fallen in ein Feld. Verschiebe sie, drehe sie und lass sie landen. Ist eine Reihe lückenlos gefüllt, löst sie sich auf und bringt Punkte – mehrere Reihen zugleich bringen deutlich mehr. Alle sechs aufgelöste Reihen wird es schneller. Ein gelandetes Teil lässt sich noch kurz verschieben. Das Spiel ist aus, wenn ein neues Teil oben nicht mehr ins Feld passt. Steuerung: nach links oder rechts ziehen verschiebt, antippen dreht, nach unten ziehen beschleunigt, nach unten wischen lässt das Teil sofort fallen – oder die Knöpfe darunter.",
                            einzelText: "Ein Spieler: Wie viele Punkte schaffst du?", zeigtRekord: true,
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SteinfallSpiel(name: teilnehmer[0].name, rekordFuer: { umgebung.statistik.rekord(spiel: "steinfall", stufe: $0) }, ende: ende, abbrechen: abbrechen)
        }.mitAnleitung(Self.anleitung))
    }
}

struct SteinfallSpiel: View {
    let name: String
    let rekordFuer: (Int) -> Int?
    private var rekord: Int? { rekordFuer(spiel.schwierigkeit) }
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel = ArcadeStand.laden(Steinfall.self, spiel: "steinfall", phase: \.phase) ?? Steinfall(schwierigkeit: ComputerStufe.gespeichert("steinfall").rawValue)
    @State private var zieherX: CGFloat = 0
    @State private var bewegt = false

    private static let farben: [Color] = [AkzentFarbeWert.violett, .blau, .tuerkis, .gruen, .orange, .pink].map(\.color)

    var body: some View {
        huelle.arcadeStand("steinfall", phase: spiel.phase) { spiel }
    }

    @ViewBuilder private var stufenWahl: some View {
        if spiel.phase == .bereit {
            ArcadeStufeWahl(spiel: "steinfall", stufe: spiel.schwierigkeit) { spiel = Steinfall(schwierigkeit: $0) }
        }
    }

    private var huelle: some View {
        ArcadeHuelle(punkte: spiel.punkte, status: String(localized: "Stufe \(spiel.stufe)"), rekord: rekord, ansage: String(localized: "\(spiel.punkte) Punkte, Stufe \(spiel.stufe)"), phase: spiel.phase,
                     hinweis: "Ziehen: verschieben · Tippen: drehen · Nach unten ziehen: schneller",
                     schritt: { spiel.schritt($0) }, beginnen: { spiel.starte() }, neu: { SpielStand.loeschen("steinfall"); spiel = Steinfall(schwierigkeit: ComputerStufe.gespeichert("steinfall").rawValue) },
                     abbrechen: abbrechen, beenden: beenden) {
            HStack(alignment: .top, spacing: Design.Abstand.m) {
                SpielfeldKarte { feld }
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel("Nächster")
                    Canvas { ctx, _ in
                        let form = Steinfall.formen[spiel.naechste]
                        for c in form { ctx.fill(Path(roundedRect: CGRect(x: CGFloat(c.x) * 11 + 1, y: CGFloat(c.y) * 11 + 1, width: 10, height: 10), cornerRadius: 2), with: .color(Self.farben[spiel.naechste])) }
                    }.frame(width: 44, height: 60)
                    Text("Reihen: \(spiel.reihen)").font(.footnote.monospacedDigit()).foregroundStyle(.secondary)
                }.frame(width: 84, alignment: .leading)
            }
        } unten: {
            VStack(spacing: 10) {
                stufenWahl
            HStack(spacing: 10) {
                RundKnopf(symbol: "arrow.left", beschriftung: "Links") { spiel.bewege(-1) }
                RundKnopf(symbol: "arrow.clockwise", beschriftung: "Drehen") { spiel.drehe() }
                RundKnopf(symbol: "arrow.down.to.line", beschriftung: "Fallen lassen") { spiel.hartFallen() }
                RundKnopf(symbol: "arrow.right", beschriftung: "Rechts") { spiel.bewege(1) }
            }
            }
        }
    }

    private func beenden() {
        ende(SpielEnde(reihenfolge: [name], info: String(localized: "\(spiel.reihen) Reihen"),
                       arcade: ArcadeAusgang(punkte: spiel.punkte, grund: spiel.phase.grund, kennzahlen: ["stufe": Double(spiel.schwierigkeit)])))
    }

    private var feld: some View {
        GeometryReader { g in
            let z = min(g.size.width / CGFloat(Steinfall.breite), g.size.height / CGFloat(Steinfall.hoehe))
            Canvas { ctx, _ in
                func zelle(_ x: Int, _ y: Int, _ c: Color, _ rand: Bool = false) {
                    let r = CGRect(x: CGFloat(x) * z + 1, y: CGFloat(y) * z + 1, width: z - 2, height: z - 2)
                    if rand { ctx.stroke(Path(roundedRect: r.insetBy(dx: 1, dy: 1), cornerRadius: 3), with: .color(c.opacity(0.7)), lineWidth: 1.5) }
                    else { ctx.fill(Path(roundedRect: r, cornerRadius: 3), with: .color(c)) }
                }
                for y in 0..<Steinfall.hoehe { for x in 0..<Steinfall.breite {
                    let n = spiel.feld[y][x]
                    zelle(x, y, n == 0 ? Color.secondary.opacity(0.10) : Self.farben[(n - 1) % Self.farben.count])
                } }
                if !spiel.vorbei {
                    for c in spiel.schatten where c.y >= 0 { zelle(c.x, c.y, Self.farben[spiel.form], true) }
                    for c in spiel.aktuelleFelder where c.y >= 0 { zelle(c.x, c.y, Self.farben[spiel.form]) }
                }
            }
            .frame(width: z * CGFloat(Steinfall.breite), height: z * CGFloat(Steinfall.hoehe))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    guard spiel.phase.laeuft else { return }
                    let dx = v.translation.width - zieherX
                    let schritte = Int(dx / z)
                    if schritte != 0 {
                        bewegt = true
                        for _ in 0..<abs(schritte) { spiel.bewege(schritte > 0 ? 1 : -1) }
                        zieherX += CGFloat(schritte) * z
                    }
                    if v.translation.height > 30, v.translation.height > abs(v.translation.width) { bewegt = true; spiel.weich = true }
                    if abs(v.translation.width) > 10 || abs(v.translation.height) > 10 { bewegt = true }
                }
                .onEnded { v in
                    spiel.weich = false
                    if spiel.phase.laeuft {
                        let schnellRunter = v.predictedEndTranslation.height > 260 && v.translation.height > 40 && v.translation.height > abs(v.translation.width) * 1.5
                        if schnellRunter { spiel.hartFallen() }
                        else if !bewegt { spiel.drehe() }
                    }
                    zieherX = 0; bewegt = false
                })
        }
        .aspectRatio(CGFloat(Steinfall.breite) / CGFloat(Steinfall.hoehe), contentMode: .fit)
    }
}
#endif
