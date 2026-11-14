// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
import MinensucheKern
import SpieleKern
@testable import SpielMinensuche

/// Prüft das Spielmodell der Minensuche (Start, Züge, Verbuchen, Speichern, Tagesrätsel).
/// Der Speicherordner liegt im Application Support des Testprozesses; jeder Test räumt ihn vorher und nachher auf.
@MainActor
@Suite(.serialized)
struct SpielModellTests {
    private static var ordner: URL { URL.applicationSupportDirectory.appending(path: "Minensuche", directoryHint: .isDirectory) }

    private func sauber() {
        try? FileManager.default.removeItem(at: Self.ordner)
        SpielStand.loeschen(SpielModell.standKennung)
        SpielStand.verworfen.remove(SpielModell.standKennung)
    }

    /// Neues Modell auf leerem Speicher; räumt am Ende selbst auf.
    private func mitModell(_ pruefung: (SpielModell) throws -> Void) rethrows {
        sauber()
        defer { sauber() }
        try pruefung(SpielModell())
    }

    private func alleFelder(_ s: Spiel) -> [Position] { (0..<s.mass.felder).map { s.mass.position($0) } }

    @Test func startStufeLiefertBrettInDerRichtigenGroesse() {
        mitModell { m in
            #expect(m.spiel == nil && !m.laeuft && !m.hatSpielstand)
            for stufe in Stufe.allCases {
                m.neu(stufe)
                #expect(m.spiel?.mass == stufe.mass)
                #expect(m.spiel?.status == .bereit)
                #expect(m.art == .stufe && m.stufe == stufe)
                #expect(m.laeuft && m.hatSpielstand)
            }
        }
    }

    @Test func ersterZugIstNieEineMineUndStartetDieUhr() {
        mitModell { m in
            for _ in 0..<20 {
                m.neu(.schwer)
                let start = Position(zeile: 9, spalte: 5)
                m.aufdecken(start)
                let s = m.spiel!
                #expect(!s.istMine(start))
                #expect(s.feld(start) == .aufgedeckt)
                #expect(s.status == .laeuft || s.status == .gewonnen)
                #expect(s.minen.filter { $0 }.count == s.mass.minen)
            }
        }
    }

    @Test func flaggeSetzenUndEntfernenZaehltMinenRest() {
        mitModell { m in
            m.neu(.leicht)
            let p = Position(zeile: 0, spalte: 0)
            let rest = m.spiel!.minenRest
            m.flagge(p)
            #expect(m.spiel?.feld(p) == .flagge)
            #expect(m.spiel?.minenRest == rest - 1)
            m.flagge(p)
            #expect(m.spiel?.feld(p) == .verdeckt)
            #expect(m.spiel?.minenRest == rest)
        }
    }

    @Test func tippenUndLangDrueckenKehrenImFlaggenmodusUm() {
        mitModell { m in
            m.neu(.leicht)
            let a = Position(zeile: 2, spalte: 2), b = Position(zeile: 6, spalte: 5)
            m.flaggenModus = false
            m.langDruecken(a)
            #expect(m.spiel?.feld(a) == .flagge)
            m.flaggenModus = true
            m.tippen(b)
            #expect(m.spiel?.feld(b) == .flagge)
            let c = Position(zeile: 4, spalte: 3)
            m.langDruecken(c)              // im Flaggenmodus: langes Drücken deckt auf
            #expect(m.spiel?.feld(c) == .aufgedeckt)
            m.langDruecken(a)              // eine gesetzte Fahne bleibt davor geschützt
            #expect(m.spiel?.feld(a) == .flagge)
        }
    }

    @Test func minePlatztVerlorenUndVerbuchtDieNiederlage() throws {
        try mitModell { m in
            m.neu(.leicht)
            m.aufdecken(Position(zeile: 4, spalte: 3))
            let s = try #require(m.spiel)
            let mine = try #require(alleFelder(s).first { s.istMine($0) && s.feld($0) == .verdeckt })
            m.aufdecken(mine)
            #expect(m.spiel?.status == .verloren)
            #expect(m.laeuft == false)
            #expect(m.statistik.fuer(.leicht).gespielt == 1)
            #expect(m.statistik.fuer(.leicht).gewonnen == 0)
            let e = try #require(m.ergebnis)
            #expect(!e.gewonnen && e.stufe == .leicht && e.art == .stufe)
            m.ergebnisSchliessen()
            #expect(m.ergebnis == nil)
        }
    }

    @Test func allesSicherAufgedecktGewinntUndMerktBesteZeit() throws {
        try mitModell { m in
            m.neu(.leicht)
            m.aufdecken(Position(zeile: 4, spalte: 3))
            let s = try #require(m.spiel)
            for p in alleFelder(s) where !s.istMine(p) { m.aufdecken(p) }
            #expect(m.spiel?.status == .gewonnen)
            let st = m.statistik.fuer(.leicht)
            #expect(st.gespielt == 1 && st.gewonnen == 1 && st.serie == 1)
            #expect(st.besteZeit != nil)
            let e = try #require(m.ergebnis)
            #expect(e.gewonnen && e.neuerRekord)
            // Beendete Partie bleibt nicht als Spielstand liegen
            #expect(!m.hatSpielstand)
            #expect(!FileManager.default.fileExists(atPath: Self.ordner.appending(path: "spiel.json").path))
        }
    }

    @Test func neueStufenPartieWaehrendLaufenderZaehltAlsVerloren() {
        mitModell { m in
            m.neu(.mittel)
            m.aufdecken(Position(zeile: 5, spalte: 4))
            #expect(m.spiel?.status == .laeuft)
            m.neu(.leicht)
            #expect(m.statistik.fuer(.mittel).gespielt == 1)
            #expect(m.statistik.fuer(.mittel).gewonnen == 0)
            #expect(m.statistik.fuer(.leicht).gespielt == 0)
        }
    }

    @Test func neuAusBereitemBrettVerbuchtNichts() {
        mitModell { m in
            m.neu(.mittel)
            m.neu(.leicht)
            #expect(m.statistik.fuer(.mittel).gespielt == 0)
        }
    }

    @Test func aufgebenZaehltNurNachDemErstenZug() {
        mitModell { m in
            m.neu(.leicht)
            m.aufgeben()
            #expect(m.spiel == nil)
            #expect(m.statistik.fuer(.leicht).gespielt == 0)
            m.neu(.leicht)
            m.aufdecken(Position(zeile: 4, spalte: 3))
            m.aufgeben()
            #expect(m.spiel == nil && !m.laeuft)
            #expect(m.statistik.fuer(.leicht).gespielt == 1)
        }
    }

    @Test func laufendePartieUeberlebtNeustart() throws {
        sauber()
        defer { sauber() }
        let m = SpielModell()
        m.neu(.mittel)
        m.aufdecken(Position(zeile: 5, spalte: 4))
        m.flagge(Position(zeile: 0, spalte: 0))
        m.pausieren()
        let vorher = try #require(m.spiel)

        let neu = SpielModell()
        let nachher = try #require(neu.spiel)
        #expect(nachher == vorher)
        #expect(neu.stufe == .mittel && neu.art == .stufe)
        #expect(neu.laeuft)
    }

    @Test func statistikUeberlebtNeustartUndLaesstSichZuruecksetzen() {
        sauber()
        defer { sauber() }
        let m = SpielModell()
        m.neu(.leicht)
        m.aufdecken(Position(zeile: 4, spalte: 3))
        m.aufgeben()
        #expect(SpielModell().statistik.fuer(.leicht).gespielt == 1)
        m.statistikZuruecksetzen()
        #expect(SpielModell().statistik == Statistik())
    }

    @Test func kaputteSpeicherdateiFuehrtZuLeeremStart() throws {
        sauber()
        defer { sauber() }
        try FileManager.default.createDirectory(at: Self.ordner, withIntermediateDirectories: true)
        UserDefaults.standard.set(Data("kein json".utf8), forKey: "partie.stand.minensuche")
        try Data("{".utf8).write(to: Self.ordner.appending(path: "statistik.json"))
        let m = SpielModell()
        #expect(m.spiel == nil)
        #expect(m.statistik == Statistik())
    }

    @Test func hinweisDecktEinSicheresFeldAufUndKostetZeit() throws {
        try mitModell { m in
            m.neu(.leicht)
            m.aufdecken(Position(zeile: 4, spalte: 3))
            let vorher = try #require(m.spiel)
            guard vorher.status == .laeuft else { return }
            m.hinweis()
            let nachher = try #require(m.spiel)
            if nachher.hinweise > 0 {
                #expect(nachher.hinweise == 1)
                #expect(nachher.dauer >= Spiel.hinweisStrafe)
                #expect(nachher.felder.filter { $0 == .aufgedeckt }.count > vorher.felder.filter { $0 == .aufgedeckt }.count)
                #expect(nachher.status != .verloren)
            }
        }
    }

    @Test func tagesraetselIstFuerAlleAmSelbenTagGleich() throws {
        try mitModell { m in
            let tag = Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: 8))!
            m.tagesraetsel(am: tag)
            let a = try #require(m.spiel)
            #expect(m.art == .tag && m.stufe == .mittel)
            #expect(a.tagesStart != nil)
            #expect(a.felder.filter { $0 == .aufgedeckt }.count >= 1, "Startfeld ist aufgedeckt")
            m.tagesraetsel(am: tag)
            #expect(m.spiel == a)
            m.tagesraetsel(am: Calendar.current.date(byAdding: .day, value: 1, to: tag)!)
            #expect(m.spiel?.seed != a.seed)
        }
    }

    @Test func tagKennungIstJahrMonatTag() {
        let d = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 9))!
        #expect(SpielModell.tagKennung(d) == 20_260_109)
    }

    @Test func zeitUndStufentexte() {
        #expect(!SpielModell.zeit(75).isEmpty)
        #expect(Stufe.leicht.beschreibung.contains("8"))
        #expect(Stufe.schwer.beschreibung.contains("44"))
        #expect(!Stufe.mittel.nameText.isEmpty)
    }

    @Test func uhrLaeuftNurWaehrendDerPartie() {
        mitModell { m in
            #expect(m.dauer() == 0)
            m.neu(.leicht)
            #expect(m.dauer() == 0, "vor dem ersten Zug steht die Uhr")
            m.aufdecken(Position(zeile: 4, spalte: 3))
            guard m.spiel?.status == .laeuft else { return }
            #expect(m.dauer(Date().addingTimeInterval(30)) >= 29)
            m.pausieren()
            let fest = m.dauer(Date().addingTimeInterval(500))
            #expect(fest < 5, "pausiert: die Zeit läuft nicht weiter")
        }
    }
}
