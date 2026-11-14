// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension ZahlenfusionModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "arrow.left", titel: "Wischen und verschmelzen", text: "Wische in eine Richtung: Alle Kacheln rutschen dorthin, gleiche Zahlen verschmelzen zur Summe.", geste: .wischen(von: UnitPoint(x: 0.7, y: 0.5), nach: UnitPoint(x: 0.3, y: 0.5)), ["2.2."], ["4..."], zelle: 44),
        .bild(symbol: "2.square", titel: "Bis zur 2048", text: "Nach jedem Zug erscheint eine neue 2 oder 4. Erreiche die 2048 – oder so viele Punkte wie möglich.", bild: "square.fill", geste: .keine),
        .bild(symbol: "square.grid.3x3", titel: "Größe und Zurück", text: "Im Menü wählst du das Feld von 3 × 3 bis 6 × 6. Zurück geht dreimal pro Spiel, der Tipp zeigt eine gute Richtung.", bild: "square.grid.3x3", geste: .keine),
    ] }
}
#endif
