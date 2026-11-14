// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern

/// Bauplan RL-K: Hängt die erzeugten Lesetexte (`RegelLeseTabelle`) an die Seite „Alle Regeln lesen“. Nur Deutsch, bis die Texte übersetzt sind.
enum RegelLeseAnbindung {
    static func installieren() {
        RegelLeseKatalog.lieferant = { id in RegelTexteNeu.aktiv ? RegelLeseTabelle.eintraege[id] : nil }
    }
}
