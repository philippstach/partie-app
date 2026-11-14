// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension PaarsucheModul {
    static var anleitung: [AnleitungSchritt] { [
        .bild(symbol: "rectangle.grid.2x2.fill", titel: "Zwei Karten aufdecken", text: "Tippe nacheinander zwei verdeckte Karten an.", bild: "rectangle.grid.2x2.fill", geste: .tippen(UnitPoint(x: 0.4, y: 0.5))),
        .bild(symbol: "checkmark.circle.fill", titel: "Paar gefunden", text: "Zeigen beide dasselbe Bild, gehört dir das Paar und du darfst nochmal.", bild: "checkmark.circle.fill", geste: .keine),
        .bild(symbol: "brain.head.profile", titel: "Gut merken", text: "Sonst werden sie wieder umgedreht. Merke dir, wo was liegt – wer die meisten Paare hat, gewinnt.", bild: "brain.head.profile", geste: .keine),
    ] }
}
#endif
