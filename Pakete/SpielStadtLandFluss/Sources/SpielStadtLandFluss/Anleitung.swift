// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension StadtLandFlussModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "textformat.abc", titel: "Ein Buchstabe pro Runde", text: "Pro Runde wird ein Buchstabe gezogen. Trage zu jeder Kategorie ein Wort ein, das mit diesem Buchstaben beginnt.", geste: .tippen(.zelle(0, 1, zeilen: 2, spalten: 3)), ["B..", "..."], ["BER", "..."], zelle: 44),
        .bild(symbol: "star.circle", titel: "Punkte", text: "Je Kategorie: 10 Punkte, 5 bei gleicher Antwort mehrerer Spieler, 20 wenn nur du eine gültige Antwort hast. Fünf Runden, die meisten Punkte gewinnen.", bild: "star.circle.fill", geste: .keine),
    ] }
}
#endif
