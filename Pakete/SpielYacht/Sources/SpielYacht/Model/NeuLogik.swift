// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Reine Hilfsfunktionen von „Yacht“ ohne Oberfläche, damit sie sich mit `swift test` prüfen lassen.
nonisolated enum NeuLogik {
    /// Zeilen des Blocks: Felder, Bonus (falls die Wertung einen hat), Yacht-Bonus (falls an) und Gesamt.
    static func zeilen(_ rules: Rules) -> Int {
        rules.variant.fields.count + (rules.upperBonus > 0 ? 1 : 0) + (rules.kniffelBonus > 0 ? 1 : 0) + 1
    }

    /// Zeilenhöhe so, dass der Block die Resthöhe füllt (Kopfzeile eingerechnet), begrenzt auf 22…34 pt (große Schrift 26…40).
    static func zeilenHoehe(verfuegbar: Double, zeilen: Int, grosseSchrift: Bool, regular: Bool = false) -> Double {   // B18 M-005: iPad darf höhere Zeilen, damit zwischen Tabelle und Würfeln keine Lücke bleibt
        let h = verfuegbar / Double(max(zeilen + 2, 1))     // die Kopfzeile zählt wie zwei Zeilen
        return min(max(h, grosseSchrift ? 26 : 22), grosseSchrift ? 44 : (regular ? 52 : 34))
    }

    /// Würfelkante in der Würfelzone: SE 48, große Schrift 56, übrige iPhones 64–72, iPad 90.
    static func wuerfelKante(hoehe: Double, regular: Bool, grosseSchrift: Bool) -> Double {
        if grosseSchrift { return 56 }   // G-006: bei großer Schrift etwas größer als SE
        if regular { return 90 }
        if hoehe < 700 { return 48 }
        return hoehe < 840 ? 64 : 72
    }

    /// Wie viele Personen passen mit Namen in den Block (SE 4, sonst 6 – mehr gibt es auf dem iPhone nicht).
    static func spaltenBreite(gesamt: Double, spalten: Int, beschriftung: Double) -> Double {
        max((gesamt - beschriftung) / Double(max(spalten, 1)), 40)
    }

    // MARK: Computer

    /// Entscheidung je Stufe: leicht = einfach, schwer = gut, mittel = gut mit Aussetzern (`patzer` der Entscheidungen einfach).
    static func entscheide(_ state: GameState, stufe: ComputerStufe, zufall: Double, random: () -> Double = { Double.random(in: 0..<1) }) -> Action {
        let level: ComputerLevel
        switch stufe {
        case .leicht: level = .einfach
        case .mittel: level = zufall < patzer(stufe) ? .einfach : .gut
        case .schwer: level = .gut
        }
        return ComputerPlayer.decide(state, level: level, random: random)
    }

    static func patzer(_ stufe: ComputerStufe) -> Double {
        switch stufe {
        case .leicht: 1
        case .mittel: 0.5
        case .schwer: 0
        }
    }

    static func level(_ stufe: ComputerStufe) -> ComputerLevel { stufe == .leicht ? .einfach : .gut }

    // MARK: Ende

    /// Das Ende einer Partie, unabhängig vom SpielRahmen (der nur auf dem iPhone übersetzt wird).
    struct Ende: Equatable {
        var reihenfolge: [String]
        var punkte: [String]
        var plaetze: [Int]
        var info: String?
    }

    /// Ende für den Rahmen: nach Gesamtpunkten, gleiche Punkte teilen den Platz. Solo: Platz entfällt in der Anzeige des Rahmens.
    static func ende(_ r: GameRecord) -> Ende {
        let summen = r.players.indices.map { r.total($0) }
        let ordnung = r.players.indices.sorted { (summen[$0], -$0) > (summen[$1], -$1) }
        let plaetze = ordnung.map { i in 1 + summen.filter { $0 > summen[i] }.count }
        let yachts = r.players.indices.reduce(0) { $0 + r.yachts($1) }
        var info = r.state.rules.variant.titel
        if r.settings.dailyKey != nil { info += " · " + String(localized: "Tageswürfel") }   // 1.0 (P5)
        if yachts > 0 { info += " · " + (yachts == 1 ? String(localized: "1 × Yacht") : String(localized: "\(yachts) × Yacht")) }
        return Ende(reihenfolge: ordnung.map { r.players[$0].name }, punkte: ordnung.map { "\(summen[$0])" }, plaetze: plaetze, info: info)
    }

    // MARK: Solo-Ziel

    /// Schlüssel der Bestmarke je Wertung.
    static func rekordSchluessel(_ v: Variant) -> String { "rekord.\(v.rawValue)" }

    /// Neue Bestmarke? (Solo, mehr Punkte als der bisherige Rekord; ohne Rekord zählt die erste Partie nicht als „neu“.)
    static func istNeuerRekord(punkte: Int, bisher: Int?) -> Bool { bisher.map { punkte > $0 } ?? false }
}
