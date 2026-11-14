// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import IrrgangKern

final class IrrgangTests: XCTestCase {
    func testAlleZellenErreichbarOhneSchleifen() {
        var g = SystemRandomNumberGenerator()
        for st in 1...14 {
            let m = Irrgang(stufe: st, mit: &g)
            var kanten = 0
            for yy in 0..<m.hoehe { for xx in 0..<m.breite { kanten += m.anzahlOeffnungen(xx, yy) } }
            XCTAssertEqual(kanten / 2, m.breite * m.hoehe - 1, "Baum hat Zellen−1 Kanten")
            XCTAssertNotNil(m.kuerzesterWeg())
        }
    }
    func testWaendeStimmenBeidseitig() {
        var g = SystemRandomNumberGenerator(); let m = Irrgang(stufe: 5, mit: &g)
        for yy in 0..<m.hoehe { for xx in 0..<m.breite { for r in Richtung.allCases where m.offen[yy][xx][r.rawValue] {
            XCTAssertTrue(m.offen[yy + r.dy][xx + r.dx][r.gegenueber.rawValue])
        } } }
    }
    func testBewegenAnWandGeht_nicht() {
        var g = SystemRandomNumberGenerator(); var m = Irrgang(stufe: 1, mit: &g)
        XCTAssertFalse(m.bewege(.nord)); XCTAssertFalse(m.bewege(.west))
    }
    func testGleitenErreichtDasZiel() {
        var g = SystemRandomNumberGenerator()
        for st in [1, 4, 9] {
            var m = Irrgang(stufe: st, mit: &g); var n = 0
            while !m.imZiel && n < 5000 {
                // Bot: nimmt jede Richtung, die auf einem kürzesten Weg liegt
                let rest = m.kuerzesterWeg()!
                for r in Richtung.allCases where m.offen[m.y][m.x][r.rawValue] {
                    var k = m; k.bewege(r)
                    if k.kuerzesterWeg() == rest - 1 { m.bewege(r); break }
                }
                n += 1
            }
            XCTAssertTrue(m.imZiel)
            XCTAssertTrue(m.stufenPunkte() > 0)
        }
    }
    func testGleitenBleibtAufGerader() {
        var g = SystemRandomNumberGenerator()
        for st in [1, 3, 8] {
            for _ in 0..<30 {
                var m = Irrgang(stufe: st, mit: &g)
                for r in Richtung.allCases.shuffled() {
                    let x0 = m.x, y0 = m.y
                    let n = m.gleite(r)
                    XCTAssertEqual(m.x, x0 + r.dx * n); XCTAssertEqual(m.y, y0 + r.dy * n)   // nur geradeaus
                    if n > 0 && !m.imZiel {
                        // Danach geht es entweder nicht weiter oder es gibt eine Abzweigung / einen eingesammelten Funken
                        let weiter = m.offen[m.y][m.x][r.rawValue]
                        let seitlich = Richtung.allCases.contains { $0 != r && $0 != r.gegenueber && m.offen[m.y][m.x][$0.rawValue] }
                        XCTAssertTrue(!weiter || seitlich || m.gesammelt > 0)
                    }
                }
            }
        }
    }
    func testFunkenWerdenAufDemWegEingesammelt() {
        var g = SystemRandomNumberGenerator()
        var m = Irrgang(stufe: 2, mit: &g)
        let ziel = m.funken.first!
        // Weg zum Funken per Breitensuche ablaufen, Schritt für Schritt
        var weg: [Richtung] = []; var gesehen: Set<Int> = [0]; var queue: [(Int, Int, [Richtung])] = [(0, 0, [])]
        while !queue.isEmpty {
            let (x, y, w) = queue.removeFirst()
            if y * m.breite + x == ziel { weg = w; break }
            for r in Richtung.allCases where m.offen[y][x][r.rawValue] {
                let k = (y + r.dy) * m.breite + x + r.dx
                if gesehen.insert(k).inserted { queue.append((x + r.dx, y + r.dy, w + [r])) }
            }
        }
        for r in weg { m.bewege(r) }
        XCTAssertGreaterThan(m.gesammelt, 0)
    }
    func testSichtweite() {
        XCTAssertNil(Irrgang.sichtweite(stufe: 3)); XCTAssertEqual(Irrgang.sichtweite(stufe: 4), 5); XCTAssertEqual(Irrgang.sichtweite(stufe: 14), 2)
    }
    func testHinweisFuehrtInKuerzesterZeit() {
        var g = SystemRandomNumberGenerator()
        for st in [1, 4, 9] {
            var m = Irrgang(stufe: st, mit: &g)
            let kurz = m.kuerzesterWeg()!; var n = 0
            while !m.imZiel, let r = m.hinweisRichtung() { XCTAssertTrue(m.bewege(r)); n += 1 }
            XCTAssertEqual(n, kurz)
        }
    }
    func testZurueckNimmtEinenWischZurueckAberSchritteZaehlenWeiter() {
        var g = SystemRandomNumberGenerator()
        var m = Irrgang(stufe: 2, mit: &g)
        XCTAssertFalse(m.kannZurueck); XCTAssertFalse(m.zurueck())
        guard let r = Richtung.allCases.first(where: { m.offen[0][0][$0.rawValue] }) else { return XCTFail() }
        let n = m.gleite(r)
        XCTAssertGreaterThan(n, 0); XCTAssertTrue(m.kannZurueck)
        let schritte = m.schritte
        XCTAssertTrue(m.zurueck())
        XCTAssertEqual(m.x, 0); XCTAssertEqual(m.y, 0)
        XCTAssertEqual(m.schritte, schritte, "der Umweg zählt")
        XCTAssertFalse(m.kannZurueck)
    }
    func testZurueckGibtGesammelteFunkenFreiUndBesuchtWird() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            var m = Irrgang(stufe: 3, mit: &g)
            let funken0 = m.funken, besucht0 = m.besucht
            var zuege = 0
            while zuege < 300, !m.imZiel, let r = Richtung.allCases.shuffled(using: &g).first(where: { m.offen[m.y][m.x][$0.rawValue] }) { m.gleite(r); zuege += 1 }
            while m.kannZurueck { m.zurueck() }
            XCTAssertEqual(m.funken, funken0); XCTAssertEqual(m.gesammelt, 0); XCTAssertEqual(m.besucht, besucht0)
            XCTAssertEqual(m.x, 0); XCTAssertEqual(m.y, 0)
        }
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class IrrgangKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = { var g = SystemRandomNumberGenerator(); return Irrgang(stufe: 1, mit: &g) }()
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = { var g = SystemRandomNumberGenerator(); return Irrgang(stufe: 1, mit: &g) }()
        let k = try kaputt(w, "breite", 99)
        XCTAssertFalse(k.istKonsistent)
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Irrgang(stufe: 1, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Irrgang Stufe 1: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Irrgang(stufe: 5, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Irrgang Stufe 5: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Irrgang(stufe: 10, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Irrgang Stufe 10: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Irrgang(stufe: 14, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Irrgang Stufe 14: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = Irrgang(stufe: 20, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Irrgang Stufe 20: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}

final class IrrgangZusatzTests: XCTestCase {
    func testRichtungenSindPaarweiseGegenueber() {
        for r in Richtung.allCases { XCTAssertEqual(r.gegenueber.gegenueber, r); XCTAssertEqual(r.dx + r.gegenueber.dx, 0); XCTAssertEqual(r.dy + r.gegenueber.dy, 0) }
    }
    func testGroesseWaechstMitDerStufeUndIstBeiVierzehnGedeckelt() {
        XCTAssertLessThan(Irrgang.groesse(stufe: 1).b, Irrgang.groesse(stufe: 5).b)
        XCTAssertEqual(Irrgang.groesse(stufe: 14).b, Irrgang.groesse(stufe: 30).b)
    }
    func testSichtweiteGiltErstAbStufeVierUndSchrumpft() {
        XCTAssertNil(Irrgang.sichtweite(stufe: 3)); XCTAssertNotNil(Irrgang.sichtweite(stufe: 4))
        XCTAssertGreaterThanOrEqual(Irrgang.sichtweite(stufe: 4)!, Irrgang.sichtweite(stufe: 20)!)
    }
    func testStartPunktIstNichtDasZielUndSchritteStartenBeiNull() {
        var g = SystemRandomNumberGenerator()
        let l = Irrgang(stufe: 1, mit: &g)
        XCTAssertFalse(l.imZiel); XCTAssertEqual(l.schritte, 0); XCTAssertEqual(l.x, 0); XCTAssertEqual(l.y, 0)
    }
}
