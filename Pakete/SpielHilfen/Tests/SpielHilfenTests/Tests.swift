// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
@testable import SpielHilfen
final class RanglisteTests: XCTestCase {
    func testReihenfolgeUndPlaetze() {
        let p = [5, 9, 5, 1]
        let r = Rangliste.reihenfolge(punkte: p, hoeherIstBesser: true)
        XCTAssertEqual(r, [1, 0, 2, 3]); XCTAssertEqual(Rangliste.plaetze(punkte: p, reihenfolge: r), [1, 2, 2, 4])
        XCTAssertEqual(Rangliste.reihenfolge(punkte: p, hoeherIstBesser: false), [3, 0, 2, 1])
    }
}
final class TagesraetselTests: XCTestCase {
    func testSeedStabilUndVerschieden() {
        let d = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(Tagesraetsel.seed(spiel: "a", datum: d), Tagesraetsel.seed(spiel: "a", datum: d))
        XCTAssertNotEqual(Tagesraetsel.seed(spiel: "a", datum: d), Tagesraetsel.seed(spiel: "b", datum: d))
        XCTAssertNotEqual(Tagesraetsel.seed(spiel: "a", datum: d), Tagesraetsel.seed(spiel: "a", datum: d.addingTimeInterval(86400)))
        XCTAssertEqual(Tagesraetsel.tag(d).count, 8)
    }
    func testBestleistung() {
        let k = "test.\(UUID().uuidString)"
        XCTAssertTrue(Bestleistung.melden(k, wert: 20)); XCTAssertFalse(Bestleistung.melden(k, wert: 25)); XCTAssertTrue(Bestleistung.melden(k, wert: 15))
        XCTAssertEqual(Bestleistung.lesen(k), 15)
    }
    /// RT-005: Tages-Bestleistungen verschiedener Größen teilen sich keinen Schlüssel mehr; ohne Variante bleibt der alte Schlüssel.
    func testTagesBestleistungJeVariante() {
        let a = Bestleistung.schluessel("schiebepuzzle", variante: "3", tages: true)
        let b = Bestleistung.schluessel("schiebepuzzle", variante: "4", tages: true)
        XCTAssertNotEqual(a, b)
        XCTAssertEqual(Bestleistung.schluessel("lagerplatz", tages: true), "lagerplatz.tag.\(Tagesraetsel.tag())")
        XCTAssertEqual(Bestleistung.tagesSchluessel("x", variante: "", tag: "20261113"), "x.tag.20261113")
        XCTAssertEqual(Bestleistung.tagesSchluessel("x", variante: "4", tag: "20261113"), "x.tag.20261113.4")
    }
}

final class TagesraetselUhrTests: XCTestCase {
    private func datum(_ j: Int, _ m: Int, _ t: Int, _ h: Int, _ min: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: j, month: m, day: t, hour: h, minute: min))!
    }
    func testTagBleibtDenGanzenTagGleichUndWechseltUmMitternacht() {
        XCTAssertEqual(Tagesraetsel.tag(datum(2026, 11, 8, 0, 0)), "20261108")
        XCTAssertEqual(Tagesraetsel.tag(datum(2026, 11, 8, 23, 59)), "20261108")
        XCTAssertEqual(Tagesraetsel.tag(datum(2026, 11, 9, 0, 1)), "20261109")
    }
    func testSeedGleichAmSelbenTagVerschiedenAmNaechstenTagUndJeSpiel() {
        let a = Tagesraetsel.seed(spiel: "kakuro", datum: datum(2026, 11, 8, 6, 0))
        XCTAssertEqual(a, Tagesraetsel.seed(spiel: "kakuro", datum: datum(2026, 11, 8, 23, 30)))
        XCTAssertNotEqual(a, Tagesraetsel.seed(spiel: "kakuro", datum: datum(2026, 11, 9, 0, 5)))
        XCTAssertNotEqual(a, Tagesraetsel.seed(spiel: "nonogramm", datum: datum(2026, 11, 8, 6, 0)))
    }
    func testSchaltjahrUndJahreswechsel() {
        XCTAssertEqual(Tagesraetsel.tag(datum(2028, 2, 29, 12, 0)), "20280229")
        XCTAssertEqual(Tagesraetsel.tag(datum(2026, 12, 31, 23, 59)), "20261231")
        XCTAssertEqual(Tagesraetsel.tag(datum(2027, 1, 1, 0, 0)), "20270101")
    }
    func testErgebnisZaehltFuerDenStarttagAuchNachMitternacht() {
        let d = UserDefaults(suiteName: "test.tagesstart")!
        d.removePersistentDomain(forName: "test.tagesstart")
        Tagesraetsel.merkeStart(spiel: "testspiel", datum: datum(2026, 11, 8, 23, 58), defaults: d)
        // Es ist inzwischen der nächste Tag: Das Ergebnis gehört trotzdem zum Rätsel vom 08.11.
        XCTAssertEqual(Tagesraetsel.startTag(spiel: "testspiel", jetzt: datum(2026, 11, 9, 0, 3), defaults: d), "20261108")
        // Ohne laufendes Tagesrätsel gilt der heutige Tag.
        XCTAssertEqual(Tagesraetsel.startTag(spiel: "anderes", jetzt: datum(2026, 11, 9, 0, 3), defaults: d), "20261109")
    }
}

/// 1.0 (P5): Serie und gelöste Tage der Tageskarte.
final class TagesSerieTests: XCTestCase {
    private func datum(_ j: Int, _ m: Int, _ t: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: j, month: m, day: t, hour: 12))!
    }
    private func leer() -> UserDefaults {
        let d = UserDefaults(suiteName: "tagesserie.\(UUID().uuidString)")!
        return d
    }
    func testOhneLoesungKeineSerie() {
        XCTAssertEqual(TagesSerie.serie(spiel: "x", heute: datum(2026, 11, 13), defaults: leer()), 0)
    }
    func testSerieZaehltTageInFolgeBisHeute() {
        let d = leer()
        for t in [11, 12, 13] { TagesSerie.melden(spiel: "x", tag: Tagesraetsel.tag(datum(2026, 11, t)), defaults: d) }
        XCTAssertEqual(TagesSerie.serie(spiel: "x", heute: datum(2026, 11, 13), defaults: d), 3)
    }
    func testHeuteOffenSerieLebtWeiterWennGesternGeloest() {
        let d = leer()
        for t in [11, 12] { TagesSerie.melden(spiel: "x", tag: Tagesraetsel.tag(datum(2026, 11, t)), defaults: d) }
        XCTAssertEqual(TagesSerie.serie(spiel: "x", heute: datum(2026, 11, 13), defaults: d), 2)
    }
    func testLuckeBrichtDieSerie() {
        let d = leer()
        for t in [9, 10, 12, 13] { TagesSerie.melden(spiel: "x", tag: Tagesraetsel.tag(datum(2026, 11, t)), defaults: d) }
        XCTAssertEqual(TagesSerie.serie(spiel: "x", heute: datum(2026, 11, 13), defaults: d), 2)
        XCTAssertEqual(TagesSerie.serie(spiel: "x", heute: datum(2026, 11, 16), defaults: d), 0)   // seit drei Tagen nichts gelöst
    }
    func testSerieUeberMonatsUndJahresgrenze() {
        let d = leer()
        for (m, t) in [(12, 30), (12, 31)] { TagesSerie.melden(spiel: "x", tag: Tagesraetsel.tag(datum(2026, m, t)), defaults: d) }
        TagesSerie.melden(spiel: "x", tag: Tagesraetsel.tag(datum(2027, 1, 1)), defaults: d)
        XCTAssertEqual(TagesSerie.serie(spiel: "x", heute: datum(2027, 1, 1), defaults: d), 3)
    }
    func testErstesErgebnisBleibtUndSpieleSindGetrennt() {
        let d = leer()
        TagesSerie.melden(spiel: "x", tag: "20261113", ergebnis: "14 Züge", defaults: d)
        TagesSerie.melden(spiel: "x", tag: "20261113", ergebnis: "9 Züge", defaults: d)
        XCTAssertEqual(TagesSerie.ergebnis(spiel: "x", tag: "20261113", defaults: d), "14 Züge")
        XCTAssertTrue(TagesSerie.geloest(spiel: "x", tag: "20261113", defaults: d))
        XCTAssertFalse(TagesSerie.geloest(spiel: "y", tag: "20261113", defaults: d))
    }
    func testAeltesteTageFallenWeg() {
        let d = leer()
        for i in 0..<(TagesSerie.behalten + 5) { TagesSerie.melden(spiel: "x", tag: String(format: "2000%04d", i), defaults: d) }
        let g = TagesSerie.gespeichert(spiel: "x", defaults: d)
        XCTAssertEqual(g.count, TagesSerie.behalten)
        XCTAssertNil(g["20000000"]); XCTAssertNotNil(g[String(format: "2000%04d", TagesSerie.behalten + 4)])
    }
    func testWunschGiltGenauEinmal() {
        let d = leer()
        XCTAssertFalse(Tagesraetsel.wunschAbholen(spiel: "x", defaults: d))
        Tagesraetsel.wunschMerken(spiel: "x", defaults: d)
        XCTAssertTrue(Tagesraetsel.wunschAbholen(spiel: "x", defaults: d))
        XCTAssertFalse(Tagesraetsel.wunschAbholen(spiel: "x", defaults: d))
    }
    func testWunschVerfaelltNachZweiMinuten() {
        let d = leer(), jetzt = datum(2026, 11, 13)
        Tagesraetsel.wunschMerken(spiel: "x", jetzt: jetzt, defaults: d)
        XCTAssertFalse(Tagesraetsel.wunschAbholen(spiel: "x", jetzt: jetzt.addingTimeInterval(300), defaults: d))
        Tagesraetsel.wunschMerken(spiel: "x", jetzt: jetzt, defaults: d)
        XCTAssertTrue(Tagesraetsel.wunschAbholen(spiel: "x", jetzt: jetzt.addingTimeInterval(30), defaults: d))
    }
    func testTeilenTextEnthaeltNameErgebnisUndSerie() {
        let t = TagesSerie.teilenText(spielName: "Farbfüller", ergebnis: "14 Züge", serie: 3, datum: datum(2026, 11, 13))
        XCTAssertTrue(t.hasPrefix("Farbfüller · ")); XCTAssertTrue(t.contains("14 Züge")); XCTAssertTrue(t.contains("3"))
        XCTAssertFalse(TagesSerie.teilenText(spielName: "A", ergebnis: "", serie: 0).contains("Serie"))
    }
}
