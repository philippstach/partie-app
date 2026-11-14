// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Würfelstatistik je Spieler (SPEZIFIKATION 11.1): wie oft jede Zahl fiel und die längste Durststrecke ohne 6.
/// Wird immer aus dem Verlauf berechnet (und dem laufenden Spielzug), so zählt ein zurückgenommener Wurf nie mit.
struct WuerfelZahlen: Equatable, Codable, Sendable {
    /// `augen[0]` = Einsen … `augen[5]` = Sechsen
    var augen = [Int](repeating: 0, count: 6)
    /// Längste Folge eigener Würfe ohne 6 (über Spielzüge hinweg)
    var ohneSechs = 0
    /// davon mit einem echten Würfel eingetippt
    var eingetippt = 0

    var wuerfe: Int { augen.reduce(0, +) }
}

enum Wuerfelstatistik {
    /// Zahlen je Spieler-Index. Der laufende Spielzug zählt mit (auch ein schon gewürfelter, noch nicht gezogener Wurf).
    static func zaehle(_ partie: Partie) -> [WuerfelZahlen] {
        var folgen = Array(repeating: [Int](), count: partie.spielerzahl)
        for e in partie.verlauf { folgen[e.spieler] += e.wuerfe.map(\.augen) }
        let sp = partie.spielzug
        if !partie.vorbei {
            folgen[sp.spieler] += sp.wuerfe.map(\.augen)
            if sp.stand == .wahl, let w = sp.augen { folgen[sp.spieler].append(w) }
        }
        var eingetippt = Array(repeating: 0, count: partie.spielerzahl)
        for e in partie.verlauf { eingetippt[e.spieler] += e.eingetippt }
        if !partie.vorbei { eingetippt[sp.spieler] += sp.eingetippt }
        return folgen.enumerated().map { i, folge in
            var z = WuerfelZahlen()
            z.eingetippt = eingetippt[i]
            var lauf = 0
            for w in folge {
                z.augen[w - 1] += 1
                if w == 6 { lauf = 0 } else { lauf += 1; z.ohneSechs = max(z.ohneSechs, lauf) }
            }
            return z
        }
    }
}
