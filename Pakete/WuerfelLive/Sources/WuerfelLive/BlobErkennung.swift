// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import Foundation

/// Augen als Flecken suchen und zu Würfeln gruppieren – unabhängig von der Würfelfarbe.
/// Statt Umrissen (Vision) zählt der lokale Kontrast: ein Auge ist ein kleiner, runder Fleck, der heller oder dunkler ist als seine Umgebung.
/// Das findet rote, bunte, weiße und beige Würfel (auch auf weißem Tisch), solange die Augen sich vom Würfel abheben.
public struct BlobWuerfelErkennung: WuerfelErkennung {
    public init() {}

    /// Gerechnet wird auf drei Bildgrößen (längste Seite), jede mit den Fensterradien (Pixel) für ihren Bereich von Augengrößen:
    /// das volle Kamerabild für kleine, weit entfernte Würfel, das halbe für übliche Abstände, das Viertel für Nahaufnahmen.
    /// Zusammen: Würfelkanten von etwa 3 % bis 90 % der Bildbreite.
    static let stufen: [(maxSeite: Int, radien: [Int])] = [(1280, [6, 9, 13]), (640, [6, 9, 14, 21, 32]), (320, [24, 36])]
    /// Mindest-Kontrast zur Umgebung (0…1).
    static let schwelle: Float = 0.12

    public func erkenne(in bild: CGImage) throws -> [GesehenerWuerfel] {
        let lang = Double(max(bild.width, bild.height))
        var alle: [Fleck] = []
        var bezug: (breite: Int, hoehe: Int)?
        for stufe in Self.stufen {
            // Ist das Bild kaum größer als die nächste Stufe, bringt die feinere nichts.
            if stufe.maxSeite > 640, lang < 1.3 * 640 { continue }
            guard let g = Graubild(bild, maxSeite: stufe.maxSeite) else { continue }
            if bezug == nil { bezug = (g.breite, g.hoehe) }
            // Alle Flecken in den Maßstab der ersten (größten) Stufe umrechnen.
            let f = Double(bezug!.breite) / Double(g.breite)
            alle += Self.rohFlecken(in: g, radien: stufe.radien).map {
                Fleck(x: $0.x * f, y: $0.y * f, d: $0.d * f, hell: $0.hell, kontrast: $0.kontrast, fuell: $0.fuell, breite: $0.breite * f, hoehe: $0.hoehe * f)
            }
        }
        guard let b = bezug else { return [] }
        return Self.wuerfel(aus: Self.container(Self.entdoppelt(alle)), breite: b.breite, hoehe: b.hoehe)
    }

    // MARK: Graubild

    struct Graubild {
        let breite: Int, hoehe: Int
        var px: [Float]
        init?(_ bild: CGImage, maxSeite: Int) {
            let s = Double(maxSeite) / Double(max(bild.width, bild.height))
            let w = max(8, Int((Double(bild.width) * min(1, s)).rounded())), h = max(8, Int((Double(bild.height) * min(1, s)).rounded()))
            var roh = [UInt8](repeating: 0, count: w * h)
            let ok = roh.withUnsafeMutableBytes { p -> Bool in
                guard let ctx = CGContext(data: p.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w,
                                          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
                ctx.interpolationQuality = .medium
                ctx.draw(bild, in: CGRect(x: 0, y: 0, width: w, height: h))
                return true
            }
            guard ok else { return nil }
            breite = w; hoehe = h; px = roh.map { Float($0) / 255 }
        }
    }

    // MARK: Flecken

    struct Fleck {
        var x: Double, y: Double        // Schwerpunkt (Pixel)
        var d: Double                   // Durchmesser einer gleich großen Kreisfläche
        var hell: Bool                  // heller als die Umgebung
        var kontrast: Double
        var fuell: Double
        var breite: Double, hoehe: Double
        var punkte: Double { kontrast * fuell }
    }

    static func flecken(in g: Graubild, radien: [Int] = [6, 9, 14, 21, 32]) -> [Fleck] {
        container(entdoppelt(rohFlecken(in: g, radien: radien)))
    }

    private static func rohFlecken(in g: Graubild, radien: [Int]) -> [Fleck] {
        let w = g.breite, h = g.hoehe
        // Integralbild für schnelle Fenstermittel.
        var integral = [Double](repeating: 0, count: (w + 1) * (h + 1))
        for y in 0..<h {
            var zeile = 0.0
            for x in 0..<w {
                zeile += Double(g.px[y * w + x])
                integral[(y + 1) * (w + 1) + x + 1] = integral[y * (w + 1) + x + 1] + zeile
            }
        }
        var alle: [Fleck] = []
        var diff = [Float](repeating: 0, count: w * h)
        for r in radien where r * 3 < min(w, h) {
            for y in 0..<h {
                let y0 = max(0, y - r), y1 = min(h - 1, y + r) + 1
                for x in 0..<w {
                    let x0 = max(0, x - r), x1 = min(w - 1, x + r) + 1
                    let summe = integral[y1 * (w + 1) + x1] - integral[y0 * (w + 1) + x1] - integral[y1 * (w + 1) + x0] + integral[y0 * (w + 1) + x0]
                    diff[y * w + x] = g.px[y * w + x] - Float(summe / Double((x1 - x0) * (y1 - y0)))
                }
            }
            for hell in [false, true] { alle += komponenten(diff, w, h, r, hell) }
        }
        return alle
    }

    private static func komponenten(_ d: [Float], _ w: Int, _ h: Int, _ r: Int, _ hell: Bool) -> [Fleck] {
        var besucht = [Bool](repeating: false, count: w * h)
        var ergebnis: [Fleck] = []
        var stapel: [Int] = []
        let t = schwelle
        @inline(__always) func gilt(_ i: Int) -> Bool { hell ? d[i] > t : d[i] < -t }
        for start in 0..<(w * h) where !besucht[start] && gilt(start) {
            stapel.removeAll(keepingCapacity: true)
            stapel.append(start); besucht[start] = true
            var flaeche = 0, sx = 0.0, sy = 0.0, sk = 0.0
            var minX = w, maxX = 0, minY = h, maxY = 0
            while let i = stapel.popLast() {
                let x = i % w, y = i / w
                flaeche += 1; sx += Double(x); sy += Double(y); sk += Double(abs(d[i]))
                minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
                if x > 0, !besucht[i - 1], gilt(i - 1) { besucht[i - 1] = true; stapel.append(i - 1) }
                if x < w - 1, !besucht[i + 1], gilt(i + 1) { besucht[i + 1] = true; stapel.append(i + 1) }
                if y > 0, !besucht[i - w], gilt(i - w) { besucht[i - w] = true; stapel.append(i - w) }
                if y < h - 1, !besucht[i + w], gilt(i + w) { besucht[i + w] = true; stapel.append(i + w) }
            }
            let bw = Double(maxX - minX + 1), bh = Double(maxY - minY + 1)
            let dm = 2 * (Double(flaeche) / Double.pi).squareRoot()
            guard flaeche >= 8, dm >= 0.35 * Double(r), dm <= 0.9 * Double(r),
                  min(bw, bh) / max(bw, bh) >= 0.6 else { continue }
            let fuell = Double(flaeche) / (bw * bh)
            guard fuell >= 0.62 else { continue }
            let k = sk / Double(flaeche)
            guard k >= 0.15 else { continue }
            ergebnis.append(Fleck(x: sx / Double(flaeche), y: sy / Double(flaeche), d: dm, hell: hell, kontrast: k, fuell: fuell, breite: bw, hoehe: bh))
        }
        return ergebnis
    }

    /// Dasselbe Auge taucht in mehreren Größenstufen auf: der beste Fund bleibt.
    private static func entdoppelt(_ liste: [Fleck]) -> [Fleck] {
        var behalten: [Fleck] = []
        for f in liste.sorted(by: { $0.punkte > $1.punkte }) {
            if !behalten.contains(where: { $0.hell == f.hell && hypot($0.x - f.x, $0.y - f.y) < 0.6 * max($0.d, f.d) }) { behalten.append(f) }
        }
        return behalten
    }

    /// Ein Fleck, der kleinere Flecken der Gegenfarbe umschließt, ist die Würfelfläche (mit ihren Augen), kein Auge.
    private static func container(_ liste: [Fleck]) -> [Fleck] {
        liste.filter { a in
            !liste.contains { b in
                b.hell != a.hell && b.d < 0.6 * a.d && abs(b.x - a.x) < a.breite / 2 && abs(b.y - a.y) < a.hoehe / 2
            }
        }
    }

    // MARK: Gruppieren

    /// Flecken zu Würfeln: gleiche Farbe, ähnliche Größe, nah beieinander.
    static func wuerfel(aus flecken: [Fleck], breite: Int, hoehe: Int) -> [GesehenerWuerfel] {
        var ergebnis: [(w: GesehenerWuerfel, flaeche: Double)] = []
        for hell in [false, true] {
            let teil = flecken.filter { $0.hell == hell }
            for gruppe in zweierVerbunden(gruppiere(teil, faktor: 3.7)) {
                let kandidaten = gruppe.count > 6 ? gruppiere(gruppe, faktor: 2.9).filter { $0.count <= 6 } : [gruppe]
                for k in kandidaten {
                    if let w = alsWuerfel(k, breite: Double(breite), hoehe: Double(hoehe)) { ergebnis.append((w, Double(w.rahmen.width * w.rahmen.height))) }
                }
            }
        }
        return sortiert(auswahl(ergebnis))
    }

    /// Die „Zwei“: Ihre beiden Augen liegen so weit auseinander (0,7 Würfelkanten), dass sie bei kleinen Augen nicht mehr als
    /// Gruppe gelten und als zwei Einsen gelesen würden. Zwei einzelne Augen gleicher Größe, die einander am nächsten und näher
    /// als 4,6 Augendurchmesser sind, gehören zusammen (zwei echte Einsen nebeneinander liegen mindestens eine Kante = 5 Durchmesser auseinander).
    private static func zweierVerbunden(_ gruppen: [[Fleck]]) -> [[Fleck]] {
        let einzeln = gruppen.filter { $0.count == 1 }.map { $0[0] }
        guard einzeln.count >= 2 else { return gruppen }
        func naechster(_ i: Int) -> Int? {
            var bester: (Int, Double)?
            for j in einzeln.indices where j != i {
                let a = einzeln[i], b = einzeln[j]
                let d = hypot(a.x - b.x, a.y - b.y)
                if max(a.d, b.d) / max(min(a.d, b.d), 0.1) <= 1.6, d <= 4.6 * (a.d + b.d) / 2, bester == nil || d < bester!.1 { bester = (j, d) }
            }
            return bester?.0
        }
        var ergebnis = gruppen.filter { $0.count != 1 }
        var erledigt = Set<Int>()
        for i in einzeln.indices where !erledigt.contains(i) {
            if let j = naechster(i), !erledigt.contains(j), naechster(j) == i {
                ergebnis.append([einzeln[i], einzeln[j]]); erledigt.insert(i); erledigt.insert(j)
            } else {
                ergebnis.append([einzeln[i]]); erledigt.insert(i)
            }
        }
        return ergebnis
    }

    private static func gruppiere(_ f: [Fleck], faktor: Double) -> [[Fleck]] {
        var eltern = Array(f.indices)
        func wurzel(_ i: Int) -> Int { var j = i; while eltern[j] != j { eltern[j] = eltern[eltern[j]]; j = eltern[j] }; return j }
        for i in f.indices { for j in f.indices where j > i {
            let a = f[i], b = f[j]
            let verhaeltnis = max(a.d, b.d) / max(min(a.d, b.d), 0.1)
            if verhaeltnis <= 1.6, hypot(a.x - b.x, a.y - b.y) <= faktor * (a.d + b.d) / 2 { eltern[wurzel(i)] = wurzel(j) }
        } }
        var gruppen: [Int: [Fleck]] = [:]
        for i in f.indices { gruppen[wurzel(i), default: []].append(f[i]) }
        return Array(gruppen.values)
    }

    private static func alsWuerfel(_ g: [Fleck], breite: Double, hoehe: Double) -> GesehenerWuerfel? {
        guard (1...6).contains(g.count) else { return nil }
        let dm = g.map(\.d).reduce(0, +) / Double(g.count)
        // Augen berühren sich nicht.
        for i in g.indices { for j in g.indices where j > i && hypot(g[i].x - g[j].x, g[i].y - g[j].y) < 1.15 * dm { return nil } }
        if g.count == 1, g[0].kontrast < 0.22 { return nil }
        let punkte = g.map { (x: $0.x, y: $0.y) }
        // Augenmuster: passt die Anordnung zu einem echten Würfelbild (auch gedreht), zählt das Muster – ein übersehenes Auge wird ergänzt.
        if let t = Augenmuster.deute(punkte, augenDurchmesser: dm) {
            let kante = t.seite * (abs(cos(t.winkel)) + abs(sin(t.winkel))) * 1.06   // umschließendes Rechteck des gedrehten Würfels
            let rahmen = CGRect(x: (Double(t.mitte.x) - kante / 2) / breite, y: (Double(t.mitte.y) - kante / 2) / hoehe, width: kante / breite, height: kante / hoehe)
            return GesehenerWuerfel(augen: t.augen, rahmen: rahmen)
        }
        let minX = g.map(\.x).min()!, maxX = g.map(\.x).max()!, minY = g.map(\.y).min()!, maxY = g.map(\.y).max()!
        // Die Augen liegen bei ¼ und ¾ der Kante: der Abstand der äußeren Augen ist die halbe Würfelkante (mit etwas Rand).
        let seite = max(2.3 * max(maxX - minX, maxY - minY), 5.0 * dm) * 1.05
        let cx = (minX + maxX) / 2, cy = (minY + maxY) / 2
        let rahmen = CGRect(x: (cx - seite / 2) / breite, y: (cy - seite / 2) / hoehe, width: seite / breite, height: seite / hoehe)
        return GesehenerWuerfel(augen: g.count, rahmen: rahmen)
    }

    /// Ausreißer in der Größe und Überlappungen fallen weg (mehr Augen und größere Fläche gewinnen).
    private static func auswahl(_ liste: [(w: GesehenerWuerfel, flaeche: Double)]) -> [GesehenerWuerfel] {
        var rest = liste
        if rest.count > 2 {
            let med = rest.map(\.flaeche).sorted()[rest.count / 2]
            rest = rest.filter { $0.flaeche > med * 0.4 && $0.flaeche < med * 2.5 }
        }
        rest.sort { ($0.w.augen, $0.flaeche) > ($1.w.augen, $1.flaeche) }
        var behalten: [GesehenerWuerfel] = []
        for e in rest where !behalten.contains(where: { ueberlappt($0.rahmen, e.w.rahmen) }) { behalten.append(e.w) }
        return behalten
    }

    private static func ueberlappt(_ a: CGRect, _ b: CGRect) -> Bool {
        let s = a.intersection(b)
        if s.isNull { return false }
        return Double(s.width * s.height) > 0.3 * Double(min(a.width * a.height, b.width * b.height))
    }

    static func sortiert(_ liste: [GesehenerWuerfel]) -> [GesehenerWuerfel] {
        guard let h = liste.map({ $0.rahmen.height }).max() else { return [] }
        return liste.sorted {
            let za = Int(($0.rahmen.midY / h).rounded()), zb = Int(($1.rahmen.midY / h).rounded())
            return za != zb ? za < zb : $0.rahmen.minX < $1.rahmen.minX
        }
    }
}

/// Standard der Live-Erkennung: erst die Flecken-Suche (farbunabhängig); findet sie nichts, die Umriss-Erkennung aus F6.
public struct KombinierteErkennung: WuerfelErkennung {
    private let blob = BlobWuerfelErkennung()
    private let vision = VisionWuerfelErkennung()
    public init() {}
    public func erkenne(in bild: CGImage) throws -> [GesehenerWuerfel] {
        let b = try blob.erkenne(in: bild)
        if !b.isEmpty { return b }
        return (try? vision.erkenne(in: bild)) ?? []
    }
}
