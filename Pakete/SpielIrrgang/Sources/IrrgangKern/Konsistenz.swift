// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Irrgang {
    public var istKonsistent: Bool {
        guard breite >= 2, hoehe >= 2, offen.count == hoehe, offen.allSatisfy({ $0.count == breite && $0.allSatisfy { $0.count == 4 } }) else { return false }
        let m = breite * hoehe
        return (0..<breite).contains(x) && (0..<hoehe).contains(y) && funken.allSatisfy { (0..<m).contains($0) } && besucht.allSatisfy { (0..<m).contains($0) }
    }
}
