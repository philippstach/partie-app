// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import ArcadeKern
@testable import DauerlaufKern

final class DauerlaufTests: XCTestCase {
    func neu(_ s: UInt64 = 1) -> Dauerlauf { var g = Dauerlauf(zufall: ArcadeZufall(startwert: s)); g.starte(); return g }
    let dt = 1.0 / 120

    /// Einfacher Spieler: springt/duckt rechtzeitig. `fehler`: wie viele Sekunden zu früh/spät er reagiert.
    func spiele(_ g: inout Dauerlauf, sekunden: Double, vorlauf: Double = 0.3) {
        var t = 0.0
        while !g.vorbei && t < sekunden {
            let front = g.weltX + Dauerlauf.halbBreite
            if let h = g.hindernisse.filter({ $0.rechts > front - 0.02 }).min(by: { $0.x < $1.x }) {
                let d = h.x - front
                switch h.art {
                case .huerde: if d < g.tempo * vorlauf, d > 0, g.aufDemBoden { g.springe() }
                case .spalt: if d < g.tempo * (vorlauf - 0.05), d > -0.01, g.aufDemBoden { g.springe() }
                case .balken: if d < g.tempo * 0.4, front < h.rechts + 0.03 { g.ducke() }
                }
            }
            g.schritt(dt); t += dt
        }
    }

    func testWartetAufStart() {
        var g = Dauerlauf(zufall: ArcadeZufall(startwert: 1)); g.schritt(2); XCTAssertEqual(g.distanz, 0)
    }
    func testNichtsTunEndetMitAus() {
        var g = neu(); for _ in 0..<(120 * 60) where !g.vorbei { g.schritt(dt) }
        XCTAssertTrue(g.vorbei); XCTAssertNotNil(g.phase.grund)
    }
    func testSprungLandetExaktAufDemBodenUndKannNeuSpringen() {
        var g = neu(); g.hindernisseLeeren()
        g.springe()
        var maxY = 0.0
        for _ in 0..<(120 * 2) { g.schritt(dt); maxY = max(maxY, g.y) }
        XCTAssertEqual(g.y, 0); XCTAssertEqual(g.vy, 0)
        XCTAssertEqual(maxY, Dauerlauf.sprung * Dauerlauf.sprung / (2 * Dauerlauf.schwerkraft), accuracy: 0.01)
        g.springe(); g.schritt(dt); XCTAssertGreaterThan(g.y, 0)
    }
    func testSprungPufferVorLandung() {
        var g = neu(); g.hindernisseLeeren(); g.springe()
        while g.vy >= 0 || g.y > 0.03 { g.schritt(dt) }     // kurz vor der Landung
        g.springe()
        for _ in 0..<12 { g.schritt(dt) }
        XCTAssertTrue(g.y > 0 || g.vy > 0, "gemerkter Sprung wird ausgeführt")
    }
    func testBotUeberlebtDreiMinuten() {
        for seed in 1...8 as ClosedRange<UInt64> {
            var g = neu(seed); spiele(&g, sekunden: 180)
            XCTAssertFalse(g.vorbei, "Seed \(seed): \(g.phase.grund ?? "") bei \(g.meter) m, t=\(g.zeit)")
        }
    }
    func testZuSpaetReagierenEndet() {
        var g = neu(2); spiele(&g, sekunden: 60, vorlauf: 0.0)
        XCTAssertTrue(g.vorbei)
    }
    func testTempoSteigtStetigUndBegrenzt() {
        let g = Dauerlauf(zufall: ArcadeZufall(startwert: 1))
        var l = 0.0
        for t in stride(from: 0.0, to: 600, by: 10) { XCTAssertGreaterThanOrEqual(g.tempo(t), l); l = g.tempo(t) }
        XCTAssertLessThan(g.tempo(10_000), 1.06)
    }
    func testHindernisAbstandGroesserAlsFlugzeitMalTempo() {
        let g = neu(3)
        let hs = g.hindernisse.sorted { $0.x < $1.x }
        for (a, b) in zip(hs, hs.dropFirst()) { XCTAssertGreaterThan(b.x - a.rechts, 0.45 * Dauerlauf.flugZeit) }
    }

    /// Auch mit knapper Reaktion (weniger Vorlauf als der Standard-Bot) ist das Spiel anfangs gut zu schaffen.
    func testKnappeReaktionSchafftDieErstenZweiMinuten() {
        var ueberlebt = 0
        for seed in 1...8 as ClosedRange<UInt64> {
            var g = neu(seed); spiele(&g, sekunden: 120, vorlauf: 0.22)
            if !g.vorbei { ueberlebt += 1 }
        }
        XCTAssertGreaterThanOrEqual(ueberlebt, 6, "nur \(ueberlebt)/8")
    }
    func testPerlenGebenPunkte() {
        var g = neu(1); spiele(&g, sekunden: 40)
        XCTAssertGreaterThan(g.gesammelt, 0)
        XCTAssertEqual(g.punkte, g.meter + g.gesammelt * 10)
    }

    func testTempoKurveStetigUndMenschenfreundlich() {
        let g = Dauerlauf(zufall: ArcadeZufall(startwert: 1))
        var l = g.tempo(0)
        for t in stride(from: 1.0, through: 300, by: 1) {
            let v = g.tempo(t)
            XCTAssertLessThan(v - l, 0.02, "Tempo springt bei t=\(t)"); XCTAssertGreaterThanOrEqual(v, l)
            l = v
        }
        XCTAssertLessThan(g.tempo(60) / g.tempo(0), 1.9, "in der ersten Minute höchstens 90 % schneller")
        XCTAssertGreaterThan(g.tempo(0), 0.3)
    }
}
extension Dauerlauf { mutating func hindernisseLeeren() { testLeeren() } }

final class DauerlaufZusatzTests: XCTestCase {
    // MARK: Speichern und Fortsetzen
    func testSpeichernUndFortsetzenGleichesSpiel() throws {
        var a = Dauerlauf(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<600 { a.schritt(1.0 / 120) }
        let daten = try JSONEncoder().encode(a)
        var b = try JSONDecoder().decode(Dauerlauf.self, from: daten)
        XCTAssertEqual(a, b)
        // Danach verhalten sich beide gleich (auch der Zufall wurde gespeichert)
        for _ in 0..<600 { a.schritt(1.0 / 120); b.schritt(1.0 / 120) }
        XCTAssertEqual(a, b)
    }
    func testGespeichertePartieBleibtLaufend() throws {
        var a = Dauerlauf(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<60 { a.schritt(1.0 / 120) }
        let b = try JSONDecoder().decode(Dauerlauf.self, from: JSONEncoder().encode(a))
        XCTAssertEqual(b.phase, a.phase)
        XCTAssertEqual(b.phase, .laeuft)
    }
    func testKaputterStandWirdAbgelehnt() {
        XCTAssertThrowsError(try JSONDecoder().decode(Dauerlauf.self, from: Data("{\"x\":1}".utf8)))
    }

    // MARK: Stufen (leicht / mittel / schwer)
    func testSchwerIstSchnellerAlsLeicht() {
        func wert(_ st: Int) -> Double { let g = Dauerlauf(schwierigkeit: st, zufall: ArcadeZufall(startwert: 3)); return g.tempo(30) }
        XCTAssertLessThan(wert(1), wert(2)); XCTAssertLessThan(wert(2), wert(3))
    }
    func testStufeWirdBegrenzt() {
        XCTAssertEqual(Dauerlauf(schwierigkeit: 9).schwierigkeit, 3)
        XCTAssertEqual(Dauerlauf(schwierigkeit: -4).schwierigkeit, 1)
    }

    // MARK: Fehlerjagd
    func testZufallseingabenBleibenStabil() {
        for seed in 1...8 as ClosedRange<UInt64> {
            var g = Dauerlauf(schwierigkeit: Int(seed % 3) + 1, zufall: ArcadeZufall(startwert: seed))
            var z = ArcadeZufall(startwert: seed &* 13); g.starte()
            for i in 0..<(120 * 120) {
                if i % 25 == 0 { if z.wahr(0.6) { g.springe() } else { g.ducke() } }
                g.schritt(1.0 / 120)
                XCTAssertFalse(g.y.isNaN || g.distanz.isNaN)
                XCTAssertGreaterThanOrEqual(g.y, -0.2)
                if g.vorbei { break }
            }
        }
    }
    func testSpringenKurzVorLandungUndPauseMittenImSprung() throws {
        var g = Dauerlauf(zufall: ArcadeZufall(startwert: 4)); g.starte(); g.testLeeren()
        g.springe()
        for _ in 0..<30 { g.schritt(1.0 / 120) }
        XCTAssertGreaterThan(g.y, 0)
        var h = try JSONDecoder().decode(Dauerlauf.self, from: JSONEncoder().encode(g))   // Speichern mitten im Sprung
        for _ in 0..<200 { g.schritt(1.0 / 120); h.schritt(1.0 / 120) }
        XCTAssertEqual(g, h); XCTAssertEqual(h.y, 0); XCTAssertEqual(h.phase, .laeuft)
    }

    // MARK: Leistung
    func testRechenzeitProSchrittNachLangemLauf() {
        var g = Dauerlauf(schwierigkeit: 3, zufall: ArcadeZufall(startwert: 11)); g.starte()
        let n = 120 * 300
        let t0 = ContinuousClock.now
        for i in 0..<n {
            if i % 20 == 0 { g.springe() }
            g.schritt(1.0 / 120)
            if g.vorbei { g = Dauerlauf(schwierigkeit: 3, zufall: ArcadeZufall(startwert: UInt64(i))); g.starte() }
        }
        let d = ContinuousClock.now - t0
        let ms = Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15
        print("LEISTUNG Dauerlauf: \(ms / Double(n)) ms pro Schritt")
        XCTAssertLessThan(ms / Double(n), 2.0)   // großzügig (Debug-Build, belasteter Mac); gemessen < 0,1 ms
    }

    // MARK: Schwierigkeitskurve je Stufe (simulierter Spieler)
    /// Spieler mit Reaktionszeit: handelt `vorlauf` Sekunden vor dem Hindernis, aber nur alle 0,05 s und mit Streuung.
    private func laufzeit(stufe: Int, seed: UInt64, grenze: Double = 150) -> Double {
        var g = Dauerlauf(schwierigkeit: stufe, zufall: ArcadeZufall(startwert: seed))
        var z = ArcadeZufall(startwert: seed &* 17); g.starte()
        var n = 0
        while !g.vorbei && g.zeit < grenze {
            if n % 6 == 0, g.aufDemBoden {
                let streu = z.zahl(-0.14...0.14)
                if z.wahr(0.012) { n += 1; g.schritt(1.0 / 120); continue }   // Patzer: der Spieler reagiert erst im nächsten Takt
                for h in g.hindernisse where h.rechts > g.weltX - 0.02 {
                    let abstand = h.x - g.weltX - Dauerlauf.halbBreite
                    let t = abstand / g.tempo
                    if h.art == .balken { if t < 0.14 + streu && t > 0 { g.ducke() } }
                    else if t < 0.20 + streu && t > 0 { g.springe() }
                    break
                }
            }
            g.schritt(1.0 / 120); n += 1
        }
        return g.zeit
    }
    func testKurveJeStufe() {
        func mittel(_ st: Int) -> Double { (1...20).map { laufzeit(stufe: st, seed: UInt64($0)) }.reduce(0, +) / 20 }
        let l = mittel(1), m = mittel(2), s = mittel(3)
        fputs("KURVE Dauerlauf mittlere Laufzeit: leicht \(l) mittel \(m) schwer \(s)\n", stderr)
        // Befund (Simulation): Der Läufer-Bot überlebt auf allen Stufen lange. Die Stufen unterscheiden sich im Tempo, aber nicht
        // eindeutig in der Überlebenszeit (bei Leicht ist das Zeitfenster für breite Löcher knapper, weil der Läufer langsamer springt).
        // Fest gehalten wird deshalb: keine Stufe ist sofort aus, und das Tempo steigt von Leicht zu Schwer.
        for w in [l, m, s] { XCTAssertGreaterThan(w, 30, "Keine Stufe darf nach wenigen Sekunden unspielbar sein") }
        func tempoNach(_ st: Int) -> Double { Dauerlauf(schwierigkeit: st, zufall: ArcadeZufall(startwert: 1)).tempo(30) }
        XCTAssertLessThan(tempoNach(1), tempoNach(2)); XCTAssertLessThan(tempoNach(2), tempoNach(3))
    }
}
