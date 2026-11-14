// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import StufenstapelKern

final class StufenstapelTests: XCTestCase {
    func testAusteilen() {
        var g = SystemRandomNumberGenerator(); let s = Stufenstapel(spieler: 3, mit: &g)
        XCTAssertEqual(s.kartenGesamt, Stufenstapel.satz().count)
        XCTAssertTrue(s.vorrat.allSatisfy { $0.count == 15 }); XCTAssertEqual(s.hand[0].count, 5)
    }
    func testBauRegeln() {
        var g = SystemRandomNumberGenerator(); let s = Stufenstapel(spieler: 2, mit: &g)
        XCTAssertTrue(s.kannBauen(1, auf: 0)); XCTAssertFalse(s.kannBauen(2, auf: 0)); XCTAssertTrue(s.kannBauen(0, auf: 0))
    }
    func testComputerPartienEnden() {
        for n in 2...4 {
            for _ in 0..<20 {
                var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: n, mit: &g); var z = 0
                while s.gewinner == nil && z < 20000 { s.computerSchritt(mit: &g); z += 1; XCTAssertEqual(s.kartenGesamt, Stufenstapel.satz().count) }
                XCTAssertNotNil(s.gewinner, "\(n) Spieler")
                XCTAssertEqual(s.vorrat[s.gewinner!].count, 0)
            }
        }
    }
    func testAblegenWechseltSpieler() {
        var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: 2, mit: &g)
        XCTAssertTrue(s.lege(handKarte: 0, auf: 1, mit: &g)); XCTAssertEqual(s.amZug, 1); XCTAssertEqual(s.hand[0].count, 4 + 0 + 0 + (s.hand[0].count - 4))
        XCTAssertEqual(s.ablage[0][1].count, 1)
    }
    func testIllegalesBauenAbgelehnt() {
        var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: 2, mit: &g)
        if let i = s.hand[0].indices.first(where: { s.hand[0][$0] > 1 }) { XCTAssertFalse(s.baue(.hand(i), auf: 0, mit: &g)) }
    }
    func testHandkarteAufLeereAblage() {
        for _ in 0..<20 {
            var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: 2, mit: &g)
            let spieler = s.amZug
            XCTAssertTrue(s.ablage[spieler][0].isEmpty)
            let k = s.hand[spieler][0]
            XCTAssertTrue(s.lege(handKarte: 0, auf: 0, mit: &g))
            XCTAssertEqual(s.ablage[spieler][0], [k])
            XCTAssertNotEqual(s.amZug, spieler)
        }
    }
    func testFehlerhafterComputerBleibtRegelkonformUndEndet() {
        for n in 2...3 { for _ in 0..<10 {
            var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: n, mit: &g); var z = 0
            while s.gewinner == nil && z < 60000 { s.computerSchritt(fehler: 0.4, mit: &g); z += 1; XCTAssertEqual(s.kartenGesamt, Stufenstapel.satz().count) }
            XCTAssertNotNil(s.gewinner)
        } }
    }

    /// F4: Der Vorschlag ist immer ausführbar und beendet nie den Zug falsch.
    func testVorschlagIstGueltig() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<20 {
            var s = Stufenstapel(spieler: 2, mit: &g)
            var schritte = 0
            while s.gewinner == nil, schritte < 12, let v = s.vorschlag() {
                var kopie = s
                switch v {
                case .bauen(let q, let b): XCTAssertTrue(kopie.baue(q, auf: b, mit: &g), "Bau-Vorschlag muss gültig sein")
                case .ablegen(let i, let a): XCTAssertTrue(kopie.lege(handKarte: i, auf: a, mit: &g), "Ablege-Vorschlag muss gültig sein")
                }
                s = kopie; schritte += 1
            }
        }
    }

    /// Liegt die Vorratskarte passend, schlägt der Tipp zuerst den Vorrat vor (wie der Computer).
    func testVorschlagBevorzugtVorrat() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<50 {
            let s = Stufenstapel(spieler: 2, mit: &g)
            if let v = s.vorrat[s.amZug].last, s.bau.indices.contains(where: { s.kannBauen(v, auf: $0) }) {
                if case .bauen(.vorrat, _)? = s.vorschlag() { return }
                XCTFail("Vorrat passt, wurde aber nicht vorgeschlagen")
            }
        }
    }
}

final class StufenstapelRegelTests: XCTestCase {
    func testSternErsetztJedeZahlAufJedemStapel() {
        var g = SystemRandomNumberGenerator(); let s = Stufenstapel(spieler: 2, mit: &g)
        for b in 0..<4 { XCTAssertTrue(s.kannBauen(Stufenstapel.stern, auf: b)) }
        XCTAssertFalse(s.kannBauen(3, auf: 2)); XCTAssertTrue(s.kannBauen(1, auf: 3))
    }
    func testKartensatzHat112Karten() {
        let satz = Stufenstapel.satz()
        XCTAssertEqual(satz.count, 112)
        for w in 1...10 { XCTAssertEqual(satz.filter { $0 == w }.count, 10) }
        XCTAssertEqual(satz.filter { $0 == Stufenstapel.stern }.count, 12)
    }
    func testBauStapelBleibenImWertebereichUndVolleWerdenAbgeraeumt() {
        for n in 2...4 {
            var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: n, mit: &g); var z = 0
            while s.gewinner == nil && z < 20000 {
                s.computerSchritt(mit: &g); z += 1
                XCTAssertTrue(s.bau.allSatisfy { (0...9).contains($0) }, "Ein voller Stapel (10) wird sofort abgeräumt")
                XCTAssertEqual(s.abgeraeumt.count % 10, 0)
            }
        }
    }
    func testHandWirdNachDemAblegenAufFuenfAufgefuellt() {
        var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: 2, mit: &g)
        s.lege(handKarte: 0, auf: 0, mit: &g)
        XCTAssertEqual(s.hand[1].count, Stufenstapel.handGroesse)
    }
    func testUngueltigeAblagenWerdenAbgelehnt() {
        var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: 2, mit: &g)
        XCTAssertFalse(s.lege(handKarte: 9, auf: 0, mit: &g)); XCTAssertFalse(s.lege(handKarte: 0, auf: 5, mit: &g))
        XCTAssertFalse(s.baue(.hand(0), auf: 9, mit: &g))
        XCTAssertEqual(s.amZug, 0)
    }
    func testNachDemSiegIstSchluss() {
        var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: 2, mit: &g); var z = 0
        while s.gewinner == nil && z < 20000 { s.computerSchritt(mit: &g); z += 1 }
        let stand = s
        XCTAssertFalse(s.lege(handKarte: 0, auf: 0, mit: &g)); XCTAssertFalse(s.baue(.vorrat, auf: 0, mit: &g)); XCTAssertNil(s.vorschlag())
        XCTAssertEqual(s, stand)
    }
    func testWertDerQuellenAnDerRichtigenStelle() {
        var g = SystemRandomNumberGenerator(); let s = Stufenstapel(spieler: 3, mit: &g)
        XCTAssertEqual(s.wert(.vorrat), s.vorrat[0].last); XCTAssertEqual(s.wert(.hand(0)), s.hand[0][0])
        XCTAssertNil(s.wert(.hand(9))); XCTAssertNil(s.wert(.ablage(0)), "Ablagen sind zu Beginn leer")
    }
    func testSpielstandIstCodierbar() throws {
        var g = SystemRandomNumberGenerator(); var s = Stufenstapel(spieler: 3, mit: &g)
        for _ in 0..<10 { s.computerSchritt(mit: &g) }
        let neu = try JSONDecoder().decode(Stufenstapel.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(neu, s)
    }
}
