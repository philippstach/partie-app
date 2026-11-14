// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Bruecken {
    public var istKonsistent: Bool {
        guard (3...15).contains(groesse), !inseln.isEmpty else { return false }
        guard inseln.allSatisfy({ (0..<groesse).contains($0.x) && (0..<groesse).contains($0.y) && $0.n >= 0 }) else { return false }
        return bruecken.allSatisfy { $0.key.a >= 0 && $0.key.b < inseln.count && $0.value >= 0 && $0.value <= 3 }
    }
}
