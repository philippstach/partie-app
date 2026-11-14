// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Reine Hilfsfunktionen von „Schocken“ ohne Oberfläche, damit sie sich mit `swift test` prüfen lassen.
enum NeuLogik {
    /// Aufbau des Spielbildschirms: eine Spalte (iPhone, iPad hoch) oder zwei Spalten (iPad quer).
    enum Aufbau: Equatable { case spalte, quer }

    static func aufbau(breite: Double, hoehe: Double, regular: Bool) -> Aufbau {
        regular && breite > hoehe ? .quer : .spalte
    }

    /// Höhenklassen, gemessen als Fensterhöhe ohne Statusleiste: SE ≈ 647, 390×844 ≈ 797, Pro Max ≈ 873.
    static let hoeheMittel: Double = 700
    static let hoeheGross: Double = 840

    /// Größte Würfelkante im Becher: SE 56, 390×844 bis 90, Pro Max bis 104, iPad bis 120. Große Schrift: 56.
    static func wuerfelKante(hoehe: Double, grosseSchrift: Bool, regular: Bool = false) -> Double {
        if grosseSchrift { return 56 }
        if regular { return 120 }
        if hoehe < hoeheMittel { return 56 }
        return hoehe < hoeheGross ? 90 : 104
    }

    /// Deckelreihe in der Spielerleiste: erst ab mittlerer Höhe und ohne große Schrift (SE zeigt nur die Zahl).
    static func zeigtDeckelReihe(hoehe: Double, grosseSchrift: Bool) -> Bool {
        !grosseSchrift && hoehe >= hoeheMittel
    }

    /// Darf der Würfel `i` des Wurfs zusätzlich herausgelegt werden? `auswahl`: Indizes, die schon gewählt sind.
    static func darfWaehlen(zug: Zug, auswahl: Set<Int>, umdrehen: Int, index i: Int) -> Bool {
        guard zug.darfWeiter, zug.wurf.indices.contains(i) else { return false }
        if zug.wurf[i] == 6, umdrehen > 0 { return false }
        let werte = auswahl.union([i]).map { zug.wurf[$0] }.sorted()
        return weiterErlaubt(draussen: zug.draussen, wurf: zug.wurf, wuerfe: zug.wuerfe, maxWuerfe: zug.maxWuerfe,
                             herauslegen: werte, umdrehen: umdrehen, optionen: zug.optionen)
    }

    /// Nächster Stand von „Sechsen umdrehen“ (0 → 1 → … → Maximum → 0) samt bereinigter Auswahl.
    /// Sechsen in der Auswahl fallen weg, wenn umgedreht wird; passt die Auswahl dann nicht mehr, wird sie geleert.
    /// `nil`: gar nichts davon ist erlaubt (Wackeln).
    static func umdrehenWechsel(zug: Zug, auswahl: Set<Int>, umdrehen: Int) -> (umdrehen: Int, auswahl: Set<Int>)? {
        var naechste = umdrehen + 1
        if naechste > maxUmdrehen(zug.wurf) { naechste = 0 }
        func erlaubt(_ a: Set<Int>) -> Bool {
            weiterErlaubt(draussen: zug.draussen, wurf: zug.wurf, wuerfe: zug.wuerfe, maxWuerfe: zug.maxWuerfe,
                          herauslegen: a.map { zug.wurf[$0] }.sorted(), umdrehen: naechste, optionen: zug.optionen)
        }
        var neu = auswahl.filter { zug.wurf[$0] != 6 }
        if naechste > 0, !erlaubt(neu) { neu = [] }
        if naechste > 0, !erlaubt(neu) { return nil }
        return (naechste, neu)
    }

    /// Welche Strategie rechnet für diese Stufe? Mittel spielt „gut“, patzt aber mit Wahrscheinlichkeit `patzer`
    /// (dann rechnet die einfache Strategie). `zufall` liegt in 0..<1.
    static func strategie(stufe: ComputerStufe, zufall: Double) -> Strategie {
        switch stufe {
        case .leicht: .einfach
        case .mittel: zufall < patzer(stufe) ? .einfach : .gut
        case .schwer: .gut
        }
    }

    static func patzer(_ stufe: ComputerStufe) -> Double {
        switch stufe {
        case .leicht: 1
        case .mittel: 0.5
        case .schwer: 0
        }
    }

    /// Vorlage „Kneipe“ (streng) und „Familie“ (locker) für die Hausregeln.
    static let vorlageKneipe = Optionen(jule: true, herauslegen: .einsen, sechsenUmdrehen: true, deckel: 13, spiellaenge: .partie, schockAusEndet: true)
    static let vorlageFamilie = Optionen(jule: false, herauslegen: .beliebig, sechsenUmdrehen: true, deckel: 13, spiellaenge: .partie, schockAusEndet: true)

    /// Das Ende einer Partie, unabhängig vom SpielRahmen (der nur auf dem iPhone übersetzt wird).
    struct Ende: Equatable {
        var reihenfolge: [String]
        var punkte: [String]
        var plaetze: [Int]
        var info: String?
        var istRemis: Bool { reihenfolge.count > 1 && Set(plaetze).count == 1 }
    }

    /// Ende für den SpielRahmen. Verlierer der Partie steht zuletzt; alle anderen nach verlorenen Hälften
    /// (weniger ist besser), bei gleicher Zahl teilen sie den Platz.
    static func ende(_ z: Spielzustand) -> Ende {
        let n = z.namen.count
        let verlierer = z.partieVerlierer
        func verloren(_ i: Int) -> Int { z.zaehler.haelftenVerloren[i] }
        let reihenfolge = z.namen.indices.sorted { a, b in
            if (a == verlierer) != (b == verlierer) { return b == verlierer }
            if verloren(a) != verloren(b) { return verloren(a) < verloren(b) }
            return a < b
        }
        func platz(_ i: Int) -> Int {
            if i == verlierer { return n }
            return 1 + z.namen.indices.filter { j in j != verlierer && verloren(j) < verloren(i) }.count
        }
        let info = verlierer.map { String(localized: "\(z.namen[$0]) verliert die Partie") }
        return Ende(reihenfolge: reihenfolge.map { z.namen[$0] },
                         punkte: reihenfolge.map { i in
                             verloren(i) == 1 ? String(localized: "1 Hälfte verloren") : String(localized: "\(verloren(i)) Hälften verloren")
                         },
                         plaetze: reihenfolge.map(platz),
                         info: info)
    }
}
