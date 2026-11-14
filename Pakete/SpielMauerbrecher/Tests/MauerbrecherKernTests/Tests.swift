// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import ArcadeKern
@testable import MauerbrecherKern

final class MauerbrecherTests: XCTestCase {
    let dt = 1.0 / 120
    func neu(_ s: UInt64 = 1) -> Mauerbrecher { var g = Mauerbrecher(zufall: ArcadeZufall(startwert: s)); g.starte(); return g }

    func botSchritt(_ g: inout Mauerbrecher) {
        if g.haftet { g.abschuss() }
        if let b = g.baelle.filter({ $0.vy > 0 }).max(by: { $0.y < $1.y }) ?? g.baelle.first { g.zielen(b.x) }
        g.schritt(dt)
    }

    func testBallBleibtImFeldUndWirdNieWaagerecht() {
        var g = neu()
        for _ in 0..<(120 * 60) where !g.vorbei {
            botSchritt(&g)
            for b in g.baelle where !g.haftet {
                XCTAssertTrue(b.x >= 0 && b.x <= 1 && b.y >= 0)
                XCTAssertGreaterThan(abs(b.vy), 0.2 * g.ballTempo * 0.9, "zu flach")
            }
        }
    }
    func testBotRaeumtLevelEinsUndKommtWeiter() {
        var g = neu(2); var t = 0
        while !g.vorbei && g.stufe < 3 && t < 120 * 400 { botSchritt(&g); t += 1 }
        XCTAssertGreaterThanOrEqual(g.stufe, 3, "nach \(t / 120) s nur Stufe \(g.stufe), leben \(g.leben)")
        XCTAssertGreaterThan(g.punkte, 500)
    }
    func testNichtsTunVerliertAlleLebenUndEndetMitAus() {
        var g = neu(3); var t = 0
        while !g.vorbei && t < 120 * 600 { if g.haftet { g.abschuss() }; g.zielen(0.0); g.schritt(dt); t += 1 }
        XCTAssertTrue(g.vorbei); XCTAssertEqual(g.leben, 0)
        XCTAssertNotNil(g.phase.grund)
    }
    func testMauerErreichtSchlaegerEndetSpiel() {
        var g = neu(4); g.starte()
        var t = 0
        while !g.vorbei && t < 120 * 2000 { g.zielen(0.5); g.schritt(dt); t += 1 }      // Ball bleibt auf dem Schläger kleben (wird nach 3 s abgeschossen) 
        XCTAssertTrue(g.vorbei)
    }
    func testSchlaegerBewegtSichNurMitHoechstgeschwindigkeit() {
        var g = neu(); g.zielen(1); g.schritt(dt)
        XCTAssertLessThan(g.schlaegerX - 0.5, Mauerbrecher.schlaegerSpeed * dt + 1e-9)
    }
    func testLevelSchaffenGibtBonusUndHoehereStufe() {
        var g = neu(); g.testSteineLeeren(); g.schritt(dt)
        XCTAssertEqual(g.stufe, 2); XCTAssertGreaterThanOrEqual(g.punkte, 200); XCTAssertFalse(g.steine.isEmpty)
    }
    func testTempoSteigtMitStufe() {
        var g = neu(); let t1 = g.ballTempo
        g.testSteineLeeren(); g.schritt(dt)
        XCTAssertGreaterThan(g.ballTempo, t1)
    }

    func testBotKommtMehrereLevelWeitUndPunkteSteigen() {
        for seed in 1...3 as ClosedRange<UInt64> {
            var g = neu(seed); var t = 0; var letzte = 0
            while !g.vorbei && g.stufe < 5 && t < 120 * 900 { botSchritt(&g); t += 1; XCTAssertGreaterThanOrEqual(g.punkte, letzte); letzte = g.punkte }
            XCTAssertGreaterThanOrEqual(g.stufe, 4, "Seed \(seed): Stufe \(g.stufe) nach \(t / 120) s, Grund: \(g.phase.grund ?? "-")")
        }
    }
    func testLevelMusterSindImmerLeerUndSpielbar() {
        var g = neu(5)
        for _ in 0..<8 {
            XCTAssertFalse(g.steine.isEmpty)
            XCTAssertTrue(g.steine.allSatisfy { $0.spalte >= 0 && $0.spalte < Mauerbrecher.spalten && $0.leben >= 1 })
            XCTAssertFalse(g.vorbei)
            g.testSteineLeeren(); g.schritt(dt)
        }
    }

    func testBallTempoUndSenkungWachsenSanft() {
        var g = neu(); var tempo = g.ballTempo, senk = g.senkung
        for _ in 0..<12 {
            g.testSteineLeeren(); g.schritt(dt)
            XCTAssertGreaterThanOrEqual(g.ballTempo, tempo); XCTAssertLessThan(g.ballTempo - tempo, 0.25)
            XCTAssertGreaterThanOrEqual(g.senkung, senk); XCTAssertLessThan(g.senkung - senk, 0.002)
            tempo = g.ballTempo; senk = g.senkung
        }
        XCTAssertLessThanOrEqual(g.ballTempo, 1.5 + 1e-9)
        // Eine Mauer braucht mindestens 60 s, um den Schläger zu erreichen (auch auf hoher Stufe, ohne Ball)
        let weg = Mauerbrecher.schlaegerY - Mauerbrecher.oben - 0.05 * 8
        XCTAssertGreaterThan(weg / g.senkung, 60)
    }

    // MARK: Speichern und Fortsetzen
    func testSpeichernUndFortsetzenGleichesSpiel() throws {
        var a = Mauerbrecher(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<600 { a.schritt(1.0 / 120) }
        let daten = try JSONEncoder().encode(a)
        var b = try JSONDecoder().decode(Mauerbrecher.self, from: daten)
        XCTAssertEqual(a, b)
        // Danach verhalten sich beide gleich (auch der Zufall wurde gespeichert)
        for _ in 0..<600 { a.schritt(1.0 / 120); b.schritt(1.0 / 120) }
        XCTAssertEqual(a, b)
    }
    func testGespeichertePartieBleibtLaufend() throws {
        var a = Mauerbrecher(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<60 { a.schritt(1.0 / 120) }
        let b = try JSONDecoder().decode(Mauerbrecher.self, from: JSONEncoder().encode(a))
        XCTAssertEqual(b.phase, a.phase)
        XCTAssertEqual(b.phase, .laeuft)
    }
    func testKaputterStandWirdAbgelehnt() {
        XCTAssertThrowsError(try JSONDecoder().decode(Mauerbrecher.self, from: Data("{\"x\":1}".utf8)))
    }

    // MARK: Stufen (leicht / mittel / schwer)
    func testSchwerIstSchnellerAlsLeicht() {
        func wert(_ st: Int) -> Double { let g = Mauerbrecher(schwierigkeit: st, zufall: ArcadeZufall(startwert: 3)); return g.ballTempo }
        XCTAssertLessThan(wert(1), wert(2)); XCTAssertLessThan(wert(2), wert(3))
    }
    func testStufeWirdBegrenzt() {
        XCTAssertEqual(Mauerbrecher(schwierigkeit: 9).schwierigkeit, 3)
        XCTAssertEqual(Mauerbrecher(schwierigkeit: -4).schwierigkeit, 1)
    }

    // MARK: Fehlerjagd (Zufallseingaben, Randfälle)
    func testZufallseingabenHaltenBaelleImFeld() {
        for seed in 1...12 as ClosedRange<UInt64> {
            var g = Mauerbrecher(schwierigkeit: Int(seed % 3) + 1, zufall: ArcadeZufall(startwert: seed))
            var z = ArcadeZufall(startwert: seed &* 77)
            g.starte()
            for i in 0..<(120 * 120) {
                if i % 40 == 0 { g.zielen(z.zahl(-0.5...1.5)) }
                if i % 300 == 0 { g.abschuss() }
                g.schritt(1.0 / 120)
                for b in g.baelle {
                    XCTAssertFalse(b.x.isNaN || b.y.isNaN, "NaN bei Seed \(seed)")
                    XCTAssertTrue(b.x >= 0 && b.x <= 1, "Ball ausserhalb x=\(b.x) Seed \(seed)")
                    XCTAssertGreaterThanOrEqual(b.y, 0)
                }
                XCTAssertTrue(g.schlaegerX - g.schlaegerBreite / 2 >= -1e-9 && g.schlaegerX + g.schlaegerBreite / 2 <= 1 + 1e-9)
                if g.vorbei { break }
            }
        }
    }
    func testBallBleibtNichtWaagerecht() {
        var g = Mauerbrecher(zufall: ArcadeZufall(startwert: 5)); g.starte(); g.abschuss()
        for _ in 0..<(120 * 30) {
            g.zielen(g.baelle.first?.x ?? 0.5); g.schritt(1.0 / 120)
            for b in g.baelle where !g.haftet { XCTAssertGreaterThan(abs(b.vy), 0.1 * g.ballTempo) }
            if g.vorbei { break }
        }
    }

    // MARK: Leistung (Rechenzeit pro Schritt; Bildrate 60 Hz = 2 Schritte à 1/120 s in 16,7 ms)
    func testRechenzeitProSchrittHoechsteStufeVieleObjekte() {
        var g = Mauerbrecher(schwierigkeit: 3, zufall: ArcadeZufall(startwert: 11)); g.starte()
        var z = ArcadeZufall(startwert: 3)
        let n = 120 * 60
        let t0 = ContinuousClock.now
        for i in 0..<n {
            if i % 30 == 0 { g.zielen(g.baelle.first?.x ?? 0.5 + z.zahl(-0.1...0.1)) }
            g.schritt(1.0 / 120)
            if g.vorbei { g = Mauerbrecher(schwierigkeit: 3, zufall: ArcadeZufall(startwert: UInt64(i))); g.starte() }
        }
        let ms = Double((ContinuousClock.now - t0).components.attoseconds) / 1e15 + Double((ContinuousClock.now - t0).components.seconds) * 1000
        print("LEISTUNG Mauerbrecher: \(ms / Double(n)) ms pro Schritt")
        XCTAssertLessThan(ms / Double(n), 2.0, "Ein Schritt braucht zu lang")
    }

    func testVerloreneLebenWerdenGezaehlt() {
        var g = Mauerbrecher(zufall: ArcadeZufall(startwert: 2)); g.starte(); g.abschuss()
        g.zielen(0); var n = 0
        while g.verloreneLeben == 0 && n < 120 * 120 { g.schritt(1.0 / 120); n += 1 }
        XCTAssertEqual(g.verloreneLeben, Mauerbrecher.startLeben - g.leben)
        XCTAssertGreaterThan(g.verloreneLeben, 0)
    }

    // MARK: Schwierigkeitskurve je Stufe (simulierter Spieler)
    /// Spieler: schaut alle 0,1 s auf den Ball, folgt ihm mit Fehler (σ ≈ 0,04); Punkte nach 100 s (oder Ende) zählen.
    private func punkteNachLauf(stufe: Int, seed: UInt64) -> (zeit: Double, punkte: Int) {
        var g = Mauerbrecher(schwierigkeit: stufe, zufall: ArcadeZufall(startwert: seed))
        var z = ArcadeZufall(startwert: seed &* 29); g.starte()
        var n = 0
        while !g.vorbei && n < 120 * 100 {
            if n % 12 == 0 { g.zielen((g.baelle.first(where: { $0.vy > 0 })?.x ?? g.baelle.first?.x ?? 0.5) + z.zahl(-0.07...0.07)) }
            if n % 60 == 0 { g.abschuss() }
            g.schritt(1.0 / 120); n += 1
        }
        return (Double(n) / 120, g.punkte)
    }
    func testKurveJeStufe() {
        func mittel(_ st: Int) -> (Double, Double) { let r = (1...16).map { punkteNachLauf(stufe: st, seed: UInt64($0)) }; return (r.map(\.zeit).reduce(0, +) / 16, Double(r.map(\.punkte).reduce(0, +)) / 16) }
        let l = mittel(1), m = mittel(2), s = mittel(3)
        fputs("KURVE Mauerbrecher (Zeit, Punkte): leicht \(l) mittel \(m) schwer \(s)\n", stderr)
        for w in [l, m, s] { XCTAssertGreaterThan(w.0, 10, "Keine Stufe darf nach wenigen Sekunden unspielbar sein") }
        XCTAssertGreaterThanOrEqual(l.0, s.0, "Leicht darf nicht kürzer dauern als Schwer")
    }
}
