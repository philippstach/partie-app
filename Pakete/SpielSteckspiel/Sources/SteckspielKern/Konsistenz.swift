// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Steckspiel {
    public var istKonsistent: Bool { !loecher.isEmpty && stecker.isSubset(of: loecher) }
}
