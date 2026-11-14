// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Heuristik für mittel und stark (SPEZIFIKATION 7.2): 69 Fenster zu je 4 Feldern plus Mittelspalte.
enum Bewertung {
    /// Alle Fenster als Zellen.
    static let fenster: [[Zelle]] = {
        var f: [[Zelle]] = []
        for s in 0..<Partie.spalten {
            for z in 0..<Partie.zeilen {
                for (ds, dz) in Partie.richtungen {
                    let zellen = (0..<4).map { Zelle(spalte: s + $0 * ds, zeile: z + $0 * dz) }
                    if zellen.allSatisfy({ $0.spalte >= 0 && $0.spalte < Partie.spalten && $0.zeile >= 0 && $0.zeile < Partie.zeilen }) {
                        f.append(zellen)
                    }
                }
            }
        }
        return f
    }()

    /// Aus Sicht von `spieler`. Es gilt immer `wert(b, 1) == -wert(b, 2)`.
    static func wert(_ brett: [[Int]], fuer spieler: Int) -> Int {
        let gegner = 3 - spieler
        var w = 0
        for zellen in fenster {
            var eigen = 0, fremd = 0
            for c in zellen {
                let v = brett[c.spalte][c.zeile]
                if v == spieler { eigen += 1 } else if v == gegner { fremd += 1 }
            }
            if eigen > 0 && fremd > 0 { continue }
            switch (eigen, fremd) {
            case (3, _): w += 5
            case (2, _): w += 2
            case (_, 3): w -= 5
            case (_, 2): w -= 2
            default: break
            }
        }
        for z in 0..<Partie.zeilen {
            if brett[3][z] == spieler { w += 3 } else if brett[3][z] == gegner { w -= 3 }
        }
        return w
    }

    static func wert(_ partie: Partie, fuer spieler: Int) -> Int { wert(partie.brett, fuer: spieler) }
}
