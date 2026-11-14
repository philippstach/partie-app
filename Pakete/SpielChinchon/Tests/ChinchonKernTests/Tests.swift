// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import ChinchonKern

final class ChinchonTests: XCTestCase {
    private func k(_ f: Int, _ r: Int) -> ChinKarte { ChinKarte(farbe: f, rang: r) }

    func testSiebenUndZehnSindNachbarn() {
        XCTAssertEqual(k(0, 7).folge + 1, k(0, 10).folge)
        let h = [k(0, 6), k(0, 7), k(0, 10), k(1, 12)]
        XCTAssertEqual(Chinchon.rest(h).punkte, 10)      // Reihe 6-7-10, offen: 12 (10 Punkte)
    }
    func testSatzUndReihe() {
        let h = [k(0, 2), k(1, 2), k(2, 2), k(3, 5), k(3, 6), k(3, 7), k(0, 12)]
        XCTAssertEqual(Chinchon.rest(h).punkte, 10)
        XCTAssertEqual(Chinchon.rest(h).offen, [6])
    }
    func testBesteAufteilung() {
        // 4-5-6 Münzen + 4er Becher/Schwerter: Satz geht nicht (nur zwei Vierer) → Reihe zählt
        let h = [k(0, 4), k(0, 5), k(0, 6), k(1, 4), k(2, 4), k(1, 1), k(2, 1)]
        XCTAssertEqual(Chinchon.rest(h).punkte, 10)   // Reihe 4-5-6 Münzen, offen 4+4+1+1
    }
    func testSchliessen() {
        let h = [k(0, 2), k(1, 2), k(2, 2), k(3, 5), k(3, 6), k(3, 7), k(0, 12), k(1, 1)]
        let erlaubt = Chinchon.schliessKarten(h)
        XCTAssertTrue(erlaubt.contains(6))               // 12 ablegen → Rest 1 Punkt
        XCTAssertFalse(erlaubt.contains(0))
    }
    func testChinchonErkennung() {
        XCTAssertTrue(Chinchon.istChinchon((1...7).map { k(2, $0) }))
        XCTAssertTrue(Chinchon.istChinchon([4, 5, 6, 7, 10, 11, 12].map { k(0, $0) }))
        XCTAssertFalse(Chinchon.istChinchon([1, 2, 3, 4, 5, 6, 10].map { k(0, $0) }))
    }
    func testHandAblauf() {
        var g = SystemRandomNumberGenerator()
        var h = ChinchonHand(beginner: 0, mit: &g)
        XCTAssertFalse(h.lege(ab: 0))                    // erst ziehen
        XCTAssertTrue(h.ziehe(vonAblage: false)); XCTAssertEqual(h.haende[0].count, 8)
        XCTAssertFalse(h.ziehe(vonAblage: true))
        XCTAssertTrue(h.lege(ab: 0)); XCTAssertEqual(h.amZug, 1)
    }
    func testAlleStufenEnden() {
        for stufe in 1...3 {
            for _ in 0..<15 {
                var g = SystemRandomNumberGenerator(); var p = ChinchonPartie(mit: &g); var n = 0
                while p.gewinner == nil && n < 20000 {
                    n += 1
                    if p.hand.vorbei { p.handAbschliessen(mit: &g); continue }
                    let von = ChinchonComputer.ziehenVonAblage(p.hand, stufe: stufe)
                    p.zug { XCTAssertTrue($0.ziehe(vonAblage: von)) }
                    let (i, schl) = ChinchonComputer.ablegen(p.hand, stufe: stufe)
                    p.zug { XCTAssertTrue($0.lege(ab: i, schliessen: schl)) }
                }
                XCTAssertNotNil(p.gewinner)
            }
        }
    }
    func testComputerPartienEnden() {
        for _ in 0..<30 {
            var g = SystemRandomNumberGenerator(); var p = ChinchonPartie(mit: &g); var n = 0
            while p.gewinner == nil && n < 20000 {
                n += 1
                if p.hand.vorbei { p.handAbschliessen(mit: &g); continue }
                let von = ChinchonComputer.ziehenVonAblage(p.hand)
                p.zug { XCTAssertTrue($0.ziehe(vonAblage: von)) }
                let (i, schl) = ChinchonComputer.ablegen(p.hand)
                p.zug { XCTAssertTrue($0.lege(ab: i, schliessen: schl)) }
            }
            XCTAssertNotNil(p.gewinner)
        }
    }

    /// Spieler 0 spielt „schwer“, Spieler 1 „leicht“: schwer gewinnt klar öfter.
    func testSchwerSchlaegtLeicht() {
        var siege = 0; let partien = 40
        for _ in 0..<partien {
            var g = SystemRandomNumberGenerator(); var p = ChinchonPartie(mit: &g); var n = 0
            while p.gewinner == nil && n < 20000 {
                n += 1
                if p.hand.vorbei { p.handAbschliessen(mit: &g); continue }
                let stufe = p.hand.amZug == 0 ? 3 : 1
                let von = ChinchonComputer.ziehenVonAblage(p.hand, stufe: stufe)
                p.zug { XCTAssertTrue($0.ziehe(vonAblage: von)) }
                let (i, schl) = ChinchonComputer.ablegen(p.hand, stufe: stufe)
                p.zug { XCTAssertTrue($0.lege(ab: i, schliessen: schl)) }
            }
            if p.gewinner == 0 { siege += 1 }
        }
        XCTAssertGreaterThan(Double(siege) / Double(partien), 0.6, "schwer gewann \(siege) von \(partien)")
    }
}

final class ChinchonRegelnTests: XCTestCase {
    private func c(_ f: Int, _ r: Int) -> ChinKarte { ChinKarte(farbe: f, rang: r) }

    func testPunkteDerKarten() {
        XCTAssertEqual(c(0, 12).punkte, 10); XCTAssertEqual(c(0, 10).punkte, 10); XCTAssertEqual(c(0, 7).punkte, 7); XCTAssertEqual(c(0, 1).punkte, 1)
    }
    func testVierlingGibtDreierTeilmengen() {
        let h = (0..<4).map { c($0, 5) } + [c(0, 1), c(1, 12), c(2, 11)]
        XCTAssertEqual(Chinchon.rest(h).punkte, 1 + 10 + 10)         // alle vier Fünfer melden
    }
    func testReiheUeberDieLuecke7Auf10() {
        let h = [c(1, 6), c(1, 7), c(1, 10), c(2, 1), c(3, 12), c(0, 12), c(0, 11)]
        XCTAssertEqual(Chinchon.rest(h).punkte, 1 + 10 + 10 + 10)
    }
    func testKeineReiheUeberDieZwoelfZurEins() {
        let h = [c(1, 11), c(1, 12), c(1, 1), c(2, 3), c(3, 4), c(0, 5), c(0, 7)]
        XCTAssertEqual(Chinchon.rest(h).punkte, h.reduce(0) { $0 + $1.punkte })
    }
    func testSchliessenBrauchtHoechstensFuenfRestpunkte() {
        let gut = [c(0, 1), c(0, 2), c(0, 3), c(1, 4), c(1, 5), c(1, 6), c(2, 5), c(3, 12)]
        XCTAssertEqual(Chinchon.schliessKarten(gut), [6, 7].filter { Chinchon.rest(without(gut, $0)).punkte <= 5 })
        XCTAssertTrue(Chinchon.schliessKarten(gut).contains(7))
        let schlecht = [c(0, 1), c(0, 2), c(0, 3), c(1, 12), c(1, 11), c(1, 6), c(2, 5), c(3, 10)]
        XCTAssertTrue(Chinchon.schliessKarten(schlecht).isEmpty)
        XCTAssertTrue(Chinchon.schliessKarten(Array(gut.prefix(7))).isEmpty)       // nur mit 8 Karten
    }
    private func without(_ h: [ChinKarte], _ i: Int) -> [ChinKarte] { var r = h; r.remove(at: i); return r }

    func testChinchonSiebenInReiheGleicherFarbe() {
        XCTAssertTrue(Chinchon.istChinchon([1, 2, 3, 4, 5, 6, 7].map { c(2, $0) }))
        XCTAssertTrue(Chinchon.istChinchon([4, 5, 6, 7, 10, 11, 12].map { c(2, $0) }))
        XCTAssertFalse(Chinchon.istChinchon([1, 2, 3, 4, 5, 6, 10].map { c(2, $0) }))
        XCTAssertFalse(Chinchon.istChinchon([1, 2, 3, 4, 5, 6].map { c(2, $0) } + [c(1, 7)]))
    }
    func testSchliessenMitNullRestGibtMinusZehn() {
        let h0 = [c(0, 1), c(0, 2), c(0, 3), c(0, 4), c(1, 5), c(1, 6), c(1, 7)]
        let extra = c(3, 12)
        let rest = (0..<4).flatMap { f in [1, 2, 3, 4, 5, 6, 7, 10, 11, 12].map { c(f, $0) } }.filter { !h0.contains($0) && $0 != extra }
        var hand = ChinchonHand(karten: h0 + Array(rest.prefix(7)) + [rest[7]] + [extra] + Array(rest.dropFirst(8)), beginner: 0)
        XCTAssertTrue(hand.ziehe(vonAblage: false))
        let i = hand.haende[0].firstIndex(of: extra)!
        XCTAssertTrue(hand.lege(ab: i, schliessen: true))
        XCTAssertTrue(hand.vorbei); XCTAssertEqual(hand.schliesser, 0); XCTAssertEqual(hand.strafe[0], -10)
    }
    func testGezogenWerdenMussVorDemAblegen() {
        var g = SystemRandomNumberGenerator(); var hand = ChinchonHand(beginner: 0, mit: &g)
        XCTAssertFalse(hand.lege(ab: 0))
        XCTAssertTrue(hand.ziehe(vonAblage: false)); XCTAssertFalse(hand.ziehe(vonAblage: true))
        XCTAssertTrue(hand.lege(ab: 0)); XCTAssertEqual(hand.amZug, 1); XCTAssertEqual(hand.haende[0].count, 7)
    }
    func testAblagenKarteWirdMerkbarFuerDenGegner() {
        var g = SystemRandomNumberGenerator(); var hand = ChinchonHand(beginner: 0, mit: &g)
        let oben = hand.ablage.last!
        XCTAssertTrue(hand.ziehe(vonAblage: true)); XCTAssertEqual(hand.ablageGenommen[0], [oben])
    }
    func testLeererStapelWirdAusDerAblageNeuGebildet() {
        let karten = (0..<4).flatMap { f in [1, 2, 3, 4, 5, 6, 7, 10, 11, 12].map { c(f, $0) } }
        var hand = ChinchonHand(karten: karten, beginner: 0)
        for _ in 0..<26 { XCTAssertTrue(hand.ziehe(vonAblage: false)); hand.lege(ab: 0); XCTAssertTrue(hand.ziehe(vonAblage: false)); hand.lege(ab: 0) }
        XCTAssertEqual(hand.haende[0].count, 7); XCTAssertEqual(hand.haende[1].count, 7)
        XCTAssertEqual(hand.stapel.count + hand.ablage.count + 14, 40)
    }
    func testNichtsMehrZuZiehenLiefertFalschStattAbsturz() {
        var hand = ChinchonHand(karten: Array((0..<4).flatMap { f in [1, 2, 3, 4, 5, 6, 7, 10, 11, 12].map { c(f, $0) } }.prefix(15)), beginner: 0)
        XCTAssertFalse(hand.ziehe(vonAblage: false))
    }
    func testFalschesSchliessenWirdAbgelehnt() {
        var g = SystemRandomNumberGenerator(); var hand = ChinchonHand(beginner: 0, mit: &g)
        hand.ziehe(vonAblage: false)
        if Chinchon.schliessKarten(hand.haende[0]).isEmpty { XCTAssertFalse(hand.lege(ab: 0, schliessen: true)); XCTAssertFalse(hand.vorbei) }
    }
    func testPartieEndetBei100Strafpunkten() {
        var g = SystemRandomNumberGenerator(); var p = ChinchonPartie(mit: &g); var runden = 0
        while p.gewinner == nil && runden < 300 {
            runden += 1
            var z = 0
            while !p.hand.vorbei && z < 400 {
                z += 1
                p.zug { h in
                    let s = h.amZug
                    if ChinchonComputer.ziehenVonAblage(h, stufe: 2) { h.ziehe(vonAblage: true) } else { h.ziehe(vonAblage: false) }
                    let (i, zu) = ChinchonComputer.ablegen(h, stufe: 2); _ = s; h.lege(ab: i, schliessen: zu)
                }
            }
            p.handAbschliessen(mit: &g)
        }
        XCTAssertNotNil(p.gewinner); XCTAssertTrue(p.strafe.contains { $0 >= ChinchonPartie.grenze } || p.hand.chinchon)
    }
    func testComputerSchliesstSobaldMoeglich() {
        let karten = [c(0, 1), c(0, 2), c(0, 3), c(1, 4), c(1, 5), c(1, 6), c(2, 5), c(3, 12)]
        let rest = (0..<4).flatMap { f in [1, 2, 3, 4, 5, 6, 7, 10, 11, 12].map { c(f, $0) } }.filter { !karten.contains($0) }
        var hand = ChinchonHand(karten: Array(karten.prefix(7)) + Array(rest.prefix(7)) + Array(rest.dropFirst(7)), beginner: 0)
        hand.ziehe(vonAblage: false)
        let (_, schliessen) = ChinchonComputer.ablegen(hand, stufe: 2)
        XCTAssertEqual(schliessen, !Chinchon.schliessKarten(hand.haende[0]).isEmpty)
    }
}
