// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SudokuKern

@Suite struct GeometrieTests {
    @Test func einheitenAnzahl() {
        #expect(SudokuForm.klassisch.geometrie.einheiten.count == 27)
        #expect(SudokuForm.kinder.geometrie.einheiten.count == 18)
        #expect(SudokuForm.x.geometrie.einheiten.count == 29)
    }
    @Test func nachbarn() {
        #expect(SudokuForm.klassisch.geometrie.nachbarn[0].count == 20)
        #expect(SudokuForm.kinder.geometrie.nachbarn[0].count == 5 + 5 + 2)   // Zeile 5, Spalte 5, Box (3×2) 2 zusätzliche
        // X: Zelle 0 liegt auf der Hauptdiagonale: 20 + 6 weitere der Diagonale
        #expect(SudokuForm.x.geometrie.nachbarn[0].count == 20 + 6)
        #expect(SudokuForm.x.geometrie.nachbarn[1].count == 20)
    }
    @Test func boxenKinder() {
        let g = SudokuForm.kinder.geometrie
        let boxen = Array(g.einheiten[12..<18])
        #expect(boxen.allSatisfy { $0.count == 6 })
        #expect(Set(boxen.flatMap { $0 }).count == 36)
        #expect(boxen[0] == [0, 1, 2, 6, 7, 8])
        #expect(g.box(3) == 1 && g.box(12) == 2)
    }
}

@Suite struct LoeserTests {
    private func gueltig(_ form: SudokuForm, _ g: [UInt8]) -> Bool {
        form.geometrie.einheiten.allSatisfy { u in Set(u.map { g[$0] }) == Set((1...form.n).map { UInt8($0) }) }
    }
    @Test(arguments: SudokuForm.allCases) func zufaelligesGitterGueltig(form: SudokuForm) {
        var rng = SudokuZufall(seed: 7)
        let g = SudokuLoeser.zufaelligesGitter(form, using: &rng)
        #expect(gueltig(form, g))
    }
    @Test func leeresGitterMehrdeutig() {
        #expect(SudokuLoeser.zaehle(.kinder, [UInt8](repeating: 0, count: 36)) == 2)
    }
    @Test func widerspruchUnloesbar() {
        var g = [UInt8](repeating: 0, count: 36)
        g[0] = 1; g[1] = 1
        #expect(SudokuLoeser.loese(.kinder, g) == nil)
    }
}

@Suite struct ErzeugerTests {
    @Test(arguments: SudokuForm.allCases, [SudokuStufe.leicht, .mittel, .schwer]) func eindeutig(form: SudokuForm, stufe: SudokuStufe) {
        for seed in 1...3 {
            let r = SudokuErzeuger.erzeuge(form, stufe, seed: UInt64(seed))
            #expect(r.stimmig)
            #expect(SudokuLoeser.zaehle(form, r.vorgaben) == 1)
            #expect(SudokuLoeser.loese(form, r.vorgaben) == r.loesung)
            let vorgaben = r.vorgaben.filter { $0 != 0 }.count
            #expect(vorgaben <= SudokuErzeuger.ziel(form, stufe) + 1 || vorgaben > 0)
        }
    }
    @Test func leichtMitEinzelnLoesbar() {
        for form in SudokuForm.allCases {
            let r = SudokuErzeuger.erzeuge(form, .leicht, seed: 11)
            #expect(SudokuLoeser.einzelnLoesbar(form, r.vorgaben))
        }
    }
    @Test func gleicherSeedGleichesRaetsel() {
        #expect(SudokuErzeuger.erzeuge(.x, .mittel, seed: 5) == SudokuErzeuger.erzeuge(.x, .mittel, seed: 5))
    }
    @Test func stufenWerdenSchwerer() {
        func vorgaben(_ s: SudokuStufe) -> Int { SudokuErzeuger.erzeuge(.kinder, s, seed: 3).vorgaben.filter { $0 != 0 }.count }
        #expect(vorgaben(.leicht) > vorgaben(.mittel))
        #expect(vorgaben(.mittel) >= vorgaben(.schwer))
    }
    @Test func xDiagonaleStimmt() {
        let r = SudokuErzeuger.erzeuge(.x, .mittel, seed: 9)
        let g = SudokuForm.x.geometrie
        let hauptDiagonale = Set((0..<9).map { r.loesung[$0 * 9 + $0] })
        let nebenDiagonale = Set((0..<9).map { r.loesung[$0 * 9 + 8 - $0] })
        #expect(hauptDiagonale.count == 9 && nebenDiagonale.count == 9 && g.einheiten.count == 29)
    }
}

@Suite struct PruefungTests {
    @Test func leer() { #expect(SudokuPruefung.pruefe(.kinder, [UInt8](repeating: 0, count: 36)) == .leer) }
    @Test func widerspruch() {
        var g = [UInt8](repeating: 0, count: 36); g[0] = 2; g[5] = 2
        #expect(SudokuPruefung.pruefe(.kinder, g) == .widerspruch([0, 5]))
    }
    @Test func mehrdeutig() {
        var g = [UInt8](repeating: 0, count: 36); g[0] = 1
        #expect(SudokuPruefung.pruefe(.kinder, g) == .mehrdeutig)
    }
    @Test func eindeutig() {
        let r = SudokuErzeuger.erzeuge(.klassisch, .leicht, seed: 2)
        #expect(SudokuPruefung.pruefe(.klassisch, r.vorgaben) == .eindeutig(r.loesung))
    }
    @Test func xBrauchtDiagonale() {
        // Ein klassisch eindeutiges Rätsel kann als X-Sudoku unlösbar sein, wenn die Lösung die Diagonalen verletzt
        let r = SudokuErzeuger.erzeuge(.klassisch, .leicht, seed: 4)
        let p = SudokuPruefung.pruefe(.x, r.vorgaben)
        if case .eindeutig = p {} else { #expect(p == .unloesbar || p == .mehrdeutig || { if case .widerspruch = p { true } else { false } }()) }
    }
}

@Suite struct PartieTests {
    private func partie(_ form: SudokuForm = .kinder) -> SudokuPartie {
        SudokuPartie(raetsel: SudokuErzeuger.erzeuge(form, .leicht, seed: 21))
    }
    private func ersteLuecke(_ p: SudokuPartie) -> Int { p.werte.firstIndex(of: 0)! }

    @Test func richtigeZahl() {
        var p = partie()
        let z = ersteLuecke(p)
        #expect(p.setze(z, Int(p.raetsel.loesung[z])) == .gesetzt)
        #expect(p.fehler == 0 && p.werte[z] != 0)
    }
    @Test func falscheZahlZaehlt() {
        var p = partie()
        let z = ersteLuecke(p)
        let falsch = Int(p.raetsel.loesung[z]) % 6 + 1
        #expect(p.setze(z, falsch) == .falsch)
        #expect(p.fehler == 1 && p.falsche() == [z])
    }
    @Test func vorgabeBleibt() {
        var p = partie()
        let v = p.werte.firstIndex { $0 != 0 }!
        #expect(p.setze(v, 1) == .nichts && p.loesche(v) == .nichts && p.notiz(v, 1) == .nichts)
    }
    @Test func gleicheZahlLoescht() {
        var p = partie()
        let z = ersteLuecke(p)
        p.setze(z, Int(p.raetsel.loesung[z]))
        #expect(p.setze(z, Int(p.raetsel.loesung[z])) == .geloescht && p.werte[z] == 0)
    }
    @Test func notizenWerdenAutomatischGestrichen() {
        var p = partie()
        p.notizenFuellen()
        var paar: (z: Int, d: Int, nachbar: Int)?
        for z in 0..<p.form.zellen where p.werte[z] == 0 && paar == nil {
            let d = Int(p.raetsel.loesung[z])
            if let n = p.form.geometrie.nachbarn[z].first(where: { p.werte[$0] == 0 && p.notizen[$0] & SudokuForm.bit(d) != 0 }) { paar = (z, d, n) }
        }
        let (z, d, nachbar) = paar!
        #expect(p.notizen[nachbar] & SudokuForm.bit(d) != 0)
        p.setze(z, d)
        #expect(p.notizen[nachbar] & SudokuForm.bit(d) == 0)
        p.zurueck()
        #expect(p.notizen[nachbar] & SudokuForm.bit(d) != 0 && p.werte[z] == 0)
    }
    @Test func rueckgaengigUndWiederholen() {
        var p = partie()
        let z = ersteLuecke(p)
        p.notiz(z, 3)
        #expect(p.notizen[z] == SudokuForm.bit(3))
        p.zurueck(); #expect(p.notizen[z] == 0 && p.kannWiederholen)
        p.wiederholen(); #expect(p.notizen[z] == SudokuForm.bit(3))
    }
    @Test func loesenBeendet() {
        var p = partie(.x)
        for z in 0..<p.form.zellen where p.werte[z] == 0 { p.setze(z, Int(p.raetsel.loesung[z])) }
        #expect(p.geloest && p.fertig && p.fehler == 0)
    }
    @Test func fehlerLimitUndZuruecksetzen() {
        var p = partie()
        let luecken = (0..<36).filter { p.werte[$0] == 0 }
        for z in luecken.prefix(1) { p.setze(z, Int(p.raetsel.loesung[z])) }
        for z in luecken.dropFirst().prefix(3) { p.setze(z, Int(p.raetsel.loesung[z]) % 6 + 1) }
        #expect(p.limitErreicht)
        p.zuruecksetzen()
        #expect(p.falsche().isEmpty && p.fehler == 0 && !p.limitErreicht)
        #expect(p.werte[luecken[0]] != 0)   // der richtige Eintrag davor bleibt
    }
    @Test func codableRunde() throws {
        var p = partie(.x)
        let z = ersteLuecke(p)
        p.setze(z, Int(p.raetsel.loesung[z])); p.notiz(p.werte.lastIndex(of: 0)!, 2)
        let d = try JSONEncoder().encode(p)
        let q = try JSONDecoder().decode(SudokuPartie.self, from: d)
        #expect(p == q && q.stimmig)
    }
    @Test func altesFormatOhneOptionalLaedt() throws {
        let r = SudokuErzeuger.erzeuge(.kinder, .leicht, seed: 1)
        let json = try JSONEncoder().encode(["raetsel": r])
        let p = try JSONDecoder().decode(SudokuPartie.self, from: json)
        #expect(p.werte == r.vorgaben && p.stimmig)
    }
    @Test func kaputterStandIstUnstimmig() {
        var p = partie()
        p.werte = [1, 2, 3]
        #expect(!p.stimmig)
    }
}

@Suite struct HinweisTests {
    @Test func falscheZahlZuerst() {
        var p = SudokuPartie(raetsel: SudokuErzeuger.erzeuge(.kinder, .mittel, seed: 5))
        let z = p.werte.firstIndex(of: 0)!
        p.setze(z, Int(p.raetsel.loesung[z]) % 6 + 1)
        let h = p.hinweis()
        #expect(h?.art == .falsch && h?.zelle == z)
    }
    @Test func hinweisIstRichtig() {
        for form in SudokuForm.allCases {
            let p = SudokuPartie(raetsel: SudokuErzeuger.erzeuge(form, .leicht, seed: 8))
            let h = p.hinweis()
            #expect(h != nil)
            if let h { #expect(h.ziffer == Int(p.raetsel.loesung[h.zelle]) && p.werte[h.zelle] == 0) }
        }
    }
    @Test func leichtEndetMitEinzelschritten() {
        var p = SudokuPartie(raetsel: SudokuErzeuger.erzeuge(.klassisch, .leicht, seed: 30))
        var schritte = 0
        while !p.fertig, let h = p.hinweis(), schritte < 100 {
            #expect(h.art == .einzigeMoeglichkeit || h.art == .einzigeStelle)
            p.tippEintragen(h.zelle); schritte += 1
        }
        #expect(p.geloest && p.tipps == schritte)
    }
}
