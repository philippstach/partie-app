// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import KoenigswegKern
final class KoenigswegTests: XCTestCase {
    func testPartienEnden() {
        var g = SystemRandomNumberGenerator()
        for st in [1, 2, 3] {
            var s = Koenigsweg(); var n = 0
            while s.sieger == nil && n < 20000 {
                s.wuerfeln(mit: &g)
                if s.wurf != nil, let z = s.computerZug(stufe: s.amZug == 0 ? st : 1, mit: &g) { s.ziehe(z) }
                for sp in 0..<2 { XCTAssertEqual(s.brett[sp].reduce(0, +), Koenigsweg.steine) }
                n += 1
            }
            XCTAssertNotNil(s.sieger, "Stufe \(st)")
        }
    }
    func testSichereRosetteUndSchlagen() {
        var g = SystemRandomNumberGenerator()
        var s = Koenigsweg()
        // Mittelrosette ist für den Gegner gesperrt, wenn belegt: wir prüfen nur die Regel über viele Partien
        for _ in 0..<200 {
            s.wuerfeln(mit: &g)
            for z in s.zuege() { XCTAssertFalse(z.nach == 8 && s.brett[1 - s.amZug][8] > 0) }
            if s.wurf != nil, let z = s.computerZug(stufe: 3, mit: &g) { s.ziehe(z) }
            if s.sieger != nil { s = Koenigsweg() }
        }
    }
    func testSchwererSchlaegtZufall() {
        var g = SystemRandomNumberGenerator(); var siege = 0
        for k in 0..<30 {
            var s = Koenigsweg(); let ich = k % 2; var n = 0
            while s.sieger == nil && n < 20000 {
                s.wuerfeln(mit: &g)
                if s.wurf != nil, let z = s.computerZug(stufe: s.amZug == ich ? 3 : 1, mit: &g) { s.ziehe(z) }
                n += 1
            }
            if s.sieger == ich { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 19)
    }
    func testSpielstandRundlauf() throws {
        var g = SystemRandomNumberGenerator(); var s = Koenigsweg()
        s.wuerfeln(mit: &g)
        if let z = s.computerZug(stufe: 2, mit: &g) { s.ziehe(z) }
        let neu = try JSONDecoder().decode(Koenigsweg.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}

final class KoenigswegRegelTests: XCTestCase {
    private func leer() -> [[Int]] { Array(repeating: Array(repeating: 0, count: 16), count: 2) }
    private func stellung(_ a: [Int: Int], _ b: [Int: Int], amZug: Int = 0, wurf: Int?) -> Koenigsweg {
        var f = leer()
        for (k, v) in a { f[0][k] = v }; for (k, v) in b { f[1][k] = v }
        return Koenigsweg(steine: f, amZug: amZug, wurf: wurf)
    }

    func testStartstellungHatSiebenSteineImVorrat() {
        let s = Koenigsweg()
        XCTAssertEqual(s.vorrat(0), 7); XCTAssertEqual(s.vorrat(1), 7); XCTAssertEqual(s.draussen(0), 0)
    }
    func testRosetteGibtExtrazug() {
        var s = stellung([0: 7], [0: 7], wurf: 4)
        XCTAssertTrue(s.ziehe(.init(von: 0, nach: 4)))
        XCTAssertEqual(s.amZug, 0); XCTAssertTrue(s.meldung.contains("Rosette"))
    }
    func testNormalesFeldWechseltDenSpieler() {
        var s = stellung([0: 7], [0: 7], wurf: 2)
        s.ziehe(.init(von: 0, nach: 2))
        XCTAssertEqual(s.amZug, 1)
    }
    func testGemeinsamesFeldSchlaegtGegnerischenStein() {
        var s = stellung([4: 1, 0: 6], [6: 1, 0: 6], wurf: 2)
        XCTAssertTrue(s.ziehe(.init(von: 4, nach: 6)))
        XCTAssertEqual(s.brett[1][6], 0); XCTAssertEqual(s.brett[1][0], 7); XCTAssertEqual(s.meldung, "Stein geschlagen!")
    }
    func testAufDemEigenenWegIstNichtsZuSchlagen() {
        var s = stellung([0: 6, 3: 1], [3: 1, 0: 6], wurf: 3)
        s.ziehe(.init(von: 0, nach: 3))
        XCTAssertEqual(s.brett[1][3], 1, "Felder 1–4 gehören jedem allein")
    }
    func testMittelrosetteIstSicher() {
        let s = stellung([6: 1, 0: 6], [8: 1, 0: 6], wurf: 2)
        XCTAssertFalse(s.zuege().contains(.init(von: 6, nach: 8)))
    }
    func testEigenerSteinBlockiertDasZielfeld() {
        let s = stellung([2: 1, 5: 1, 0: 5], [0: 7], wurf: 3)
        XCTAssertFalse(s.zuege().contains(.init(von: 2, nach: 5)))
    }
    func testAusgangMussGenauGetroffenWerden() {
        let s = stellung([13: 1, 0: 6], [0: 7], wurf: 3)
        XCTAssertFalse(s.zuege().contains(.init(von: 13, nach: 16)))
        let t = stellung([13: 1, 0: 6], [0: 7], wurf: 2)
        XCTAssertTrue(t.zuege().contains(.init(von: 13, nach: 15)))
    }
    func testSiebenSteineDraussenGewinnen() {
        var s = stellung([14: 1, 15: 6], [0: 7], wurf: 1)
        XCTAssertTrue(s.ziehe(.init(von: 14, nach: 15)))
        XCTAssertEqual(s.sieger, 0)
        XCTAssertFalse(s.ziehe(.init(von: 0, nach: 1)))
    }
    func testUngueltigerZugWirdAbgelehnt() {
        var s = stellung([0: 7], [0: 7], wurf: 2)
        XCTAssertFalse(s.ziehe(.init(von: 0, nach: 3)))
        XCTAssertFalse(s.ziehe(.init(von: 5, nach: 7)))
        XCTAssertEqual(s.amZug, 0)
    }
    func testOhneWurfGibtEsKeineZuege() {
        XCTAssertTrue(stellung([0: 7], [0: 7], wurf: nil).zuege().isEmpty)
        XCTAssertTrue(stellung([0: 7], [0: 7], wurf: 0).zuege().isEmpty)
    }
    func testSchwererComputerSchlaegtWennMoeglich() {
        var g = SystemRandomNumberGenerator()
        let s = stellung([4: 1, 0: 6], [7: 1, 0: 6], wurf: 3)
        XCTAssertEqual(s.computerZug(stufe: 3, mit: &g), .init(von: 4, nach: 7))
    }
    func testVorausschauSpieltGueltigeZuegeBisZumEnde() {
        var g = ZufallsQuelleTest(seed: 5)
        var s = Koenigsweg()
        var schritte = 0
        while s.sieger == nil, schritte < 3000 {
            s.wuerfeln(mit: &g)
            if s.wurf != nil, let z = s.computerZug(stufe: 3, mit: &g) { XCTAssertTrue(s.ziehe(z)) }
            schritte += 1
        }
        XCTAssertNotNil(s.sieger)
    }
    func testSchwerSchlaegtMittelUndLeicht() {
        func punkte(_ stufeA: Int, _ stufeB: Int, partien: Int, seed: UInt64) -> (Int, Int) {
            var g = ZufallsQuelleTest(seed: seed); var a = 0, b = 0
            for partie in 0..<partien {
                var s = Koenigsweg(); let platzA = partie % 2; var n = 0
                while s.sieger == nil, n < 4000 {
                    s.wuerfeln(mit: &g)
                    if s.wurf != nil, let z = s.computerZug(stufe: s.amZug == platzA ? stufeA : stufeB, mit: &g) { s.ziehe(z) }
                    n += 1
                }
                if s.sieger == platzA { a += 1 } else if s.sieger != nil { b += 1 }
            }
            return (a, b)
        }
        let (s1, l1) = punkte(3, 1, partien: 60, seed: 1)
        XCTAssertGreaterThan(s1, l1)
        let (s2, m2) = punkte(3, 2, partien: 60, seed: 2)
        XCTAssertGreaterThan(s2, m2, "schwer \(s2) : mittel \(m2)")
    }
    func testEchteMuenzenSetzenWurf() {
        var s = Koenigsweg()
        XCTAssertFalse(s.setzeWurf(5))
        XCTAssertFalse(s.setzeWurf(-1))
        XCTAssertTrue(s.setzeWurf(3))
        XCTAssertEqual(s.wurf, 3)
        XCTAssertFalse(s.setzeWurf(2), "zweiter Wurf vor dem Zug ist nicht erlaubt")
    }
    func testEchteMuenzenNullSetztAus() {
        var s = Koenigsweg()
        XCTAssertTrue(s.setzeWurf(0))
        XCTAssertNil(s.wurf)
        XCTAssertEqual(s.amZug, 1)
    }
}

struct ZufallsQuelleTest: RandomNumberGenerator {
    var z: UInt64
    init(seed: UInt64) { z = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        z &+= 0x9E37_79B9_7F4A_7C15
        var x = z
        x = (x ^ (x >> 30)) &* 0xBF58_476D_1CE4_E5B9
        x = (x ^ (x >> 27)) &* 0x94D0_49BB_1331_11EB
        return x ^ (x >> 31)
    }
}

/// 1.0 (P4): letzter Wurf für die Würfelbilanz, Rückgängig über Merkstände.
final class KoenigswegWurfBilanzTests: XCTestCase {
    func testLetzterWurfAuchBeiNull() {
        var s = Koenigsweg()
        XCTAssertNil(s.letzterWurf)
        XCTAssertTrue(s.setzeWurf(0))
        XCTAssertEqual(s.letzterWurf, 0)
        XCTAssertNil(s.wurf)
        XCTAssertTrue(s.setzeWurf(3))
        XCTAssertEqual(s.letzterWurf, 3)
    }

    func testWuerfelnMeldetObGeworfenWurde() {
        var s = Koenigsweg(); var g = ZufallsQuelleTest(seed: 7)
        XCTAssertTrue(s.wuerfeln(mit: &g))
        XCTAssertNotNil(s.letzterWurf)
        if s.wurf != nil { XCTAssertFalse(s.wuerfeln(mit: &g), "zweiter Wurf vor dem Zug ist nicht erlaubt") }
    }

    func testAlterStandOhneLetztenWurfLaedt() throws {
        let neu = try JSONEncoder().encode(Koenigsweg())
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: neu) as? [String: Any])
        json.removeValue(forKey: "letzterWurf")
        let alt = try JSONSerialization.data(withJSONObject: json)
        let s = try JSONDecoder().decode(Koenigsweg.self, from: alt)
        XCTAssertNil(s.letzterWurf)
        XCTAssertTrue(s.istStimmig)
    }

    func testMerkstandStelltZugWiederHerAberBehaeltDenWurf() {
        var s = Koenigsweg()
        s.setzeWurf(2)
        let vorher = s
        let z = s.zuege()[0]
        XCTAssertTrue(s.ziehe(z))
        XCTAssertNotEqual(s, vorher)
        s = vorher                       // Rückgängig der Oberfläche: Stand vor dem Zug
        XCTAssertEqual(s.wurf, 2)
        XCTAssertEqual(s.zuege(), vorher.zuege())
    }

    // Blatt 22 (EB2, Schritt 2): Geschlagen-Zähler, alter Stand
    func testGeschlagenWirdGezaehlt() {
        var s = Koenigsweg(steine: [[0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0]], amZug: 0, wurf: 2)
        XCTAssertEqual(s.geschlagen, [0, 0])
        XCTAssertTrue(s.ziehe(Koenigsweg.Zug(von: 4, nach: 6)))
        XCTAssertEqual(s.geschlagen, [1, 0])
    }
    func testAlterStandLaedtOhneGeschlagen() throws {
        var s = Koenigsweg()
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as? [String: Any])
        json.removeValue(forKey: "geschlagen")
        var alt = try JSONDecoder().decode(Koenigsweg.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(alt.geschlagen); XCTAssertTrue(alt.istStimmig)
        var g = SystemRandomNumberGenerator()
        alt.wuerfeln(mit: &g)
        if alt.wurf != nil, let z = alt.computerZug(stufe: 1, mit: &g) { alt.ziehe(z) }   // zählt nicht, stürzt nicht ab
        XCTAssertNil(alt.geschlagen)
        s.wuerfeln(mit: &g)
    }
}
