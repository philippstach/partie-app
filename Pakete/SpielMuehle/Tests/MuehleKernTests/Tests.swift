// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MuehleKern

final class MuehleTests: XCTestCase {
    func testGeometrie() {
        XCTAssertEqual(Muehle.muehlen.count, 16)
        XCTAssertEqual(Set(Muehle.nachbarn[1]), [0, 2, 9])
        XCTAssertEqual(Set(Muehle.nachbarn[9]), [8, 10, 1, 17])
        XCTAssertEqual(Set(Muehle.nachbarn[0]), [1, 7])
        for (i, n) in Muehle.nachbarn.enumerated() { for j in n { XCTAssertTrue(Muehle.nachbarn[j].contains(i)) } }
    }
    func testMuehleUndEntfernen() {
        var m = Muehle()
        // Weiß: 0,1,2  Schwarz: 8,9
        for z in [MuehleZug.setze(0), .setze(8), .setze(1), .setze(9)] { XCTAssertTrue(m.spiele(z)) }
        XCTAssertTrue(m.spiele(.setze(2)))
        XCTAssertTrue(m.mussEntfernen); XCTAssertEqual(m.dran, 1)
        XCTAssertFalse(m.spiele(.setze(3)))
        XCTAssertTrue(m.spiele(.entferne(8)))
        XCTAssertEqual(m.dran, 2); XCTAssertEqual(m.steine(2), 1)
    }
    func testGeschuetzteSteine() {
        var m = Muehle()
        for z in [MuehleZug.setze(0), .setze(8), .setze(1), .setze(9), .setze(2)] { m.spiele(z) }
        XCTAssertTrue(m.mussEntfernen)
        // Schwarz hat nur 8 und 9, keine Mühle: beide erlaubt
        XCTAssertEqual(Set(m.zuege()), [.entferne(8), .entferne(9)])
    }
    func testComputerSpieltLegal() {
        var m = Muehle(); var n = 0
        while m.sieger == nil && n < 300 {
            guard let z = MuehleComputer.wahl(m, tiefe: 2) else { break }
            XCTAssertTrue(m.spiele(z)); n += 1
        }
        XCTAssertTrue(n > 18)
    }
    func testPartieEndetMitSiegOderRemis() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<10 {
            var m = Muehle(); var n = 0
            while !m.vorbei && n < 3000 { m.spiele(m.zuege().randomElement(using: &g)!); n += 1 }
            XCTAssertTrue(m.vorbei, "Zufallspartie endet")
        }
    }
    func testComputerBesserAlsZufall() {
        var g = SystemRandomNumberGenerator(); var siege = 0, partien = 6
        for k in 0..<partien {
            var m = Muehle(); var n = 0; let ich = k % 2 + 1
            while !m.vorbei && n < 400 {
                if m.dran == ich { m.spiele(MuehleComputer.wahl(m, staerke: .mittel)!) } else { m.spiele(m.zuege().randomElement(using: &g)!) }
                n += 1
            }
            if m.sieger == ich { siege += 1 }
        }
        XCTAssertGreaterThanOrEqual(siege, 4)
    }
}

final class MuehleRegelnTests: XCTestCase {
    func testKurzStartetMitSechsSteinen() {
        let m = Muehle(regeln: .kurz); XCTAssertEqual(m.vorrat, [0, 6, 6]); XCTAssertEqual(m.gesamt(1), 6)
    }
    func testSechserMuehleSpieltBisZumEnde() {
        var m = Muehle(regeln: .kurz); var n = 0
        while !m.vorbei, n < 400, let z = m.zuege().randomElement() { m.spiele(z); n += 1 }
        XCTAssertTrue(m.vorbei || n == 400)
    }
    func testAlterSpielstandLaedt() throws {
        let json = #"{"brett":\#(Muehle().brett),"vorrat":[0,9,9],"dran":1,"mussEntfernen":false,"ruhigeZuege":0}"#
        XCTAssertEqual(try JSONDecoder().decode(Muehle.self, from: Data(json.utf8)).regeln, .klassisch)
    }
}

import SpieleKern
final class MuehleAbbruchTests: XCTestCase {
    /// „Beenden“ nach dem ersten Zug zählt als Niederlage des Menschen; ohne gemeldeten Zug zählt es nichts.
    @MainActor func testBeendenNachErstemZugIstEineNiederlage() {
        XCTAssertFalse(SpielZug.hatZug("muehle"))
        SpielZug.gemacht("muehle")
        XCTAssertTrue(SpielZug.hatZug("muehle"))
        let e = PartieMeldung.abbruch(spiel: "muehle", teilnehmer: [("Ich", false), ("Computer", true)])
        XCTAssertEqual(e?.teilnehmer.first { $0.name == "Ich" }?.platz, 2)
        XCTAssertEqual(e?.teilnehmer.first { $0.name == "Computer" }?.platz, 1)
        XCTAssertEqual(e?.istRemis, false)
    }
}

final class MuehleStandTests: XCTestCase {
    private func partie(zuege: Int, regeln: MuehleRegeln = .klassisch) -> (Muehle, [Muehle]) {
        var m = Muehle(regeln: regeln), verlauf: [Muehle] = []
        for _ in 0..<zuege { guard let z = m.zuege().first else { break }; verlauf.append(m); m.spiele(z) }
        return (m, verlauf)
    }
    func testStandBehaeltZugverlaufUndRegel() throws {
        let (m, verlauf) = partie(zuege: 7, regeln: .kurz)
        let stand = MuehleStand(spiel: m, verlauf: verlauf)
        let geladen = try JSONDecoder().decode(MuehleStand.self, from: JSONEncoder().encode(stand))
        XCTAssertEqual(geladen, stand); XCTAssertEqual(geladen.verlauf.count, 7)
        XCTAssertEqual(geladen.spiel.regeln, .kurz)
        XCTAssertTrue(geladen.istKonsistent); XCTAssertTrue(geladen.begonnen)
    }
    func testAlterStandNurMitStellungBleibtLadbar() throws {
        let (m, _) = partie(zuege: 5)
        let geladen = try JSONDecoder().decode(MuehleStand.self, from: JSONEncoder().encode(m))   // so wurde bis Build 9 gespeichert
        XCTAssertEqual(geladen.spiel, m); XCTAssertTrue(geladen.verlauf.isEmpty)
        XCTAssertTrue(geladen.istKonsistent)
        XCTAssertTrue(geladen.begonnen, "Steine auf dem Brett: Regelwechsel bleibt gesperrt, auch ohne Verlauf")
    }
    func testFrischePartieGiltNichtAlsBegonnen() {
        XCTAssertFalse(MuehleStand(spiel: Muehle(regeln: .streng)).begonnen)
    }
    func testVerlaufWirdBegrenzt() {
        let (m, _) = partie(zuege: 3)
        let stand = MuehleStand(spiel: m, verlauf: Array(repeating: Muehle(), count: 300))
        XCTAssertEqual(stand.verlauf.count, MuehleStand.verlaufGrenze)
    }
    func testUnstimmigeStaendeWerdenErkannt() throws {
        let (m, verlauf) = partie(zuege: 4)
        XCTAssertFalse(MuehleStand(spiel: m, verlauf: [Muehle(regeln: .kurz)]).istKonsistent, "Verlauf mit anderer Regel")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(MuehleStand(spiel: m, verlauf: verlauf))) as? [String: Any])
        var s = try XCTUnwrap(json["spiel"] as? [String: Any])
        func lade(_ spiel: [String: Any]) throws -> MuehleStand { var j = json; j["spiel"] = spiel; return try JSONDecoder().decode(MuehleStand.self, from: JSONSerialization.data(withJSONObject: j)) }
        XCTAssertTrue(try lade(s).istKonsistent)
        var a = s; a["dran"] = 3
        XCTAssertFalse(try lade(a).istKonsistent, "Spieler, den es nicht gibt")
        var b = s; b["brett"] = [1, 2]
        XCTAssertFalse(try lade(b).istKonsistent, "Brett zu klein")
        var c = s; c["vorrat"] = [0, 40, 9]
        XCTAssertFalse(try lade(c).istKonsistent, "mehr Steine als die Regel erlaubt")
        s["vorrat"] = [0]
        XCTAssertFalse(try lade(s).istKonsistent, "Vorrat unvollständig")
    }

    /// Blatt 22 (Schritt 2): Mühlen werden je Spieler gezählt; ein Stand ohne den neuen Schlüssel lädt mit nil und zählt nicht weiter.
    func testGeschlosseneMuehlenZaehlen() throws {
        var m = Muehle(regeln: .klassisch, beginner: 1)
        XCTAssertEqual(m.geschlosseneMuehlen, [0, 0, 0])
        // Weiß setzt 0, 1, 2 (obere Reihe des äußeren Rings), Schwarz setzt 8, 10 dazwischen
        for p in [0, 8, 1, 10] { XCTAssertTrue(m.spiele(.setze(p))) }
        XCTAssertTrue(m.spiele(.setze(2)))
        XCTAssertTrue(m.mussEntfernen)
        XCTAssertEqual(m.geschlosseneMuehlen, [0, 1, 0])
        // Alter Stand: JSON ohne den neuen Schlüssel
        let data = try JSONEncoder().encode(m)
        var obj = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertNotNil(obj["geschlosseneMuehlen"])
        obj.removeValue(forKey: "geschlosseneMuehlen")
        let alt = try JSONDecoder().decode(Muehle.self, from: JSONSerialization.data(withJSONObject: obj))
        XCTAssertNil(alt.geschlosseneMuehlen)
        XCTAssertTrue(alt.istKonsistent)
        var weiter = alt
        XCTAssertTrue(weiter.spiele(.entferne(8)))
        XCTAssertNil(weiter.geschlosseneMuehlen)
        // „Partie begonnen“ gilt auch für einen alten Stand ohne Zähler nicht fälschlich bei leerem Brett
        let leer = try JSONDecoder().decode(Muehle.self, from: JSONSerialization.data(withJSONObject: ["brett": [Int](repeating: 0, count: 24), "vorrat": [0, 9, 9], "dran": 1, "mussEntfernen": false]))
        XCTAssertFalse(MuehleStand(spiel: leer).begonnen)
    }
}
