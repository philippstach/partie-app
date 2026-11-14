// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import CoreGraphics
@testable import WuerfelLive

/// Synthetische Bilder in verschiedenen Farben. Prüft die Flecken-Erkennung (rot, weiß auf weiß, beige, schräg, mehrere Würfel).
final class BlobTests: XCTestCase {
    static let muster: [Int: [(Double, Double)]] = [
        1: [(0.5, 0.5)], 2: [(0.25, 0.25), (0.75, 0.75)], 3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
        4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
        5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
        6: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.5), (0.75, 0.5), (0.25, 0.75), (0.75, 0.75)],
    ]
    typealias Farbe = (Double, Double, Double)

    func bild(_ werte: [Int], tisch: Farbe, wuerfel: Farbe, auge: Farbe, seite: Double = 120, abstand: Double = 190,
              kante: Farbe? = nil, rauschen: Double = 0) -> CGImage {
        let b = 720, h = 480
        let ctx = CGContext(data: nil, width: b, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        func f(_ c: Farbe) { ctx.setFillColor(CGColor(red: c.0, green: c.1, blue: c.2, alpha: 1)) }
        f(tisch); ctx.fill(CGRect(x: 0, y: 0, width: b, height: h))
        for (i, wert) in werte.enumerated() {
            let x0 = 60.0 + Double(i) * abstand, y0 = 170.0
            if let k = kante { f(k); ctx.fill(CGRect(x: x0 - 3, y: y0 - 3, width: seite + 6, height: seite + 6)) }
            f(wuerfel); ctx.fill(CGRect(x: x0, y: y0, width: seite, height: seite))
            f(auge)
            let pip = seite * 0.19
            for (px, py) in Self.muster[wert]! {
                ctx.fillEllipse(in: CGRect(x: x0 + px * seite - pip / 2, y: y0 + py * seite - pip / 2, width: pip, height: pip))
            }
        }
        if rauschen > 0 {
            var gen = SystemRandomNumberGenerator()
            for _ in 0..<400 {
                ctx.setFillColor(CGColor(gray: Double.random(in: 0.4...0.6, using: &gen), alpha: rauschen))
                ctx.fill(CGRect(x: Double.random(in: 0..<Double(b), using: &gen), y: Double.random(in: 0..<Double(h), using: &gen), width: 2, height: 2))
            }
        }
        return ctx.makeImage()!
    }

    private func augen(_ b: CGImage) throws -> [Int] { try BlobWuerfelErkennung().erkenne(in: b).map(\.augen) }

    func testRoteWuerfelMitWeissenAugen() throws {
        let b = bild([1, 4, 6], tisch: (0.55, 0.55, 0.55), wuerfel: (0.8, 0.1, 0.1), auge: (1, 1, 1))
        XCTAssertEqual(try augen(b), [1, 4, 6])
    }

    func testWeisserWuerfelAufWeissemTisch() throws {
        let b = bild([2, 5, 3], tisch: (0.93, 0.93, 0.93), wuerfel: (0.98, 0.98, 0.98), auge: (0.15, 0.15, 0.15), kante: (0.85, 0.85, 0.85))
        XCTAssertEqual(try augen(b), [2, 5, 3])
    }

    func testBeigeWuerfelAufWeissemTischOhneKante() throws {
        let b = bild([6, 1], tisch: (0.97, 0.97, 0.97), wuerfel: (0.93, 0.89, 0.78), auge: (0.2, 0.15, 0.1))
        XCTAssertEqual(try augen(b), [6, 1])
    }

    func testBlauerWuerfelUndGelbeAugen() throws {
        let b = bild([3, 5], tisch: (0.4, 0.3, 0.2), wuerfel: (0.1, 0.2, 0.7), auge: (1, 0.9, 0.2))
        XCTAssertEqual(try augen(b), [3, 5])
    }

    func testSchwarzerWuerfelWeisseAugen() throws {
        let b = bild([4, 2], tisch: (0.9, 0.9, 0.9), wuerfel: (0.1, 0.1, 0.1), auge: (1, 1, 1))
        XCTAssertEqual(try augen(b), [4, 2])
    }

    func testKleineWuerfelWeiterWeg() throws {
        let b = bild([5, 6, 1, 3], tisch: (0.6, 0.6, 0.6), wuerfel: (0.85, 0.15, 0.15), auge: (1, 1, 1), seite: 70, abstand: 150)
        XCTAssertEqual(try augen(b), [5, 6, 1, 3])
    }

    /// Kamerabild im Hochformat (720 × 1280) mit Würfeln der Kantenlänge `seite` in zwei Reihen.
    private func hochformat(_ werte: [Int], seite: Double) -> CGImage {
        let b = 720, h = 1280
        let ctx = CGContext(data: nil, width: b, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(gray: 0.55, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: b, height: h))
        let pip = seite * 0.19
        for (i, wert) in werte.enumerated() {
            let x0 = 40.0 + Double(i % 3) * seite * 2.2, y0 = 700.0 - Double(i / 3) * seite * 2.4
            ctx.setFillColor(CGColor(red: 0.85, green: 0.15, blue: 0.15, alpha: 1)); ctx.fill(CGRect(x: x0, y: y0, width: seite, height: seite))
            ctx.setFillColor(CGColor(gray: 1, alpha: 1))
            for (px, py) in Self.muster[wert]! { ctx.fillEllipse(in: CGRect(x: x0 + px * seite - pip / 2, y: y0 + py * seite - pip / 2, width: pip, height: pip)) }
        }
        return ctx.makeImage()!
    }

    func testWuerfelVonWinzigBisNah() throws {
        // Kante von 3,6 % (weit herausgezoomt) bis 17 % der Bildbreite.
        for seite in [26.0, 30, 36, 44, 60, 90, 120] {
            XCTAssertEqual(try augen(hochformat([5, 6, 1, 3, 4, 2], seite: seite)), [5, 6, 1, 3, 4, 2], "Kante \(seite)")
        }
        // Nahaufnahme: Kante 28 % und 42 % der Bildbreite.
        XCTAssertEqual(try augen(hochformat([5, 6], seite: 200)), [5, 6])
        XCTAssertEqual(try augen(hochformat([6], seite: 300)), [6])
    }

    /// Die Flecken-Suche zählt Pixel in Swift-Schleifen. Ohne Optimierung (Debug-Bau, `swift test` ohne `-c release`)
    /// sind die 10- bis 50-mal langsamer, die Grenze sagt dann nichts. Gemessen wird nur im optimierten Bau.
    /// Die Live-Kamera nutzt seit Version 5 das Modell, die Flecken-Suche nur noch als Rückfall.
    func testRechenzeitReichtFuerZehnAuswertungenProSekunde() throws {
        #if DEBUG
        throw XCTSkip("Rechenzeit nur im optimierten Bau aussagekräftig (swift test -c release)")
        #endif
        let b = hochformat([5, 6, 1, 3, 4, 2], seite: 60)
        let start = Date()
        for _ in 0..<5 { _ = try BlobWuerfelErkennung().erkenne(in: b) }
        XCTAssertLessThan(Date().timeIntervalSince(start) / 5, 0.08)
    }

    func testLeererTischUndRauschen() throws {
        XCTAssertTrue(try augen(bild([], tisch: (0.9, 0.9, 0.9), wuerfel: (0, 0, 0), auge: (0, 0, 0), rauschen: 0.5)).isEmpty)
    }

    func testRahmenSitztUmDenWuerfel() throws {
        let e = try BlobWuerfelErkennung().erkenne(in: bild([4], tisch: (0.5, 0.5, 0.5), wuerfel: (0.8, 0.1, 0.1), auge: (1, 1, 1)))
        let r = try XCTUnwrap(e.first).rahmen
        // Würfel: x 60…180 von 720, y 170…290 von 480 (Ursprung unten) → oben links 190…310
        XCTAssertEqual(Double(r.midX), 120.0 / 720, accuracy: 0.03)
        XCTAssertEqual(Double(r.midY), 250.0 / 480, accuracy: 0.04)
        XCTAssertEqual(Double(r.width), 120.0 / 720, accuracy: 0.05)
    }

    func testKombiniertFaelltAufVisionZurueck() throws {
        let b = bild([2, 5], tisch: (0.12, 0.12, 0.12), wuerfel: (0.95, 0.95, 0.95), auge: (0.05, 0.05, 0.05))
        XCTAssertEqual(try KombinierteErkennung().erkenne(in: b).map(\.augen), [2, 5])
    }
}
