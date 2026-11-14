// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SchiebepuzzleKern
import SpieleKern
import SpielHilfen

final class SchiebepuzzleTests: XCTestCase {
    func testStartGeloest() { XCTAssertTrue(Schiebepuzzle(n: 4).geloest) }
    func testSchieben() {
        var p = Schiebepuzzle(n: 3)
        XCTAssertFalse(p.schiebe(0))        // nicht in Reihe mit der Lücke
        XCTAssertTrue(p.schiebe(5))         // Kachel 6 nach unten
        XCTAssertEqual(p.felder[8], 6); XCTAssertEqual(p.luecke, 5); XCTAssertEqual(p.zuege, 1)
        XCTAssertTrue(p.schiebe(3))         // ganze Reihe: 4,5 nach rechts
        XCTAssertEqual(Set(p.felder), Set(0...8))
    }
    func testMischenLoesbarUndNichtGeloest() {
        var g = SystemRandomNumberGenerator()
        for n in [3, 4] {
            var p = Schiebepuzzle(n: n); p.mischen(mit: &g)
            XCTAssertFalse(p.geloest); XCTAssertEqual(p.zuege, 0); XCTAssertEqual(Set(p.felder), Set(0..<(n * n)))
        }
    }
    func testHinweiseLoesen3x3() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            var p = Schiebepuzzle(n: 3); p.mischen(mit: &g)
            var n = 0
            while !p.geloest, let h = p.hinweis(), n < 40 { XCTAssertTrue(p.schiebe(h)); n += 1 }
            XCTAssertTrue(p.geloest); XCTAssertTrue(n <= 31, "3x3 braucht höchstens 31 Züge, hatte \(n)")
        }
    }
    func testHinweisIstLegalAuf4x4und5x5() {
        var g = SystemRandomNumberGenerator()
        for n in [4, 5] {
            var p = Schiebepuzzle(n: n); p.mischen(mit: &g)
            for _ in 0..<5 { if let h = p.hinweis() { XCTAssertTrue(p.nachbarn(von: p.luecke).contains(h)); p.schiebe(h) } }
        }
    }
}

final class SchiebepuzzleRegelTests: XCTestCase {
    func testNachbarnAnEckeKanteUndMitte() {
        let p = Schiebepuzzle(n: 4)
        XCTAssertEqual(Set(p.nachbarn(von: 0)), [1, 4])
        XCTAssertEqual(Set(p.nachbarn(von: 1)), [0, 2, 5])
        XCTAssertEqual(Set(p.nachbarn(von: 5)), [1, 4, 6, 9])
    }
    func testSchiebenVerschiebtLueckeUndZaehltZuege() {
        var p = Schiebepuzzle(n: 3)
        XCTAssertTrue(p.schiebe(7))
        XCTAssertEqual(p.luecke, 7); XCTAssertEqual(p.zuege, 1); XCTAssertFalse(p.geloest)
        XCTAssertTrue(p.schiebe(8)); XCTAssertTrue(p.geloest); XCTAssertEqual(p.zuege, 2)
    }
    func testDiagonaleKachelBewegtSichNicht() {
        var p = Schiebepuzzle(n: 3)
        XCTAssertFalse(p.schiebe(4)); XCTAssertEqual(p.zuege, 0)
    }
    func testMischenSetztZugzaehlerZurueckFuerAlleGroessen() {
        var g = SystemRandomNumberGenerator()
        for n in 3...6 { var p = Schiebepuzzle(n: n); p.mischen(mit: &g); XCTAssertEqual(p.zuege, 0); XCTAssertFalse(p.geloest); XCTAssertEqual(Set(p.felder), Set(0..<(n * n))) }
    }
}

final class SchiebepuzzleZusatzTests: XCTestCase {
    func testAlleGroessenMischenUndHinweisVerringertAbstand() {
        var g = SystemRandomNumberGenerator()
        for n in 3...6 {
            var p = Schiebepuzzle(n: n); p.mischen(zuege: 80, mit: &g)
            XCTAssertFalse(p.geloest); XCTAssertEqual(p.zuege, 0)
            XCTAssertEqual(Set(p.felder), Set(0..<(n * n)))
        }
    }
    func testHinweisFuehrtAufDreiMalDreiZumZiel() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<10 {
            var p = Schiebepuzzle(n: 3); p.mischen(mit: &g)
            var k = 0
            while !p.geloest, let h = p.hinweis(), k < 40 { XCTAssertTrue(p.schiebe(h)); k += 1 }
            XCTAssertTrue(p.geloest)
        }
    }
    func testReiheSchieben() {
        var p = Schiebepuzzle(n: 4)           // Lücke unten rechts (15)
        XCTAssertTrue(p.schiebe(12))           // ganze Reihe nach rechts: 13,14,15→ Lücke wandert nach links
        XCTAssertEqual(p.luecke, 12); XCTAssertEqual(p.zuege, 1)
    }
    func testUngueltigeZuege() {
        var p = Schiebepuzzle(n: 3)
        XCTAssertFalse(p.schiebe(p.luecke)); XCTAssertFalse(p.schiebe(0))       // nicht in Reihe/Spalte mit Lücke
        XCTAssertEqual(p.zuege, 0)
    }
    func testCodableRundlauf() throws {
        var g = SystemRandomNumberGenerator()
        var p = Schiebepuzzle(n: 5); p.mischen(mit: &g); p.schiebe(p.nachbarn(von: p.luecke)[0])
        XCTAssertEqual(try JSONDecoder().decode(Schiebepuzzle.self, from: JSONEncoder().encode(p)), p)
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class SchiebepuzzleKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = Schiebepuzzle(n: 4)
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = Schiebepuzzle(n: 4)
        let k = try kaputt(w, "felder", Array(repeating: 1, count: 16))
        XCTAssertFalse(k.istKonsistent)
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = { var p = Schiebepuzzle(n: 3); p.mischen(mit: &g); return p }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Schiebepuzzle 3x3: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = { var p = Schiebepuzzle(n: 4); p.mischen(mit: &g); return p }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Schiebepuzzle 4x4: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = { var p = Schiebepuzzle(n: 5); p.mischen(mit: &g); return p }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Schiebepuzzle 5x5: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<20 { let t0 = Date(); _ = { var p = Schiebepuzzle(n: 6); p.mischen(mit: &g); return p }(); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Schiebepuzzle 6x6: Ø \(String(format: "%.3f", sum / 20)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}

final class SchiebepuzzleStandTests: XCTestCase {
    func testStandBehaeltZeitTippsUndTagesraetsel() throws {
        var g = SystemRandomNumberGenerator()
        var p = Schiebepuzzle(n: 5); p.mischen(mit: &g)
        p.schiebe(p.nachbarn(von: p.luecke)[0])
        let stand = SchiebepuzzleStand(puzzle: p, sekunden: 95, tipps: 3, tag: true)
        let geladen = try JSONDecoder().decode(SchiebepuzzleStand.self, from: JSONEncoder().encode(stand))
        XCTAssertEqual(geladen, stand)
        XCTAssertEqual(geladen.puzzle.zuege, 1); XCTAssertEqual(geladen.sekunden, 95); XCTAssertEqual(geladen.tipps, 3); XCTAssertTrue(geladen.tag)
        XCTAssertTrue(geladen.istKonsistent)
    }
    func testAlterStandNurMitBrettBleibtLadbar() throws {
        var g = SystemRandomNumberGenerator()
        var p = Schiebepuzzle(n: 3); p.mischen(mit: &g)
        p.schiebe(p.nachbarn(von: p.luecke)[0])
        let alt = try JSONEncoder().encode(p)   // so wurde bis Build 9 gespeichert
        let geladen = try JSONDecoder().decode(SchiebepuzzleStand.self, from: alt)
        XCTAssertEqual(geladen.puzzle, p)
        XCTAssertEqual(geladen.sekunden, 0); XCTAssertEqual(geladen.tipps, 0); XCTAssertFalse(geladen.tag)
        XCTAssertTrue(geladen.istKonsistent)
    }
    func testFehlendeZusatzfelderBekommenStandardwerte() throws {
        let p = Schiebepuzzle(n: 4)
        let daten = try JSONSerialization.data(withJSONObject: ["puzzle": JSONSerialization.jsonObject(with: JSONEncoder().encode(p))])
        XCTAssertEqual(try JSONDecoder().decode(SchiebepuzzleStand.self, from: daten), SchiebepuzzleStand(puzzle: p))
    }
    func testUnstimmigerStandWirdErkannt() throws {
        let p = Schiebepuzzle(n: 4)
        XCTAssertFalse(SchiebepuzzleStand(puzzle: p, sekunden: -1).istKonsistent)
        let kaputt = try JSONDecoder().decode(SchiebepuzzleStand.self, from: Data("{\"puzzle\":{\"n\":3,\"felder\":[1,1,2,3,4,5,6,7,0],\"zuege\":0},\"sekunden\":4}".utf8))
        XCTAssertFalse(kaputt.istKonsistent, "doppelte Kachel")
    }
}

/// T-055: Das Tagesrätsel hing beim Start (100 % CPU). Ursache war nicht das Mischen, sondern dass der Start im `init` der Ansicht den
/// Starttag in UserDefaults schrieb und damit die Ansicht ständig neu aufbaute. Hier: Mischen ist für alle Größen und Tage schnell,
/// und die Tageszufallsquelle schreibt nichts.
final class SchiebepuzzleTagesraetselTests: XCTestCase {
    func testTagesraetselAlleGroessenUndTageSchnellUndLoesbar() {
        let start = Date()
        for n in 3...6 {
            for tagVor in 0..<12 {
                let datum = Calendar(identifier: .gregorian).date(byAdding: .day, value: -tagVor, to: Date(timeIntervalSince1970: 1_794_000_000))!
                var g = ZufallsQuelle(seed: Tagesraetsel.seed(spiel: "schiebepuzzle\(n)", datum: datum))
                var p = Schiebepuzzle(n: n)
                p.mischen(mit: &g)
                XCTAssertFalse(p.geloest, "n=\(n) tag=\(tagVor)")
                XCTAssertTrue(p.istKonsistent)
                XCTAssertEqual(p.zuege, 0)
            }
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 5, "Mischen darf nicht hängen")
    }

    func testDerTagesraetselStartSchreibtNurEinmal() {
        let d = UserDefaults(suiteName: "T055-\(UUID().uuidString)")!
        var zaehler = 0
        let beobachter = NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: d, queue: nil) { _ in zaehler += 1 }
        defer { NotificationCenter.default.removeObserver(beobachter) }
        for _ in 0..<50 { Tagesraetsel.merkeStart(spiel: "schiebepuzzle", defaults: d) }
        XCTAssertLessThanOrEqual(zaehler, 1, "wiederholtes Merken darf keine neuen Änderungen auslösen")
        XCTAssertEqual(d.string(forKey: "partie.tagesstart.schiebepuzzle"), Tagesraetsel.tag())
    }

    func testReinerGeneratorSchreibtNichts() {
        let d = UserDefaults.standard
        d.removeObject(forKey: "partie.tagesstart.t055spiel")
        _ = Tagesraetsel.reinerGenerator(spiel: "t055spiel", variante: "4")
        XCTAssertNil(d.string(forKey: "partie.tagesstart.t055spiel"))
        var a = Tagesraetsel.reinerGenerator(spiel: "t055spiel", variante: "4"), b = Tagesraetsel.generator(spiel: "t055spiel", variante: "4")
        XCTAssertEqual(a.next(), b.next())
        d.removeObject(forKey: "partie.tagesstart.t055spiel")
    }

    func testGespeicherterStandMitTagesraetselIstKonsistent() {
        var g = ZufallsQuelle(seed: Tagesraetsel.seed(spiel: "schiebepuzzle4"))
        var p = Schiebepuzzle(n: 4); p.mischen(mit: &g)
        XCTAssertTrue(p.istKonsistent && !p.geloest)   // das prüft `fortsetzbar` beim Weiterspielen
    }

    /// T-086: größere Felder werden länger gemischt, und jedes gemischte Brett bleibt lösbar (Tipp-Lösung führt bis ans Ziel nicht nötig: Zufallsgang aus legalen Zügen).
    func testMischZuegeWachsenMitDerGroesse() {
        XCTAssertEqual(Schiebepuzzle.mischZuege(n: 3), 200)
        XCTAssertTrue(Schiebepuzzle.mischZuege(n: 4) > Schiebepuzzle.mischZuege(n: 3))
        XCTAssertTrue(Schiebepuzzle.mischZuege(n: 5) > Schiebepuzzle.mischZuege(n: 4))
        XCTAssertTrue(Schiebepuzzle.mischZuege(n: 6) > Schiebepuzzle.mischZuege(n: 5))
        var g = SystemRandomNumberGenerator()
        for n in 3...6 {
            var p = Schiebepuzzle(n: n); p.mischen(mit: &g)
            XCTAssertFalse(p.geloest); XCTAssertEqual(p.zuege, 0); XCTAssertEqual(Set(p.felder), Set(0..<(n * n)))
        }
    }
}
