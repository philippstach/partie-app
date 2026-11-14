// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Der gespeicherte Spielstand: Zustand plus Zustand der Würfelquelle.
struct Spielstand: Codable, Equatable {
    static let aktuelleVersion = 1

    var formatVersion = Spielstand.aktuelleVersion
    var zustand: Spielzustand
    var quelle: SeedQuelle

    init(zustand: Spielzustand, quelle: SeedQuelle) {
        self.zustand = zustand
        self.quelle = quelle
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        formatVersion = try c.decodeIfPresent(Int.self, forKey: .formatVersion) ?? 1
        zustand = try c.decode(Spielzustand.self, forKey: .zustand)
        quelle = try c.decodeIfPresent(SeedQuelle.self, forKey: .quelle) ?? SeedQuelle(seed: UInt64.random(in: .min ... .max))
    }
}

/// Eine JSON-Datei, atomar geschrieben.
struct GameRepository {
    let url: URL

    static var standard: GameRepository {
        return GameRepository(url: SpielDatei.standardOrdner.appending(path: "spielstand.json"))
    }

    func laden() -> Spielstand? {
        SpielDatei.laden(Spielstand.self, url: url, defektName: "spielstand-defekt.json") { $0.zustand.istStimmig }
    }

    func speichern(_ stand: Spielstand) throws {
        try SpielDatei.speichern(stand, url: url)
    }

    func loeschen() {
        SpielDatei.loeschen(url: url)
    }
}
