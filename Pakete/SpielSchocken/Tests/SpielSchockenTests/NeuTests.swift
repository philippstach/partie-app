// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import SpieleKern
@testable import SpielSchocken

/// „Schocken“: Aufbau, Becher-Regeln, Computer-Stufen, Hausregeln, Ende. Alles ohne Oberfläche.
@Suite("Schocken neu")
struct NeuTests {
    // MARK: Aufbau und Größen

    @Test func aufbauQuerNurAufDemIpad() {
        #expect(NeuLogik.aufbau(breite: 1180, hoehe: 820, regular: true) == .quer)
        #expect(NeuLogik.aufbau(breite: 820, hoehe: 1180, regular: true) == .spalte)
        #expect(NeuLogik.aufbau(breite: 844, hoehe: 390, regular: false) == .spalte)
    }

    @Test func wuerfelKanteWaechstMitDerHoehe() {
        let se = NeuLogik.wuerfelKante(hoehe: 647, grosseSchrift: false)
        let mittel = NeuLogik.wuerfelKante(hoehe: 797, grosseSchrift: false)
        let gross = NeuLogik.wuerfelKante(hoehe: 873, grosseSchrift: false)
        #expect(se == 56 && mittel == 90 && gross == 104)
        #expect(NeuLogik.wuerfelKante(hoehe: 873, grosseSchrift: true) == 56)
        #expect(NeuLogik.wuerfelKante(hoehe: 800, grosseSchrift: false, regular: true) == 120)
    }

    @Test func deckelReiheErstAbMittlererHoehe() {
        #expect(!NeuLogik.zeigtDeckelReihe(hoehe: 647, grosseSchrift: false))
        #expect(NeuLogik.zeigtDeckelReihe(hoehe: 797, grosseSchrift: false))
        #expect(!NeuLogik.zeigtDeckelReihe(hoehe: 873, grosseSchrift: true))
    }

    // MARK: Becher

    private func zug(wurf: [Int], draussen: [Int] = [], wuerfe: Int = 1, opt: Optionen = .standard) -> Zug {
        var z = Zug(maxWuerfe: 3, optionen: opt)
        z.wurf = wurf; z.draussen = draussen; z.wuerfe = wuerfe
        return z
    }

    @Test func nurEinsenDuerfenHeraus() {
        let z = zug(wurf: [5, 1, 3])
        #expect(NeuLogik.darfWaehlen(zug: z, auswahl: [], umdrehen: 0, index: 1))
        #expect(!NeuLogik.darfWaehlen(zug: z, auswahl: [], umdrehen: 0, index: 0))
        let frei = zug(wurf: [5, 1, 3], opt: Optionen(herauslegen: .beliebig))
        #expect(NeuLogik.darfWaehlen(zug: frei, auswahl: [], umdrehen: 0, index: 0))
    }

    @Test func alleDreiHerauslegenIstNichtErlaubt() {
        let z = zug(wurf: [1, 1, 3], opt: Optionen(herauslegen: .beliebig))
        #expect(NeuLogik.darfWaehlen(zug: z, auswahl: [0], umdrehen: 0, index: 1))
        #expect(!NeuLogik.darfWaehlen(zug: z, auswahl: [0, 1], umdrehen: 0, index: 2))   // einer muss im Becher bleiben
    }

    @Test func nachDemLetztenWurfNichtsMehr() {
        let z = zug(wurf: [1, 2, 3], wuerfe: 3)
        #expect(!NeuLogik.darfWaehlen(zug: z, auswahl: [], umdrehen: 0, index: 0))
    }

    @Test func sechsenUmdrehenWechseltDurch() {
        let z = zug(wurf: [6, 6, 6])
        let a = NeuLogik.umdrehenWechsel(zug: z, auswahl: [], umdrehen: 0)
        #expect(a?.umdrehen == 1)
        let b = NeuLogik.umdrehenWechsel(zug: z, auswahl: [], umdrehen: 1)
        #expect(b?.umdrehen == 2)
        let c = NeuLogik.umdrehenWechsel(zug: z, auswahl: [], umdrehen: 2)
        #expect(c?.umdrehen == 0)
    }

    @Test func umdrehenLeertUnpassendeAuswahl() {
        let z = zug(wurf: [6, 6, 1], opt: Optionen(herauslegen: .beliebig))
        // Eine Sechs ist gewählt; Umdrehen verbietet das Herauslegen von Sechsen → Auswahl ohne Sechsen
        let r = NeuLogik.umdrehenWechsel(zug: z, auswahl: [0, 2], umdrehen: 0)
        #expect(r?.umdrehen == 1)
        #expect(r?.auswahl == [2])
    }

    @Test func umdrehenOhneZweiSechsenGehtNicht() {
        let z = zug(wurf: [6, 2, 1])
        #expect(NeuLogik.umdrehenWechsel(zug: z, auswahl: [], umdrehen: 0)?.umdrehen == 0 || NeuLogik.umdrehenWechsel(zug: z, auswahl: [], umdrehen: 0) == nil)
    }

    // MARK: Computer-Stufen

    @Test func stufenWaehlenDieStrategie() {
        #expect(NeuLogik.strategie(stufe: .leicht, zufall: 0.99) == .einfach)
        #expect(NeuLogik.strategie(stufe: .schwer, zufall: 0) == .gut)
        #expect(NeuLogik.strategie(stufe: .mittel, zufall: 0.1) == .einfach)     // Patzer
        #expect(NeuLogik.strategie(stufe: .mittel, zufall: 0.9) == .gut)
        #expect(NeuLogik.patzer(.leicht) > NeuLogik.patzer(.mittel))
        #expect(NeuLogik.patzer(.mittel) > NeuLogik.patzer(.schwer))
    }

    /// Jede Stufe spielt ganze Partien nur mit erlaubten Zügen zu Ende (Messung der Stärke: Doku/Bewertung, 1200 Partien je Paar).
    @Test @MainActor func jedeStufeSpieltPartienZuEnde() {
        for stufe in ComputerStufe.allCases {
            for seed in 1...6 {
                var quelle = SeedQuelle(seed: UInt64(seed))
                var z = Spielzustand(namen: ["A", "B", "C"], strategien: [.gut, .gut, .einfach], optionen: Optionen(spiellaenge: .haelfte), beginner: seed % 3)
                var n = 0
                while z.phase != .partieVorbei, n < 6000 {
                    n += 1
                    switch z.phase {
                    case .computer:
                        guard let lage = z.lage else { z.wuerfeln(&quelle); continue }
                        let a = Computer.entscheide(NeuLogik.strategie(stufe: stufe, zufall: Double(seed) / 7), lage)
                        #expect(z.fuehreAus(a, &quelle))
                    case .zugEnde: z.zugWeiter()
                    case .rundenwertung: z.rundeWeiter()
                    case .haelfteVorbei: z.haelfteWeiter()
                    default: Issue.record("unerwartete Phase \(z.phase)"); return
                    }
                }
                #expect(z.phase == .partieVorbei)
            }
        }
    }

    // MARK: Hausregeln

    @Test func alteOptionenLadenMitSchockAusEndet() throws {
        let alt = #"{"jule":true,"deckel":15}"#
        let o = try JSONDecoder().decode(Optionen.self, from: Data(alt.utf8))
        #expect(o.schockAusEndet)
        #expect(o.jule && o.deckel == 15)
    }

    @Test func vorlagen() {
        #expect(NeuLogik.vorlageKneipe.jule && NeuLogik.vorlageKneipe.herauslegen == .einsen)
        #expect(!NeuLogik.vorlageFamilie.jule && NeuLogik.vorlageFamilie.herauslegen == .beliebig)
    }

    private func runde(opt: Optionen, stock: Int, deckel: [Int], wuerfel: [[Int]]) -> (Rundenausgang, Haelfte) {
        var h = Haelfte(art: .haelfte1, spieler: Array(deckel.indices), beginner: 0, optionen: opt)
        h.stock = stock; h.deckel = deckel
        let e: [(spieler: Int, ergebnis: Ergebnis)] = wuerfel.enumerated().map { i, w in
            (i, Ergebnis(wertung: werte(w, ausEinemWurf: true, optionen: opt), wuerfe: 1, position: i))
        }
        let a = werteRunde(e, haelfte: h)
        h.wendeAn(a)
        return (a, h)
    }

    @Test func schockAusBeendetDieHaelfteImStandard() {
        let (a, h) = runde(opt: .standard, stock: 13, deckel: [0, 0], wuerfel: [[1, 1, 1], [6, 5, 4]])
        #expect(a.schockAus)
        #expect(h.verlierer == 1)
        #expect(h.deckel == [0, 13])
    }

    @Test func schockAusOhneEndeGibtNurDenWertAusDemStock() {
        let opt = Optionen(schockAusEndet: false)
        let (a, h) = runde(opt: opt, stock: 13, deckel: [0, 0], wuerfel: [[1, 1, 1], [6, 5, 4]])
        #expect(!a.schockAus)
        #expect(a.ausStock && a.deckel == 13)           // alle 13 – aber als gewöhnliche Runde, die Hälfte endet über den Stand
        #expect(h.deckel == [0, 13])
    }

    @Test func schockAusOhneEndeBegrenztAufStockUndGewinner() {
        let opt = Optionen(schockAusEndet: false)
        let (a, h) = runde(opt: opt, stock: 3, deckel: [4, 6], wuerfel: [[1, 1, 1], [6, 5, 4]])
        #expect(a.deckel == 3 && a.ausStock)
        #expect(h.stock == 0 && h.deckel == [4, 9])
        let (b, g) = runde(opt: opt, stock: 0, deckel: [4, 9], wuerfel: [[1, 1, 1], [6, 5, 4]])
        #expect(b.deckel == 4 && !b.ausStock)             // Gewinner gibt nur, was er hat
        #expect(g.deckel == [0, 13])
    }

    @Test func schockAusEndetWirdInDerHaelfteGemerkt() throws {
        let h = Haelfte(art: .haelfte1, spieler: [0, 1], beginner: 0, optionen: Optionen(schockAusEndet: false))
        let kopie = try JSONDecoder().decode(Haelfte.self, from: JSONEncoder().encode(h))
        #expect(!kopie.schockAusEndet)
    }

    // MARK: Regeln vor dem ersten Zug

    @Test @MainActor func regelnVorStartBautDiePartieNeuAuf() {
        let datei = FileManager.default.temporaryDirectory.appending(path: "schocken-neu-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: datei) }
        let store = GameStore(repository: GameRepository(url: datei), seed: 7)
        store.neuePartie(namen: ["A", "B", "C"], strategien: [.mensch, .gut, .gut], optionen: .standard, beginner: 1)
        #expect(store.vorErstemZug)
        #expect(store.regelnVorStart(NeuLogik.vorlageFamilie))
        #expect(store.zustand?.optionen == NeuLogik.vorlageFamilie)
        #expect(store.zustand?.runde.beginner == 1)
        #expect(store.zustand?.namen == ["A", "B", "C"])
    }

    @Test @MainActor func regelnNachDemErstenWurfSindGesperrt() {
        let datei = FileManager.default.temporaryDirectory.appending(path: "schocken-neu-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: datei) }
        let store = GameStore(repository: GameRepository(url: datei), seed: 7)
        store.neuePartie(namen: ["A", "B"], strategien: [.mensch, .mensch], optionen: .standard, beginner: 0)
        store.wuerfeln()
        #expect(!store.vorErstemZug)
        #expect(!store.regelnVorStart(NeuLogik.vorlageKneipe))
        #expect(store.zustand?.optionen == .standard)
    }

    // MARK: Ende für den Rahmen

    private func beendet(verlierer: Int, haelften: [Int], namen: [String]) -> Spielzustand {
        var z = Spielzustand(namen: namen, strategien: Array(repeating: .mensch, count: namen.count), optionen: .standard, beginner: 0)
        z.partieVerlierer = verlierer
        z.phase = .partieVorbei
        for h in haelften { z.zaehler.haelftenVerloren[h] += 1 }
        return z
    }

    @Test func endeVerliererStehtZuletzt() {
        let z = beendet(verlierer: 1, haelften: [1, 1, 0], namen: ["Anna", "Ben", "Cem"])
        let e = NeuLogik.ende(z)
        #expect(e.reihenfolge == ["Cem", "Anna", "Ben"])
        #expect(e.plaetze == [1, 2, 3])
        #expect(e.info == "Ben verliert die Partie")
        #expect(!e.istRemis)
    }

    @Test func endeGleicheHaelftenTeilenDenPlatz() {
        let z = beendet(verlierer: 0, haelften: [0, 0], namen: ["Anna", "Ben", "Cem"])
        let e = NeuLogik.ende(z)
        #expect(e.reihenfolge.last == "Anna")
        #expect(e.plaetze == [1, 1, 3])
    }
}
