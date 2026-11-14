// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import SpielHilfen
import SechseckKern

@MainActor
public struct SechseckModul: SpielModul {
    public init() {}
    public let id = "sechseck"
    public let name = "Sechseck"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.tuerkis
    public let symbol = "hexagon.fill"
    public let spielerzahl = 1...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Baue die Brücke", farbe: farbe, spieler: 1...2, computerErlaubt: true,
                            regeln: "Auf dem Feld aus Sechsecken setzen zwei Spieler abwechselnd je einen Stein auf ein freies Feld. Blau muss die obere mit der unteren Kante verbinden, Rot die linke mit der rechten. Die Steine müssen sich dabei an den Seiten berühren. Wer zuerst eine durchgehende Kette hat, gewinnt. Unentschieden gibt es nicht. Tipp: Wer in der Mitte steht, hat es leichter. Blau beginnt. Allein spielst du gegen den Computer und wählst Feldgröße und Stärke.",
                            einzelText: "Du gegen den Computer.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            SechseckSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Verbinde mit einer durchgehenden Kette deine beiden Seiten des Feldes, bevor es dein Gegner schafft.").mitAnleitung([
            .figuren(symbol: "hexagon", titel: "Stein setzen", text: "Ihr setzt abwechselnd je einen Stein auf ein freies Sechseck.", figuren: ["⬡", "🔵", "⬡"], bewegt: nil),
            .figuren(symbol: "link", titel: "Kette bilden", text: "Blau verbindet die obere mit der unteren Kante, Rot die linke mit der rechten.", figuren: ["🔵", "🔵", "🔵"], bewegt: nil),
            .figuren(symbol: "flag.checkered", titel: "Kein Unentschieden", text: "Wer zuerst eine durchgehende Kette hat, gewinnt. Unentschieden gibt es nicht.", figuren: ["🔵", "🏆"], bewegt: nil),
        ]))
    }
}

struct SechseckSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var groesse = 9
    @State private var stufe = ComputerStufe.gespeichert("sechseck")
    @State private var spiel: Sechseck?
    @State private var denkt = false
    @State private var verlauf: [Sechseck] = []
    @State private var tipp: Int?
    @State private var tippRechnet = false
    @State private var gemeldet = false

    private var gegnerComputer: Bool { teilnehmer.count < 2 || teilnehmer[1].computer }
    @State private var ich = 1          // Seite des ersten Teilnehmers: 1 = Blau (beginnt), 2 = Rot
    /// Die Seite, die der Computer spielt (nil bei zwei Menschen).
    private var computerSeite: Int? { gegnerComputer ? 3 - ich : nil }
    private func name(_ s: Int) -> String {
        if s == ich { return teilnehmer[0].name }
        return teilnehmer.count > 1 ? teilnehmer[1].name : String(localized: "Computer")
    }
    private var spiele: Int { [ComputerStufe.leicht: 0, .mittel: 30, .schwer: 120][stufe] ?? 30 }
    private static let blau = Color(red: 0.2, green: 0.45, blue: 0.85), rot = Color(red: 0.85, green: 0.28, blue: 0.28)

    var body: some View { Group { if let s = spiel { brett(s) } else { auswahl } }.background(Color.seitenGrund).fortsetzbar("sechseck", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel?.sieger != nil))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3) }

    private var auswahl: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Sechseck", linksAktion: abbrechen) { Color.clear.frame(width: 44, height: 44) }
            VStack(alignment: .leading, spacing: 14) {
                Text("Feldgröße").font(.headline)
                Picker("Feldgröße", selection: $groesse) { Text("7 × 7").tag(7); Text("9 × 9").tag(9); Text("11 × 11").tag(11) }.pickerStyle(.segmented)
                if gegnerComputer {
                    Text("Deine Farbe").font(.headline)
                    Picker("Deine Farbe", selection: $ich) { Text("Blau (beginnt)").tag(1); Text("Rot").tag(2) }.pickerStyle(.segmented)
                    ComputerStufePicker(spiel: "sechseck", stufe: $stufe).pickerStyle(.segmented) }
            }.padding(Theme.seitenRand)
            Spacer()
            Button("Los geht’s") { spiel = Sechseck(groesse: groesse); verlauf = []; tipp = nil; gemeldet = false }
                .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private func brett(_ s: Sechseck) -> some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: s.sieger == nil ? String(localized: "\(name(s.amZug)) ist dran") : String(localized: "Spielende"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { spiel = nil }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            HStack(spacing: Design.Abstand.l) {
                Label(name(1), systemImage: "arrow.up.and.down").foregroundStyle(Self.blau).font(.footnote.weight(s.amZug == 1 ? .bold : .regular))
                Label(name(2), systemImage: "arrow.left.and.right").foregroundStyle(Self.rot).font(.footnote.weight(s.amZug == 2 ? .bold : .regular))
            }
            ZugKnoepfe(kannZurueck: !verlauf.isEmpty && !denkt, tippMoeglich: s.sieger == nil && s.amZug != computerSeite, rechnet: tippRechnet, zurueck: zurueck, tipp: holeTipp)
            GeometryReader { g in
                let n = s.n
                let w1: CGFloat = 1.7320508
                let r = min((g.size.width - 24) / (w1 * (CGFloat(n) * 1.5 - 0.5)), g.size.height / (1.5 * CGFloat(n - 1) + 2.8))
                let ox = (g.size.width - r * w1 * (CGFloat(n) * 1.5 - 0.5)) / 2 + r * w1 / 2
                Canvas { ctx, _ in zeichne(&ctx, s, r, ox) }
                    .contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { v in tippe(v.location, s, r, ox) })
                    .accessibilityElement(children: .ignore)   // G1
                    .accessibilityLabel(Text("Sechseckbrett, \(n) mal \(n)"))
                    .accessibilityValue(Text("\(name(s.amZug)) ist dran"))
                    .accessibilityHint(Text("Ein freies Feld antippen, um einen Stein zu setzen."))
            }.padding(.horizontal, 8)
            Spacer(minLength: 0)
        }
        .task(id: "\(s.zuege)-\(spiel == nil)") {
            guard let sp = spiel, sp.sieger == nil, let cs = computerSeite, sp.amZug == cs else { return }
            denkt = true
            try? await Task.sleep(nanoseconds: 400_000_000)
            let kopie = sp; let tiefe = spiele
            let zug = await Task.detached(priority: .userInitiated) { () -> Int? in var g = SystemRandomNumberGenerator(); return kopie.computerZug(spiele: tiefe, mit: &g) }.value
            denkt = false
            guard !Task.isCancelled, var s2 = spiel, let z = zug, s2.zuege == kopie.zuege else { return }
            s2.setze(z); spiel = s2; pruefe()
        }
    }

    private func mitte(_ x: Int, _ y: Int, _ r: CGFloat, _ ox: CGFloat) -> CGPoint {
        let w: CGFloat = 1.7320508 * r
        return CGPoint(x: ox + w * (CGFloat(x) + CGFloat(y) * 0.5), y: r * 1.4 + CGFloat(y) * r * 1.5)
    }

    private func sechseck(_ c: CGPoint, _ r: CGFloat) -> Path {
        var p = Path()
        for k in 0..<6 {
            let a = CGFloat(k) * .pi / 3 + .pi / 6
            let pt = CGPoint(x: c.x + r * 0.95 * cos(a), y: c.y + r * 0.95 * sin(a))
            if k == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath(); return p
    }

    private func zeichne(_ ctx: inout GraphicsContext, _ s: Sechseck, _ r: CGFloat, _ ox: CGFloat) {
        let n = s.n
        // Randfarben: Blau oben/unten, Rot links/rechts
        for i in 0..<n {
            let o = mitte(i, 0, r, ox), u = mitte(i, n - 1, r, ox), l = mitte(0, i, r, ox), re = mitte(n - 1, i, r, ox)
            ctx.fill(Path(ellipseIn: CGRect(x: o.x - 3, y: o.y - r * 1.15 - 3, width: 6, height: 6)), with: .color(Self.blau))
            ctx.fill(Path(ellipseIn: CGRect(x: u.x - 3, y: u.y + r * 1.15 - 3, width: 6, height: 6)), with: .color(Self.blau))
            ctx.fill(Path(ellipseIn: CGRect(x: l.x - r * 1.0 - 3, y: l.y - 3, width: 6, height: 6)), with: .color(Self.rot))
            ctx.fill(Path(ellipseIn: CGRect(x: re.x + r * 1.0 - 3, y: re.y - 3, width: 6, height: 6)), with: .color(Self.rot))
        }
        for y in 0..<n { for x in 0..<n {
            let c = mitte(x, y, r, ox); let p = sechseck(c, r)
            let w = s.zellen[s.index(x, y)]
            ctx.fill(p, with: .color(w == 1 ? Self.blau : (w == 2 ? Self.rot : Color.appFlaeche.opacity(0.12))))
            ctx.stroke(p, with: .color(tipp == s.index(x, y) ? .yellow : (s.letzter == s.index(x, y) ? .primary : .secondary.opacity(0.5))), lineWidth: tipp == s.index(x, y) ? 5 : (s.letzter == s.index(x, y) ? 3 : 1))
        } }
    }

    private func tippe(_ pt: CGPoint, _ s: Sechseck, _ r: CGFloat, _ ox: CGFloat) {
        guard var sp = spiel, sp.sieger == nil, sp.amZug != computerSeite else { return }
        var best: (Int, CGFloat)?
        for y in 0..<s.n { for x in 0..<s.n {
            let c = mitte(x, y, r, ox); let d = hypot(c.x - pt.x, c.y - pt.y)
            if d < r && (best == nil || d < best!.1) { best = (s.index(x, y), d) }
        } }
        if let b = best { let vorher = sp; if sp.setze(b.0) { verlauf.append(vorher); tipp = nil; spiel = sp; pruefe() } }
    }

    private func zurueck() {
        tipp = nil
        while let l = verlauf.popLast() { spiel = l; if l.amZug != computerSeite { break } }
    }

    private func holeTipp() {
        tippRechnet = true
        guard let stand = spiel else { return }
        Task {
            let z = await Task.detached { () -> Int? in var g = SystemRandomNumberGenerator(); return stand.computerZug(spiele: 80, mit: &g) }.value
            if spiel == stand { tipp = z }
            tippRechnet = false
        }
    }

    private func pruefe() {
        guard let s = spiel, let w = s.sieger, !gemeldet else { return }
        gemeldet = true
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            ende(SpielEnde(reihenfolge: [name(w), name(3 - w)], info: String(localized: "\(name(w)) hat die Brücke gebaut")))
        }
    }
}
#endif
