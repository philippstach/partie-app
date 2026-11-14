// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Namen für den Start einer Partie: Leere bekommen „Spieler n“, gleiche Namen werden durchnummeriert,
/// damit Banner („Anna wirft Anna raus“), Statistik und Verlauf eindeutig bleiben.
enum Spielernamen {
    /// Ist das der Standardname „Ich“ (in allen Sprachen)? Dann gilt die Ich-Form: „Ich bin dran“.
    static func istIch(_ name: String) -> Bool {
        [L("name.ich"), "Ich", "Me", "Yo", "Moi"].contains(name.trimmingCharacters(in: .whitespaces))
    }

    /// „Anna ist dran“ bzw. „Ich bin dran“
    static func dranText(_ name: String) -> String { istIch(name) ? L("hinweis.dran.ich") : L("hinweis.dran", name) }

    /// Anzeige eines gespeicherten Namens: Standardnamen („Spieler 2“, „Player 2“ …) folgen der aktuellen Sprache
    static func angezeigt(_ name: String) -> String {
        let teile = name.split(separator: " ")
        if teile.count == 2, ["Spieler", "Player", "Jugador", "Joueur"].contains(String(teile[0])), let n = Int(teile[1]) {
            return L("setup.spielerNr", n)
        }
        return name
    }

    /// Feste Namen der Computergegner (Start und Neue Partie)
    static let computer = ["Ben", "Clara", "David", "Emil"]

    static func bereinigt(_ namen: [String], leer: (Int) -> String) -> [String] {
        var benutzt = Set<String>()
        return namen.enumerated().map { i, roh in
            let basis = roh.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = basis.isEmpty ? leer(i + 1) : basis
            var kandidat = name
            var n = 2
            while !benutzt.insert(kandidat.lowercased()).inserted {
                kandidat = "\(name) \(n)"
                n += 1
            }
            return kandidat
        }
    }
}
