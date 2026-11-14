// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Foundation
import Testing
@testable import SpielRauswurf

@Suite("Würfel")
struct WuerfelTests {
    @Test func augenLiegenInnerhalbDerFlaeche() {
        let r = DieView.augenAnteil / 2
        for n in 1 ... 6 {
            let punkte = DieView.augenPunkte[n] ?? []
            #expect(punkte.count == n, "Würfel \(n) hat \(punkte.count) Augen")
            for p in punkte {
                // ganzes Auge mit Abstand zum Rand (mindestens 8 % der Kante)
                #expect(p.x - r >= 0.08 && p.x + r <= 0.92, "Auge x \(p.x) bei \(n)")
                #expect(p.y - r >= 0.08 && p.y + r <= 0.92, "Auge y \(p.y) bei \(n)")
            }
            // keine zwei Augen überlappen
            for (i, a) in punkte.enumerated() {
                for b in punkte[(i + 1)...] {
                    #expect(hypot(a.x - b.x, a.y - b.y) > DieView.augenAnteil * 1.2)
                }
            }
        }
    }
}
