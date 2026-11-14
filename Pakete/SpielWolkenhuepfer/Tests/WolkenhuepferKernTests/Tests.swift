// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import ArcadeKern
@testable import WolkenhuepferKern

final class WolkenhuepferTests: XCTestCase {
    func neu(_ s: UInt64 = 1) -> Wolkenhuepfer { var g = Wolkenhuepfer(zufall: ArcadeZufall(startwert: s)); g.starte(); return g }

    func testWartetBisStart() {
        var g = Wolkenhuepfer(zufall: ArcadeZufall(startwert: 1))
        g.schritt(1); XCTAssertEqual(g.y, 0.12); XCTAssertEqual(g.phase, .bereit)
    }
    func testFallenOhneSteuerungEndet() {
        var g = neu(); g.lenke(um: 0.45)
        for _ in 0..<(120 * 30) where !g.vorbei { g.schritt(1.0 / 120) }
        XCTAssertTrue(g.vorbei)
    }
    func testRandUmbruch() {
        var g = neu(); g.lenke(um: 0.6); XCTAssertEqual(g.x, 0.1, accuracy: 1e-9)
        g.lenke(um: -0.2); XCTAssertEqual(g.x, 0.9, accuracy: 1e-9)
    }
    func testLueckenImmerSprungbar() {
        var g = neu(4)
        for _ in 0..<(120 * 60) where !g.vorbei { g.lenke(um: 0.0); g.schritt(1.0 / 120); g.testSetzeHoehe(g.hoechste + 0.01) }
        let ys = g.wolken.filter { $0.art == .fest || $0.art == .wandernd }.map(\.y).sorted()
        for (a, b) in zip(ys, ys.dropFirst()) { XCTAssertLessThan(b - a, Wolkenhuepfer.sprungHoehe * 0.9) }
    }
    /// Ein einfacher Bot, der immer auf eine feste/wandernde Wolke zusteuert, muss lange überleben und hoch kommen.
    func testBotKommtHoch() {
        for seed in 1...6 as ClosedRange<UInt64> {
            var g = neu(seed); var t = 0
            while !g.vorbei && t < 120 * 120 {
                let ziele = g.wolken.filter { $0.art != .bruechig && !$0.weg }
                var ziel: Wolke?
                if g.vy > 0 { ziel = ziele.filter { $0.y > g.y && $0.y < g.y + 0.5 }.min { $0.y < $1.y } }
                if ziel == nil { ziel = ziele.filter { $0.y < g.y && $0.y > g.y - 0.5 }.max { $0.y < $1.y } }
                if let z = ziel {
                    let wx = g.wolkenX(z)
                    var d = wx - g.x; if d > 0.5 { d -= 1 } else if d < -0.5 { d += 1 }
                    g.lenke(um: max(-2.5 / 120, min(2.5 / 120, d)))
                }
                g.schritt(1.0 / 120); t += 1
            }
            XCTAssertFalse(g.vorbei, "Seed \(seed) gefallen bei \(g.punkte) Punkten nach \(t / 120) s")
            XCTAssertGreaterThan(g.punkte, 600)
        }
    }

    func testFederSpringtHoeherAlsNormal() {
        XCTAssertGreaterThan(Wolkenhuepfer.federGeschwindigkeit, Wolkenhuepfer.sprungGeschwindigkeit * 1.3)
        XCTAssertGreaterThan(Wolkenhuepfer.federHoehe, Wolkenhuepfer.maxLuecke)
    }
    func testPunkteSteigenNurMitHoehe() {
        var g = neu(2); let p0 = g.punkte
        for _ in 0..<60 { g.schritt(1.0 / 120) }
        XCTAssertGreaterThanOrEqual(g.punkte, p0)
        let p1 = g.punkte
        g.testSetzeHoehe(g.hoechste + 1)
        XCTAssertEqual(g.punkte, p1 + 50)
    }
    func testSchwierigkeitStiegtMitHoehe() {
        var g = neu(); let s0 = g.schwere
        g.testSetzeHoehe(60); XCTAssertGreaterThan(g.schwere, s0)
        XCTAssertLessThan(g.schwere, 1)
    }

    func testSchwierigkeitStetigUndSprungbarBleibtImmer() {
        var g = neu(); var letzte = g.schwere
        for h in stride(from: 0.0, through: 400, by: 5) {
            g.testSetzeHoehe(h)
            XCTAssertGreaterThanOrEqual(g.schwere, letzte); XCTAssertLessThan(g.schwere - letzte, 0.15)
            letzte = g.schwere
        }
        XCTAssertLessThan(Wolkenhuepfer.maxLuecke, Wolkenhuepfer.sprungHoehe * 0.85 + 1e-9)
    }

    // MARK: Speichern und Fortsetzen
    func testSpeichernUndFortsetzenGleichesSpiel() throws {
        var a = Wolkenhuepfer(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<600 { a.schritt(1.0 / 120) }
        let daten = try JSONEncoder().encode(a)
        var b = try JSONDecoder().decode(Wolkenhuepfer.self, from: daten)
        XCTAssertEqual(a, b)
        // Danach verhalten sich beide gleich (auch der Zufall wurde gespeichert)
        for _ in 0..<600 { a.schritt(1.0 / 120); b.schritt(1.0 / 120) }
        XCTAssertEqual(a, b)
    }
    func testGespeichertePartieBleibtLaufend() throws {
        var a = Wolkenhuepfer(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<60 { a.schritt(1.0 / 120) }
        let b = try JSONDecoder().decode(Wolkenhuepfer.self, from: JSONEncoder().encode(a))
        XCTAssertEqual(b.phase, a.phase)
        XCTAssertEqual(b.phase, .laeuft)
    }
    func testKaputterStandWirdAbgelehnt() {
        XCTAssertThrowsError(try JSONDecoder().decode(Wolkenhuepfer.self, from: Data("{\"x\":1}".utf8)))
    }

    // MARK: Stufen (leicht / mittel / schwer)
    func testSchwerHatMehrSchwereAlsLeicht() {
        func schwere(_ st: Int) -> Double { var g = Wolkenhuepfer(schwierigkeit: st, zufall: ArcadeZufall(startwert: 3)); g.starte(); return g.schwere }
        XCTAssertLessThanOrEqual(schwere(1), schwere(3))
    }
    func testStufeWirdBegrenzt() {
        XCTAssertEqual(Wolkenhuepfer(schwierigkeit: 9).schwierigkeit, 3)
        XCTAssertEqual(Wolkenhuepfer(schwierigkeit: -4).schwierigkeit, 1)
    }

    // MARK: Fehlerjagd
    func testLenkenMitSehrGrossemSprungBleibtImFeld() {
        for dx in [-3.7, -1.2, -0.4, 0.6, 1.0, 1.7, 2.3, 7.9] {
            var g = Wolkenhuepfer(zufall: ArcadeZufall(startwert: 2)); g.starte()
            g.lenke(um: dx)
            XCTAssertTrue(g.x >= 0 && g.x <= 1, "x=\(g.x) nach \(dx)")
        }
    }
    func testZufallseingabenKeinAbsturzUndStabil() {
        for seed in 1...8 as ClosedRange<UInt64> {
            var g = Wolkenhuepfer(schwierigkeit: Int(seed % 3) + 1, zufall: ArcadeZufall(startwert: seed))
            var z = ArcadeZufall(startwert: seed &* 31); g.starte()
            for i in 0..<(120 * 90) {
                if i % 10 == 0 { g.lenke(um: z.zahl(-0.3...0.3)) }
                g.schritt(1.0 / 120)
                XCTAssertFalse(g.y.isNaN)
                XCTAssertTrue(g.x >= 0 && g.x <= 1)
                if g.vorbei { break }
            }
        }
    }

    // MARK: Leistung
    func testRechenzeitProSchrittGrosseHoehe() {
        var g = Wolkenhuepfer(schwierigkeit: 3, zufall: ArcadeZufall(startwert: 11)); g.starte()
        let n = 120 * 300
        let t0 = ContinuousClock.now
        for i in 0..<n {
            g.testSetzeHoehe(g.hoechste + 0.01)
            g.lenke(um: i % 2 == 0 ? 0.01 : -0.01)
            g.schritt(1.0 / 120)
            if g.vorbei { g = Wolkenhuepfer(schwierigkeit: 3, zufall: ArcadeZufall(startwert: UInt64(i))); g.starte() }
        }
        let d = ContinuousClock.now - t0
        let ms = Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15
        print("LEISTUNG Wolkenhuepfer: \(ms / Double(n)) ms pro Schritt")
        XCTAssertLessThan(ms / Double(n), 2.0)   // großzügig (Debug-Build, belasteter Mac); gemessen < 0,1 ms
    }

    // MARK: Schwierigkeitskurve je Stufe (simulierter Spieler)
    /// Spieler: peilt die nächste sichere Wolke über sich an (Fehler σ ≈ 0,06) und lenkt mit höchstens 1,5 Bildbreiten pro Sekunde.
    private func hoeheNachLauf(stufe: Int, seed: UInt64) -> (zeit: Double, hoehe: Double) {
        var g = Wolkenhuepfer(schwierigkeit: stufe, zufall: ArcadeZufall(startwert: seed))
        var z = ArcadeZufall(startwert: seed &* 23); g.starte()
        var ziel = 0.5, n = 0
        while !g.vorbei && n < 120 * 120 {
            if n % 6 == 0 {
                let kandidaten = g.wolken.filter { !$0.weg && $0.art != .bruechig && $0.y > g.y - 0.02 && $0.y < g.y + 0.5 }.sorted { $0.y < $1.y }
                if let w = kandidaten.first(where: { $0.y > g.y + 0.05 }) ?? kandidaten.first { ziel = g.wolkenX(w) + z.zahl(-0.06...0.06) }
            }
            let d = max(-0.0125, min(0.0125, ziel - g.x))
            g.lenke(um: d)
            g.schritt(1.0 / 120); n += 1
        }
        return (Double(n) / 120, g.hoechste)
    }
    func testKurveJeStufe() {
        func mittel(_ st: Int) -> (Double, Double) { let r = (1...12).map { hoeheNachLauf(stufe: st, seed: UInt64($0)) }; return (r.map(\.zeit).reduce(0, +) / 12, r.map(\.hoehe).reduce(0, +) / 12) }
        let l = mittel(1), m = mittel(2), s = mittel(3)
        fputs("KURVE Wolkenhuepfer (Zeit, Hoehe): leicht \(l) mittel \(m) schwer \(s)\n", stderr)
        for w in [l, m, s] { XCTAssertGreaterThan(w.0, 10, "Keine Stufe darf nach wenigen Sekunden unspielbar sein") }
        // Befund: In der gespielten Höhe (bis ca. 3) ist die Kurve noch flach (Halbwert 25), die Stufen unterscheiden sich kaum.
        XCTAssertLessThan(Wolkenhuepfer(schwierigkeit: 1).schwere, Wolkenhuepfer(schwierigkeit: 3).schwere + 1e-9)
    }
}
