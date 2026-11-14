// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Mogeln {
    /// Stimmigkeit eines geladenen Stands: alle 32 Karten genau einmal im Spiel, Zeiger im Bereich, und in der Phase „entscheiden“
    /// ist bekannt, wer wie viele Karten gelegt hat. Ein unstimmiger Stand wird verworfen statt geladen.
    public var istKonsistent: Bool {
        guard (2...6).contains(haende.count), haende.indices.contains(dran), (7...14).contains(rang) else { return false }
        let alle = haende.flatMap { $0 } + haufen
        guard alle.count == MoKarte.alle.count, Set(alle) == Set(MoKarte.alle) else { return false }
        if let g = gewinner { return haende.indices.contains(g) && haende[g].isEmpty }
        switch phase {
        case .entscheiden:
            guard let l = letzter, haende.indices.contains(l), l != dran, (1...4).contains(letzteAnzahl), letzteAnzahl <= haufen.count else { return false }
            return haende.indices.allSatisfy { $0 == l || !haende[$0].isEmpty }
        case .legen:
            return haende.allSatisfy { !$0.isEmpty }   // wer ablegen soll, braucht Karten
        }
    }
}
