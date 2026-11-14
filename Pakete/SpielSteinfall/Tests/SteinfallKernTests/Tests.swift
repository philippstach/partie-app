// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import ArcadeKern
@testable import SteinfallKern

final class SteinfallTests: XCTestCase {
    private func spiel(_ s: UInt64 = 1) -> Steinfall { var g = Steinfall(zufall: ArcadeZufall(startwert: s)); g.starte(); return g }

    func testStartetBereitUndLaeuftErstNachStart() {
        var g = Steinfall(zufall: ArcadeZufall(startwert: 1))
        XCTAssertEqual(g.phase, .bereit)
        let y = g.ankerY; g.schritt(5)
        XCTAssertEqual(g.ankerY, y)
        g.starte(); XCTAssertEqual(g.phase, .laeuft)
    }
    func testBewegenStopptAnWand() {
        var g = spiel()
        for _ in 0..<20 { g.bewege(-1) }
        XCTAssertTrue(g.aktuelleFelder.allSatisfy { $0.x >= 0 })
        XCTAssertEqual(g.aktuelleFelder.map(\.x).min(), 0)
    }
    func testDrehenBleibtImFeld() {
        var g = spiel(3)
        for _ in 0..<20 { g.bewege(1) }
        for _ in 0..<8 { g.drehe(); XCTAssertFalse(g.kollidiert(g.zellen, g.ankerX, g.ankerY)) }
    }
    func testVolleReiheLoestSichAufUndPunkte() {
        var g = spiel()
        var f = Array(repeating: Array(repeating: 0, count: Steinfall.breite), count: Steinfall.hoehe)
        f[Steinfall.hoehe - 1] = Array(repeating: 1, count: Steinfall.breite)
        f[Steinfall.hoehe - 1][4] = 0
        g.setzeFeld(f)
        // Teil so legen, dass es die Lücke füllt: Stab senkrecht in Spalte 4
        while g.form != 0 { g.hartFallen(); g.setzeFeld(f); if g.vorbei { break } }
        guard g.form == 0 else { return XCTFail("kein Stab") }
        let vorher = g.punkte, reihenVorher = g.reihen
        g.bewege(4 - g.ankerX)
        g.hartFallen()
        XCTAssertEqual(g.reihen - reihenVorher, 1)
        XCTAssertGreaterThan(g.punkte, vorher)
    }
    func testEndeNurWennNichtsMehrPasstUndNieGewonnen() {
        var g = spiel(5)
        var n = 0
        while !g.vorbei && n < 500 { g.hartFallen(); n += 1 }     // einfach alles in die Mitte werfen
        XCTAssertTrue(g.vorbei, "Spiel muss enden")
        guard case .vorbei(let grund) = g.phase else { return XCTFail() }
        XCTAssertFalse(grund.isEmpty)
        XCTAssertLessThan(n, 60)
    }
    func testAbstandHaeltTeilSchwebendVorLandung() {
        var g = spiel()
        for _ in 0..<(120 * 20) { g.schritt(1.0 / 120); if g.phase != .laeuft { break } }
        XCTAssertGreaterThan(g.fallZeit, 0)
    }
    func testSchwierigkeitSteigtStetig() {
        var g = spiel(); var letzte = g.fallZeit
        for r in stride(from: 0, through: 120, by: 6) { g.setzeReihen(r); XCTAssertLessThanOrEqual(g.fallZeit, letzte + 1e-12); letzte = g.fallZeit }
        XCTAssertGreaterThan(g.fallZeit, 0.08)
        g.setzeReihen(0); XCTAssertEqual(g.fallZeit, 0.8, accuracy: 1e-9)
    }
    func testSchattenLiegtUnterTeil() {
        let g = spiel()
        XCTAssertGreaterThanOrEqual(g.schatten.map(\.y).max()!, g.aktuelleFelder.map(\.y).max()!)
    }
    func testKeinAbsturzBeiZufallsspiel() {
        var g = spiel(9); var z = ArcadeZufall(startwert: 2); var i = 0
        while !g.vorbei && i < 20000 {
            switch z.ganz(0...4) { case 0: g.bewege(-1); case 1: g.bewege(1); case 2: g.drehe(); case 3: if z.wahr(0.1) { g.hartFallen() }; default: break }
            g.schritt(1.0 / 60); i += 1
        }
        XCTAssertTrue(true)
    }

    // MARK: Bot (Rule 7: Spiel ist schaffbar)

    /// Einfacher Bot: probiert alle Drehungen und Spalten, setzt das Teil hart ab und nimmt die Stellung mit den wenigsten Löchern/der geringsten Höhe.
    private func bewerte(_ g: Steinfall) -> Double {
        var hoehen = [Int](repeating: 0, count: Steinfall.breite), loecher = 0
        for x in 0..<Steinfall.breite {
            var gefunden = false
            for y in 0..<Steinfall.hoehe {
                if g.feld[y][x] != 0 { if !gefunden { hoehen[x] = Steinfall.hoehe - y; gefunden = true } }
                else if gefunden { loecher += 1 }
            }
        }
        var rauheit = 0
        for (a, b) in zip(hoehen, hoehen.dropFirst()) { rauheit += abs(a - b) }
        return Double(loecher) * 9 + Double(hoehen.max()!) * 1.5 + Double(rauheit) * 0.6 + Double(hoehen.reduce(0, +)) * 0.3
    }

    /// Alle erreichbaren Absetzstellungen des aktuellen Teils (Drehung × Spalte), jeweils nach hartem Fall.
    private func kandidaten(_ g: Steinfall) -> [Steinfall] {
        var aus: [Steinfall] = []
        for dreh in 0..<4 {
            var a = g
            for _ in 0..<dreh { a.drehe() }
            for ziel in 0..<Steinfall.breite {
                var b = a
                let dx = ziel - (b.ankerX + b.zellen.map(\.x).min()!)
                var gut = true
                for _ in 0..<abs(dx) { if !b.bewege(dx > 0 ? 1 : -1) { gut = false; break } }
                guard gut else { continue }
                b.hartFallen()
                aus.append(b)
            }
        }
        return aus
    }

    private func botZug(_ g: inout Steinfall) {
        // 1. Stufe: die sechs besten Stellungen, 2. Stufe: Blick auf das nächste Teil
        let erste = kandidaten(g).map { ($0, bewerte($0) - Double($0.reihen - g.reihen) * 40) }.sorted { $0.1 < $1.1 }.prefix(6)
        var bester: (Double, Steinfall)?
        for (b, w1) in erste {
            var w = w1
            if b.vorbei { w += 10_000 }
            else { w += (kandidaten(b).map { bewerte($0) - Double($0.reihen - b.reihen) * 40 }.min() ?? 1000) * 0.7 }
            if bester == nil || w < bester!.0 { bester = (w, b) }
        }
        if let b = bester { g = b.1 } else { g.hartFallen() }
    }

    /// Das Spiel ist schaffbar: ein Bot mit Blick auf das nächste Teil räumt viele Reihen, ohne unterzugehen.
    func testBotRaeumtVieleReihen() {
        for seed in 1...3 as ClosedRange<UInt64> {
            var g = spiel(seed); var zuege = 0
            while !g.vorbei && zuege < 70 { botZug(&g); zuege += 1 }
            XCTAssertFalse(g.vorbei, "Seed \(seed): untergegangen nach \(zuege) Zügen mit \(g.reihen) Reihen")
            XCTAssertGreaterThan(g.reihen, 15, "Seed \(seed): nur \(g.reihen) Reihen")
        }
    }

    func testNichtsTunEndetMitAus() {
        var g = spiel(7)
        for _ in 0..<(120 * 600) where !g.vorbei { g.schritt(1.0 / 120) }
        XCTAssertTrue(g.vorbei, "Ohne Eingabe muss das Spiel enden")
        XCTAssertNotNil(g.phase.grund)
    }

    func testWeichFallenBringtPunkteAberHartFallenAuch() {
        var g = spiel(2)
        g.weich = true
        for _ in 0..<120 { g.schritt(1.0 / 120) }
        XCTAssertGreaterThan(g.punkte, 0)
        let p = g.punkte
        g.weich = false; g.hartFallen()
        XCTAssertGreaterThan(g.punkte, p)
    }

    func testNachEndeReagiertNichtsMehr() {
        var g = spiel(5)
        while !g.vorbei { g.hartFallen() }
        let (x, f) = (g.ankerX, g.feld)
        XCTAssertFalse(g.bewege(1)); XCTAssertFalse(g.drehe()); g.hartFallen(); g.schritt(1)
        XCTAssertEqual(g.ankerX, x); XCTAssertEqual(g.feld, f)
    }

    func testKurveOhneSpruenge() {
        var g = spiel(); var letzte = g.fallZeit
        for stufe in 1..<30 {
            g.setzeReihen(stufe * 6)
            let verhaeltnis = g.fallZeit / letzte
            XCTAssertGreaterThan(verhaeltnis, 0.6, "Stufe \(stufe): Tempo springt zu stark")
            XCTAssertLessThanOrEqual(verhaeltnis, 1.0)
            letzte = g.fallZeit
        }
        g.setzeReihen(6 * 40); XCTAssertGreaterThan(g.fallZeit, 0.085, "bleibt spielbar (Landezeit 0,45 s)")
        // Ein Mensch (≈ 0,25 s je Griff) kommt auch auf Stufe 10 noch zurecht: Fallzeit je Feld ≥ 0,1 s
        g.setzeReihen(6 * 9); XCTAssertGreaterThanOrEqual(g.fallZeit, 0.1)
    }

    // MARK: Speichern und Fortsetzen
    func testSpeichernUndFortsetzenGleichesSpiel() throws {
        var a = Steinfall(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<600 { a.schritt(1.0 / 120) }
        let daten = try JSONEncoder().encode(a)
        var b = try JSONDecoder().decode(Steinfall.self, from: daten)
        XCTAssertEqual(a, b)
        // Danach verhalten sich beide gleich (auch der Zufall wurde gespeichert)
        for _ in 0..<600 { a.schritt(1.0 / 120); b.schritt(1.0 / 120) }
        XCTAssertEqual(a, b)
    }
    func testGespeichertePartieBleibtLaufend() throws {
        var a = Steinfall(zufall: ArcadeZufall(startwert: 7)); a.starte()
        for _ in 0..<60 { a.schritt(1.0 / 120) }
        let b = try JSONDecoder().decode(Steinfall.self, from: JSONEncoder().encode(a))
        XCTAssertEqual(b.phase, a.phase)
        XCTAssertEqual(b.phase, .laeuft)
    }
    func testKaputterStandWirdAbgelehnt() {
        XCTAssertThrowsError(try JSONDecoder().decode(Steinfall.self, from: Data("{\"x\":1}".utf8)))
    }

    // MARK: Stufen (leicht / mittel / schwer)
    func testSchwerIstSchnellerAlsLeicht() {
        func wert(_ st: Int) -> Double { let g = Steinfall(schwierigkeit: st, zufall: ArcadeZufall(startwert: 3)); return 1 / g.fallZeit }
        XCTAssertLessThan(wert(1), wert(2)); XCTAssertLessThan(wert(2), wert(3))
    }
    func testStufeWirdBegrenzt() {
        XCTAssertEqual(Steinfall(schwierigkeit: 9).schwierigkeit, 3)
        XCTAssertEqual(Steinfall(schwierigkeit: -4).schwierigkeit, 1)
    }

    // MARK: Fehlerjagd
    func testZufallseingabenBleibenImFeldUndStabil() {
        for seed in 1...10 as ClosedRange<UInt64> {
            var g = Steinfall(schwierigkeit: Int(seed % 3) + 1, zufall: ArcadeZufall(startwert: seed))
            var z = ArcadeZufall(startwert: seed &* 5); g.starte()
            for i in 0..<(120 * 200) {
                if i % 15 == 0 {
                    switch z.ganz(0...4) { case 0: g.bewege(-1); case 1: g.bewege(1); case 2: g.drehe(); case 3: g.weich = z.wahr(0.5); default: if z.wahr(0.2) { g.hartFallen() } }
                }
                g.schritt(1.0 / 120)
                for c in g.aktuelleFelder where !g.vorbei { XCTAssertTrue(c.x >= 0 && c.x < Steinfall.breite && c.y < Steinfall.hoehe, "Teil ausserhalb Seed \(seed)") }
                XCTAssertEqual(g.feld.count, Steinfall.hoehe)
                if g.vorbei { break }
            }
        }
    }
    func testStufenwechselBeschleunigtStetig() {
        var g = Steinfall(zufall: ArcadeZufall(startwert: 1)); var letzte = g.fallZeit
        for n in stride(from: 0, through: 120, by: 6) { g.setzeReihen(n); XCTAssertLessThanOrEqual(g.fallZeit, letzte + 1e-12); letzte = g.fallZeit }
        XCTAssertGreaterThan(letzte, 0.05)
    }

    // MARK: Leistung
    func testRechenzeitProSchritt() {
        var g = Steinfall(schwierigkeit: 3, zufall: ArcadeZufall(startwert: 11)); g.starte(); g.setzeReihen(200)
        var z = ArcadeZufall(startwert: 3)
        let n = 120 * 120
        let t0 = ContinuousClock.now
        for i in 0..<n {
            if i % 8 == 0 { _ = g.schatten; if z.wahr(0.3) { g.hartFallen() } else { g.bewege(z.wahr(0.5) ? 1 : -1); g.drehe() } }
            g.schritt(1.0 / 120)
            if g.vorbei { g = Steinfall(schwierigkeit: 3, zufall: ArcadeZufall(startwert: UInt64(i))); g.starte(); g.setzeReihen(200) }
        }
        let d = ContinuousClock.now - t0
        let ms = Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15
        print("LEISTUNG Steinfall: \(ms / Double(n)) ms pro Schritt")
        XCTAssertLessThan(ms / Double(n), 2.0)   // großzügig (Debug-Build, belasteter Mac); gemessen < 0,1 ms
    }

    // MARK: Schwierigkeitskurve je Stufe (Bot mit Platzierung)
    /// Bewertung einer Stellung nach dem Ablegen (klassische Gewichte): niedrig, ohne Löcher, eben, mit gelösten Reihen.
    private func wert(_ g: Steinfall, reihenVorher: Int) -> Double {
        var hoehe = [Int](repeating: 0, count: Steinfall.breite), loecher = 0
        for x in 0..<Steinfall.breite {
            var gefunden = false
            for y in 0..<Steinfall.hoehe {
                if g.feld[y][x] != 0 { if !gefunden { hoehe[x] = Steinfall.hoehe - y; gefunden = true } }
                else if gefunden { loecher += 1 }
            }
        }
        let rauheit = (1..<Steinfall.breite).map { abs(hoehe[$0] - hoehe[$0 - 1]) }.reduce(0, +)
        return -0.51 * Double(hoehe.reduce(0, +)) + 0.76 * Double(g.reihen - reihenVorher) - 0.36 * Double(loecher) - 0.18 * Double(rauheit)
    }

    /// Bester Platz (Drehungen, Zielspalte) für das aktuelle Teil.
    private func plane(_ g: Steinfall) -> (drehungen: Int, x: Int) {
        var best = (drehungen: 0, x: g.ankerX), bestWert = -Double.infinity
        for r in 0..<4 {
            var c = g; var ok = true
            for _ in 0..<r { if !c.drehe() { ok = false } }
            if !ok { continue }
            for richtung in [-1, 1] {
                var d = c
                while true {
                    var e = d; e.hartFallen()
                    let w = wert(e, reihenVorher: g.reihen)
                    if w > bestWert { bestWert = w; best = (r, d.ankerX) }
                    if !d.bewege(richtung) { break }
                }
            }
        }
        return best
    }

    /// Spielt `sekunden` Spielzeit: eine Handlung alle 0,3 s (Drehen/Verschieben), dann nach unten ziehen. Liefert (überlebte Zeit, Reihen).
    private func spieleBot(stufe: Int, seed: UInt64, sekunden: Double) -> (zeit: Double, reihen: Int) {
        var g = Steinfall(schwierigkeit: stufe, zufall: ArcadeZufall(startwert: seed)); g.starte()
        var plan = plane(g), gedreht = 0, letzteForm = g.form, letzteNaechste = g.naechste, n = 0
        let schritte = Int(sekunden * 120)
        while !g.vorbei && n < schritte {
            if g.form != letzteForm || g.naechste != letzteNaechste { plan = plane(g); gedreht = 0; letzteForm = g.form; letzteNaechste = g.naechste }
            if n % 36 == 0 {   // ein Mensch handelt etwa alle 0,3 s
                if gedreht < plan.drehungen { g.drehe(); gedreht += 1 }
                else if g.ankerX < plan.x { g.bewege(1) }
                else if g.ankerX > plan.x { g.bewege(-1) }
                else { g.weich = true }   // ausgerichtet: nach unten ziehen (kein Sofort-Fall)
            }
            g.schritt(1.0 / 120); n += 1
            if g.form != letzteForm { g.weich = false }
        }
        return (Double(n) / 120, g.reihen)
    }

    func testKurveJeStufe() {
        func mittel(_ st: Int) -> (Double, Double) { let r = (1...6).map { spieleBot(stufe: st, seed: UInt64($0), sekunden: 150) }; return (r.map(\.zeit).reduce(0, +) / 6, Double(r.map(\.reihen).reduce(0, +)) / 6) }
        let l = mittel(1), m = mittel(2), s = mittel(3)
        fputs("KURVE Steinfall (Zeit, Reihen): leicht \(l) mittel \(m) schwer \(s)\n", stderr)
        for w in [l, m, s] { XCTAssertGreaterThan(w.0, 10, "Keine Stufe darf nach wenigen Sekunden unspielbar sein") }
        XCTAssertGreaterThanOrEqual(l.0, s.0 - 1, "Leicht darf nicht kürzer dauern als Schwer")
        XCTAssertGreaterThanOrEqual(l.1, s.1 - 0.5, "Leicht soll nicht weniger Reihen bringen als Schwer")
        // Befund (Stand 08.11.): Leicht ca. 88 s / 21 Reihen, Mittel ca. 87 s / 20, Schwer ca. 84 s / 18 – die Reihenfolge stimmt,
        // der Abstand ist klein (ca. 4 %). Das Spiel endet vor allem durch Stapelfehler, nicht durch das Fallen.
    }
}
