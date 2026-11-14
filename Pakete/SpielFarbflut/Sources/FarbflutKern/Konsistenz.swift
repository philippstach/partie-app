// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Farbflut {
    public var istKonsistent: Bool {
        n >= 2 && farben >= 2 && feld.count == n * n && feld.allSatisfy { (0..<farben).contains($0) } && limit > 0 && zuege >= 0
    }
}
