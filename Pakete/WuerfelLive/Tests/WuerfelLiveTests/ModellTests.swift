// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import CoreGraphics
@testable import WuerfelLive

/// Zerlegung des Kamerabilds in Quadrate und Zusammenführen der Funde (ohne Modell prüfbar).
final class ModellTests: XCTestCase {
    func testQuadratischesBildIstEineKachel() {
        XCTAssertEqual(ModellWuerfelErkennung.kacheln(breite: 640, hoehe: 640), [CGRect(x: 0, y: 0, width: 640, height: 640)])
    }

    func testHochformatErgibtDreiUeberlappendeQuadrate() {
        let k = ModellWuerfelErkennung.kacheln(breite: 720, hoehe: 1280)
        XCTAssertEqual(k.count, 3)
        XCTAssertEqual(k.first, CGRect(x: 0, y: 0, width: 720, height: 720))
        XCTAssertEqual(k.last, CGRect(x: 0, y: 560, width: 720, height: 720))
        // Jeder Würfel bis zur halben Kachelbreite liegt in mindestens einer Kachel ganz.
        for (a, b) in zip(k, k.dropFirst()) { XCTAssertGreaterThanOrEqual(a.maxY - b.minY, 360) }
    }

    func testQuerformatKacheltEntlangDerBreite() {
        let k = ModellWuerfelErkennung.kacheln(breite: 1280, hoehe: 720)
        XCTAssertEqual(k.count, 3)
        XCTAssertTrue(k.allSatisfy { $0.minY == 0 && $0.width == 720 && $0.height == 720 })
    }

    func testDerselbeWuerfelAusZweiKachelnBleibtEinmal() {
        typealias F = ModellWuerfelErkennung.Fund
        let funde = [F(augen: 5, rahmen: CGRect(x: 100, y: 500, width: 80, height: 80), sicherheit: 0.6),
                     F(augen: 3, rahmen: CGRect(x: 104, y: 498, width: 78, height: 82), sicherheit: 0.9),
                     F(augen: 2, rahmen: CGRect(x: 300, y: 500, width: 80, height: 80), sicherheit: 0.5)]
        let rest = ModellWuerfelErkennung.ohneDoppelte(funde)
        XCTAssertEqual(rest.map(\.augen).sorted(), [2, 3])
    }

    func testBeruehrendeWuerfelBleibenGetrennt() {
        typealias F = ModellWuerfelErkennung.Fund
        let funde = [F(augen: 1, rahmen: CGRect(x: 100, y: 100, width: 80, height: 80), sicherheit: 0.8),
                     F(augen: 6, rahmen: CGRect(x: 172, y: 100, width: 80, height: 80), sicherheit: 0.7)]
        XCTAssertEqual(ModellWuerfelErkennung.ohneDoppelte(funde).count, 2)
    }

    func testAusreisserInDerGroesseFallenWeg() {
        typealias F = ModellWuerfelErkennung.Fund
        var funde = (0..<5).map { F(augen: 3, rahmen: CGRect(x: 100 * Double($0), y: 100, width: 60 + Double($0), height: 60), sicherheit: 0.8) }
        funde.append(F(augen: 1, rahmen: CGRect(x: 0, y: 400, width: 200, height: 190), sicherheit: 0.6))   // großer Aufdruck
        funde.append(F(augen: 1, rahmen: CGRect(x: 300, y: 400, width: 20, height: 22), sicherheit: 0.6))    // kleiner Fleck
        XCTAssertEqual(ModellWuerfelErkennung.gleichGross(funde).count, 5)
        // Zwei Funde reichen nicht für ein Urteil.
        XCTAssertEqual(ModellWuerfelErkennung.gleichGross(Array(funde.suffix(2))).count, 2)
    }

    func testNurDieSicherstenBleibenBeiZuVielenFunden() {
        let r = CGRect(x: 0, y: 0, width: 0.1, height: 0.1)
        let liste = [0.9, 0.3, 0.8, 0.95, 0.4, 0.7, 0.85].enumerated().map { GesehenerWuerfel(augen: $0.offset % 6 + 1, rahmen: r, sicherheit: $0.element) }
        let rest = GesehenerWuerfel.dieSichersten(liste, hoechstens: 5)
        XCTAssertEqual(rest.map(\.sicherheit), [0.9, 0.8, 0.95, 0.7, 0.85])   // Reihenfolge bleibt, die zwei unsichersten fallen weg
        XCTAssertEqual(GesehenerWuerfel.dieSichersten(liste, hoechstens: nil).count, 7)
        XCTAssertEqual(GesehenerWuerfel.dieSichersten(Array(liste.prefix(3)), hoechstens: 5).count, 3)
    }

    /// Die mitgelieferten Netze laden und lesen ein gezeichnetes Würfelbild (schwarze Augen auf Weiß, grauer Tisch).
    func testMitgelieferteNetzeLesenEinenWuerfel() throws {
        let erkennung = try XCTUnwrap(ModellWuerfelErkennung(), "Modelle fehlen im Paket")
        let n = 640
        let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(gray: 0.45, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n))
        func wuerfel(_ x: Double, _ y: Double, _ augen: [(Double, Double)]) {
            let s = 110.0
            ctx.setFillColor(CGColor(gray: 0.95, alpha: 1)); ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: s, height: s), cornerWidth: 14, cornerHeight: 14, transform: nil)); ctx.fillPath()
            ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
            for (px, py) in augen { ctx.fillEllipse(in: CGRect(x: x + px * s - 11, y: y + py * s - 11, width: 22, height: 22)) }
        }
        wuerfel(120, 260, [(0.27, 0.27), (0.73, 0.27), (0.5, 0.5), (0.27, 0.73), (0.73, 0.73)])
        wuerfel(400, 260, [(0.27, 0.27), (0.73, 0.73)])
        let funde = try erkennung.erkenne(in: ctx.makeImage()!)
        XCTAssertEqual(funde.map(\.augen), [5, 2])
    }

    /// Nahprüfung: Der angetippte Würfel wird gefunden und gelesen, eine leere Stelle liefert nichts.
    func testNahpruefungFindetAngetippteWuerfelUndLeereStelleNichts() throws {
        let erkennung = try XCTUnwrap(ModellWuerfelErkennung(), "Modelle fehlen im Paket")
        let n = 640
        let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(gray: 0.45, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: n, height: n))
        let s = 110.0, x = 400.0, y = 260.0
        ctx.setFillColor(CGColor(gray: 0.95, alpha: 1)); ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: s, height: s), cornerWidth: 14, cornerHeight: 14, transform: nil)); ctx.fillPath()
        ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
        for (px, py) in [(0.27, 0.27), (0.73, 0.73)] { ctx.fillEllipse(in: CGRect(x: x + px * s - 11, y: y + py * s - 11, width: 22, height: 22)) }
        let bild = ctx.makeImage()!
        let w = try XCTUnwrap(try erkennung.erkenneNah(in: bild, um: CGPoint(x: (x + s / 2 + 12) / Double(n), y: (y + s / 2 - 9) / Double(n)), ueblicheKante: nil))
        XCTAssertEqual(w.augen, 2)
        XCTAssertEqual(Double(w.rahmen.midX), (x + s / 2) / Double(n), accuracy: 0.05)
        XCTAssertNil(try erkennung.erkenneNah(in: bild, um: CGPoint(x: 0.1, y: 0.1), ueblicheKante: 0.17))
    }

    func testAmNaechstenWaehltDenFundUnterDemFinger() {
        typealias F = ModellWuerfelErkennung.Fund
        let a = F(augen: 0, rahmen: CGRect(x: 100, y: 100, width: 50, height: 50), sicherheit: 0.2)
        let b = F(augen: 0, rahmen: CGRect(x: 300, y: 100, width: 50, height: 50), sicherheit: 0.9)
        XCTAssertEqual(ModellWuerfelErkennung.amNaechsten([a, b], zu: CGPoint(x: 118, y: 120))?.rahmen, a.rahmen)
        XCTAssertNil(ModellWuerfelErkennung.amNaechsten([a, b], zu: CGPoint(x: 220, y: 300)))
    }

    // MARK: W4 Tempo

    func testSuchQuadratUmschliesstAlleSpurenMitRand() throws {
        let spuren = [CGRect(x: 300, y: 900, width: 80, height: 80), CGRect(x: 500, y: 950, width: 80, height: 80)]
        let q = try XCTUnwrap(ModellWuerfelErkennung.suchQuadrat(um: spuren, breite: 1080, hoehe: 1920))
        XCTAssertEqual(q.width, q.height)
        for s in spuren { XCTAssertTrue(q.insetBy(dx: 80, dy: 80).contains(s), "mindestens eine Kante Rand") }
        XCTAssertGreaterThanOrEqual(q.width, 5 * 80)
        XCTAssertTrue(CGRect(x: 0, y: 0, width: 1080, height: 1920).contains(q))
    }

    func testSuchQuadratAmBildrandBleibtImBild() throws {
        let q = try XCTUnwrap(ModellWuerfelErkennung.suchQuadrat(um: [CGRect(x: 5, y: 10, width: 60, height: 60)], breite: 1080, hoehe: 1920))
        XCTAssertEqual(q.minX, 0); XCTAssertEqual(q.minY, 0)
    }

    func testWeitVerteilteWuerfelSuchenDasGanzeBild() {
        XCTAssertNil(ModellWuerfelErkennung.suchQuadrat(um: [], breite: 1080, hoehe: 1920))
        let weit = [CGRect(x: 50, y: 300, width: 90, height: 90), CGRect(x: 940, y: 1500, width: 90, height: 90)]
        XCTAssertNil(ModellWuerfelErkennung.suchQuadrat(um: weit, breite: 1080, hoehe: 1920))
    }

    func testVerfolgtErkenntDieselbeStelle() {
        let spur = [CGRect(x: 100, y: 100, width: 80, height: 80)]
        XCTAssertTrue(ModellWuerfelErkennung.verfolgt(CGRect(x: 110, y: 95, width: 84, height: 78), in: spur))
        XCTAssertFalse(ModellWuerfelErkennung.verfolgt(CGRect(x: 200, y: 100, width: 80, height: 80), in: spur), "zu weit weg")
        XCTAssertFalse(ModellWuerfelErkennung.verfolgt(CGRect(x: 120, y: 120, width: 20, height: 20), in: spur), "viel kleiner")
        XCTAssertFalse(ModellWuerfelErkennung.verfolgt(CGRect(x: 100, y: 100, width: 80, height: 80), in: []))
    }

    /// Der Ausschnitt über das ausgeschnittene Teilbild sieht aus wie vorher über das ganze Bild (auch über den Rand hinaus).
    func testQuadratAusschnittStimmtMitGanzemBildUeberein() throws {
        let w = 300, h = 500
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(red: 0, green: 0, blue: 1, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        // Rotes Feld oben links im Bild (Bildkoordinaten x 20…60, y 30…70; im Kontext liegt y = 0 unten).
        ctx.setFillColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1)); ctx.fill(CGRect(x: 20, y: h - 70, width: 40, height: 40))
        let bild = ctx.makeImage()!
        // Ausschnitt ragt links und oben über das Bild: x −20…80, y −10…90.
        let teil = try XCTUnwrap(ModellWuerfelErkennung.quadrat(bild, CGRect(x: -20, y: -10, width: 100, height: 100), kante: 100))
        func farbe(_ x: Int, _ y: Int) -> (Int, Int, Int) {
            var px = [UInt8](repeating: 0, count: 4)
            let c = CGContext(data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
            c.draw(teil, in: CGRect(x: -x, y: -(teil.height - 1 - y), width: teil.width, height: teil.height))
            return (Int(px[0]), Int(px[1]), Int(px[2]))
        }
        XCTAssertGreaterThan(farbe(60, 50).0, 200, "rotes Feld bei Bild (40, 40) → Ausschnitt (60, 50)")
        XCTAssertGreaterThan(farbe(95, 95).2, 200, "Blau im Bild")
        let rand = farbe(5, 50)
        XCTAssertTrue(abs(rand.0 - 128) < 20 && abs(rand.2 - 128) < 20, "grau außerhalb des Bildes")
    }

    func testEingangsgroesseKommtAusDemModell() throws {
        let erkennung = try XCTUnwrap(ModellWuerfelErkennung(), "Modelle fehlen im Paket")
        XCTAssertEqual(erkennung.finderKante, 448)
        XCTAssertEqual(erkennung.augenKante, 64)
    }

    /// Mit verfolgten Würfeln findet die Bereichssuche dasselbe wie die Suche im ganzen Bild.
    func testBereichssucheFindetDieVerfolgtenWuerfel() throws {
        let erkennung = try XCTUnwrap(ModellWuerfelErkennung(), "Modelle fehlen im Paket")
        let w = 1080, h = 1920   // wie die Kamera in 1080p
        let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(gray: 0.45, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        func wuerfel(_ x: Double, _ y: Double, _ augen: [(Double, Double)]) {
            let s = 120.0
            ctx.setFillColor(CGColor(gray: 0.95, alpha: 1)); ctx.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: s, height: s), cornerWidth: 20, cornerHeight: 20, transform: nil)); ctx.fillPath()
            ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
            for (px, py) in augen { ctx.fillEllipse(in: CGRect(x: x + px * s - 12, y: y + py * s - 12, width: 24, height: 24)) }
        }
        // Zwei Würfel nah beieinander: Das Suchquadrat (rund 860 Pixel) ist kleiner als die Bildbreite, es wird wirklich nur der Bereich abgesucht.
        // Abstand so, dass das Suchquadrat (Spannweite + 3 Kanten) unter 85 % der kurzen Bildseite bleibt, auch wenn die Rahmen etwas größer ausfallen.
        wuerfel(300, 900, [(0.27, 0.27), (0.73, 0.27), (0.5, 0.5), (0.27, 0.73), (0.73, 0.73)])
        wuerfel(450, 900, [(0.27, 0.27), (0.73, 0.73)])
        let bild = ctx.makeImage()!
        let ganz = try erkennung.erkenne(in: bild)
        XCTAssertEqual(ganz.map(\.augen), [5, 2])
        XCTAssertNotNil(ModellWuerfelErkennung.suchQuadrat(um: ganz.map { CGRect(x: $0.rahmen.minX * 1080, y: $0.rahmen.minY * 1920, width: $0.rahmen.width * 1080, height: $0.rahmen.height * 1920) }, breite: 1080, hoehe: 1920))
        let bereich = try erkennung.erkenne(in: bild, verfolgt: ganz.map(\.rahmen), ganzesBild: false)
        XCTAssertEqual(bereich.map(\.augen), [5, 2])
        for (a, b) in zip(ganz, bereich) { XCTAssertEqual(Double(a.rahmen.midX), Double(b.rahmen.midX), accuracy: 0.03) }
    }
}
