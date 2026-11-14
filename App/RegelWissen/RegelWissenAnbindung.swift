// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import SpieleKern
import SpielMauMau

/// KI-3: Hängt die erzeugten Regeltexte (`RegelWissenTabelle`) an den `SpielRahmen` („Frag nach den Regeln“).
/// Beim App-Start `RegelWissenAnbindung.installieren()` aufrufen. Der Rahmen zeigt Knopf und Menüzeile nur, wenn das Gerät
/// Apple Intelligence kann (iOS 26, Deutsch) und es zum Spiel einen Eintrag gibt.
enum RegelWissenAnbindung {
    static func installieren() {
        RegelWissenKatalog.lieferant = { id in wissen(id) }
    }

    /// `aktiveRegeln` kommt je Spiel aus den eingestellten Hausregeln; wo es noch keine Auskunft gibt, bleibt es leer
    /// (dann sagt das Chat-Blatt auch nichts von Hausregeln).
    static func wissen(_ id: String) -> (any RegelWissen)? {
        guard let e = RegelWissenTabelle.eintraege[id] else { return nil }
        return RegelWissenEinfach(spielID: id, name: e.name, abschnitte: RegelWissenMarkdown.abschnitte(aus: e.quelle),
                                  aktiveRegeln: aktiveRegeln(id), beispielfragen: e.fragen)
    }

    private static func aktiveRegeln(_ id: String) -> String {
        switch id {
        case "maumau": return MauMauRegelAuskunft.aktiveRegeln()
        default: return ""
        }
    }
}
