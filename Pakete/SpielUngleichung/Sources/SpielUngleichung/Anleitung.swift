// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension UngleichungModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "lessthan", titel: "Zeichen lesen", text: "Die Spitze eines Zeichens zeigt zur kleineren Zahl: „<“ heißt, die linke (obere) Zahl ist kleiner als die rechte (untere).", geste: .tippen(.zelle(0, 2, zeilen: 1, spalten: 3)), ["1<."], ["1<3"], zelle: 44),
        .bild(symbol: "square.grid.3x3", titel: "Jede Zahl einmal", text: "Fülle das Quadrat mit den Zahlen von 1 bis zur Kantenlänge: in jeder Zeile und Spalte jede Zahl genau einmal.", bild: "square.grid.3x3.fill", geste: .keine),
    ] }
}
#endif
