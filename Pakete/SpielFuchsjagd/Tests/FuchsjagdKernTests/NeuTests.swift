// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import FuchsjagdKern

final class FuchsjagdNeuTests: XCTestCase {
    func testAufstellungen() {
        for v in FuchsVariante.allCases {
            let s = Fuchsjagd(regeln: FuchsRegeln(variante: v))
            XCTAssertEqual(s.gaense.count, v.gaenseZahl); XCTAssertEqual(s.fuechse.count, v.fuchsZahl)
            XCTAssertTrue(s.gaense.allSatisfy(Fuchsjagd.gueltig)); XCTAssertTrue(s.fuechse.allSatisfy(Fuchsjagd.gueltig))
            XCTAssertTrue(s.gaense.isDisjoint(with: Set(s.fuechse))); XCTAssertEqual(s.startGaense, v.gaenseZahl)
            XCTAssertNil(s.ausgang); XCTAssertFalse(s.zuegeDes(.gaense).isEmpty)
        }
    }
    func testSiebzehnFuchsZiehtSchraegUndSpringtSchraeg() {
        var s = Fuchsjagd(regeln: FuchsRegeln(variante: .siebzehn))
        let g = s.zuegeDes(.gaense).first!; s.ziehe(g)
        XCTAssertTrue(s.zuegeDes(.fuchs).contains { abs($0.nach.x - $0.von.x) == 1 && abs($0.nach.y - $0.von.y) == 1 })
        let k = Fuchsjagd(regeln: FuchsRegeln(variante: .dreizehn))
        var k2 = k; k2.ziehe(k2.zuegeDes(.gaense).first!)
        XCTAssertFalse(k2.zuegeDes(.fuchs).contains { $0.nach.x != $0.von.x && $0.nach.y != $0.von.y })
    }
    func testZweiFuechseZiehenEinzeln() {
        var s = Fuchsjagd(regeln: FuchsRegeln(variante: .zweiFuechse))
        s.ziehe(s.zuegeDes(.gaense).first!)
        let z = s.zuegeDes(.fuchs)
        XCTAssertEqual(Set(z.map(\.von)), Set(s.fuechse))
        let vorher = Set(s.fuechse); s.ziehe(z[0])
        XCTAssertEqual(s.fuechse.count, 2); XCTAssertEqual(Set(s.fuechse).symmetricDifference(vorher).count, 2)
    }
    func testAlleVariantenSpielenBisEnde() {
        var g = SystemRandomNumberGenerator()
        for v in FuchsVariante.allCases {
            var s = Fuchsjagd(regeln: FuchsRegeln(variante: v)); var n = 0
            while s.ausgang == nil, n < 500 { s.ziehe(s.computerZug(tiefe: n % 2 == 0 ? 1 : 0, mit: &g)!); n += 1 }
            XCTAssertNotNil(s.ausgang, "\(v)"); XCTAssertEqual(s.historie.count, s.zuege)
        }
    }
    func testRemisBeiZuglimit() {
        var g = SystemRandomNumberGenerator()
        var s = Fuchsjagd(regeln: FuchsRegeln(remisBeiLimit: true)); var n = 0
        // Computer 0 wählt zufällig; bis zum Ende spielen und prüfen, dass nach dem Limit ein Remis statt Fuchssieg gilt
        while s.ausgang == nil, n < 600 { s.ziehe(s.computerZug(tiefe: 0, mit: &g)!); n += 1 }
        if s.zuege >= Fuchsjagd.maxZuege, s.gaense.count >= 4, !s.zuegeDes(s.amZug).isEmpty { XCTAssertEqual(s.ausgang, .remis) }
        XCTAssertNotNil(s.ausgang)
    }
    func testRemisUndKeinZugMehr() throws {
        struct R: Encodable { var fuchs: Pos; var gaense: [Pos]; var amZug: Fuchsjagd.Seite; var zuege: Int; var geschlagen: Int; var regeln: FuchsRegeln }
        let d = try JSONEncoder().encode(R(fuchs: Pos(3, 3), gaense: [Pos(0, 4), Pos(1, 4), Pos(2, 4), Pos(4, 4), Pos(5, 4)], amZug: .gaense, zuege: 160, geschlagen: 0, regeln: FuchsRegeln(remisBeiLimit: true)))
        var s = try JSONDecoder().decode(Fuchsjagd.self, from: d)
        XCTAssertEqual(s.ausgang, .remis); XCTAssertNil(s.sieger)
        XCTAssertFalse(s.ziehe(s.zuegeDes(.gaense)[0]))
        var fuchsSieg = s; _ = fuchsSieg
        let d2 = try JSONEncoder().encode(R(fuchs: Pos(3, 3), gaense: [Pos(0, 4), Pos(1, 4), Pos(2, 4), Pos(4, 4), Pos(5, 4)], amZug: .gaense, zuege: 160, geschlagen: 0, regeln: .standard))
        fuchsSieg = try JSONDecoder().decode(Fuchsjagd.self, from: d2)
        XCTAssertEqual(fuchsSieg.ausgang, .sieg(.fuchs))
    }
    func testPunkteSiegerNieHinterVerlierer() throws {
        struct R: Encodable { var fuchs: Pos; var gaense: [Pos]; var amZug: Fuchsjagd.Seite; var zuege: Int; var geschlagen: Int }
        // Fuchs blockiert, Gänse siegen mit 12 Gänsen und 1 gefressen
        let gaense = [Pos(2, 0), Pos(4, 0), Pos(3, 1), Pos(3, 2), Pos(1, 0)] + (0..<7).map { Pos($0, 4) }
        let s = try JSONDecoder().decode(Fuchsjagd.self, from: JSONEncoder().encode(R(fuchs: Pos(3, 0), gaense: gaense, amZug: .fuchs, zuege: 20, geschlagen: 1)))
        XCTAssertEqual(s.ausgang, .sieg(.gaense))
        XCTAssertGreaterThan(s.punkte(.gaense), s.punkte(.fuchs))
        XCTAssertEqual(s.punkte(.fuchs), 1)
    }
    func testNotation() {
        XCTAssertEqual(Fuchsjagd.notation(Pos(0, 6)), "a1"); XCTAssertEqual(Fuchsjagd.notation(Pos(3, 3)), "d4")
        XCTAssertEqual(Fuchsjagd.notation(FuchsZug(von: Pos(3, 3), nach: Pos(3, 5), schlag: Pos(3, 4))), "d4×d2")
        XCTAssertEqual(Fuchsjagd.notation(FuchsZug(von: Pos(3, 4), nach: Pos(3, 3), schlag: nil)), "d3–d4")
    }
    func testSpielstandMitHistorieRoundTrip() throws {
        var s = Fuchsjagd(regeln: FuchsRegeln(variante: .zweiFuechse, remisBeiLimit: true))
        s.ziehe(s.zuegeDes(.gaense)[0]); s.ziehe(s.zuegeDes(.fuchs)[0])
        let t = try JSONDecoder().decode(Fuchsjagd.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(s, t); XCTAssertEqual(t.historie.count, 2)
    }
    func testMatchSeitentauschUndWertung() {
        var m = FuchsMatch(seiteErster: .gaense)
        var p1 = Fuchsjagd(); var g = SystemRandomNumberGenerator()
        while p1.ausgang == nil { p1.ziehe(p1.computerZug(tiefe: 0, mit: &g)!) }
        XCTAssertTrue(m.buche(p1)); XCTAssertEqual(m.seiteErster, .fuchs); XCTAssertEqual(m.partie, 2); XCTAssertFalse(m.vorbei)
        XCTAssertEqual(m.summe[0], p1.punkte(.gaense)); XCTAssertEqual(m.summe[1], p1.punkte(.fuchs))
        XCTAssertFalse(m.buche(p1)); XCTAssertTrue(m.vorbei)
        XCTAssertEqual(m.summe[0], m.summe[1])   // beide spielten je einmal jede Seite derselben Partie
    }
}
