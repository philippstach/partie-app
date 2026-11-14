// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import XCTest
import SpieleKern
@testable import Partie

private final class SpeicherAblage: SpielAblageProtokoll {
    var daten: Data?
    func lesen() -> Data? { daten }
    func schreiben(_ d: Data?) throws { daten = d }
}

private final class FalscheZentrale: MitteilungsZentrale {
    var aktuell: MitteilungsStatus
    let antwort: Bool
    private(set) var anfragen_Zaehler = 0
    init(_ s: MitteilungsStatus, antwort: Bool = true) { aktuell = s; self.antwort = antwort }
    func status() async -> MitteilungsStatus { aktuell }
    func anfragen() async -> Bool { anfragen_Zaehler += 1; aktuell = antwort ? .erlaubt : .abgelehnt; return antwort }
}

@MainActor
final class RahmenTests: XCTestCase {
    private let schluessel = [Entwickler.key, Modi.kinderKey, Modi.ruheKey, Modi.gesperrtKey, Modi.tagesaufgabeKey, "startLayout"]

    override func setUp() { super.setUp(); schluessel.forEach { UserDefaults.standard.removeObject(forKey: $0) } }
    override func tearDown() { schluessel.forEach { UserDefaults.standard.removeObject(forKey: $0) }; super.tearDown() }

    // MARK: 26 Startspiele (10.11.2026)

    func testNormalNurDie26Startspiele() {
        let ids = SpielKatalog.spielbar.map(\.id)
        XCTAssertEqual(ids.count, 26)
        XCTAssertEqual(Set(ids).count, 26)
        XCTAssertTrue(ids.contains("wortpfeil"))
        XCTAssertEqual(SpielKatalog.modul("wortpfeil")?.name, "Kreuzworträtsel")
        for neu in ["yacht-neu", "schocken-neu", "10k-neu", "sudoku-neu", "galgenmaennchen-neu"] { XCTAssertTrue(ids.contains(neu), neu) }
        for alt in ["yacht", "schocken", "10k", "sudoku", "galgenmaennchen"] { XCTAssertFalse(ids.contains(alt), alt) }
        XCTAssertTrue(SpielKatalog.spielbar.allSatisfy { $0.gattung != .arcade })
    }

    func testEntwicklermodusZeigtAlleSpiele() {
        UserDefaults.standard.set(true, forKey: Entwickler.key)
        XCTAssertEqual(SpielKatalog.spielbar.count, SpielKatalog.alleModule.count)
        XCTAssertGreaterThan(SpielKatalog.spielbar.count, 26)
        XCTAssertTrue(SpielKatalog.spielbar.contains { $0.id == SpielKatalog.kennung("yacht") })   // alte Kennung → heutige Speicherkennung (yacht-neu)
    }

    // MARK: Kinder-Modus

    func testKinderAusZeigtAlleSpiele() {
        XCTAssertEqual(SpielKatalog.sichtbar.count, SpielKatalog.spielbar.count)
    }

    func testKinderModusBlendetVoreingestellteSpieleAus() {
        UserDefaults.standard.set(true, forKey: Modi.kinderKey)
        let ids = Set(SpielKatalog.sichtbar.map(\.id))
        for id in Modi.standardGesperrt where SpielKatalog.modul(id) != nil { XCTAssertFalse(ids.contains(id), id) }
        XCTAssertFalse(ids.isEmpty)
    }

    func testEigeneAuswahlUeberschreibtVoreinstellung() {
        UserDefaults.standard.set(true, forKey: Modi.kinderKey)
        Modi.setzeGesperrt(["yacht"])
        let ids = Set(SpielKatalog.sichtbar.map(\.id))
        XCTAssertFalse(ids.contains("yacht"))
        XCTAssertTrue(ids.contains("pokerwurf") || SpielKatalog.modul("pokerwurf") == nil)
        XCTAssertEqual(Modi.gesperrt, [SpielKatalog.kennung("yacht")])   // gesperrt wird unter der heutigen Speicherkennung geführt
    }

    func testLeereAuswahlSperrtNichts() {
        UserDefaults.standard.set(true, forKey: Modi.kinderKey)
        Modi.setzeGesperrt([])
        XCTAssertEqual(SpielKatalog.sichtbar.count, SpielKatalog.spielbar.count)
    }

    // MARK: Ruhe-Modus

    func testRuheModusSchalter() {
        XCTAssertFalse(Modi.ruhe)
        UserDefaults.standard.set(true, forKey: Modi.ruheKey)
        XCTAssertTrue(Modi.ruhe)
    }

    // MARK: Tagesaufgabe

    private func partie(_ id: String, am tag: Date) -> PartieErgebnis {
        PartieErgebnis(spiel: id, datum: tag, teilnehmer: [.init(name: "", platz: 1)])
    }
    private func tag(_ versatz: Int, von basis: Date) -> Date { Calendar.current.date(byAdding: .day, value: versatz, to: basis)! }

    func testTagesaufgabeSichtbarkeit() {
        XCTAssertTrue(Tagesaufgabe.sichtbar(ruhe: false, kinder: false))
        XCTAssertTrue(Tagesaufgabe.sichtbar(ruhe: false, kinder: false, an: true))
        XCTAssertFalse(Tagesaufgabe.sichtbar(ruhe: false, kinder: false, an: false), "eigener Schalter")
        XCTAssertFalse(Tagesaufgabe.sichtbar(ruhe: true, kinder: false, an: true), "Ruhe-Modus")
        XCTAssertFalse(Tagesaufgabe.sichtbar(ruhe: false, kinder: true, an: true), "Kinder-Modus")
        XCTAssertFalse(Tagesaufgabe.sichtbar(ruhe: true, kinder: true, an: false))
    }

    func testTagesaufgabeSchalterStandardAn() {
        UserDefaults.standard.removeObject(forKey: Modi.tagesaufgabeKey)
        XCTAssertTrue(UserDefaults.standard.object(forKey: Modi.tagesaufgabeKey) == nil)
        UserDefaults.standard.set(false, forKey: Modi.tagesaufgabeKey)
        XCTAssertFalse(UserDefaults.standard.bool(forKey: Modi.tagesaufgabeKey))
        UserDefaults.standard.removeObject(forKey: Modi.tagesaufgabeKey)
    }

    func testSpielDesTagesIstStabilUndWechselt() {
        let heute = Date()
        XCTAssertNotNil(Tagesaufgabe.spiel(am: heute))
        XCTAssertEqual(Tagesaufgabe.spiel(am: heute)?.id, Tagesaufgabe.spiel(am: Calendar.current.startOfDay(for: heute))?.id)
        let ids = Set((0..<14).compactMap { Tagesaufgabe.spiel(am: tag($0, von: heute))?.id })
        XCTAssertGreaterThan(ids.count, 3)
    }

    func testTageswechselMacheAufgabeNeuOffen() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        let heute = Date(), morgen = tag(1, von: heute)
        let id = Tagesaufgabe.spiel(am: heute)!.id
        XCTAssertFalse(Tagesaufgabe.geschafft(am: heute, s))
        s.melden(partie(id, am: heute))
        XCTAssertTrue(Tagesaufgabe.geschafft(am: heute, s))
        XCTAssertFalse(Tagesaufgabe.geschafft(am: morgen, s))
    }

    func testAnderesSpielZaehltNicht() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        let heute = Date()
        let anderes = SpielKatalog.spielbar.first { $0.id != Tagesaufgabe.spiel(am: heute)!.id }!.id
        s.melden(partie(anderes, am: heute))
        XCTAssertFalse(Tagesaufgabe.geschafft(am: heute, s))
    }

    func testSerieZaehltAufeinanderfolgendeTage() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        let heute = Date()
        for v in [0, -1, -2] { s.melden(partie(Tagesaufgabe.spiel(am: tag(v, von: heute))!.id, am: tag(v, von: heute))) }
        XCTAssertEqual(Tagesaufgabe.serie(s, heute: heute), 3)
    }

    func testSerieBrichtBeiLuecke() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        let heute = Date()
        for v in [0, -2] { s.melden(partie(Tagesaufgabe.spiel(am: tag(v, von: heute))!.id, am: tag(v, von: heute))) }
        XCTAssertEqual(Tagesaufgabe.serie(s, heute: heute), 1)
    }

    func testOffeneAufgabeHeuteBrichtSerieNicht() {
        let s = StatistikDienst(ablage: SpeicherAblage())
        let heute = Date()
        for v in [-1, -2] { s.melden(partie(Tagesaufgabe.spiel(am: tag(v, von: heute))!.id, am: tag(v, von: heute))) }
        XCTAssertEqual(Tagesaufgabe.serie(s, heute: heute), 2)
    }

    func testOhneAufgabenKeineSerie() {
        XCTAssertEqual(Tagesaufgabe.serie(StatistikDienst(ablage: SpeicherAblage())), 0)
    }

    // MARK: Startseiten-Anordnung

    func testStartLayoutVorgabe() {
        let l = StartLayout()
        XCTAssertFalse(l.ids.isEmpty)
        XCTAssertTrue(l.ids.allSatisfy { id in SpielKatalog.modul(id) != nil })
    }

    func testStartLayoutSpeichertAnordnung() {
        let l = StartLayout()
        let a = l.ids[0], b = l.ids[1], c = l.ids[2]
        l.verschieben(c, vor: a)
        XCTAssertEqual(Array(l.ids.prefix(3)), [c, a, b])
        let neu = StartLayout()
        XCTAssertEqual(neu.ids, l.ids)
    }

    func testStartLayoutHinzufuegenEntfernen() {
        let l = StartLayout()
        let n = l.ids.count
        let weg = l.ids[0]
        l.entfernen(weg)
        XCTAssertEqual(StartLayout().ids.count, n - 1)
        l.hinzufuegen(weg); l.hinzufuegen(weg)
        XCTAssertEqual(StartLayout().ids.count, n)
        XCTAssertEqual(StartLayout().ids.last, weg)
    }

    func testStartLayoutLeerBleibtLeer() {
        let l = StartLayout()
        l.ids.forEach { l.entfernen($0) }
        XCTAssertTrue(StartLayout().ids.isEmpty)
    }

    // MARK: Mitteilungen

    func testFragtEinmalUndMerktSichDieAntwort() async {
        let z = FalscheZentrale(.offen)
        let erst = await Mitteilungen.fragen(ruhe: false, zentrale: z)
        let zweit = await Mitteilungen.fragen(ruhe: false, zentrale: z)
        XCTAssertEqual(erst, .erlaubt)
        XCTAssertEqual(zweit, .erlaubt)
        XCTAssertEqual(z.anfragen_Zaehler, 1)
    }

    func testNeinWirdRespektiertUndNichtNochmalGefragt() async {
        let z = FalscheZentrale(.offen, antwort: false)
        let erst = await Mitteilungen.fragen(ruhe: false, zentrale: z)
        let zweit = await Mitteilungen.fragen(ruhe: false, zentrale: z)
        XCTAssertEqual(erst, .abgelehnt)
        XCTAssertEqual(zweit, .abgelehnt)
        XCTAssertEqual(z.anfragen_Zaehler, 1)
    }

    func testImRuheModusWirdNichtGefragt() async {
        let z = FalscheZentrale(.offen)
        let r = await Mitteilungen.fragen(ruhe: true, zentrale: z)
        XCTAssertEqual(r, .offen)
        XCTAssertEqual(z.anfragen_Zaehler, 0)
    }

    func testBereitsErlaubtOderAbgelehntFragtNie() async {
        for status in [MitteilungsStatus.erlaubt, .abgelehnt] {
            let z = FalscheZentrale(status)
            let r = await Mitteilungen.fragen(ruhe: false, zentrale: z)
            XCTAssertEqual(r, status)
            XCTAssertEqual(z.anfragen_Zaehler, 0)
        }
    }

    // MARK: Randwisch

    private func wisch(_ x: CGFloat, dx: CGFloat, dy: CGFloat = 0, breite: CGFloat = 400, offen: Bool, erlaubt: Bool = true) -> Randwisch.Aktion? {
        Randwisch.aktion(start: CGPoint(x: x, y: 300), bewegung: CGSize(width: dx, height: dy), breite: breite, spielOffen: offen, letztesErlaubt: erlaubt)
    }

    func testLinkerRandwischFuehrtAusDemSpielZurStartseite() {
        XCTAssertEqual(wisch(10, dx: 120, offen: true), .zurueckZurStartseite)
    }

    func testRechterRandwischOeffnetLetztesSpiel() {
        XCTAssertEqual(wisch(390, dx: -120, offen: false), .letztesSpiel)
    }

    func testRandwischNurAmRand() {
        XCTAssertNil(wisch(100, dx: 150, offen: true))
        XCTAssertNil(wisch(200, dx: -150, offen: false))
    }

    func testRandwischBrauchtGenugWeg() {
        XCTAssertNil(wisch(10, dx: 60, offen: true))
        XCTAssertNil(wisch(390, dx: -60, offen: false))
    }

    func testRandwischIgnoriertDiagonaleBewegung() {
        XCTAssertNil(wisch(10, dx: 150, dy: 80, offen: true))
    }

    func testRandwischRichtungMussPassen() {
        XCTAssertNil(wisch(10, dx: -150, offen: true))
        XCTAssertNil(wisch(390, dx: 150, offen: false))
    }

    func testRandwischRechtsNichtMitGesperrtemLetztenSpiel() {
        XCTAssertNil(wisch(390, dx: -120, offen: false, erlaubt: false))
    }

    func testRandwischRechterRandFolgtDerFensterbreite() {
        // iPad im schmalen Fenster: Rand liegt bei 320 statt am Bildschirmrand
        XCTAssertEqual(wisch(315, dx: -120, breite: 320, offen: false), .letztesSpiel)
        XCTAssertNil(wisch(315, dx: -120, breite: 1024, offen: false))
    }

    // MARK: Einführung und „Was ist neu?“

    func testEinfuehrungErsterStartUndNachUpdate() {
        XCTAssertTrue(Einfuehrung.zeigen(gespeichert: "", aktuell: "1.1"))
        XCTAssertTrue(Einfuehrung.zeigen(gespeichert: "1.0", aktuell: "1.1"))
        XCTAssertFalse(Einfuehrung.zeigen(gespeichert: "1.1", aktuell: "1.1"))
    }

    func testWillkommenOderWasIstNeu() {
        XCTAssertFalse(Einfuehrung.istUpdate(gespeichert: "", hatSpieler: false))   // ganz neu: Willkommen
        XCTAssertTrue(Einfuehrung.istUpdate(gespeichert: "1.0", hatSpieler: false)) // nach Update
        XCTAssertTrue(Einfuehrung.istUpdate(gespeichert: "", hatSpieler: true))     // Update von Version ohne Einführung
    }

    // MARK: Tagesaufgabe sichtbar

    func testTagesaufgabeNurOhneRuheUndKinderModus() {
        XCTAssertTrue(Tagesaufgabe.sichtbar(ruhe: false, kinder: false))
        XCTAssertFalse(Tagesaufgabe.sichtbar(ruhe: true, kinder: false))
        XCTAssertFalse(Tagesaufgabe.sichtbar(ruhe: false, kinder: true))
        XCTAssertFalse(Tagesaufgabe.sichtbar(ruhe: true, kinder: true))
    }

    // MARK: Kinder-Modus: weitere Wege zu Spielen

    func testSchnellaktionenOhneGesperrteSpiele() {
        let ids = ["yacht", "schocken", "sudoku"]
        XCTAssertEqual(FavoritenAktionen.erlaubteIDs(ids, kinder: true, gesperrt: ["schocken"]), ["yacht", "sudoku"])
        XCTAssertEqual(FavoritenAktionen.erlaubteIDs(ids, kinder: false, gesperrt: ["schocken"]), ids)
    }

    func testTagesraetselLinkWaehltNurErlaubteSpiele() {
        let nur = TagesSpielInfo.alle.first!.id
        XCTAssertEqual(WidgetAbgleich.naechstesTagesraetsel(erlaubt: { $0 == nur }), nur)
        XCTAssertNil(WidgetAbgleich.naechstesTagesraetsel(erlaubt: { _ in false }))
    }

    // MARK: Widgets und Siri im Kinder-Modus

    func testWidgetZuletztBlendetGesperrtesSpielAus() {
        let z = PartieGeteilt.Zuletzt(id: "schocken", name: "Schocken", farbeHex: 0, datum: .now)
        XCTAssertNil(PartieGeteilt.sichtbar(z, gesperrt: ["schocken"]))
        XCTAssertEqual(PartieGeteilt.sichtbar(z, gesperrt: ["yacht"]), z)
        XCTAssertNil(PartieGeteilt.sichtbar(nil, gesperrt: []))
    }

    func testWidgetRekordeBlendenGesperrteSpieleAus() {
        let a = PartieGeteilt.Rekord(id: "schocken", name: "Schocken", farbeHex: 0, punkte: 5, datum: .now)
        let b = PartieGeteilt.Rekord(id: "yacht", name: "Yacht", farbeHex: 0, punkte: 300, datum: .now)
        XCTAssertEqual(PartieGeteilt.sichtbar([a, b], gesperrt: ["schocken"]), [b])
        XCTAssertEqual(PartieGeteilt.sichtbar([a, b], gesperrt: []).count, 2)
    }

    func testSiriSagtEhrlichWennDasSpielGesperrtIst() {
        XCTAssertThrowsError(try Modi.pruefeOeffnen("schocken", kinder: true, gesperrt: ["schocken"])) { fehler in
            XCTAssertTrue(fehler is KinderModusGesperrt)
        }
        XCTAssertNoThrow(try Modi.pruefeOeffnen("yacht", kinder: true, gesperrt: ["schocken"]))
        XCTAssertNoThrow(try Modi.pruefeOeffnen("schocken", kinder: false, gesperrt: ["schocken"]))
    }

    // MARK: KI-8 Siri und Spotlight

    func testNeuePartieWunschSagtEhrlichWasNichtGeht() {
        // Spiel mit Computer: nichts zu bemängeln
        var r = NeuePartieWunsch.pruefen(menschen: 1, computer: 1, spielerzahl: 2...2, computerErlaubt: true)
        XCTAssertEqual(r.wunsch, StartWunsch(menschen: 1, computer: 1)); XCTAssertNil(r.hinweis)
        // Spiel ohne Computer
        r = NeuePartieWunsch.pruefen(menschen: nil, computer: 1, spielerzahl: 2...4, computerErlaubt: false)
        XCTAssertEqual(r.wunsch, StartWunsch(menschen: nil, computer: 0)); XCTAssertEqual(r.hinweis, .keinComputer)
        // Einzelspiel
        r = NeuePartieWunsch.pruefen(menschen: 2, computer: nil, spielerzahl: 1...1, computerErlaubt: false)
        XCTAssertEqual(r.wunsch, StartWunsch()); XCTAssertEqual(r.hinweis, .einzelspiel)
        r = NeuePartieWunsch.pruefen(menschen: nil, computer: nil, spielerzahl: 1...1, computerErlaubt: false)
        XCTAssertNil(r.hinweis)
        // zu viele
        r = NeuePartieWunsch.pruefen(menschen: 5, computer: 2, spielerzahl: 2...4, computerErlaubt: true)
        XCTAssertEqual(r.hinweis, .gekuerzt)
        // nichts genannt: Vorgabe des Spiels
        r = NeuePartieWunsch.pruefen(menschen: nil, computer: nil, spielerzahl: 2...4, computerErlaubt: true)
        XCTAssertEqual(r.wunsch, StartWunsch()); XCTAssertNil(r.hinweis)
    }

    @MainActor func testComputerSpieleSindNurSpieleDerEinsPunktNull() {
        let grund = Set(Startauswahl.grundIDs.map(SpielKatalog.kennung))
        XCTAssertTrue(NeuePartieWunsch.computerSpiele.isSubset(of: grund))
        for id in NeuePartieWunsch.computerSpiele { XCTAssertNotNil(SpielKatalog.modul(id), id) }
    }

    @MainActor func testSpielSucheFindetUeberStichworteUndNamen() {
        let module = SpielKatalog.standardModule
        func ids(_ t: String) -> [String] { SpielSuchtext.treffer(t, in: module).map(\.id) }
        XCTAssertTrue(ids("vier gewinnt").contains("viererreihe-neu"))
        XCTAssertTrue(ids("kniffel").contains("yacht-neu"))
        XCTAssertEqual(ids("yac").first, "yacht-neu", "Name zuerst")
        XCTAssertEqual(ids("").count, module.count, "leere Suche zeigt alle")
        XCTAssertTrue(ids("zzzzqq").isEmpty)
    }

    @MainActor func testSpotlightBezeichnerOhneUndMitPraefix() {
        let bekannt: (String) -> Bool = { ["yacht-neu", "10k-neu"].contains($0) }
        XCTAssertEqual(SpielSpotlight.id(ausBezeichner: "yacht-neu", bekannt: bekannt), "yacht-neu")
        XCTAssertEqual(SpielSpotlight.id(ausBezeichner: "de.philippstach.partie.SpielEntitaet/10k-neu", bekannt: bekannt), "10k-neu")
        XCTAssertEqual(SpielSpotlight.id(ausBezeichner: "SpielEntitaet:yacht-neu", bekannt: bekannt), "yacht-neu")
        XCTAssertNil(SpielSpotlight.id(ausBezeichner: "unbekannt", bekannt: bekannt))
    }

    // MARK: Spotlight im Kinder-Modus

    func testSpotlightIndexOhneGesperrteSpieleImKinderModus() {
        let alle = ["yacht", "schocken", "sudoku"]
        XCTAssertEqual(SpielSpotlight.indexIDs(alle: alle, kinder: true, gesperrt: ["schocken"]), ["yacht", "sudoku"])
        XCTAssertEqual(SpielSpotlight.indexIDs(alle: alle, kinder: false, gesperrt: ["schocken"]), alle)
    }

    func testSpotlightStandAendertSichMitDerAuswahl() {
        let voll = SpielSpotlight.standSchluessel(version: "7", ids: ["a", "b", "c"], sprache: "de")
        let ohneB = SpielSpotlight.standSchluessel(version: "7", ids: ["a", "c"], sprache: "de")
        let andereZwei = SpielSpotlight.standSchluessel(version: "7", ids: ["a", "b"], sprache: "de")
        XCTAssertNotEqual(voll, ohneB)
        XCTAssertNotEqual(ohneB, andereZwei)                         // gleiche Anzahl, andere Spiele
        XCTAssertEqual(voll, SpielSpotlight.standSchluessel(version: "7", ids: ["c", "b", "a"], sprache: "de"))   // Reihenfolge egal
        XCTAssertNotEqual(voll, SpielSpotlight.standSchluessel(version: "8", ids: ["a", "b", "c"], sprache: "de"))
    }

    // MARK: Kinder-Modus beim Öffnen

    func testGesperrtesSpielOeffnetImKinderModusNicht() {
        XCTAssertFalse(Modi.erlaubt("schocken", kinder: true, gesperrt: ["schocken"]))
        XCTAssertTrue(Modi.erlaubt("yacht", kinder: true, gesperrt: ["schocken"]))
    }

    func testOhneKinderModusIstAllesErlaubt() {
        XCTAssertTrue(Modi.erlaubt("schocken", kinder: false, gesperrt: ["schocken"]))
    }

    func testErlaubtLiestStandardmaessigDieEinstellung() {
        UserDefaults.standard.set(true, forKey: Modi.kinderKey)
        Modi.setzeGesperrt(["yacht"])
        XCTAssertFalse(Modi.erlaubt("yacht"))
        XCTAssertTrue(Modi.erlaubt("sudoku"))
    }
}

/// Suche: Stichwortsuche und Aufbau des KI-Katalogs (ohne das Sprachmodell selbst, das nur auf dem Gerät läuft).
@MainActor
final class SpielSucheTests: XCTestCase {
    func testStichwortFindetVergleichsnamen() {
        let treffer = SpielSuche.stichwort("mensch ärgere dich nicht", in: SpielKatalog.sichtbar).map(\.id)
        XCTAssertTrue(treffer.prefix(3).contains(SpielKatalog.kennung("rauswurf")), "Rauswurf muss bei „Mensch ärgere dich nicht“ vorn stehen: \(treffer.prefix(3))")
    }

    func testKatalogZeileKnappMitStichworten() throws {
        let m = try XCTUnwrap(SpielKatalog.sichtbar.first { $0.id == SpielKatalog.kennung("yacht") })
        let zeile = SpielSuche.katalogZeile(m, wunsch: false)
        XCTAssertTrue(zeile.hasPrefix(SpielKatalog.kennung("yacht") + "|"))
        XCTAssertTrue(zeile.contains("kniffel"))
        XCTAssertFalse(zeile.contains(SpielMetadaten.info(m.id).kurz), "Die lange Kurzregel gehört nicht in den KI-Katalog")
        XCTAssertTrue(SpielSuche.katalogZeile(m, wunsch: true).contains("Min."))
    }

    func testKatalogPasstInKontextGrenze() {
        let liste = SpielKatalog.sichtbar
        for wunsch in [false, true] {
            let k = SpielSuche.katalog(liste, wunsch: wunsch)
            XCTAssertEqual(k.split(separator: "\n").count, liste.count)
            // Grob 3 Zeichen je Token; das Modell fasst etwa 4 000 Token, Anweisung und Antwort brauchen Platz.
            XCTAssertLessThan(SpielSuche.anweisung(katalog: k, wunsch: wunsch).count, 9000)
        }
    }

    func testVorfilterLiefertWenigeKandidatenOderNichts() {
        let liste = SpielKatalog.sichtbar
        let wenige = SpielSuche.vorfilter("würfeln bluffen", in: liste)
        XCTAssertFalse(wenige.isEmpty)
        XCTAssertLessThanOrEqual(wenige.count, 15)
        XCTAssertTrue(SpielSuche.vorfilter("!!", in: liste).isEmpty)
    }
}
