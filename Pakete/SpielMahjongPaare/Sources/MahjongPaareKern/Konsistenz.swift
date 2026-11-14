// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension MahjongPaare {
    public var istKonsistent: Bool {
        steine.count >= 2 && steine.count % 2 == 0 && steine.allSatisfy { (0..<MahjongPaare.motive).contains($0.motiv) && $0.ebene >= 0 && $0.x >= 0 && $0.y >= 0 }
    }
}
