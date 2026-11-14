// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Kakuro {
    public var istKonsistent: Bool {
        let m = n * n
        guard (3...12).contains(n), !laeufe.isEmpty, weiss.count == m, loesung.count == m, eintrag.count == m else { return false }
        guard eintrag.allSatisfy({ (0...9).contains($0) }), vorgaben.allSatisfy({ (0..<m).contains($0) }) else { return false }
        guard vorgaben.allSatisfy({ eintrag[$0] == loesung[$0] }) else { return false }   // Vorgaben sind nicht änderbar
        return laeufe.allSatisfy { l in l.felder.allSatisfy { (0..<m).contains($0) } && (0..<m).contains(l.startFeld) }
    }
}
