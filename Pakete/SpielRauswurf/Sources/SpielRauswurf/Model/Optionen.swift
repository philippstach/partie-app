// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Hausregeln (SPEZIFIKATION Abschnitt 6). Fehlende Schlüssel beim Laden bekommen den Standardwert.
struct Optionen: Codable, Hashable, Sendable {
    enum Spielende: String, Codable, Sendable { case erster, alle }

    var rausPflicht = true
    var startfeldRaeumen = true
    var schlagpflicht = false
    var dreiVersuche = true
    var sechsNochmal = true
    var zielUeberspringen = true
    var spielende = Spielende.erster
    /// Figuren je Spieler: 4, 3 oder 2 (kurze Partie).
    var figuren = 4
    /// Zu Beginn steht Figur 0 jedes Spielers schon auf dem Startfeld.
    var startMitFigur = false
    /// Aus: Niemand wird geschlagen, fremd besetzte Felder sind gesperrt (Kinder-Regel).
    var rauswerfen = true
    /// Teams 2 gegen 2 (nur mit 4 Spielern): gegenübersitzende Spieler (1+3, 2+4) gewinnen gemeinsam,
    /// sobald beide alle Figuren im Ziel haben. Ein fertiger Spieler setzt aus, sein Partner spielt weiter.
    var teams = false

    static let standard = Optionen()

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let std = Optionen()
        rausPflicht = try c.decodeIfPresent(Bool.self, forKey: .rausPflicht) ?? std.rausPflicht
        startfeldRaeumen = try c.decodeIfPresent(Bool.self, forKey: .startfeldRaeumen) ?? std.startfeldRaeumen
        schlagpflicht = try c.decodeIfPresent(Bool.self, forKey: .schlagpflicht) ?? std.schlagpflicht
        dreiVersuche = try c.decodeIfPresent(Bool.self, forKey: .dreiVersuche) ?? std.dreiVersuche
        sechsNochmal = try c.decodeIfPresent(Bool.self, forKey: .sechsNochmal) ?? std.sechsNochmal
        zielUeberspringen = try c.decodeIfPresent(Bool.self, forKey: .zielUeberspringen) ?? std.zielUeberspringen
        spielende = (try? c.decodeIfPresent(Spielende.self, forKey: .spielende)) ?? std.spielende
        figuren = min(4, max(2, try c.decodeIfPresent(Int.self, forKey: .figuren) ?? std.figuren))
        startMitFigur = try c.decodeIfPresent(Bool.self, forKey: .startMitFigur) ?? std.startMitFigur
        rauswerfen = try c.decodeIfPresent(Bool.self, forKey: .rauswerfen) ?? std.rauswerfen
        teams = try c.decodeIfPresent(Bool.self, forKey: .teams) ?? std.teams
    }
}
