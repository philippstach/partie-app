// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

// design:spielinhalt-datei – Minenfeld mit den klassischen Ziffernfarben (Spielmaterial)
import SwiftUI
import KlarGlas
import MinensucheKern
import SpieleKern

/// Das Spielfeld. Zellgröße richtet sich nach dem verfügbaren Platz.
struct BrettView: View {
    @Environment(SpielModell.self) private var modell
    @AppStorage(Einstellung.haltedauer) private var haltedauer = 1   // 1.0 (M3)
    @Environment(\.horizontalSizeClass) private var sizeClass
    /// Große Tinte-Runde, Punkt 13: Knöpfe direkt unter dem Feld (nur iPad in Tinte), das Feld wächst dann bis 120 pt je Zelle
    var untenImFeld: AnyView? = nil

    var body: some View {
        if let s = modell.spiel {
            GeometryReader { geo in
                let luecke: CGFloat = 3
                let knopfPlatz: CGFloat = untenImFeld == nil ? 0 : 88   // Platz für die Knöpfe unter dem Feld
                let breite = (geo.size.width - luecke * CGFloat(s.mass.spalten - 1)) / CGFloat(s.mass.spalten)
                let hoehe = (geo.size.height - knopfPlatz - luecke * CGFloat(s.mass.zeilen - 1)) / CGFloat(s.mass.zeilen)
                // Nie größer als der Platz: sonst ragt das Brett über Kopf und Leiste hinaus
                let deckel: CGFloat = Tisch.aktiv && sizeClass == .regular ? 120 : 56
                let seite = max(12, floor(min(breite, hoehe, deckel)))
                VStack(spacing: untenImFeld == nil ? 0 : 20) {
                    VStack(spacing: luecke) {
                        ForEach(0..<s.mass.zeilen, id: \.self) { z in
                            HStack(spacing: luecke) {
                                ForEach(0..<s.mass.spalten, id: \.self) { sp in
                                    ZelleView(spiel: s, position: Position(zeile: z, spalte: sp), seite: seite, halte: Einstellung.haltesekunden(haltedauer))
                                }
                            }
                        }
                    }
                    if let untenImFeld { untenImFeld }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ZelleView: View {
    @Environment(SpielModell.self) private var modell
    let spiel: Spiel
    let position: Position
    let seite: CGFloat
    /// 1.0 (M3): Haltedauer für langes Drücken in Sekunden
    var halte: Double = 0.3

    var body: some View {
        let feld = spiel.feld(position)
        let vorbei = spiel.minenSichtbar   // N-024: nach einer Mine erst, wenn der Spieler aufhört; vorher nur die getroffene Mine
        let mine = spiel.istMine(position)
        ZStack {
            if Tisch.aktiv {
                // Blatt 4/4b (Tinte): helle Steine, vertiefte Mulden, gezeichnete Mine und Fahne
                let treffer = spiel.ausgeloest == spiel.mass.index(position)
                switch feld {
                case .aufgedeckt:
                    if mine {
                        TinteMinen.Stein(seite: seite, rot: treffer) {
                            if treffer { TinteMinen.TrefferZeichen().frame(width: seite * 0.66, height: seite * 0.66) }
                            else { TinteMinen.Kugel().frame(width: seite * 0.66, height: seite * 0.66) }
                        }
                    } else {
                        TinteMinen.Mulde(seite: seite)
                        let n = spiel.zahl(position)
                        if n > 0 {
                            Text("\(n)")
                                .font(.system(size: seite * TinteMinen.zahlGroesse, weight: .bold, design: Design.zahlDesign))
                                .foregroundStyle(TinteMinen.zahlFarbe(n))
                        }
                    }
                case .flagge:
                    TinteMinen.Stein(seite: seite) {
                        TinteMinen.Fahne(falsch: vorbei && !mine).frame(width: seite * 0.6, height: seite * 0.6)
                    }
                case .verdeckt:
                    TinteMinen.Stein(seite: seite) {
                        if vorbei && mine { TinteMinen.Kugel().frame(width: seite * 0.66, height: seite * 0.66) }
                    }
                }
            } else {
            switch feld {
            case .aufgedeckt:
                RoundedRectangle(cornerRadius: Theme.feldRadius / 2)
                    .fill(spiel.ausgeloest == spiel.mass.index(position) ? Color.red.opacity(0.85) : (Tisch.aktiv ? Color.white.opacity(0.14) : Color.kartenGrund.opacity(0.55)))   // Design-Runde 3: aufgedeckt = helle Mulde im Filz
                inhaltAufgedeckt(mine: mine)
            case .flagge:
                RoundedRectangle(cornerRadius: Theme.feldRadius / 2).fill(Tisch.aktiv ? Color.white.opacity(0.22) : Color.accentColor.opacity(0.28))
                if vorbei && !mine {
                    Image(systemName: "xmark").font(.system(size: seite * 0.45, weight: .bold)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.red)  // design:spielinhalt
                } else {
                    Image(systemName: "flag.fill").font(.system(size: seite * 0.45)).foregroundStyle(Tisch.aktiv ? Tisch.elfenbein : Color.accentColor)  // design:spielinhalt
                }
            case .verdeckt:
                RoundedRectangle(cornerRadius: Theme.feldRadius / 2).fill(Color.accentColor)
                if vorbei && mine {
                    Image(systemName: "circle.fill").font(.system(size: seite * 0.3)).foregroundStyle(.white.opacity(0.9))  // design:spielinhalt
                }
            }
            }
        }
        .frame(width: seite, height: seite)
        .contentShape(.rect)
        .gesture(
            LongPressGesture(minimumDuration: halte)
                .onEnded { _ in modell.langDruecken(position) }
                .exclusively(before: TapGesture().onEnded { modell.tippen(position) })
        )
        .accessibilityElement()
        .accessibilityLabel(beschriftung(feld: feld, mine: mine))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: Text("Fahne umschalten")) { modell.flagge(position) }
    }

    @ViewBuilder
    private func inhaltAufgedeckt(mine: Bool) -> some View {
        if mine {
            Image(systemName: "burst.fill").font(.system(size: seite * 0.5)).foregroundStyle(.white)  // design:spielinhalt
        } else {
            let n = spiel.zahl(position)
            if n > 0 {
                Text("\(n)")
                    .font(.system(size: seite * 0.55, weight: .bold, design: Design.zahlDesign))  // design:spielinhalt
                    .foregroundStyle(Self.zahlFarbe(n))
            }
        }
    }

    private func beschriftung(feld: Spiel.Feld, mine: Bool) -> Text {
        let ort = "\(String(localized: "Zeile")) \(position.zeile + 1), \(String(localized: "Spalte")) \(position.spalte + 1)"
        switch feld {
        case .verdeckt: return Text("\(ort): verdeckt")
        case .flagge: return Text("\(ort): Fahne")
        case .aufgedeckt:
            if mine { return Text("\(ort): Mine") }
            let n = spiel.zahl(position)
            return n == 0 ? Text("\(ort): leer") : Text("\(ort): \(n) Minen in der Nähe")
        }
    }

    /// Zahlenfarben: Spielinhalt, kein Teil der App-Farbe. Alle ≥ 4,5:1 auf der hellen und dunklen Zelle.
    static func zahlFarbe(_ n: Int) -> Color {
        switch n {
        case 1: Color(light: 0x1B5FD0, dark: 0x6CA6FF)  // design:spielinhalt
        case 2: Color(light: 0x1F7A3A, dark: 0x5FCB85)  // design:spielinhalt
        case 3: Tisch.aktiv ? Color(hex: 0xFFD166) : Color(light: 0xC62828, dark: 0xFF7B72)  // design:spielinhalt (auf dem Filz kein Rot als Schrift)
        case 4: Color(light: 0x5B34B5, dark: 0xB59CFF)  // design:spielinhalt
        case 5: Color(light: 0x8A4B12, dark: 0xE0A36B)  // design:spielinhalt
        case 6: Color(light: 0x0B7285, dark: 0x5CD0E3)  // design:spielinhalt
        case 7: Color(light: 0x111114, dark: 0xF2F2F7)  // design:spielinhalt
        default: Color(light: 0x5A5A63, dark: 0xB5B5BF)  // design:spielinhalt
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })  // design:spielinhalt
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255, blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}


/// Tinte-Zeichnung der Minensuche (Blatt 4/4b). Farben und Maße stehen hier an einer Stelle, damit Philipps Antwort auf Blatt 4b leicht einzubauen ist.
enum TinteMinen {
    // Zahlen nach Wärme (auf dem Filz): 1 Elfenbein, 2 grün, 3 gelb, 4 orange, 5 rot, 6 pink, 7 flieder, 8 grau
    static let zahlHex: [UInt32] = [0xFFFDF6, 0xA8E6B8, 0xFFD166, 0xFFA35C, 0xFF8073, 0xFF78A8, 0xD7B8FF, 0xB8C4D8]
    static let zahlGroesse: CGFloat = 0.62   // Anteil der Feldseite
    static func zahlFarbe(_ n: Int) -> Color { Color(hex: zahlHex[min(max(n, 1), 8) - 1]) }

    static let steinOben = Color(hex: 0xFFFDF6)
    static let steinUnten = Color(hex: 0xEDE7D6)
    static let steinKante = Color(hex: 0xC9C2AD)
    static let rotOben = Color(hex: 0xE2605A)
    static let rotUnten = Color(hex: 0xC9413D)
    static let rotKante = Color(hex: 0x96302D)
    static let kugel = Color(hex: 0x262A40)
    static let kugelHell = Color(hex: 0x4A5070)
    static let stachel = Color(hex: 0x23263A)
    static let fahnenRot = Color(hex: 0xD94F4A)
    static let fahnenGrau = Color(hex: 0xB9B4A6)
    static let mast = Color(hex: 0x23263A)

    /// Heller Stein mit leichtem Verlauf, dunklerer unterer Kante und weichem Schatten (rot = getroffene Mine).
    struct Stein<Inhalt: View>: View {
        let seite: CGFloat
        var rot = false
        @ViewBuilder var inhalt: () -> Inhalt
        var body: some View {
            let r = Theme.feldRadius / 2
            let kante = max(1.5, min(3, seite * 0.07))
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: r, style: .continuous).fill(rot ? rotKante : steinKante)
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(LinearGradient(colors: rot ? [rotOben, rotUnten] : [steinOben, steinUnten], startPoint: .top, endPoint: .bottom))
                    .frame(height: seite - kante)
                inhalt().frame(width: seite, height: seite - kante)
            }
            .frame(width: seite, height: seite)
            .shadow(color: .black.opacity(0.28), radius: 2, y: 1.5)
        }
    }

    /// Aufgedecktes Feld: vertieft im Filz.
    struct Mulde: View {
        let seite: CGFloat
        var body: some View {
            let r = Theme.feldRadius / 2
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(Color.black.opacity(0.26))
                .overlay(
                    RoundedRectangle(cornerRadius: r, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.3), lineWidth: max(2, seite * 0.08))
                        .blur(radius: 1.5)
                        .clipShape(RoundedRectangle(cornerRadius: r, style: .continuous))
                )
        }
    }

    /// Dunkle Kugel mit acht kurzen Stacheln und Glanzpunkt.
    struct Kugel: View {
        var koerper: Color = TinteMinen.kugel
        var body: some View {
            Canvas { ctx, size in
                let m = min(size.width, size.height)
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let rK = m * 0.30
                for i in 0..<8 {
                    let w = Double(i) * .pi / 4
                    var p = Path()
                    p.move(to: CGPoint(x: c.x + cos(w) * rK * 0.8, y: c.y + sin(w) * rK * 0.8))
                    p.addLine(to: CGPoint(x: c.x + cos(w) * m * 0.47, y: c.y + sin(w) * m * 0.47))
                    ctx.stroke(p, with: .color(stachel), style: StrokeStyle(lineWidth: max(1.5, m * 0.09), lineCap: .round))
                }
                let kreis = Path(ellipseIn: CGRect(x: c.x - rK, y: c.y - rK, width: rK * 2, height: rK * 2))
                ctx.fill(kreis, with: .radialGradient(Gradient(colors: [kugelHell, koerper]), center: CGPoint(x: c.x - rK * 0.4, y: c.y - rK * 0.4), startRadius: 0, endRadius: rK * 1.5))
                let g = rK * 0.32
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rK * 0.5, y: c.y - rK * 0.55, width: g, height: g)), with: .color(.white.opacity(0.85)))
            }
        }
    }

    /// Getroffene Mine: heller Zackenstern mit dunkler Kugel in der Mitte (auf rotem Stein).
    struct TrefferZeichen: View {
        var body: some View {
            Canvas { ctx, size in
                let m = min(size.width, size.height)
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                var stern = Path()
                for i in 0..<16 {
                    let w = Double(i) * .pi / 8 - .pi / 2
                    let r = i % 2 == 0 ? m * 0.5 : m * 0.3
                    let pt = CGPoint(x: c.x + cos(w) * r, y: c.y + sin(w) * r)
                    if i == 0 { stern.move(to: pt) } else { stern.addLine(to: pt) }
                }
                stern.closeSubpath()
                ctx.fill(stern, with: .color(Color(hex: 0xFFFDF6)))
                let rK = m * 0.17
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rK, y: c.y - rK, width: rK * 2, height: rK * 2)), with: .color(kugel))
                let g = rK * 0.4
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - rK * 0.6, y: c.y - rK * 0.6, width: g, height: g)), with: .color(.white.opacity(0.8)))
            }
        }
    }

    /// Fahne: dunkler Mast mit Fuß, rotes Fähnchen. Falsch gesetzt (am Ende): graues Fähnchen und dunkles Kreuz darüber.
    struct Fahne: View {
        var falsch = false
        var body: some View {
            Canvas { ctx, size in
                let m = min(size.width, size.height)
                let ox = (size.width - m) / 2, oy = (size.height - m) / 2
                func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: ox + m * x, y: oy + m * y) }
                var tuch = Path()
                tuch.move(to: pt(0.38, 0.08)); tuch.addLine(to: pt(0.86, 0.30)); tuch.addLine(to: pt(0.38, 0.52)); tuch.closeSubpath()
                ctx.fill(tuch, with: .color(falsch ? fahnenGrau : fahnenRot))
                ctx.fill(Path(roundedRect: CGRect(x: ox + m * 0.35, y: oy + m * 0.08, width: m * 0.06, height: m * 0.78), cornerRadius: m * 0.02), with: .color(mast))
                ctx.fill(Path(roundedRect: CGRect(x: ox + m * 0.18, y: oy + m * 0.84, width: m * 0.40, height: m * 0.07), cornerRadius: m * 0.03), with: .color(mast))
                if falsch {
                    var k = Path()
                    k.move(to: pt(0.10, 0.10)); k.addLine(to: pt(0.90, 0.90))
                    k.move(to: pt(0.90, 0.10)); k.addLine(to: pt(0.10, 0.90))
                    ctx.stroke(k, with: .color(mast), style: StrokeStyle(lineWidth: max(2, m * 0.09), lineCap: .round))
                }
            }
        }
    }
}
