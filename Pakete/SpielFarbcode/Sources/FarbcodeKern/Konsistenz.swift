// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Farbcode {
    public var istKonsistent: Bool {
        code.count == modus.laenge && code.allSatisfy { (0..<modus.farben).contains($0) } && versuche.count <= modus.versuche
            && versuche.allSatisfy { $0.tipp.count == modus.laenge && $0.tipp.allSatisfy { (0..<modus.farben).contains($0) } }
    }
}
