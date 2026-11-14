// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension FarbcodeModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "paintpalette", titel: "Tipp legen", text: "Der Computer denkt sich einen Code aus Farbpunkten aus. Lege mit den Farben unten einen Tipp und tippe auf „Prüfen“.", geste: .tippen(.zelle(0, 1, zeilen: 1, spalten: 4)), ["...."], ["rgby"], zelle: 50),
        .raster(symbol: "circle.lefthalf.filled", titel: "Dunkel und hell", text: "Ein dunkler Punkt heißt: richtige Farbe an der richtigen Stelle. Ein heller Punkt: richtige Farbe, aber an der falschen Stelle.", geste: .keine, ["rgby", "...."], ["rgby", "**~~"], zelle: 44),
    ] }
}
#endif
