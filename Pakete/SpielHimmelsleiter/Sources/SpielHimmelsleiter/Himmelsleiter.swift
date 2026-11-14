// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import HimmelsleiterKern

@MainActor
public struct HimmelsleiterModul: SpielModul {
    public init() {}
    public let id = "himmelsleiter"
    public let name = "Himmelsleiter"
    public let gattung = Gattung.wuerfel
    public let farbe = AkzentFarbeWert.blau
    public let symbol = "arrow.up.right.circle.fill"
    public let spielerzahl = 2...4
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Rauf auf die Leitern, runter von den Wolken", farbe: farbe, spieler: 2...4, computerErlaubt: true,
                            wuerfelWahl: true, regeln: "Alle starten vor dem Feld 1 und würfeln reihum. Du ziehst so viele Felder, wie der Würfel zeigt. Endet dein Zug unten an einer Leiter, kletterst du nach oben. Endet er oben auf einer Wolkenrutsche, rutschst du nach unten. Bei einer 6 darfst du nochmal würfeln; würfelst du dreimal hintereinander eine 6, musst du aussetzen. Wer als Erster das Feld 100 erreicht oder überschreitet, gewinnt.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            HimmelsleiterSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen, quelle: WuerfelWahl.quelle(id, vorgabe: umgebung.wuerfelQuelle))
        }.mitZiel("Sei der Erste, der das Feld 100 erreicht. Leitern bringen dich hoch, Wolkenrutschen runter.").mitAnleitung(Self.anleitung))
    }
}

private let figurFarben: [Color] = [.red, .blue, .green, .orange]

struct HimmelsleiterSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    let quelle: WuerfelQuelle
    @State private var eingabe: Int?
    @State private var spiel: Himmelsleiter
    @State private var gemeldet = false
    @State private var tick = 0

    init(teilnehmer: [SpielTeilnehmer], ende: @escaping (SpielEnde) -> Void, abbrechen: @escaping () -> Void, quelle: WuerfelQuelle) {
        self.teilnehmer = teilnehmer; self.ende = ende; self.abbrechen = abbrechen; self.quelle = quelle
        _spiel = State(initialValue: Himmelsleiter(spieler: teilnehmer.count))
    }

    private var amZugComputer: Bool { teilnehmer[spiel.amZug].computer }

    var body: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: spiel.sieger == nil ? String(localized: "\(teilnehmer[spiel.amZug].name) ist dran") : String(localized: "Spielende"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            HStack(spacing: Design.Abstand.s) {
                ForEach(teilnehmer.indices, id: \.self) { i in
                    HStack(spacing: 6) {
                        Circle().fill(figurFarben[i]).frame(width: 12, height: 12)
                        Text(verbatim: "\(teilnehmer[i].name): \(spiel.positionen[i])").font(.footnote).lineLimit(1).minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 10).fill(i == spiel.amZug ? Color.appFlaeche.opacity(0.25) : Color.kartenGrund))
                }
            }.padding(.horizontal, Theme.seitenRand)
            GeometryReader { g in
                let z = min(g.size.width, g.size.height) / 10
                Canvas { ctx, _ in zeichne(&ctx, z: z) }
                    .frame(width: z * 10, height: z * 10).frame(maxWidth: .infinity)
                    .accessibilityElement()
                    .accessibilityLabel(Text("Spielbrett mit 100 Feldern"))
                    .accessibilityValue(Text(verbatim: teilnehmer.indices.map { "\(teilnehmer[$0].name): \(spiel.positionen[$0])" }.joined(separator: ", ")))
            }.aspectRatio(1, contentMode: .fit).padding(.horizontal, Theme.seitenRand)
            HStack(spacing: 14) {
                if spiel.letzterWurf > 0 {
                    WuerfelBild(spiel.letzterWurf).font(.largeTitle).foregroundStyle(Color.appFlaeche)
                        .accessibilityLabel(Text("Würfel: \(spiel.letzterWurf)"))
                }
                Text(LocalizedStringKey(spiel.meldung.isEmpty ? " " : spiel.meldung)).font(.subheadline.weight(.semibold))
            }.frame(minHeight: 50)
            Button("Würfeln") { if quelle == .echt { eingabe = 1 } else { wuerfeln() } }.buttonStyle(HauptKnopfStil()).beimSchuetteln(aktiv: quelle == .app) { wuerfeln() }
                .disabled(amZugComputer || spiel.sieger != nil).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
            Spacer(minLength: 0)
        }
        .background(Color.seitenGrund)
        .fortsetzbar("himmelsleiter", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel.sieger != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .echteWuerfelEingabe(anzahl: $eingabe) { wuerfeln(wurf: $0[0]) }
        .task(id: "\(spiel.amZug)-\(tick)") {
            guard amZugComputer, spiel.sieger == nil else { return }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }
            wuerfeln()
        }
    }

    private func wuerfeln(wurf: Int = Int.random(in: 1...6)) {
        guard spiel.sieger == nil else { return }
        spiel.zug(wurf: wurf); tick += 1
        if let w = spiel.sieger, !gemeldet {
            gemeldet = true
            let rang = teilnehmer.indices.sorted { a, b in a == w ? true : (b == w ? false : spiel.positionen[a] > spiel.positionen[b]) }
            Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                ende(SpielEnde(reihenfolge: rang.map { teilnehmer[$0].name }, punkte: rang.map { "\(spiel.positionen[$0])" }))
            }
        }
    }

    private func mitte(_ feld: Int, _ z: CGFloat) -> CGPoint {
        let k = Himmelsleiter.koordinate(max(1, feld))
        return CGPoint(x: (CGFloat(k.spalte) + 0.5) * z, y: (CGFloat(k.zeile) + 0.5) * z)
    }

    private func zeichne(_ ctx: inout GraphicsContext, z: CGFloat) {
        for f in 1...100 {
            let k = Himmelsleiter.koordinate(f)
            let r = CGRect(x: CGFloat(k.spalte) * z, y: CGFloat(k.zeile) * z, width: z, height: z)
            ctx.fill(Path(r), with: .color(((k.spalte + k.zeile) % 2 == 0 ? Color.appFlaeche.opacity(0.18) : Color.appFlaeche.opacity(0.07))))
            ctx.draw(Text(verbatim: "\(f)").font(.system(size: z * 0.28)).foregroundStyle(.secondary), at: CGPoint(x: r.minX + z * 0.25, y: r.minY + z * 0.2))   // design:spielinhalt (skaliert mit Feld/Karte/Würfel)
        }
        for (a, b) in Himmelsleiter.leitern {
            var p = Path(); p.move(to: mitte(a, z)); p.addLine(to: mitte(b, z))
            ctx.stroke(p, with: .color(.green.opacity(0.8)), style: StrokeStyle(lineWidth: max(3, z * 0.18), lineCap: .round))
        }
        for (a, b) in Himmelsleiter.rutschen {
            var p = Path(); p.move(to: mitte(a, z)); p.addLine(to: mitte(b, z))
            ctx.stroke(p, with: .color(.red.opacity(0.7)), style: StrokeStyle(lineWidth: max(3, z * 0.18), lineCap: .round, dash: [z * 0.25, z * 0.2]))
        }
        for i in 0..<spiel.spieler {
            let pos = spiel.positionen[i]
            var c = pos == 0 ? CGPoint(x: z * 0.2 + CGFloat(i) * z * 0.25, y: z * 9.8) : mitte(pos, z)
            c.x += CGFloat(i % 2) * z * 0.22 - z * 0.11; c.y += CGFloat(i / 2) * z * 0.22 - z * 0.11
            let r = z * 0.17
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(figurFarben[i]))
            ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(.white), lineWidth: 1.5)
        }
    }
}
#endif
