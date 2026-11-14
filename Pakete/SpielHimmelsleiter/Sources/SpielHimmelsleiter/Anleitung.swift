// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension HimmelsleiterModul {
    static var anleitung: [AnleitungSchritt] { [
        .bild(symbol: "dice.fill", titel: "Würfeln und ziehen", text: "Würfle und ziehe so viele Felder, wie der Würfel zeigt. Bei einer 6 darfst du nochmal.", bild: "dice.fill", geste: .tippen(UnitPoint(x: 0.5, y: 0.5))),
        .bild(symbol: "arrow.up.right", titel: "Leiter und Rutsche", text: "Unten an einer Leiter kletterst du hinauf, oben auf einer Wolkenrutsche rutschst du hinunter.", bild: "arrow.up.and.down", geste: .keine),
        .bild(symbol: "flag.checkered", titel: "Ziel: Feld 100", text: "Wer als Erster das Feld 100 erreicht, gewinnt. Dreimal hintereinander eine 6 heißt aussetzen.", bild: "flag.checkered", geste: .keine),
    ] }
}
#endif
