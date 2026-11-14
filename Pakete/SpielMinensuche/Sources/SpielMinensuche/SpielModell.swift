// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import SpieleKern
import KlarGlas
import SpieleKern
import Observation
import Baukasten
import MinensucheKern

/// Hält die laufende Partie, die Uhr, die Statistik und speichert alles nach jedem Zug.
@Observable
@MainActor
final class SpielModell {
    enum Art: String, Codable { case stufe, tag }

    struct Gespeichert: Codable {
        var spiel: Spiel
        var stufe: Stufe
        var art: Art
    }

    private(set) var spiel: Spiel?
    private(set) var stufe: Stufe = .leicht
    private(set) var art: Art = .stufe
    private(set) var statistik: Statistik
    /// Beendete Partie, die noch im Ergebnis-Bildschirm gezeigt wird.
    private(set) var ergebnis: Ergebnis?
    var flaggenModus = false

    /// R2 (Blatt 8): Das Brett am Ende, nur im Speicher. Bleibt nach `ergebnisSchliessen()` lesbar, bis die nächste Partie beginnt.
    struct EndeStand {
        let spiel: Spiel
        let stufe: Stufe
        let art: Art
        let dauer: TimeInterval
    }
    static var letzterStand: EndeStand?
    /// Leeres Modell für die nicht antippbare Ansicht des Endbretts (`ZelleView` verlangt eines in der Umgebung).
    static let anzeigeModell = SpielModell()

    struct Ergebnis: Identifiable {
        let id = UUID()
        let gewonnen: Bool
        let dauer: TimeInterval
        let neuerRekord: Bool
        let stufe: Stufe
        let art: Art
        /// 1.0 (M3): Partie mit zweiter Chance (gewonnen = keine Bestzeit)
        var zweiteChance = false
        /// RT-043: Partie mit Hinweis (gewonnen = keine Bestzeit)
        var mitHinweis = false
    }
    /// 1.0 (M3): Statistik vor dem Verbuchen einer Mine, damit die zweite Chance die Niederlage wieder zurücknimmt
    private var statistikVorMine: Statistik?

    private var laufStart: Date?
    private var basisDauer: TimeInterval = 0

    static let standKennung = "minensuche"
    private static var dateiStatistik: URL { Self.ordner.appending(path: "statistik.json") }
    private static var ordner: URL { URL.applicationSupportDirectory.appending(path: "Minensuche", directoryHint: .isDirectory) }

    init() {
        statistik = JSONSpeicher.laden(Statistik.self, url: Self.dateiStatistik) ?? Statistik()
        if let g = SpielStand.laden(Gespeichert.self, spiel: Self.standKennung), !g.spiel.istZuende {
            spiel = g.spiel; stufe = g.stufe; art = g.art
            basisDauer = g.spiel.dauer
        }
    }

    var laeuft: Bool { spiel != nil && spiel?.istZuende == false }
    var hatSpielstand: Bool { spiel != nil && spiel?.istZuende == false }

    // MARK: Start

    /// Eine laufende Stufen-Partie, die ersetzt wird, zählt als verloren (sonst ließe sich die Serie durch Abbrechen retten).
    private func laufendeAlsVerlorenVerbuchen() {
        guard let s = spiel, s.status == .laeuft, art == .stufe else { return }
        statistik.verbuche(stufe: stufe, gewonnen: false, dauer: dauer())
        JSONSpeicher.sichern(statistik, url: Self.dateiStatistik)
    }

    /// Serie des Tagesrätsels, nur solange sie nicht gerissen ist
    var tagesSerieAktuell: Int {
        let gestern = Self.tagKennung(Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
        return statistik.aktuelleSerie(heute: tagesraetselHeute, gestern: gestern)
    }

    func neu(_ stufe: Stufe) {
        Self.letzterStand = nil
        laufendeAlsVerlorenVerbuchen()
        let fair = UserDefaults.standard.object(forKey: Einstellung.fair) as? Bool ?? true
        self.stufe = stufe; art = .stufe
        spiel = Spiel(stufe: stufe, seed: UInt64.random(in: 1...UInt64.max), fair: fair)
        starteUhr(bei: 0)
        sichern()
    }

    /// Geteiltes Rätsel (D3): gleiches Brett wie beim Absender. Zählt als normale Stufen-Partie.
    func geteilt(_ stufe: Stufe, seed: UInt64) {
        Self.letzterStand = nil
        laufendeAlsVerlorenVerbuchen()
        self.stufe = stufe; art = .stufe
        spiel = Spiel.geteilt(stufe: stufe, seed: seed)
        starteUhr(bei: 0)
        sichern()
    }

    func tagesraetsel(am datum: Date = .now) {
        Self.letzterStand = nil
        laufendeAlsVerlorenVerbuchen()
        let k = Calendar.current.dateComponents([.year, .month, .day], from: datum)
        stufe = .mittel; art = .tag
        spiel = Spiel.tagesraetsel(jahr: k.year!, monat: k.month!, tag: k.day!)
        starteUhr(bei: 0)
        sichern()
    }

    var tagesraetselHeute: Int { Self.tagKennung(.now) }
    static func tagKennung(_ d: Date) -> Int {
        let k = Calendar.current.dateComponents([.year, .month, .day], from: d)
        return k.year! * 10_000 + k.month! * 100 + k.day!
    }

    // MARK: Uhr

    /// Gespielte Sekunden einschließlich der laufenden.
    func dauer(_ jetzt: Date = .now) -> TimeInterval {
        guard let spiel else { return 0 }
        if spiel.istZuende { return spiel.dauer }
        guard spiel.status == .laeuft, let s = laufStart else { return spiel.dauer }
        return basisDauer + jetzt.timeIntervalSince(s)
    }

    private func starteUhr(bei sekunden: TimeInterval) {
        basisDauer = sekunden
        laufStart = (spiel?.status == .laeuft) ? .now : nil
    }

    /// Beim Verlassen des Spielbildschirms oder Hintergrund: Zeit festhalten.
    func pausieren() {
        guard var s = spiel, s.status == .laeuft else { return }
        s.dauer = dauer()
        basisDauer = s.dauer
        laufStart = nil
        spiel = s
        sichern()
    }

    func fortsetzen() {
        guard let s = spiel, s.status == .laeuft else { return }
        basisDauer = s.dauer
        laufStart = .now
    }

    // MARK: Zuege

    func aufdecken(_ p: Position) {
        aendern { $0.aufdecken(p) }
    }

    func flagge(_ p: Position) {
        aendern { $0.flaggeUmschalten(p) }
    }

    /// Tippen: im Flaggenmodus Fahne, sonst aufdecken.
    func tippen(_ p: Position) {
        guard let s = spiel else { return }
        if flaggenModus, s.feld(p) != .aufgedeckt { flagge(p) } else { aufdecken(p) }
    }

    func langDruecken(_ p: Position) {
        guard let s = spiel else { return }
        if s.feld(p) == .aufgedeckt { return }
        flaggenModus ? aufdecken(p) : flagge(p)
    }

    func hinweis() {
        aendern { _ = $0.hinweisGeben() }
    }

    private func aendern(_ aktion: (inout Spiel) -> Void) {
        guard var s = spiel, !s.istZuende else { return }
        let vorher = s.status
        if vorher == .laeuft { s.dauer = dauer() }
        aktion(&s)
        if vorher == .bereit && s.status == .laeuft { s.dauer = 0; basisDauer = 0; laufStart = .now }
        else if s.status == .laeuft { basisDauer = s.dauer; laufStart = .now }
        if s.istZuende { beenden(&s) }
        spiel = s
        sichern()
    }

    private func beenden(_ s: inout Spiel) {
        s.dauer = max(s.dauer, (laufStart.map { basisDauer + Date().timeIntervalSince($0) } ?? s.dauer))
        laufStart = nil
        let gewonnen = s.status == .gewonnen
        var rekord = false
        statistikVorMine = (!gewonnen && art == .stufe && s.zweiteChanceMoeglich) ? statistik : nil   // 1.0 (M3)
        if art == .tag {
            if gewonnen {
                let heute = Self.tagKennung(.now)
                let gestern = Self.tagKennung(Calendar.current.date(byAdding: .day, value: -1, to: .now)!)
                statistik.verbucheTag(tag: heute, gestern: gestern)
            }
        } else {
            if gewonnen { rekord = statistik.verbuche(stufe: stufe, gewonnen: true, dauer: s.dauer, bestzeitMoeglich: s.bestzeitMoeglich) }   // RT-043: auch Hinweise verhindern die Bestzeit
            else { statistik.verbuche(stufe: stufe, gewonnen: false, dauer: s.dauer) }
            if gewonnen, let i = Stufe.allCases.firstIndex(of: stufe) { Leiter.sieg("minensuche", stufe: i, mitTipp: s.hinweise > 0) }   // D4
        }
        ergebnis = Ergebnis(gewonnen: gewonnen, dauer: s.dauer, neuerRekord: rekord, stufe: stufe, art: art, zweiteChance: s.zweiteChanceGenutzt, mitHinweis: s.hinweise > 0)
        JSONSpeicher.sichern(statistik, url: Self.dateiStatistik)
    }

    /// N-024: „Aufhören“ nach einer Mine: zeigt die Lage aller Minen.
    func minenZeigen() {
        guard var s = spiel else { return }
        s.minenZeigen()
        spiel = s
    }

    func ergebnisSchliessen() {
        if ergebnis != nil, var s = spiel {
            s.minenZeigen()   // am Ende zeigt das Feld alle Minen (nach einem Sieg ohnehin)
            Self.letzterStand = EndeStand(spiel: s, stufe: stufe, art: art, dauer: ergebnis?.dauer ?? s.dauer)
        }
        ergebnis = nil; statistikVorMine = nil
    }

    /// 1.0 (M3): Zweite Chance nach einer Mine. Der letzte Zug wird zurückgenommen (30 s Strafzeit), die Niederlage nicht verbucht.
    var zweiteChanceMoeglich: Bool { ergebnis != nil && spiel?.zweiteChanceMoeglich == true }

    func zweiteChanceNehmen() {
        guard zweiteChanceMoeglich, var s = spiel, s.zweiteChanceNehmen() else { return }
        if let alt = statistikVorMine {
            statistik = alt
            JSONSpeicher.sichern(statistik, url: Self.dateiStatistik)
        }
        statistikVorMine = nil
        ergebnis = nil
        spiel = s
        starteUhr(bei: s.dauer)
        sichern()
    }

    /// Aufgeben/Verlassen einer laufenden Partie: zählt als verloren, nur wenn schon aufgedeckt wurde.
    func aufgeben() {
        guard var s = spiel, s.status == .laeuft else { spiel = nil; sichern(); return }
        if art == .stufe { statistik.verbuche(stufe: stufe, gewonnen: false, dauer: dauer()) }
        JSONSpeicher.sichern(statistik, url: Self.dateiStatistik)
        s.dauer = dauer()
        spiel = nil
        laufStart = nil
        sichern()
    }

    func spielVerlassen() {
        pausieren()
    }

    func statistikZuruecksetzen() {
        statistik = Statistik()
        JSONSpeicher.sichern(statistik, url: Self.dateiStatistik)
    }

    private func sichern() {
        // Serie des Tagesrätsels ans Widget. Minensuche kennt den Tag als Zahl jjjjmmtt, das Widget erwartet „jjjj-mm-tt“.
        let tag = statistik.letzterTag.map { String(format: "%04d-%02d-%02d", $0 / 10_000, $0 / 100 % 100, $0 % 100) }
        TagesSerieWidget.melden(praefix: "minensuche", serie: tagesSerieAktuell, letzterTag: tag)
        // Fortsetzen über den Kern (`SpielStand`); ein bewusst beendeter Stand wird nicht wieder angelegt
        if let s = spiel, !s.istZuende {
            if !SpielStand.verworfen.contains(Self.standKennung) { SpielStand.sichern(Gespeichert(spiel: s, stufe: stufe, art: art), spiel: Self.standKennung) }
        } else {
            SpielStand.loeschen(Self.standKennung)
        }
    }

    // MARK: Anzeige

    /// Sieben Einträge Mo…So der laufenden Woche: wahr = Tagesrätsel an diesem Tag Teil der aktuellen Serie.
    var woche: [Bool] {
        var kal = Calendar(identifier: .gregorian)
        kal.firstWeekday = 2
        guard let start = kal.dateInterval(of: .weekOfYear, for: .now)?.start else { return Array(repeating: false, count: 7) }
        let letzter = tagesSerieAktuell > 0 ? statistik.letzterTag : nil
        return (0..<7).map { i in
            guard let tag = kal.date(byAdding: .day, value: i, to: start), let letzter else { return false }
            let k = Self.tagKennung(tag)
            guard k <= letzter, let ende = Self.datum(letzter, kal),
                  let anfang = kal.date(byAdding: .day, value: -(max(tagesSerieAktuell, 1) - 1), to: ende) else { return false }
            return k >= Self.tagKennung(anfang)
        }
    }

    private static func datum(_ kennung: Int, _ kal: Calendar) -> Date? {
        kal.date(from: DateComponents(year: kennung / 10_000, month: kennung / 100 % 100, day: kennung % 100))
    }

    var tagesraetselGeloest: Bool { statistik.letzterTag == tagesraetselHeute }

    /// Gespeicherte Statistik für die Startoptionen (Bestzeiten, Tagesserie), ohne ein ganzes Modell anzulegen.
    static func gespeicherteStatistik() -> Statistik { JSONSpeicher.laden(Statistik.self, url: dateiStatistik) ?? Statistik() }

    static func zeit(_ sekunden: TimeInterval) -> String { Zeitformat.text(sekunden) }   // Q16
}

extension Stufe {
    var name: LocalizedStringKey {
        switch self {
        case .leicht: "Leicht"
        case .mittel: "Mittel"
        case .schwer: "Schwer"
        }
    }
    var nameText: String {
        switch self {
        case .leicht: String(localized: "Leicht")
        case .mittel: String(localized: "Mittel")
        case .schwer: String(localized: "Schwer")
        }
    }
    var beschreibung: String {
        let m = mass
        return String(localized: "\(m.spalten) × \(m.zeilen) Felder, \(m.minen) Minen")
    }
}
