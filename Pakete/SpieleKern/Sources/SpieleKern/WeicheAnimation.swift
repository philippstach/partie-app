// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(SwiftUI)
import SwiftUI

public extension View {
    /// Weiche Übergänge, wenn sich der Spielzustand ändert (Steine, Einträge, Felder). Bei „Bewegung reduzieren“ ohne Animation.
    func weicheAnimation<V: Equatable>(bei wert: V) -> some View { modifier(WeicheAnimation(wert: wert)) }
}

struct WeicheAnimation<V: Equatable>: ViewModifier {
    let wert: V
    @Environment(\.accessibilityReduceMotion) private var bewegungReduziert
    func body(content: Content) -> some View {
        content.animation(bewegungReduziert ? nil : .snappy(duration: 0.18), value: wert)
    }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

public extension View {
    /// Einheitliche Haptik der Rätselspiele, abschaltbar über Einstellungen › Ton & Haptik (`SpieleHaptik`).
    /// `zug`: ändert sich bei jedem Zug (leichter Impuls). `erfolg`: wird `true` beim Lösen. `fehler`: wird `true` bei Scheitern/Fehler.
    func spielHaptik<Z: Equatable>(zug: Z, erfolg: Bool, fehler: Bool = false) -> some View {
        self
            .sensoryFeedback(trigger: zug) { _, _ in SpieleHaptik.erlaubt ? .impact(weight: .light) : nil }
            .sensoryFeedback(trigger: erfolg) { alt, neu in (neu && !alt && SpieleHaptik.erlaubt) ? .success : nil }
            .sensoryFeedback(trigger: fehler) { alt, neu in (neu && !alt && SpieleHaptik.erlaubt) ? .error : nil }
    }
}
#endif

public extension View {
    /// Blätter auf dem iPad in Seitengröße statt Vollbild (ab iOS 18; auf dem iPhone ohne Wirkung). Gegenstück zu `formSheet()` aus KlarGlas.
    @ViewBuilder func seitenBlatt() -> some View {
        if #available(iOS 18, macOS 15, *) { presentationSizing(.page) } else { self }
    }
}
