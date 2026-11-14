// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import PaarsucheKern

final class PaarsucheTests: XCTestCase {
    func testJedesMotivZweimal() {
        var g = SystemRandomNumberGenerator(); let s = Paarsuche(paare: 8, spieler: 2, mit: &g)
        XCTAssertEqual(s.karten.count, 16)
        for m in 0..<8 { XCTAssertEqual(s.karten.filter { $0.motiv == m }.count, 2) }
    }
    func testDreiteKarteGesperrt() {
        var g = SystemRandomNumberGenerator(); var s = Paarsuche(paare: 6, spieler: 1, mit: &g)
        XCTAssertTrue(s.decke(0)); XCTAssertFalse(s.decke(0)); XCTAssertTrue(s.decke(1)); XCTAssertFalse(s.decke(2))
    }
    func testPaarBringtPunktUndBleibtAmZug() {
        var g = SystemRandomNumberGenerator(); var s = Paarsuche(paare: 6, spieler: 2, mit: &g)
        let a = 0, b = s.karten.indices.first { $0 != 0 && s.karten[$0].motiv == s.karten[0].motiv }!
        s.decke(a); s.decke(b)
        XCTAssertTrue(s.aufloesen()); XCTAssertEqual(s.punkte, [1, 0]); XCTAssertEqual(s.amZug, 0)
    }
    func testFehlversuchWechseltSpieler() {
        var g = SystemRandomNumberGenerator(); var s = Paarsuche(paare: 6, spieler: 3, mit: &g)
        let b = s.karten.indices.first { s.karten[$0].motiv != s.karten[0].motiv }!
        s.decke(0); s.decke(b)
        XCTAssertFalse(s.aufloesen()); XCTAssertEqual(s.amZug, 1)
    }
    func testComputerSpieltPartieZuEnde() {
        for staerke in [0.0, 0.6, 1.0] {
            var g = SystemRandomNumberGenerator(); var s = Paarsuche(paare: 10, spieler: 2, mit: &g)
            var n = 0
            while !s.vorbei && n < 2000 {
                s.vergiss(staerke: staerke, mit: &g)
                guard let a = s.computerWahl(staerke: staerke, mit: &g) else { break }
                s.decke(a)
                guard let b = s.computerWahl(staerke: staerke, mit: &g) else { break }
                s.decke(b); s.aufloesen(); n += 1
            }
            XCTAssertTrue(s.vorbei, "staerke \(staerke)")
            XCTAssertEqual(s.punkte.reduce(0, +), 10)
        }
    }
    func testPerfekterComputerIstSchnell() {
        var g = SystemRandomNumberGenerator(); var s = Paarsuche(paare: 10, spieler: 1, mit: &g)
        while !s.vorbei {
            let a = s.computerWahl(staerke: 1, mit: &g)!; s.decke(a)
            let b = s.computerWahl(staerke: 1, mit: &g)!; s.decke(b); s.aufloesen()
        }
        XCTAssertTrue(s.zuege <= 20, "Züge \(s.zuege)")
    }
}

final class PaarsucheRegelTests: XCTestCase {
    private func spiel(paare: Int = 6, spieler: Int = 2) -> Paarsuche { var g = SystemRandomNumberGenerator(); return Paarsuche(paare: paare, spieler: spieler, mit: &g) }
    private func zweiMitMotiv(_ s: Paarsuche, gleich: Bool) -> (Int, Int) {
        for i in s.karten.indices { for j in s.karten.indices where j > i && (s.karten[i].motiv == s.karten[j].motiv) == gleich { return (i, j) } }
        fatalError()
    }

    func testJedesMotivKommtZweimalVor() {
        let s = spiel(paare: 8)
        XCTAssertEqual(s.karten.count, 16)
        for m in 0..<8 { XCTAssertEqual(s.karten.filter { $0.motiv == m }.count, 2) }
    }
    func testPaarGibtPunktUndDerSpielerBleibtDran() {
        var s = spiel()
        let (a, b) = zweiMitMotiv(s, gleich: true)
        XCTAssertTrue(s.decke(a)); XCTAssertTrue(s.decke(b))
        XCTAssertTrue(s.aufloesen())
        XCTAssertEqual(s.punkte, [1, 0]); XCTAssertEqual(s.amZug, 0); XCTAssertEqual(s.paareGefunden, 1)
        XCTAssertEqual(s.karten[a].finder, 0); XCTAssertNil(s.gedaechtnis[a])
    }
    func testKeinPaarWechseltDenSpieler() {
        var s = spiel()
        let (a, b) = zweiMitMotiv(s, gleich: false)
        s.decke(a); s.decke(b)
        XCTAssertFalse(s.aufloesen())
        XCTAssertEqual(s.amZug, 1); XCTAssertEqual(s.punkte, [0, 0]); XCTAssertEqual(s.zuege, 1)
        XCTAssertNotNil(s.gedaechtnis[a], "Der Computer hat die Karte gesehen")
    }
    func testAufdeckenRegeln() {
        var s = spiel()
        XCTAssertTrue(s.decke(0))
        XCTAssertFalse(s.decke(0), "Schon offen")
        XCTAssertFalse(s.decke(99)); XCTAssertFalse(s.decke(-1))
        XCTAssertTrue(s.decke(1))
        XCTAssertFalse(s.decke(2), "Nur zwei Karten gleichzeitig")
        XCTAssertFalse(Paarsuche.aufloesenOhneZwei(s: spiel()))
    }
    func testGefundeneKartenKoennenNichtMehrGedecktWerden() {
        var s = spiel()
        let (a, b) = zweiMitMotiv(s, gleich: true)
        s.decke(a); s.decke(b); s.aufloesen()
        XCTAssertFalse(s.decke(a))
    }
    func testAllePaareGefundenBeendetDasSpiel() {
        var s = spiel(paare: 3, spieler: 1)
        while !s.vorbei {
            let frei = s.karten.indices.filter { !s.karten[$0].gefunden }
            let a = frei[0]; let b = frei.first { $0 != a && s.karten[$0].motiv == s.karten[a].motiv }!
            s.decke(a); s.decke(b); s.aufloesen()
        }
        XCTAssertEqual(s.punkte, [3]); XCTAssertEqual(s.zuege, 3)
    }
    func testRangfolgeNachPaaren() {
        var s = spiel(paare: 4, spieler: 3)
        // Spieler 1 findet ein Paar
        let (a, b) = zweiMitMotiv(s, gleich: false)
        s.decke(a); s.decke(b); s.aufloesen()
        let (c, d) = zweiMitMotiv(s, gleich: true)
        s.decke(c); s.decke(d); s.aufloesen()
        XCTAssertEqual(s.rangfolge.first, 1)
    }
    func testComputerNimmtEinBekanntesPaar() {
        var g = SystemRandomNumberGenerator()
        var s = spiel(paare: 6)
        let m = s.karten[0].motiv
        let a = 0, c = s.karten.indices.first { $0 != a && s.karten[$0].motiv == m }!
        let rest = s.karten.indices.filter { s.karten[$0].motiv != m }
        let b = rest[0]; let d = rest.first { s.karten[$0].motiv != s.karten[b].motiv }!
        s.decke(a); s.decke(b); s.aufloesen()       // kein Paar: der Computer merkt sich a und b
        s.decke(c); s.decke(d); s.aufloesen()       // kein Paar: c ist Partner von a
        for _ in 0..<20 { XCTAssertTrue([a, c].contains(s.computerWahl(staerke: 1, mit: &g)!)) }
        s.decke(a)
        for _ in 0..<20 { XCTAssertEqual(s.computerWahl(staerke: 1, mit: &g), c, "Zweite Karte: der gemerkte Partner") }
    }
    func testVergessenMitStaerkeNullLoeschtAlles() {
        var g = SystemRandomNumberGenerator()
        var s = spiel()
        let (a, b) = zweiMitMotiv(s, gleich: false)
        s.decke(a); s.decke(b); s.aufloesen()
        XCTAssertEqual(s.gedaechtnis.count, 2)
        s.vergiss(staerke: 0, mit: &g)
        XCTAssertTrue(s.gedaechtnis.isEmpty)
        s.decke(a); s.decke(b); s.aufloesen()
        s.vergiss(staerke: 1, mit: &g)
        XCTAssertEqual(s.gedaechtnis.count, 2, "Volle Stärke vergisst nichts")
    }
    func testSpielstandIstCodierbar() throws {
        var s = spiel(); s.decke(0)
        let neu = try JSONDecoder().decode(Paarsuche.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}

private extension Paarsuche {
    static func aufloesenOhneZwei(s: Paarsuche) -> Bool { var t = s; return t.aufloesen() }
}
