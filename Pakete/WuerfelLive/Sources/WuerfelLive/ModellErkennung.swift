// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import CoreML
import Foundation
import Vision
import WuerfelScan
#if canImport(UIKit)
import SwiftUI
#endif

/// Würfel mit zwei kleinen trainierten Netzen lesen (beide mit gerenderten Würfelbildern trainiert, zusammen unter 5 MB):
/// 1. `WuerfelFinder` findet in einem quadratischen Bild die Mittelpunkte und Größen aller Würfel.
/// 2. `WuerfelAugen` liest aus dem Ausschnitt eines Würfels die Augenzahl (oder „kein Würfel“).
/// Ersetzt die Flecken-Suche: Die Netze haben Seitenflächen, Glanz, Schatten und gemusterte Tische im Training gesehen.
///
/// Ein Kamerabild (9:16) wird in überlappende Quadrate zerlegt; sind die gefundenen Würfel klein, wird ihr Bereich noch
/// einmal vergrößert abgesucht. Die Augenzahl wird immer aus dem Bild in voller Auflösung gelesen.
///
/// Live (W4, 13.11.2026): Sind schon Würfel verfolgt, sucht der Finder meist nur noch ein Quadrat um sie herum ab
/// (ein Durchlauf statt drei bis vier). Bei schon verfolgten Würfeln gelten niedrigere Schwellen, damit sie nicht kurz verschwinden.
public final class ModellWuerfelErkennung: WuerfelErkennung, @unchecked Sendable {
    private let finder: MLModel
    private let augen: MLModel
    /// Mindest-Sicherheit eines Fundes (0…1).
    public var schwelle: Float = 0.3
    /// Mindest-Sicherheit der Augenzahl; darunter gilt der Fund nicht als Würfel.
    public var augenSchwelle: Float = 0.45
    /// Mindest-Sicherheit aus beiden Netzen zusammen. Seit Build 18 0,5 (Würfeltraining: auf 100 Alltagsfotos nur noch 3–4 statt 11 Fehlfunde, alle 180 echten Fotos richtig). Frühere Messung bei 0,4:
    /// Gemessen (11.11.2026): Bei 0,4 bleiben auf 100 Alltagsfotos ohne Würfel 5 Fehlfunde
    /// (ohne Schwelle 11), auf den gerenderten Prüfbildern sinkt der Anteil sofort erkannter Würfel nur von 95 % auf 94 %.
    public var mindestSicherheit: Float = 0.5
    /// Niedrigere Schwellen dort, wo schon ein Würfel verfolgt wird (Finder, Augen-Netz, beide zusammen).
    /// Ein Fehlfund müsste dafür zuerst über mehrere Bilder mit den normalen Schwellen entstanden sein.
    public var verfolgtSchwelle: Float = 0.15
    public var verfolgtAugenSchwelle: Float = 0.35
    public var verfolgtSicherheit: Float = 0.3
    /// Unter dieser Kantenlänge (Anteil der kurzen Bildseite) lohnt die zweite, vergrößerte Suche.
    static let kleinGrenze = 0.09
    static let standardFinderKante = 448, standardAugenKante = 64, schritt = 4
    /// Eingangsgröße der Netze, aus dem Modell gelesen (so kann ein neu trainiertes Augen-Netz z. B. 96 × 96 haben).
    let finderKante: Int, augenKante: Int

    /// Die mitgelieferten Modelle (Ordner `Modell` im Paket). `nil`, wenn sie fehlen oder nicht geladen werden können.
    public convenience init?() {
        guard let f = Bundle.module.url(forResource: "WuerfelFinder", withExtension: "mlmodelc", subdirectory: "Modell") else { return nil }
        self.init(ordner: f.deletingLastPathComponent())
    }

    /// Modelle `WuerfelFinder.mlmodelc` und `WuerfelAugen.mlmodelc` aus einem Ordner.
    public init?(ordner: URL) {
        let k = MLModelConfiguration()
        guard let f = try? MLModel(contentsOf: ordner.appendingPathComponent("WuerfelFinder.mlmodelc"), configuration: k),
              let a = try? MLModel(contentsOf: ordner.appendingPathComponent("WuerfelAugen.mlmodelc"), configuration: k) else { return nil }
        finder = f; augen = a
        finderKante = Self.eingangsKante(f, standard: Self.standardFinderKante)
        augenKante = Self.eingangsKante(a, standard: Self.standardAugenKante)
    }

    /// Seitenlänge des quadratischen Bild-Eingangs `bild`; fehlt die Angabe oder ist sie nicht quadratisch, der Standard.
    static func eingangsKante(_ modell: MLModel, standard: Int) -> Int {
        guard let c = modell.modelDescription.inputDescriptionsByName["bild"]?.imageConstraint,
              c.pixelsWide > 0, c.pixelsWide == c.pixelsHigh else { return standard }
        return c.pixelsWide
    }

    struct Fund { var augen: Int; var rahmen: CGRect; var sicherheit: Float }   // Rahmen in Pixeln des ganzen Bildes

    public func erkenne(in bild: CGImage) throws -> [GesehenerWuerfel] {
        try erkenne(in: bild, verfolgt: [], ganzesBild: true)
    }

    public func erkenne(in bild: CGImage, verfolgt: [CGRect], ganzesBild: Bool) throws -> [GesehenerWuerfel] {
        let b = Double(bild.width), h = Double(bild.height)
        let spuren = verfolgt.map { CGRect(x: Double($0.minX) * b, y: Double($0.minY) * h, width: Double($0.width) * b, height: Double($0.height) * h) }
            .filter { $0.width > 1 && $0.height > 1 }
        var funde: [Fund] = []
        if !ganzesBild, let q = Self.suchQuadrat(um: spuren, breite: b, hoehe: h) {
            // Nur der Bereich um die verfolgten Würfel: ein Finder-Durchlauf. Das Quadrat ist schon eng, eine zweite Nahsuche entfällt.
            funde = Self.ohneDoppelte(try suche(bild, ausschnitt: q, spuren: spuren))
        } else {
            funde = try sucheGanz(bild, spuren: spuren)
        }
        // Augenzahl je Fund aus dem Bild in voller Auflösung; was das Augen-Netz nicht als Würfel sieht, fällt weg.
        var gelesen: [Fund] = []
        for f in funde {
            let bekannt = Self.verfolgt(f.rahmen, in: spuren)
            guard let (wert, p) = try lies(bild, rahmen: f.rahmen, schwelle: bekannt ? min(augenSchwelle, verfolgtAugenSchwelle) : nil) else { continue }
            let sicher = min(f.sicherheit, 1) * p
            if sicher >= (bekannt ? min(mindestSicherheit, verfolgtSicherheit) : mindestSicherheit) { gelesen.append(Fund(augen: wert, rahmen: f.rahmen, sicherheit: sicher)) }
        }
        let ergebnis = Self.gleichGross(gelesen).map {
            GesehenerWuerfel(augen: $0.augen, rahmen: CGRect(x: Double($0.rahmen.minX) / b, y: Double($0.rahmen.minY) / h, width: Double($0.rahmen.width) / b, height: Double($0.rahmen.height) / h), sicherheit: Double($0.sicherheit))
        }
        return BlobWuerfelErkennung.sortiert(ergebnis)
    }

    /// Ganzes Bild in Kacheln absuchen, bei kleinen Würfeln deren Bereich noch einmal vergrößert (ohne Augenzahl).
    private func sucheGanz(_ bild: CGImage, spuren: [CGRect]) throws -> [Fund] {
        let b = Double(bild.width), h = Double(bild.height)
        var funde: [Fund] = []
        for k in Self.kacheln(breite: b, hoehe: h) { funde += try suche(bild, ausschnitt: k, spuren: spuren) }
        funde = Self.ohneDoppelte(funde)
        // Kleine Würfel: den Bereich aller Funde vergrößert noch einmal absuchen – dort sitzen die Rahmen genauer, und übersehene Nachbarn tauchen auf.
        if let erster = funde.first, funde.map({ Double(max($0.rahmen.width, $0.rahmen.height)) }).min()! < Self.kleinGrenze * min(b, h) {
            var alle = erster.rahmen
            for f in funde { alle = alle.union(f.rahmen) }
            let kante = Double(funde.map { max($0.rahmen.width, $0.rahmen.height) }.max()!)
            let seite = min(min(b, h), max(Double(max(alle.width, alle.height)) + 2 * kante, 5 * kante))
            if seite < 0.75 * min(b, h) {
                let x = min(max(0, Double(alle.midX) - seite / 2), b - seite), y = min(max(0, Double(alle.midY) - seite / 2), h - seite)
                let nah = try suche(bild, ausschnitt: CGRect(x: x, y: y, width: seite, height: seite), spuren: spuren)
                // Die Nahaufnahme gewinnt, wo sie denselben Würfel sieht.
                funde = Self.ohneDoppelte(nah.map { Fund(augen: 0, rahmen: $0.rahmen, sicherheit: $0.sicherheit + 1) } + funde)
            }
        }
        return funde
    }

    /// Quadrat (Pixel) um alle verfolgten Würfel mit Rand für Bewegung und Nachbarn: mindestens anderthalb Würfelkanten rundum,
    /// insgesamt mindestens fünf Kanten. `nil`, wenn keine Spur da ist oder das Quadrat fast so groß wie die kurze Bildseite wäre
    /// (dann bringt es nichts, das ganze Bild ist besser).
    static func suchQuadrat(um spuren: [CGRect], breite b: Double, hoehe h: Double) -> CGRect? {
        guard let erste = spuren.first else { return nil }
        var alle = erste
        for s in spuren { alle = alle.union(s) }
        let kante = Double(spuren.map { max($0.width, $0.height) }.max()!)
        let kurz = min(b, h)
        let seite = max(Double(max(alle.width, alle.height)) + 3 * kante, 5 * kante)
        guard seite <= 0.85 * kurz, kante > 0 else { return nil }
        let x = min(max(0, Double(alle.midX) - seite / 2), b - seite), y = min(max(0, Double(alle.midY) - seite / 2), h - seite)
        return CGRect(x: x, y: y, width: seite, height: seite)
    }

    /// Liegt ein Fund dort, wo schon ein Würfel verfolgt wird? Mittelpunkt höchstens 0,6 Kanten entfernt, Größe höchstens doppelt so groß oder halb so groß.
    static func verfolgt(_ r: CGRect, in spuren: [CGRect]) -> Bool {
        let k = Double(max(r.width, r.height))
        return spuren.contains { s in
            let ks = Double(max(s.width, s.height))
            guard ks > 0, k >= 0.5 * ks, k <= 2 * ks else { return false }
            return hypot(Double(r.midX - s.midX), Double(r.midY - s.midY)) <= 0.6 * ks
        }
    }

    /// Niedrigere Schwellen für die Nahprüfung: Der Nutzer hat gezeigt, dass dort ein Würfel liegt – gesucht wird nur noch, wo genau und welche Zahl.
    static let nahSchwelle: Float = 0.08, nahAugenSchwelle: Float = 0.2

    /// Wählt aus den Funden den, der zur angetippten Stelle gehört: Die Stelle liegt im (etwas vergrößerten) Rahmen, der nächste Mittelpunkt gewinnt.
    static func amNaechsten(_ funde: [Fund], zu punkt: CGPoint) -> Fund? {
        func abstand(_ f: Fund) -> Double { hypot(Double(f.rahmen.midX - punkt.x), Double(f.rahmen.midY - punkt.y)) / Double(max(f.rahmen.width, f.rahmen.height, 1)) }
        return funde.filter { abstand($0) <= 0.8 }.min { abstand($0) < abstand($1) }
    }

    /// Nahprüfung: Ausschnitte in mehreren Größen um die angetippte Stelle werden vergrößert mit niedriger Schwelle abgesucht, der sicherste Fund zählt.
    /// Findet das Netz nichts, gilt ein Rahmen üblicher Größe um die Stelle – die Augenzahl entscheidet dann, ob dort ein Würfel liegt.
    public func erkenneNah(in bild: CGImage, um punkt: CGPoint, ueblicheKante: Double?) throws -> GesehenerWuerfel? {
        let b = Double(bild.width), h = Double(bild.height), kurz = min(b, h)
        guard (0...1).contains(punkt.x), (0...1).contains(punkt.y) else { return nil }
        let p = CGPoint(x: Double(punkt.x) * b, y: Double(punkt.y) * h)
        let seiten: [Double] = ueblicheKante.map { [$0 * kurz * 3, $0 * kurz * 5, $0 * kurz * 9] } ?? [0.2 * kurz, 0.35 * kurz, 0.55 * kurz]
        var fund: Fund?
        for s in seiten {
            let seite = min(max(s, 48), kurz)
            let x = min(max(0, Double(p.x) - seite / 2), b - seite), y = min(max(0, Double(p.y) - seite / 2), h - seite)
            let funde = try suche(bild, ausschnitt: CGRect(x: x, y: y, width: seite, height: seite), schwelle: Self.nahSchwelle)
            // Zu enge Ausschnitte treffen den Würfel schlecht (unsicher, falscher Rahmen): der sicherste Fund über alle Größen gewinnt.
            if let f = Self.amNaechsten(funde, zu: p), f.sicherheit > (fund?.sicherheit ?? 0) { fund = f }
        }
        let rahmen: CGRect
        if let fund { rahmen = fund.rahmen } else {
            let kante = (ueblicheKante ?? 0.12) * kurz
            rahmen = CGRect(x: Double(p.x) - kante / 2, y: Double(p.y) - kante / 2, width: kante, height: kante)
        }
        guard let (wert, _) = try lies(bild, rahmen: rahmen, schwelle: Self.nahAugenSchwelle) else { return nil }
        return GesehenerWuerfel(augen: wert, rahmen: CGRect(x: Double(rahmen.minX) / b, y: Double(rahmen.minY) / h, width: Double(rahmen.width) / b, height: Double(rahmen.height) / h), sicherheit: 1)
    }

    /// Würfel eines Wurfs sind etwa gleich groß: Ab drei Funden fallen die weg, deren Kante um mehr als das Doppelte vom Median abweicht.
    /// Bewusst großzügig: Überwiegen einmal die Fehlfunde, darf der echte Würfel nicht herausfallen.
    static func gleichGross(_ funde: [Fund]) -> [Fund] {
        guard funde.count >= 3 else { return funde }
        let kanten = funde.map { Double(max($0.rahmen.width, $0.rahmen.height)) }.sorted()
        let median = kanten[kanten.count / 2]
        return funde.filter { let k = Double(max($0.rahmen.width, $0.rahmen.height)); return k >= 0.45 * median && k <= 2.2 * median }
    }

    /// Quadrate entlang der langen Seite, je etwa zur Hälfte überlappend (9:16 ergibt drei).
    static func kacheln(breite b: Double, hoehe h: Double) -> [CGRect] {
        let s = min(b, h), lang = max(b, h)
        if lang <= 1.12 * s { return [CGRect(x: (b - s) / 2, y: (h - s) / 2, width: s, height: s)] }
        let n = max(2, Int(((lang - s) / (0.5 * s)).rounded(.up)) + 1)
        return (0..<n).map { i in
            let o = (lang - s) * Double(i) / Double(n - 1)
            return b >= h ? CGRect(x: o, y: 0, width: s, height: s) : CGRect(x: 0, y: o, width: s, height: s)
        }
    }

    /// Bildausschnitt als Quadrat der Kante `kante` (Bildkoordinaten, Ursprung oben links); was über den Bildrand ragt, wird grau.
    /// Gezeichnet wird nur der Teil im Bild (vorher ausgeschnitten): Bei 1080p muss so nicht das ganze Bild skaliert werden.
    static func quadrat(_ bild: CGImage, _ r: CGRect, kante: Int) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: kante, height: kante, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        ctx.setFillColor(CGColor(gray: 0.5, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: kante, height: kante))
        ctx.interpolationQuality = .high
        guard r.width > 0, r.height > 0 else { return ctx.makeImage() }
        let fx = Double(kante) / Double(r.width), fy = Double(kante) / Double(r.height)
        let voll = CGRect(x: 0, y: 0, width: bild.width, height: bild.height)
        let innen = r.intersection(voll).integral.intersection(voll)
        if !innen.isNull, innen.width >= 1, innen.height >= 1, let teil = bild.cropping(to: innen) {
            // Bildzeile y landet im Kontext (Ursprung unten links) bei (r.maxY − y) · fy.
            ctx.draw(teil, in: CGRect(x: (Double(innen.minX) - Double(r.minX)) * fx, y: (Double(r.maxY) - Double(innen.maxY)) * fy,
                                      width: Double(innen.width) * fx, height: Double(innen.height) * fy))
        } else {
            ctx.draw(bild, in: CGRect(x: -Double(r.minX) * fx, y: -(Double(bild.height) - Double(r.maxY)) * fy, width: Double(bild.width) * fx, height: Double(bild.height) * fy))
        }
        return ctx.makeImage()
    }

    private static func ausgabe(_ modell: MLModel, _ bild: CGImage, kante: Int, name: String) throws -> MLShapedArray<Float> {
        let wert = try MLFeatureValue(cgImage: bild, pixelsWide: kante, pixelsHigh: kante, pixelFormatType: kCVPixelFormatType_32BGRA, options: nil)
        let aus = try modell.prediction(from: MLDictionaryFeatureProvider(dictionary: ["bild": wert]))
        guard let feld = aus.featureValue(for: name)?.multiArrayValue else { return MLShapedArray<Float>(scalars: [], shape: [0]) }
        return MLShapedArray<Float>(converting: feld)
    }

    /// Würfel in einem quadratischen Ausschnitt suchen (ohne Augenzahl).
    /// `spuren`: verfolgte Würfel (Pixel); dort genügt `verfolgtSchwelle`.
    private func suche(_ bild: CGImage, ausschnitt: CGRect, schwelle: Float? = nil, spuren: [CGRect] = []) throws -> [Fund] {
        let normal = schwelle ?? self.schwelle
        let schwelle = spuren.isEmpty ? normal : min(normal, verfolgtSchwelle)
        let r = ausschnitt.integral
        guard let teil = Self.quadrat(bild, r, kante: finderKante) else { return [] }
        let karte = try Self.ausgabe(finder, teil, kante: finderKante, name: "karte")
        let k = finderKante / Self.schritt
        guard karte.scalarCount == 3 * k * k else { return [] }
        let b = Double(bild.width), h = Double(bild.height), seite = Double(r.width)
        var funde: [Fund] = []
        karte.withUnsafeShapedBufferPointer { p, _, _ in
            for y in 0..<k { for x in 0..<k {
                let i = y * k + x
                guard p[i] >= schwelle else { continue }
                // Nur die Spitze zählt: kein Nachbar ist sicherer (bei Gleichstand gewinnt der frühere).
                var spitze = true
                for dy in -1...1 where spitze { for dx in -1...1 where dx != 0 || dy != 0 {
                    let nx = x + dx, ny = y + dy
                    guard nx >= 0, ny >= 0, nx < k, ny < k else { continue }
                    let n = p[ny * k + nx]
                    if n > p[i] || (n == p[i] && (dy < 0 || (dy == 0 && dx < 0))) { spitze = false; break }
                } }
                guard spitze else { continue }
                let breite = Double(p[k * k + i]) * seite, hoehe = Double(p[2 * k * k + i]) * seite
                guard breite > 4, hoehe > 4 else { continue }
                let cx = Double(r.minX) + (Double(x) + 0.5) / Double(k) * seite, cy = Double(r.minY) + (Double(y) + 0.5) / Double(k) * seite
                let rahmen = CGRect(x: cx - breite / 2, y: cy - hoehe / 2, width: breite, height: hoehe)
                // Würfel, die an einer Schnittkante der Kachel liegen (nicht am Bildrand), sind angeschnitten: die Nachbarkachel sieht sie ganz.
                let rand = 0.012 * seite
                let angeschnitten = (Double(rahmen.minX) < Double(r.minX) + rand && Double(r.minX) > 1) || (Double(rahmen.maxX) > Double(r.maxX) - rand && Double(r.maxX) < b - 1)
                    || (Double(rahmen.minY) < Double(r.minY) + rand && Double(r.minY) > 1) || (Double(rahmen.maxY) > Double(r.maxY) - rand && Double(r.maxY) < h - 1)
                guard !angeschnitten else { continue }
                // Unter der normalen Schwelle nur, wo schon ein Würfel verfolgt wird.
                if p[i] >= normal || Self.verfolgt(rahmen, in: spuren) { funde.append(Fund(augen: 0, rahmen: rahmen, sicherheit: p[i])) }
            } }
        }
        return funde
    }

    /// Augenzahl eines Fundes; `nil`, wenn das Augen-Netz dort keinen Würfel sieht.
    private func lies(_ bild: CGImage, rahmen: CGRect, schwelle: Float? = nil) throws -> (Int, Float)? {
        let s = Double(max(rahmen.width, rahmen.height)) * 1.15
        let r = CGRect(x: Double(rahmen.midX) - s / 2, y: Double(rahmen.midY) - s / 2, width: s, height: s)
        guard let teil = Self.quadrat(bild, r, kante: augenKante) else { return nil }
        let p = try Self.ausgabe(augen, teil, kante: augenKante, name: "augen").scalars
        guard p.count == 7, let bester = p.indices.max(by: { p[$0] < p[$1] }), bester != 0, p[bester] >= (schwelle ?? augenSchwelle) else { return nil }
        return (bester, p[bester])
    }

    /// Derselbe Würfel aus mehreren Kacheln: der sicherste Fund bleibt.
    static func ohneDoppelte(_ liste: [Fund]) -> [Fund] {
        var behalten: [Fund] = []
        for f in liste.sorted(by: { $0.sicherheit > $1.sicherheit }) {
            let doppelt = behalten.contains { g in
                let s = g.rahmen.intersection(f.rahmen)
                guard !s.isNull else { return false }
                let schnitt = Double(s.width * s.height)
                return schnitt > 0.45 * Double(min(g.rahmen.width * g.rahmen.height, f.rahmen.width * f.rahmen.height))
            }
            if !doppelt { behalten.append(f) }
        }
        return behalten
    }
}

/// Die Erkennung, die Kamera-Seite und Foto-Scan verwenden: das trainierte Modell; lässt es sich nicht laden, die bisherige Flecken-Suche.
public enum StandardErkennung {
    public static let aktuell: WuerfelErkennung = ModellWuerfelErkennung() ?? KombinierteErkennung()

    /// „Mit Kamera lesen“ (Foto-Scan aus `WuerfelScan`, z. B. in Yacht) nutzt dieselbe Erkennung wie die Live-Seite.
    public static func fuerFotoScanEinsetzen() {
        #if canImport(UIKit)
        WuerfelKamera.leser = { bild in ((try? aktuell.erkenne(in: bild)) ?? []).map(\.augen) }
        WuerfelKamera.seite = { erwartet, hoechstens, fertig in AnyView(LiveWuerfelVollbild(erwartet: erwartet, hoechstens: hoechstens, fertig: fertig)) }
        #endif
    }
}
