// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Ungleichung {
    public var istKonsistent: Bool {
        let m = n * n
        return (2...9).contains(n) && loesung.count == m && werte.count == m && werte.allSatisfy { (0...n).contains($0) } && vorgaben.allSatisfy { (0..<m).contains($0) && werte[$0] == loesung[$0] }
    }
}
