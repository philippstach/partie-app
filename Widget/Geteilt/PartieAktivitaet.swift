// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import ActivityKit

// E5: Live Activity „Partie läuft“ (Sperrbildschirm, Dynamic Island). Diese Datei gehört zur App UND zur Widget-Erweiterung.
// Die App startet und aktualisiert die Aktivität (`AktivitaetVerwalter`), die Widget-Erweiterung zeichnet sie.

struct PartieAktivitaet: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Wer gerade dran ist (nil, wenn das Spiel es nicht meldet).
        var amZug: String?
        /// Kurzer Stand, z. B. „Anna 12 · Ben 8“ (nil, wenn nicht gemeldet).
        var stand: String?
    }

    var spielID: String
    var spielName: String
    var farbeHex: UInt32
    var spieler: [String]
    var beginn: Date

    /// Link, der das Spiel wieder öffnet.
    var link: URL? { URL(string: "partie://spiel/\(spielID)") }
}
