// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import CoreGraphics
@testable import WuerfelLive

/// Synthetische Bilder: weiße Würfel mit schwarzen Augen auf dunklem Tisch. Prüft die Kette Bild → Protokoll → Stabilisierer.
final class ErkennungTests: XCTestCase {
    private static let muster: [Int: [(Double, Double)]] = [
        1: [(0.5, 0.5)], 2: [(0.25, 0.25), (0.75, 0.75)], 3: [(0.25, 0.25), (0.5, 0.5), (0.75, 0.75)],
        4: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)],
        5: [(0.25, 0.25), (0.75, 0.25), (0.5, 0.5), (0.25, 0.75), (0.75, 0.75)],
        6: [(0.25, 0.25), (0.75, 0.25), (0.25, 0.5), (0.75, 0.5), (0.25, 0.75), (0.75, 0.75)],
    ]

    private func bild(_ werte: [Int]) -> CGImage {
        let b = 640, h = 480, seite = 120.0
        let ctx = CGContext(data: nil, width: b, height: h, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setFillColor(CGColor(gray: 0.12, alpha: 1)); ctx.fill(CGRect(x: 0, y: 0, width: b, height: h))
        for (i, wert) in werte.enumerated() {
            let x0 = 60.0 + Double(i) * 190, y0 = 180.0
            ctx.setFillColor(CGColor(gray: 0.95, alpha: 1)); ctx.fill(CGRect(x: x0, y: y0, width: seite, height: seite))
            ctx.setFillColor(CGColor(gray: 0.05, alpha: 1))
            for (px, py) in Self.muster[wert]! {
                ctx.fillEllipse(in: CGRect(x: x0 + px * seite - 11, y: y0 + py * seite - 11, width: 22, height: 22))
            }
        }
        return ctx.makeImage()!
    }

    func testErkennungLiefertWerteInLesereihenfolge() throws {
        let r = try VisionWuerfelErkennung().erkenne(in: bild([2, 5, 6]))
        XCTAssertEqual(r.map(\.augen), [2, 5, 6])
    }

    func testLeererTischLiefertNichts() throws {
        XCTAssertTrue(try VisionWuerfelErkennung().erkenne(in: bild([])).isEmpty)
    }

    func testKetteBildBisSicher() throws {
        var s = WuerfelVerfolger()
        let erk = VisionWuerfelErkennung()
        var a: [AngezeigterWuerfel] = []
        for _ in 1...5 { a = s.verarbeite(try erk.erkenne(in: bild([3, 4]))) }
        XCTAssertEqual(a.map(\.augen), [3, 4])
        XCTAssertTrue(a.allesSicher)
        XCTAssertEqual(a.summe, 7)
    }
}
