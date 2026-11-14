// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension NonogrammModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "number.square", titel: "Zahlen am Rand", text: "Die Zahlen am Rand sagen, wie lang die Blöcke gefüllter Felder in dieser Zeile oder Spalte sind – mit mindestens einem leeren Feld dazwischen.", geste: .tippen(.zelle(0, 1, zeilen: 2, spalten: 4)), ["2...", "...."], ["2.**", "...."], zelle: 44),
        .raster(symbol: "hand.tap", titel: "Füllen und markieren", text: "Tippe ein Feld, um es zu füllen. Halte es gedrückt, um es als leer zu markieren.", geste: .tippen(.zelle(0, 1, zeilen: 2, spalten: 3)), ["...", "..."], ["*..", "..."], zelle: 44),
    ] }
}
#endif
