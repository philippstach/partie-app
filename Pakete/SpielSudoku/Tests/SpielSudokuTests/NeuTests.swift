// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import Foundation
import SpieleKern
import SudokuKern
@testable import SpielSudoku

/// „Sudoku“: Verbindung von neuem Kern und dem Spielkern (Rätselbau, Tipps, Übungen, Tagesrätsel), Ablage und Fortsetzen.
@Suite struct NeuBrueckeTests {
    @Test func klassischNutztDenAltenErzeuger() {
        let r = NeuBruecke.raetsel(.klassisch, .leicht, seed: 7)
        #expect(r.form == .klassisch && r.stimmig && r.stufe == .leicht)
        #expect(SudokuLoeser.zaehle(.klassisch, r.vorgaben) == 1)
        #expect(SudokuLoeser.loese(.klassisch, r.vorgaben) == r.loesung)
    }

    @Test(arguments: [SudokuForm.kinder, .x]) func varianteNutztDenNeuenKern(form: SudokuForm) {
        let r = NeuBruecke.raetsel(form, .mittel, seed: 3)
        #expect(r.form == form && r.stimmig)
        #expect(SudokuLoeser.zaehle(form, r.vorgaben) == 1)
    }

    /// RT-041: Nur klassische Rätsel zählen für die Stufenleiter.
    @Test func nurKlassischSchaltetStufenFrei() {
        #expect(NeuBruecke.leiterStufe(SudokuPartie(raetsel: NeuBruecke.raetsel(.klassisch, .mittel, seed: 5))) == SudokuStufe.allCases.firstIndex(of: .mittel))
        #expect(NeuBruecke.leiterStufe(SudokuPartie(raetsel: NeuBruecke.raetsel(.kinder, .mittel, seed: 5))) == nil)
        #expect(NeuBruecke.leiterStufe(SudokuPartie(raetsel: NeuBruecke.raetsel(.x, .mittel, seed: 5))) == nil)
    }

    @Test func tagesraetselIstDasAlteTagesraetsel() {
        let r = NeuBruecke.tagesraetsel("2026-11-09")
        let alt = DailyPuzzle.puzzle(for: "2026-11-09")
        #expect(r.vorgaben == alt.givens && r.loesung == alt.solution && r.stufe == .mittel)
    }

    @Test func boardEntsprichtPartie() {
        var p = SudokuPartie(raetsel: NeuBruecke.raetsel(.klassisch, .leicht, seed: 5))
        let z = p.werte.firstIndex(of: 0)!
        p.setze(z, Int(p.raetsel.loesung[z]))
        p.notiz(p.werte.lastIndex(of: 0)!, 4)
        let b = NeuBruecke.board(p)
        #expect(b.values == p.werte)
        #expect(b.cells.map(\.notes) == p.notizen)
        #expect(b.cells.indices.allSatisfy { b.cells[$0].isGiven == (p.raetsel.vorgaben[$0] != 0) })
    }

    @Test(arguments: SudokuForm.allCases) func tippIstRichtig(form: SudokuForm) {
        let p = SudokuPartie(raetsel: NeuBruecke.raetsel(form, .leicht, seed: 12))
        let t = NeuBruecke.tipp(p, bevorzugt: nil)
        #expect(t != nil)
        if let t {
            #expect(t.ziffer == Int(p.raetsel.loesung[t.zelle]) && p.werte[t.zelle] == 0 && !t.titel.isEmpty && !t.text.isEmpty)
        }
    }

    @Test func tippMeldetFalscheZahlZuerst() {
        for form in SudokuForm.allCases {
            var p = SudokuPartie(raetsel: NeuBruecke.raetsel(form, .leicht, seed: 2))
            let z = p.werte.firstIndex(of: 0)!
            p.setze(z, Int(p.raetsel.loesung[z]) % form.n + 1)
            let t = NeuBruecke.tipp(p, bevorzugt: nil)
            #expect(t?.falsch == true && t?.zelle == z)
        }
    }

    @Test func titel() {
        let p = SudokuPartie(raetsel: NeuBruecke.raetsel(.kinder, .leicht, seed: 1))
        #expect(NeuBruecke.titel(p).contains(NeuBruecke.formName(.kinder)))
        let tag = SudokuPartie(raetsel: NeuBruecke.raetsel(.klassisch, .leicht, seed: 1), tagesschluessel: "2026-11-09")
        #expect(NeuBruecke.titel(tag) == String(localized: "Tagesrätsel"))
        let eigen = SudokuPartie(raetsel: NeuBruecke.raetsel(.klassisch, .leicht, seed: 1), eigen: true)
        #expect(NeuBruecke.titel(eigen) == String(localized: "Eigenes Rätsel"))
    }
}

@Suite struct NeuUebungTests {
    @Test func jedeUebungLaesstSichStartenUndLoesen() {
        var geprueft = 0
        for t in Technique.allCases {
            for e in Exercises.series(for: t) {
                guard var p = NeuBruecke.uebungPartie(t, e.nr) else { Issue.record("Übung \(t) \(e.nr) nicht startbar"); continue }
                #expect(p.uebung == SudokuUebungRef(technik: t.rawValue, nummer: e.nr) && p.fehler == 0)
                #expect(!NeuBruecke.uebungErledigt(p))
                if let s = e.schritt.setzen {
                    p.setze(s.zelle, s.ziffer)
                } else if let streiche = e.schritt.streichen {
                    for st in streiche { for d in st.ziffern where p.notizen[st.zelle] & SudokuForm.bit(d) != 0 { p.notiz(st.zelle, d) } }
                }
                #expect(NeuBruecke.uebungErledigt(p), "Übung \(t) \(e.nr) nach dem Zielschritt nicht erledigt")
                #expect(p.fehler == 0, "Übungen zählen keine Fehler")
                geprueft += 1
            }
        }
        // Ohne Übungsdaten (Bundle fehlt) wäre der Test leer: die App liefert uebungen.json mit
        #expect(geprueft > 0)
    }
}

@Suite struct NeuAblageTests {
    private func defaults() -> UserDefaults {
        let name = "sudoku-neu-test-\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test func tageUndUebungenWerdenGemerkt() {
        let d = defaults()
        #expect(NeuAblage.geloesteTage(d).isEmpty)
        NeuAblage.tagGeloest("2026-11-09", d); NeuAblage.tagGeloest("2026-11-09", d); NeuAblage.tagGeloest("2026-11-10", d)
        #expect(NeuAblage.geloesteTage(d) == ["2026-11-09", "2026-11-10"])
        NeuAblage.uebungGeschafft(SudokuUebungRef(technik: Technique.xWing.rawValue, nummer: 2), d)
        #expect(NeuAblage.istGeuebt(.xWing, 2, in: NeuAblage.geuebt(d)))
        #expect(!NeuAblage.istGeuebt(.xWing, 3, in: NeuAblage.geuebt(d)))
    }

    @Test func serieAusGeloestenTagen() {
        let s = DailyStreak.compute(solved: ["2026-11-07", "2026-11-08", "2026-11-09"], today: "2026-11-09")
        #expect(s.length == 3)
    }

    @Test func standUeberlebtSpeichernUndLaden() {
        let d = defaults()
        var p = SudokuPartie(raetsel: NeuBruecke.raetsel(.x, .leicht, seed: 4), tagesschluessel: nil)
        let z = p.werte.firstIndex(of: 0)!
        p.setze(z, Int(p.raetsel.loesung[z]))
        p.verstrichen = 42
        SpielStand.sichern(p, spiel: NeuAblage.id, defaults: d)
        let q = SpielStand.laden(SudokuPartie.self, spiel: NeuAblage.id, defaults: d)
        #expect(q == p && q?.stimmig == true)
        SpielStand.loeschen(NeuAblage.id, defaults: d)
        #expect(!SpielStand.vorhanden(NeuAblage.id, defaults: d))
    }

    @Test func modulIdUndNamen() async {
        await MainActor.run {
            let m = SudokuModul()
            #expect(m.id == "sudoku-neu" && m.name == "Sudoku" && m.gattung == .raetsel && m.spielerzahl == 1...1)
        }
    }
}
