// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import KlarGlas

// Daten, die die App für Widgets und Steuerelemente in die gemeinsame App Group schreibt (E6, Build 4).
// Diese Datei gehört zur App UND zur Widget-Erweiterung (project.yml). Die Tagesrätsel-Serien schreiben die Spiele selbst
// (Schlüssel „<Präfix>.serie“ / „<Präfix>.letzterTag“); hier liegen „zuletzt gespielt“, Bestleistungen und Gesamtzahlen.

enum PartieGeteilt {
    static let gruppe = "group.de.philippstach.spiele"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: gruppe) }

    /// Das Spiel, das zuletzt geöffnet wurde (Name und Farbe, damit das Widget ohne Spielkatalog auskommt).
    struct Zuletzt: Codable, Equatable {
        var id: String
        var name: String
        var farbeHex: UInt32
        var datum: Date
    }

    /// Bestleistung (höchste Punktzahl) in einem Spiel.
    struct Rekord: Codable, Equatable {
        var id: String
        var name: String
        var farbeHex: UInt32
        var punkte: Int
        var datum: Date
    }

    struct Summen: Codable, Equatable {
        var partien: Int = 0
        var siege: Int = 0
    }

    // MARK: Lesen (Widget und App)

    static func zuletzt() -> Zuletzt? {
        guard let d = defaults?.data(forKey: "geteilt.zuletzt"), let z = try? JSONDecoder().decode(Zuletzt.self, from: d) else { return nil }
        return sichtbar(z, gesperrt: gesperrt())
    }

    static func rekorde() -> [Rekord] {
        guard let d = defaults?.data(forKey: "geteilt.rekorde"), let r = try? JSONDecoder().decode([Rekord].self, from: d) else { return [] }
        return sichtbar(r, gesperrt: gesperrt()).sorted { $0.datum > $1.datum }
    }

    // MARK: Design (Designwechsel: die App spiegelt die Auswahl, die Widgets lesen sie)

    /// Schlüssel der Design-Auswahl in der App Group (derselbe wie in `UserDefaults.standard` der App).
    static let designSchluessel = "design.art"

    /// DER Standard: das Design, das gilt, solange nichts gewählt ist (App, Einführung und Widgets). Zum Umstellen nur diese Zeile ändern
    /// (`.tinte` oder `.salon`; Stand 11.11.2026: Tinte, Entscheidung Salon offen).
    static let standardDesign: DesignArt = .tinte

    /// Das gewählte Design als Rohwert („klar“, „tinte“, „salon“); ohne Eintrag der Standard.
    static func design() -> String { defaults?.string(forKey: designSchluessel) ?? standardDesign.rawValue }

    @discardableResult
    static func designSchreiben(_ art: String) -> Bool {
        guard let defaults, design() != art else { return false }
        defaults.set(art, forKey: designSchluessel)
        return true
    }

    // MARK: Kinder-Modus (Widgets blenden gesperrte Spiele aus)

    /// Spiele, die im Kinder-Modus gesperrt sind (leer, wenn der Kinder-Modus aus ist). Die App schreibt, die Widgets lesen.
    static func gesperrt() -> Set<String> {
        Set((defaults?.string(forKey: "geteilt.gesperrt") ?? "").split(separator: ",").map(String.init))
    }

    @discardableResult
    static func gesperrtSchreiben(_ ids: Set<String>) -> Bool {
        guard let defaults, gesperrt() != ids else { return false }
        defaults.set(ids.sorted().joined(separator: ","), forKey: "geteilt.gesperrt")
        return true
    }

    static func sichtbar(_ z: Zuletzt?, gesperrt: Set<String>) -> Zuletzt? {
        guard let z, !gesperrt.contains(z.id) else { return nil }
        return z
    }

    static func sichtbar(_ r: [Rekord], gesperrt: Set<String>) -> [Rekord] { r.filter { !gesperrt.contains($0.id) } }

    static func summen() -> Summen {
        guard let d = defaults?.data(forKey: "geteilt.summen"), let s = try? JSONDecoder().decode(Summen.self, from: d) else { return Summen() }
        return s
    }

    /// Letzter gelöster Tag und Serie eines Tagesrätsels (Präfix wie bei `TagesSerieWidget.melden` in den Spielen).
    static func tag(praefix: String) -> (serie: Int, letzterTag: String) {
        let d = defaults
        return (d?.integer(forKey: praefix + ".serie") ?? 0, d?.string(forKey: praefix + ".letzterTag") ?? "")
    }

    // MARK: Schreiben (nur App)

    /// Gibt `true` zurück, wenn sich etwas geändert hat (dann Widgets neu laden).
    @discardableResult
    static func zuletztSchreiben(_ neu: Zuletzt) -> Bool {
        guard let defaults else { return false }
        if let alt = zuletzt(), alt.id == neu.id, alt.name == neu.name, alt.farbeHex == neu.farbeHex,
           Calendar.current.isDate(alt.datum, inSameDayAs: neu.datum) { return false }
        guard let d = try? JSONEncoder().encode(neu) else { return false }   // nie nil schreiben (würde den Schlüssel löschen)
        defaults.set(d, forKey: "geteilt.zuletzt")
        return true
    }

    @discardableResult
    static func rekordSchreiben(_ neu: Rekord) -> Bool {
        guard let defaults else { return false }
        var alle = rekorde().filter { $0.id != neu.id }
        if let alt = rekorde().first(where: { $0.id == neu.id }), alt.punkte == neu.punkte, alt.name == neu.name { return false }
        alle.append(neu)
        guard let d = try? JSONEncoder().encode(alle) else { return false }   // nie nil schreiben (würde den Schlüssel löschen)
        defaults.set(d, forKey: "geteilt.rekorde")
        return true
    }

    @discardableResult
    static func summenSchreiben(_ neu: Summen) -> Bool {
        guard let defaults, summen() != neu else { return false }
        guard let d = try? JSONEncoder().encode(neu) else { return false }   // nie nil schreiben (würde den Schlüssel löschen)
        defaults.set(d, forKey: "geteilt.summen")
        return true
    }
}

/// Spiele mit Tagesrätsel: Kennung in der Sammlung, Präfix der Serien-Schlüssel, Kurzname, Farbe (Mockup-Hex).
/// Gemeinsam für Widget und App („Tagesrätsel starten“).
struct TagesSpielInfo {
    let id: String
    let praefix: String
    let name: String
    let farbeHex: UInt32
    /// Tage, die der letzte gelöste Tag zurückliegen darf, damit die Serie lebt (Sudoku: Ruhetag).
    let toleranz: Int

    static let alle: [TagesSpielInfo] = [
        .init(id: "minensuche", praefix: "minensuche", name: "Minensuche", farbeHex: Familienfarbe.schiefer.flaeche, toleranz: 1),
        .init(id: "sudoku", praefix: "sudoku", name: "Sudoku", farbeHex: Familienfarbe.blau.flaeche, toleranz: 1),
        .init(id: "solitaer", praefix: "solitaer", name: "Solitär", farbeHex: Familienfarbe.gruen.flaeche, toleranz: 1),
        .init(id: "viererreihe", praefix: "vier", name: "Viererreihe", farbeHex: Familienfarbe.rot.flaeche, toleranz: 1),
        .init(id: "galgenmaennchen", praefix: "galgen", name: "Galgenmännchen", farbeHex: Familienfarbe.violett.flaeche, toleranz: 1),
        .init(id: "wortpfeil", praefix: "kreuzwort", name: "Kreuzworträtsel", farbeHex: Familienfarbe.pink.flaeche, toleranz: 1),
        .init(id: "farbraetsel", praefix: "farbraetsel", name: "Farbrätsel", farbeHex: Familienfarbe.limette.flaeche, toleranz: 1),
    ]
}
