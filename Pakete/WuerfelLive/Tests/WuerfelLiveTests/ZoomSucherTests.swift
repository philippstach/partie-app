// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import WuerfelLive

final class ZoomSucherTests: XCTestCase {
    func testEineStufeSchaltetNie() {
        var z = ZoomSucher(stufen: 1, start: 0)
        for _ in 1...50 { XCTAssertNil(z.beobachte(punkte: 0, allesSicher: false)) }
    }

    func testSicherBleibtAufDerStufe() {
        var z = ZoomSucher(stufen: 3, start: 1)
        for _ in 1...50 { XCTAssertNil(z.beobachte(punkte: 6, allesSicher: true)) }
        XCTAssertEqual(z.aktuell, 1)
    }

    func testProbiertDannWaehltBeste() {
        var z = ZoomSucher(stufen: 3, start: 1, geduld: 4, probeLaenge: 5, einschwingen: 1)
        var wechsel: [Int] = []
        // Stufe 2 liefert gute Punkte, die anderen nichts, aber nie „alles sicher“.
        for _ in 1...80 {
            if let n = z.beobachte(punkte: z.aktuell == 2 ? 4 : 0, allesSicher: false) { wechsel.append(n) }
            if wechsel.count == 3 { break }
        }
        XCTAssertEqual(wechsel.first, 2)
        XCTAssertEqual(wechsel.last, 2, "am Ende die beste Stufe")
        XCTAssertEqual(z.aktuell, 2)
    }

    func testBleibtBeiGleichstandAufAusgang() {
        var z = ZoomSucher(stufen: 3, start: 1, geduld: 3, probeLaenge: 4, einschwingen: 1)
        var wechsel: [Int] = []
        for _ in 1...60 { if let n = z.beobachte(punkte: 1, allesSicher: false) { wechsel.append(n) }; if wechsel.count == 3 { break } }
        XCTAssertEqual(wechsel, [2, 0, 1], "alle probiert, am Ende zurück auf die Ausgangsstufe")
    }

    func testFrueherAbbruchWennSicher() {
        var z = ZoomSucher(stufen: 3, start: 0, geduld: 3, probeLaenge: 9, einschwingen: 1)
        var n = 0
        while z.aktuell == 0, n < 20 { _ = z.beobachte(punkte: 0, allesSicher: false); n += 1 }
        XCTAssertNotEqual(z.aktuell, 0)
        let probe = z.aktuell
        for _ in 1...3 { _ = z.beobachte(punkte: 6, allesSicher: true) }
        XCTAssertEqual(z.aktuell, probe)
    }
}
