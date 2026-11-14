// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

// Runde 5, Blatt 19 (KS-F): Kartensatz „Figuren“ mit gezeichnetem Buben, Dame und König.
// Die Linien stehen als SVG-Pfade im Feld 100 × 71 (obere Hälfte), die untere Hälfte ist dieselbe Hälfte um 180° gedreht.
// Pfade 1:1 aus werkzeug/ks19.py (Design-Chat). Farben aus dem `KartenStil`: Linien und Haar Schwarz, Kleid Rot (Herz, Karo)
// oder Tintengrau (Kreuz, Pik), Flächen Papier. Kein Gold.

/// Die Figur einer Bildkarte (B, D, K) im Feld 100 × 142; skaliert nach der Kartenbreite.
public struct KartenFigur: View {
    let rang: String
    let rot: Bool
    let stil: KartenStil

    public init(rang: String, rot: Bool, stil: KartenStil) { self.rang = rang; self.rot = rot; self.stil = stil }

    /// Gibt es für diesen Rang eine Figur?
    public static func hat(_ rang: String) -> Bool { rang == "B" || rang == "D" || rang == "K" }

    /// Tintengrau: das Kleid der schwarzen Farben.
    static let grau = Color(hex: 0x4A4D57)

    enum Fuellung { case linie, papier, kleid, keine }
    enum Form {
        case pfad(String)
        case ellipse(CGFloat, CGFloat, CGFloat, CGFloat)   // cx, cy, rx, ry
    }
    struct Teil {
        let form: Form
        let fuellung: Fuellung
        let strich: CGFloat?
    }

    private static func kreis(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ f: Fuellung, _ s: CGFloat? = nil) -> Teil { Teil(form: .ellipse(x, y, r, r), fuellung: f, strich: s) }
    private static func pfad(_ d: String, _ f: Fuellung, _ s: CGFloat? = 1.5) -> Teil { Teil(form: .pfad(d), fuellung: f, strich: s) }

    /// Obere Hälfte, in Zeichenreihenfolge.
    static func teile(_ rang: String) -> [Teil] {
        let w: CGFloat = rang == "K" ? 16 : 20
        let kleid = pfad("M\(w) 72 L\(w + 3) 60 C\(w + 6) 55 34 53 41 51 L59 51 C66 53 \(94 - w) 55 \(97 - w) 60 L\(100 - w) 72 Z", .kleid)
        let hals = pfad("M44.5 43 V53 H55.5 V43 Z", .papier)
        let kopf = Teil(form: .ellipse(50, 33, 10.5, 12.5), fuellung: .papier, strich: 1.5)
        let augen = [kreis(45.8, 33, 1.15, .linie), kreis(54.2, 33, 1.15, .linie)]
        let nase = pfad("M50 33.5 V38", .keine, 1.1)
        switch rang {
        case "B":
            let haar = pfad("M37 31 C36 17 64 17 63 31 L64.5 45 C62 49 58.5 48 57.5 46 L57 30 H43 L42.5 46 C41.5 48 38 49 35.5 45 Z", .linie, nil)
            let kragen = pfad("M41 51 L50 63 L59 51 L55.5 51 L50 57 L44.5 51 Z", .papier)
            let knopf = kreis(50, 66.5, 1.3, .papier)
            let mund = pfad("M47.3 40.8 Q50 42.6 52.7 40.8", .keine, 1.1)
            let feder = pfad("M59 19 C64 6 76 4 82 9 C75 10 68 15 63 23 Z", .papier)
            let federLinie = pfad("M61 20 C66 13 72 9.5 79 9", .keine, 0.9)
            let muetze = pfad("M35.5 26.5 C33 15 52 9 64 17 C68 20 67 25 62.5 25.5 Z", .kleid)
            return [kleid, kragen, knopf, hals, haar, kopf] + augen + [nase, mund, feder, federLinie, muetze]
        case "D":
            let haar = pfad("M37 32 C34 15 66 15 63 32 C63.5 40 66 45 68.5 50 C64 53.5 59.5 51 58.5 47 L57.5 31 H42.5 L41.5 47 C40.5 51 36 53.5 31.5 50 C34 45 36.5 40 37 32 Z", .linie, nil)
            let ausschnitt = pfad("M41 51 Q50 65 59 51 Z", .papier)
            let kette = [(45.3, 55.4), (47.6, 57.2), (50, 57.9), (52.4, 57.2), (54.7, 55.4)].map { kreis(CGFloat($0.0), CGFloat($0.1), 1, .linie) }
            let krone = pfad("M41 23.5 L42 14.5 L46.2 19.5 L50 12 L53.8 19.5 L58 14.5 L59 23.5 Z", .kleid)
            let scheitel = pfad("M39.5 30 C43 25 48 23.5 50 23.5 C52 23.5 57 25 60.5 30 C56 26.5 44 26.5 39.5 30 Z", .linie, nil)
            let lippe = pfad("M47.6 40.6 Q50 43 52.4 40.6 Q50 39.7 47.6 40.6 Z", .kleid, nil)
            return [kleid, ausschnitt, hals] + kette + [haar, kopf, scheitel] + augen + [nase, lippe, krone]
        default:
            let haar = pfad("M38.5 26 C36 31 36.5 39 39.5 42 L41 30 Z M61.5 26 C64 31 63.5 39 60.5 42 L59 30 Z", .linie, 1)
            let bart = pfad("M39.6 36 C39.5 49 45 54.5 50 55.5 C55 54.5 60.5 49 60.4 36 C57.5 40.5 53.5 41 50 39 C46.5 41 42.5 40.5 39.6 36 Z", .linie, nil)
            let pelz = pfad("M22.5 58 C33 53 43 54.5 50 61 C57 54.5 67 53 77.5 58 L78.5 61.8 C67 57.5 57 58.5 50 64.8 C43 58.5 33 57.5 21.5 61.8 Z", .papier)
            let pelzKnopf = kreis(50, 64.3, 2.3, .papier, 1.2)
            let krone = pfad("M37.5 24 L35.5 8.5 L43 16 L50 5.5 L57 16 L64.5 8.5 L62.5 24 Z", .kleid)
            let kronenband = pfad("M38 20 H62", .keine, 1.3)
            return [kleid, pelz, pelzKnopf, hals, haar, kopf] + augen + [nase, bart, krone, kronenband]
        }
    }

    public var body: some View {
        let kleidFarbe = rot ? stil.rot : Self.grau
        let linie = stil.schwarz, papier = stil.papier
        let guertelRand: CGFloat = rang == "K" ? 14.5 : 18.5
        let teile = Self.teile(rang)
        Canvas { ctx, size in
            let s = size.width / 100
            let oy = (size.height - 142 * s) / 2
            var basis = ctx
            basis.translateBy(x: 0, y: oy)
            basis.scaleBy(x: s, y: s)

            func farbe(_ f: Fuellung) -> Color? {
                switch f { case .linie: linie; case .papier: papier; case .kleid: kleidFarbe; case .keine: nil }
            }
            func zeichne(_ c: GraphicsContext) {
                for t in teile {
                    let p: Path
                    switch t.form {
                    case .pfad(let d): p = SVGPfad.pfad(d)
                    case .ellipse(let cx, let cy, let rx, let ry): p = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: 2 * rx, height: 2 * ry))
                    }
                    if let f = farbe(t.fuellung) { c.fill(p, with: .color(f)) }
                    if let sw = t.strich {
                        c.stroke(p, with: .color(linie), style: StrokeStyle(lineWidth: sw, lineCap: .round, lineJoin: .round))
                    }
                }
            }
            zeichne(basis)
            var unten = basis
            unten.translateBy(x: 50, y: 71)
            unten.rotate(by: .degrees(180))
            unten.translateBy(x: -50, y: -71)
            zeichne(unten)
            // Gürtel in der Mitte
            let band = Path(roundedRect: CGRect(x: guertelRand, y: 68.2, width: 100 - 2 * guertelRand, height: 5.6), cornerRadius: 1.2)
            basis.fill(band, with: .color(papier))
            basis.stroke(band, with: .color(linie), style: StrokeStyle(lineWidth: 1.5, lineJoin: .round))
            basis.fill(SVGPfad.pfad("M50 68.8 L53.2 71 L50 73.2 L46.8 71 Z"), with: .color(kleidFarbe))
        }
        .accessibilityHidden(true)
    }
}

/// Kleiner Leser für SVG-Pfade mit den absoluten Befehlen M, L, H, V, C, Q und Z (mehr brauchen die Figuren nicht).
enum SVGPfad {
    static func pfad(_ d: String) -> Path {
        var p = Path()
        var zahlen: [CGFloat] = []
        var befehl: Character = "M"
        var aktuell = CGPoint.zero
        var start = CGPoint.zero

        func ausfuehren() {
            let z = zahlen
            switch befehl {
            case "M" where z.count >= 2:
                aktuell = CGPoint(x: z[0], y: z[1]); start = aktuell; p.move(to: aktuell)
            case "L" where z.count >= 2:
                aktuell = CGPoint(x: z[0], y: z[1]); p.addLine(to: aktuell)
            case "H" where z.count >= 1:
                aktuell = CGPoint(x: z[0], y: aktuell.y); p.addLine(to: aktuell)
            case "V" where z.count >= 1:
                aktuell = CGPoint(x: aktuell.x, y: z[0]); p.addLine(to: aktuell)
            case "C" where z.count >= 6:
                aktuell = CGPoint(x: z[4], y: z[5])
                p.addCurve(to: aktuell, control1: CGPoint(x: z[0], y: z[1]), control2: CGPoint(x: z[2], y: z[3]))
            case "Q" where z.count >= 4:
                aktuell = CGPoint(x: z[2], y: z[3])
                p.addQuadCurve(to: aktuell, control: CGPoint(x: z[0], y: z[1]))
            default: break
            }
        }
        func benoetigt(_ c: Character) -> Int {
            switch c { case "M", "L": 2; case "H", "V": 1; case "C": 6; case "Q": 4; default: 0 }
        }

        var zahl = ""
        func zahlAbschliessen() {
            if !zahl.isEmpty, let v = Double(zahl) { zahlen.append(CGFloat(v)) }
            zahl = ""
            let n = benoetigt(befehl)
            if n > 0, zahlen.count == n {
                ausfuehren()
                zahlen = []
                if befehl == "M" { befehl = "L" }   // weitere Paare nach M sind Linien
            }
        }
        for ch in d {
            if ch.isLetter {
                zahlAbschliessen()
                befehl = ch
                zahlen = []
                if ch == "Z" { p.closeSubpath(); aktuell = start }
            } else if ch == " " || ch == "," {
                zahlAbschliessen()
            } else if ch == "-" {
                zahlAbschliessen(); zahl = "-"
            } else {
                zahl.append(ch)
            }
        }
        zahlAbschliessen()
        return p
    }
}
#endif
