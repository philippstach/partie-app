// Partie – https://github.com/philippstach/partie
// SPDX-License-Identifier: MIT

#if canImport(UIKit)
import SwiftUI
import KlarGlas

/// Anleitung zum Durchwischen (KlarGlas `AnleitungBlatt`); der Rahmen hängt die Regelseite als „Alle Regeln lesen“ an.
extension LichterAusModul {
    static var anleitung: [AnleitungSchritt] { [
        .raster(symbol: "lightbulb", titel: "Ein Tipp, fünf Felder", text: "Ein Tipp schaltet das Feld und seine vier Nachbarn um: an wird aus, aus wird an.", geste: .tippen(.zelle(1, 1, zeilen: 3, spalten: 3)), ["*.*", ".*.", "*.*"], [".*.", "***", ".*."], zelle: 44),
        .bild(symbol: "lightbulb.slash", titel: "Alle Lichter aus", text: "Bring alle Lichter zum Erlöschen, mit möglichst wenigen Tipps.", bild: "lightbulb.slash.fill", geste: .keine),
        .bild(symbol: "slider.horizontal.3", titel: "Größe, Stufe, Muster", text: "Im Menü stellst du Größe (3 × 3 bis 7 × 7), Schwierigkeit und Muster ein. Das Muster Plus, Diagonal oder Rund bestimmt, welche Nachbarn mitschalten.", bild: "slider.horizontal.3", geste: .keine),
    ] }
}
#endif
