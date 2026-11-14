// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Zahlenfusion {
    public var istKonsistent: Bool { (2...8).contains(n) && feld.count == n * n && feld.allSatisfy { $0 >= 0 } && punkte >= 0 }
}
