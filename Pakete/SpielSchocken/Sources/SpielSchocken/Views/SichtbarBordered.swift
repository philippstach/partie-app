// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI
import KlarGlas

extension View {
    /// Zweit-Pille in den Bedienleisten: zart (`accentSoft`) oder – wenn eine Funktion an ist – gefüllt in der App-Farbe.
    /// (Früher in Views/GameView.swift der Alt-Fassung; seit dem Kern-Umbau hier.)
    func sichtbarBordered(aktiv: Bool = false) -> some View {
        buttonStyle(AkzentPilleStil(gefuellt: aktiv))
    }
}

/// Schüttel-Effekt für den Becher. (Früher in Views/GameView.swift der Alt-Fassung; seit dem Kern-Umbau hier.)
struct WackelEffekt: ViewModifier {
    let zaehler: Int
    @State private var versatz: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: versatz)
            .onChange(of: zaehler) { _, _ in
                Task { @MainActor in
                    for v in [-8, 8, -5, 5, 0] as [CGFloat] {
                        withAnimation(.linear(duration: 0.05)) { versatz = v }
                        try? await Task.sleep(for: .milliseconds(50))
                    }
                }
            }
    }
}
