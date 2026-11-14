// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei (Spielmaterial: Brett, Gänse, Füchse im Feld)
#if canImport(UIKit)
import SwiftUI
import KlarGlas
import FuchsjagdKern

/// Brett der neuen Fuchsjagd: gezeichnet in einem Canvas, darüber 33 echte Felder (Knöpfe) für Antippen und VoiceOver.
struct FuchsBrettNeu: View {
    let spiel: Fuchsjagd
    var gewaehlt: Pos? = nil
    var tipp: FuchsZug? = nil
    var aktiv = true                 // false = Vorschau (Seitenwahl, Spielende): keine Bedienung
    var aktion: (Pos) -> Void = { _ in }
    let seite: CGFloat

    private var z: CGFloat { seite / 7 }
    private var ziele: [FuchsZug] { gewaehlt.map { spiel.ziele(von: $0) } ?? [] }
    private static let felder: [Pos] = (0..<7).flatMap { y in (0..<7).map { Pos($0, y) } }.filter(Fuchsjagd.gueltig)

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in zeichne(&ctx) }
                .accessibilityHidden(true)
            if aktiv {
                ForEach(Self.felder, id: \.self) { p in
                    Button { aktion(p) } label: { Color.clear.contentShape(Rectangle()) }
                        .buttonStyle(.plain)
                        .frame(width: z, height: z)
                        .position(x: (CGFloat(p.x) + 0.5) * z, y: (CGFloat(p.y) + 0.5) * z)
                        .accessibilityLabel(beschreibung(p))
                        .accessibilityAddTraits(gewaehlt == p ? .isSelected : [])
                        .accessibilityHint(hinweis(p))
                }
            }
        }
        .frame(width: seite, height: seite)
        .accessibilityElement(children: aktiv ? .contain : .ignore)
        .accessibilityLabel(Text("Fuchsjagd-Brett, 7 mal 7"))
    }

    // MARK: Felder für VoiceOver

    private func beschreibung(_ p: Pos) -> Text {
        let n = Fuchsjagd.notation(p)
        if spiel.fuechse.contains(p) { return Text("\(n), Fuchs") }
        if spiel.gaense.contains(p) { return Text("\(n), Gans") }
        if let z = ziele.first(where: { $0.nach == p }) { return z.schlag != nil ? Text("\(n), Zielfeld mit Sprung") : Text("\(n), Zielfeld") }
        return Text("\(n), leer")
    }

    private func hinweis(_ p: Pos) -> Text {
        if ziele.contains(where: { $0.nach == p }) { return Text("Antippen, um hier zu ziehen") }
        let eigene = spiel.amZug == .fuchs ? spiel.fuechse.contains(p) : spiel.gaense.contains(p)
        if eigene, !spiel.ziele(von: p).isEmpty { return Text("Antippen, um die Figur zu wählen") }
        return Text(verbatim: "")
    }

    // MARK: Zeichnung

    private func feld(_ p: Pos) -> CGRect { CGRect(x: CGFloat(p.x) * z + 1.5, y: CGFloat(p.y) * z + 1.5, width: z - 3, height: z - 3) }

    private func zeichne(_ ctx: inout GraphicsContext) {
        let hell = Color.appFlaeche.opacity(0.14)
        for p in Self.felder {
            let r = feld(p)
            ctx.fill(Path(ellipseIn: r.insetBy(dx: z * 0.06, dy: z * 0.06)), with: .color(hell))
            if let t = ziele.first(where: { $0.nach == p }) {
                let c = CGPoint(x: r.midX, y: r.midY)
                let rad = z * (t.schlag == nil ? 0.13 : 0.2)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rad, y: c.y - rad, width: 2 * rad, height: 2 * rad)), with: .color(Color.appFlaeche))
            }
        }
        if let l = spiel.letzterZug {
            for p in [l.von, l.nach] {
                ctx.stroke(Path(ellipseIn: feld(p)), with: .color(Color.appFlaeche.opacity(p == l.nach ? 0.9 : 0.45)), lineWidth: 2.5)
            }
        }
        if let t = tipp {
            for p in [t.von, t.nach] { ctx.stroke(Path(ellipseIn: feld(p)), with: .color(.yellow), lineWidth: 4) }
        }
        for g in spiel.gaense { gans(&ctx, g) }
        for f in spiel.fuechse { fuchs(&ctx, f) }
    }

    private func mitte(_ p: Pos) -> CGPoint { CGPoint(x: (CGFloat(p.x) + 0.5) * z, y: (CGFloat(p.y) + 0.5) * z) }

    /// Gans: weiße Scheibe mit Schnabel nach oben (Zugrichtung).
    private func gans(_ ctx: inout GraphicsContext, _ p: Pos) {
        let c = mitte(p), r = z * 0.34
        let rand: Color = gewaehlt == p ? Color.appFlaeche : Color.gray
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(.white))
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(rand), lineWidth: gewaehlt == p ? 4 : 1.5)
        var schnabel = Path()
        schnabel.move(to: CGPoint(x: c.x, y: c.y - r * 0.62))
        schnabel.addLine(to: CGPoint(x: c.x - r * 0.3, y: c.y - r * 0.1)); schnabel.addLine(to: CGPoint(x: c.x + r * 0.3, y: c.y - r * 0.1)); schnabel.closeSubpath()
        ctx.fill(schnabel, with: .color(Color.appFlaeche))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.34, y: c.y + r * 0.08, width: r * 0.68, height: r * 0.5)), with: .color(Color.gray.opacity(0.35)))
    }

    /// Fuchs: orange Scheibe mit zwei Ohren und heller Schnauze (andere Form als die Gans, nicht nur andere Farbe).
    private func fuchs(_ ctx: inout GraphicsContext, _ p: Pos) {
        let c = mitte(p), r = z * 0.36
        let gew = gewaehlt == p
        var ohren = Path()
        for s in [-1.0, 1.0] {
            ohren.move(to: CGPoint(x: c.x + s * r * 0.9, y: c.y - r * 0.3))
            ohren.addLine(to: CGPoint(x: c.x + s * r * 0.75, y: c.y - r * 1.15))
            ohren.addLine(to: CGPoint(x: c.x + s * r * 0.2, y: c.y - r * 0.8)); ohren.closeSubpath()
        }
        ctx.fill(ohren, with: .color(.orange))
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(.orange))
        ctx.stroke(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)), with: .color(gew ? .white : .brown), lineWidth: gew ? 4 : 2)
        var schnauze = Path()
        schnauze.move(to: CGPoint(x: c.x, y: c.y + r * 0.7))
        schnauze.addLine(to: CGPoint(x: c.x - r * 0.45, y: c.y + r * 0.05)); schnauze.addLine(to: CGPoint(x: c.x + r * 0.45, y: c.y + r * 0.05)); schnauze.closeSubpath()
        ctx.fill(schnauze, with: .color(.white))
        for s in [-1.0, 1.0] { ctx.fill(Path(ellipseIn: CGRect(x: c.x + s * r * 0.4 - r * 0.08, y: c.y - r * 0.25, width: r * 0.16, height: r * 0.16)), with: .color(.brown)) }
        ctx.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.1, y: c.y + r * 0.58, width: r * 0.2, height: r * 0.14)), with: .color(.brown))
    }
}
#endif
