// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension SchiffsfrachtModul {
    static var anleitung: [AnleitungSchritt] { [
        .bild(symbol: "dice.fill", titel: "Reihenfolge würfeln", text: "Zuerst eine 6 (Schiff), dann eine 5 (Kapitän), dann eine 4 (Mannschaft). Sie werden automatisch festgelegt.", bild: "dice.fill", geste: .tippen(UnitPoint(x: 0.5, y: 0.5))),
        .bild(symbol: "shippingbox.fill", titel: "Fracht zählt", text: "Mit Besatzung zählen die übrigen zwei Würfel als Fracht, höchstens 12. Ohne Besatzung ist sie null.", bild: "shippingbox.fill", geste: .keine),
        .bild(symbol: "flag.fill", titel: "Fünf Runden", text: "Wer in einer Runde die meiste Fracht hat, bekommt einen Punkt. Du darfst nach jedem Wurf mit Fertig aufhören.", bild: "flag.fill", geste: .keine),
    ] }
}
#endif
