// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import CoreGraphics
@testable import WuerfelLive

/// Fester Zufall, damit die Simulationen wiederholbar sind.
struct Zufall: RandomNumberGenerator {
    var s: UInt64
    init(_ saat: UInt64) { s = saat &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> UInt64 { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s }
}

/// Ein Tisch mit Würfeln und eine Kamera darüber, die sich verschiebt, dreht und den Abstand ändert.
/// Die „Erkennung“ liefert die Würfel mit Lagefehler, Aussetzern, Fehlwerten und Fehlfunden.
struct Szene {
    struct Wuerfel { var x: Double, y: Double, augen: Int }
    var wuerfel: [Wuerfel]
    var kante = 0.07                       // Würfelkante in Bildhöhen bei Maßstab 1
    var dx = 0.0, dy = 0.0, massstab = 1.0, winkel = 0.0
    var lagefehler = 0.0                   // in Würfelkanten
    var aussetzer = 0.0, fehlwert = 0.0, fehlfund = 0.0
    var zufall = Zufall(7)
    static let k = 9.0 / 16.0

    /// Lage eines Würfels im Bild (entzerrt, Einheit Bildhöhe), Kamera dreht um die Bildmitte.
    func imBild(_ w: Wuerfel) -> (Double, Double) {
        let cx = 0.5 * Self.k, cy = 0.5
        let x = (w.x - cx) * massstab, y = (w.y - cy) * massstab
        return (cx + x * cos(winkel) - y * sin(winkel) + dx, cy + x * sin(winkel) + y * cos(winkel) + dy)
    }

    mutating func aufnahme() -> [GesehenerWuerfel] {
        var liste: [GesehenerWuerfel] = []
        let s = kante * massstab
        for w in wuerfel {
            if Double.random(in: 0..<1, using: &zufall) < aussetzer { continue }
            var (x, y) = imBild(w)
            x += Double.random(in: -1...1, using: &zufall) * lagefehler * s
            y += Double.random(in: -1...1, using: &zufall) * lagefehler * s
            var augen = w.augen
            if Double.random(in: 0..<1, using: &zufall) < fehlwert { augen = Int.random(in: 1...6, using: &zufall) }
            liste.append(GesehenerWuerfel(augen: augen, rahmen: CGRect(x: (x - s / 2) / Self.k, y: y - s / 2, width: s / Self.k, height: s)))
        }
        if Double.random(in: 0..<1, using: &zufall) < fehlfund {
            let x = Double.random(in: 0.05...0.5, using: &zufall), y = Double.random(in: 0.05...0.95, using: &zufall)
            liste.append(GesehenerWuerfel(augen: Int.random(in: 1...6, using: &zufall), rahmen: CGRect(x: (x - s / 2) / Self.k, y: y - s / 2, width: s / Self.k, height: s)))
        }
        return liste
    }

    static func fuenf() -> Szene {
        Szene(wuerfel: [Wuerfel(x: 0.12, y: 0.30, augen: 2), Wuerfel(x: 0.30, y: 0.34, augen: 5), Wuerfel(x: 0.45, y: 0.31, augen: 6),
                        Wuerfel(x: 0.18, y: 0.55, augen: 1), Wuerfel(x: 0.38, y: 0.60, augen: 4)])
    }
}

final class VerfolgungTests: XCTestCase {
    private func w(_ augen: Int, x: Double, y: Double = 0.5, s: Double = 0.1) -> GesehenerWuerfel {
        GesehenerWuerfel(augen: augen, rahmen: CGRect(x: x, y: y, width: s, height: s * 9 / 16))
    }

    /// Nummern der sicheren Würfel zu ihren Werten.
    private func sichere(_ v: WuerfelVerfolger) -> [Int: Int] {
        Dictionary(uniqueKeysWithValues: v.anzeige.filter(\.sicher).map { ($0.id, $0.augen) })
    }

    // MARK: Mehrheit

    func testSicherNachWenigenGleichen() {
        var v = WuerfelVerfolger()
        XCTAssertTrue(v.verarbeite([w(3, x: 0.2)]).isEmpty, "ein einzelner Fund wird noch nicht gezeigt")
        XCTAssertEqual(v.verarbeite([w(3, x: 0.2)]).first?.sicher, false)
        v.verarbeite([w(3, x: 0.2)])
        XCTAssertEqual(v.verarbeite([w(3, x: 0.2)]).first?.sicher, true)
    }

    func testEinzelneFehlwerteVerhindernDieSicherheitNicht() {
        var v = WuerfelVerfolger()
        // Früher: nie fünf gleiche in Folge, also nie sicher. Jetzt entscheidet die Mehrheit.
        for a in [4, 4, 3, 4, 4, 5, 4, 4] { v.verarbeite([w(a, x: 0.3)]) }
        XCTAssertEqual(v.anzeige.first?.augen, 4)
        XCTAssertEqual(v.anzeige.first?.sicher, true)
    }

    func testFesterWertUeberstehtAusreisser() {
        var v = WuerfelVerfolger()
        for _ in 1...6 { v.verarbeite([w(4, x: 0.3)]) }
        for a in [3, 4, 6, 6, 4, 5, 3, 4] {
            let e = v.verarbeite([w(a, x: 0.3)])
            XCTAssertEqual(e.first?.augen, 4)
            XCTAssertEqual(e.first?.sicher, true)
        }
    }

    func testGedrehterWuerfelWechseltNachFuenfGleichen() {
        var v = WuerfelVerfolger()
        for _ in 1...20 { v.verarbeite([w(2, x: 0.3)]) }
        for _ in 1...4 { XCTAssertEqual(v.verarbeite([w(6, x: 0.3)]).first?.augen, 2) }
        let e = v.verarbeite([w(6, x: 0.3)])
        XCTAssertEqual(e.first?.augen, 6)
        XCTAssertEqual(e.first?.sicher, true)
    }

    func testEinzelbildIstSofortSicher() {
        var v = WuerfelVerfolger.einzelbild()
        let e = v.verarbeite([w(6, x: 0.7), w(1, x: 0.1), w(4, x: 0.4)])
        XCTAssertEqual(e.map(\.augen), [1, 4, 6])
        XCTAssertTrue(e.allesSicher)
        XCTAssertEqual(e.summe, 11)
    }

    // MARK: Wiedererkennung

    func testNummerBleibtBeiBewegung() {
        var v = WuerfelVerfolger()
        for _ in 1...5 { v.verarbeite([w(2, x: 0.20)]) }
        let id = v.anzeige.first!.id
        var x = 0.20
        for _ in 1...30 { x += 0.015; XCTAssertEqual(v.verarbeite([w(2, x: x)]).first?.id, id) }   // wandert über das halbe Bild
        XCTAssertEqual(v.anzeige.count, 1)
        XCTAssertEqual(v.anzeige.first?.sicher, true)
    }

    func testAussetzerWerdenUeberbrueckt() {
        var v = WuerfelVerfolger()
        for _ in 1...5 { v.verarbeite([w(5, x: 0.3)]) }
        let id = v.anzeige.first!.id
        for _ in 1...10 { XCTAssertEqual(v.verarbeite([]).first?.sicher, true) }
        XCTAssertEqual(v.verarbeite([w(5, x: 0.3)]).first?.id, id)
    }

    func testWuerfelVerschwindetNachGeduld() {
        var v = WuerfelVerfolger(geduld: 3)
        for _ in 1...5 { v.verarbeite([w(5, x: 0.3)]) }
        for _ in 1...4 { v.verarbeite([]) }
        XCTAssertTrue(v.anzeige.isEmpty)
    }

    func testEinzelnerFehlfundWirdNichtGezeigt() {
        var v = WuerfelVerfolger()
        for _ in 1...5 { v.verarbeite([w(5, x: 0.3)]) }
        XCTAssertEqual(v.verarbeite([w(5, x: 0.3), w(2, x: 0.7)]).count, 1)
        XCTAssertEqual(v.verarbeite([w(5, x: 0.3)]).count, 1)
    }

    func testFundMitFremderGroesseWirdKeinWuerfel() {
        var v = WuerfelVerfolger()
        for _ in 1...5 { v.verarbeite([w(5, x: 0.2), w(3, x: 0.5)]) }
        for _ in 1...5 { v.verarbeite([w(5, x: 0.2), w(3, x: 0.5), w(1, x: 0.8, s: 0.03)]) }   // Krümel
        XCTAssertEqual(v.anzeige.map(\.augen), [5, 3])
        for _ in 1...2 { v.verarbeite([w(5, x: 0.2), w(3, x: 0.5), w(1, x: 0.8)]) }             // dritter Würfel
        XCTAssertEqual(v.anzeige.map(\.augen), [5, 3, 1])
    }

    func testKorrekturUndFesthalten() {
        var v = WuerfelVerfolger()
        for _ in 1...2 { v.verarbeite([w(2, x: 0.2)]) }
        let id = v.anzeige.first!.id
        v.korrigiere(id: id, auf: 5)
        v.korrigiere(id: id, auf: 9)   // ungültig
        for _ in 1...20 { v.verarbeite([w(2, x: 0.2)]) }
        XCTAssertEqual(v.anzeige.first?.augen, 5)
        XCTAssertEqual(v.anzeige.first?.sicher, true)
        var f = WuerfelVerfolger()
        for _ in 1...2 { f.verarbeite([w(3, x: 0.3)]) }
        f.festhalten(id: f.anzeige.first!.id)
        for _ in 1...20 { f.verarbeite([w(5, x: 0.3)]) }
        XCTAssertEqual(f.anzeige.first?.augen, 3)
    }

    func testZoomVonHandBehaeltDieWuerfel() {
        var v = WuerfelVerfolger()
        var sz = Szene.fuenf()
        for _ in 1...6 { v.verarbeite(sz.aufnahme()) }
        let vorher = sichere(v)
        XCTAssertEqual(vorher.count, 5)
        v.zoome(um: 0.5)
        sz.massstab = 0.5
        for _ in 1...3 { v.verarbeite(sz.aufnahme()) }
        XCTAssertEqual(sichere(v), vorher)
    }

    // MARK: Simulation mit bewegter Kamera

    /// Lässt die Kamera `schritte` Auswertungen lang laufen; `bewege` verändert die Kamera vor jeder Aufnahme.
    private func laufe(_ sz: inout Szene, _ v: inout WuerfelVerfolger, schritte: Int, bewege: (inout Szene, Int) -> Void = { _, _ in }) {
        for i in 0..<schritte { bewege(&sz, i); v.verarbeite(sz.aufnahme()) }
    }

    private func pruefe(_ sz: Szene, _ v: WuerfelVerfolger, _ vorher: [Int: Int], datei: StaticString = #filePath, zeile: UInt = #line) {
        XCTAssertEqual(sichere(v), vorher, "Nummern und Werte müssen erhalten bleiben", file: datei, line: zeile)
        XCTAssertEqual(v.anzeige.count, sz.wuerfel.count, file: datei, line: zeile)
        XCTAssertEqual(v.anzeige.summe, sz.wuerfel.reduce(0) { $0 + $1.augen }, file: datei, line: zeile)
    }

    func testKameraSchwenk() {
        var sz = Szene.fuenf(), v = WuerfelVerfolger()
        laufe(&sz, &v, schritte: 6)
        let vorher = sichere(v)
        XCTAssertEqual(vorher.count, 5)
        // Schwenk: je Auswertung 0,4 Würfelkanten, insgesamt fast fünf Würfelkanten.
        laufe(&sz, &v, schritte: 12) { s, _ in s.dx += 0.006; s.dy += 0.027 }
        pruefe(sz, v, vorher)
    }

    func testHerauszoomenUndZurueck() {
        var sz = Szene.fuenf(), v = WuerfelVerfolger()
        laufe(&sz, &v, schritte: 6)
        let vorher = sichere(v)
        laufe(&sz, &v, schritte: 12) { s, _ in s.massstab *= 0.95 }   // Abstand fast verdoppelt
        XCTAssertLessThan(sz.massstab, 0.56)
        pruefe(sz, v, vorher)
        laufe(&sz, &v, schritte: 12) { s, _ in s.massstab /= 0.95 }
        pruefe(sz, v, vorher)
    }

    func testDrehenDerKamera() {
        var sz = Szene.fuenf(), v = WuerfelVerfolger()
        laufe(&sz, &v, schritte: 6)
        let vorher = sichere(v)
        laufe(&sz, &v, schritte: 20) { s, _ in s.winkel += 0.04 }   // 46° insgesamt
        pruefe(sz, v, vorher)
    }

    func testWackelndeHandMitAussetzernUndFehlwerten() {
        for saat in 1...300 as ClosedRange<UInt64> {
            var sz = Szene.fuenf(), v = WuerfelVerfolger()
            sz.zufall = Zufall(saat)
            sz.lagefehler = 0.06; sz.aussetzer = 0.2; sz.fehlwert = 0.15; sz.fehlfund = 0.2
            var hand = Zufall(saat &+ 100)
            // Die Hand zittert (bis 0,2 Würfelkanten je Auswertung) um ihre Ausgangslage.
            laufe(&sz, &v, schritte: 60) { s, _ in
                s.dx = 0.93 * s.dx + Double.random(in: -0.015...0.015, using: &hand); s.dy = 0.93 * s.dy + Double.random(in: -0.015...0.015, using: &hand)
                s.massstab *= Double.random(in: 0.985...1.015, using: &hand)
            }
            let e = v.anzeige.filter(\.sicher)
            XCTAssertEqual(e.count, 5, "Saat \(saat): alle fünf Würfel sicher")
            XCTAssertEqual(e.summe, 18, "Saat \(saat)")
            XCTAssertLessThanOrEqual(v.anzeige.count, 6, "Saat \(saat): höchstens ein kurzer Fehlfund")
            // Fünf Würfel, fünf Nummern über die ganze Zeit: keine Spur wurde neu angelegt.
            XCTAssertEqual(Set(e.map(\.id)).count, 5)
            XCTAssertLessThanOrEqual(e.map(\.id).max() ?? 99, 5 + 60, "Saat \(saat)")
        }
    }

    func testNummernBleibenBeiWackelnOhneStoerung() {
        var sz = Szene.fuenf(), v = WuerfelVerfolger()
        sz.lagefehler = 0.05
        laufe(&sz, &v, schritte: 6)
        let vorher = sichere(v)
        var hand = Zufall(3)
        laufe(&sz, &v, schritte: 80) { s, _ in
            s.dx += Double.random(in: -0.02...0.02, using: &hand); s.dy += Double.random(in: -0.02...0.02, using: &hand)
        }
        pruefe(sz, v, vorher)
    }

    func testUebersehenerWuerfelWandertMitDerKamera() {
        var sz = Szene.fuenf(), v = WuerfelVerfolger()
        laufe(&sz, &v, schritte: 6)
        let vorher = sichere(v)
        // Der erste Würfel wird während des Schwenks nicht erkannt und ist danach an anderer Stelle im Bild.
        let alle = sz.wuerfel
        sz.wuerfel = Array(alle.dropFirst())
        laufe(&sz, &v, schritte: 8) { s, _ in s.dy += 0.03 }
        sz.wuerfel = alle
        laufe(&sz, &v, schritte: 2)
        pruefe(sz, v, vorher)
    }

    func testEinWuerfelWirdVerschobenDieAnderenBleiben() {
        var sz = Szene.fuenf(), v = WuerfelVerfolger()
        laufe(&sz, &v, schritte: 6)
        let vorher = sichere(v)
        laufe(&sz, &v, schritte: 10) { s, _ in s.wuerfel[4].x += 0.012; s.wuerfel[4].y += 0.02 }
        pruefe(sz, v, vorher)
    }

    func testBewegungWirdGemeldet() {
        var sz = Szene.fuenf(), v = WuerfelVerfolger()
        laufe(&sz, &v, schritte: 4)
        XCTAssertEqual(v.bewegung ?? 1, 0, accuracy: 0.01)
        sz.dy += 0.035   // halbe Würfelkante
        v.verarbeite(sz.aufnahme())
        XCTAssertGreaterThan(v.bewegung ?? 0, 0.3)
        var leer = WuerfelVerfolger()
        leer.verarbeite([])
        XCTAssertNil(leer.bewegung)
    }
}

final class RuheTests: XCTestCase {
    func testMesserUndFilter() {
        var m = RuheMesser(), f = RuheFilter()
        let a = [UInt8](repeating: 100, count: 100), b = [UInt8](repeating: 140, count: 100)
        XCTAssertEqual(m.bewegung(a), 1)
        XCTAssertEqual(m.bewegung(a), 0)
        XCTAssertEqual(m.bewegung(b), 40.0 / 255, accuracy: 1e-9)
        XCTAssertFalse(f.beobachte(bewegung: 0.01))      // erst eine ruhige Auswertung
        XCTAssertTrue(f.beobachte(bewegung: 0.01))
        XCTAssertFalse(f.beobachte(bewegung: 0.2))       // wackelt sofort
        XCTAssertFalse(f.beobachte(bewegung: 0.01))
        XCTAssertTrue(f.beobachte(bewegung: 0.01))
    }
}

/// Von Hand ergänzte Würfel (Tipp auf einen übersehenen Würfel).
final class VerfolgerErgaenzenTests: XCTestCase {
    func testErgaenzterWuerfelIstSicherUndBleibt() {
        var v = WuerfelVerfolger.einzelbild()
        v.verarbeite([GesehenerWuerfel(augen: 3, rahmen: CGRect(x: 0.2, y: 0.4, width: 0.1, height: 0.056))])
        let id = v.fuegeHinzu(GesehenerWuerfel(augen: 5, rahmen: CGRect(x: 0.6, y: 0.4, width: 0.1, height: 0.056)))
        XCTAssertEqual(v.anzeige.count, 2)
        let neu = v.anzeige.first { $0.id == id }
        XCTAssertEqual(neu?.augen, 5); XCTAssertEqual(neu?.sicher, true)
        XCTAssertTrue(v.anzeige.allesSicher)
    }

    func testAnDerselbenStelleEntstehtKeinZweiterWuerfel() {
        var v = WuerfelVerfolger.einzelbild()
        v.verarbeite([GesehenerWuerfel(augen: 3, rahmen: CGRect(x: 0.2, y: 0.4, width: 0.1, height: 0.056))])
        let vorhanden = v.anzeige[0].id
        let id = v.fuegeHinzu(GesehenerWuerfel(augen: 6, rahmen: CGRect(x: 0.21, y: 0.41, width: 0.1, height: 0.056)))
        XCTAssertEqual(id, vorhanden)
        XCTAssertEqual(v.anzeige.count, 1)
        XCTAssertEqual(v.anzeige[0].augen, 3)
    }
}
