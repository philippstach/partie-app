// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import KlarGlas
import SpieleKern
import Foundation

/// Wer einen Platz spielt (SPEZIFIKATION Abschnitt 7).
enum Strategie: String, Codable, CaseIterable, Sendable {
    case mensch, einfach, gut, lieb
}

/// Der Computer entscheidet nur, welchen der erlaubten Züge er nimmt. Nur ganze Zahlen, kein Zufall.
enum Computer {
    /// Könnte ein Gegner im nächsten Wurf auf dieses absolute Feld ziehen?
    static func bedroht(_ lage: Lage, _ p: Int, _ absFeld: Int) -> Bool {
        for (q, fs) in lage.figuren.enumerated() where q != p {
            let sq = lage.sitze[q]
            for r in fs {
                if (0 ..< Brettmass.lauf).contains(r) {
                    let d = (((absFeld - feld(sq, r)) % Brettmass.lauf) + Brettmass.lauf) % Brettmass.lauf
                    if (1 ... 6).contains(d) && r + d < Brettmass.lauf { return true }
                } else if r == Brettmass.haus && absFeld == feld(sq, 0) {
                    return true
                }
            }
        }
        return false
    }

    /// Punkte eines Zugs für „gut“: Schlagen > ins Ziel > raus > sicher ziehen > Rest.
    static func bewerteGut(_ lage: Lage, _ p: Int, _ z: Zug) -> Int {
        let sp = lage.sitze[p]
        var nachher = lage
        nachher.fuehreAus(p, z)
        let sicher = z.nach >= Brettmass.lauf || !bedroht(nachher, p, feld(sp, z.nach))
        if z.schlaegt != nil, let b = lage.besetzer(feld(sp, z.nach)) {
            return 3000 + (sicher ? 100 : 0) + lage.figuren[b.spieler][b.figur]
        }
        if (0 ..< Brettmass.lauf).contains(z.von) && z.nach >= Brettmass.lauf { return 2000 + z.von }
        if z.von == Brettmass.haus { return 1500 }
        if z.von < Brettmass.lauf && sicher { return 1000 + z.von }
        return z.von
    }

    static func entscheideEinfach(_ lage: Lage, _ zuege: [Zug]) -> Zug {
        if let z = zuege.first(where: { $0.schlaegt != nil }) { return z }
        if let z = zuege.first(where: { $0.von == Brettmass.haus }) { return z }
        let k = lage.figuren.reduce(0) { $0 + $1.reduce(0) { $0 + $1 + 1 } }
        return zuege[k % zuege.count]
    }

    static func entscheideGut(_ lage: Lage, _ p: Int, _ zuege: [Zug]) -> Zug {
        var beste = zuege[0]
        var wert = Int.min
        for z in zuege {
            let v = bewerteGut(lage, p, z)
            if v > wert { beste = z; wert = v }      // bei Gleichstand gewinnt der frühere Zug
        }
        return beste
    }

    /// „Lieb“ (SPEZIFIKATION 7.3): wie „gut“, wirft aber Menschen nur raus, wenn kein anderer Zug erlaubt ist.
    static func bewerteLieb(_ lage: Lage, _ p: Int, _ z: Zug, menschen: Set<Int>) -> Int {
        if let opfer = z.schlaegt, menschen.contains(opfer) { return -1000 + z.von }
        return bewerteGut(lage, p, z)
    }

    static func entscheideLieb(_ lage: Lage, _ p: Int, _ zuege: [Zug], menschen: Set<Int>) -> Zug {
        var beste = zuege[0]
        var wert = Int.min
        for z in zuege {
            let v = bewerteLieb(lage, p, z, menschen: menschen)
            if v > wert { beste = z; wert = v }
        }
        return beste
    }

    /// `menschen`: Spieler-Indizes der Menschen (nur für „lieb“ wichtig; wird nicht gespeichert).
    static func entscheide(_ strategie: Strategie, _ lage: Lage, _ p: Int, _ zuege: [Zug], menschen: Set<Int> = []) -> Zug {
        if zuege.count == 1 { return zuege[0] }
        switch strategie {
        case .einfach, .mensch: return entscheideEinfach(lage, zuege)
        case .gut: return entscheideGut(lage, p, zuege)
        case .lieb: return entscheideLieb(lage, p, zuege, menschen: menschen)
        }
    }
}
