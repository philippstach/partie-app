// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Die zuletzt gestartete Runde (Spieler mit Farbe, Art und Würfelart sowie die Regeln), für „Gleiche Runde wie zuletzt“
/// und die Vorbelegung in „Neue Partie“.
struct LetzteRunde: Codable, Equatable, Sendable {
    var spieler: [Spieler]
    var optionen: Optionen

    private static let schluessel = "letzteRundeLudo"

    static func laden(_ defaults: UserDefaults = .standard) -> LetzteRunde? {
        guard let daten = defaults.data(forKey: schluessel),
              let r = try? JSONDecoder().decode(LetzteRunde.self, from: daten), r.spieler.count >= 2 else { return nil }
        return r
    }

    static func speichern(spieler: [Spieler], optionen: Optionen, _ defaults: UserDefaults = .standard) {
        let r = LetzteRunde(spieler: spieler.sorted { $0.sitz < $1.sitz }, optionen: optionen)
        if let daten = try? JSONEncoder().encode(r) { defaults.set(daten, forKey: schluessel) }
    }

    /// Kurzer Text für den Knopf: die Namen.
    var namen: String { spieler.map { Spielernamen.angezeigt($0.name) }.joined(separator: ", ") }
}
