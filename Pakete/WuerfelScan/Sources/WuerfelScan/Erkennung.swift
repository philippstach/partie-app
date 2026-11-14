// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import Foundation
import Vision

/// Ein erkannter Würfel: Augenzahl (1…6) und Lage im Bild (normiert, Ursprung oben links).
public struct ErkannterWuerfel: Equatable, Sendable {
    public let augen: Int
    public let rahmen: CGRect
    /// Innenumrisse, die keine Augen sind (nur zur Wahl der Hell-Dunkel-Richtung).
    let fremdeUmrisse: Int
    public init(augen: Int, rahmen: CGRect, fremdeUmrisse: Int = 0) {
        self.augen = augen; self.rahmen = rahmen; self.fremdeUmrisse = fremdeUmrisse
    }
}

/// Ergebnis eines Fotos: die Würfel von links nach rechts (Zeilen von oben nach unten).
public struct ScanErgebnis: Equatable, Sendable {
    public let wuerfel: [ErkannterWuerfel]
    public var augen: [Int] { wuerfel.map(\.augen) }
}

/// Liest Würfelaugen aus einem Foto. Gedacht für Würfel auf dem Tisch von oben:
/// Vision liefert Umrisse, ein Würfel ist ein annähernd quadratischer Umriss mit 1…6 kleinen runden Innenumrissen (den Augen).
/// Funktioniert für helle Würfel mit dunklen Augen und für dunkle mit hellen Augen.
public enum WuerfelErkenner {
    /// Bildgröße, auf der Vision rechnet (Rechenzeit gegen Genauigkeit).
    static let maxSeite = 768

    public static func erkenne(in bild: CGImage) throws -> ScanErgebnis {
        // Der Tisch nimmt den größten Teil des Bildes ein: ein dunkler Tisch heißt helle Würfel und umgekehrt.
        // Nur bei mittlerem Grau (oder wenn die Annahme nichts findet) werden beide Richtungen verglichen.
        let tisch = tischHelligkeit(bild)
        let zuerstDunkelAufHell = tisch > 0.5
        let erste = try kandidaten(bild, dunkelAufHell: zuerstDunkelAufHell)
        if abs(tisch - 0.5) > 0.12, !plausibel(erste).isEmpty {
            return ScanErgebnis(wuerfel: sortiert(plausibel(erste)))
        }
        let zweite = try kandidaten(bild, dunkelAufHell: !zuerstDunkelAufHell)
        let besser = punkte(erste) >= punkte(zweite) ? erste : zweite
        return ScanErgebnis(wuerfel: sortiert(plausibel(besser)))
    }

    /// Mittlere Helligkeit (Median) auf einem 32×32-Graubild, 0…1.
    static func tischHelligkeit(_ bild: CGImage) -> Double {
        let n = 32
        var pixel = [UInt8](repeating: 0, count: n * n)
        pixel.withUnsafeMutableBytes { p in
            guard let ctx = CGContext(data: p.baseAddress, width: n, height: n, bitsPerComponent: 8, bytesPerRow: n,
                                      space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return }
            ctx.interpolationQuality = .medium
            ctx.draw(bild, in: CGRect(x: 0, y: 0, width: n, height: n))
        }
        return Double(pixel.sorted()[pixel.count / 2]) / 255
    }

    /// Welche Hell-Dunkel-Richtung stimmt? Mehr Würfel zählt, dann Reinheit: im richtigen Modus sind alle Innenumrisse Augen.
    private static func punkte(_ liste: [ErkannterWuerfel]) -> Int {
        liste.reduce(0) { $0 + 100 - $1.fremdeUmrisse }
    }

    // MARK: Umrisse

    private static func kandidaten(_ bild: CGImage, dunkelAufHell: Bool) throws -> [ErkannterWuerfel] {
        let anfrage = VNDetectContoursRequest()
        anfrage.contrastAdjustment = 1.5
        anfrage.detectsDarkOnLight = dunkelAufHell
        anfrage.maximumImageDimension = maxSeite
        let handler = VNImageRequestHandler(cgImage: bild, options: [:])
        try handler.perform([anfrage])
        guard let ergebnis = anfrage.results?.first else { return [] }

        // Seitenverhältnis: normierte Punkte → gleich skalierte Einheiten, sonst stimmen Flächen und Rundheit nicht.
        let breite = Double(bild.width), hoehe = Double(bild.height)
        var gefunden: [ErkannterWuerfel] = []
        for umriss in ergebnis.topLevelContours {
            sammle(umriss, breite: breite, hoehe: hoehe, in: &gefunden)
        }
        return gefunden
    }

    /// Würfel können als Kind eines Tischumrisses auftauchen; deshalb wird die ganze Hierarchie durchsucht.
    private static func sammle(_ umriss: VNContour, breite: Double, hoehe: Double, in liste: inout [ErkannterWuerfel]) {
        if let w = alsWuerfel(umriss, breite: breite, hoehe: hoehe) {
            liste.append(w)
            return
        }
        for kind in umriss.childContours { sammle(kind, breite: breite, hoehe: hoehe, in: &liste) }
    }

    private static func alsWuerfel(_ umriss: VNContour, breite: Double, hoehe: Double) -> ErkannterWuerfel? {
        let form = Form(umriss, breite: breite, hoehe: hoehe)
        // Würfel: nicht winzig, nicht bildfüllend, annähernd quadratisch (Perspektive, Kippung erlaubt).
        guard form.flaeche > 0.0015, form.flaeche < 0.25, form.seitenverhaeltnis > 0.55 else { return nil }
        guard form.fuellgrad > 0.55 else { return nil }          // Quadrat ≈ 1, Dreieck/Strich weniger

        var augen = 0, fremde = 0
        for kind in umriss.childContours {
            let k = Form(kind, breite: breite, hoehe: hoehe)
            let anteil = k.flaeche / form.flaeche
            // Auge: klein gegenüber dem Würfel, rund.
            if anteil > 0.012, anteil < 0.14, k.seitenverhaeltnis > 0.6, k.fuellgrad > 0.6 { augen += 1 } else if anteil > 0.004 { fremde += 1 }
        }
        guard (1...6).contains(augen) else { return nil }
        return ErkannterWuerfel(augen: augen, rahmen: form.rahmen, fremdeUmrisse: fremde)
    }

    // MARK: Auswahl

    /// Wirft Ausreißer weg: Würfel eines Wurfs sind etwa gleich groß; Überlappungen (Würfel im Würfel) fallen heraus.
    static func plausibel(_ liste: [ErkannterWuerfel]) -> [ErkannterWuerfel] {
        guard liste.count > 1 else { return liste }
        let flaechen = liste.map { Double($0.rahmen.width * $0.rahmen.height) }.sorted()
        let median = flaechen[flaechen.count / 2]
        var rest = liste.filter {
            let f = Double($0.rahmen.width * $0.rahmen.height)
            return f > median * 0.45 && f < median * 2.2
        }
        rest.sort { $0.rahmen.width * $0.rahmen.height > $1.rahmen.width * $1.rahmen.height }
        var behalten: [ErkannterWuerfel] = []
        for w in rest where !behalten.contains(where: { schnittAnteil($0.rahmen, w.rahmen) > 0.5 }) { behalten.append(w) }
        return behalten
    }

    private static func schnittAnteil(_ a: CGRect, _ b: CGRect) -> Double {
        let s = a.intersection(b)
        if s.isNull { return 0 }
        let kleiner = min(a.width * a.height, b.width * b.height)
        return kleiner > 0 ? Double(s.width * s.height / kleiner) : 0
    }

    /// Lesereihenfolge: Zeilen (grobe Höhe) von oben nach unten, darin links nach rechts.
    static func sortiert(_ liste: [ErkannterWuerfel]) -> [ErkannterWuerfel] {
        guard let h = liste.map({ $0.rahmen.height }).max() else { return [] }
        return liste.sorted {
            let za = Int(($0.rahmen.midY / h).rounded()), zb = Int(($1.rahmen.midY / h).rounded())
            return za != zb ? za < zb : $0.rahmen.minX < $1.rahmen.minX
        }
    }

    // MARK: Geometrie eines Umrisses

    struct Form {
        let flaeche: Double            // Anteil an der Bildfläche
        let seitenverhaeltnis: Double  // kurze/lange Seite des Hüllrechtecks
        let fuellgrad: Double          // Umrissfläche / Hüllrechteck
        let rahmen: CGRect             // normiert, Ursprung oben links

        init(_ umriss: VNContour, breite: Double, hoehe: Double) {
            let p = umriss.normalizedPoints
            var minX = Double.infinity, maxX = -Double.infinity, minY = Double.infinity, maxY = -Double.infinity
            var summe = 0.0
            for i in p.indices {
                let a = p[i], b = p[(i + 1) % p.count]
                summe += Double(a.x) * Double(b.y) - Double(b.x) * Double(a.y)
                minX = min(minX, Double(a.x)); maxX = max(maxX, Double(a.x))
                minY = min(minY, Double(a.y)); maxY = max(maxY, Double(a.y))
            }
            let w = max(maxX - minX, 1e-9), h = max(maxY - minY, 1e-9)
            let pixelW = w * breite, pixelH = h * hoehe
            flaeche = abs(summe) / 2
            seitenverhaeltnis = min(pixelW, pixelH) / max(pixelW, pixelH)
            fuellgrad = flaeche / (w * h)
            rahmen = CGRect(x: minX, y: 1 - maxY, width: w, height: h)
        }
    }
}
