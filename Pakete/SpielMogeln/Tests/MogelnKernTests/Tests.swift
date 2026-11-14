// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MogelnKern

final class MogelnTests: XCTestCase {
    func testStart() { var g = SystemRandomNumberGenerator(); let m = Mogeln(spieler: 4, mit: &g); XCTAssertEqual(m.haende.map(\.count), [8, 8, 8, 8]) }
    func testLegenUndAnzweifeln() {
        var g = SystemRandomNumberGenerator(); var m = Mogeln(spieler: 3, mit: &g)
        XCTAssertFalse(m.lege([])); XCTAssertFalse(m.lege([0, 0]))
        XCTAssertTrue(m.lege([0])); XCTAssertEqual(m.phase, .entscheiden); XCTAssertEqual(m.dran, 1)
        let log = m.gelogen
        m.anzweifeln()
        XCTAssertEqual(m.aufdeckung!.gelogen, log); XCTAssertEqual(m.rang, 8); XCTAssertEqual(m.haufen.count, 0)
        XCTAssertEqual(m.haende.map(\.count).reduce(0, +), 32)
        XCTAssertEqual(m.aufdeckung!.verlierer, log ? 0 : 1)
    }
    func testSpielEnde() {
        var g = SystemRandomNumberGenerator(); var m = Mogeln(spieler: 3, mit: &g); var n = 0
        while m.gewinner == nil && n < 20000 {
            switch m.phase {
            case .legen: XCTAssertTrue(m.lege(MogelnComputer.lege(m)))
            case .entscheiden: if MogelnComputer.zweifelt(m, spieler: m.dran, mit: &g) { m.anzweifeln() } else { m.glauben() }
            }
            n += 1
            XCTAssertEqual(m.haende.map(\.count).reduce(0, +) + m.haufen.count, 32)
        }
        XCTAssertNotNil(m.gewinner)
    }

    func testLuegeIstImmerEineKarteUndDieEhrlichenWerdenGelegt() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<30 {
            var m = Mogeln(spieler: 3, mit: &g); var n = 0
            while m.gewinner == nil && n < 3000 {
                if m.phase == .legen {
                    let z = MogelnComputer.lege(m)
                    XCTAssertTrue((1...4).contains(z.count))
                    let ehrlich = m.haende[m.dran].filter { $0.wert == m.rang }.count
                    if ehrlich > 0 { XCTAssertEqual(z.count, min(4, ehrlich)) } else { XCTAssertEqual(z.count, 1) }
                    XCTAssertTrue(m.lege(z))
                } else if MogelnComputer.zweifelt(m, spieler: m.dran, mit: &g) { m.anzweifeln() } else { m.glauben() }
                n += 1
            }
        }
    }
}

final class MogelnFehlerjagdTests: XCTestCase {
    func testPartieEndetInJederStufe() {
        var g = SystemRandomNumberGenerator()
        for stufe in 1...3 {
            for spieler in 3...6 {
                var m = Mogeln(spieler: spieler, mit: &g); var n = 0
                while m.gewinner == nil, n < 3000 {
                    switch m.phase {
                    case .legen:
                        let z = MogelnComputer.lege(m)
                        XCTAssertFalse(z.isEmpty); XCTAssertTrue(m.lege(z))
                    case .entscheiden:
                        if MogelnComputer.zweifelt(m, spieler: m.dran, stufe: stufe, mit: &g) { m.anzweifeln() } else { m.glauben() }
                    }
                    n += 1
                }
                XCTAssertNotNil(m.gewinner, "Stufe \(stufe), \(spieler) Spieler")
            }
        }
    }
    func testKartenGehenNieVerloren() {
        var g = SystemRandomNumberGenerator()
        var m = Mogeln(spieler: 4, mit: &g); var n = 0
        while m.gewinner == nil, n < 1000 {
            switch m.phase {
            case .legen: m.lege(MogelnComputer.lege(m))
            case .entscheiden: if Bool.random() { m.anzweifeln() } else { m.glauben() }
            }
            XCTAssertEqual(m.haende.reduce(0) { $0 + $1.count } + m.haufen.count, 32)
            n += 1
        }
    }
}

final class MogelnTippTests: XCTestCase {
    func testWahrheitsChanceUnmoeglichWennZuvieleGleiche() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<200 {
            var m = Mogeln(spieler: 3, mit: &g)
            let z = MogelnComputer.lege(m); m.lege(z)
            guard m.phase == .entscheiden else { continue }
            let p = MogelnComputer.wahrheitsChance(m, spieler: m.dran)
            XCTAssertTrue((0...1).contains(p))
            let eigene = m.haende[m.dran].filter { $0.wert == m.rang }.count
            if eigene + m.letzteAnzahl > 4 { XCTAssertEqual(p, 0) } else { XCTAssertGreaterThan(p, 0) }
        }
    }
    func testMehrKartenSindUnwahrscheinlicher() {
        var g = SystemRandomNumberGenerator()
        var m = Mogeln(spieler: 3, mit: &g); m.lege([0]); let p1 = MogelnComputer.wahrheitsChance(m, spieler: m.dran)
        var m2 = Mogeln(spieler: 3, mit: &g); m2.lege([0, 1]); let p2 = MogelnComputer.wahrheitsChance(m2, spieler: m2.dran)
        // gleicher Rang 7, gleiche Zählung ohne eigene Treffer: Zwei Karten sind seltener wahr als eine
        if m.haende[m.dran].allSatisfy({ $0.wert != 7 }) && m2.haende[m2.dran].allSatisfy({ $0.wert != 7 }) { XCTAssertLessThan(p2, p1) }
    }
}

final class MogelnRegelTests: XCTestCase {
    private func hand(_ w: [Int]) -> [MoKarte] { w.enumerated().map { MoKarte($0.offset % 4, $0.element) } }

    func testEhrlichesLegenIstNichtGelogen() {
        var m = Mogeln(haende: [hand([7, 7, 9]), hand([8, 8])])
        XCTAssertTrue(m.lege([0, 1]))
        XCTAssertFalse(m.gelogen)
        XCTAssertEqual(m.letzteAnzahl, 2); XCTAssertEqual(m.dran, 1); XCTAssertEqual(m.phase, .entscheiden)
    }
    func testGeloegenWennNurEineKarteAbweicht() {
        var m = Mogeln(haende: [hand([7, 9, 9]), hand([8, 8])])
        m.lege([0, 1])
        XCTAssertTrue(m.gelogen)
    }
    func testLuegnerNimmtDenHaufenBeiAnzweifeln() {
        var m = Mogeln(haende: [hand([9, 10]), hand([8, 8])])
        m.lege([0])                                   // gefordert 7, gelegt 9
        m.anzweifeln()
        XCTAssertEqual(m.aufdeckung?.gelogen, true); XCTAssertEqual(m.aufdeckung?.verlierer, 0)
        XCTAssertEqual(m.haende[0].count, 2); XCTAssertTrue(m.haufen.isEmpty); XCTAssertEqual(m.dran, 0)
        XCTAssertEqual(m.rang, 8)
    }
    func testZweiflerNimmtDenHaufenWennEsStimmte() {
        var m = Mogeln(haende: [hand([7, 10]), hand([8, 8])])
        m.lege([0])
        m.anzweifeln()
        XCTAssertEqual(m.aufdeckung?.gelogen, false); XCTAssertEqual(m.aufdeckung?.verlierer, 1)
        XCTAssertEqual(m.haende[1].count, 3); XCTAssertEqual(m.dran, 1)
    }
    func testLetzteKartenEhrlichUndNichtUeberfuehrtGewinnt() {
        var m = Mogeln(haende: [hand([7]), hand([8, 8])])
        m.lege([0]); m.glauben()
        XCTAssertEqual(m.gewinner, 0)
    }
    func testLetzteKartenEhrlichAberAngezweifeltGewinnt() {
        var m = Mogeln(haende: [hand([7]), hand([8, 8])])
        m.lege([0]); m.anzweifeln()
        XCTAssertEqual(m.gewinner, 0, "Wer ehrlich ausspielt und zu Unrecht angezweifelt wird, gewinnt")
    }
    func testLetzteKartenGelogenWirdUeberfuehrt() {
        var m = Mogeln(haende: [hand([10]), hand([8, 8])])
        m.lege([0]); m.anzweifeln()
        XCTAssertNil(m.gewinner); XCTAssertEqual(m.haende[0].count, 1)
    }
    func testRangLaeuftVonAssWiederZurSieben() {
        var m = Mogeln(haende: [hand([14, 14, 14, 14]), hand([9, 9, 9, 9])], rang: 14)
        m.lege([0]); m.glauben()
        XCTAssertEqual(m.rang, 7)
    }
    func testLegenIstNurMitEinsBisVierKartenUndGueltigenIndizesMoeglich() {
        var m = Mogeln(haende: [hand([7, 8, 9, 10, 11]), hand([8])])
        XCTAssertFalse(m.lege([0, 1, 2, 3, 4]))
        XCTAssertFalse(m.lege([9]))
        XCTAssertFalse(m.lege([-1]))
        XCTAssertTrue(m.lege([0, 1, 2, 3]))
    }
    func testNachDemGewinnWirdNichtsMehrGelegt() {
        var m = Mogeln(haende: [hand([7]), hand([8, 8])])
        m.lege([0]); m.glauben()
        XCTAssertFalse(m.lege([0]))
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator()
        var m = Mogeln(spieler: 3, mit: &g); m.lege([0, 1])
        let neu = try JSONDecoder().decode(Mogeln.self, from: JSONEncoder().encode(m))
        XCTAssertEqual(neu.haende, m.haende); XCTAssertEqual(neu.haufen, m.haufen); XCTAssertEqual(neu.rang, m.rang)
        XCTAssertEqual(neu.dran, m.dran); XCTAssertEqual(neu.phase, m.phase)
    }
    func testKartenKurzUndName() {
        XCTAssertEqual(MoKarte(2, 11).kurz, "B"); XCTAssertEqual(MoKarte(0, 14).kurz, "A"); XCTAssertEqual(MoKarte(1, 10).kurz, "10")
        XCTAssertEqual(MoKarte.alle.count, 32); XCTAssertEqual(Set(MoKarte.alle).count, 32)
    }
}

final class MogelnKonsistenzTests: XCTestCase {
    func testComputerpartieBleibtStimmig() {
        var g = SystemRandomNumberGenerator()
        for spieler in 3...6 {
            var m = Mogeln(spieler: spieler, mit: &g)
            XCTAssertTrue(m.istKonsistent)
            var schritte = 0
            while m.gewinner == nil, schritte < 600 {
                switch m.phase {
                case .legen: m.lege(MogelnComputer.lege(m))
                case .entscheiden: if MogelnComputer.zweifelt(m, spieler: m.dran, stufe: 1 + schritte % 3, mit: &g) { m.anzweifeln() } else { m.glauben() }
                }
                schritte += 1
                XCTAssertTrue(m.istKonsistent, "nach Schritt \(schritte) mit \(spieler) Spielern")
            }
        }
    }
    func testGeladenerStandInDerEntscheidungBleibtStimmig() throws {
        var g = SystemRandomNumberGenerator()
        var m = Mogeln(spieler: 3, mit: &g)
        m.lege([0, 1])
        let geladen = try JSONDecoder().decode(Mogeln.self, from: JSONEncoder().encode(m))
        XCTAssertTrue(geladen.istKonsistent); XCTAssertEqual(geladen.letzter, 0); XCTAssertEqual(geladen.phase, .entscheiden)
    }
    func testKaputteStaendeWerdenErkannt() throws {
        var g = SystemRandomNumberGenerator()
        var m = Mogeln(spieler: 3, mit: &g)
        m.lege([0])
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(m)) as? [String: Any])
        func lade(_ j: [String: Any]) throws -> Mogeln { try JSONDecoder().decode(Mogeln.self, from: JSONSerialization.data(withJSONObject: j)) }
        var a = json; a.removeValue(forKey: "letzter")
        XCTAssertFalse(try lade(a).istKonsistent, "Entscheidung ohne Vorgänger (früher Absturz durch erzwungenes Entpacken)")
        var b = json; b["letzteAnzahl"] = 0
        XCTAssertFalse(try lade(b).istKonsistent, "Entscheidung ohne gelegte Karten")
        var c = json; c["dran"] = 9
        XCTAssertFalse(try lade(c).istKonsistent, "Zeiger außerhalb")
        var d = json; d["haufen"] = [Any]()
        XCTAssertFalse(try lade(d).istKonsistent, "Karte fehlt")
        var e = json; e["rang"] = 3
        XCTAssertFalse(try lade(e).istKonsistent, "Rang außerhalb")
    }
    func testComputerLegtBeiLeererHandNichtsStattAbzustuerzen() {
        let m = Mogeln(haende: [[], [MoKarte(0, 7)]])
        XCTAssertEqual(MogelnComputer.lege(m), [])
    }
}
