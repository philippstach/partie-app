// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import ArcadeKern
@testable import BallwechselKern

final class BallwechselTests: XCTestCase {
    let dt = 1.0 / 120
    func neu(_ stufe: Int = 2, _ s: UInt64 = 1, computer: Bool = true) -> Ballwechsel { var g = Ballwechsel(ziel: 7, computer: computer, stufe: stufe, zufall: ArcadeZufall(startwert: s)); g.starte(); return g }

    /// Spieler, der dem Ball folgt und mit der Kante schlägt – weg vom Gegner.
    func klug(_ g: inout Ballwechsel) {
        let away = g.schlaegerX[1] > 0.5 ? -1.0 : 1.0
        g.steuere(0, x: g.ballX - away * 0.75 * Ballwechsel.schlaegerB / 2)
    }

    func testBallBleibtImFeld() {
        var g = neu()
        for _ in 0..<(120 * 30) where !g.vorbei { klug(&g); g.schritt(dt); XCTAssertTrue(g.ballX >= 0 && g.ballX <= 1) }
    }
    func testWartetAufStartUndAufschlag() {
        var g = Ballwechsel(zufall: ArcadeZufall(startwert: 1)); g.schritt(5); XCTAssertEqual(g.punkte, [0, 0]); XCTAssertEqual(g.phase, .bereit)
        g.starte(); g.schritt(0.5); XCTAssertFalse(g.imSpiel)
        g.schritt(1); XCTAssertTrue(g.imSpiel)
    }
    func testNichtsTunVerliertSiebenZuNull() {
        var g = neu(); var t = 0
        while !g.vorbei && t < 120 * 600 { g.schritt(dt); t += 1 }
        XCTAssertTrue(g.vorbei); XCTAssertEqual(g.gewinner, 1); XCTAssertLessThan(g.punkte[0], 7)
    }
    func testSpielEndetExaktBeiZiel() {
        var g = neu(1, 3); var t = 0
        while !g.vorbei && t < 120 * 1200 { klug(&g); g.schritt(dt); t += 1 }
        XCTAssertTrue(g.vorbei)
        XCTAssertEqual(max(g.punkte[0], g.punkte[1]), 7)
        XCTAssertNotNil(g.gewinner)
    }
    func testGuterSpielerSchlaegtLeichtenComputerOft() {
        var siege = 0
        for seed in 1...6 as ClosedRange<UInt64> {
            var g = neu(1, seed); var t = 0
            while !g.vorbei && t < 120 * 1500 { klug(&g); g.schritt(dt); t += 1 }
            if g.gewinner == 0 { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 4, "leicht muss schlagbar sein: \(siege)/6")
    }
    func testSchwerBeendetPartieGegenMenschlichenSpieler() {
        // Ein „menschlicher“ Spieler: folgt dem Ball mit Verzögerung und zufälligem Treffpunkt
        var z = ArcadeZufall(startwert: 11)
        var g = neu(3, 2); var t = 0; var off = 0.0
        while !g.vorbei && t < 120 * 1500 {
            if t % 120 == 0 { off = z.zahl(-1...1) * 0.12 }
            g.steuere(0, x: g.ballX + off); g.schritt(dt); t += 1
        }
        XCTAssertTrue(g.vorbei); XCTAssertEqual(max(g.punkte[0], g.punkte[1]), 7)
    }
    func testTempoWaechstMitRallyeUndIstBegrenzt() {
        var g = neu(); XCTAssertEqual(g.tempo, Ballwechsel.startTempo)
        g.testRallye(100); XCTAssertEqual(g.tempo, Ballwechsel.maxTempo)
    }
    func testZweiSpielerModusSteuertOben() {
        var g = neu(computer: true); g.steuere(1, x: 0.8); for _ in 0..<240 { g.schritt(dt) }
        XCTAssertNotEqual(g.schlaegerX[1], 0.9)       // Computer ignoriert fremde Steuerung
        var h = neu(computer: false); h.steuere(1, x: 0.8); for _ in 0..<240 { h.schritt(dt) }
        XCTAssertEqual(h.schlaegerX[1], 0.8, accuracy: 1e-6)
    }

    func testStufenSindGestaffelt() {
        func siege(_ stufe: Int) -> Int {
            var n = 0
            for seed in 1...8 as ClosedRange<UInt64> {
                var g = neu(stufe, seed); var t = 0
                while !g.vorbei && t < 120 * 1500 { klug(&g); g.schritt(dt); t += 1 }
                if g.gewinner == 0 { n += 1 }
            }
            return n
        }
        let (l, m, s) = (siege(1), siege(2), siege(3))
        XCTAssertGreaterThanOrEqual(l, m, "leicht \(l) mittel \(m) schwer \(s)")
        XCTAssertGreaterThanOrEqual(m, s, "leicht \(l) mittel \(m) schwer \(s)")
        XCTAssertGreaterThanOrEqual(l, 6)
    }
    func testAusgleichNachSpielstand() {
        var g = neu(2)
        let normal = g.computerStaerke
        XCTAssertGreaterThan(normal, 0.05); XCTAssertLessThanOrEqual(normal, 1)
        // Kein Wertebereichsfehler bei beliebigem Rückstand
        for _ in 0..<7 { g.steuere(0, x: 0.5) }
        XCTAssertTrue((0.05...1).contains(g.computerStaerke))
    }
}
extension Ballwechsel { mutating func testRallye(_ n: Int) { setzeRallye(n) } }

final class BallwechselZusatzTests: XCTestCase {
    func testSpielzielWirdRespektiert() {
        for z in [5, 11, 15] {
            let g = Ballwechsel(ziel: z, computer: true, stufe: 2)
            XCTAssertEqual(g.ziel, z); XCTAssertNil(g.gewinner)
        }
    }
    func testStufeWirdBegrenzt() {
        XCTAssertEqual(Ballwechsel(stufe: 0).stufe, 1)
        XCTAssertEqual(Ballwechsel(stufe: 9).stufe, 3)
    }
    func testSteuerungVonSpielerEinsGegenComputerWirdIgnoriert() {
        var g = Ballwechsel(computer: true, zufall: ArcadeZufall(startwert: 3)); g.starte()
        let vorher = g.schlaegerX[1]
        g.steuere(1, x: 0.05); g.schritt(0.05)
        XCTAssertEqual(g.schlaegerX[1], vorher, accuracy: 0.2)
    }
    func testComputerStaerkeSteigtMitStufe() {
        let a = Ballwechsel(stufe: 1).computerStaerke, b = Ballwechsel(stufe: 2).computerStaerke, c = Ballwechsel(stufe: 3).computerStaerke
        XCTAssertLessThan(a, b); XCTAssertLessThan(b, c)
    }

    // MARK: Speichern und Fortsetzen
    func testSpeichernUndFortsetzenGleichesSpiel() throws {
        var a = Ballwechsel(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<600 { a.schritt(1.0 / 120) }
        let daten = try JSONEncoder().encode(a)
        var b = try JSONDecoder().decode(Ballwechsel.self, from: daten)
        XCTAssertEqual(a, b)
        // Danach verhalten sich beide gleich (auch der Zufall wurde gespeichert)
        for _ in 0..<600 { a.schritt(1.0 / 120); b.schritt(1.0 / 120) }
        XCTAssertEqual(a, b)
    }
    func testGespeichertePartieBleibtLaufend() throws {
        var a = Ballwechsel(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<60 { a.schritt(1.0 / 120) }
        let b = try JSONDecoder().decode(Ballwechsel.self, from: JSONEncoder().encode(a))
        XCTAssertEqual(b.phase, a.phase)
        XCTAssertEqual(b.phase, .laeuft)
    }
    func testKaputterStandWirdAbgelehnt() {
        XCTAssertThrowsError(try JSONDecoder().decode(Ballwechsel.self, from: Data("{\"x\":1}".utf8)))
    }

    // MARK: Fehlerjagd
    func testZufallseingabenBallBleibtImFeldUndSpielEndet() {
        for seed in 1...10 as ClosedRange<UInt64> {
            var g = Ballwechsel(ziel: 5, computer: seed % 2 == 0, stufe: Int(seed % 3) + 1, zufall: ArcadeZufall(startwert: seed))
            var z = ArcadeZufall(startwert: seed &* 9); g.starte()
            for i in 0..<(120 * 600) {
                if i % 20 == 0 { g.steuere(0, x: z.zahl(-0.5...1.5)); g.steuere(1, x: z.zahl(-0.5...1.5)) }
                g.schritt(1.0 / 120)
                XCTAssertFalse(g.ballX.isNaN || g.ballY.isNaN)
                XCTAssertTrue(g.ballX >= 0 && g.ballX <= 1, "Ball x=\(g.ballX)")
                for s in 0..<2 { XCTAssertTrue(g.schlaegerX[s] >= Ballwechsel.schlaegerB / 2 - 1e-9 && g.schlaegerX[s] <= 1 - Ballwechsel.schlaegerB / 2 + 1e-9) }
                if g.vorbei { break }
            }
            XCTAssertTrue(g.vorbei, "Spiel endet nicht (Seed \(seed))")
            XCTAssertEqual(g.punkte.max(), 5)
        }
    }

    // MARK: Leistung
    func testRechenzeitProSchritt() {
        var g = Ballwechsel(ziel: 15, computer: true, stufe: 3, zufall: ArcadeZufall(startwert: 11)); g.starte(); g.setzeRallye(40)
        let n = 120 * 300
        let t0 = ContinuousClock.now
        for i in 0..<n { g.steuere(0, x: Double(i % 100) / 100); g.schritt(1.0 / 120); if g.vorbei { g = Ballwechsel(ziel: 15, computer: true, stufe: 3, zufall: ArcadeZufall(startwert: UInt64(i))); g.starte() } }
        let d = ContinuousClock.now - t0
        let ms = Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15
        print("LEISTUNG Ballwechsel: \(ms / Double(n)) ms pro Schritt")
        XCTAssertLessThan(ms / Double(n), 2.0)   // großzügig (Debug-Build, belasteter Mac); gemessen < 0,1 ms
    }

    // MARK: Computerstärke je Stufe (simulierte Spiele gegen einen ordentlichen Menschen)
    /// Menschlicher Spieler: schaut alle 0,12 s auf den Ball, schätzt den Auftreffpunkt unten mit Fehler (σ ≈ 0,03) und zieht dorthin.
    private func menschGewinntAnteil(stufe: Int, spiele: Int, fehler: Double) -> Double {
        var siege = 0
        for n in 0..<spiele {
            var g = Ballwechsel(ziel: 7, computer: true, stufe: stufe, zufall: ArcadeZufall(startwert: UInt64(1000 + n * 7 + stufe)))
            var z = ArcadeZufall(startwert: UInt64(n * 31 + 5)); g.starte()
            var denk = 0.0
            var schritte = 0
            while !g.vorbei && schritte < 120 * 900 {
                denk -= 1.0 / 120
                if denk <= 0 {
                    denk = 0.12
                    var x = 0.5 + (g.ballX - 0.5) * 0.3
                    if g.imSpiel, g.vy > 0 {
                        let t = (Ballwechsel.hoehe - Ballwechsel.randAbstand - Ballwechsel.schlaegerH - g.ballY) / g.vy
                        let breite = 1 - 2 * Ballwechsel.radius
                        var f = (g.ballX - Ballwechsel.radius + g.vx * t).truncatingRemainder(dividingBy: 2 * breite)
                        if f < 0 { f += 2 * breite }
                        if f > breite { f = 2 * breite - f }
                        x = f + Ballwechsel.radius
                        // Ein geschickter Mensch zielt mit der Schlägerkante weg vom Computer
                        let weg = g.schlaegerX[1] < 0.5 ? 1.0 : -1.0
                        x -= weg * 0.8 * Ballwechsel.schlaegerB / 2
                    }
                    g.steuere(0, x: x + z.zahl(-fehler...fehler))
                }
                g.schritt(1.0 / 120); schritte += 1
            }
            if g.gewinner == 0 { siege += 1 }
        }
        return Double(siege) / Double(spiele)
    }

    func testComputerStaerkeJeStufe() {
        let leicht = menschGewinntAnteil(stufe: 1, spiele: 40, fehler: 0.05)
        let mittel = menschGewinntAnteil(stufe: 2, spiele: 40, fehler: 0.05)
        let schwer = menschGewinntAnteil(stufe: 3, spiele: 40, fehler: 0.05)
        print("STAERKE Mensch gewinnt: leicht \(leicht) mittel \(mittel) schwer \(schwer)")
        XCTAssertGreaterThanOrEqual(leicht, mittel)
        XCTAssertGreaterThanOrEqual(mittel, schwer)
        XCTAssertGreaterThan(leicht, 0.8, "Leicht muss gut schlagbar sein")
        XCTAssertTrue((0.3...0.9).contains(mittel), "Mittel muss ein faires Spiel sein, war \(mittel)")
        XCTAssertGreaterThan(schwer, 0.1, "Schwer darf nicht unschlagbar sein")
        XCTAssertLessThan(schwer, 0.7, "Schwer muss fordernd sein")
    }
}
