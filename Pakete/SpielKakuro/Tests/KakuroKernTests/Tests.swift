// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import KakuroKern

final class KakuroTests: XCTestCase {
    func testGenerierung() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<4 {
            var k = Kakuro.zufaellig(mit: &g)
            XCTAssertFalse(k.geloest)
            k.loesen(); XCTAssertTrue(k.geloest); XCTAssertTrue(k.fehlerFelder().isEmpty)
            for l in k.laeufe { XCTAssertTrue((2...9).contains(l.felder.count)); XCTAssertTrue(l.summe >= 3 && l.summe <= 45) }
        }
    }
    func testFehler() {
        var g = SystemRandomNumberGenerator(); var k = Kakuro.zufaellig(mit: &g)
        guard let l = k.laeufe.first(where: { l in l.felder.filter { !k.vorgaben.contains($0) }.count >= 2 }) else { return }
        let fr = l.felder.filter { !k.vorgaben.contains($0) }
        k.setze(fr[0], 5); k.setze(fr[1], 5)
        XCTAssertTrue(k.fehlerFelder().contains(fr[0]))
    }
    func testSetzenNurAufWeissenFeldernUndGueltigeZahlen() {
        var g = SystemRandomNumberGenerator(); var k = Kakuro.zufaellig(mit: &g)
        let block = k.weiss.firstIndex(of: false)!
        k.setze(block, 5); XCTAssertEqual(k.eintrag[block], 0)
        let w = k.weiss.indices.first { k.weiss[$0] && !k.vorgaben.contains($0) }!
        k.setze(w, 10); XCTAssertEqual(k.eintrag[w], 0)
        k.setze(w, -1); XCTAssertEqual(k.eintrag[w], 0)
        k.setze(w, 7); XCTAssertEqual(k.eintrag[w], 7); k.setze(w, 0); XCTAssertEqual(k.eintrag[w], 0)
    }
    func testZuGrosseSummeIstFehler() {
        let laeufe = [KakuroLauf(felder: [1, 2], summe: 4, waagrecht: true, startFeld: 0)]
        var k = Kakuro(n: 3, weiss: [false, true, true, false, false, false, false, false, false], laeufe: laeufe, loesung: [0, 1, 3, 0, 0, 0, 0, 0, 0])
        k.setze(1, 9); XCTAssertEqual(k.fehlerFelder(), [1])
        k.setze(2, 3); XCTAssertEqual(k.fehlerFelder(), [1, 2]); XCTAssertFalse(k.geloest)
        k.setze(1, 1); XCTAssertTrue(k.geloest); XCTAssertTrue(k.fehlerFelder().isEmpty)
    }
    func testLaufMitDoppelterZahlIstNichtErfuellt() {
        let l = KakuroLauf(felder: [1, 2], summe: 4, waagrecht: true, startFeld: 0)
        var k = Kakuro(n: 3, weiss: [false, true, true, false, false, false, false, false, false], laeufe: [l], loesung: [0, 1, 3, 0, 0, 0, 0, 0, 0])
        k.setze(1, 2); k.setze(2, 2)
        XCTAssertFalse(k.laufErfuellt(l)); XCTAssertFalse(k.geloest)
    }
    func testKandidatenEnthaltenDieLoesung() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<3 {
            var k = Kakuro.zufaellig(mit: &g)
            for f in k.weiss.indices where k.weiss[f] { XCTAssertTrue(k.kandidaten(f).contains(k.loesung[f])) }
            // Mit einigen richtigen Einträgen bleibt die Lösungsziffer erlaubt
            for f in k.weiss.indices.filter({ k.weiss[$0] }).prefix(6) { k.setze(f, k.loesung[f]) }
            for f in k.weiss.indices where k.weiss[f] && k.eintrag[f] == 0 { XCTAssertTrue(k.kandidaten(f).contains(k.loesung[f])) }
        }
    }
    func testTippLoestDasRaetsel() {
        var g = SystemRandomNumberGenerator(); var k = Kakuro.zufaellig(mit: &g)
        var n = 0
        while k.tipp(bevorzugt: nil, mit: &g) != nil { n += 1 }
        XCTAssertTrue(k.geloest); XCTAssertEqual(n, k.weiss.filter { $0 }.count - k.vorgaben.count)
    }
    func testGleicherStartwertGleichesRaetsel() {
        var a = TestGenerator(s: 5), b = TestGenerator(s: 5)
        XCTAssertEqual(Kakuro.zufaellig(n: 5, mit: &a), Kakuro.zufaellig(n: 5, mit: &b))
    }
}

struct TestGenerator: RandomNumberGenerator {
    var s: UInt64
    mutating func next() -> UInt64 { s &+= 0x9E3779B97F4A7C15; var z = s; z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9; z = (z ^ (z >> 27)) &* 0x94D049BB133111EB; return z ^ (z >> 31) }
}

final class KakuroLoesbarTests: XCTestCase {
    func testJedesRaetselHatGenauEineLoesung() {
        var g = TestGenerator(s: 11)
        for n in [4, 5, 6] { for _ in 0..<2 {
            let k = Kakuro.zufaellig(n: n, mit: &g)
            XCTAssertEqual(k.loesungenOderNil(grenze: 2), 1, "n=\(n)")
            var l = k; l.loesen(); XCTAssertTrue(l.geloest)
            XCTAssertFalse(k.geloest)
            XCTAssertTrue(k.vorgaben.allSatisfy { k.weiss[$0] && k.eintrag[$0] == k.loesung[$0] })
            XCTAssertLessThan(k.vorgaben.count, k.weiss.filter { $0 }.count, "nicht alles vorgegeben")
        } }
    }
    func testVorgabenLassenSichNichtAendern() {
        var g = TestGenerator(s: 4)
        var k = Kakuro.zufaellig(n: 5, mit: &g)
        guard let v = k.vorgaben.first else { return }
        let z = k.eintrag[v]; k.setze(v, z % 9 + 1)
        XCTAssertEqual(k.eintrag[v], z)
    }
    func testZaehlerErkenntMehrdeutigkeit() {
        let l1 = KakuroLauf(felder: [1, 2], summe: 3, waagrecht: true, startFeld: 0)
        let k = Kakuro(n: 3, weiss: [false, true, true, false, false, false, false, false, false], laeufe: [l1], loesung: [0, 1, 2, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(k.loesungen(), 2)
        let k1 = Kakuro(n: 3, weiss: k.weiss, laeufe: [l1], loesung: [0, 1, 2, 0, 0, 0, 0, 0, 0], vorgaben: [1])
        XCTAssertEqual(k1.loesungen(), 1)
    }
}

/// Ändert einen Schlüssel im kodierten Zustand und liest ihn zurück – so entsteht ein absichtlich kaputter Spielstand.
private func kaputt<T: Codable>(_ w: T, _ schluessel: String, _ wert: Any) throws -> T {
    var d = try JSONSerialization.jsonObject(with: JSONEncoder().encode(w)) as! [String: Any]
    d[schluessel] = wert
    return try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: d))
}

final class KakuroKonsistenzTests: XCTestCase {
    func testGesunderStandIstKonsistent() {
        let w = { var g = SystemRandomNumberGenerator(); return Kakuro.zufaellig(n: 5, mit: &g) }()
        XCTAssertTrue(w.istKonsistent)
    }
    func testKaputterStandWirdErkannt() throws {
        let w = { var g = SystemRandomNumberGenerator(); return Kakuro.zufaellig(n: 5, mit: &g) }()
        let k = try kaputt(w, "eintrag", [1, 2])
        XCTAssertFalse(k.istKonsistent)
    }
}

final class SchwierigkeitMessung: XCTestCase {
    func testStufen() {
        var g = SystemRandomNumberGenerator()
        for n in [5, 6, 7] {
            var weiss = 0.0, vor = 0.0, laeufe = 0.0
            for _ in 0..<15 { let k = Kakuro.zufaellig(n: n, mit: &g); weiss += Double(k.weiss.filter { $0 }.count); vor += Double(k.vorgaben.count); laeufe += Double(k.laeufe.count) }
            print("MESS Kakuro \(n)x\(n): weiße Felder Ø \(String(format: "%.1f", weiss / 15)), Vorgaben Ø \(String(format: "%.1f", vor / 15)), Läufe Ø \(String(format: "%.1f", laeufe / 15))")
        }
    }
}

final class ErzeugungsZeit: XCTestCase {
    func testZeiten() {
        var g = SystemRandomNumberGenerator()
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<10 { let t0 = Date(); _ = Kakuro.zufaellig(n: 5, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Kakuro 5x5: Ø \(String(format: "%.3f", sum / 10)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<10 { let t0 = Date(); _ = Kakuro.zufaellig(n: 6, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Kakuro 6x6: Ø \(String(format: "%.3f", sum / 10)) s, max \(String(format: "%.3f", mx)) s")
        }
        do {
            var mx = 0.0, sum = 0.0
            for _ in 0..<10 { let t0 = Date(); _ = Kakuro.zufaellig(n: 7, mit: &g); let d = Date().timeIntervalSince(t0); mx = max(mx, d); sum += d }
            print("ZEIT Kakuro 7x7: Ø \(String(format: "%.3f", sum / 10)) s, max \(String(format: "%.3f", mx)) s")
        }
    }
}

final class KakuroRandfaelle: XCTestCase {
    func testKaputterStandOhneLaeufeIstNichtGeloestUndNichtKonsistent() throws {
        var g = SystemRandomNumberGenerator()
        let k = Kakuro.zufaellig(n: 5, mit: &g)
        let leer = try kaputt(k, "laeufe", [Any]())
        XCTAssertFalse(leer.geloest, "ohne Läufe darf nichts als gelöst gelten")
        XCTAssertFalse(leer.istKonsistent)
    }
    func testVorgabeFeldMitFalschemEintragIstNichtKonsistent() throws {
        var g = SystemRandomNumberGenerator()
        let k = Kakuro.zufaellig(n: 5, mit: &g)
        guard let v = k.vorgaben.first else { return }
        var e = k.eintrag; e[v] = 0
        XCTAssertFalse(try kaputt(k, "eintrag", e).istKonsistent, "Vorgaben sind nicht änderbar: ein leeres Vorgabefeld wäre unlösbar")
    }
    func testGeloestNachLoesenUndEntlerenNicht() {
        var g = SystemRandomNumberGenerator()
        var k = Kakuro.zufaellig(n: 5, mit: &g)
        XCTAssertFalse(k.geloest); k.loesen(); XCTAssertTrue(k.geloest)
        if let f = (0..<25).first(where: { k.weiss[$0] && !k.vorgaben.contains($0) }) { k.setze(f, 0); XCTAssertFalse(k.geloest) }
    }
}

final class KakuroIndexSchutz: XCTestCase {
    func testUngueltigesFeldIstWirkungslos() {
        var g = SystemRandomNumberGenerator()
        var k = Kakuro.zufaellig(n: 5, mit: &g)
        let vorher = k.eintrag
        k.setze(999, 3); k.setze(-1, 3)
        XCTAssertEqual(k.eintrag, vorher)
    }
}

final class ErzeugungsZeitSchwanz: XCTestCase {
    func testSchwanz() {
        var g = SystemRandomNumberGenerator()
        var zeiten: [Double] = []
        for _ in 0..<150 { let t = Date(); _ = Kakuro.zufaellig(n: 7, mit: &g); zeiten.append(Date().timeIntervalSince(t)) }
        zeiten.sort()
        print("ZEIT Kakuro 7x7: Median \(String(format: "%.3f", zeiten[zeiten.count / 2])) s, 95% \(String(format: "%.3f", zeiten[zeiten.count * 95 / 100])) s, max \(String(format: "%.3f", zeiten.last!)) s")
    }
}

final class KakuroEindeutigTrotzKnappemLimit: XCTestCase {
    func testErzeugteRaetselSindEindeutig() {
        var g = SystemRandomNumberGenerator()
        for n in [5, 6, 7] { for _ in 0..<6 {
            let k = Kakuro.zufaellig(n: n, mit: &g)
            XCTAssertEqual(k.loesungenOderNil(grenze: 2, schrittLimit: 5_000_000), 1, "\(n)x\(n)")
        } }
    }
}

/// SplitMix64: kleiner, fester Zufall für Tests (wie die Tagesrätsel-Quelle, aber ohne Abhängigkeit vom Spielpaket).
struct FesterZufall: RandomNumberGenerator {
    var zustand: UInt64
    init(seed: UInt64) { zustand = seed }
    mutating func next() -> UInt64 {
        zustand &+= 0x9E3779B97F4A7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Tagesrätsel von Kakuro: Der Erzeuger wird mit festen Seeds gefüttert (wie `Tagesraetsel.generator`) und muss immer ein
/// eindeutig lösbares, in sich stimmiges Rätsel liefern, in jeder Größe, und mit gleichem Seed dasselbe.
final class KakuroTagesraetselSeeds: XCTestCase {
    private func rätsel(n: Int, seed: UInt64) -> Kakuro {
        var g = FesterZufall(seed: seed)
        return Kakuro.zufaellig(n: n, mit: &g)
    }

    func testFesteSeedsSindEindeutigUndStabil() {
        for (n, seeds) in [(5, [UInt64(20261108), 20280229, 99999]), (6, [20261108, 20280229, 99999]), (7, [20261108])] {
            for seed in seeds {
                let k = rätsel(n: n, seed: seed)
                XCTAssertEqual(k.loesungenOderNil(grenze: 2, schrittLimit: 5_000_000), 1, "n=\(n) seed=\(seed) nicht eindeutig")
                XCTAssertTrue(k.istKonsistent, "n=\(n) seed=\(seed)")
                XCTAssertFalse(k.geloest, "ein frisches Rätsel darf nicht gelöst sein")
                var voll = k; voll.loesen()
                XCTAssertTrue(voll.geloest, "n=\(n) seed=\(seed): Lösung muss gelten")
                XCTAssertEqual(k, rätsel(n: n, seed: seed), "n=\(n) seed=\(seed): gleicher Seed muss dasselbe Rätsel geben")
            }
        }
    }

    func testVerschiedeneTageGebenVerschiedeneRaetsel() {
        let a = rätsel(n: 6, seed: 20261108), b = rätsel(n: 6, seed: 20261109)
        XCTAssertNotEqual(a.weiss, b.weiss)
    }
}

final class KakuroPruefenTests: XCTestCase {
    func testFalscheEintraegeNurFuerAusgefuellteUndNichtVorgaben() {
        var g = SystemRandomNumberGenerator()
        var k = Kakuro.zufaellig(n: 5, mit: &g)
        XCTAssertTrue(k.falscheEintraege().isEmpty, "frisches Rätsel: nichts Falsches")
        guard let f = (0..<25).first(where: { k.weiss[$0] && !k.vorgaben.contains($0) }) else { return XCTFail("kein freies Feld") }
        k.setze(f, k.loesung[f]); XCTAssertTrue(k.falscheEintraege().isEmpty)
        k.setze(f, k.loesung[f] % 9 + 1); XCTAssertEqual(k.falscheEintraege(), [f])
        k.setze(f, 0); XCTAssertTrue(k.falscheEintraege().isEmpty, "leer ist nicht falsch")
        k.loesen(); XCTAssertTrue(k.falscheEintraege().isEmpty)
    }
}

final class KakuroStandTests: XCTestCase {
    func testStandBehaeltZeitTippsUndTagesraetsel() throws {
        var g = SystemRandomNumberGenerator()
        var k = Kakuro.zufaellig(n: 5, mit: &g)
        k.tipp(bevorzugt: nil, mit: &g)
        let stand = KakuroStand(spiel: k, sekunden: 137, tipps: 2, tag: true)
        let geladen = try JSONDecoder().decode(KakuroStand.self, from: JSONEncoder().encode(stand))
        XCTAssertEqual(geladen, stand)
        XCTAssertEqual(geladen.sekunden, 137); XCTAssertEqual(geladen.tipps, 2); XCTAssertTrue(geladen.tag)
        XCTAssertTrue(geladen.istKonsistent)
    }
    func testAlterStandNurMitRaetselBleibtLadbar() throws {
        var g = SystemRandomNumberGenerator()
        var k = Kakuro.zufaellig(mit: &g)
        k.tipp(bevorzugt: nil, mit: &g)
        let alt = try JSONEncoder().encode(k)   // so wurde bis Build 9 gespeichert
        let geladen = try JSONDecoder().decode(KakuroStand.self, from: alt)
        XCTAssertEqual(geladen.spiel, k)
        XCTAssertEqual(geladen.sekunden, 0); XCTAssertEqual(geladen.tipps, 0); XCTAssertFalse(geladen.tag)
        XCTAssertTrue(geladen.istKonsistent)
    }
    func testFehlendeZusatzfelderBekommenStandardwerte() throws {
        var g = SystemRandomNumberGenerator()
        let k = Kakuro.zufaellig(mit: &g)
        let daten = try JSONSerialization.data(withJSONObject: ["spiel": JSONSerialization.jsonObject(with: JSONEncoder().encode(k))])
        let geladen = try JSONDecoder().decode(KakuroStand.self, from: daten)
        XCTAssertEqual(geladen, KakuroStand(spiel: k))
    }
    func testUnstimmigerStandWirdErkannt() throws {
        var g = SystemRandomNumberGenerator()
        let k = Kakuro.zufaellig(mit: &g)
        XCTAssertFalse(KakuroStand(spiel: k, sekunden: -5).istKonsistent)
        XCTAssertFalse(KakuroStand(spiel: k, tipps: -1).istKonsistent)
        XCTAssertThrowsError(try JSONDecoder().decode(KakuroStand.self, from: Data("{\"sekunden\":3}".utf8)))
    }
    /// RT-008: Die vorgewählte Zelle ist nie eine feste Vorgabe.
    func testErsteFreieIstKeineVorgabe() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<5 {
            let k = Kakuro.zufaellig(n: 5, mit: &g)
            if let f = k.ersteFreie { XCTAssertTrue(k.weiss[f]); XCTAssertFalse(k.vorgaben.contains(f)) }
        }
        let k = Kakuro(n: 2, weiss: [false, false, false, true], laeufe: [], loesung: [0, 0, 0, 5], vorgaben: [3])
        XCTAssertNil(k.ersteFreie)
    }
}
