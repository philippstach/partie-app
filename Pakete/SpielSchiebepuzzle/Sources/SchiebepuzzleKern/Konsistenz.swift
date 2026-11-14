// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Schiebepuzzle {
    /// Ist `felder` eine vollständige Anordnung von 0 bis n²−1?
    public var istKonsistent: Bool { (2...8).contains(n) && felder.sorted() == Array(0..<(n * n)) && zuege >= 0 }
}
