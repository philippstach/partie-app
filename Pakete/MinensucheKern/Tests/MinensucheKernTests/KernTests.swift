// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import MinensucheKern

final class KernTests: XCTestCase {
    func testErsterZugVerliertNie() {
        for seed in 0..<50 as Range<UInt64> {
            var s = Spiel(stufe: .mittel, seed: seed)
            s.aufdecken(Position(zeile: 5, spalte: 4))
            XCTAssertNotEqual(s.status, .verloren)
            XCTAssertEqual(s.minen.filter { $0 }.count, Stufe.mittel.mass.minen)
        }
    }

    func testSelbeSeedSelbesBrett() {
        var a = Spiel(stufe: .schwer, seed: 42), b = Spiel(stufe: .schwer, seed: 42)
        let p = Position(zeile: 3, spalte: 3)
        a.aufdecken(p); b.aufdecken(p)
        XCTAssertEqual(a.minen, b.minen)
    }

    func testFaireBretterSindOhneRatenLoesbar() {
        for stufe in Stufe.allCases {
            var s = Spiel(stufe: stufe, seed: 7)
            let start = Position(zeile: 4, spalte: 3)
            s.aufdecken(start)
            XCTAssertTrue(Loeser.istOhneRatenLoesbar(mass: s.mass, minen: s.minen, start: s.mass.index(start)), "\(stufe)")
        }
    }

    /// RT-006: Auch wenn die ersten 300 Würfe eines Seeds nicht lösbar sind, bleibt das Brett ohne Raten lösbar.
    func testFaireBretterVieleSeeds() {
        XCTAssertGreaterThan(Spiel.maxVersuche, 300)
        for stufe in Stufe.allCases {
            for seed in 1...25 as ClosedRange<UInt64> {
                var s = Spiel(stufe: stufe, seed: seed)
                let start = Position(zeile: 4, spalte: 3)
                s.aufdecken(start)
                XCTAssertTrue(Loeser.istOhneRatenLoesbar(mass: s.mass, minen: s.minen, start: s.mass.index(start)), "\(stufe) \(seed)")
            }
        }
    }

    /// RT-043: Ein Hinweis verhindert die Bestzeit.
    func testHinweisVerhindertBestzeit() {
        var s = Spiel(stufe: .leicht, seed: 3)
        s.aufdecken(Position(zeile: 4, spalte: 3))
        XCTAssertTrue(s.bestzeitMoeglich)
        _ = s.hinweisGeben()
        XCTAssertEqual(s.hinweise, 1)
        XCTAssertFalse(s.bestzeitMoeglich)
        var stat = Statistik()
        XCTAssertFalse(stat.verbuche(stufe: .leicht, gewonnen: true, dauer: 50, bestzeitMoeglich: s.bestzeitMoeglich))
    }

    func testGewinnMitLoeser() {
        var s = Spiel(stufe: .leicht, seed: 3)
        s.aufdecken(Position(zeile: 4, spalte: 3))
        var schritte = 0
        while s.status == .laeuft, schritte < 500 { s.hinweisGeben(); schritte += 1 }
        XCTAssertEqual(s.status, .gewonnen)
        XCTAssertEqual(s.minenRest, 0)
        XCTAssertGreaterThan(s.dauer, 0)
    }

    func testMineVerliert() {
        var s = Spiel(stufe: .leicht, seed: 1, fair: false)
        s.aufdecken(Position(zeile: 4, spalte: 3))
        let i = s.minen.firstIndex(of: true)!
        s.aufdecken(s.mass.position(i))
        XCTAssertEqual(s.status, .verloren)
        XCTAssertEqual(s.ausgeloest, i)
    }

    func testFlaggeSchuetztUndSchaltetUm() {
        var s = Spiel(stufe: .leicht, seed: 1)
        let p = Position(zeile: 0, spalte: 0)
        s.flaggeUmschalten(p)
        XCTAssertEqual(s.feld(p), .flagge)
        s.aufdecken(p)
        XCTAssertEqual(s.status, .bereit)
        s.flaggeUmschalten(p)
        XCTAssertEqual(s.feld(p), .verdeckt)
    }

    func testChordMitFalscherFlaggeVerliert() {
        var s = Spiel(stufe: .leicht, seed: 5, fair: false)
        s.aufdecken(Position(zeile: 4, spalte: 3))
        // Eine aufgedeckte Zahl mit verdecktem Nachbarn suchen und falsch beflaggen.
        for i in 0..<s.mass.felder where s.felder[i] == .aufgedeckt && s.zahl(s.mass.position(i)) > 0 {
            let n = s.mass.nachbarn(i)
            let verdeckt = n.filter { s.felder[$0] == .verdeckt }
            let zahl = s.zahl(s.mass.position(i))
            let keineMine = verdeckt.filter { !s.minen[$0] }
            guard keineMine.count >= 1, verdeckt.count >= zahl else { continue }
            var gesetzt = 0
            for f in keineMine.prefix(zahl) { s.flaggeUmschalten(s.mass.position(f)); gesetzt += 1 }
            guard gesetzt == zahl else { continue }
            s.aufdecken(s.mass.position(i))
            XCTAssertEqual(s.status, .verloren)
            return
        }
    }

    func testTagesraetselGleichFuerAlle() {
        let a = Spiel.tagesraetsel(jahr: 2026, monat: 11, tag: 3)
        let b = Spiel.tagesraetsel(jahr: 2026, monat: 11, tag: 3)
        let c = Spiel.tagesraetsel(jahr: 2026, monat: 11, tag: 4)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a.minen, c.minen)
        XCTAssertEqual(a.status, .laeuft)
    }

    func testSpeichernUndLaden() throws {
        var s = Spiel(stufe: .mittel, seed: 9)
        s.aufdecken(Position(zeile: 2, spalte: 2))
        let neu = try JSONDecoder().decode(Spiel.self, from: JSONEncoder().encode(s))
        XCTAssertEqual(s, neu)
    }

    func testStatistik() {
        var st = Statistik()
        XCTAssertTrue(st.verbuche(stufe: .leicht, gewonnen: true, dauer: 50))
        XCTAssertFalse(st.verbuche(stufe: .leicht, gewonnen: true, dauer: 60))
        st.verbuche(stufe: .leicht, gewonnen: false, dauer: 5)
        let e = st.fuer(.leicht)
        XCTAssertEqual(e.gespielt, 3); XCTAssertEqual(e.gewonnen, 2)
        XCTAssertEqual(e.besteZeit, 50); XCTAssertEqual(e.serie, 0); XCTAssertEqual(e.besteSerie, 2)
        st.verbucheTag(tag: 20261103, gestern: 20261102)
        st.verbucheTag(tag: 20261104, gestern: 20261103)
        st.verbucheTag(tag: 20261104, gestern: 20261103)
        XCTAssertEqual(st.tagesSerie, 2); XCTAssertEqual(st.tageGeloest, 2)
    }

    func testLoeserEinzelzahl() {
        // 3x1-Streifen: Mine links, Zahl 1 in der Mitte → rechts sicher
        let mass = Brettmass(zeilen: 1, spalten: 3, minen: 1)
        let erg = Loeser.ableiten(mass: mass, zahl: [0, 1, 0], aufgedeckt: [false, true, false])
        XCTAssertTrue(erg.sicher.isEmpty && erg.minen.isEmpty) // 1 aus 2 offen: ohne Zusatzinfo unklar
    }

    func testAlteStatistikOhneNeueFelderLaedtMitStandardwerten() throws {
        let alt = Data(#"{"tagesSerie": 3}"#.utf8)
        let st = try JSONDecoder().decode(Statistik.self, from: alt)
        XCTAssertEqual(st.tagesSerie, 3)
        XCTAssertEqual(st.tageGeloest, 0)
        XCTAssertTrue(st.stufen.isEmpty)
        let stufe = try JSONDecoder().decode(StufenStatistik.self, from: Data(#"{"gespielt": 5}"#.utf8))
        XCTAssertEqual(stufe.gespielt, 5)
        XCTAssertEqual(stufe.besteSerie, 0)
    }

    func testSpielstandRoundTripUndKaputteFeldanzahl() throws {
        var s = Spiel(stufe: .leicht, seed: 7)
        s.aufdecken(Position(zeile: 2, spalte: 2))
        let daten = try JSONEncoder().encode(s)
        XCTAssertEqual(try JSONDecoder().decode(Spiel.self, from: daten), s)
        var json = try XCTUnwrap(try JSONSerialization.jsonObject(with: daten) as? [String: Any])
        json["felder"] = [0, 1]
        let kaputt = try JSONSerialization.data(withJSONObject: json)
        XCTAssertThrowsError(try JSONDecoder().decode(Spiel.self, from: kaputt))
    }

    func testSerieZaehltNurWennHeuteOderGesternGeloestWurde() {
        var st = Statistik()
        st.verbucheTag(tag: 20261102, gestern: 20261101)
        st.verbucheTag(tag: 20261103, gestern: 20261102)
        XCTAssertEqual(st.tagesSerie, 2)
        XCTAssertEqual(st.aktuelleSerie(heute: 20261103, gestern: 20261102), 2)   // heute gelöst
        XCTAssertEqual(st.aktuelleSerie(heute: 20261104, gestern: 20261103), 2)   // heute noch offen, gestern gelöst
        XCTAssertEqual(st.aktuelleSerie(heute: 20261105, gestern: 20261104), 0)   // zwei Tage ausgelassen: gerissen
    }

    func testStatistikMitUnbekannterStufeLaedtDenRest() throws {
        let json = Data(#"{"tagesSerie": 4, "tageGeloest": 9, "stufen": "kaputt"}"#.utf8)
        let st = try JSONDecoder().decode(Statistik.self, from: json)
        XCTAssertEqual(st.tagesSerie, 4)
        XCTAssertEqual(st.tageGeloest, 9)
        XCTAssertTrue(st.stufen.isEmpty)
    }
}

final class MinensucheRegelTests: XCTestCase {
    func testZahlEntsprichtDenMinenInDerNachbarschaft() {
        var s = Spiel(stufe: .mittel, seed: 11)
        s.aufdecken(Position(zeile: 4, spalte: 4))
        for i in 0..<s.mass.felder {
            let p = s.mass.position(i)
            guard !s.istMine(p) else { continue }
            XCTAssertEqual(s.zahl(p), s.mass.nachbarn(i).filter { s.minen[$0] }.count)
        }
    }
    func testErstesFeldIstNullUndOeffnetEineFlaeche() {
        for seed in 0..<20 as Range<UInt64> {
            var s = Spiel(stufe: .mittel, seed: seed)
            let start = Position(zeile: 3, spalte: 3)
            s.aufdecken(start)
            XCTAssertEqual(s.zahl(start), 0)
            XCTAssertGreaterThan(s.felder.filter { $0 == .aufgedeckt }.count, 1, "Eine Null deckt ihre Nachbarn auf")
        }
    }
    func testMinenRestZaehltFlaggenAb() {
        var s = Spiel(stufe: .leicht, seed: 3)
        let vorher = s.minenRest
        s.flaggeUmschalten(Position(zeile: 0, spalte: 0))
        XCTAssertEqual(s.minenRest, vorher - 1); XCTAssertEqual(s.flaggen, 1)
        s.flaggeUmschalten(Position(zeile: 0, spalte: 0))
        XCTAssertEqual(s.minenRest, vorher)
    }
    func testGeflaggtesFeldWirdNichtAufgedeckt() {
        var s = Spiel(stufe: .leicht, seed: 5)
        let p = Position(zeile: 2, spalte: 2)
        s.flaggeUmschalten(p); s.aufdecken(p)
        XCTAssertEqual(s.feld(p), .flagge)
    }
    func testNachDemEndeAendertSichNichts() {
        var s = Spiel(stufe: .leicht, seed: 9)
        s.aufdecken(Position(zeile: 4, spalte: 4))
        guard let mine = (0..<s.mass.felder).first(where: { s.minen[$0] }) else { return XCTFail() }
        s.aufdecken(s.mass.position(mine))
        XCTAssertEqual(s.status, .verloren)
        let stand = s
        s.aufdecken(Position(zeile: 0, spalte: 0)); s.flaggeUmschalten(Position(zeile: 1, spalte: 1))
        XCTAssertEqual(s, stand)
    }
}

final class GeteiltTests: XCTestCase {
    func testGeteiltesRaetselIstFuerAlleGleich() {
        for stufe in Stufe.allCases {
            let a = Spiel.geteilt(stufe: stufe, seed: 4711), b = Spiel.geteilt(stufe: stufe, seed: 4711)
            XCTAssertEqual(a.minen, b.minen)
            XCTAssertEqual(a.felder, b.felder)
            XCTAssertNotEqual(a.status, .verloren)
            XCTAssertEqual(a.minen.filter { $0 }.count, stufe.mass.minen)
        }
        XCTAssertNotEqual(Spiel.geteilt(stufe: .mittel, seed: 1).minen, Spiel.geteilt(stufe: .mittel, seed: 2).minen)
    }

    // MARK: 1.0 (M3) Zweite Chance, Rest öffnen

    private func mineGetroffen(seed: UInt64 = 1) -> Spiel {
        var s = Spiel(stufe: .leicht, seed: seed, fair: false)
        s.aufdecken(Position(zeile: 4, spalte: 3))
        let i = s.minen.firstIndex(of: true)!
        s.aufdecken(s.mass.position(i))
        return s
    }

    func testZweiteChanceNimmtDenMinenzugZurueck() {
        var s = mineGetroffen()
        XCTAssertEqual(s.status, .verloren)
        XCTAssertTrue(s.zweiteChanceMoeglich)
        let mine = s.ausgeloest!
        let dauer = s.dauer
        XCTAssertTrue(s.zweiteChanceNehmen())
        XCTAssertEqual(s.status, .laeuft)
        XCTAssertNil(s.ausgeloest)
        XCTAssertEqual(s.feld(s.mass.position(mine)), .flagge)
        XCTAssertEqual(s.dauer, dauer + 30)
        XCTAssertTrue(s.zweiteChanceGenutzt)
        // nur einmal je Partie
        XCTAssertFalse(s.zweiteChanceMoeglich)
        XCTAssertFalse(s.zweiteChanceNehmen())
    }

    /// N-024: Nach einer Mine bleiben die übrigen Minen verdeckt, solange der Spieler noch weiterspielen kann.
    func testNachMineSindDieUebrigenMinenErstBeimAufhoerenSichtbar() {
        var s = mineGetroffen()
        XCTAssertEqual(s.status, .verloren)
        XCTAssertTrue(s.zweiteChanceMoeglich)
        XCTAssertFalse(s.minenSichtbar, "erst die Frage: weiterspielen?")
        s.minenZeigen()
        XCTAssertTrue(s.minenSichtbar)
        XCTAssertFalse(s.zweiteChanceMoeglich, "wer die Minen gesehen hat, spielt nicht mehr weiter")
        XCTAssertFalse(s.zweiteChanceNehmen())
    }

    func testWeiterspielenNachMineLaesstFeldVerdecktUndNimmtDieMineAlsFahne() {
        var s = mineGetroffen()
        XCTAssertFalse(s.minenSichtbar)
        XCTAssertTrue(s.zweiteChanceNehmen())
        XCTAssertFalse(s.minenSichtbar)
        XCTAssertEqual(s.status, .laeuft)
    }

    func testOhneZweiteChanceZeigtDasBrettSofortAlleMinen() {
        var s = mineGetroffen()
        XCTAssertTrue(s.zweiteChanceNehmen())
        let i = s.minen.indices.first { s.minen[$0] && s.felder[$0] == .verdeckt }!
        s.aufdecken(s.mass.position(i))
        XCTAssertEqual(s.status, .verloren)
        XCTAssertTrue(s.minenSichtbar, "keine Wahl mehr: gleich zeigen")
    }

    func testMinenZeigenNurNachEinerMine() {
        var s = Spiel(stufe: .leicht, seed: 1)
        s.minenZeigen()
        XCTAssertFalse(s.minenAufgedeckt)
    }

    func testZweiteChanceNurEinmalAuchBeiZweiterMine() {
        var s = mineGetroffen()
        XCTAssertTrue(s.zweiteChanceNehmen())
        let i = s.minen.indices.first { s.minen[$0] && s.felder[$0] == .verdeckt }!
        s.aufdecken(s.mass.position(i))
        XCTAssertEqual(s.status, .verloren)
        XCTAssertFalse(s.zweiteChanceMoeglich)
    }

    func testZweiteChanceNichtOhneMine() {
        var s = Spiel(stufe: .leicht, seed: 1)
        XCTAssertFalse(s.zweiteChanceNehmen())
        s.aufdecken(Position(zeile: 4, spalte: 3))
        XCTAssertFalse(s.zweiteChanceNehmen())
    }

    func testZweiteChanceUeberlebtSpeichernUndLaden() throws {
        var s = mineGetroffen()
        s.zweiteChanceNehmen()
        let neu = try JSONDecoder().decode(Spiel.self, from: JSONEncoder().encode(s))
        XCTAssertTrue(neu.zweiteChanceGenutzt)
        XCTAssertFalse(neu.zweiteChanceMoeglich)
    }

    func testAlterStandOhneZweiteChanceLaedt() throws {
        var s = Spiel(stufe: .leicht, seed: 5)
        s.aufdecken(Position(zeile: 4, spalte: 3))
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as! [String: Any]
        json.removeValue(forKey: "zweiteChanceGenutzt")
        let neu = try JSONDecoder().decode(Spiel.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(neu.zweiteChanceGenutzt)
    }

    func testBestzeitZaehltNichtNachZweiterChance() {
        var st = Statistik()
        XCTAssertFalse(st.verbuche(stufe: .leicht, gewonnen: true, dauer: 20, bestzeitMoeglich: false))
        XCTAssertNil(st.fuer(.leicht).besteZeit)
        XCTAssertEqual(st.fuer(.leicht).gewonnen, 1)
        XCTAssertEqual(st.fuer(.leicht).serie, 1)
    }

    func testAlleMinenMarkiertOeffnetDenRestUndGewinnt() {
        var s = Spiel(stufe: .leicht, seed: 3)
        s.aufdecken(Position(zeile: 4, spalte: 3))
        XCTAssertEqual(s.status, .laeuft)
        let minen = s.minen.indices.filter { s.minen[$0] }
        for i in minen.dropLast() { s.flaggeUmschalten(s.mass.position(i)) }
        XCTAssertEqual(s.status, .laeuft)
        s.flaggeUmschalten(s.mass.position(minen.last!))
        XCTAssertEqual(s.status, .gewonnen)
        XCTAssertTrue((0..<s.mass.felder).allSatisfy { s.minen[$0] || s.felder[$0] == .aufgedeckt })
    }

    func testFalscheFlaggeOeffnetNichts() {
        var s = Spiel(stufe: .leicht, seed: 3)
        s.aufdecken(Position(zeile: 4, spalte: 3))
        let minen = s.minen.indices.filter { s.minen[$0] }
        let keine = s.felder.indices.first { !s.minen[$0] && s.felder[$0] == .verdeckt }!
        for i in minen.dropLast() { s.flaggeUmschalten(s.mass.position(i)) }
        s.flaggeUmschalten(s.mass.position(keine))   // falsch
        XCTAssertEqual(s.status, .laeuft)
        XCTAssertEqual(s.flaggen, minen.count)
        XCTAssertEqual(s.feld(s.mass.position(keine)), .flagge)
    }
}
