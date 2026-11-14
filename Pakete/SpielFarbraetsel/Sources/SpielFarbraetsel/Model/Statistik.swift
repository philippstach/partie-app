// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Bestwerte je Stufe und erledigte Tagesrätsel.
struct Statistik: Equatable, Codable, Sendable {
    struct StufenWerte: Equatable, Codable, Sendable {
        var geloest = 0
        var bestZuege: Int?
        var bestSekunden: Double?
    }

    var stufen: [String: StufenWerte] = [:]
    /// Tage („2026-11-03“), an denen das Tagesrätsel gelöst wurde.
    var tage: Set<String> = []

    func werte(_ stufe: Stufe) -> StufenWerte { stufen[stufe.rawValue] ?? StufenWerte() }
    var gesamtGeloest: Int { stufen.values.reduce(0) { $0 + $1.geloest } }

    /// Trägt eine gelöste Partie ein. Gibt zurück, ob es ein neuer Bestwert (Züge) ist.
    @discardableResult
    mutating func eintragen(stufe: Stufe, zuege: Int, sekunden: Double, tag: String?, hilfen: Int = 0) -> Bool {
        var w = werte(stufe)
        w.geloest += 1
        // Mit Tipps erreicht man immer den kleinsten Zugwert: Bestwerte zählen nur für Partien ohne Tipp
        let zaehltFuerBestwert = hilfen == 0
        let neuerBest = zaehltFuerBestwert && (w.bestZuege.map { zuege < $0 } ?? true)
        if neuerBest { w.bestZuege = zuege }
        if zaehltFuerBestwert, w.bestSekunden.map({ sekunden < $0 }) ?? true { w.bestSekunden = sekunden }
        stufen[stufe.rawValue] = w
        if let tag { tage.insert(tag) }
        return neuerBest
    }

    /// Anzahl aufeinanderfolgender Tage bis `heute` (oder bis gestern, wenn heute noch offen ist).
    func serie(heute: Date, kalender: Calendar = .current) -> Int {
        var tag = heute
        if !tage.contains(Tageskennung.text(tag, kalender)) {
            guard let gestern = kalender.date(byAdding: .day, value: -1, to: tag) else { return 0 }
            tag = gestern
        }
        var n = 0
        while tage.contains(Tageskennung.text(tag, kalender)) {
            n += 1
            guard let davor = kalender.date(byAdding: .day, value: -1, to: tag) else { break }
            tag = davor
        }
        return n
    }

    /// Sieben Einträge Mo…So der Woche von `heute`: Tagesrätsel gelöst?
    func woche(heute: Date, kalender: Calendar = .current) -> [Bool] {
        var kal = kalender
        kal.firstWeekday = 2
        guard let start = kal.dateInterval(of: .weekOfYear, for: heute)?.start else { return Array(repeating: false, count: 7) }
        return (0..<7).map { i in
            guard let tag = kal.date(byAdding: .day, value: i, to: start) else { return false }
            return tage.contains(Tageskennung.text(tag, kal))
        }
    }
}

enum Tageskennung {
    static func text(_ datum: Date, _ kalender: Calendar = .current) -> String {
        let k = kalender.dateComponents([.year, .month, .day], from: datum)
        return String(format: "%04d-%02d-%02d", k.year ?? 0, k.month ?? 0, k.day ?? 0)
    }

    /// Fester Seed je Kalendertag, auf allen Geräten gleich.
    static func seed(_ datum: Date, _ kalender: Calendar = .current) -> UInt64 {
        let k = kalender.dateComponents([.year, .month, .day], from: datum)
        let zahl = UInt64((k.year ?? 0) * 10_000 + (k.month ?? 0) * 100 + (k.day ?? 0))
        return zahl &* 2_654_435_761 &+ 12_345
    }
}
