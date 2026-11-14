// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import ArcadeKern
import BallwechselKern

@MainActor
public struct BallwechselModul: SpielModul {
    public init() {}
    public let id = "ballwechsel"
    public let name = "Ballwechsel"
    public let gattung = Gattung.arcade
    public let farbe = AkzentFarbeWert.rot
    public let symbol = "circle.dotted.and.circle"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Das Schläger-Duell", farbe: farbe, spieler: 1...2, computerErlaubt: true,
                            regeln: "Schlage den Ball mit deinem Schläger zurück und lass ihn beim Gegner durch. Ziehe den Finger, um den Schläger zu bewegen – er folgt dir, so schnell er kann. Trifft der Ball die Kante des Schlägers, fliegt er schräger und schneller weg; jeder Schlag macht den Ball schneller, nach jedem Punkt beginnt er wieder langsam. Wer einen Punkt verliert, bekommt den nächsten Ball. Wer zuerst sieben Punkte hat, gewinnt. Allein spielst du gegen den Computer, der mit der Zeit Fehler macht; zu zweit zieht der zweite Spieler im oberen Feld.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            BallwechselSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitAnleitung(Self.anleitung))
    }
}

struct BallwechselSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var spiel: Ballwechsel
    @State private var ziel = Self.gespeichertesZiel
    private static var gespeichertesZiel: Int { let z = UserDefaults.standard.integer(forKey: "ballwechsel.ziel"); return [5, 7, 11, 15].contains(z) ? z : 7 }

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen
        let alt = ArcadeStand.laden(Ballwechsel.self, spiel: "ballwechsel", phase: \.phase)
        _spiel = State(initialValue: alt ?? Self.neuesSpiel(teilnehmer))
        if let alt { _ziel = State(initialValue: alt.ziel) }
    }
    private static func neuesSpiel(_ t: [SpielTeilnehmer]) -> Ballwechsel {
        let computer = t.count < 2 || t[1].computer
        return Ballwechsel(ziel: gespeichertesZiel, computer: computer, stufe: ComputerStufe.gespeichert("ballwechsel").rawValue)
    }

    private var name0: String { teilnehmer[0].name }
    private var name1: String { teilnehmer.count > 1 ? teilnehmer[1].name : String(localized: "Computer") }

    var body: some View {
        huelle.arcadeStand("ballwechsel", phase: spiel.phase) { spiel }
    }

    private var huelle: some View {
        ArcadeHuelle(punkte: spiel.punkte[0], kopf: "\(spiel.punkte[0]) : \(spiel.punkte[1])", ansage: String(localized: "Punktestand \(spiel.punkte[0]) zu \(spiel.punkte[1])"), verloren: spiel.punkte[1], phase: spiel.phase,
                     bereitText: "Tippe zum Starten",
                     hinweis: spiel.computer ? "Finger ziehen bewegt deinen Schläger – Kante lenkt steiler" : "Jeder Spieler zieht in seiner Hälfte",
                     schritt: { spiel.schritt($0) }, beginnen: { spiel.starte() }, neu: { SpielStand.loeschen("ballwechsel"); spiel = Self.neuesSpiel(teilnehmer) },
                     abbrechen: abbrechen, beenden: melden, endeGewonnen: spiel.computer ? spiel.gewinner.map { $0 == 0 } : true) {
            SpielfeldKarte {
                GeometryReader { g in
                    let w = g.size.width, h = w * Ballwechsel.hoehe
                    ZStack {
                        Canvas { ctx, _ in zeichne(&ctx, w: w) }
                            .frame(width: w, height: h)
                        steuerung(w: w, h: h)
                    }
                    .frame(width: w, height: h)
                    .background(Color.secondary.opacity(0.06))
                }
                .aspectRatio(1 / Ballwechsel.hoehe, contentMode: .fit)
            }
        } unten: {
            if spiel.phase == .bereit {
                Picker("Spielziel", selection: $ziel) { ForEach([5, 7, 11, 15], id: \.self) { Text("\($0) Punkte").tag($0) } }
                    .pickerStyle(.segmented).padding(.horizontal, Theme.seitenRand)
                    .onChange(of: ziel) { _, z in UserDefaults.standard.set(z, forKey: "ballwechsel.ziel"); spiel = Self.neuesSpiel(teilnehmer) }
            }
        }
    }

    @ViewBuilder private func steuerung(w: CGFloat, h: CGFloat) -> some View {
        if spiel.computer {
            Color.clear.contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { spiel.steuere(0, x: Double($0.location.x / w)) })
        } else {
            VStack(spacing: 0) {
                Color.clear.contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { spiel.steuere(1, x: Double($0.location.x / w)) })
                Color.clear.contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { spiel.steuere(0, x: Double($0.location.x / w)) })
            }
        }
    }

    private func melden() {
        let w = spiel.gewinner ?? 0
        let reihenfolge = w == 0 ? [name0, name1] : [name1, name0]
        let punkte = w == 0 ? [spiel.punkte[0], spiel.punkte[1]] : [spiel.punkte[1], spiel.punkte[0]]
        let info = String(localized: "Längster Ballwechsel: \(spiel.laengsteRallye)")
        ende(SpielEnde(reihenfolge: reihenfolge, punkte: punkte.map(String.init), info: info,
                       arcade: spiel.computer ? ArcadeAusgang(punkte: spiel.punkte[0], sieg: w == 0, grund: nil, kennzahlen: ["rallye": Double(spiel.laengsteRallye)]) : nil))
    }

    private func zeichne(_ ctx: inout GraphicsContext, w: CGFloat) {
        let h = w * Ballwechsel.hoehe
        ctx.stroke(Path { p in p.move(to: CGPoint(x: 0, y: h / 2)); p.addLine(to: CGPoint(x: w, y: h / 2)) }, with: .color(.secondary.opacity(0.35)), style: StrokeStyle(lineWidth: 2, dash: [6, 8]))
        for s in 0..<2 {
            let y = spiel.schlaegerY(s) * w
            let r = CGRect(x: (spiel.schlaegerX[s] - Ballwechsel.schlaegerB / 2) * w, y: y, width: Ballwechsel.schlaegerB * w, height: Ballwechsel.schlaegerH * w)
            ctx.fill(Path(roundedRect: r, cornerRadius: r.height / 2), with: .color(s == 0 ? Color.appFlaeche : Color.secondary))
        }
        let rad = Ballwechsel.radius * w
        let alpha = spiel.imSpiel ? 1.0 : 0.5
        ctx.fill(Path(ellipseIn: CGRect(x: spiel.ballX * w - rad, y: spiel.ballY * w - rad, width: rad * 2, height: rad * 2)), with: .color(.primary.opacity(alpha)))
        if !spiel.imSpiel && spiel.phase.laeuft {
            ctx.draw(Text("\(Int(spiel.aufschlagIn.rounded(.up)))").font(.system(.largeTitle, design: Design.zahlDesign).weight(.bold)).foregroundColor(.secondary), at: CGPoint(x: w / 2, y: h / 2 - 40))
        }
    }
}
#endif
