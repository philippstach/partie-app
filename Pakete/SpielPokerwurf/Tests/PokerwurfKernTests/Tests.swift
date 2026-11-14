// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import PokerwurfKern
struct SeededGenerator: RandomNumberGenerator {
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
final class PokerwurfTests: XCTestCase {
    /// RT-011: Alle Würfel gehalten und würfeln verbraucht keinen Wurf.
    func testAlleGehaltenVerbrauchtKeinenWurf() {
        var g = SeededGenerator(seed: 3); var s = Pokerwurf(spieler: 2)
        XCTAssertTrue(s.kannWuerfeln)
        s.wuerfeln(mit: &g); XCTAssertEqual(s.wuerfe, 1)
        for i in 0..<5 { s.halte(i) }
        let augen = s.becher.augen
        XCTAssertFalse(s.kannWuerfeln)
        s.wuerfeln(mit: &g)
        XCTAssertEqual(s.wuerfe, 1); XCTAssertEqual(s.becher.augen, augen)
        s.halte(0); XCTAssertTrue(s.kannWuerfeln)
        s.wuerfeln(mit: &g); XCTAssertEqual(s.wuerfe, 2)
    }

    func testHandarten() {
        XCTAssertEqual(PokerHand([3, 3, 3, 3, 3]).art, .fuenfling); XCTAssertEqual(PokerHand([2, 2, 2, 2, 5]).art, .vierling)
        XCTAssertEqual(PokerHand([4, 4, 4, 1, 1]).art, .fullHouse); XCTAssertEqual(PokerHand([2, 3, 4, 5, 6]).art, .grosseStrasse)
        XCTAssertEqual(PokerHand([1, 2, 3, 4, 5]).art, .kleineStrasse); XCTAssertEqual(PokerHand([6, 6, 6, 2, 1]).art, .drilling)
        XCTAssertEqual(PokerHand([6, 6, 1, 1, 2]).art, .zweiPaare); XCTAssertEqual(PokerHand([6, 6, 1, 3, 2]).art, .paar)
        XCTAssertEqual(PokerHand([6, 5, 1, 3, 2]).art, .nichts)
    }
    func testVergleich() {
        XCTAssertTrue(PokerHand([1, 1, 2, 3, 6]) < PokerHand([2, 2, 1, 3, 6]))      // Paar 1 < Paar 2
        XCTAssertTrue(PokerHand([6, 6, 1, 1, 2]) < PokerHand([6, 6, 2, 2, 1]))      // gleiche hohe Paare, zweites Paar entscheidet
        XCTAssertTrue(PokerHand([6, 6, 6, 2, 1]) < PokerHand([1, 1, 1, 1, 6]))
        XCTAssertTrue(PokerHand([1, 2, 3, 4, 5]) < PokerHand([2, 3, 4, 5, 6]))
        XCTAssertEqual(PokerHand([1, 1, 2, 3, 6]), PokerHand([3, 6, 1, 2, 1]))
    }
    func testPartieLaeuft() {
        var g = SystemRandomNumberGenerator(); var s = Pokerwurf(spieler: 3)
        while !s.vorbei {
            while s.kannWuerfeln {   // RT-011: alle gehalten → kein Wurf mehr möglich
                s.wuerfeln(mit: &g)
                let h = Pokerwurf.computerHalten(s.becher.augen)
                for i in 0..<5 where h[i] != s.becher.gehalten[i] { s.halte(i) }
            }
            s.fertig()
            if s.rundeGewertet { s.naechsteRunde() }
        }
        XCTAssertTrue(s.punkte.reduce(0, +) >= Pokerwurf.runden)
    }
    func testFehlerhafterComputerHaeltGueltigeMaske() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<100 { let a = (0..<5).map { _ in Int.random(in: 1...6) }
            XCTAssertEqual(Pokerwurf.computerHalten(a, fehler: 1, mit: &g).count, 5)
            XCTAssertEqual(Pokerwurf.computerHalten(a, fehler: 0, mit: &g), Pokerwurf.computerHalten(a)) }
    }

    /// Spieler 0 mit Fehlerquote `a`, Spieler 1 mit `b`; Rückgabe: mittlere Rundensiege (Spieler 0, Spieler 1) je Partie.
    private func siege(_ a: Double, _ b: Double, partien: Int) -> (Double, Double) {
        var p0 = 0, p1 = 0
        for _ in 0..<partien {
            var g = SystemRandomNumberGenerator(); var s = Pokerwurf(spieler: 2)
            while !s.vorbei {
                while s.kannWuerfeln {   // RT-011: alle gehalten → kein Wurf mehr möglich
                    s.wuerfeln(mit: &g)
                    let h = Pokerwurf.computerHalten(s.becher.augen, fehler: s.amZug == 0 ? a : b, mit: &g)
                    for i in 0..<5 where h[i] != s.becher.gehalten[i] { s.halte(i) }
                }
                s.fertig()
                if s.rundeGewertet { s.naechsteRunde() }
            }
            p0 += s.punkte[0]; p1 += s.punkte[1]
        }
        return (Double(p0) / Double(partien), Double(p1) / Double(partien))
    }
    func testSchwerSchlaegtLeichtUndMittel() {
        let (schwer, leicht) = siege(0, 0.5, partien: 400)
        XCTAssertGreaterThan(schwer, leicht * 1.15, "schwer \(schwer), leicht \(leicht)")
        let (mittel, leicht2) = siege(0.15, 0.5, partien: 400)
        XCTAssertGreaterThan(mittel, leicht2, "mittel \(mittel), leicht \(leicht2)")
        let (schwer2, mittel2) = siege(0, 0.15, partien: 600)
        XCTAssertGreaterThan(schwer2, mittel2, "schwer \(schwer2), mittel \(mittel2)")
    }
}

final class PokerwurfRegelTests: XCTestCase {
    private func art(_ a: [Int]) -> PokerHand.Art { PokerHand(a).art }

    func testAlleHandartenUndIhreReihenfolge() {
        let reihe: [[Int]] = [[1, 3, 4, 5, 6], [2, 2, 4, 5, 6], [2, 2, 4, 4, 6], [3, 3, 3, 4, 6], [1, 2, 3, 4, 5], [2, 3, 4, 5, 6], [3, 3, 3, 5, 5], [4, 4, 4, 4, 1], [6, 6, 6, 6, 6]]
        let hands = reihe.map { PokerHand($0) }
        for i in 1..<hands.count { XCTAssertLessThan(hands[i - 1], hands[i]) }
        XCTAssertEqual(hands.map(\.art), PokerHand.Art.allCases)
    }
    func testGleicheArtEntscheidetDieHoehe() {
        XCTAssertLessThan(PokerHand([2, 2, 3, 4, 5]), PokerHand([3, 3, 1, 2, 4]))
        XCTAssertLessThan(PokerHand([3, 3, 4, 4, 1]), PokerHand([2, 2, 5, 5, 1]), "Das höhere Paar zählt zuerst")
        XCTAssertLessThan(PokerHand([2, 2, 5, 5, 1]), PokerHand([2, 2, 5, 5, 3]), "Beistein entscheidet")
        XCTAssertEqual(PokerHand([1, 2, 2, 5, 5]), PokerHand([5, 2, 5, 1, 2]), "Reihenfolge der Würfel egal")
    }
    func testNichtsVergleichtDieHoechstenAugen() {
        XCTAssertLessThan(PokerHand([1, 2, 3, 4, 6]), PokerHand([1, 2, 3, 5, 6]))
    }
    func testZweiPaareMitFuenferUndVierer() {
        XCTAssertEqual(art([4, 4, 5, 5, 1]), .zweiPaare); XCTAssertEqual(art([3, 3, 3, 3, 1]), .vierling)
        XCTAssertEqual(art([1, 1, 1, 2, 2]), .fullHouse); XCTAssertEqual(art([1, 1, 2, 3, 6]), .paar)
    }
    func testWuerfeWerdenBegrenzt() {
        var g = SystemRandomNumberGenerator(); var s = Pokerwurf(spieler: 2)
        for _ in 0..<5 { s.wuerfeln(mit: &g) }
        XCTAssertEqual(s.wuerfe, 3)
    }
    func testHaltenNurNachDemErstenUndVorDemLetztenWurf() {
        var g = SystemRandomNumberGenerator(); var s = Pokerwurf(spieler: 2)
        s.halte(0); XCTAssertFalse(s.becher.gehalten[0])
        s.wuerfeln(mit: &g); s.halte(0); XCTAssertTrue(s.becher.gehalten[0])
        s.wuerfeln(mit: &g); s.wuerfeln(mit: &g); s.halte(1); XCTAssertFalse(s.becher.gehalten[1])
    }
    func testG020NachDemLetztenWurfLaesstSichDerZugBeenden() {
        var s = Pokerwurf(spieler: 2); var g = SystemRandomNumberGenerator()
        XCTAssertFalse(s.zugBeendbar)
        s.wuerfeln(mit: &g); s.wuerfeln(mit: &g)
        XCTAssertTrue(s.zugBeendbar); XCTAssertFalse(s.mussBehalten)
        s.wuerfeln(mit: &g)
        XCTAssertTrue(s.mussBehalten)
        s.wuerfeln(mit: &g)                       // vierter Wurf wird ignoriert
        XCTAssertEqual(s.wuerfe, 3)
        s.fertig()
        XCTAssertEqual(s.amZug, 1); XCTAssertEqual(s.wuerfe, 0)
        XCTAssertNotNil(s.haende[0]); XCTAssertFalse(s.mussBehalten)
    }

    func testFertigVorDemErstenWurfGehtNicht() {
        var s = Pokerwurf(spieler: 2)
        s.fertig()
        XCTAssertEqual(s.amZug, 0); XCTAssertNil(s.haende[0])
    }
    func testBesteHandGewinntDieRundeBeiGleichstandBeide() {
        var g = SystemRandomNumberGenerator(); var s = Pokerwurf(spieler: 3)
        for _ in 0..<3 { s.wuerfeln(mit: &g); s.fertig() }
        XCTAssertTrue(s.rundeGewertet)
        let beste = s.haende.compactMap { $0 }.max()!
        XCTAssertEqual(Set(s.rundenSieger), Set(s.haende.indices.filter { s.haende[$0] == beste }))
        XCTAssertEqual(s.punkte.reduce(0, +), s.rundenSieger.count)
    }
    func testNachDenFuenfRundenIstSchluss() {
        var g = SystemRandomNumberGenerator(); var s = Pokerwurf(spieler: 2)
        var n = 0
        while !s.vorbei && n < 100 { s.wuerfeln(mit: &g); s.fertig(); if s.rundeGewertet { s.naechsteRunde() }; n += 1 }
        XCTAssertEqual(s.runde, Pokerwurf.runden)
        let stand = s; s.wuerfeln(mit: &g); XCTAssertEqual(s, stand)
    }
    func testComputerHaeltPaareUndGanzeHaende() {
        XCTAssertEqual(Pokerwurf.computerHalten([3, 3, 3, 2, 5]), [true, true, true, false, false])
        XCTAssertEqual(Pokerwurf.computerHalten([1, 2, 3, 4, 5]), Array(repeating: true, count: 5))
        XCTAssertEqual(Pokerwurf.computerHalten([1, 2, 3, 4, 6]), [true, true, true, true, false], "Vier in Folge: auf die Straße spielen")
        XCTAssertEqual(Pokerwurf.computerHalten([1, 2, 4, 5, 6]), [false, false, false, false, true], "Nur hohe Einzelwürfel")
    }
    func testComputerSpieltAufStrasseAuchMitPaar() {
        XCTAssertEqual(Pokerwurf.computerHalten([2, 3, 4, 5, 5]), [true, true, true, true, false], "Offene Straße schlägt das Paar")
        XCTAssertEqual(Pokerwurf.computerHalten([1, 2, 3, 4, 4]), [false, false, false, true, true], "Nur eine Lücke: Paar behalten")
    }
    func testLetzterHoertMitFuehrungAuf() {
        var s = Pokerwurf(spieler: 2)
        var g = SeededGenerator(seed: 3)
        s.wuerfeln(mit: &g); s.fertig()
        XCTAssertFalse(s.computerFertig(stufe: 3), "Wer nicht Letzter ist, hört nicht deshalb auf")
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator(); var s = Pokerwurf(spieler: 2)
        s.wuerfeln(mit: &g); s.fertig()
        let neu = try JSONDecoder().decode(Pokerwurf.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}

extension PokerHand.Art: CaseIterable { public static var allCases: [PokerHand.Art] { (0...8).compactMap(PokerHand.Art.init(rawValue:)) } }

/// 1.0 (P4): Rückgängig der Oberfläche arbeitet mit Merkständen des Werts; ein Wurf bleibt dabei erhalten.
final class PokerwurfMerkstandTests: XCTestCase {
    func testHalteAuswahlUndWertungLassenSichUeberMerkstandZuruecknehmen() {
        var s = Pokerwurf(spieler: 2); var g = SeededGenerator(seed: 11)
        s.wuerfeln(mit: &g)
        let augen = s.becher.augen
        let vorHalten = s
        s.halte(0)
        XCTAssertTrue(s.becher.gehalten[0])
        s = vorHalten
        XCTAssertFalse(s.becher.gehalten[0])
        XCTAssertEqual(s.becher.augen, augen, "der Wurf bleibt")
        let vorFertig = s
        s.fertig()
        XCTAssertEqual(s.amZug, 1)
        s = vorFertig
        XCTAssertEqual(s.amZug, 0)
        XCTAssertEqual(s.wuerfe, 1)
        XCTAssertNil(s.haende[0])
    }

    // Blatt 22 (EB2, Schritt 2): beste Hand je Person, alter Stand
    func testBesteHandWirdGemerkt() {
        var p = Pokerwurf(spieler: 2); var g = SystemRandomNumberGenerator()
        p.wuerfeln(mit: &g); p.fertig()
        XCTAssertNotNil(p.besteHaende?[0]); XCTAssertNil(p.besteHaende?[1])
        XCTAssertEqual(p.besteHaende?[0], p.haende[0])
    }
    func testAlterStandLaedtOhneBesteHaende() throws {
        var p = Pokerwurf(spieler: 2); var g = SystemRandomNumberGenerator()
        p.wuerfeln(mit: &g)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(p)) as? [String: Any])
        json.removeValue(forKey: "besteHaende")
        var alt = try JSONDecoder().decode(Pokerwurf.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(alt.besteHaende)
        alt.fertig()   // zählt nicht, stürzt nicht ab
        XCTAssertNil(alt.besteHaende)
    }
}
