// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import CoreGraphics
import XCTest
@testable import WuerfelScan

/// Zeichnet Würfel als Bild (wie ein Foto von oben) und prüft, ob die Augen richtig gelesen werden.
final class ErkennungTests: XCTestCase {
    private static let raster: [Int: [(Double, Double)]] = [
        1: [(0.5, 0.5)],
        2: [(0.25, 0.25), (0.75, 0.75)],
        3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
        4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
        5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
        6: [(0.25, 0.22), (0.75, 0.22), (0.25, 0.5), (0.75, 0.5), (0.25, 0.78), (0.75, 0.78)],
    ]

    private func bild(_ werte: [Int], hellerWuerfel: Bool, groesse: CGFloat = 110) -> CGImage {
        let b = 640, h = 480
        let ctx = CGContext(data: nil, width: b, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let tisch: CGFloat = hellerWuerfel ? 0.18 : 0.88
        ctx.setFillColor(CGColor(red: tisch, green: tisch + 0.05, blue: tisch, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: b, height: h))
        for (i, n) in werte.enumerated() {
            let x = 40 + CGFloat(i % 4) * 150, y = 300 - CGFloat(i / 4) * 160
            let r = CGRect(x: x, y: y, width: groesse, height: groesse)
            ctx.setFillColor(CGColor(gray: hellerWuerfel ? 0.96 : 0.1, alpha: 1))
            ctx.addPath(CGPath(roundedRect: r, cornerWidth: 12, cornerHeight: 12, transform: nil)); ctx.fillPath()
            ctx.setFillColor(CGColor(gray: hellerWuerfel ? 0.08 : 0.95, alpha: 1))
            for (px, py) in Self.raster[n]! {
                let d = groesse * 0.17
                ctx.fillEllipse(in: CGRect(x: r.minX + px * groesse - d / 2, y: r.minY + py * groesse - d / 2, width: d, height: d))
            }
        }
        return ctx.makeImage()!
    }

    func testHelleWuerfelAufDunklemTisch() throws {
        let e = try WuerfelErkenner.erkenne(in: bild([3, 6, 1, 5, 2], hellerWuerfel: true))
        XCTAssertEqual(Set(e.augen), [1, 2, 3, 5, 6])
        XCTAssertEqual(e.augen.count, 5)
    }

    func testReihenfolgeLinksNachRechtsUndObenNachUnten() throws {
        let e = try WuerfelErkenner.erkenne(in: bild([4, 1, 6, 2, 5], hellerWuerfel: true))
        XCTAssertEqual(e.augen, [4, 1, 6, 2, 5])
    }

    func testDunkleWuerfelMitHellenAugen() throws {
        let e = try WuerfelErkenner.erkenne(in: bild([2, 4, 6], hellerWuerfel: false))
        XCTAssertEqual(e.augen, [2, 4, 6])
    }

    func testAlleSechsAugenzahlen() throws {
        let e = try WuerfelErkenner.erkenne(in: bild([1, 2, 3, 4, 5, 6], hellerWuerfel: true, groesse: 100))
        XCTAssertEqual(e.augen, [1, 2, 3, 4, 5, 6])
    }

    func testLeererTischLiefertNichts() throws {
        let e = try WuerfelErkenner.erkenne(in: bild([], hellerWuerfel: true))
        XCTAssertTrue(e.wuerfel.isEmpty)
    }
}
