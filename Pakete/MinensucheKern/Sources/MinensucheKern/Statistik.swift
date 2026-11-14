// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

public struct StufenStatistik: Codable, Equatable, Sendable {
    public var gespielt = 0
    public var gewonnen = 0
    public var besteZeit: TimeInterval? = nil
    public var serie = 0
    public var besteSerie = 0
    public init() {}

    private enum CodingKeys: String, CodingKey { case gespielt, gewonnen, besteZeit, serie, besteSerie }

    /// Fehlende Felder bekommen Standardwerte (neue Felder in späteren Versionen löschen keine alte Statistik)
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gespielt = (try? c.decodeIfPresent(Int.self, forKey: .gespielt)) ?? 0
        gewonnen = (try? c.decodeIfPresent(Int.self, forKey: .gewonnen)) ?? 0
        besteZeit = (try? c.decodeIfPresent(TimeInterval.self, forKey: .besteZeit)) ?? nil
        serie = (try? c.decodeIfPresent(Int.self, forKey: .serie)) ?? 0
        besteSerie = (try? c.decodeIfPresent(Int.self, forKey: .besteSerie)) ?? 0
    }
}

public struct Statistik: Codable, Equatable, Sendable {
    public var stufen: [Stufe: StufenStatistik] = [:]
    /// Tagesrätsel: letzter gelöster Tag als jjjjmmtt und Folge gelöster Tage.
    public var letzterTag: Int? = nil
    public var tagesSerie = 0
    public var tageGeloest = 0
    public init() {}

    private enum CodingKeys: String, CodingKey { case stufen, letzterTag, tagesSerie, tageGeloest }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        stufen = (try? c.decodeIfPresent([Stufe: StufenStatistik].self, forKey: .stufen)) ?? [:]
        letzterTag = (try? c.decodeIfPresent(Int.self, forKey: .letzterTag)) ?? nil
        tagesSerie = (try? c.decodeIfPresent(Int.self, forKey: .tagesSerie)) ?? 0
        tageGeloest = (try? c.decodeIfPresent(Int.self, forKey: .tageGeloest)) ?? 0
    }

    public func fuer(_ s: Stufe) -> StufenStatistik { stufen[s] ?? StufenStatistik() }

    /// Eine beendete Partie verbuchen. Neue Bestzeit → wahr.
    @discardableResult
    /// `bestzeitMoeglich: false` (1.0 M3, nach der zweiten Chance): Sieg und Serie zählen, die Zeit nicht als Bestzeit.
    public mutating func verbuche(stufe: Stufe, gewonnen: Bool, dauer: TimeInterval, bestzeitMoeglich: Bool = true) -> Bool {
        var e = fuer(stufe)
        e.gespielt += 1
        var rekord = false
        if gewonnen {
            e.gewonnen += 1
            e.serie += 1
            e.besteSerie = max(e.besteSerie, e.serie)
            if bestzeitMoeglich, e.besteZeit == nil || dauer < e.besteZeit! { e.besteZeit = dauer; rekord = true }
        } else {
            e.serie = 0
        }
        stufen[stufe] = e
        return rekord
    }

    /// Serie nur anzeigen, wenn sie noch lebt: letzter gelöster Tag ist heute oder gestern (sonst ist sie gerissen).
    public func aktuelleSerie(heute: Int, gestern: Int) -> Int {
        (letzterTag == heute || letzterTag == gestern) ? tagesSerie : 0
    }

    /// Tagesrätsel gelöst. `tag` = jjjjmmtt, `gestern` = jjjjmmtt des Vortags (Aufrufer rechnet den Kalender).
    public mutating func verbucheTag(tag: Int, gestern: Int) {
        guard letzterTag != tag else { return }
        tagesSerie = (letzterTag == gestern) ? tagesSerie + 1 : 1
        letzterTag = tag
        tageGeloest += 1
    }
}

/// Atomares Speichern als JSON; fehlende oder kaputte Datei → Standardwert.
public enum JSONSpeicher {
    public static func laden<T: Decodable>(_ typ: T.Type, url: URL) -> T? {
        guard let daten = try? Data(contentsOf: url) else { return nil }
        do { return try JSONDecoder().decode(T.self, from: daten) } catch {
            // Nicht lesbar: beiseitelegen, damit der nächste Speichervorgang die Datei nicht überschreibt
            let ziel = url.deletingPathExtension().appendingPathExtension("kaputt.json")
            try? FileManager.default.removeItem(at: ziel)
            try? FileManager.default.moveItem(at: url, to: ziel)
            return nil
        }
    }
    public static func sichern<T: Encodable>(_ wert: T, url: URL) {
        guard let daten = try? JSONEncoder().encode(wert) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? daten.write(to: url, options: .atomic)
    }
}
