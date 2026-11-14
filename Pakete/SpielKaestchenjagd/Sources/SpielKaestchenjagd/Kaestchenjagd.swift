// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas
import SpieleKern
import KaestchenjagdKern

@MainActor
public struct KaestchenjagdModul: SpielModul {
    public init() {}
    public let id = "kaestchenjagd"
    public let name = "Kästchenjagd"
    public let gattung = Gattung.brett
    public let farbe = AkzentFarbeWert.gruen
    public let symbol = "squareshape.split.2x2.dotted"
    public let spielerzahl = 2...2
    public func start(_ umgebung: SpielUmgebung) -> AnyView {
        AnyView(SpielRahmen(id: id, name: name, untertitel: "Schließe die meisten Kästchen", farbe: farbe, spieler: 2...2, computerErlaubt: true,
                            regeln: "Auf dem Punktegitter zieht jeder abwechselnd eine Linie zwischen zwei benachbarten Punkten. Wer mit seiner Linie die vierte Seite eines Kästchens schließt, bekommt dieses Kästchen und darf gleich noch eine Linie ziehen. Sind alle Linien gezogen, gewinnt, wer mehr Kästchen hat. Tipp: Zieh nicht die dritte Seite eines Kästchens, sonst schenkst du es dem Gegner. Am Ende gewinnt oft, wer die längsten Ketten zuletzt bekommt. Tippe in die Nähe einer Linie, um sie zu ziehen.",
                            umgebung: umgebung) { teilnehmer, ende, abbrechen in
            KaestchenjagdSpiel(teilnehmer: teilnehmer, ende: ende, abbrechen: abbrechen)
        }.mitZiel("Schließe mehr Kästchen als dein Gegner. Wer die vierte Seite zieht, bekommt das Kästchen.").mitAnleitung([
            .figuren(symbol: "line.diagonal", titel: "Linie ziehen", text: "Ihr zieht abwechselnd eine Linie zwischen zwei benachbarten Punkten.", figuren: ["•", "—", "•"], bewegt: nil),
            .figuren(symbol: "square", titel: "Kästchen schließen", text: "Wer die vierte Seite eines Kästchens schließt, bekommt es und darf gleich noch eine Linie ziehen.", figuren: ["🟦", "🔵"], bewegt: nil),
            .figuren(symbol: "exclamationmark.triangle", titel: "Nicht die dritte Seite", text: "Zieh nicht die dritte Seite eines Kästchens, sonst schenkst du es dem Gegner. Wer am Ende mehr Kästchen hat, gewinnt.", figuren: ["⚠️", "🟦"], bewegt: nil),
        ]))
    }
}

struct KaestchenjagdSpiel: View {
    let teilnehmer: [SpielTeilnehmer]
    let ende: (SpielEnde) -> Void
    let abbrechen: () -> Void
    @State private var groesse = 5
    @State private var stufe = ComputerStufe.gespeichert("kaestchenjagd")
    @State private var spiel: Kaestchenjagd?
    @State private var gemeldet = false
    @State private var tick = 0
    @State private var vorschau: Kante?
    @State private var verlauf: [Kaestchenjagd] = []   // Zug zurück: Stand vor jedem Zug eines Menschen
    @State private var tipp: Kante?   // F4: vorgeschlagene Linie (sicher, sonst beliebig)

    private static let farben: [Color] = [Color(red: 0.2, green: 0.45, blue: 0.85), Color(red: 0.85, green: 0.35, blue: 0.2)]
    private var computerGegner: Bool { teilnehmer[1].computer }
    private func istComputer(_ s: Int) -> Bool { teilnehmer[s].computer }

    var body: some View { Group { if let s = spiel { brett(s) } else { auswahl } }.background(Color.seitenGrund).fortsetzbar("kaestchenjagd", $spiel)
        .weicheAnimation(bei: spiel)
        .spielHaptik(zug: spiel, erfolg: (spiel?.vorbei ?? false))
        .dynamicTypeSize(...DynamicTypeSize.accessibility3) }

    private var auswahl: some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: "Kästchenjagd", linksAktion: abbrechen) { Color.clear.frame(width: 44, height: 44) }
            VStack(alignment: .leading, spacing: 14) {
                Text("Feldgröße").font(.headline)
                Picker("Feldgröße", selection: $groesse) { Text("3 × 3").tag(3); Text("4 × 4").tag(4); Text("5 × 5").tag(5); Text("6 × 6").tag(6) }.pickerStyle(.segmented)
                if teilnehmer.contains(where: \.computer) { ComputerStufePicker(spiel: "kaestchenjagd", stufe: $stufe).pickerStyle(.segmented) }
            }.padding(Theme.seitenRand)
            Spacer()
            Button("Los geht’s") { spiel = Kaestchenjagd(breite: groesse, hoehe: groesse); verlauf = []; gemeldet = false; tick += 1 }
                .buttonStyle(HauptKnopfStil()).padding(.horizontal, Theme.seitenRand).padding(.bottom, 8)
        }
    }

    private func brett(_ s: Kaestchenjagd) -> some View {
        VStack(spacing: Theme.kartenAbstand) {
            SpielKopf(mitte: s.vorbei ? String(localized: "Spielende") : String(localized: "\(teilnehmer[s.amZug].name) ist dran"), linksAktion: abbrechen) {
                RundKnopfMenue(symbol: "ellipsis", beschriftung: "Mehr") {
                    Button("Neu beginnen", systemImage: "arrow.counterclockwise") { spiel = nil }
                    Button("Spiel beenden", systemImage: "xmark.circle", role: .destructive, action: abbrechen)
                }
            }
            HStack(spacing: Design.Abstand.s) {
                ForEach(0..<2, id: \.self) { i in
                    VStack(spacing: 2) {
                        HStack(spacing: 6) { Circle().fill(Self.farben[i]).frame(width: 10, height: 10); Text(verbatim: teilnehmer[i].name).font(.footnote).lineLimit(1).minimumScaleFactor(0.7) }
                        Text(verbatim: "\(s.punkte[i])").font(.title3.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: Design.Ecke.feld).fill(i == s.amZug && !s.vorbei ? Self.farben[i].opacity(0.2) : Color.kartenGrund))
                }
            }.padding(.horizontal, Theme.seitenRand)
            GeometryReader { g in
                let z = min(g.size.width - 24, g.size.height - 24) / CGFloat(max(s.breite, s.hoehe))
                let ox = (g.size.width - z * CGFloat(s.breite)) / 2, oy: CGFloat = 12
                Canvas { ctx, _ in zeichne(&ctx, s, z, ox, oy) }
                    .contentShape(Rectangle())
                    // G1: Das Brett ist eine Zeichnung; VoiceOver bekommt Stand und freie Linien als ein Element
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text("Kästchenbrett, \(s.breite) mal \(s.hoehe)"))
                    .accessibilityValue(Text("\(teilnehmer[0].name) \(s.punkte[0]) Kästchen, \(teilnehmer[1].name) \(s.punkte[1]) Kästchen, \(s.alleKanten.count - s.gezogen.count) Linien frei"))
                    .accessibilityHint(Text("Finger über das Brett ziehen und auf einer Linie loslassen."))
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { v in vorschau = naechsteKante(v.location, s, z, ox, oy) }
                        .onEnded { v in
                            if let k = naechsteKante(v.location, s, z, ox, oy), var sp = spiel, !sp.vorbei, !istComputer(sp.amZug) { let vorher = sp; if sp.ziehe(k) { verlauf.append(vorher); spiel = sp; tick += 1; tipp = nil; pruefe() } }
                            vorschau = nil
                        })
            }.aspectRatio(1, contentMode: .fit).frame(maxWidth: Theme.wideColumnWidth).padding(.horizontal, Theme.seitenRand)
            HStack(spacing: Design.Abstand.m) {
                Text(hinweis(s)).font(.footnote).foregroundStyle(vorschau.map { gefaehrlich($0, s) } == true ? Color.orange : .secondary).frame(minHeight: 18)
                if !s.vorbei, !istComputer(s.amZug) {
                    Button { if let v = verlauf.popLast() { spiel = v; tipp = nil; tick += 1 } } label: { Label("Zug zurück", systemImage: "arrow.uturn.backward") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge).disabled(verlauf.isEmpty)
                    Button { let frei = s.alleKanten.filter { s.gezogen[$0] == nil }; tipp = frei.first { !gefaehrlich($0, s) } ?? frei.first; if let k = tipp { UIAccessibility.post(notification: .announcement, argument: k.waagrecht ? String(localized: "Tipp: waagrechte Linie in Reihe \(k.y + 1) ab Punkt \(k.x + 1), gelb gestrichelt.") : String(localized: "Tipp: senkrechte Linie in Spalte \(k.x + 1) ab Punkt \(k.y + 1), gelb gestrichelt.")) } } label: { Label("Tipp", systemImage: "lightbulb") }.nebenKnopf().dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                }
            }.padding(.horizontal, Theme.seitenRand)
            Spacer(minLength: 0)
        }
        .task(id: "\(tick)-\(s.punkte[0] + s.punkte[1])-\(s.gezogen.count)") {
            guard let sp = spiel, !sp.vorbei, istComputer(sp.amZug) else { return }
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled, var s2 = spiel else { return }
            var g = SystemRandomNumberGenerator()
            if let k = s2.computerZug(stufe: stufe.rawValue - 1, mit: &g) { s2.ziehe(k); spiel = s2; tick += 1; pruefe() }
        }
    }

    private func hinweis(_ s: Kaestchenjagd) -> String {
        if s.vorbei || istComputer(s.amZug) { return " " }
        if let k = vorschau { return gefaehrlich(k, s) ? String(localized: "Achtung: Das schenkt dem Gegner ein Kästchen.") : String(localized: "Loslassen, um die Linie zu ziehen.") }
        return String(localized: "Ziehe den Finger zu einer Linie und lass los.")
    }

    private func punktPos(_ x: Int, _ y: Int, _ z: CGFloat, _ ox: CGFloat, _ oy: CGFloat) -> CGPoint { CGPoint(x: ox + CGFloat(x) * z, y: oy + CGFloat(y) * z) }

    private func zeichne(_ ctx: inout GraphicsContext, _ s: Kaestchenjagd, _ z: CGFloat, _ ox: CGFloat, _ oy: CGFloat) {
        for y in 0..<s.hoehe { for x in 0..<s.breite {
            if let b = s.besitzer[y][x] {
                let r = CGRect(x: ox + CGFloat(x) * z + 3, y: oy + CGFloat(y) * z + 3, width: z - 6, height: z - 6)
                ctx.fill(Path(roundedRect: r, cornerRadius: 6), with: .color(Self.farben[b].opacity(0.3)))
                ctx.draw(Text(verbatim: String(teilnehmer[b].name.prefix(1))).font(.system(size: z * 0.4, weight: .bold)).foregroundStyle(Self.farben[b]), at: CGPoint(x: r.midX, y: r.midY))   // design:spielinhalt (Spielmaterial im Feld)
            }
        } }
        for k in s.alleKanten {
            let a = k.waagrecht ? punktPos(k.x, k.y, z, ox, oy) : punktPos(k.x, k.y, z, ox, oy)
            let b = k.waagrecht ? punktPos(k.x + 1, k.y, z, ox, oy) : punktPos(k.x, k.y + 1, z, ox, oy)
            var p = Path(); p.move(to: a); p.addLine(to: b)
            if let w = s.gezogen[k] {
                ctx.stroke(p, with: .color(Self.farben[w]), style: StrokeStyle(lineWidth: s.letzte == k ? 7 : 5, lineCap: .round))
            } else {
                ctx.stroke(p, with: .color(.secondary.opacity(0.25)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [2, 5]))
            }
        }
        if let k = tipp, s.gezogen[k] == nil {
            let a = punktPos(k.x, k.y, z, ox, oy)
            let b = k.waagrecht ? punktPos(k.x + 1, k.y, z, ox, oy) : punktPos(k.x, k.y + 1, z, ox, oy)
            var p = Path(); p.move(to: a); p.addLine(to: b)
            ctx.stroke(p, with: .color(.yellow), style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [6, 6]))
        }
        if let k = vorschau {
            let a = punktPos(k.x, k.y, z, ox, oy)
            let b = k.waagrecht ? punktPos(k.x + 1, k.y, z, ox, oy) : punktPos(k.x, k.y + 1, z, ox, oy)
            var p = Path(); p.move(to: a); p.addLine(to: b)
            ctx.stroke(p, with: .color(gefaehrlich(k, s) ? Color.orange : Self.farben[s.amZug]), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        }
        for y in 0...s.hoehe { for x in 0...s.breite {
            let c = punktPos(x, y, z, ox, oy)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 4.5, y: c.y - 4.5, width: 9, height: 9)), with: .color(.primary))
        } }
    }

    /// Freie Kante in Fingernähe (nur wenn ein Mensch am Zug ist).
    private func naechsteKante(_ pt: CGPoint, _ s: Kaestchenjagd, _ z: CGFloat, _ ox: CGFloat, _ oy: CGFloat) -> Kante? {
        guard !s.vorbei, !istComputer(s.amZug) else { return nil }
        let sp = s
        var best: (Kante, CGFloat)?
        for k in sp.freieKanten {
            let a = punktPos(k.x, k.y, z, ox, oy)
            let m = k.waagrecht ? CGPoint(x: a.x + z / 2, y: a.y) : CGPoint(x: a.x, y: a.y + z / 2)
            let d = hypot(m.x - pt.x, m.y - pt.y)
            if d < z * 0.45 && (best == nil || d < best!.1) { best = (k, d) }
        }
        return best?.0
    }

    /// Schenkt diese Linie dem Gegner ein Kästchen (dritte Seite, ohne selbst eines zu schließen)?
    private func gefaehrlich(_ k: Kante, _ s: Kaestchenjagd) -> Bool {
        let nachbarn = s.angrenzend(k)
        if nachbarn.contains(where: { s.zahlSeiten($0.0, $0.1) == 3 }) { return false }       // schließt selbst ein Kästchen
        return nachbarn.contains { s.zahlSeiten($0.0, $0.1) == 2 }
    }

    private func pruefe() {
        guard let s = spiel, s.vorbei, !gemeldet else { return }
        gemeldet = true
        let rang = s.punkte[0] >= s.punkte[1] ? [0, 1] : [1, 0]
        Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            ende(SpielEnde(reihenfolge: rang.map { teilnehmer[$0].name }, punkte: rang.map { "\(s.punkte[$0])" },
                           plaetze: s.punkte[0] == s.punkte[1] ? [1, 1] : nil))
        }
    }
}
#endif
