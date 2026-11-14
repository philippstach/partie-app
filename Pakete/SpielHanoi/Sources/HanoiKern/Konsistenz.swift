// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Hanoi {
    /// Scheiben 1…n liegen genau einmal auf den Stäben, jeder Stab ist nach oben kleiner werdend.
    public var istKonsistent: Bool {
        guard (1...12).contains(scheiben), (3...5).contains(anzahlStaebe), staebe.count == anzahlStaebe else { return false }
        guard staebe.flatMap({ $0 }).sorted() == Array(1...scheiben) else { return false }
        return staebe.allSatisfy { st in zip(st, st.dropFirst()).allSatisfy { $0 > $1 } }
    }
}
