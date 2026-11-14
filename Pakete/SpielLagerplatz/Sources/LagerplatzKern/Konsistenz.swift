// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation

extension Lagerplatz {
    public var istKonsistent: Bool {
        guard breite >= 3, hoehe >= 3 else { return false }
        func drin(_ p: LPos) -> Bool { (0..<breite).contains(p.x) && (0..<hoehe).contains(p.y) }
        return drin(spieler) && kisten.allSatisfy(drin) && ziele.allSatisfy(drin) && waende.allSatisfy(drin) && kisten.count == ziele.count && !kisten.contains(spieler)
    }
}
