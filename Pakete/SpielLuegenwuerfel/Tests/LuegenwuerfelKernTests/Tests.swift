// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import LuegenwuerfelKern

final class LuegenwuerfelTests: XCTestCase {
    func testGebotRang() { XCTAssertTrue(Gebot(3, 2).hoeherAls(Gebot(2, 6))); XCTAssertTrue(Gebot(2, 4).hoeherAls(Gebot(2, 3))); XCTAssertFalse(Gebot(2, 3).hoeherAls(Gebot(2, 3))) }
    func testAblauf() {
        var s = Luegenwuerfel(spieler: 2); var g = SystemRandomNumberGenerator(); s.neueRunde(mit: &g)
        XCTAssertEqual(s.wuerfel.map(\.count), [5, 5])
        XCTAssertTrue(s.biete(Gebot(1, 3))); XCTAssertFalse(s.biete(Gebot(1, 2))); XCTAssertEqual(s.dran, 1)
        let r = s.zweifeln()!; XCTAssertEqual(s.anzahlen.reduce(0, +), 9); XCTAssertTrue([0, 1].contains(r.verlierer))
    }
    func testSpielEnde() {
        var s = Luegenwuerfel(spieler: 3); var g = SystemRandomNumberGenerator(); var n = 0
        s.neueRunde(mit: &g)
        while s.sieger == nil && n < 3000 {
            if s.gebot != nil, LuegenwuerfelComputer.zweifelt(s, spieler: s.dran) || s.gebot!.anzahl >= s.gesamt {
                let r = s.zweifeln()!; s.neueRunde(beginnt: r.verlierer, mit: &g)
            } else { XCTAssertTrue(s.biete(LuegenwuerfelComputer.gebot(s, spieler: s.dran))) }
            n += 1
        }
        XCTAssertNotNil(s.sieger)
    }
    // MARK: Perudo
    private func perudo(_ w: [[Int]], anzahlen: [Int]? = nil) -> Luegenwuerfel {
        var s = Luegenwuerfel(spieler: w.count, regeln: .perudo); var g = SystemRandomNumberGenerator()
        s.neueRunde(mit: &g); s.testWuerfel(w)
        return s
    }
    func testEinserSindJoker() {
        let s = perudo([[1, 2, 3, 3, 4], [1, 5, 6, 3, 2]])
        XCTAssertEqual(s.zaehle(3), 3 + 2); XCTAssertEqual(s.zaehle(1), 2, "Einser zählen bei Gebot auf Einser nur selbst")
        let st = Luegenwuerfel(spieler: 2)
        XCTAssertEqual(st.regeln, .standard)
    }
    func testEroeffnungNichtAufEinser() {
        let s = perudo([[2, 2, 2, 2, 2], [3, 3, 3, 3, 3]])
        XCTAssertFalse(s.erlaubt(Gebot(1, 1), nach: nil)); XCTAssertTrue(s.erlaubt(Gebot(1, 2), nach: nil))
    }
    func testSteigerungMitEinsern() {
        let s = perudo([[2, 2, 2, 2, 2], [3, 3, 3, 3, 3]])
        XCTAssertTrue(s.erlaubt(Gebot(3, 1), nach: Gebot(5, 4)), "5 -> halbe Anzahl aufgerundet = 3 Einser")
        XCTAssertFalse(s.erlaubt(Gebot(2, 1), nach: Gebot(5, 4)))
        XCTAssertTrue(s.erlaubt(Gebot(7, 2), nach: Gebot(3, 1)), "Einser 3 -> 2*3+1 = 7")
        XCTAssertFalse(s.erlaubt(Gebot(6, 2), nach: Gebot(3, 1)))
        XCTAssertTrue(s.erlaubt(Gebot(4, 1), nach: Gebot(3, 1))); XCTAssertFalse(s.erlaubt(Gebot(3, 1), nach: Gebot(3, 1)))
        XCTAssertTrue(s.erlaubt(Gebot(5, 5), nach: Gebot(5, 4)))
    }
    func testCalza() {
        var s = perudo([[1, 2, 3, 3, 4], [4, 3, 6, 6, 5]])
        XCTAssertTrue(s.biete(Gebot(5, 3)))     // 3er: 3, dazu 1 Einser = 3+1 = ... gezählt prüfen
        let gez = s.zaehle(3)
        s.testAnzahlen([3, 5])
        let r = s.calzaRufen()!
        XCTAssertEqual(r.richtig, gez == 5)
        XCTAssertEqual(s.anzahlen[1], r.richtig ? 5 : 4)
        var t = Luegenwuerfel(spieler: 2); var g = SystemRandomNumberGenerator(); t.neueRunde(mit: &g)
        t.biete(Gebot(1, 2)); XCTAssertNil(t.calzaRufen(), "Standard kennt kein Calza")
    }
    func testCalzaRichtigGibtWuerfelHoechstensStart() {
        var s = perudo([[2, 2, 3, 4, 5], [6, 6, 6, 1, 1]])
        XCTAssertTrue(s.biete(Gebot(4, 6)))     // 3 sechsen + 2 einser = 5? -> Gebot 5 genau
        XCTAssertEqual(s.zaehle(6), 5)
        XCTAssertFalse(s.calzaRufen()!.richtig)
        var t = perudo([[2, 2, 3, 4, 5], [6, 6, 6, 1, 1]])
        XCTAssertTrue(t.biete(Gebot(5, 6)))
        let r = t.calzaRufen()!
        XCTAssertTrue(r.richtig); XCTAssertEqual(t.anzahlen[1], 5, "höchstens Startzahl")
    }
    func testPalifico() {
        var s = Luegenwuerfel(spieler: 3, regeln: .perudo); var g = SystemRandomNumberGenerator()
        s.testAnzahlen([1, 3, 3]); s.neueRunde(beginnt: 0, mit: &g)
        XCTAssertTrue(s.palificoRunde)
        XCTAssertTrue(s.biete(Gebot(2, 4)))
        XCTAssertFalse(s.erlaubt(Gebot(2, 5), nach: s.gebot), "Augenzahl bleibt fest")
        XCTAssertTrue(s.erlaubt(Gebot(3, 4), nach: s.gebot))
        s.testWuerfel([[1], [4, 4, 1], [2, 2, 4]])
        XCTAssertEqual(s.zaehle(4), 3, "Einser sind in Palifico kein Joker")
        s.neueRunde(beginnt: 0, mit: &g)
        XCTAssertFalse(s.palificoRunde, "Palifico nur einmal je Spieler")
    }
    func testKeinPalificoZuZweit() {
        var s = Luegenwuerfel(spieler: 2, regeln: .perudo); var g = SystemRandomNumberGenerator()
        s.testAnzahlen([1, 3]); s.neueRunde(beginnt: 0, mit: &g)
        XCTAssertFalse(s.palificoRunde)
    }
    func testPerudoSpielEndeMitComputer() {
        for _ in 0..<30 {
            var s = Luegenwuerfel(spieler: 4, regeln: .perudo); var g = SystemRandomNumberGenerator(); var n = 0
            s.neueRunde(mit: &g)
            while s.sieger == nil && n < 5000 {
                let i = s.dran
                if s.gebot != nil, LuegenwuerfelComputer.ruftCalza(s, spieler: i), let r = s.calzaRufen() {
                    _ = r; s.neueRunde(beginnt: s.sieger == nil && s.anzahlen[i] > 0 ? i : nil, mit: &g)
                } else if let b = s.gebot, LuegenwuerfelComputer.zweifelt(s, spieler: i) || b.anzahl >= s.gesamt {
                    let r = s.zweifeln()!; if s.sieger == nil { s.neueRunde(beginnt: r.verlierer, mit: &g) }
                } else { XCTAssertTrue(s.biete(LuegenwuerfelComputer.gebot(s, spieler: i))) }
                n += 1
            }
            XCTAssertNotNil(s.sieger, "Perudo-Partie endet")
        }
    }


    /// Zwei Spieler: der Computer (Spieler 0) gegen einen naiven Gegner, der zufällig bietet und zu 30 % zweifelt.
    func testComputerSchlaegtNaivenGegner() {
        var siege = 0; let partien = 300
        for _ in 0..<partien {
            var s = Luegenwuerfel(spieler: 2); var g = SystemRandomNumberGenerator(); var n = 0
            s.neueRunde(mit: &g)
            while s.sieger == nil && n < 5000 {
                let i = s.dran
                let zweifeln: Bool
                if let b = s.gebot {
                    zweifeln = i == 0 ? (LuegenwuerfelComputer.zweifelt(s, spieler: 0) || b.anzahl >= s.gesamt) : (Double.random(in: 0..<1) < 0.3 || b.anzahl >= s.gesamt)
                } else { zweifeln = false }
                if zweifeln {
                    let r = s.zweifeln()!; if s.sieger == nil { s.neueRunde(beginnt: r.verlierer, mit: &g) }
                } else if i == 0 {
                    XCTAssertTrue(s.biete(LuegenwuerfelComputer.gebot(s, spieler: 0)))
                } else {
                    let moegliche = (1...max(1, s.gesamt)).flatMap { a in (1...6).map { Gebot(a, $0) } }.filter { s.erlaubt($0, nach: s.gebot) }
                    XCTAssertTrue(s.biete(moegliche.randomElement() ?? Gebot(1, 6)))
                }
                n += 1
            }
            XCTAssertNotNil(s.sieger)
            if s.sieger == 0 { siege += 1 }
        }
        XCTAssertGreaterThan(Double(siege) / Double(partien), 0.55, "Computer gewann \(siege) von \(partien)")
    }

    private func quote(_ a: Int, _ b: Int, partien: Int) -> Double {
        var siege = 0
        for _ in 0..<partien {
            var s = Luegenwuerfel(spieler: 2); var g = SystemRandomNumberGenerator(); var n = 0
            s.neueRunde(mit: &g)
            while s.sieger == nil && n < 5000 {
                let i = s.dran; let stufe = i == 0 ? a : b
                if let bt = s.gebot, LuegenwuerfelComputer.zweifelt(s, spieler: i, stufe: stufe) || bt.anzahl >= s.gesamt {
                    let r = s.zweifeln()!; if s.sieger == nil { s.neueRunde(beginnt: r.verlierer, mit: &g) }
                } else { XCTAssertTrue(s.biete(LuegenwuerfelComputer.gebot(s, spieler: i))) }
                n += 1
            }
            XCTAssertNotNil(s.sieger)
            if s.sieger == 0 { siege += 1 }
        }
        return Double(siege) / Double(partien)
    }
    /// Der Anfangsvorteil ist durch vertauschte Rollen herausgerechnet.
    func testSchwerSchlaegtMittelSchlaegtLeicht() {
        let schwer = quote(3, 2, partien: 600), mittelGegenSchwer = quote(2, 3, partien: 600)
        XCTAssertGreaterThan(schwer, mittelGegenSchwer + 0.2, "schwer auf Platz 0: \(schwer), mittel auf Platz 0: \(mittelGegenSchwer)")
        let mittel = quote(2, 1, partien: 600), leichtGegenMittel = quote(1, 2, partien: 600)
        XCTAssertGreaterThan(mittel, leichtGegenMittel, "mittel auf Platz 0: \(mittel), leicht auf Platz 0: \(leichtGegenMittel)")
    }
}

final class LuegenwuerfelTippTests: XCTestCase {
    func testWahrheitsChanceGrenzen() {
        var s = Luegenwuerfel(spieler: 3); var g = SystemRandomNumberGenerator()
        s.neueRunde(mit: &g)
        XCTAssertTrue(s.biete(Gebot(15, 6)) || s.gebot == nil)
        s.neueRunde(mit: &g); s.biete(Gebot(1, 2))
        let p1 = LuegenwuerfelComputer.wahrheitsChance(s, spieler: s.dran)
        XCTAssertGreaterThan(p1, 0.5)                                    // ein Würfel von 14 fremden: sehr wahrscheinlich
        s.neueRunde(mit: &g); s.biete(Gebot(15, 6))
        XCTAssertEqual(LuegenwuerfelComputer.wahrheitsChance(s, spieler: s.dran), 0, accuracy: 0.01)   // 15 Sechser von 15 Würfeln
    }
    func testWahrheitsChanceSinktMitDerAnzahl() {
        var s = Luegenwuerfel(spieler: 3); var g = SystemRandomNumberGenerator()
        s.neueRunde(mit: &g)
        var vorher = 2.0
        for n in 1...15 {
            var k = s; k.biete(Gebot(n, 5))
            let p = LuegenwuerfelComputer.wahrheitsChance(k, spieler: k.dran)
            XCTAssertLessThanOrEqual(p, vorher + 1e-9); vorher = p
        }
    }
}
