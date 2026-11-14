// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import EscobaKern

final class EscobaTests: XCTestCase {
    private func k(_ f: Int, _ r: Int) -> EscobaKarte { EscobaKarte(farbe: f, rang: r) }

    func testAnfang() {
        var g = SystemRandomNumberGenerator(); let e = Escoba(mit: &g)
        XCTAssertEqual(e.tisch.count, 4); XCTAssertEqual(e.haende[0].count, 3); XCTAssertEqual(e.haende[1].count, 3)
        XCTAssertEqual(e.stapel.count, 40 - 4 - 6)
    }
    func testFaengeSummeFuenfzehn() {
        let e = Escoba(stapel: [], tisch: [k(1, 5), k(2, 4), k(3, 10), k(1, 1)], haende: [[k(0, 6)], []])
        // 6 + 5 + 4 = 15 und 6 + ... 9 fehlt: {5,4}
        XCTAssertEqual(e.faenge(k(0, 6)).map(Set.init), [Set([0, 1])])
    }
    func testAblegenNurOhneFang() {
        var e = Escoba(stapel: [], tisch: [k(1, 5), k(2, 4)], haende: [[k(0, 6), k(0, 2)], [k(3, 1)]])
        XCTAssertFalse(e.spiele(hand: 0, fang: nil))       // Fang möglich → Ablegen verboten
        XCTAssertTrue(e.spiele(hand: 1, fang: nil))        // 2 + 5 + 4 = 11 → kein Fang
        XCTAssertEqual(e.tisch.count, 3)
        XCTAssertEqual(e.amZug, 1)
    }
    func testFangUndEscoba() {
        var e = Escoba(stapel: [k(3, 2)], tisch: [k(1, 5), k(2, 4)], haende: [[k(0, 6)], [k(3, 1)]])
        XCTAssertFalse(e.spiele(hand: 0, fang: [0]))       // falsche Auswahl
        XCTAssertTrue(e.spiele(hand: 0, fang: [0, 1]))
        XCTAssertEqual(e.escobas[0], 1)
        XCTAssertTrue(e.tisch.isEmpty)
        XCTAssertEqual(e.gewonnen[0].count, 3)
    }
    func testLetzteEscobaZaehltNicht() {
        var e = Escoba(stapel: [], tisch: [k(1, 5), k(2, 4)], haende: [[k(0, 6)], []])
        XCTAssertTrue(e.spiele(hand: 0, fang: [0, 1]))
        XCTAssertEqual(e.escobas[0], 0); XCTAssertTrue(e.vorbei)
    }
    func testRestTischAnLetztenFaenger() {
        var e = Escoba(stapel: [], tisch: [k(1, 5), k(2, 4), k(3, 3)], haende: [[k(0, 6)], [k(0, 1)]])
        XCTAssertTrue(e.spiele(hand: 0, fang: [0, 1]))
        XCTAssertTrue(e.spiele(hand: 0, fang: nil))
        XCTAssertTrue(e.vorbei); XCTAssertTrue(e.tisch.isEmpty)
        XCTAssertEqual(e.gewonnen[0].count, 5)
    }
    func testWertung() {
        var e = Escoba(stapel: [], tisch: [], haende: [[], []])
        e = Escoba(stapel: [], tisch: [], haende: [[], []])
        _ = e
        let a = [k(0, 7), k(0, 1), k(1, 7)], b = [k(2, 2)]
        var s = Escoba(stapel: [], tisch: [], haende: [[], []])
        s = Escoba.testZustand(gewonnen: [a, b])
        let w = s.wertung(0)
        XCTAssertTrue(w.siebenMuenzen); XCTAssertTrue(w.karten); XCTAssertTrue(w.muenzen); XCTAssertTrue(w.siebener)
        XCTAssertEqual(w.summe, 4)
        XCTAssertEqual(s.wertung(1).summe, 0)
    }
    func testAlleStufenSpielenZuEnde() {
        for stufe in 1...3 {
            for _ in 0..<40 {
                var g = SystemRandomNumberGenerator(); var e = Escoba(mit: &g); var n = 0
                while !e.vorbei && n < 100 { let (i, f) = EscobaComputer.wahl(e, stufe: stufe); XCTAssertTrue(e.spiele(hand: i, fang: f)); n += 1 }
                XCTAssertTrue(e.vorbei)
            }
        }
    }
    func testSchwerSchlaegtLeicht() {
        var siege = [0, 0, 0]
        for _ in 0..<200 {
            var g = SystemRandomNumberGenerator(); var e = Escoba(mit: &g)
            while !e.vorbei { let (i, f) = EscobaComputer.wahl(e, stufe: e.amZug == 0 ? 3 : 1); e.spiele(hand: i, fang: f) }
            if let s = e.sieger { siege[s] += 1 } else { siege[2] += 1 }
        }
        XCTAssertGreaterThan(siege[0], siege[1])
    }
    func testComputerSpieltPartienZuEnde() {
        for _ in 0..<100 {
            var g = SystemRandomNumberGenerator(); var e = Escoba(mit: &g); var n = 0
            while !e.vorbei && n < 100 { let (i, f) = EscobaComputer.wahl(e); XCTAssertTrue(e.spiele(hand: i, fang: f)); n += 1 }
            XCTAssertTrue(e.vorbei)
            XCTAssertEqual(e.gewonnen[0].count + e.gewonnen[1].count + e.tisch.count, 40)
        }
    }
}

extension Escoba {
    static func testZustand(gewonnen: [[EscobaKarte]]) -> Escoba {
        var e = Escoba(stapel: [], tisch: [], haende: [[], []])
        e.setzeGewonnen(gewonnen); return e
    }
}

final class EscobaRegelnTests: XCTestCase {
    private func k(_ f: Int, _ r: Int) -> EscobaKarte { EscobaKarte(farbe: f, rang: r) }

    func testAnfangVerteilt40KartenAufTischHaendeStapel() {
        var g = SystemRandomNumberGenerator(); let e = Escoba(mit: &g)
        XCTAssertEqual(e.tisch.count, 4); XCTAssertEqual(e.haende.map(\.count), [3, 3]); XCTAssertEqual(e.stapel.count, 40 - 4 - 6)
    }
    func testKarteMitWertAb15HatKeinenFang() {
        let e = Escoba(stapel: [], tisch: [k(0, 5), k(1, 10)], haende: [[k(2, 10)], [k(3, 1)]])
        XCTAssertEqual(e.faenge(k(2, 10)).count, 1)
        XCTAssertTrue(e.faenge(k(2, 5)).count == 1)                         // 5 + 10
    }
    func testMehrereFangmoeglichkeitenWerdenAllegefunden() {
        let e = Escoba(stapel: [], tisch: [k(0, 5), k(1, 4), k(2, 1), k(3, 10)], haende: [[k(2, 10)], [k(3, 1)]])
        let f = e.faenge(k(1, 10)).map { Set($0) }
        XCTAssertTrue(f.contains([0])); XCTAssertTrue(f.contains([1, 2])); XCTAssertEqual(f.count, 2)
    }
    func testUngueltigerFangWirdAbgelehnt() {
        var e = Escoba(stapel: [], tisch: [k(0, 5), k(1, 4)], haende: [[k(2, 10)], [k(3, 1)]])
        XCTAssertFalse(e.spiele(hand: 0, fang: [1])); XCTAssertFalse(e.spiele(hand: 0, fang: [0, 1])); XCTAssertEqual(e.gewonnen[0].count, 0)
    }
    func testAblegenWennFangMoeglichIstVerboten() {
        var e = Escoba(stapel: [], tisch: [k(0, 5)], haende: [[k(2, 10)], [k(3, 1)]])
        XCTAssertFalse(e.spiele(hand: 0, fang: nil))
    }
    func testGezogeneKartenWandernInDenGewonnenStapelUndDerAndereIstDran() {
        var e = Escoba(stapel: [k(0, 2)], tisch: [k(0, 5), k(1, 3)], haende: [[k(2, 10), k(2, 1)], [k(3, 1)]])
        XCTAssertTrue(e.spiele(hand: 0, fang: [0])); XCTAssertEqual(e.gewonnen[0].count, 2); XCTAssertEqual(e.amZug, 1)
        XCTAssertEqual(e.tisch, [k(1, 3)])
    }
    func testEscobaZaehltBeiLeeremTischAberNichtBeimLetztenZug() {
        var e = Escoba(stapel: [k(0, 2)], tisch: [k(0, 5)], haende: [[k(2, 10)], [k(3, 1)]])
        XCTAssertTrue(e.spiele(hand: 0, fang: [0])); XCTAssertEqual(e.escobas, [1, 0])
    }
    func testNeuAusteilenWennBeideHaendeLeerUndStapelNochDa() {
        var e = Escoba(stapel: (1...6).map { k(1, $0) }, tisch: [k(0, 5)], haende: [[k(2, 10)], [k(3, 1)]])
        e.spiele(hand: 0, fang: [0])
        XCTAssertNotNil(e.letzterFaenger)
        e.spiele(hand: 0, fang: nil)
        XCTAssertEqual(e.haende.map(\.count), [3, 3]); XCTAssertFalse(e.vorbei)
    }
    func testWertungSiebenMuenzenUndSiebenerUndGleichstand() {
        var e = Escoba(stapel: [], tisch: [], haende: [[], []])
        e.setzeGewonnen([[k(0, 7), k(1, 7), k(2, 7)], [k(3, 7), k(1, 2)]])
        let w = e.wertung(0)
        XCTAssertTrue(w.siebenMuenzen); XCTAssertTrue(w.siebener); XCTAssertTrue(w.karten); XCTAssertTrue(w.muenzen)
        e.setzeGewonnen([[k(1, 1), k(1, 2)], [k(2, 1), k(2, 2)]])
        XCTAssertFalse(e.wertung(0).karten); XCTAssertFalse(e.wertung(1).karten)
    }
    func testComputerSchwerNimmtDenTischSauberWennErKann() {
        let e = Escoba(stapel: [k(0, 2)], tisch: [k(0, 5)], haende: [[k(2, 10), k(2, 1)], [k(3, 1)]])
        let w = EscobaComputer.wahl(e, stufe: 3)
        XCTAssertEqual(w.0, 0); XCTAssertEqual(w.1, [0])
    }
    func testComputerLegtKleineKarteAbOhneFang() {
        let e = Escoba(stapel: [k(0, 2)], tisch: [k(1, 10), k(2, 10), k(3, 10)], haende: [[k(0, 7), k(2, 1)], [k(3, 1)]])
        let w = EscobaComputer.wahl(e, stufe: 3)
        XCTAssertNil(w.1); XCTAssertEqual(w.0, 1)                         // die Eins statt der Münzen-Sieben
    }
}
