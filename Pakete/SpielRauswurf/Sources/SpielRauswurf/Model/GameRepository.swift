// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Der gespeicherte Spielstand. Fehlende Felder beim Laden bekommen Standardwerte.
struct Spielstand: Codable, Equatable, Sendable {
    static let aktuelleVersion = 1

    var formatVersion = Spielstand.aktuelleVersion
    var zustand: Spielzustand
    /// Spielzeit der laufenden Partie in Sekunden (Pausen über 2 Minuten zählen nicht); gehört nicht zum Spielzustand,
    /// damit „Rückgängig“ und der Vergleich von Zuständen nicht von der Uhr abhängen.
    var dauerSekunden = 0.0

    init(zustand: Spielzustand, dauerSekunden: Double = 0) {
        self.zustand = zustand
        self.dauerSekunden = dauerSekunden
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        formatVersion = try c.decodeIfPresent(Int.self, forKey: .formatVersion) ?? 1
        zustand = try c.decode(Spielzustand.self, forKey: .zustand)
        dauerSekunden = try c.decodeIfPresent(Double.self, forKey: .dauerSekunden) ?? 0
    }
}

/// Eine JSON-Datei, atomar geschrieben.
struct GameRepository: Sendable {
    let url: URL

    static var standard: GameRepository {
        return GameRepository(url: SpielDatei.standardOrdner.appending(path: "spielstand.json"))
    }

    func laden() -> Spielstand? {
        SpielDatei.laden(Spielstand.self, url: url, defektName: "spielstand.defekt.json") { $0.zustand.istPlausibel }
    }

    func speichern(_ stand: Spielstand) throws {
        try SpielDatei.speichern(stand, url: url)
    }

    func loeschen() {
        SpielDatei.loeschen(url: url)
    }
}
