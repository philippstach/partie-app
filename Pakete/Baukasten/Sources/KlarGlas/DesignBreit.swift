// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

import SwiftUI

// Designwechsel (KlarGlas 2.19): Tinte und Salon auf dem iPad. Gemeinsame Seiten (Sieger, Zwischenstand, Neues Spiel, Gerät weitergeben, Einführung)
// stehen in einer Spalte; in der breiten Größenklasse wird sie breiter und die Schrift eine Stufe größer. „Klar & Glas“ und die schmale
// Größenklasse (iPhone, Split View, Slide Over) bleiben genau wie bisher (Spalte `Theme.wideColumnWidth`).

public extension View {
    /// Spalte der Seite: wie bisher `.frame(maxWidth: Theme.wideColumnWidth).frame(maxWidth: .infinity)`; in Tinte und Salon mit breiter Größenklasse
    /// 25 % breiter und mit größerer Schrift (Dynamic-Type-Stufe XXL).
    func iPadSpalte() -> some View { modifier(IPadSpalteStil()) }
}

private struct IPadSpalteStil: ViewModifier {
    @Environment(\.horizontalSizeClass) private var klasse
    @Environment(\.designArt) private var art

    func body(content: Content) -> some View {
        if art != .klar && klasse == .regular {
            content
                .dynamicTypeSize(.xxLarge)
                .frame(maxWidth: Theme.wideColumnWidth * 1.25)
                .frame(maxWidth: .infinity)
        } else {
            content
                .frame(maxWidth: Theme.wideColumnWidth)
                .frame(maxWidth: .infinity)
        }
    }
}
