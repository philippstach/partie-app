// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Hoelzchen {
    public var istKonsistent: Bool { !reihen.isEmpty && reihen.count <= 8 && reihen.allSatisfy { $0 >= 0 && $0 <= 20 } && (0...1).contains(amZug) }
}
