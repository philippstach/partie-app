// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension KlappbrettModul {
    static var anleitung: [AnleitungSchritt] { [
        .bild(symbol: "dice.fill", titel: "Würfeln", text: "Würfle und sieh dir die Augensumme an.", bild: "dice.fill", geste: .tippen(UnitPoint(x: 0.5, y: 0.5))),
        .bild(symbol: "number.square.fill", titel: "Zahlen zuklappen", text: "Klappe offene Zahlen von 1 bis 9 zu, deren Summe genau der Würfelsumme entspricht.", bild: "number.square.fill", geste: .tippen(UnitPoint(x: 0.5, y: 0.4))),
        .bild(symbol: "trophy.fill", titel: "Wenige Punkte gewinnen", text: "Geht kein Zug mehr, zählen die offenen Zahlen als Punkte. Alle Zahlen zu bedeutet null Punkte.", bild: "trophy.fill", geste: .keine),
    ] }
}
#endif
