// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import Testing
import SwiftUI
@testable import SpielSudoku

struct SpielLayoutTests {
    private func layout(_ w: CGFloat, _ h: CGFloat, _ sc: UserInterfaceSizeClass? = .regular, ax: Bool = false) -> SpielLayout {
        SpielLayout.entscheide(breite: w, hoehe: h, sizeClass: sc, grosseSchrift: ax)
    }

    @Test func iPhoneIstKompakt() {
        #expect(layout(393, 852, .compact) == .kompakt)
        #expect(layout(932, 430, .compact) == .kompakt) // iPhone quer
    }

    @Test func iPad11Zoll() {
        #expect(layout(834, 1194) == .breitHoch)
        #expect(layout(1194, 834) == .breitQuer)
    }

    @Test func iPad13Zoll() {
        #expect(layout(1032, 1376) == .breitHoch)
        #expect(layout(1376, 1032) == .breitQuer)
    }

    @Test func splitView() {
        // ⅓ (iPad 11″ quer): schmal → iPhone-Layout; ½ quer: breit hoch; ⅔ quer: breit quer
        #expect(layout(320, 834, .compact) == .kompakt)
        #expect(layout(597, 834, .compact) == .kompakt)
        #expect(layout(597, 834, .regular) == .kompakt, "unter 700 pt immer kompakt")
        #expect(layout(834, 834, .regular) == .breitHoch)
        #expect(layout(795, 834, .regular) == .breitHoch)
        #expect(layout(1194 * 2 / 3, 834) == .breitHoch, "⅔ quer (796 pt): breit hoch")
        #expect(layout(1194 / 2, 834) == .kompakt, "½ quer (597 pt): unter 700 pt kompakt")
        #expect(layout(1032, 1032) == .breitHoch, "quadratisch gilt als hoch")
    }

    @Test func stageManagerFenster() {
        #expect(layout(800, 600) == .breitHoch, "800 × 600: breiter als hoch, aber unter 1000 pt")
        #expect(layout(1100, 700) == .breitQuer)
    }

    @Test func grosseSchriftNieQuer() {
        #expect(layout(1194, 834, ax: true) == .breitHoch)
        #expect(layout(393, 852, .compact, ax: true) == .kompakt)
    }
}
