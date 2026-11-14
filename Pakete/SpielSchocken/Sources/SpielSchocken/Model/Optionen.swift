// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Hausregeln (SPEZIFIKATION Abschnitt 7). Fehlende Schlüssel beim Laden bekommen den Standardwert.
struct Optionen: Codable, Hashable {
    enum Herauslegen: String, Codable { case einsen, beliebig }
    enum Spiellaenge: String, Codable { case partie, haelfte }

    var jule = false
    var herauslegen = Herauslegen.einsen
    var sechsenUmdrehen = true
    var deckel = 13
    var spiellaenge = Spiellaenge.partie
    /// Schock aus (drei Einsen) gibt dem Verlierer der Runde alle Deckel und beendet die Hälfte sofort (Standard).
    /// Aus: Schock aus zählt wie ein Wurf mit so vielen Deckeln, wie pro Hälfte im Spiel sind, und die Hälfte läuft weiter.
    var schockAusEndet = true

    static let standard = Optionen()

    init(jule: Bool = false, herauslegen: Herauslegen = .einsen, sechsenUmdrehen: Bool = true,
         deckel: Int = 13, spiellaenge: Spiellaenge = .partie, schockAusEndet: Bool = true) {
        self.jule = jule
        self.herauslegen = herauslegen
        self.sechsenUmdrehen = sechsenUmdrehen
        self.deckel = deckel
        self.spiellaenge = spiellaenge
        self.schockAusEndet = schockAusEndet
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        jule = try c.decodeIfPresent(Bool.self, forKey: .jule) ?? false
        herauslegen = (try? c.decodeIfPresent(Herauslegen.self, forKey: .herauslegen)) ?? .einsen
        sechsenUmdrehen = try c.decodeIfPresent(Bool.self, forKey: .sechsenUmdrehen) ?? true
        deckel = try c.decodeIfPresent(Int.self, forKey: .deckel) ?? 13
        spiellaenge = (try? c.decodeIfPresent(Spiellaenge.self, forKey: .spiellaenge)) ?? .partie
        schockAusEndet = try c.decodeIfPresent(Bool.self, forKey: .schockAusEndet) ?? true
    }
}
