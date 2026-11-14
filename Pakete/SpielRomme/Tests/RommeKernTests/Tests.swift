// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import RommeKern

/// Deterministischer Zufallsgenerator (SplitMix64) für reproduzierbare Tests.
struct FesterZufall: RandomNumberGenerator {
    var zustand: UInt64
    init(seed: UInt64) { zustand = seed }
    mutating func next() -> UInt64 {
        zustand &+= 0x9E3779B97F4A7C15
        var z = zustand
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

final class RommeTests: XCTestCase {
    func testSatzUndFolge() {
        XCTAssertTrue(RommeRegeln.istSatz([RKarte(0, 7), RKarte(1, 7), RKarte(2, 7)]))
        XCTAssertFalse(RommeRegeln.istSatz([RKarte(0, 7), RKarte(0, 7, 1), RKarte(2, 7)]))
        XCTAssertTrue(RommeRegeln.istSatz([RKarte(0, 7), RKarte(1, 7), RKarte(0, 0)]))
        XCTAssertTrue(RommeRegeln.istFolge([RKarte(2, 4), RKarte(2, 5), RKarte(2, 6)]))
        XCTAssertTrue(RommeRegeln.istFolge([RKarte(2, 4), RKarte(2, 6), RKarte(0, 0)]))
        XCTAssertTrue(RommeRegeln.istFolge([RKarte(1, 12), RKarte(1, 13), RKarte(1, 1)]))      // D K A
        XCTAssertTrue(RommeRegeln.istFolge([RKarte(1, 1), RKarte(1, 2), RKarte(1, 3)]))
        XCTAssertFalse(RommeRegeln.istFolge([RKarte(1, 13), RKarte(1, 1), RKarte(1, 2)]))       // keine Ecke
        XCTAssertFalse(RommeRegeln.istFolge([RKarte(1, 4), RKarte(2, 5), RKarte(1, 6)]))
    }
    func testZerlegen() {
        let k = [RKarte(0, 3), RKarte(0, 4), RKarte(0, 5), RKarte(1, 9), RKarte(2, 9), RKarte(3, 9)]
        XCTAssertEqual(RommeRegeln.zerlege(k)?.count, 2)
        XCTAssertNil(RommeRegeln.zerlege([RKarte(0, 3), RKarte(1, 9), RKarte(2, 11)]))
    }
    func testSpielZuEnde() {
        var g = SystemRandomNumberGenerator(); var r = Romme(spieler: 2, mit: &g); var n = 0
        while r.gewinner == nil && n < 400 { RommeComputer.zug(&r, mit: &g); n += 1 }
        XCTAssertNotNil(r.gewinner)
    }

    /// F4: Der Vorschlag ist immer ein gültiger Zug und passt zur Phase (ziehen / auslegen / anlegen / abwerfen).
    func testVorschlagIstGueltig() {
        var g = SystemRandomNumberGenerator()
        for seed in 0..<20 {
            var r = Romme(spieler: 2, mit: &g)
            _ = seed
            // Vor dem Ziehen: nur Ziehen vorschlagen
            switch RommeComputer.vorschlag(r) {
            case .ablageNehmen?, .vomStapelZiehen?: break
            default: XCTFail("vor dem Ziehen nur Ziehen")
            }
            r.ziehe(vomStapel: true, mit: &g)
            guard let v = RommeComputer.vorschlag(r) else { return XCTFail("nach dem Ziehen gibt es immer einen Vorschlag") }
            var kopie = r
            switch v {
            case .ablageNehmen, .vomStapelZiehen: XCTFail("nach dem Ziehen nicht nochmal ziehen")
            case .auslegen(let idx): XCTAssertTrue(kopie.auslegen(idx), "Auslege-Vorschlag muss gültig sein")
            case .anlegen(let i, let m): XCTAssertTrue(kopie.anlegen(i, an: m))
            case .jokerTauschen(let i, let m): XCTAssertTrue(kopie.jokerTauschen(i, an: m))   // 1.0 (S3 Jokertausch)
            case .abwerfen(let i): XCTAssertTrue(kopie.abwerfen(i), "Abwurf-Index muss in der Hand liegen")
            }
        }
    }

    /// Mit drei Siebenen und einer Folge ab 40 Punkten schlägt der Tipp das Auslegen vor.
    func testVorschlagAuslegenBeiVierzig() {
        var g = SystemRandomNumberGenerator()
        var r = Romme(spieler: 2, mit: &g)
        r.ziehe(vomStapel: true, mit: &g)
        let h = r.haende[r.dran]
        // Nur prüfen, wenn der Zufall eine ≥40-Auslage geliefert hat; sonst muss es Abwerfen/Anlegen sein
        if case .auslegen(let idx)? = RommeComputer.vorschlag(r) {
            let teile = RommeRegeln.zerlege(idx.map { h[$0] })
            XCTAssertNotNil(teile)
            XCTAssertGreaterThanOrEqual(teile!.reduce(0) { $0 + RommeRegeln.punkte($1) }, Romme.mindestens)
        }
    }

    /// Mittlere Zuglänge einer Partie, wenn beide Spieler Stufe `stufe` spielen (stärkere Computer bringen schneller aus).
    /// Mit festen Seeds, damit der Test nicht vom Zufall abhängt (vorher gelegentlich rot).
    private func mittlereZuege(_ stufe: Int, partien: Int) -> Double {
        var summe = 0
        for i in 0..<partien {
            var g = FesterZufall(seed: UInt64(1000 + i)); var r = Romme(spieler: 2, mit: &g); var n = 0
            while r.gewinner == nil && n < 600 { RommeComputer.zug(&r, stufe: stufe, mit: &g); n += 1 }
            XCTAssertNotNil(r.gewinner, "Stufe \(stufe) endet")
            summe += n
        }
        return Double(summe) / Double(partien)
    }
    func testStarkeStufenBringenSchnellerAus() {
        let schwer = mittlereZuege(3, partien: 20), mittel = mittlereZuege(2, partien: 20), leicht = mittlereZuege(1, partien: 20)
        XCTAssertLessThan(schwer, leicht * 0.85, "schwer \(schwer), leicht \(leicht)")
        XCTAssertLessThan(mittel, leicht, "mittel \(mittel), leicht \(leicht)")
    }

    /// F4: Der Tipp folgt dem Computer „schwer“ (Stufe 3): wer nach dem Tipp zieht, hat dieselbe Ablagekarte genommen oder liegen lassen.
    func testVorschlagEntsprichtStufeSchwer() {
        for _ in 0..<30 {
            var g = SystemRandomNumberGenerator()
            let r = Romme(spieler: 2, mit: &g)
            var k = r; RommeComputer.zug(&k, stufe: 3, mit: &g)
            let computerNahmAblage = k.stapel.count == r.stapel.count   // vom Stapel gezogen → ein Stapelblatt weniger
            XCTAssertEqual(RommeComputer.vorschlag(r) == .ablageNehmen, computerNahmAblage)
        }
    }
}

final class RommeAblaufTests: XCTestCase {
    private func gesamt(_ r: Romme) -> Int { r.haende.reduce(0) { $0 + $1.count } + r.stapel.count + r.ablage.count + r.tisch.reduce(0) { $0 + $1.count } }
    func testKartenGehenNieVerloren() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<4 {
            var r = Romme(spieler: 3, mit: &g); let start = gesamt(r); var n = 0
            while r.gewinner == nil, n < 600 { RommeComputer.zug(&r, stufe: 2, mit: &g); n += 1; XCTAssertEqual(gesamt(r), start) }
        }
    }
    func testOhneZiehenKeinAuslegenNochAbwerfen() {
        var g = SystemRandomNumberGenerator()
        var r = Romme(spieler: 2, mit: &g)
        XCTAssertFalse(r.auslegen([0, 1, 2])); XCTAssertFalse(r.abwerfen(0)); XCTAssertFalse(r.anlegen(0, an: 0))
        XCTAssertEqual(r.dran, 0)
    }
    func testNurEinmalZiehenProZug() {
        var g = SystemRandomNumberGenerator()
        var r = Romme(spieler: 2, mit: &g)
        r.ziehe(vomStapel: true, mit: &g); let n = r.haende[0].count
        r.ziehe(vomStapel: true, mit: &g); r.ziehe(vomStapel: false, mit: &g)
        XCTAssertEqual(r.haende[0].count, n)
    }
    func testAbwerfenBeendetZug() {
        var g = SystemRandomNumberGenerator()
        var r = Romme(spieler: 2, mit: &g)
        r.ziehe(vomStapel: true, mit: &g); XCTAssertTrue(r.abwerfen(0))
        XCTAssertEqual(r.dran, 1); XCTAssertFalse(r.gezogen)
    }
    func testStrafpunkteJokerZwanzig() {
        XCTAssertEqual(RKarte(0, 0).augen, 0)
        XCTAssertEqual(RKarte(1, 1).augen, 11); XCTAssertEqual(RKarte(1, 13).augen, 10); XCTAssertEqual(RKarte(1, 7).augen, 7)
    }
    func testGrenzfaelleMeld() {
        XCTAssertFalse(RommeRegeln.istSatz([RKarte(0, 7), RKarte(1, 7)]))                                   // zu kurz
        XCTAssertFalse(RommeRegeln.istSatz([RKarte(0, 7), RKarte(1, 7), RKarte(2, 7), RKarte(3, 7), RKarte(0, 7, 1)]))   // zu lang
        XCTAssertFalse(RommeRegeln.istFolge([RKarte(0, 4), RKarte(0, 5)]))
        XCTAssertFalse(RommeRegeln.istFolge([RKarte(0, 4), RKarte(0, 4, 1), RKarte(0, 5)]))               // doppelter Wert
        XCTAssertFalse(RommeRegeln.istFolge([RKarte(0, 0), RKarte(0, 0, 1), RKarte(0, 0, 2)]))              // nur Joker: keine Farbe, keine Folge
        XCTAssertEqual(RommeRegeln.zerlege([])?.count, 0)
    }
}

final class RommeRegelTests: XCTestCase {
    private func k(_ f: Int, _ w: Int, _ n: Int = 0) -> RKarte { RKarte(f, w, n) }
    private let joker = RKarte(0, 0, 0)

    func testDeckHat110Karten() {
        let d = RKarte.deck()
        XCTAssertEqual(d.count, 110); XCTAssertEqual(d.filter(\.joker).count, 6); XCTAssertEqual(Set(d).count, 110)
    }
    func testSatzBrauchtGleichenWertUndVerschiedeneFarben() {
        XCTAssertTrue(RommeRegeln.istSatz([k(0, 7), k(1, 7), k(2, 7)]))
        XCTAssertTrue(RommeRegeln.istSatz([k(0, 7), k(1, 7), k(2, 7), k(3, 7)]))
        XCTAssertFalse(RommeRegeln.istSatz([k(0, 7), k(0, 7, 1), k(2, 7)]), "Gleiche Farbe zweimal")
        XCTAssertFalse(RommeRegeln.istSatz([k(0, 7), k(1, 8), k(2, 7)]))
        XCTAssertFalse(RommeRegeln.istSatz([k(0, 7), k(1, 7)]))
        XCTAssertFalse(RommeRegeln.istSatz([k(0, 7), k(1, 7), k(2, 7), k(3, 7), joker]))
    }
    func testJokerErsetztImSatz() {
        XCTAssertTrue(RommeRegeln.istSatz([k(0, 7), k(1, 7), joker]))
        XCTAssertTrue(RommeRegeln.istSatz([k(0, 7), joker, RKarte(0, 0, 1)]))
        XCTAssertFalse(RommeRegeln.istSatz([joker, RKarte(0, 0, 1), RKarte(0, 0, 2)]), "Nur Joker ist kein Satz")
    }
    func testFolgeGleicheFarbeAufsteigend() {
        XCTAssertTrue(RommeRegeln.istFolge([k(2, 4), k(2, 5), k(2, 6)]))
        XCTAssertTrue(RommeRegeln.istFolge([k(2, 6), k(2, 4), k(2, 5)].sorted { $0.wert < $1.wert }))
        XCTAssertFalse(RommeRegeln.istFolge([k(2, 4), k(2, 5), k(1, 6)]))
        XCTAssertFalse(RommeRegeln.istFolge([k(2, 4), k(2, 5)]))
        XCTAssertFalse(RommeRegeln.istFolge([k(2, 4), k(2, 4, 1), k(2, 5)]), "Doppelte Werte")
    }
    func testAssUntenUndObenAberNichtUmDieEcke() {
        XCTAssertTrue(RommeRegeln.istFolge([k(0, 1), k(0, 2), k(0, 3)]))
        XCTAssertTrue(RommeRegeln.istFolge([k(0, 12), k(0, 13), k(0, 1)]))
        XCTAssertFalse(RommeRegeln.istFolge([k(0, 13), k(0, 1), k(0, 2)]))
    }
    func testJokerFuelltLueckenInDerFolge() {
        XCTAssertTrue(RommeRegeln.istFolge([k(1, 5), joker, k(1, 7)]))
        XCTAssertFalse(RommeRegeln.istFolge([k(1, 5), joker, k(1, 9)]))
    }
    /// RT-044: Ass unten zählt 1, oben 11; Joker zählt wie die ersetzte Karte.
    func testWertungAssUntenUndJokerErsetzt() {
        XCTAssertEqual(RommeRegeln.punkte([k(0, 1), k(0, 2), k(0, 3)]), 1 + 2 + 3)
        XCTAssertEqual(RommeRegeln.punkte([k(0, 12), k(0, 13), k(0, 1)]), 10 + 10 + 11)
        XCTAssertEqual(RommeRegeln.punkte([k(1, 5), joker, k(1, 7)]), 5 + 6 + 7)           // Joker ersetzt die 6
        XCTAssertEqual(RommeRegeln.punkte([k(0, 7), k(1, 7), joker]), 21)                    // Joker im Satz = 7
        XCTAssertEqual(RommeRegeln.punkte([k(2, 1), k(3, 1), joker]), 33)                    // Joker im Ass-Satz = 11
        XCTAssertEqual(RommeRegeln.punkte([k(0, 9), k(0, 10), joker]), 9 + 10 + 10)          // Joker oben als Bube
        XCTAssertEqual(RommeRegeln.auslageAugen([k(0, 1), k(0, 2), k(0, 3), k(1, 10), k(2, 10), k(3, 10)]), 36)
    }
    func testPunkteUndStrafpunkte() {
        XCTAssertEqual(k(0, 1).augen, 11); XCTAssertEqual(k(0, 13).augen, 10); XCTAssertEqual(k(0, 5).augen, 5); XCTAssertEqual(joker.augen, 0)
        XCTAssertEqual(RommeRegeln.punkte([k(0, 10), k(1, 10), k(2, 10)]), 30)
        let r = Romme(haende: [[k(0, 1), joker, k(1, 9)], [k(2, 2)]])
        XCTAssertEqual(r.strafpunkte(0), 11 + 20 + 9)
    }
    func testZerlegeFindetMehrereAuslagen() {
        let karten = [k(0, 5), k(1, 5), k(2, 5), k(3, 8), k(3, 9), k(3, 10)]
        let z = RommeRegeln.zerlege(karten)
        XCTAssertEqual(z?.count, 2)
        XCTAssertNil(RommeRegeln.zerlege([k(0, 5), k(1, 5), k(2, 6)]))
        XCTAssertEqual(RommeRegeln.zerlege([])?.count, 0)
    }
    func testErsteAuslageBrauchtVierzigPunkte() {
        var r = Romme(haende: [[k(0, 2), k(1, 2), k(2, 2), k(3, 9), k(3, 10), k(3, 11)], [k(0, 13)]], gezogen: true)
        XCTAssertFalse(r.auslegen([0, 1, 2]), "6 Punkte reichen nicht")
        XCTAssertFalse(r.auslegen([0, 1, 2, 3, 4, 5]), "6 + 29 = 35 Punkte reichen nicht")
        var t = Romme(haende: [[k(0, 13), k(1, 13), k(2, 13), k(3, 9), k(3, 10), k(3, 11), k(0, 1)], [k(0, 13)]], gezogen: true)
        XCTAssertTrue(t.auslegen([0, 1, 2, 3, 4, 5]), "30 + 29 = 59 Punkte")
    }
    func testAuslegenOhneZiehenGehtNicht() {
        var r = Romme(haende: [[k(0, 10), k(1, 10), k(2, 10), k(0, 13)], [k(0, 1)]], gezogen: false)
        XCTAssertFalse(r.auslegen([0, 1, 2]))
    }
    func testAuslegenMitDreissigPlusAnlegenAbwerfenUndSieg() {
        var r = Romme(haende: [[k(0, 10), k(1, 10), k(2, 10), k(3, 10), k(0, 13), k(1, 2)], [k(0, 1)]], tisch: [], gezogen: true)
        XCTAssertFalse(r.auslegen([0, 1, 2]), "30 Punkte < 40")
        XCTAssertTrue(r.auslegen([0, 1, 2, 3])); XCTAssertEqual(r.tisch.count, 1); XCTAssertTrue(r.hatAusgelegt[0])
        XCTAssertTrue(r.abwerfen(0)); XCTAssertEqual(r.dran, 1); XCTAssertFalse(r.gezogen)
        XCTAssertEqual(r.ablage.last, k(0, 13))
        XCTAssertNil(r.gewinner)
    }
    func testAnlegenNurNachDerErstenAuslage() {
        var r = Romme(haende: [[k(3, 7)], [k(0, 1)]], tisch: [[k(0, 7), k(1, 7), k(2, 7)]], hatAusgelegt: [false, false], gezogen: true)
        XCTAssertFalse(r.anlegen(0, an: 0))
        var s = Romme(haende: [[k(3, 7), k(0, 2)], [k(0, 1)]], tisch: [[k(0, 7), k(1, 7), k(2, 7)]], hatAusgelegt: [true, false], gezogen: true)
        XCTAssertTrue(s.anlegen(0, an: 0)); XCTAssertEqual(s.tisch[0].count, 4); XCTAssertEqual(s.haende[0].count, 1)
        XCTAssertFalse(s.anlegen(0, an: 0), "Zwei weitere Zweier passen nicht in den Satz")
    }
    func testWerDieLetzteKarteLosWirdGewinnt() {
        var r = Romme(haende: [[k(0, 7)], [k(0, 1)]], gezogen: true)
        XCTAssertTrue(r.abwerfen(0)); XCTAssertEqual(r.gewinner, 0)
        XCTAssertFalse(r.abwerfen(0))
    }
    func testZiehenEinmalProZugUndStapelWirdAusDerAblageNachgemischt() {
        var g = SystemRandomNumberGenerator()
        var r = Romme(haende: [[k(0, 7)], [k(0, 1)]], stapel: [], ablage: [k(1, 2), k(2, 3), k(3, 4)])
        r.ziehe(vomStapel: true, mit: &g)
        XCTAssertEqual(r.haende[0].count, 2); XCTAssertEqual(r.ablage.count, 1); XCTAssertEqual(r.stapel.count, 1)
        r.ziehe(vomStapel: true, mit: &g); XCTAssertEqual(r.haende[0].count, 2, "Nur einmal pro Zug")
    }
}

final class RommeVorschlagFehlerTests: XCTestCase {
    /// Früher konnte der Tipp eine erste Auslage vorschlagen, die nach dem Zurückhalten einer Abwurfkarte unter 40 Punkte fiel.
    func testVorschlagFuerErsteAuslageErreichtNachDemZurueckhaltenNochVierzigPunkte() {
        let k: (Int, Int) -> RKarte = { RKarte($0, $1, 0) }
        // Ganze Hand ist auslegbar (4 Zehner = 40 + 3 Fünfen = 15 = 55); nach Weglassen der letzten Karte (Fünf) bleiben 50.
        let hand = [k(0, 10), k(1, 10), k(2, 10), k(3, 10), k(0, 5), k(1, 5), k(2, 5)]
        let r = Romme(haende: [hand, [k(0, 1)]], gezogen: true)
        if case .auslegen(let idx)? = RommeComputer.vorschlag(r) {
            var kopie = r
            XCTAssertTrue(kopie.auslegen(idx))
        }
        // Grenzfall: alles zusammen genau 40, aber ohne eine Karte weniger
        let knapp = [k(0, 10), k(1, 10), k(2, 10), k(3, 5), k(0, 5), k(1, 5), k(2, 5)]   // 30 + 20 = 50, ohne letzte Karte 45
        let r2 = Romme(haende: [knapp, [k(0, 1)]], gezogen: true)
        if case .auslegen(let idx)? = RommeComputer.vorschlag(r2) {
            var kopie = r2
            XCTAssertTrue(kopie.auslegen(idx))
        }
    }
    func testVieleZufallshaendeBringenNurGueltigeVorschlaege() {
        var g = SystemRandomNumberGenerator()
        for _ in 0..<15 {
            var r = Romme(spieler: 2, mit: &g)
            r.ziehe(vomStapel: true, mit: &g)
            if case .auslegen(let idx)? = RommeComputer.vorschlag(r) { var kopie = r; XCTAssertTrue(kopie.auslegen(idx), "Auslege-Vorschlag muss gültig sein") }
        }
    }
}

final class RommeKonsistenzTests: XCTestCase {
    func testFrischerStandUndComputerpartieBleibenStimmig() {
        var g = SystemRandomNumberGenerator()
        for spieler in 2...4 {
            var r = Romme(spieler: spieler, mit: &g)
            XCTAssertTrue(r.istKonsistent)
            var zuege = 0
            while r.gewinner == nil, zuege < 120 {
                RommeComputer.zug(&r, stufe: 1 + zuege % 3, mit: &g); zuege += 1
                XCTAssertTrue(r.istKonsistent, "nach Zug \(zuege) mit \(spieler) Spielern")
            }
        }
    }
    func testStandUeberlebtSpeichernUndLaden() throws {
        var g = SystemRandomNumberGenerator()
        var r = Romme(spieler: 3, mit: &g)
        for _ in 0..<5 { RommeComputer.zug(&r, mit: &g) }
        let geladen = try JSONDecoder().decode(Romme.self, from: JSONEncoder().encode(r))
        XCTAssertEqual(geladen, r); XCTAssertTrue(geladen.istKonsistent)
    }
    func testKaputteStaendeWerdenErkannt() throws {
        var g = SystemRandomNumberGenerator()
        let r = Romme(spieler: 2, mit: &g)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(r)) as? [String: Any])
        func lade(_ j: [String: Any]) throws -> Romme { try JSONDecoder().decode(Romme.self, from: JSONSerialization.data(withJSONObject: j)) }
        var a = json; a["dran"] = 5
        XCTAssertFalse(try lade(a).istKonsistent, "Zeiger außerhalb")
        var b = json; b["stapel"] = [Any]()
        XCTAssertFalse(try lade(b).istKonsistent, "Karten fehlen")
        var c = json; c["hatAusgelegt"] = [false]
        XCTAssertFalse(try lade(c).istKonsistent, "Spielerzahl passt nicht")
        var d = json; d["gewinner"] = 1
        XCTAssertFalse(try lade(d).istKonsistent, "Gewinner mit Karten auf der Hand")
        json["ablage"] = (json["ablage"] as? [Any] ?? []) + (json["ablage"] as? [Any] ?? [])
        XCTAssertFalse(try lade(json).istKonsistent, "doppelte Karte")
    }
}


final class AuslagenOrdnungTests: XCTestCase {
    func testAuslagenWerdenGeordnet() {
        let k = [RKarte(0, 10), RKarte(0, 9), RKarte(0, 7), RKarte(0, 8)]
        XCTAssertEqual(RommeRegeln.ordne(k).map(\.wert), [7, 8, 9, 10])
        let m = [RKarte(0, 0), RKarte(0, 9), RKarte(0, 7)]
        XCTAssertEqual(RommeRegeln.ordne(m).map(\.wert), [7, 0, 9])
    }
}

/// 1.0 (M19): Sortieren ändert nur die Anzeige-Reihenfolge.
final class RommeSortierTests: XCTestCase {
    private let hand = [RKarte(2, 5), RKarte(0, 0), RKarte(0, 13), RKarte(2, 1), RKarte(1, 5), RKarte(0, 2)]
    func testWieGezogenBleibtUnveraendert() {
        XCTAssertEqual(RommeSortierung.gezogen.reihenfolge(hand), [0, 1, 2, 3, 4, 5])
    }
    func testNachFarbeDannWertJokerHinten() {
        let r = RommeSortierung.farbe.reihenfolge(hand)
        XCTAssertEqual(r.map { hand[$0] }, [RKarte(0, 2), RKarte(0, 13), RKarte(1, 5), RKarte(2, 1), RKarte(2, 5), RKarte(0, 0)])
    }
    func testNachWertDannFarbeJokerHinten() {
        let r = RommeSortierung.wert.reihenfolge(hand)
        XCTAssertEqual(r.map { hand[$0] }, [RKarte(2, 1), RKarte(0, 2), RKarte(1, 5), RKarte(2, 5), RKarte(0, 13), RKarte(0, 0)])
    }
    func testReihenfolgeIstEinePermutation() {
        for s in RommeSortierung.allCases { XCTAssertEqual(Set(s.reihenfolge(hand)), Set(hand.indices)) }
    }
}

/// 1.0 (S3 Jokertausch): echte Karte gegen den Joker einer Auslage.
final class RommeJokerTauschTests: XCTestCase {
    private let k: (Int, Int) -> RKarte = { RKarte($0, $1, 0) }
    private let joker = RKarte(0, 0, 3)
    /// Tisch: ♥5 Joker ♥7 (Joker steht für ♥6), Spieler 0 hat schon ausgelegt und gezogen.
    private func stellung(hand: [RKarte], ausgelegt: Bool = true, gezogen: Bool = true) -> Romme {
        Romme(haende: [hand, [k(1, 2), k(1, 3)]], tisch: [[k(2, 5), joker, k(2, 7)]], hatAusgelegt: [ausgelegt, true], gezogen: gezogen)
    }
    func testEchteKarteTauschtJoker() {
        var r = stellung(hand: [k(2, 6), k(0, 13)])
        XCTAssertTrue(r.kannJokerTauschen(0, an: 0)); XCTAssertTrue(r.jokerTauschMoeglich)
        XCTAssertTrue(r.jokerTauschen(0, an: 0))
        XCTAssertEqual(r.tisch[0], [k(2, 5), k(2, 6), k(2, 7)])
        XCTAssertEqual(r.haende[0], [joker, k(0, 13)])
        XCTAssertEqual(r.dran, 0, "der Zug geht weiter")
        XCTAssertTrue(RommeRegeln.istMeld(r.tisch[0]))
    }
    func testFalscheKarteTauschtNicht() {
        var r = stellung(hand: [k(1, 6), k(2, 9)])
        XCTAssertFalse(r.kannJokerTauschen(0, an: 0)); XCTAssertFalse(r.kannJokerTauschen(1, an: 0))
        XCTAssertFalse(r.jokerTauschen(0, an: 0))
    }
    func testErstNachDerErstenAuslageUndNachDemZiehen() {
        XCTAssertFalse(stellung(hand: [k(2, 6)], ausgelegt: false).kannJokerTauschen(0, an: 0))
        XCTAssertFalse(stellung(hand: [k(2, 6)], gezogen: false).kannJokerTauschen(0, an: 0))
    }
    func testJokerGegenJokerGehtNicht() {
        XCTAssertFalse(stellung(hand: [RKarte(0, 0, 4)]).kannJokerTauschen(0, an: 0))
    }
    func testSatzTausch() {
        var r = Romme(haende: [[k(1, 9), k(0, 2)], [k(1, 2)]], tisch: [[k(0, 9), k(2, 9), joker]], hatAusgelegt: [true, true], gezogen: true)
        XCTAssertTrue(r.jokerTauschen(0, an: 0))
        XCTAssertEqual(Set(r.tisch[0]), [k(0, 9), k(2, 9), k(1, 9)])
        XCTAssertTrue(r.haende[0].contains(joker))
    }
    func testComputerTauschtUndNichtsGehtVerloren() {
        var r = stellung(hand: [k(2, 6), k(0, 13), k(1, 13), k(3, 2)])
        r = Romme(haende: r.haende, stapel: [k(3, 9)], ablage: [k(3, 4)], tisch: r.tisch, hatAusgelegt: [true, true])
        var g = FesterZufall(seed: 7)
        let vorher = r.haende.flatMap { $0 }.count + r.tisch.flatMap { $0 }.count + r.stapel.count + r.ablage.count
        RommeComputer.zug(&r, stufe: 3, mit: &g)
        XCTAssertEqual(r.tisch[0], [k(2, 5), k(2, 6), k(2, 7)], "der Computer tauscht den Joker gegen seine ♥6")
        XCTAssertTrue(r.tisch.allSatisfy(RommeRegeln.istMeld))
        XCTAssertEqual(r.haende.flatMap { $0 }.count + r.tisch.flatMap { $0 }.count + r.stapel.count + r.ablage.count, vorher)
    }
    func testVorschlagNenntDenTausch() {
        let r = stellung(hand: [k(0, 13), k(2, 6)])
        XCTAssertEqual(RommeComputer.vorschlag(r), .jokerTauschen(index: 1, an: 0))
    }
}

/// 1.0 (M8): mehrere Runden als Wahl, Strafpunkte = Augen der Resthand, wenigste gewinnen.
final class RommeRundenTests: XCTestCase {
    private let k: (Int, Int) -> RKarte = { RKarte($0, $1, 0) }
    func testStandardIstEineRunde() {
        var g = FesterZufall(seed: 1)
        let r = Romme(spieler: 2, mit: &g)
        XCTAssertEqual(r.rundenZiel, 1); XCTAssertEqual(r.runde, 1); XCTAssertEqual(r.gesamt, [0, 0])
        var g2 = FesterZufall(seed: 1)
        XCTAssertEqual(Romme(spieler: 2, runden: 4, mit: &g2).rundenZiel, 1, "nur 1, 3 oder 5")
    }
    func testRundenendeZaehltStrafpunkteUndGibtNeu() {
        // Spieler 0 wirft seine letzte Karte ab; Spieler 1 hat ♣K (10) und Joker (20) = 30
        var r = Romme(haende: [[k(0, 5)], [k(0, 13), RKarte(0, 0, 1)]], hatAusgelegt: [true, false], gezogen: true, rundenZiel: 3)
        XCTAssertTrue(r.abwerfen(0))
        XCTAssertEqual(r.gewinner, 0); XCTAssertEqual(r.gesamt, [0, 30])
        XCTAssertTrue(r.hatWeitereRunde); XCTAssertFalse(r.partieVorbei)
        var g = FesterZufall(seed: 3)
        r.naechsteRunde(mit: &g)
        XCTAssertNil(r.gewinner); XCTAssertEqual(r.runde, 2); XCTAssertEqual(r.dran, 1, "Startspieler rückt weiter")
        XCTAssertEqual(r.gesamt, [0, 30]); XCTAssertTrue(r.tisch.isEmpty); XCTAssertEqual(r.hatAusgelegt, [false, false])
        XCTAssertTrue(r.haende.allSatisfy { $0.count == 13 }); XCTAssertTrue(r.istKonsistent)
    }
    func testEineRundeEndetSofort() {
        var r = Romme(haende: [[k(0, 5)], [k(0, 13)]], hatAusgelegt: [true, false], gezogen: true)
        r.abwerfen(0)
        XCTAssertTrue(r.partieVorbei); XCTAssertFalse(r.hatWeitereRunde)
        var g = FesterZufall(seed: 3); let vorher = r
        r.naechsteRunde(mit: &g)
        XCTAssertEqual(r, vorher, "nach der letzten Runde wird nicht neu gegeben")
    }
    func testGesamtRangfolgeWenigsteZuerst() {
        let r = Romme(haende: [[k(0, 5)], [k(1, 5)], [k(2, 5)]], rundenZiel: 3, runde: 2, gesamt: [40, 12, 25])
        XCTAssertEqual(r.gesamtRangfolge, [1, 2, 0])
    }
    func testComputerPartieUeberDreiRundenBleibtStimmig() {
        var g = FesterZufall(seed: 11)
        var r = Romme(spieler: 3, runden: 3, mit: &g); var n = 0
        while !r.partieVorbei, n < 5000 {
            if r.hatWeitereRunde { r.naechsteRunde(mit: &g) } else { RommeComputer.zug(&r, stufe: 3, mit: &g) }
            n += 1
            XCTAssertTrue(r.istKonsistent)
        }
        XCTAssertTrue(r.partieVorbei); XCTAssertEqual(r.runde, 3)
    }
    func testAlterStandOhneRundenfelderLaedtAlsEineRunde() throws {
        var g = FesterZufall(seed: 5)
        let r = Romme(spieler: 2, mit: &g)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(r)) as? [String: Any])
        json["rundenZiel"] = nil; json["runde"] = nil; json["gesamt"] = nil
        let alt = try JSONDecoder().decode(Romme.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertEqual(alt, r); XCTAssertTrue(alt.istKonsistent)
    }
}

/// 1.0 (S3 Augen): Anzeige der Augen der gewählten Auslage.
final class RommeAugenTests: XCTestCase {
    private let k: (Int, Int) -> RKarte = { RKarte($0, $1, 0) }
    func testGueltigeAuswahlZaehltWieBeimAuslegen() {
        XCTAssertEqual(RommeRegeln.auslageAugen([k(0, 10), k(1, 10), k(2, 10)]), 30)
        XCTAssertEqual(RommeRegeln.auslageAugen([k(0, 10), k(1, 10), k(2, 10), k(3, 5), k(3, 6), k(3, 7)]), 48)
        XCTAssertEqual(RommeRegeln.auslageAugen([k(2, 12), k(2, 13), k(2, 1)]), 31, "Ass oben zählt 11")
    }
    func testUngueltigeOderZuKleineAuswahl() {
        XCTAssertNil(RommeRegeln.auslageAugen([k(0, 10), k(1, 10)]))
        XCTAssertNil(RommeRegeln.auslageAugen([k(0, 10), k(1, 9), k(2, 3)]))
    }
}
