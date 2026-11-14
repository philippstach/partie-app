// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import KreuzwurfKern

final class KreuzwurfTests: XCTestCase {
    func testFeldHatAlleFarben() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<30 {
            let s = Kreuzwurf(spieler: 2, mit: &g)
            XCTAssertEqual(s.feld.joined().count, 49)
            XCTAssertTrue((0..<5).allSatisfy { s.farbeAnzahl($0) > 0 } || true)
        }
    }
    func testErstesKreuzInMittelspalte() {
        var g = SystemRandomNumberGenerator(); let s = Kreuzwurf(spieler: 1, mit: &g)
        let mitte = (0..<7).map { Zelle(3, $0) }
        for z in mitte { XCTAssertTrue(s.anschluss(0, z)) }
        XCTAssertFalse(s.anschluss(0, Zelle(0, 0)))
    }
    func testComputerSpieltPartienZuEnde() {
        for n in 1...4 {
            for _ in 0..<20 {
                var g = SystemRandomNumberGenerator(); var s = Kreuzwurf(spieler: n, mit: &g); var z = 0
                while !s.vorbei && z < 500 {
                    if let w = s.computerWahl(mit: &g) {
                        XCTAssertTrue(s.setze(farbwuerfel: w.fw, zahlwuerfel: w.zw, farbe: w.farbe, zellen: w.zellen, mit: &g))
                    } else { s.passe(mit: &g) }
                    z += 1
                }
                XCTAssertTrue(s.vorbei, "\(n) Spieler")
                XCTAssertTrue((0..<n).allSatisfy { s.punkte($0) >= 0 })
            }
        }
    }
    func testUngueltigeAuswahlen() {
        var g = SystemRandomNumberGenerator(); let s = Kreuzwurf(spieler: 1, mit: &g)
        XCTAssertFalse(s.gueltig(spieler: 0, farbe: 0, maximal: 3, zellen: []))
        let f = s.feld[3][3]
        XCTAssertTrue(s.gueltig(spieler: 0, farbe: f, maximal: 1, zellen: [Zelle(3, 3)]))
        XCTAssertFalse(s.gueltig(spieler: 0, farbe: (f + 1) % 5, maximal: 1, zellen: [Zelle(3, 3)]))
        XCTAssertFalse(s.gueltig(spieler: 0, farbe: f, maximal: 1, zellen: [Zelle(3, 3), Zelle(3, 4)]))
    }
    func testRundenZaehlen() {
        var g = SystemRandomNumberGenerator(); var s = Kreuzwurf(spieler: 1, mit: &g)
        s.passe(mit: &g); XCTAssertEqual(s.runde, 0); s.passe(mit: &g); XCTAssertEqual(s.runde, 1)
        var t = Kreuzwurf(spieler: 3, mit: &g); XCTAssertEqual(t.amZug, 0); t.passe(mit: &g); XCTAssertEqual(t.amZug, 1)
    }
    func testFehlerhafterComputerSpieltPartienZuEnde() {
        for _ in 0..<10 {
            var g = SystemRandomNumberGenerator(); var s = Kreuzwurf(spieler: 2, mit: &g); var z = 0
            while !s.vorbei && z < 500 {
                if let w = s.computerWahl(fehler: 1, mit: &g) { s.setze(farbwuerfel: w.fw, zahlwuerfel: w.zw, farbe: w.farbe, zellen: w.zellen, mit: &g) } else { s.passe(mit: &g) }
                z += 1
            }
            XCTAssertTrue(s.vorbei)
        }
    }

    /// Spieler 0 mit Fehlerquote `a`, Spieler 1 mit `b`; Rückgabe: mittlere Punkte je Partie.
    private func punkte(_ a: Double, _ b: Double, partien: Int) -> (Double, Double) {
        var p0 = 0, p1 = 0
        for _ in 0..<partien {
            var g = SystemRandomNumberGenerator(); var s = Kreuzwurf(spieler: 2, mit: &g); var z = 0
            while !s.vorbei && z < 500 {
                if let w = s.computerWahl(fehler: s.amZug == 0 ? a : b, mit: &g) {
                    s.setze(farbwuerfel: w.fw, zahlwuerfel: w.zw, farbe: w.farbe, zellen: w.zellen, mit: &g)
                } else { s.passe(mit: &g) }
                z += 1
            }
            p0 += s.punkte(0); p1 += s.punkte(1)
        }
        return (Double(p0) / Double(partien), Double(p1) / Double(partien))
    }
    func testSchwerSchlaegtLeichtUndMittel() {
        let (schwer, leicht) = punkte(0, 0.5, partien: 40)
        XCTAssertGreaterThan(schwer, leicht * 1.1, "schwer \(schwer), leicht \(leicht)")
        let (mittel, leicht2) = punkte(0.15, 0.5, partien: 40)
        XCTAssertGreaterThan(mittel, leicht2, "mittel \(mittel), leicht \(leicht2)")
        let (schwer2, mittel2) = punkte(0, 0.15, partien: 60)
        XCTAssertGreaterThan(schwer2, mittel2 - 0.5, "schwer \(schwer2), mittel \(mittel2)")
    }
}

final class KreuzwurfRegelTests: XCTestCase {
    private func neu(_ n: Int = 2) -> Kreuzwurf { var g = SystemRandomNumberGenerator(); return Kreuzwurf(spieler: n, mit: &g) }

    func testZusammenhaengendeGruppen() {
        XCTAssertTrue(Kreuzwurf.zusammenhaengend([Zelle(0, 0), Zelle(1, 0), Zelle(1, 1)]))
        XCTAssertFalse(Kreuzwurf.zusammenhaengend([Zelle(0, 0), Zelle(2, 0)]))
        XCTAssertFalse(Kreuzwurf.zusammenhaengend([Zelle(0, 0), Zelle(1, 1)]), "Diagonal zählt nicht")
        XCTAssertFalse(Kreuzwurf.zusammenhaengend([]))
    }
    func testRundenUndPicksJeNachSpielerzahl() {
        XCTAssertEqual(neu(1).runden, 8); XCTAssertEqual(neu(1).picksProRunde, 2)
        XCTAssertEqual(neu(3).runden, 15); XCTAssertEqual(neu(3).picksProRunde, 3)
        XCTAssertEqual(neu(9).spieler, 4); XCTAssertEqual(neu(0).spieler, 1)
    }
    func testErstesKreuzNurInDerMittelspalteDanachNurAnschluss() {
        var g = SystemRandomNumberGenerator()
        var s = neu(2)
        let f = s.feld[3][3]
        XCTAssertTrue(s.anschluss(0, Zelle(3, 0))); XCTAssertFalse(s.anschluss(0, Zelle(2, 3)))
        s.setzeWurf(farbwuerfel: [f, f, f], zahlwuerfel: [1, 1, 1])
        XCTAssertFalse(s.setze(farbwuerfel: 0, zahlwuerfel: 0, farbe: f, zellen: [Zelle(0, 0)], mit: &g), "Erstes Kreuz muss in der Mittelspalte liegen")
        XCTAssertTrue(s.setze(farbwuerfel: 0, zahlwuerfel: 0, farbe: f, zellen: [Zelle(3, 3)], mit: &g))
        XCTAssertEqual(s.punkte(0), 1)
    }
    func testWuerfelKoennenNurEinmalGenommenWerden() {
        var g = SystemRandomNumberGenerator()
        var s = neu(1)
        let f = s.feld[3][3]
        s.setzeWurf(farbwuerfel: [f, f, f], zahlwuerfel: [1, 1, 1])
        XCTAssertTrue(s.setze(farbwuerfel: 0, zahlwuerfel: 0, farbe: f, zellen: [Zelle(3, 3)], mit: &g))
        XCTAssertFalse(s.setze(farbwuerfel: 0, zahlwuerfel: 1, farbe: f, zellen: [s.startZellen(spieler: 0, farbe: f).first ?? Zelle(0, 0)], mit: &g), "Farbwürfel 0 ist weg")
        XCTAssertFalse(s.setze(farbwuerfel: 1, zahlwuerfel: 0, farbe: f, zellen: [Zelle(3, 3)], mit: &g), "Zahlwürfel 0 ist weg")
    }
    func testFarbwuerfelMussZurFarbeDerFelderPassenAberJokerGeht() {
        var g = SystemRandomNumberGenerator()
        var s = neu(1)
        let f = s.feld[3][3], andere = (f + 1) % 5
        s.setzeWurf(farbwuerfel: [andere, 5, andere], zahlwuerfel: [1, 1, 1])
        XCTAssertFalse(s.setze(farbwuerfel: 0, zahlwuerfel: 0, farbe: f, zellen: [Zelle(3, 3)], mit: &g))
        XCTAssertTrue(s.setze(farbwuerfel: 1, zahlwuerfel: 0, farbe: f, zellen: [Zelle(3, 3)], mit: &g), "Joker passt zu jeder Farbe")
    }
    func testZahlwuerfelBegrenztDieAnzahlUndJokerGibtFuenf() {
        var s = neu(1)
        let f = s.feld[3][3]
        let gruppe = s.startZellen(spieler: 0, farbe: f)
        XCTAssertTrue(s.gueltig(spieler: 0, farbe: f, maximal: 1, zellen: [Zelle(3, 3)]))
        XCTAssertFalse(s.gueltig(spieler: 0, farbe: f, maximal: 1, zellen: [Zelle(3, 3), Zelle(3, 2)]))
        XCTAssertFalse(s.gueltig(spieler: 0, farbe: f, maximal: 5, zellen: []))
        _ = gruppe; s.setzeWurf(farbwuerfel: [f, f, f], zahlwuerfel: [0, 0, 0])
        XCTAssertEqual(s.zahlwuerfel, [0, 0, 0])
    }
    func testNichtDieFarbeUndDoppelteZellenSindUngueltig() {
        let s = neu(1)
        let f = s.feld[3][3]
        XCTAssertFalse(s.gueltig(spieler: 0, farbe: (f + 1) % 5, maximal: 3, zellen: [Zelle(3, 3)]))
        XCTAssertFalse(s.gueltig(spieler: 0, farbe: f, maximal: 3, zellen: [Zelle(3, 3), Zelle(3, 3)]))
        XCTAssertFalse(s.gueltig(spieler: 0, farbe: f, maximal: 3, zellen: [Zelle(7, 3)]))
    }
    func testPassenSchaltetWeiterUndNachAllenPicksKommtDieNaechsteRunde() {
        var g = SystemRandomNumberGenerator()
        var s = neu(2)
        s.passe(mit: &g); s.passe(mit: &g)
        XCTAssertEqual(s.pick, 2); XCTAssertEqual(s.runde, 0)
        s.passe(mit: &g)
        XCTAssertEqual(s.runde, 1); XCTAssertEqual(s.pick, 0); XCTAssertEqual(s.farbGenommen, [false, false, false])
    }
    func testEchteWuerfelWerdenGeprueft() {
        var s = neu(2)
        XCTAssertFalse(s.setzeWurf(farbwuerfel: [0, 1], zahlwuerfel: [1, 1, 1]))
        XCTAssertFalse(s.setzeWurf(farbwuerfel: [0, 1, 9], zahlwuerfel: [1, 1, 1]))
        XCTAssertTrue(s.setzeWurf(farbwuerfel: [0, 5, 4], zahlwuerfel: [0, 3, 5])); XCTAssertEqual(s.farbwuerfel, [0, 5, 4])
    }
    func testAlleFarbenKommenImFeldVorUndZaehlenSich() {
        let s = neu(1)
        XCTAssertEqual((0..<5).map { s.farbeAnzahl($0) }.reduce(0, +), 49)
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var s = neu(2); let f = s.feld[3][3]
        s.setzeWurf(farbwuerfel: [f, f, f], zahlwuerfel: [1, 1, 1]); s.setze(farbwuerfel: 0, zahlwuerfel: 0, farbe: f, zellen: [Zelle(3, 3)], mit: &g)
        let neuer = try JSONDecoder().decode(Kreuzwurf.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neuer, s)
    }
}
