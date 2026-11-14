// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import BackgammonKern

final class BackgammonTests: XCTestCase {
    func testStart() {
        let b = Backgammon()
        XCTAssertEqual(b.punkte.filter { $0 > 0 }.reduce(0, +), 15); XCTAssertEqual(-b.punkte.filter { $0 < 0 }.reduce(0, +), 15)
        XCTAssertEqual(b.pips(1), 167); XCTAssertEqual(b.pips(2), 167)
    }
    func testZuegeUndSchlagen() {
        var p = [Int](repeating: 0, count: 24); p[10] = 1; p[8] = -1; p[0] = 14; p[23] = -14
        var b = Backgammon(punkte: p, dran: 1, wuerfel: [2, 3])
        XCTAssertTrue(b.zuege.contains(BgZug(von: 10, nach: 8, wuerfel: 2)))
        XCTAssertTrue(b.ziehe(BgZug(von: 10, nach: 8, wuerfel: 2)))
        XCTAssertEqual(b.bar[2], 1)
    }
    func testBarPflichtUndSperre() {
        var p = [Int](repeating: 0, count: 24); p[23 - 2] = -2   // Schwarz sperrt Eintrittspunkt für Würfel 3 (idx 21)
        let b = Backgammon(punkte: p, bar: [0, 1, 0], dran: 1, wuerfel: [3, 4])
        XCTAssertTrue(b.zuege.allSatisfy { $0.von == 24 })
        XCTAssertFalse(b.zuege.contains { $0.wuerfel == 3 }); XCTAssertTrue(b.zuege.contains { $0.wuerfel == 4 })
    }
    func testAbtragen() {
        var p = [Int](repeating: 0, count: 24); p[2] = 2; p[1] = 1; p[23] = -1
        var b = Backgammon(punkte: p, draussen: [0, 12, 14], dran: 1, wuerfel: [3, 6])
        XCTAssertTrue(b.zuege.contains(BgZug(von: 2, nach: -1, wuerfel: 3)))
        XCTAssertTrue(b.zuege.contains(BgZug(von: 2, nach: -1, wuerfel: 6)))   // größer: kein weiter hinten stehender Stein
        XCTAssertTrue(b.ziehe(BgZug(von: 2, nach: -1, wuerfel: 3))); XCTAssertEqual(b.draussen[1], 13)
    }
    func testComputerSpieltPartie() {
        var b = Backgammon(); var g = SystemRandomNumberGenerator(); var n = 0
        while b.gewinner == nil && n < 3000 {
            b.wuerfeln(mit: &g)
            for z in BackgammonComputer.zugfolge(b) { XCTAssertTrue(b.ziehe(z)) }
            if !b.wuerfel.isEmpty || b.gewinner == nil { b.aussetzen() }
            n += 1
        }
        XCTAssertNotNil(b.gewinner)
    }
}

final class VariantenTests: XCTestCase {
    func testPresetsAufstellung() {
        XCTAssertEqual(Backgammon(regeln: .standard).punkte, BgRegeln.standard.aufstellung)
        XCTAssertEqual(Backgammon(regeln: .aceyDeucey).bar, [0, 15, 15])
        let n = Backgammon(regeln: .nardy)
        XCTAssertEqual(n.punkte[23], 15); XCTAssertEqual(n.punkte[11], -15)
        let p = Backgammon(regeln: .plakoto)
        XCTAssertEqual(p.punkte[23], 15); XCTAssertEqual(p.punkte[0], -15)
    }
    func testAceyDeuceyStartVonBar() {
        var b = Backgammon(regeln: .aceyDeucey); b.setzeWurf(3, 5)
        XCTAssertTrue(b.zuege.allSatisfy { $0.von == 24 })
        XCTAssertFalse(b.zuege.isEmpty)
    }
    func testNardyKopfregelEinStein() {
        var b = Backgammon(regeln: .nardy)
        b.setzeWurf(3, 5)
        XCTAssertTrue(b.ziehe(BgZug(von: 23, nach: 20, wuerfel: 3)))
        XCTAssertTrue(b.zuege.allSatisfy { $0.von != 23 })          // zweiter Stein vom Kopf verboten
    }
    func testNardySchwarzZiehtUeberNull() {
        var b = Backgammon(punkte: BgRegeln.nardy.aufstellung, dran: 2, wuerfel: [], regeln: .nardy)
        b.setzeWurf(1, 2)
        XCTAssertTrue(b.zuege.contains(BgZug(von: 11, nach: 10, wuerfel: 1)))
        // Ein Stein von Punkt 0 zieht nach 23 (Weg 11→0→23→12)
        var p = [Int](repeating: 0, count: 24); p[0] = -1; p[11] = -14; p[22] = 15
        var c = Backgammon(punkte: p, dran: 2, wuerfel: [], regeln: .nardy)
        c.setzeWurf(1, 2)
        XCTAssertTrue(c.zuege.contains(BgZug(von: 0, nach: 23, wuerfel: 1)))
    }
    func testNardyKeinSchlagen() {
        var p = [Int](repeating: 0, count: 24); p[10] = -1; p[20] = 1; p[5] = -14; p[22] = 14
        var b = Backgammon(punkte: p, dran: 1, wuerfel: [], regeln: .nardy)
        b.setzeWurf(5, 5)                                   // 20-… trifft nicht: Weiß 20→15; Test: Ziel mit Gegner gesperrt
        XCTAssertFalse(b.zuege.contains { $0.von == 22 && $0.nach == 10 })
        XCTAssertEqual(b.bar, [0, 0, 0])
    }
    func testPlakotoPinSetztFestUndGibtFrei() {
        var p = [Int](repeating: 0, count: 24); p[10] = 1; p[8] = -1; p[20] = 14; p[1] = -14
        var b = Backgammon(punkte: p, dran: 2, wuerfel: [], regeln: .plakoto)
        b.setzeWurf(2, 1)
        XCTAssertTrue(b.ziehe(BgZug(von: 8, nach: 10, wuerfel: 2)))
        XCTAssertEqual(b.festgesetzt[10], 1)                // Weißer Stein sitzt fest
        XCTAssertEqual(b.punkte[10], -1)
        XCTAssertEqual(b.bar, [0, 0, 0])
        // Schwarz zieht weg → Weiß frei
        XCTAssertTrue(b.ziehe(BgZug(von: 10, nach: 11, wuerfel: 1)))
        XCTAssertEqual(b.festgesetzt[10], 0)
        XCTAssertEqual(b.punkte[10], 1)
    }
    func testAceyDeuceyBonusPaschUndNochmal() {
        var b = Backgammon(regeln: .aceyDeucey)
        b.setzeWurf(1, 2)
        let dran = b.dran
        // beide Würfel spielen (Steine von der Bar einsetzen)
        var z = 0
        while !b.wuerfel.isEmpty && z < 4 { z += 1; _ = b.ziehe(b.zuege[0]) }
        XCTAssertTrue(b.paschWahl); XCTAssertEqual(b.dran, dran)
        XCTAssertFalse(b.waehlePasch(7))
        XCTAssertTrue(b.waehlePasch(3)); XCTAssertEqual(b.wuerfel, [3, 3, 3, 3])
        z = 0
        while !b.wuerfel.isEmpty && z < 6 { z += 1; _ = b.ziehe(b.zuege[0]) }
        XCTAssertEqual(b.dran, dran)                       // derselbe Spieler würfelt noch einmal
        XCTAssertTrue(b.wuerfel.isEmpty); XCTAssertFalse(b.paschWahl)
    }
    func testKeinBonusBeiAndererWurfOderStandard() {
        var b = Backgammon(regeln: .aceyDeucey); b.setzeWurf(3, 4)
        while !b.wuerfel.isEmpty { _ = b.ziehe(b.zuege[0]) }
        XCTAssertFalse(b.paschWahl)
        var s = Backgammon(); s.setzeWurf(1, 2)
        while !s.wuerfel.isEmpty, let z = s.zuege.first { _ = s.ziehe(z) }
        XCTAssertFalse(s.paschWahl)
    }
    func testFehlerhafteZugfolgeIstLegal() {
        var g = SystemRandomNumberGenerator()
        for fehler in [0.0, 1.0] { for _ in 0..<20 {
            var b = Backgammon(); b.wuerfeln(mit: &g)
            let folge = BackgammonComputer.zugfolge(b, fehler: fehler, mit: &g)
            for z in folge { XCTAssertTrue(b.zuege.contains(z)); b.ziehe(z) }
        } }
    }
    func testBewertungStrafftEinzelsteinInReichweite() {
        // Weißer Einzelstein auf 10, schwarzer Stein auf 6 (4 Augen dahinter) vs. weißer Einzelstein auf 20 ohne Schwarze in Reichweite
        var nah = [Int](repeating: 0, count: 24); nah[10] = 1; nah[6] = -1; nah[0] = 1; nah[23] = -1
        var fern = [Int](repeating: 0, count: 24); fern[10] = 1; fern[0] = -1; nah[0] = 1; fern[23] = 1
        let a = Backgammon(punkte: nah, dran: 1), b = Backgammon(punkte: fern, dran: 1)
        XCTAssertNotEqual(BackgammonComputer.bewerte(a, fuer: 1), BackgammonComputer.bewerte(b, fuer: 1))
    }
    func testBesserAlsZufall() {
        var g = SystemRandomNumberGenerator(); var siege = 0
        for k in 0..<2 {
            var b = Backgammon(); let ich = k % 2 + 1; var n = 0
            while b.gewinner == nil && n < 600 {
                if b.wuerfel.isEmpty { b.wuerfeln(mit: &g) }
                if b.zuege.isEmpty { b.aussetzen() }
                else if b.dran == ich { for z in BackgammonComputer.zugfolge(b) { b.ziehe(z) } }
                else { b.ziehe(b.zuege.randomElement(using: &g)!) }
                n += 1
            }
            if b.gewinner == ich { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 1)
    }
}

final class BackgammonKITests: XCTestCase {
    private func leer() -> [Int] { [Int](repeating: 0, count: 24) }

    func testStufenSindGestaffelt() {
        XCTAssertGreaterThan(BackgammonStaerke.leicht.fehler, BackgammonStaerke.mittel.fehler)
        XCTAssertGreaterThan(BackgammonStaerke.mittel.fehler, BackgammonStaerke.schwer.fehler)
        XCTAssertEqual(BackgammonStaerke.schwer.fehler, 0)
    }
    func testJedeStufeSpieltNurLegaleZuege() {
        var g = SystemRandomNumberGenerator()
        for st in stufenFuerLauf(BackgammonStaerke.allCases) {
            var b = Backgammon(); var n = 0
            while b.gewinner == nil, n < 40 {
                b.wuerfeln(mit: &g)
                for z in BackgammonComputer.zugfolge(b, staerke: st) { XCTAssertTrue(b.ziehe(z), "\(st)") }
                if !b.wuerfel.isEmpty { b.aussetzen() }
                n += 1
            }
        }
    }
    func testSchwerSpieltAlleWuerfelWennMoeglich() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<10 {
            var b = Backgammon()
            b.wuerfeln(mit: &g)
            let erwartet = b.wuerfel.count
            let folge = BackgammonComputer.zugfolge(b)
            XCTAssertEqual(folge.count, erwartet)      // am Start sind immer alle Würfel spielbar
            for z in folge { XCTAssertTrue(b.ziehe(z)) }
        }
    }
    func testSchwerSchlaegtEinzelsteinInHeimfeldWennSicher() {
        // Weiß schlägt den Blot auf Punkt 3, statt ihn stehen zu lassen (Schwarz hat einen Stein auf Bar-Reichweite).
        var p = leer(); p[8] = 3; p[6] = 2; p[3] = -1; p[20] = 5; p[23] = -2; p[11] = 4
        let b = Backgammon(punkte: p, dran: 1, wuerfel: [5, 3])
        let folge = BackgammonComputer.zugfolge(b)
        var n = b; for z in folge { n.ziehe(z) }
        XCTAssertEqual(n.bar[2], 1)
    }
    func testSchwerTraegtMitPaschAb() {
        var p = leer(); p[0] = 2; p[1] = 2; p[2] = 2; p[18] = -1; p[19] = -1
        var b = Backgammon(punkte: p, draussen: [0, 9, 13], dran: 1, wuerfel: [3, 3, 3, 3])
        for z in BackgammonComputer.zugfolge(b) { XCTAssertTrue(b.ziehe(z)) }
        XCTAssertGreaterThanOrEqual(b.draussen[1], 12)
    }
    func testMussBeidenWuerfelSpielenWennBeidesGeht() {
        var p = leer(); p[10] = 1; p[23] = -1
        let b = Backgammon(punkte: p, draussen: [0, 14, 14], dran: 1, wuerfel: [4, 2])
        XCTAssertTrue(b.zuege.allSatisfy { $0.von == 10 })
        var n = b; n.ziehe(BgZug(von: 10, nach: 6, wuerfel: 4))
        XCTAssertEqual(n.zuege.map(\.wuerfel), [2])
    }
}

/// Debug-Läufe sind etwa zehnmal langsamer: dort nur die leichten und mittleren Stufen, im Release alle.
func stufenFuerLauf<S>(_ alle: [S]) -> [S] {
    #if DEBUG
    return Array(alle.prefix(2))
    #else
    return alle
    #endif
}
