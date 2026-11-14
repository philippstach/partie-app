// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SwiftUI
@testable import SpieleKern
import ArcadeKern

@MainActor
final class KernTests: XCTestCase {
    func testBilanzRemisIstKeinSiegUndBrichtDieSerie() {
        let a = UUID(), b = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        func melde(_ pa: Int, _ pb: Int) { st.melden(PartieErgebnis(spiel: "dame", teilnehmer: [.init(spielerID: a, name: "A", platz: pa), .init(spielerID: b, name: "B", platz: pb)])) }
        melde(1, 2); melde(1, 2)                       // zwei Siege in Folge
        XCTAssertEqual(st.bilanz(spiel: "dame", ich: a).serie, 2)
        melde(1, 1)                                    // Remis: Partie ja, Sieg nein, Serie reißt
        let r = st.bilanz(spiel: "dame", ich: a)
        XCTAssertEqual(r.partien, 3); XCTAssertEqual(r.siege, 2); XCTAssertEqual(r.serie, 0); XCTAssertEqual(r.besteSerie, 2)
        melde(1, 2)                                    // wieder gewonnen: Serie neu bei 1
        XCTAssertEqual(st.bilanz(spiel: "dame", ich: a).serie, 1)
        XCTAssertEqual(st.bilanz(spiel: "dame", ich: b).siege, 0)
    }

    func testDuellZaehltBesserenPlatzRemisUndAbbruchSindUnentschieden() {
        let a = UUID(), b = UUID(), c = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        func melde(_ t: [(UUID, Int)]) { st.melden(PartieErgebnis(spiel: "x", teilnehmer: t.map { .init(spielerID: $0.0, name: "", platz: $0.1) })) }
        melde([(a, 1), (b, 2)])                 // a schlägt b
        melde([(b, 1), (a, 2)])                 // b schlägt a
        melde([(a, 1), (b, 1)])                 // Remis
        melde([(a, 2), (b, 2)])                 // gemeinsam abgebrochen
        melde([(a, 1), (b, 1), (c, 3)])         // beide gleichauf vorn
        melde([(a, 3), (b, 1), (c, 2)])         // b vor a
        melde([(a, 1)])                         // b nicht dabei: zählt nicht
        XCTAssertEqual(st.duell(a, gegen: b), StatistikDienst.Duell(partien: 6, siege: 1, niederlagen: 2, unentschieden: 3))
        XCTAssertEqual(st.duell(b, gegen: a), StatistikDienst.Duell(partien: 6, siege: 2, niederlagen: 1, unentschieden: 3))
        XCTAssertEqual(st.duell(a, gegen: c).partien, 2)
    }

    func testFotoDatenFuerListenNurMitDatei() {
        let id = UUID()
        XCTAssertNil(SpielerBilder.daten(id))
        try? Data([9, 8, 7]).write(to: SpielerBilder.datei(id))
        XCTAssertEqual(SpielerBilder.daten(id), Data([9, 8, 7]))
        SpielerBilder.loeschen(id)
        XCTAssertNil(SpielerBilder.daten(id))
    }

    func testNiederlagenHinweisNurWennGebuchtWird() {
        let t = [("Anna", false), ("Computer", true)]
        XCTAssertNil(PartieMeldung.abbruchBuchung(begonnen: false, spiel: "dame", teilnehmer: t, wertung: .computer, kinder: false))
        XCTAssertNotNil(PartieMeldung.abbruchBuchung(begonnen: true, spiel: "dame", teilnehmer: t, wertung: .computer, kinder: false))
        XCTAssertNil(PartieMeldung.abbruchBuchung(begonnen: true, spiel: "dame", teilnehmer: [("Computer", true)], wertung: .immer, kinder: false))
    }

    func testPartienAndererPersonenZaehlenNichtFuerIchUndReissenKeineSerie() {
        let anna = UUID(), ben = UUID(), cem = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        func melde(_ t: [(UUID?, Int, Int?)]) { st.melden(PartieErgebnis(spiel: "dame", teilnehmer: t.map { .init(spielerID: $0.0, name: "", platz: $0.1, punkte: $0.2) })) }
        melde([(anna, 1, 10), (ben, 2, 5)])
        melde([(ben, 1, 99), (cem, 2, 7)])            // Anna nicht dabei
        melde([(anna, 1, 12), (ben, 2, 8)])
        XCTAssertEqual(st.summe(ich: anna), StatistikSumme(partien: 2, siege: 2, dauer: 0))
        let b = st.bilanz(spiel: "dame", ich: anna)
        XCTAssertEqual(b.partien, 2); XCTAssertEqual(b.siege, 2); XCTAssertEqual(b.serie, 2)
        XCTAssertEqual(b.rekord, 12, "Bestwert nur aus eigenen Punkten, nicht die 99 von Ben")
        XCTAssertEqual(st.bilanz(spiel: "dame", ich: ben).partien, 3)
    }

    func testAltePartienOhnePersonenzuordnungZaehlenWeiterAlsPartie() {
        let anna = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "sudoku", teilnehmer: [.init(name: "", platz: 1)]))
        st.melden(PartieErgebnis(spiel: "sudoku", teilnehmer: [.init(spielerID: anna, name: "Anna", platz: 1)]))
        XCTAssertEqual(st.summe(ich: anna).partien, 2)
        XCTAssertEqual(st.bilanz(spiel: "sudoku", ich: anna).partien, 2)
    }

    func testNachLoeschenDerPersonZaehltFuerDenNeuenIchNurDieGemeinsamePartie() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        let ben = v.speichern(name: "Ben", avatar: "", farbeIndex: 1)!
        let st = StatistikDienst(ablage: SpeicherAblage())
        func buche(_ t: [PartieErgebnis.Teilnehmer]) { st.melden(v.zuordnen(PartieErgebnis(spiel: "x", teilnehmer: t))) }
        buche([.init(name: "Anna", platz: 1), .init(name: "Ben", platz: 2)])
        buche([.init(name: "Anna", platz: 1), .init(name: "Computer", platz: 2)])
        v.loeschen(anna.id)
        XCTAssertEqual(v.ich?.id, ben.id)
        XCTAssertEqual(st.summe(ich: ben.id), StatistikSumme(partien: 1, siege: 0, dauer: 0))
        XCTAssertEqual(st.bilanz(spiel: "x", ich: ben.id).serie, 0)
    }

    /// C-012: Ein Computer mit dem Namen einer Person bekommt nie deren Ergebnis.
    func testComputerMitMenschennamenWirdNichtZugeordnet() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        let e = PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "Anna", platz: 1), .init(name: "Cem", platz: 2)])
        XCTAssertEqual(v.zuordnen(e).teilnehmer[0].spielerID, anna.id)
        XCTAssertNil(v.zuordnen(e, computerNamen: ["anna"]).teilnehmer[0].spielerID)
    }

    /// C-018: Bei Strafpunkte-Spielen zählt der niedrigste Siegerwert als Bestleistung.
    func testRekordBeiStrafpunktenIstDerNiedrigsteSiegerwert() {
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "h", teilnehmer: [.init(name: "A", platz: 1, punkte: 12), .init(name: "B", platz: 2, punkte: 40)]))
        st.melden(PartieErgebnis(spiel: "h", teilnehmer: [.init(name: "A", platz: 1, punkte: 8), .init(name: "B", platz: 2, punkte: 55)]))
        XCTAssertEqual(st.rekord(spiel: "h"), 8)
        st.melden(PartieErgebnis(spiel: "p", teilnehmer: [.init(name: "A", platz: 1, punkte: 90), .init(name: "B", platz: 2, punkte: 40)]))
        XCTAssertEqual(st.rekord(spiel: "p"), 90)
    }

    func testVerlaufTextRemisAbbruchSiegerUndEinzel() {
        func e(_ t: [(String, Int, Int?)]) -> PartieErgebnis { PartieErgebnis(spiel: "x", teilnehmer: t.map { .init(name: $0.0, platz: $0.1, punkte: $0.2) }) }
        let remis = e([("Anna", 1, nil), ("Ben", 1, nil)])
        XCTAssertEqual(remis.ergebnisText(ichName: "Anna"), "Remis: Anna · Ben")
        XCTAssertFalse(remis.istAbbruch)
        let abbruch = e([("Anna", 2, nil), ("Ben", 2, nil)])
        XCTAssertTrue(abbruch.istAbbruch)
        XCTAssertEqual(abbruch.ergebnisText(ichName: "Anna"), "Abgebrochen: Anna · Ben")
        let sieg = e([("Ben", 2, nil), ("Anna", 1, nil)])
        XCTAssertEqual(sieg.ergebnisText(ichName: "Anna"), "🏆 Anna · Ben")
        XCTAssertEqual(sieg.ergebnisText(ichName: "Anna", sprechend: true), "Sieger: Anna · Ben")
        XCTAssertFalse(sieg.ergebnisText(ichName: "Anna", sprechend: true).contains("🏆"))
        // Mensch gegen Computer abgebrochen: der Computer steht vorn, kein Abbruch-Text
        XCTAssertFalse(e([("Computer", 1, nil), ("Anna", 2, nil)]).istAbbruch)
        // Einzelspiele
        XCTAssertEqual(e([("", 1, nil)]).ergebnisText(ichName: "Anna"), "gewonnen")
        XCTAssertEqual(e([("", 2, nil)]).ergebnisText(ichName: "Anna"), "verloren")
        XCTAssertEqual(e([("", 0, 120)]).ergebnisText(ichName: "Anna"), "120 Punkte")
        XCTAssertFalse(e([("", 0, 120)]).istAbbruch)
        XCTAssertEqual(e([("", 1, nil), ("Ben", 3, nil)]).ergebnisText(ichName: "Anna"), "🏆 Anna · Ben")
    }

    /// Fund C-010: Siege aus der Zeit ohne Profil bleiben, wenn man sich später anlegt.
    func testEinzelsiegeOhneProfilBleibenNachMichAnlegen() {
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "sudoku", teilnehmer: [.init(name: "", platz: 1)]))
        st.melden(PartieErgebnis(spiel: "sudoku", teilnehmer: [.init(name: "", platz: 1)]))
        st.melden(PartieErgebnis(spiel: "sudoku", teilnehmer: [.init(name: "", platz: 2)]))
        XCTAssertEqual(st.summe(spiel: "sudoku").siege, 2)
        let ich = UUID()
        XCTAssertEqual(st.summe(spiel: "sudoku", ich: ich).siege, 2)
        XCTAssertEqual(st.summe(spiel: "sudoku", ich: ich).partien, 3)
        let b = st.bilanz(spiel: "sudoku", ich: ich)
        XCTAssertEqual(b.siege, 2); XCTAssertEqual(b.besteSerie, 2); XCTAssertEqual(b.serie, 0)
    }
    /// Funde C-015 (CSV) und C-026 (Dezimalkomma).
    func testCsvFasstFelderEinUndEntschaerftFormeln() {
        XCTAssertEqual(StatistikDienst.csvFeld("Anna"), "Anna")
        XCTAssertEqual(StatistikDienst.csvFeld("Müller, Anna"), "\"Müller, Anna\"")
        XCTAssertEqual(StatistikDienst.csvFeld("=SUMME(A1)"), "'=SUMME(A1)")
        XCTAssertEqual(StatistikDienst.csvFeld("Say \"hi\""), "\"Say \"\"hi\"\"\"")
    }
    func testPunkteMitDezimalkommaWerdenGerundetNichtVerzehnfacht() {
        XCTAssertEqual(EndeBuchung.zahl("92,5"), 93)
        XCTAssertEqual(EndeBuchung.zahl("1.250"), 1250)
        XCTAssertEqual(EndeBuchung.zahl("−3"), -3)
        XCTAssertEqual(EndeBuchung.zahl("12 Punkte"), 12)
        XCTAssertNil(EndeBuchung.zahl("keine"))
    }
    func testSpielerAnlegenUndIch() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let a = v.anlegen(name: "Anna"); v.anlegen(name: "Ben")
        XCTAssertEqual(v.alle.count, 2); XCTAssertEqual(v.ich?.id, a.id)
        XCTAssertEqual(v.anlegen(name: "anna").id, a.id)
        v.loeschen(a.id); XCTAssertEqual(v.ich?.name, "Ben")
    }
    func testStatistik() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage()); let a = v.anlegen(name: "A"); let b = v.anlegen(name: "B")
        let s = StatistikDienst(ablage: SpeicherAblage())
        s.melden(.init(spiel: "yacht", dauer: 60, teilnehmer: [.init(spielerID: a.id, name: "A", platz: 1), .init(spielerID: b.id, name: "B", platz: 2)]))
        s.melden(.init(spiel: "schocken", teilnehmer: [.init(spielerID: a.id, name: "A", platz: 2), .init(spielerID: b.id, name: "B", platz: 1)]))
        XCTAssertEqual(s.summe(spieler: a.id).siege, 1); XCTAssertEqual(s.summe(spiel: "yacht").partien, 1)
        XCTAssertEqual(s.serie(zwischen: [a.id, b.id]).map(\.1), [1, 1])
    }
    func testDurchschnittUndBestwertArcade() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        XCTAssertNil(s.durchschnitt(spiel: "steinfall"))
        for p in [100, 200, 301] { s.melden(.init(spiel: "steinfall", teilnehmer: [.init(name: "A", platz: 0, punkte: p)])) }
        s.melden(.init(spiel: "dauerlauf", teilnehmer: [.init(name: "A", platz: 0, punkte: 999)]))
        XCTAssertEqual(s.durchschnitt(spiel: "steinfall"), 200)
        XCTAssertEqual(s.rekord(spiel: "steinfall"), 301)
        XCTAssertEqual(s.bilanz(spiel: "steinfall").partien, 3)
    }
    func testDuellStatistikPartienSiegeUndRallye() {
        let s = StatistikDienst(ablage: SpeicherAblage()); let ich = UUID()
        XCTAssertNil(s.besteRallye(spiel: "ballwechsel"))
        s.melden(.init(spiel: "ballwechsel", teilnehmer: [.init(spielerID: ich, name: "A", platz: 1, punkte: 7), .init(name: "Computer", platz: 2, punkte: 3)], kennzahlen: ["rallye": 9]))
        s.melden(.init(spiel: "ballwechsel", teilnehmer: [.init(name: "Computer", platz: 1, punkte: 7), .init(spielerID: ich, name: "A", platz: 2, punkte: 5)], kennzahlen: ["rallye": 14]))
        let b = s.bilanz(spiel: "ballwechsel", ich: ich)
        XCTAssertEqual(b.partien, 2); XCTAssertEqual(b.siege, 1)
        XCTAssertEqual(s.besteRallye(spiel: "ballwechsel"), 14)
    }
    func testRekordeJeStufeVerdraengenSichNicht() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        func p(_ punkte: Int, stufe: Int?) { s.melden(.init(spiel: "dauerlauf", teilnehmer: [.init(name: "A", platz: 0, punkte: punkte)], kennzahlen: stufe.map { ["stufe": Double($0)] } ?? [:])) }
        p(900, stufe: nil)      // alte Partie aus der Zeit vor den Stufen = Mittel
        p(300, stufe: 1); p(500, stufe: 1)
        p(120, stufe: 3)
        XCTAssertEqual(s.rekord(spiel: "dauerlauf", stufe: 1), 500)
        XCTAssertEqual(s.rekord(spiel: "dauerlauf", stufe: 2), 900)
        XCTAssertEqual(s.rekord(spiel: "dauerlauf", stufe: 3), 120)
        XCTAssertEqual(s.durchschnitt(spiel: "dauerlauf", stufe: 1), 400)
        XCTAssertEqual(s.rekord(spiel: "dauerlauf"), 900)     // Gesamt unverändert
        XCTAssertNil(s.rekord(spiel: "steinfall", stufe: 2))
        XCTAssertTrue(Rekord.istNeu(punkte: 150, bisher: s.rekord(spiel: "dauerlauf", stufe: 3)))
    }
    func testBilanzSerieUndRekord() {
        let s = StatistikDienst(ablage: SpeicherAblage()); let id = UUID()
        func p(_ platz: Int) -> PartieErgebnis { .init(spiel: "x", teilnehmer: [.init(spielerID: id, name: "A", platz: platz)]) }
        [1, 1, 2, 1, 1, 1].forEach { s.melden(p($0)) }
        s.melden(.init(spiel: "x", teilnehmer: [.init(spielerID: nil, name: "A", platz: 0, punkte: 420)]))
        let b = s.bilanz(spiel: "x", ich: id)
        XCTAssertEqual(b.partien, 7); XCTAssertEqual(b.siege, 5); XCTAssertEqual(b.serie, 3); XCTAssertEqual(b.besteSerie, 3); XCTAssertEqual(b.rekord, 420)
        XCTAssertEqual(s.bilanz(spiel: "leer"), SpielBilanz())
    }
    func testBecher() {
        var g = ZufallsQuelle(seed: 7); var b = WuerfelBecher(anzahl: 5)
        b.wuerfeln(mit: &g); b.halten(0); let e = b.augen[0]; b.wuerfeln(mit: &g)
        XCTAssertEqual(b.augen[0], e); XCTAssertEqual(b.verlauf.count, 2)
        XCTAssertFalse(b.eintragen([1, 2, 7, 1, 1])); XCTAssertTrue(b.eintragen([6, 6, 6, 6, 6]))
    }
}

final class KartenstapelTests: XCTestCase {
    func testBlattUndZiehen() {
        var g = SystemRandomNumberGenerator()
        var s = Kartenstapel(SkatKarte.blatt, gemischt: &g)
        XCTAssertEqual(s.anzahl, 52)
        let k = s.ziehen()!
        s.ablegen(k)
        XCTAssertEqual(s.oben, k)
        XCTAssertEqual(SkatKarte(.herz, 14).kurz, "A♥")
        XCTAssertEqual(SkatKarte(.herz, 12).sprechname, "Herz Dame")
        XCTAssertEqual(SkatKarte(.pik, 10).rang, "10")
    }
    func testAblageWirdNeuGemischt() {
        var s = Kartenstapel([1, 2, 3])
        var g = SystemRandomNumberGenerator()
        for _ in 0..<3 { s.ablegen(s.ziehen(mit: &g)!) }
        XCTAssertEqual(s.anzahl, 0)
        XCTAssertNotNil(s.ziehen(mit: &g))
        XCTAssertEqual(s.anzahl, 1)
    }
    func testLetzteRundeSpeichern() {
        let d = UserDefaults(suiteName: "test.letzteRunde")!
        d.removePersistentDomain(forName: "test.letzteRunde")
        XCTAssertNil(LetzteRunde.laden("yacht", defaults: d))
        let l = LetzteRunde(plaetze: [.init(name: "Anna", computer: false), .init(name: "Computer", computer: true)])
        l.speichern("yacht", defaults: d)
        XCTAssertEqual(LetzteRunde.laden("yacht", defaults: d), l)
        XCTAssertEqual(l.kurz, "Anna, Computer")
    }
}

final class SpielStandTests: XCTestCase {
    func testSichernLadenLoeschen() {
        let d = UserDefaults(suiteName: "test.spielstand")!
        d.removePersistentDomain(forName: "test.spielstand")
        XCTAssertFalse(SpielStand.vorhanden("x", defaults: d))
        SpielStand.sichern([1, 2, 3], spiel: "x", defaults: d)
        XCTAssertTrue(SpielStand.vorhanden("x", defaults: d))
        XCTAssertEqual(SpielStand.laden([Int].self, spiel: "x", defaults: d), [1, 2, 3])
        XCTAssertTrue(OffenesSpiel.alle(defaults: d).contains("x"))
        SpielStand.loeschen("x", defaults: d)
        XCTAssertNil(SpielStand.laden([Int].self, spiel: "x", defaults: d))
        XCTAssertFalse(OffenesSpiel.alle(defaults: d).contains("x"))
    }

    /// T-025: „Weiterspielen“ von der Startseite gilt für genau ein Spiel und genau einmal.
    @MainActor func testDirektWunschGiltEinmalUndNurFuerDasGemerkteSpiel() {
        OffenesSpiel.direktWunsch = nil
        XCTAssertFalse(OffenesSpiel.direktEinloesen("maumau-neu"))
        OffenesSpiel.direktMerken("maumau-neu")
        XCTAssertFalse(OffenesSpiel.direktEinloesen("solitaer-neu"), "anderes Spiel löst den Wunsch nicht ein")
        XCTAssertTrue(OffenesSpiel.direktEinloesen("maumau-neu"))
        XCTAssertFalse(OffenesSpiel.direktEinloesen("maumau-neu"), "nur einmal")
    }
}

final class EchteWuerfelTests: XCTestCase {
    func testAugenKommenAlsGetippt() {
        var g = EchteWuerfelZufall()
        let eingabe = [1, 6, 3, 3, 5, 2, 4, 6, 1]
        g.lade(augen: eingabe)
        let erhalten = eingabe.map { _ in Int.random(in: 1...6, using: &g) }
        XCTAssertEqual(erhalten, eingabe)
        XCTAssertEqual(g.offen, 0)
        _ = Int.random(in: 1...6, using: &g)   // danach echter Zufall, kein Absturz
    }
}

/// KI-9: Die Ansage füllt nur leere Felder (Philipp 13.11. 11:56).
final class AnsageFuellungTests: XCTestCase {
    func testFuelltNurDieLeerenPlaetzeDerReiheNach() {
        let f = AnsageFuellung(plaetze: [4, nil, nil, 2, nil])
        XCTAssertEqual(f.leer, [1, 2, 4])
        XCTAssertEqual(f.anzahl, 3)
        XCTAssertEqual(f.anwenden(augen: [3, 5, 1], auf: [4, nil, nil, 2, nil]), [4, 3, 5, 2, 1])
    }

    func testZuWenigAngesagtLaesstRestLeerUndNimmtEinenVerhoererZurueck() {
        let start: [Int?] = [nil, nil, nil]
        let f = AnsageFuellung(plaetze: start)
        let teil = f.anwenden(augen: [6, 2], auf: start)
        XCTAssertEqual(teil, [6, 2, nil])
        // Die Erkennung korrigiert sich während des Sprechens: Der Platz, der nicht mehr verstanden ist, wird wieder leer.
        XCTAssertEqual(f.anwenden(augen: [6], auf: teil), [6, nil, nil])
    }

    func testUngueltigeAugenUndZuvieleWerdenIgnoriert() {
        let f = AnsageFuellung(plaetze: [nil, nil])
        XCTAssertEqual(f.anwenden(augen: [3, 7, 1, 1], auf: [nil, nil]), [3, nil])
        XCTAssertEqual(f.anwenden(augen: [], auf: [nil, nil]), [nil, nil])
    }

    func testGefuellteBleibenUnberuehrtUndKeinLeererPlatzBedeutetNichts() {
        let voll: [Int?] = [1, 2, 3]
        let f = AnsageFuellung(plaetze: voll)
        XCTAssertEqual(f.anzahl, 0)
        XCTAssertEqual(f.anwenden(augen: [6, 6, 6], auf: voll), voll)
    }

    @MainActor func testOhneHakenIstDieAnsageNichtAngeboten() {
        WuerfelAnsageHaken.hoeren = nil; WuerfelAnsageHaken.verfuegbar = nil
        XCTAssertFalse(WuerfelAnsageHaken.angeboten)
        WuerfelAnsageHaken.hoeren = { _, _ in .beendet }
        XCTAssertFalse(WuerfelAnsageHaken.angeboten)          // ohne „verfügbar“ (z. B. Kinder-Modus) kein Knopf
        WuerfelAnsageHaken.verfuegbar = { true }
        XCTAssertTrue(WuerfelAnsageHaken.angeboten)
        WuerfelAnsageHaken.hoeren = nil; WuerfelAnsageHaken.verfuegbar = nil
    }

    @MainActor func testSteuerungFuelltLeerePlaetzeUndMeldetPruefHinweis() async {
        WuerfelAnsageHaken.verfuegbar = { true }
        WuerfelAnsageHaken.hoeren = { hoechstens, laufend in
            XCTAssertEqual(hoechstens, 2)
            laufend([5]); laufend([5, 3])
            return .beendet
        }
        defer { WuerfelAnsageHaken.hoeren = nil; WuerfelAnsageHaken.verfuegbar = nil }
        var plaetze: [Int?] = [6, nil, nil]
        let bindung = Binding(get: { plaetze }, set: { plaetze = $0 })
        let st = AnsageSteuerung()
        st.starten(plaetze: bindung)
        XCTAssertTrue(st.hoert)
        for _ in 0..<50 where st.hoert { try? await Task.sleep(for: .milliseconds(20)) }
        XCTAssertFalse(st.hoert)
        XCTAssertEqual(plaetze, [6, 5, 3])
        XCTAssertEqual(st.hinweis, AnsageSteuerung.hinweis(.beendet, verstanden: 2, erwartet: 2))
    }

    func testEingabeArtWirdGemerktUndVergessen() {
        let speicher = UserDefaults(suiteName: "test.eingabeart.\(UUID().uuidString)")!
        XCTAssertNil(WuerfelEingabeArt.gemerkt(in: speicher))
        WuerfelEingabeArt.merke(.ansage, in: speicher)
        XCTAssertEqual(WuerfelEingabeArt.gemerkt(in: speicher), .ansage)
        WuerfelEingabeArt.merke(.kamera, in: speicher)
        XCTAssertEqual(WuerfelEingabeArt.gemerkt(in: speicher), .kamera)
        speicher.set("unbekannt", forKey: WuerfelEingabeArt.schluessel)
        XCTAssertNil(WuerfelEingabeArt.gemerkt(in: speicher))
        WuerfelEingabeArt.merke(nil, in: speicher)
        XCTAssertNil(WuerfelEingabeArt.gemerkt(in: speicher))
    }

    func testHinweiseJeAusgang() {
        XCTAssertNotEqual(AnsageSteuerung.hinweis(.beendet, verstanden: 0, erwartet: 2), AnsageSteuerung.hinweis(.beendet, verstanden: 1, erwartet: 2))
        XCTAssertNotEqual(AnsageSteuerung.hinweis(.beendet, verstanden: 1, erwartet: 2), AnsageSteuerung.hinweis(.beendet, verstanden: 2, erwartet: 2))
        XCTAssertNotNil(AnsageSteuerung.hinweis(.verweigert, verstanden: 0, erwartet: 2))
        XCTAssertNotNil(AnsageSteuerung.hinweis(.nichtVerfuegbar, verstanden: 0, erwartet: 2))
    }
}

@MainActor
final class ArcadeRekordTests: XCTestCase {
    func testRekordIstHoechsteGemeldetePunktzahlDesSpiels() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        XCTAssertNil(s.rekord(spiel: "steinfall"))
        s.melden(.init(spiel: "steinfall", teilnehmer: [.init(name: "", platz: 0, punkte: 1200)]))
        s.melden(.init(spiel: "steinfall", teilnehmer: [.init(name: "", platz: 0, punkte: 800)]))
        s.melden(.init(spiel: "dauerlauf", teilnehmer: [.init(name: "", platz: 0, punkte: 5000)]))
        XCTAssertEqual(s.rekord(spiel: "steinfall"), 1200)
        XCTAssertEqual(s.rekord(spiel: "dauerlauf"), 5000)
        XCTAssertNil(s.rekord(spiel: "mauerbrecher"))
    }
    func testPunktespielZaehltAlsPartieAberNieAlsSieg() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        s.melden(.init(spiel: "steinfall", dauer: 30, teilnehmer: [.init(name: "", platz: 0, punkte: 500)]))
        let summe = s.summe(spiel: "steinfall")
        XCTAssertEqual(summe.partien, 1); XCTAssertEqual(summe.siege, 0)
    }
    func testRekordUeberlebtNeustartUndZuruecksetzen() {
        let ablage = SpeicherAblage()
        let a = StatistikDienst(ablage: ablage)
        a.melden(.init(spiel: "wolkenhuepfer", teilnehmer: [.init(name: "", platz: 0, punkte: 777)]))
        let b = StatistikDienst(ablage: ablage)
        XCTAssertEqual(b.rekord(spiel: "wolkenhuepfer"), 777)
        b.zuruecksetzen(); XCTAssertNil(b.rekord(spiel: "wolkenhuepfer"))
    }
    func testPunkteMeldungKommtBeiDerSenkeAn() async {
        let s = StatistikDienst(ablage: SpeicherAblage())
        PartieMeldung.senke = { s.melden($0) }
        PartieMeldung.punkte(spiel: "ballwechsel", punkte: 9)
        try? await Task.sleep(for: .milliseconds(100))
        PartieMeldung.senke = nil
        XCTAssertEqual(s.rekord(spiel: "ballwechsel"), 9)
    }

    // MARK: Spielerverwaltung: Fotos, Löschen, Migration, Namen

    func testFotoAusschnittGrossesQuerUndHochkantBild() {
        let quer = SpielerBilder.ausschnitt(breite: 4000, hoehe: 3000)
        XCTAssertEqual(quer?.ziel, SpielerBilder.kante)
        XCTAssertEqual(quer?.faktor ?? 0, SpielerBilder.kante / 3000, accuracy: 0.0001)
        let hoch = SpielerBilder.ausschnitt(breite: 3000, hoehe: 12000)
        XCTAssertEqual(hoch?.ziel, SpielerBilder.kante)
        XCTAssertEqual(hoch?.faktor ?? 0, SpielerBilder.kante / 3000, accuracy: 0.0001)
    }

    func testFotoKleinesBildWirdNichtHochgerechnetUndLeeresIstUngueltig() {
        let klein = SpielerBilder.ausschnitt(breite: 100, hoehe: 200)
        XCTAssertEqual(klein?.ziel, 100); XCTAssertEqual(klein?.faktor, 1)
        XCTAssertNil(SpielerBilder.ausschnitt(breite: 0, hoehe: 50))
        XCTAssertNil(SpielerBilder.ausschnitt(breite: 50, hoehe: -1))
    }

    func testNichtBildDatenWerdenAbgelehnt() {
        let id = UUID()
        XCTAssertFalse(SpielerBilder.sichern(Data("kein Bild".utf8), fuer: id))
        XCTAssertFalse(FileManager.default.fileExists(atPath: SpielerBilder.datei(id).path))
    }

    func testPersonMitFotoLoeschenEntferntDieDatei() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let a = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        let b = v.speichern(name: "Ben", avatar: "", farbeIndex: 1)!
        try? Data([1, 2, 3]).write(to: SpielerBilder.datei(a.id))
        XCTAssertTrue(FileManager.default.fileExists(atPath: SpielerBilder.datei(a.id).path))
        v.loeschen(a.id)
        XCTAssertFalse(FileManager.default.fileExists(atPath: SpielerBilder.datei(a.id).path))
        XCTAssertEqual(v.alle.map(\.name), ["Ben"]); XCTAssertEqual(v.ich?.id, b.id)
    }

    func testFotoEntfernenLoeschtDateiUndZaehler() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        var a = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        try? Data([1]).write(to: SpielerBilder.datei(a.id))
        a.bildNr = 1
        let s = v.speichern(id: a.id, name: "Anna", avatar: "", farbeIndex: 0, bild: .entfernen)
        XCTAssertNil(s?.bildNr)
        XCTAssertFalse(FileManager.default.fileExists(atPath: SpielerBilder.datei(a.id).path))
    }

    func testAlteSpielerdatenOhneFotoLassenSichLaden() throws {
        let alt = """
        [{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Anna","avatar":"A","farbeIndex":2,"art":"mensch","ich":true,
          "angelegt":700000000,"zuletzt":700000500}]
        """
        let v = SpielerVerzeichnis(ablage: SpeicherAblage(daten: Data(alt.utf8)))
        XCTAssertEqual(v.alle.count, 1)
        XCTAssertEqual(v.alle.first?.name, "Anna")
        XCTAssertNil(v.alle.first?.bildNr)
        XCTAssertEqual(v.ich?.name, "Anna")
        // Wieder speichern und laden: bleibt gleich
        v.alsIchMarkieren(v.alle[0].id)
        let ablage = SpeicherAblage(daten: try JSONEncoder().encode(v.alle))
        XCTAssertEqual(SpielerVerzeichnis(ablage: ablage).alle, v.alle)
    }

    func testDoppelteNamenWerdenBeimSpeichernAbgelehnt() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let a = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        XCTAssertNil(v.speichern(name: "  anna ", avatar: "", farbeIndex: 1))
        XCTAssertEqual(v.alle.count, 1)
        // Die eigene Person darf ihren Namen behalten (nur Farbe ändern)
        XCTAssertNotNil(v.speichern(id: a.id, name: "Anna", avatar: "", farbeIndex: 3))
        XCTAssertEqual(v.alle.first?.farbeIndex, 3)
        // Leerer Name
        XCTAssertNil(v.speichern(name: "   ", avatar: "", farbeIndex: 0))
        // Ein anderer Name geht
        XCTAssertNotNil(v.speichern(name: "Ben", avatar: "", farbeIndex: 1))
        XCTAssertNil(v.speichern(id: a.id, name: "ben", avatar: "", farbeIndex: 3))
    }

    // MARK: Spielende: Zuordnung zu Personen

    func testZuordnungLeererNameIstIchUndNamenWerdenGefunden() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        let ben = v.speichern(name: "Ben", avatar: "", farbeIndex: 1)!
        let e = v.zuordnen(PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "", platz: 2), .init(name: " ben ", platz: 1), .init(name: "Computer 1", platz: 3)]))
        XCTAssertEqual(e.teilnehmer[0].spielerID, anna.id)
        XCTAssertEqual(e.teilnehmer[1].spielerID, ben.id); XCTAssertEqual(e.teilnehmer[1].name, "Ben")
        XCTAssertNil(e.teilnehmer[2].spielerID)
    }

    func testZuordnungComputerBekommtKeinenMenschenUndEinMenschGegenComputerZaehlt() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        v.anlegen(name: "Computer 1", art: .computer)
        let e = v.zuordnen(PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "Anna", platz: 1), .init(name: "Computer 1", platz: 2), .init(name: "Computer 2", platz: 3)]))
        XCTAssertEqual(e.teilnehmer[0].spielerID, anna.id)
        XCTAssertNil(e.teilnehmer[1].spielerID); XCTAssertNil(e.teilnehmer[2].spielerID)
        let st = StatistikDienst(ablage: SpeicherAblage()); st.melden(e)
        XCTAssertEqual(st.summe(spieler: anna.id), StatistikSumme(partien: 1, siege: 1, dauer: 0))
        XCTAssertEqual(st.summe(ich: anna.id).siege, 1)
    }

    func testUmbenennenBehaeltSiegeUndLoeschenEntziehtNurDieserPerson() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        let ben = v.speichern(name: "Ben", avatar: "", farbeIndex: 1)!
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(v.zuordnen(PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "Anna", platz: 1), .init(name: "Ben", platz: 2)])))
        v.umbenennen(anna.id, zu: "Anni")
        XCTAssertEqual(st.summe(spieler: anna.id).siege, 1)
        v.loeschen(anna.id)
        XCTAssertEqual(st.summe(spieler: ben.id), StatistikSumme(partien: 1, siege: 0, dauer: 0))
        XCTAssertEqual(v.ich?.id, ben.id)
    }

    func testDoppeltGewaehltePersonZaehltEinmalMitBestemPlatz() {
        let id = UUID(), andere = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "x", teilnehmer: [.init(spielerID: andere, name: "Ben", platz: 2), .init(spielerID: id, name: "Anna", platz: 3), .init(spielerID: id, name: "anna", platz: 1)]))
        XCTAssertEqual(st.summe(spieler: id), StatistikSumme(partien: 1, siege: 1, dauer: 0))
        XCTAssertEqual(st.summe(spieler: andere), StatistikSumme(partien: 1, siege: 0, dauer: 0))
        XCTAssertEqual(st.summe(ich: id).siege, 1)
    }

    func testSerieZaehltSiegEinmalProPartie() {
        let a = UUID(), b = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "x", teilnehmer: [.init(spielerID: a, name: "A", platz: 1), .init(spielerID: a, name: "A", platz: 2), .init(spielerID: b, name: "B", platz: 3)]))
        let r = st.serie(zwischen: [a, b])
        XCTAssertEqual(r[0].1, 1); XCTAssertEqual(r[1].1, 0)
    }

    func testUmbenennenBehaeltGewaehltesZeichenUndLehntVergebeneNamenAb() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = v.speichern(name: "Anna", avatar: "🦊", farbeIndex: 0)!
        let ben = v.speichern(name: "Ben", avatar: "", farbeIndex: 1)!
        XCTAssertTrue(v.umbenennen(anna.id, zu: "Anni"))
        XCTAssertEqual(v.alle.first { $0.id == anna.id }?.avatar, "🦊")
        XCTAssertTrue(v.umbenennen(ben.id, zu: "Carl"))
        XCTAssertEqual(v.alle.first { $0.id == ben.id }?.avatar, "C")
        XCTAssertFalse(v.umbenennen(ben.id, zu: "anni"))
        XCTAssertFalse(v.umbenennen(ben.id, zu: "  "))
        XCTAssertEqual(v.alle.first { $0.id == ben.id }?.name, "Carl")
    }

    func testRemisZaehltAlsPartieAberNichtAlsSieg() {
        let a = UUID(), b = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "dame", teilnehmer: [.init(spielerID: a, name: "A", platz: 1), .init(spielerID: b, name: "B", platz: 1)]))
        XCTAssertTrue(st.ereignisse[0].istRemis)
        XCTAssertEqual(st.summe(spieler: a), StatistikSumme(partien: 1, siege: 0, dauer: 0))
        XCTAssertEqual(st.summe(spiel: "dame", ich: a), StatistikSumme(partien: 1, siege: 0, dauer: 0))
        XCTAssertEqual(st.serie(zwischen: [a, b]).map(\.1), [0, 0])
    }

    func testGleichaufVornNurEinigeBleibtSiegUndEinzelsiegIstKeinRemis() {
        let a = UUID(), b = UUID(), c = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "x", teilnehmer: [.init(spielerID: a, name: "A", platz: 1), .init(spielerID: b, name: "B", platz: 1), .init(spielerID: c, name: "C", platz: 3)]))
        XCTAssertEqual(st.summe(spieler: a).siege, 1); XCTAssertEqual(st.summe(spieler: b).siege, 1); XCTAssertEqual(st.summe(spieler: c).siege, 0)
        XCTAssertEqual(st.serie(zwischen: [a, b]).map(\.1), [1, 1])
        st.melden(PartieErgebnis(spiel: "solo", teilnehmer: [.init(spielerID: a, name: "A", platz: 1)]))
        XCTAssertFalse(st.ereignisse[1].istRemis)
        XCTAssertEqual(st.summe(spiel: "solo", spieler: a).siege, 1)
        XCTAssertEqual(st.summe(spiel: "solo").siege, 1)
    }

    func testAbbruchZaehltAlsNiederlageUndKeinMenschGewinnt() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        let ben = v.speichern(name: "Ben", avatar: "", farbeIndex: 1)!
        let st = StatistikDienst(ablage: SpeicherAblage())
        // Zwei Menschen, kein Computer: beide verlieren, kein Remis
        let e1 = PartieMeldung.abbruch(spiel: "dame", teilnehmer: [("Anna", false), ("Ben", false)])!
        XCTAssertFalse(v.zuordnen(e1).istRemis); st.melden(v.zuordnen(e1))
        XCTAssertEqual(st.summe(spieler: anna.id), StatistikSumme(partien: 1, siege: 0, dauer: 0))
        XCTAssertEqual(st.summe(spieler: ben.id), StatistikSumme(partien: 1, siege: 0, dauer: 0))
        // Mensch gegen Computer: der Computer steht vorn, der Mensch hat keinen Sieg
        let e2 = PartieMeldung.abbruch(spiel: "schach", teilnehmer: [("Anna", false), ("Computer", true)])!
        XCTAssertEqual(e2.teilnehmer.map(\.platz), [2, 1])
        st.melden(v.zuordnen(e2))
        XCTAssertEqual(st.summe(spieler: anna.id), StatistikSumme(partien: 2, siege: 0, dauer: 0))
        // Einzelspiel: ein Mensch allein verliert
        let e3 = PartieMeldung.abbruch(spiel: "mauerbrecher", teilnehmer: [("Anna", false)])!
        XCTAssertEqual(e3.teilnehmer.map(\.platz), [2]); XCTAssertFalse(e3.istRemis)
        // Ohne Menschen wird nichts gemeldet
        XCTAssertNil(PartieMeldung.abbruch(spiel: "x", teilnehmer: [("Computer", true)]))
    }

    func testNiederlageBeimBeendenNurMitAusdruecklicherZugMeldung() {
        XCTAssertFalse(SpielZug.hatZug("dame-test"))
        SpielZug.gemacht("dame-test")
        XCTAssertTrue(SpielZug.hatZug("dame-test"))
        XCTAssertFalse(SpielZug.hatZug("schach-test"))
        SpielZug.zuruecksetzen("dame-test")
        XCTAssertFalse(SpielZug.hatZug("dame-test"))
    }

    // MARK: StatistikDienst: alles zusammen, alte Daten

    func testAlteStatistikdatenLadenUndNeuesWirdDazugespeichert() throws {
        let alt = """
        [{"id":"11111111-1111-1111-1111-111111111111","spiel":"yacht","datum":700000000,"dauer":300,"kennzahlen":{},
          "teilnehmer":[{"spielerID":"6F9619FF-8B86-D011-B42D-00C04FC964FF","name":"Anna","platz":1,"punkte":210},{"name":"Ben","platz":2}]},
         {"id":"22222222-2222-2222-2222-222222222222","spiel":"sudoku","datum":700000100,"dauer":600,"kennzahlen":{"fehler":2},
          "teilnehmer":[{"name":"","platz":1}]}]
        """
        let ablage = SpeicherAblage(daten: Data(alt.utf8))
        let st = StatistikDienst(ablage: ablage)
        XCTAssertEqual(st.ereignisse.count, 2)
        let anna = UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF")!
        XCTAssertEqual(st.summe(spieler: anna), StatistikSumme(partien: 1, siege: 1, dauer: 300))
        XCTAssertEqual(st.rekord(spiel: "yacht"), 210)
        XCTAssertEqual(st.summe(spiel: "sudoku").siege, 1)         // Einzelspiel ohne „ich“
        st.melden(PartieErgebnis(spiel: "yacht", teilnehmer: [.init(spielerID: anna, name: "Anna", platz: 2)]))
        let neu = StatistikDienst(ablage: ablage)
        XCTAssertEqual(neu.ereignisse.count, 3)
        XCTAssertEqual(neu.summe(spieler: anna), StatistikSumme(partien: 2, siege: 1, dauer: 300))
    }

    func testKaputteStatistikdatenStuerzenNichtAb() {
        let ablage = SpeicherAblage(daten: Data("{kaputt".utf8))
        let st = StatistikDienst(ablage: ablage)
        XCTAssertTrue(st.ereignisse.isEmpty)
        st.melden(PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "A", platz: 1)]))
        XCTAssertEqual(StatistikDienst(ablage: ablage).ereignisse.count, 1)
    }

    func testMeldenIstEinmaligProIDUndZuruecksetzenLeert() {
        let ablage = SpeicherAblage()
        let st = StatistikDienst(ablage: ablage)
        let e = PartieErgebnis(spiel: "x", teilnehmer: [.init(name: "A", platz: 1)])
        st.melden(e); st.melden(e)
        XCTAssertEqual(st.ereignisse.count, 1)
        st.zuruecksetzen()
        XCTAssertTrue(StatistikDienst(ablage: ablage).ereignisse.isEmpty)
    }

    func testEinSpielabendAllesZusammen() {
        let v = SpielerVerzeichnis(ablage: SpeicherAblage())
        let anna = v.speichern(name: "Anna", avatar: "", farbeIndex: 0)!
        let ben = v.speichern(name: "Ben", avatar: "", farbeIndex: 1)!
        let st = StatistikDienst(ablage: SpeicherAblage())
        func buche(_ spiel: String, _ t: [PartieErgebnis.Teilnehmer]) { st.melden(v.zuordnen(PartieErgebnis(spiel: spiel, teilnehmer: t))) }
        buche("dame", [.init(name: "Anna", platz: 1), .init(name: "Ben", platz: 2)])                       // Anna gewinnt
        buche("dame", [.init(name: "anna", platz: 1), .init(name: " BEN", platz: 1)])                      // Remis
        buche("maumau", [.init(name: "Ben", platz: 1), .init(name: "Anna", platz: 2), .init(name: "Computer", platz: 3)]) // Ben gewinnt
        buche("yacht", [.init(name: "Ben", platz: 1), .init(name: "Anna", platz: 1), .init(name: "Computer", platz: 3)]) // beide vorn
        buche("sudoku", [.init(name: "", platz: 1)])                                                       // Einzelspiel: Anna ist „Ich“
        buche("schach", [.init(name: "Anna", platz: 2), .init(name: "Ben", platz: 2)])                     // Abbruch: beide verloren
        XCTAssertEqual(st.summe(spieler: anna.id), StatistikSumme(partien: 6, siege: 3, dauer: 0))   // dame, yacht, sudoku
        XCTAssertEqual(st.summe(spieler: ben.id), StatistikSumme(partien: 5, siege: 2, dauer: 0))    // maumau, yacht
        XCTAssertEqual(st.summe(spiel: "dame", spieler: anna.id).siege, 1)
        XCTAssertEqual(st.summe(spiel: "dame", spieler: ben.id).siege, 0)
        XCTAssertEqual(st.summe(ich: anna.id).partien, 6)
        // Serie Anna–Ben über alle gemeinsamen Partien (ohne Remis, ohne Einzelspiel)
        let serie = st.serie(zwischen: [anna.id, ben.id])
        XCTAssertEqual(serie[0].1, 2)   // dame, yacht
        XCTAssertEqual(serie[1].1, 2)   // maumau, yacht
        XCTAssertTrue(st.csv().contains("anna") == false)   // CSV hat die Anzeigenamen aus dem Verzeichnis
        XCTAssertTrue(st.csv().contains("Anna"))
    }
}

final class SpielStandVerlassenTests: XCTestCase {
    private func defaults() -> UserDefaults { let d = UserDefaults(suiteName: "test.verlassen.\(UUID().uuidString)")!; return d }

    func testWegwischenSichertLaufendePartie() {
        let d = defaults(); SpielStand.verworfen.remove("t1")
        XCTAssertTrue(SpielStand.sichernBeimVerlassen([1, 2, 3], spiel: "t1", laeuft: true, defaults: d))
        XCTAssertEqual(SpielStand.laden([Int].self, spiel: "t1", defaults: d), [1, 2, 3])
        XCTAssertTrue(OffenesSpiel.alle(defaults: d).contains("t1"))
    }
    func testBewusstBeendetWirdNichtGesichert() {
        let d = defaults(); SpielStand.verworfen.insert("t2"); defer { SpielStand.verworfen.remove("t2") }
        XCTAssertFalse(SpielStand.sichernBeimVerlassen([1], spiel: "t2", laeuft: true, defaults: d))
        XCTAssertFalse(SpielStand.vorhanden("t2", defaults: d))
    }
    func testNichtLaufendeOderBeendetePartieWirdNichtGesichert() {
        let d = defaults(); SpielStand.verworfen.remove("t3")
        XCTAssertFalse(SpielStand.sichernBeimVerlassen([1], spiel: "t3", laeuft: false, defaults: d))
        XCTAssertFalse(SpielStand.vorhanden("t3", defaults: d))
    }
    func testNeuePartieHebtDasVerwerfenAufDurchEntfernen() {
        let d = defaults(); SpielStand.verworfen.insert("t4")
        SpielStand.verworfen.remove("t4")
        XCTAssertTrue(SpielStand.sichernBeimVerlassen([9], spiel: "t4", laeuft: true, defaults: d))
    }
}

@MainActor
final class SpielStatistikTests: XCTestCase {
    func testAusgaengeSerienUndLetztePartien() {
        let a = UUID(), b = UUID()
        let st = StatistikDienst(ablage: SpeicherAblage())
        var tag = Date(timeIntervalSince1970: 1_000_000)
        func melde(_ pa: Int, _ pb: Int, dauer: TimeInterval = 60, spiel: String = "dame") {
            tag += 3600
            st.melden(PartieErgebnis(spiel: spiel, datum: tag, dauer: dauer, teilnehmer: [.init(spielerID: a, name: "A", platz: pa), .init(spielerID: b, name: "B", platz: pb)]))
        }
        melde(1, 2); melde(1, 2); melde(1, 1); melde(2, 1, dauer: 120); melde(1, 2, spiel: "schach")
        let s = st.spielStatistik(spiel: "dame", ich: a, letzte: 2)
        XCTAssertEqual([s.partien, s.siege, s.niederlagen, s.remis], [4, 2, 1, 1])
        XCTAssertEqual(s.siegquote, 0.5, accuracy: 0.001)
        XCTAssertEqual(s.serie, 0); XCTAssertEqual(s.besteSerie, 2)
        XCTAssertEqual(s.dauer, 300); XCTAssertEqual(s.dauerSchnitt, 75)
        XCTAssertEqual(s.letzte.count, 2); XCTAssertEqual(s.letzte.first?.datum, s.letzteDatum)
        let sb = st.spielStatistik(spiel: "dame", ich: b)
        XCTAssertEqual([sb.siege, sb.niederlagen, sb.remis], [1, 2, 1])
    }

    func testMehrspielerOhneIchIstNieEinSieg() {
        let st = StatistikDienst(ablage: SpeicherAblage())
        st.melden(PartieErgebnis(spiel: "dame", teilnehmer: [.init(name: "A", platz: 1), .init(name: "B", platz: 2)]))
        st.melden(PartieErgebnis(spiel: "dame", teilnehmer: [.init(name: "", platz: 1)]))
        XCTAssertEqual(st.summe(spiel: "dame"), StatistikSumme(partien: 2, siege: 1, dauer: 0))   // H3: nur die Einzelpartie
        let s = st.spielStatistik(spiel: "dame")
        XCTAssertEqual([s.partien, s.siege, s.niederlagen], [2, 1, 1])
    }

    func testPunktespielOhneWertungIstKeinSiegKeineNiederlage() {
        let st = StatistikDienst(ablage: SpeicherAblage())
        PartieMeldung.senke = { st.melden($0) }
        defer { PartieMeldung.senke = nil }
        st.melden(PartieErgebnis(spiel: "lauf", teilnehmer: [.init(name: "", platz: 0, punkte: 10)]))
        st.melden(PartieErgebnis(spiel: "lauf", teilnehmer: [.init(name: "", platz: 0, punkte: 31)], kennzahlen: ["rallye": 7]))
        let s = st.spielStatistik(spiel: "lauf")
        XCTAssertTrue(s.istPunktespiel)
        XCTAssertEqual([s.partien, s.siege, s.niederlagen, s.ohneWertung], [2, 0, 0, 2])
        XCTAssertEqual(s.rekord, 31); XCTAssertEqual(s.durchschnittPunkte, 21); XCTAssertEqual(s.rallye, 7)
    }

    /// Bilanz je Stufe: Partien, Siege, beste Serie und Bestzeit je gemeldeter Stufe; Tagesrätsel zählen eigens, Partien ohne Stufe nirgends.
    func testBilanzJeStufeUndTagesraetsel() {
        let st = StatistikDienst(ablage: SpeicherAblage()); let a = UUID()
        var tag = Date(timeIntervalSince1970: 2_000_000)
        func melde(_ platz: Int, dauer: TimeInterval, _ k: [String: Double], ich: Bool = true) {
            tag += 60
            st.melden(PartieErgebnis(spiel: "minen", datum: tag, dauer: dauer, teilnehmer: [.init(spielerID: ich ? a : nil, name: "A", platz: platz)], kennzahlen: k))
        }
        melde(1, dauer: 90, ["stufe": 0]); melde(1, dauer: 50, ["stufe": 0]); melde(2, dauer: 10, ["stufe": 0]); melde(1, dauer: 70, ["stufe": 0])
        melde(2, dauer: 300, ["stufe": 2])
        melde(1, dauer: 40, ["stufe": 1], ich: false)          // vor dem Profil gespielt: zählt für „Ich“ als Sieg
        melde(1, dauer: 20, ["tages": 1]); melde(2, dauer: 20, ["tages": 1]); melde(1, dauer: 5, [:])
        let s = st.spielStatistik(spiel: "minen", ich: a)
        XCTAssertEqual(s.stufen.map(\.stufe), [0, 1, 2])
        XCTAssertEqual(s.stufen[0], StufenBilanz(stufe: 0, partien: 4, siege: 3, serie: 1, besteSerie: 2, besteZeit: 50))
        XCTAssertEqual(s.stufen[1], StufenBilanz(stufe: 1, partien: 1, siege: 1, serie: 1, besteSerie: 1, besteZeit: 40))
        XCTAssertEqual(s.stufen[2], StufenBilanz(stufe: 2, partien: 1, siege: 0, serie: 0, besteSerie: 0, besteZeit: nil))
        XCTAssertEqual(s.tagesGeloest, 1)
        XCTAssertEqual([s.partien, s.siege, s.niederlagen], [9, 6, 3])   // Siege und Niederlagen ergeben zusammen die Partien
        XCTAssertTrue(st.spielStatistik(spiel: "dame", ich: a).stufen.isEmpty)
    }

    func testAbbruchZaehltAlsNiederlageUndLeeresSpielIstNull() {
        let st = StatistikDienst(ablage: SpeicherAblage()); let a = UUID()
        st.melden(PartieErgebnis(spiel: "dame", teilnehmer: [.init(spielerID: a, name: "A", platz: 2), .init(name: "Computer", platz: 1)]))
        XCTAssertEqual(st.spielStatistik(spiel: "dame", ich: a).niederlagen, 1)
        XCTAssertEqual(st.spielStatistik(spiel: "leer", ich: a), SpielStatistik())
    }
}
