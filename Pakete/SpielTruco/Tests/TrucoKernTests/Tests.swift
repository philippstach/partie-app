// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import TrucoKern

final class TrucoTests: XCTestCase {
    private func k(_ f: Int, _ r: Int) -> TrucoKarte { TrucoKarte(farbe: f, rang: r) }

    func testRangfolge() {
        XCTAssertGreaterThan(k(2, 1).staerke, k(3, 1).staerke)
        XCTAssertGreaterThan(k(3, 1).staerke, k(2, 7).staerke)
        XCTAssertGreaterThan(k(2, 7).staerke, k(0, 7).staerke)
        XCTAssertGreaterThan(k(0, 7).staerke, k(1, 3).staerke)
        XCTAssertGreaterThan(k(1, 3).staerke, k(1, 2).staerke)
        XCTAssertGreaterThan(k(1, 1).staerke, k(0, 12).staerke)
        XCTAssertGreaterThan(k(1, 10).staerke, k(1, 7).staerke)
        XCTAssertGreaterThan(k(1, 7).staerke, k(1, 6).staerke)
        XCTAssertEqual(k(1, 4).staerke, 1)
    }
    func testEnvido() {
        XCTAssertEqual(TrucoHand.envido([k(0, 7), k(0, 6), k(1, 1)]), 33)
        XCTAssertEqual(TrucoHand.envido([k(0, 12), k(0, 11), k(1, 1)]), 20)
        XCTAssertEqual(TrucoHand.envido([k(0, 7), k(1, 6), k(2, 1)]), 7)
    }
    func testEinfacheHand() {
        var h = TrucoHand(mano: 0, haende: [[k(2, 1), k(1, 4), k(1, 5)], [k(1, 6), k(0, 4), k(3, 5)]])
        XCTAssertTrue(h.spiele(0, karte: 0)); XCTAssertTrue(h.spiele(1, karte: 0))
        XCTAssertEqual(h.stiche, [0]); XCTAssertEqual(h.amZug, 0)
        XCTAssertTrue(h.spiele(0, karte: 0)); XCTAssertTrue(h.spiele(1, karte: 0))
        XCTAssertEqual(h.gewinner, 0)         // Stich 2 Parda (4 gegen 4): der erste Stich entscheidet
        XCTAssertEqual(h.stiche.count, 2)
    }
    func testErsteParda() {
        var h = TrucoHand(mano: 0, haende: [[k(0, 3), k(1, 4), k(1, 5)], [k(1, 3), k(0, 4), k(3, 6)]])
        h.spiele(0, karte: 0); h.spiele(1, karte: 0)
        XCTAssertEqual(h.stiche, [nil]); XCTAssertEqual(h.amZug, 0)
        h.spiele(0, karte: 0); h.spiele(1, karte: 1)       // 4 gegen 6: Spieler 1 gewinnt
        XCTAssertEqual(h.gewinner, 1)
        XCTAssertEqual(h.handPunkte, [0, 1])
    }
    func testTrucoAblehnenUndSteigern() {
        var h = TrucoHand(mano: 0, haende: [[k(2, 1), k(1, 4), k(1, 5)], [k(1, 6), k(0, 4), k(3, 5)]])
        XCTAssertFalse(h.rufe(0, .truco(stufe: 3)))
        XCTAssertTrue(h.rufe(0, .truco(stufe: 2)))
        XCTAssertFalse(h.spiele(0, karte: 0))             // offener Ruf
        XCTAssertTrue(h.antworte(1, annehmen: true))
        XCTAssertEqual(h.einsatz, 2)
        XCTAssertFalse(h.kannRufen(0, .truco(stufe: 3)))  // nur der Gegner darf steigern
        XCTAssertTrue(h.rufe(1, .truco(stufe: 3)))
        XCTAssertTrue(h.antworte(0, annehmen: false))
        XCTAssertEqual(h.gewinner, 1); XCTAssertEqual(h.handPunkte, [0, 2])
    }
    func testTrucoAblehnenGibtEinenPunkt() {
        var h = TrucoHand(mano: 0, haende: [[k(2, 1), k(1, 4), k(1, 5)], [k(1, 6), k(0, 4), k(3, 5)]])
        h.rufe(0, .truco(stufe: 2)); h.antworte(1, annehmen: false)
        XCTAssertEqual(h.handPunkte, [1, 0])
    }
    func testEnvidoAnnahme() {
        var h = TrucoHand(mano: 0, haende: [[k(0, 7), k(0, 6), k(1, 1)], [k(2, 5), k(1, 4), k(3, 1)]])
        XCTAssertTrue(h.rufe(1, .envido))
        XCTAssertTrue(h.antworte(0, annehmen: true))
        XCTAssertEqual(h.envidoPunkte, [2, 0])
        XCTAssertFalse(h.kannRufen(0, .envido))
    }
    func testPassen() {
        var h = TrucoHand(mano: 0, haende: [[k(2, 1), k(1, 4), k(1, 5)], [k(1, 6), k(0, 4), k(3, 5)]])
        h.passe(0); XCTAssertEqual(h.gewinner, 1); XCTAssertEqual(h.handPunkte, [0, 1])
    }
    func testAlleStufenEnden() {
        for stufe in 1...3 {
            for _ in 0..<30 {
                var g = SystemRandomNumberGenerator(); var p = TrucoPartie(mit: &g); var n = 0
                while p.gewinner == nil && n < 5000 {
                    n += 1
                    if p.hand.vorbei { p.handAbschliessen(mit: &g); continue }
                    if let o = p.hand.offen { _ = p.hand.antworte(1 - o.von, annehmen: TrucoComputer.antwort(p.hand, spieler: 1 - o.von, stufe: stufe)); continue }
                    let s = p.hand.amZug
                    switch TrucoComputer.aktion(p.hand, spieler: s, stufe: stufe) {
                    case .spiele(let i): XCTAssertTrue(p.hand.spiele(s, karte: i))
                    case .ruf(let a): XCTAssertTrue(p.hand.rufe(s, a))
                    case .passen: p.hand.passe(s)
                    }
                }
                XCTAssertNotNil(p.gewinner)
            }
        }
    }
    func testComputerPartienEnden() {
        for _ in 0..<60 {
            var g = SystemRandomNumberGenerator(); var p = TrucoPartie(mit: &g); var n = 0
            while p.gewinner == nil && n < 5000 {
                n += 1
                if p.hand.vorbei { p.handAbschliessen(mit: &g); continue }
                if let o = p.hand.offen { _ = p.hand.antworte(1 - o.von, annehmen: TrucoComputer.antwort(p.hand, spieler: 1 - o.von)); continue }
                let s = p.hand.amZug
                switch TrucoComputer.aktion(p.hand, spieler: s) {
                case .spiele(let i): XCTAssertTrue(p.hand.spiele(s, karte: i))
                case .ruf(let a): XCTAssertTrue(p.hand.rufe(s, a))
                case .passen: p.hand.passe(s)
                }
            }
            XCTAssertNotNil(p.gewinner)
        }
    }

    private func siegquote(stufe0: Int, stufe1: Int, partien: Int) -> Double {
        var siege = 0
        for _ in 0..<partien {
            var g = SystemRandomNumberGenerator(); var p = TrucoPartie(mit: &g); var n = 0
            while p.gewinner == nil && n < 5000 {
                n += 1
                if p.hand.vorbei { p.handAbschliessen(mit: &g); continue }
                if let o = p.hand.offen {
                    let w = 1 - o.von
                    _ = p.hand.antworte(w, annehmen: TrucoComputer.antwort(p.hand, spieler: w, stufe: w == 0 ? stufe0 : stufe1)); continue
                }
                let s = p.hand.amZug
                switch TrucoComputer.aktion(p.hand, spieler: s, stufe: s == 0 ? stufe0 : stufe1) {
                case .spiele(let i): XCTAssertTrue(p.hand.spiele(s, karte: i))
                case .ruf(let a): XCTAssertTrue(p.hand.rufe(s, a))
                case .passen: p.hand.passe(s)
                }
            }
            if p.gewinner == 0 { siege += 1 }
        }
        return Double(siege) / Double(partien)
    }
    func testSchwerSchlaegtLeicht() { XCTAssertGreaterThan(siegquote(stufe0: 3, stufe1: 1, partien: 400), 0.6) }
    func testMittelSchlaegtLeicht() { XCTAssertGreaterThan(siegquote(stufe0: 2, stufe1: 1, partien: 400), 0.55) }
    func testSchwerNichtSchlechterAlsMittel() { XCTAssertGreaterThan(siegquote(stufe0: 3, stufe1: 2, partien: 400), 0.45) }
}

final class TrucoRegelnTests: XCTestCase {
    private func k(_ f: Int, _ r: Int) -> TrucoKarte { TrucoKarte(farbe: f, rang: r) }
    private func hand(_ a: [TrucoKarte], _ b: [TrucoKarte], mano: Int = 0) -> TrucoHand { TrucoHand(mano: mano, haende: [a, b]) }

    func testBlattHat40KartenOhneAchtUndNeun() {
        var g = SystemRandomNumberGenerator(); let h = TrucoHand(mano: 0, mit: &g)
        let alle = h.haende.flatMap { $0 }
        XCTAssertEqual(alle.count, 6); XCTAssertEqual(Set(alle).count, 6)
        XCTAssertTrue(alle.allSatisfy { ![8, 9].contains($0.rang) })
    }
    func testNurDerAmZugDarfSpielen() {
        var h = hand([k(0, 4), k(1, 4), k(2, 4)], [k(0, 5), k(1, 5), k(2, 5)])
        XCTAssertFalse(h.spiele(1, karte: 0)); XCTAssertTrue(h.spiele(0, karte: 0)); XCTAssertFalse(h.spiele(0, karte: 0))
    }
    func testStichgewinnerFuehrtDenNaechstenStichAn() {
        var h = hand([k(0, 4), k(1, 4), k(2, 4)], [k(2, 1), k(1, 5), k(0, 5)])
        h.spiele(0, karte: 0); h.spiele(1, karte: 0)
        XCTAssertEqual(h.stiche, [1]); XCTAssertEqual(h.amZug, 1)
    }
    func testZweiStichePardaDrittenEntscheidetDerDritte() {
        var h = hand([k(0, 4), k(1, 5), k(2, 12)], [k(1, 4), k(0, 5), k(3, 10)])
        h.spiele(0, karte: 0); h.spiele(1, karte: 0)       // Parda
        h.spiele(0, karte: 0); h.spiele(1, karte: 0)       // Parda
        h.spiele(0, karte: 0); h.spiele(1, karte: 0)       // 12 sticht 10
        XCTAssertEqual(h.gewinner, 0)
    }
    func testDreimalPardaGewinntDieMano() {
        var h = hand([k(0, 4), k(1, 5), k(2, 6)], [k(1, 4), k(0, 5), k(3, 6)], mano: 1)
        h.spiele(1, karte: 0); h.spiele(0, karte: 0); h.spiele(1, karte: 0); h.spiele(0, karte: 0); h.spiele(1, karte: 0); h.spiele(0, karte: 0)
        XCTAssertEqual(h.gewinner, 1)
    }
    func testErsterSticheGewinnerGewinntBeiPardaImZweiten() {
        var h = hand([k(2, 1), k(1, 4), k(1, 5)], [k(1, 6), k(0, 4), k(3, 5)])
        h.spiele(0, karte: 0); h.spiele(1, karte: 0); h.spiele(0, karte: 0); h.spiele(1, karte: 0)
        XCTAssertEqual(h.gewinner, 0); XCTAssertEqual(h.stiche, [0, nil])
    }
    func testEnvidoGleichstandGewinntDieMano() {
        var h = hand([k(0, 7), k(0, 6), k(1, 1)], [k(1, 7), k(1, 6), k(2, 1)], mano: 1)
        h.rufe(0, .envido); h.antworte(1, annehmen: true)
        XCTAssertEqual(h.envidoPunkte, [0, 2])
    }
    func testEnvidoAblehnenGibtDemRuferEinenPunkt() {
        var h = hand([k(0, 7), k(0, 6), k(1, 1)], [k(1, 5), k(2, 6), k(3, 1)])
        h.rufe(0, .envido); h.antworte(1, annehmen: false)
        XCTAssertEqual(h.envidoPunkte, [1, 0]); XCTAssertEqual(h.envidoLog, "abgelehnt")
    }
    func testEnvidoNurVorDemErstenStich() {
        var h = hand([k(0, 4), k(1, 4), k(2, 4)], [k(2, 1), k(1, 5), k(0, 5)])
        h.spiele(0, karte: 0); XCTAssertFalse(h.kannRufen(0, .envido)); XCTAssertTrue(h.kannRufen(1, .envido))     // wer schon gespielt hat, darf nicht mehr; der Gegner noch
        h.spiele(1, karte: 0); XCTAssertFalse(h.kannRufen(0, .envido)); XCTAssertFalse(h.kannRufen(1, .envido))
    }
    func testEnvidoMitBildernZaehltNull() {
        XCTAssertEqual(TrucoHand.envido([k(0, 12), k(1, 11), k(2, 10)]), 0)
        XCTAssertEqual(TrucoHand.envido([k(0, 12), k(0, 5), k(2, 10)]), 25)
        XCTAssertEqual(TrucoHand.envido([k(0, 7), k(1, 7), k(2, 7)]), 7)
    }
    func testSteigernNurAbwechselndBisValeCuatro() {
        var h = hand([k(2, 1), k(1, 4), k(1, 5)], [k(1, 6), k(0, 4), k(3, 5)])
        h.rufe(0, .truco(stufe: 2)); h.antworte(1, annehmen: true)
        h.rufe(1, .truco(stufe: 3)); h.antworte(0, annehmen: true)
        XCTAssertEqual(h.einsatz, 3); XCTAssertFalse(h.kannRufen(1, .truco(stufe: 4)))
        XCTAssertTrue(h.rufe(0, .truco(stufe: 4))); h.antworte(1, annehmen: true)
        XCTAssertEqual(h.einsatz, 4); XCTAssertFalse(h.kannRufen(1, .truco(stufe: 5)))
    }
    func testGewinnerBekommtDenEingesetztenEinsatz() {
        var h = hand([k(2, 1), k(1, 4), k(1, 5)], [k(1, 6), k(0, 4), k(3, 5)])
        h.rufe(0, .truco(stufe: 2)); h.antworte(1, annehmen: true)
        h.spiele(0, karte: 0); h.spiele(1, karte: 0); h.spiele(0, karte: 0); h.spiele(1, karte: 0)
        XCTAssertEqual(h.handPunkte, [2, 0])
    }
    func testPartieZaehltHandUndEnvidoUndEndetBei15() {
        var g = SystemRandomNumberGenerator(); var p = TrucoPartie(mit: &g)
        p.hand = TrucoHand(mano: 0, haende: [[k(2, 1), k(1, 4), k(1, 5)], [k(1, 6), k(0, 4), k(3, 5)]])
        p.hand.rufe(1, .envido); p.hand.antworte(0, annehmen: true)
        p.hand.passe(1)
        p.handAbschliessen(mit: &g)
        XCTAssertEqual(p.punkte[0] + p.punkte[1], 1 + 2); XCTAssertNil(p.gewinner)
    }
    func testComputerAntwortIstBeiSchwacherHandSchwerAblehnendBeiTruco() {
        var h = hand([k(0, 4), k(1, 4), k(2, 4)], [k(0, 5), k(1, 5), k(2, 5)])
        h.rufe(0, .truco(stufe: 2))
        var ja = 0; for _ in 0..<200 { if TrucoComputer.antwort(h, spieler: 1, stufe: 3) { ja += 1 } }
        XCTAssertLessThan(ja, 100)
    }
    func testComputerRuftEnvidoMitSehrGuterEnvidoHandUndNimmtStarkeAn() {
        let h = hand([k(0, 7), k(0, 6), k(1, 1)], [k(1, 5), k(2, 6), k(3, 1)])
        XCTAssertEqual(TrucoComputer.aktion(h, spieler: 0, stufe: 3), .ruf(.envido))
        var h2 = h; h2.rufe(1, .envido)
        XCTAssertTrue(TrucoComputer.antwort(h2, spieler: 0, stufe: 3))
    }
}
